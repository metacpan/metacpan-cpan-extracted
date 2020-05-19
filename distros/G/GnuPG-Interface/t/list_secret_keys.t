#!/usr/bin/perl -w
#
# $Id: list_secret_keys.t,v 1.7 2001/05/03 06:00:06 ftobin Exp $
#

use strict;
use English qw( -no_match_vars );

use lib './t';
use MyTest;
use MyTestSpecific;

my $outfile;

TEST
{
    reset_handles();

    $ENV{LC_MESSAGES} = 'C';
    my $pid = $gnupg->list_secret_keys( handles => $handles );
    close $stdin;

    $outfile = 'test/secret-keys/1.out';
    my $out = IO::File->new( "> $outfile" )
      or die "cannot open $outfile for writing: $ERRNO";
    my $seckey_file = $gnupg->cmp_version($gnupg->version, '2.1') >= 0 ? 'pubring.kbx' : 'secring.gpg';
    my $pubring_line = $gnupg->options->homedir() . '/' . $seckey_file . "\n";
    while (<$stdout>) {
      if ($_ eq $pubring_line) {
        $out->print('test/gnupghome/'.$seckey_file."\n");
      } elsif (/^--*$/) {
        $out->print("--------------------------\n");
      } else {
        $out->print( $_ );
      }
    }
    close $stdout;
    $out->close();
    waitpid $pid, 0;

    return $CHILD_ERROR == 0;
};


TEST
{
    my $keylist;
    if ($gnupg->cmp_version($gnupg->version, '2.1') < 0) {
	$keylist = '0';
    }
    else {
	if ($gnupg->cmp_version($gnupg->version, '2.1.11') <= 0) {
	    $keylist = '1';
	}
	else {
	    $keylist = '2';
	}
    }
    my @files_to_test = ( 'test/secret-keys/1.'.$keylist.'.test' );

    return file_match( $outfile, @files_to_test );
};


TEST
{
    reset_handles();

    my $pid = $gnupg->list_secret_keys( handles      => $handles,
                                        command_args => '0x93AFC4B1B0288A104996B44253AE596EF950DA9C' );
    close $stdin;

    $outfile = 'test/secret-keys/2.out';
    my $out = IO::File->new( "> $outfile" )
      or die "cannot open $outfile for writing: $ERRNO";
    $out->print( <$stdout> );
    close $stdout;
    $out->close();

    waitpid $pid, 0;

    return $CHILD_ERROR == 0;

};


TEST
{
    reset_handles();

    $handles->stdout( $texts{temp}->fh() );
    $handles->options( 'stdout' )->{direct} = 1;

    my $pid = $gnupg->list_secret_keys( handles      => $handles,
                                        command_args => '0x93AFC4B1B0288A104996B44253AE596EF950DA9C' );

    waitpid $pid, 0;

    $outfile = $texts{temp}->fn();

    return $CHILD_ERROR == 0;
};
