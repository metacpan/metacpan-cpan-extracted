package Lingua::ZH::CCDICT::Storage::BerkeleyDB;

use strict;
use warnings;

use base qw( Lingua::ZH::CCDICT );

use BerkeleyDB qw( DB_CREATE DB_DUP DB_INIT_MPOOL DB_NOTFOUND DB_SET DB_NEXT DB_NEXT_DUP );

use File::Spec;

use Params::Validate qw( validate SCALAR );

use Storable qw( nfreeze );

use Lingua::ZH::CCDICT::ResultItem;
use Lingua::ZH::CCDICT::ResultSet::BerkeleyDB;


sub new
{
    my $class = shift;
    my %p = validate( @_,
                      { work_dir => { type => SCALAR },
                      },
                    );

    my $env = BerkeleyDB::Env->new( -Home  => $p{work_dir},
                                    -Flags => DB_CREATE | DB_INIT_MPOOL,
                                  )
        or die "Cannot create BerkeleyDB::Env object: $BerkeleyDB::Error\n";

    my @files;

    my %main_db;
    tie %main_db, 'BerkeleyDB::Hash', ( -Filename => 'ccdict_data',
                                        -Env => $env,
                                        -Flags => DB_CREATE,
                                      )
        or die "Cannot create BerkeleyDB::Hash object: $! -- $BerkeleyDB::Error\n";


    push @files, File::Spec->catfile( $p{work_dir}, 'ccdict_data' );

    my %indexes;

    foreach my $type ( $class->_InternalTypes )
    {
        next if $type eq 'english';

        $indexes{$type} = BerkeleyDB::Hash->new( -Filename => "ccdict_index_$type",
                                                 -Env => $env,
                                                 -Flags => DB_CREATE,
                                                 -Property => DB_DUP,
                                               )
            or die "Cannot create BerkeleyDB::Hash object: $! -- $BerkeleyDB::Error\n";

        push @files, File::Spec->catfile( $p{work_dir}, "ccdict_index_$type" );
    }

    return bless { data    => \%main_db,
                   db      => tied %main_db,
                   indexes => \%indexes,
                   files   => \@files,
                 }, $class;
}

sub _real_add_entry
{
    my $self    = shift;
    my $unicode = shift;
    my $entry   = shift;

    foreach my $key ( keys %{ $entry } )
    {
        next if $key eq 'english' || $key eq 'unicode';

        foreach my $val ( ref $entry->{$key} eq 'ARRAY' ?
                          @{ $entry->{$key} } :
                          $entry->{$key} )
        {

            my $status = $self->{indexes}{$key}->db_put( "$val" => $unicode );

            die "Failed to store key ($val): $status" if $status;
        }
    }

    my $status = $self->{db}->db_put( $unicode => nfreeze($entry) );

    die "Failed to store key ($unicode): $status" if $status;
}

sub match_unicode
{
    my $self = shift;

    my %seen;
    my @chars = map { $seen{$_}++ ? () : $_ } sort @_;

    return
        Lingua::ZH::CCDICT::ResultSet::BerkeleyDB->new
            ( keys => \@chars,
              db   => $self->{db},
            );
}

sub _match
{
    my $self = shift;
    my $type = shift;

    return
        $self->match_unicode
            ( map { $self->_get_all_values( $self->{indexes}{$type}, $_ ) } @_ );
}

sub _get_all_values
{
    my $self = shift;
    my $db = shift;
    my $key = shift;

    my $cursor = $db->db_cursor;

    die "Failed to create a cursor: $BerkeleyDB::Error" unless $cursor;

    my @values;

    my $value;
    my $status = $cursor->c_get( $key, $value, DB_SET );

    if ( $status )
    {
        return if $status == DB_NOTFOUND;

        die "Calling c_get on a cursor failed: $status";
    }

    push @values, $value;

    while (1)
    {
        $status = $cursor->c_get( $key, $value, DB_NEXT_DUP );

        if ( $status )
        {
            last if $status == DB_NOTFOUND;

            die "Calling c_get on a cursor failed: $status";
        }

        push @values, $value;
    }

    return @values;
}

sub all_characters
{
    my $self = shift;

    return
        Lingua::ZH::CCDICT::ResultSet::BerkeleyDB->new
            ( keys => [ keys %{ $self->{data} } ],
              db   => $self->{db},
            );
}

sub entry_count
{
    my $self = shift;

    return scalar keys %{ $self->{data} };
}

sub files { @{ $_[0]->{files} } }


1;

__END__

=head1 NAME

Lingua::ZH::CCDICT::Storage::BerkeleyDB - Store the dictionary in BerkeleyDB files

=head1 USAGE

  use Lingua::ZH::CCDICT;

  my $dict = Lingua::ZH::CCDICT->new( storage  => 'BerkeleyDB',
                                      work_dir => '/path/to/work/dir',
                                    );

=head1 DESCRIPTION

This module stores the CCDICT dictionary in a set of BerkeleyDB files.
There is one file for the data and a number of other files used as
indexes.

This storage implementation is quite fast and uses very little memory.

The only parameter it takes is "work_dir". This directory will be used
when creating new files from a CCDICT source file, when
C<parse_source_file()> is called. Once these files exist, they can be
re-used for future searches without parsing the source again.

This class is the most memory-efficient of all the storage classes, as
it uses BerkeleyDB cursors for result sets. It is also quite fast.

=head1 METHODS

This class offers only one method not documented in the
C<Lingua::ZH::CCDICT> class.

=head2 $dict->files()

This returns a list of the files that make up the dictionary. This
list includes files automatically created by BerkeleyDB for its own
use.

=head1 AUTHOR

David Rolsky <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2002-2007 David Rolsky. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
