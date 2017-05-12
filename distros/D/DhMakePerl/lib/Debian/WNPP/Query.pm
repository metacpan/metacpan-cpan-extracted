package Debian::WNPP::Query;
use strict;
use warnings;

our $VERSION = '0.74';

=head1 NAME

Debian::WNPP::Query - offline storage of Debian's work-needing package lists

=head1 SYNOPSIS

    my $wnpp = Debian::WNPP::Query->new(
        {   cache_dir       => '/somewhere',
            network_enabled => 0,
            ttl             => 3600 * 24,
            bug_types       => [qw( ITP RFP )]
        }
    );

    my @bugs = $wnpp->bugs_for_package('ken-lee');

=head1 DESCRIPTION

Debian::WNPP::Query provides a way to retrieve and cache the contents of
Debian's "Work-needing and prospective packages" lists.

=head1 CONSTRUCTOR

B<new> is the constructor. Initial field values are to be given as a hash
reference.

If B<cache_file> is given, it is read.

=cut

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(
    qw(
        cache_file ttl bug_types
        _bug_types _cache
        )
);

use autodie;
use Debian::WNPP::Bug;
use File::Basename qw(dirname);
use File::Path;
use Storable ();
use WWW::Mechanize ();

our %list_url = (
    ITP => 'http://www.debian.org/devel/wnpp/being_packaged',
    RFP => 'http://www.debian.org/devel/wnpp/requested',
    ITA => 'http://www.debian.org/devel/wnpp/being_adopted',
    RFA => 'http://www.debian.org/devel/wnpp/rfa_bypackage',
    O   => 'http://www.debian.org/devel/wnpp/orphaned',
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # default to all types
    $self->_bug_types(
        { map( ( $_ => 1 ), @{ $self->bug_types || [ keys %list_url ] } ), }
    );

    # default TTL
    $self->ttl( 24 * 3600 )
        unless defined $self->ttl;

    $self->_cache( {} );

    $self->_read_cache if $self->cache_file;
    $self->_fetch
        if not $self->_cache->{timestamp}
            or ( ( time - $self->_cache->{timestamp} ) > $self->ttl );

    return $self;
}

sub _read_cache {
    my $self = shift;

    return unless $self->cache_file and -e $self->cache_file;

    $self->_cache( eval { Storable::retrieve( $self->cache_file ) }
            || {} );
}

sub _write_cache {
    my $self = shift;

    return unless $self->cache_file;

    File::Path::make_path( dirname( $self->cache_file ) );

    $self->_cache->{timestamp} = scalar(time);

    Storable::nstore( $self->_cache, $self->cache_file );
}

sub _fetch {
    my $self = shift;

    my $browser = WWW::Mechanize->new();

    while( my( $type, $url ) = each %list_url ) {
        eval {
            $browser->get($url);
        };
        if ($@) {
            warn "Error retrieving the list of $type bugs:\n";
            warn $@;
            next;
        }

        for my $link ( $browser->links ) {
            next unless $link->url =~ m{^http://bugs.debian.org/(\d+)};

            my $bug = $1;

            my $desc = $link->text;
            $desc =~ s/^([^:]+): //;
            my $package = $1;

            push @{ $self->_cache->{$package} ||= [] },
                Debian::WNPP::Bug->new(
                {   type              => $type,
                    number            => $bug,
                    package           => $package,
                    short_description => $desc,
                    title             => "$type: $package -- $desc",
                }
                );
        }
    }

    $self->_write_cache;
}

=head1 FIELDS

=over

=item cache_file I<path>

The path to the file holding the offline cache of the WNPP lists. If not
specified, no cache is read or written.

=item ttl I<seconds>

The time after which the on-disk cache is considered too old and WNPP pages are
retrieved afresh. Ignored if B<cache_file> is not defined. Defaults to 86400 (1
day).

=item bug_types I<arrayref>

Specified which bug types to retrieve. For example, if you are interested in
ITP and RFP bugs, there is no point in downloading, parsing and storing
ITA/RFA/O bugs. By default all types of bugs are processed.

=back

=head1 METHODS

=over

=item bugs_for_package(I<package>)

Returns a list of bugs matching the given package name. Normally the list would
contain only one bug, but there are no guarantees.

=cut

sub bugs_for_package {
    my ( $self, $package ) = @_;

    if (exists $self->_cache->{ $package }) {
        return @{ $self->_cache->{ $package } };
    }
    return ();
}

=back

=head1 SEE ALSO

=over

=item L<Debian::WNPP::Bug>

=item L<http://www.debian.org/devel/wnpp/>

=back

=head1 AUTHOR AND COPYRIGHT

=over

=item Copyright (C) 2010 Damyan Ivanov <dmn@debian.org>

=back

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

1;
