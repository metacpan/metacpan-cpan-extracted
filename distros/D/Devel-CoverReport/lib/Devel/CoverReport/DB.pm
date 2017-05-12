# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/

package Devel::CoverReport::DB;

use strict;
use warnings;

our $VERSION = "0.05";

use Carp;
use Digest::MD5 qw( md5_hex );
use English qw( -no_match_vars );
use File::Slurp qw( read_file write_file read_dir );
use JSON;
use Params::Validate qw( :all );
use Storable;
use YAML::Syck qw( LoadFile DumpFile );

=encoding UTF-8

=head1 DESCRIPTION

Methods for accessing files from I<cover_db> database.

=head1 WARNING

Consider this module to be an early ALPHA. It does the job for me, so it's here.

This is my first CPAN module, so I expect that some things may be a bit rough around edges.

The plan is, to fix both those issues, and remove this warning in next immediate release.

=head1 API

=over

=item new

Constructor for C<Devel::CoverReport::DB>.

=cut

sub new { # {{{
    my $class = shift;
    my %P = @_;
    validate(
        @_,
        {
            cover_db => { type=>SCALAR },
        }
    );

    my $self = {
        cover_db => $P{'cover_db'},

        runs_path      => $P{'cover_db'} . '/runs/',
        structure_path => $P{'cover_db'} . '/structure/',

        runs    => undef,
        digests => undef,
    };

    bless $self, $class;

    if (not $self->is_valid()) {
        croak "Is not a valid cover_db database: ". $self->{'cover_db'};
    }

    return $self;
} # }}}

=item is_valid

Check if specified I<cover_db> database seems to be valid.

Returns true, if DB seems to be OK.

Returns false, if problems with DB are found, additionally carp'ing about them along the way.

=cut

sub is_valid { # {{{
    my ( $self ) = @_;

    if (not -d $self->{'cover_db'}) {
        # Directory does not exist, it may not be valid.
        carp "Not a directory: ". $self->{'cover_db'};

        return 0;
    }

    if (not -d $self->{'runs_path'}) {
        # Directory 'runs' does not exist...
        carp "Not a directory: ". $self->{'runs_path'};

        return 0;
    }

    if (not -d $self->{'structure_path'}) {
        # Directory 'structure' does not exist...
        carp "Not a directory: ". $self->{'structure_path'};

        return 0;
    }

    # No problems found :)
    return 1;
} # }}}

=item get_digest_to_run

Analize contents of 'runs' directory, and prepare mapping that shows which runs cover which files (from structure).

Returned data structure is as follows:

 %digest_to_run = (
    $file_1_digest => [
        $run_1_id,
        $run_2_id,
        ...
        $run_n_id,
    ],
    $file_2_digest => [
        ...
    ],
    ...
    $file_n_digest => [
        ...
    ],
 );

=cut

sub get_digest_to_run { # {{{
    my ( $self, $feedback ) = @_;

    my %digest_to_run; # which runs covered which file.

    $feedback->progress_open("Runs/files");

    foreach my $run ( read_dir($self->{'runs_path'}) ) {
        foreach my $version (qw( 12 13 )) {
            my $datafile_path = $self->{'runs_path'} . q{/} . $run . q{/cover.} . $version;

            if (not -f $datafile_path) {
                next;
            }

            my $run_data = $self->read_db_file($datafile_path, $version);

#            use YAML::Syck; warn Dump $run_data;

            foreach my $digest (values %{ $run_data->{'runs'}->{$run}->{'digests'} } ) {
                push @{ $digest_to_run{$digest} }, $run;
            }

            last;
        }

        $feedback->progress_tick();
    }

#    use Data::Dumper; warn Dumper \%digest_to_run;

    $feedback->progress_close();

    return %digest_to_run;
} # }}}

=item digests

Return all digests (structure IDs), from current cover_db.

=cut
sub digests { # {{{
    my ( $self ) = @_;

    if ($self->{'digests'}) {
        return @{ $self->{'digests'} };
    }

    my @digests;
    foreach my $item (read_dir( $self->{'cover_db'} . '/structure' )) {
        # Skip hidden files...
        if ($item =~ m{^\.}) {
            next;
        }

        if (-f $self->{'cover_db'} . '/structure/' . $item) {
            push @digests, $item;
        }
    }

    return @{ $self->{'digests'} = \@digests };
} # }}}

=item runs

Return all run ID, from current cover_db.

=cut
sub runs { # {{{
    my ( $self ) = @_;

    if ($self->{'runs'}) {
        return @{ $self->{'runs'} };
    }

    my @runs;
    foreach my $dir (read_dir( $self->{'cover_db'} . '/runs' )) {
        # Skip hidden files...
        if ($dir =~ m{^\.}) {
            next;
        }

        if (-d $self->{'cover_db'} . '/runs/' . $dir) {
            push @runs, $dir;
        }
    }

    return @{ $self->{'runs'} = \@runs };
} # }}}

=item get_structure_data

Slurp and deserialize data for single structure element, identified by C<$digest>.

Parameters:
  $self
  $digest

Returns:
  $digest_data - hashref.

=cut
sub get_structure_data { # {{{
    my ( $self, $digest ) = @_;

    return $self->read_db_file($self->{'structure_path'} . q{/} . $digest);
} # }}}

=item get_run_data

Slurp and deserialize data for single run, identified by C<$run>.

Parameters:
  $self
  $run

Returns:
  $run_data - hashref.

=cut
sub get_run_data { # {{{
    my ( $self, $run ) = @_;

    foreach my $version (qw( 12 13 )) {
        my $run_data_path = $self->{'runs_path'} . q{/} . $run . q{/cover.} . $version;

        if (-f $run_data_path) {
            return $self->read_db_file($run_data_path);
        }
    }

    return;
} # }}}

=item make_file_digest

Generate cover_db-compatile file digest.

Parameters:
  $self
  $path

Returns:
  $digest - scalar (string)

=cut
sub make_file_digest { # {{{
    my ( $self, $path ) = @_;

    return ( $self->{'_digest_cache'}->{$path} or $self->{'_digest_cache'}->{$path} = md5_hex(scalar read_file($path)) );
} # }}}

=item read_db_file

Read and parse DB file, then return data structure as it is in the file.

Bu default, it assumes, that file is a I<storeble> data dump.
When storable fails, it will try to use I<JSON> to load the data.

This method supports reading I<.12> and I<.13> file formats.
It can auto-detect if it was serialized with storable or JSON.

=cut
sub read_db_file { # {{{
    my ( $self, $file_path ) = @_;

    my $data = read_file($file_path);

    my $storable_info = Storable::read_magic($data);

    if ($storable_info) {
        # Data is a Storable image.
        return retrieve($file_path);
    }

    require JSON;

    return decode_json( $data );
} # }}}

1;

=back

=head1 LICENCE

Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)

This is free software. It is licensed, and can be distributed under the same terms as Perl itself.

For more, see my website: http://bs502.pl/

=cut

# vim: fdm=marker
