#  MyTestSpecific.pm
#    - module for use with test scripts
#
#  Copyright (C) 2000 Frank J. Tobin <ftobin@cpan.org>
#
#  This module is free software; you can redistribute it and/or modify it
#  under the same terms as Perl itself.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#  $Id: MyTestSpecific.pm,v 1.7 2001/08/21 13:31:50 ftobin Exp $
#

use strict;
use English qw( -no_match_vars );
use Fatal qw/ open close /;
use IO::File;
use IO::Handle;
use IO::Seekable;
use File::Compare;
use Exporter;
use Class::Struct;
use File::Temp qw (tempdir);

use GnuPG::Interface;
use GnuPG::Handles;

use vars qw( @ISA           @EXPORT
             $stdin         $stdout           $stderr
             $gpg_program   $handles          $gnupg
             %texts
           );

@ISA    = qw( Exporter );
@EXPORT = qw( stdin                  stdout          stderr
              gnupg_program handles  reset_handles
              texts                  file_match
            );

my $homedir;
if (-f "test/gnupghome") {
  my $record = IO::File->new( "< test/gnupghome" );
  $homedir = <$record>;
  $record->close();
} else {
  $homedir = tempdir( DIR => '/tmp');
  my $record = IO::File->new( "> test/gnupghome" );
  $record->write($homedir);
  $record->close();
}

$ENV{'GNUPGHOME'} = $homedir;

$gnupg = GnuPG::Interface->new( passphrase => 'test' );
$gnupg->options->hash_init( homedir              => $homedir,
                            armor                => 1,
                            meta_interactive     => 0,
                            meta_signing_key_id  => '0x93AFC4B1B0288A104996B44253AE596EF950DA9C',
                            always_trust         => 1,
                          );

struct( Text => { fn => "\$", fh => "\$", data => "\$" } );

$texts{plain} = Text->new();
$texts{plain}->fn( 'test/plain.1.txt' );

$texts{alt_plain} = Text->new();
$texts{alt_plain}->fn( 'test/plain.2.txt' );

$texts{encrypted} = Text->new();
$texts{encrypted}->fn( 'test/encrypted.1.gpg' );

$texts{alt_encrypted} = Text->new();
$texts{alt_encrypted}->fn( 'test/encrypted.2.gpg' );

$texts{signed} = Text->new();
$texts{signed}->fn( 'test/signed.1.asc' );

$texts{key} = Text->new();
$texts{key}->fn( 'test/key.1.asc' );

$texts{temp} = Text->new();
$texts{temp}->fn( 'test/temp' );


foreach my $name ( qw( plain alt_plain encrypted alt_encrypted signed key ) )
{
    my $entry = $texts{$name};
    my $filename = $entry->fn();
    my $fh = IO::File->new( $filename )
      or die "cannot open $filename: $ERRNO";
    $entry->data( [ $fh->getlines() ] );
}

sub reset_handles
{
    foreach ( $stdin, $stdout, $stderr )
    {
        $_ = IO::Handle->new();
    }

    $handles = GnuPG::Handles->new
      ( stdin   => $stdin,
        stdout  => $stdout,
        stderr  => $stderr
      );

    foreach my $name ( qw( plain alt_plain encrypted alt_encrypted signed key ) )
    {
        my $entry = $texts{$name};
        my $filename = $entry->fn();
        my $fh = IO::File->new( $filename )
          or die "cannot open $filename: $ERRNO";
        $entry->fh( $fh );
    }

    {
        my $entry = $texts{temp};
        my $filename = $entry->fn();
        my $fh = IO::File->new( $filename, 'w' )
          or die "cannot open $filename: $ERRNO";
        $entry->fh( $fh );
    }
}



sub file_match
{
    my ( $orig, @compares ) = @_;

    my $found_match = 0;

    foreach my $file ( @compares )
    {
        return 1
          if compare( $file, $orig ) == 0;
    }

    return 0;
}



# blank user_id_string and different validity for expired sig in GPG 2.2.x vs 1.x, 2.1
sub get_expired_test_sig_params {
    my $gnupg = shift;
    my $version = $gnupg->version;

    my %sig_params = (
        date_string => '2000-03-16',
        hex_id => '56FFD10A260C4FA3',
        sig_class => 0x10,
        algo_num => 17,
        is_exportable => 1,
    );
    if ($gnupg->cmp_version($gnupg->version, '2.2') > 0) {
        $sig_params{user_id_string} = '';
        $sig_params{validity} = '?';
    }
    else {
        $sig_params{user_id_string} = 'Frank J. Tobin <ftobin@neverending.org>',
        $sig_params{validity} = '!';
    }
    return %sig_params
}

1;
