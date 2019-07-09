package IO::BlockSync::App;

# Basic
use 5.010;
use strict;
use warnings FATAL => 'all';

# Build in
use English qw( -no_match_vars );
use Scalar::Util qw(blessed);

# CPAN
use Moo;
use MooX::Options;
use Log::Log4perl;
use Log::Log4perl::Level;

# This bundle
use IO::BlockSync;

################################################################

=head1 NAME

IO::BlockSync::App - Perl module

=head1 VERSION

Version 0.002

=cut

our $VERSION = '0.002';

################################################################

=head1 SYNOPSIS

BlockSync can some of the same stuff that bigsync (by Egor Egorov) can
- it's just written in perl.

BlockSync copies data from source file to destination file (can be a block
device) and calculates checksum on each block it copies.
On all runs after the first only the changed blocks will be copied.

    blocksync -S -s /source/path -d /destination/path

=cut

################################################################

=head1 INSTALLATION

Look in C<README.pod>

Can also be found on
L<GitHub|https://github.com/thordreier/perl-IO-BlockSync/blob/master/README.pod>
or L<meta::cpan|https://metacpan.org/pod/distribution/IO-BlockSync/README.pod>

=cut

################################################################

=head1 COMMAND LINE OPTIONS

=cut

################################################################

=head2 -V --version

Print version and exit

=cut

option 'version' => (
    is    => 'ro',
    short => 'V',
    doc   => 'print version and exit',
);

################################################################

=head2 -v --verbose

Print version and exit

=cut

option 'verbose' => (
    is         => 'ro',
    short      => 'v',
    repeatable => 1,
    doc        => 'be verbose',
);

################################################################

=head2 -s --src

Path to source file.

mandatory - string (containing path)

=cut

option 'src' => (
    is     => 'ro',
    format => 's',
    short  => 's',
    doc    => 'source file path',
);

################################################################

=head2 -d --dst

Destination file. If not set, then only checksum file will be updated.

optional - string (containing path)

=cut

option 'dst' => (
    is     => 'ro',
    format => 's',
    short  => 'd',
    doc    => 'destination file path',
);

################################################################

=head2 -c --chk

Path to checksum file.

mandatory - string (containing path)

=cut

option 'chk' => (
    is     => 'rwp',
    format => 's',
    short  => 'c',
    doc    => 'checksum file path',
);

################################################################

=head2 -b --bs

Block size to use in bytes.

optional - integer - defaults to 1_048_576 B (1 MB)

=cut

option 'bs' => (
    is      => 'ro',
    format  => 'i',
    short   => 'b',
    default => 1_048_576,
    doc     => 'block size',
);

################################################################

=head2 -S --sparse

Seek in dst file, instead of writing blocks only containing \0

optional - boolean - defaults to 0 (false)

=cut

option 'sparse' => (
    is      => 'ro',
    short   => 'S',
    default => 0,
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    doc => 'seek in dst file, instead of writing blocks only containing \0',
    ## use critic
);

################################################################

=head2 -t --truncate

Truncate the destination file to same size as source file. Does not work on block devices. Will only be tried if C<data> has default value (whole file is copied).

optional - boolean - defaults to 0 (false)

=cut

option 'truncate' => (
    is      => 'ro',
    short   => 't',
    default => 0,
    doc     => 'truncate destination file',
);

################################################################

=head1 METHODS

=cut

################################################################

=head2 run

C<bin/blocksync> calls C<IO::BlockSync::App::run> to start the program.

If you just run C<blocksync> command then ignore this method.

=cut

sub run {
    my ($self) = @_;

    # Create object with data from command line and run this function again
    if ( !blessed $self) {
        return $self->new_with_options->run;
    }

    if ( $self->version ) {
        say "blocksync version $VERSION";
        exit;
    }

    if ( !$self->src ) {
        $self->options_usage( 1, '<src> must be set' );
    }

    if ( $self->dst && !$self->chk ) {
        $self->_set_chk( $self->dst . '.chk' );
    }
    elsif ( !$self->dst && !$self->chk ) {
        $self->options_usage( 1, 'at least one of <chk> or <dst> must be set' );
    }

    my $status;
    if ( $self->verbose ) {
        $status = sub {
            printf
              "Copying block=<%s> type=<%s> start=<%s> end=<%s> size=<%s>\n",
              @_, $_[3] - $_[2];
        };
        if ( $self->verbose > 1 ) {
            Log::Log4perl->init( \<<"EOF");
                log4perl.logger = DEBUG, Screen
                log4perl.appender.Screen = Log::Log4perl::Appender::Screen
                log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
                log4perl.appender.Screen.layout.ConversionPattern = %d %p %M %m%n
EOF
        }
    }
    else {
        $status = sub {
            $OUTPUT_AUTOFLUSH++;
            print( "\rCopying block " . shift );
        }
    }

    BlockSync( %{$self}, 'status' => $status, );

    say '';

    # Make Perl::Critic happy
    return;
}

################################################################

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Thor Dreier-Hansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself:

=over

=item * the 
        L<GNU General Public License|http://dev.perl.org/licenses/gpl1.html>
        as published by the Free Software Foundation; either
        L<version 1|http://dev.perl.org/licenses/gpl1.html>,
        or (at your option) any later version, or

=item * the L<"Artistic License"|http://dev.perl.org/licenses/artistic.html>

=back

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of IO::BlockSync::App
