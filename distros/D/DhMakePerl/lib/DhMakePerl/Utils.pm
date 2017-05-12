package DhMakePerl::Utils;

use strict;
use warnings;

our $VERSION = '0.71';

=head1 NAME

DhMakePerl::Utils - helper routines for dh-make-perl and alike

=head1 SYNOPSIS

    use DhMakePerl::Utils qw(is_core_module);

    my $v = is_core_module('Test::More', '1.002');
    my $v = nice_perl_ver('5.010001');

=cut

our @EXPORT_OK = qw(
    find_core_perl_dependency
    apt_cache
    find_cpan_module find_cpan_distribution
    is_core_module
    nice_perl_ver
    split_version_relation
);

use base 'Exporter';

use 5.10.0;

use AptPkg::Cache;
use Module::CoreList ();
use Debian::Dependency;

=head1 FUNCTIONS

None of he following functions is exported by default.

=over

=item apt_cache

Evaluate the creation of an AptPkg::Cache, and return it on success

=cut

sub apt_cache {
    my $apt_cache;

    eval {
        $apt_cache = AptPkg::Cache->new;
    };

    warn "Error initializing AptPkg::Cache: $@" if $@;
    $apt_cache;
}

=item find_cpan_module

Returns CPAN::Module object that corresponds to the supplied argument. Returns
undef if no module is found by CPAN.

If the CPAN module needs to be configured in some way, that should be done
before calling this function.

=cut

sub find_cpan_module {
    my( $name ) = @_;

    my $mod;

    # expand() returns a list of matching items when called in list
    # context, so after retrieving it, we try to match exactly what
    # the user asked for. Specially important when there are
    # different modules which only differ in case.
    #
    # This Closes: #451838
    my @mod = CPAN::Shell->expand( 'Module', '/^' . $name . '$/' );

    foreach (@mod) {
        my $file = $_->cpan_file();
        $file =~ s#.*/##;          # remove directory
        $file =~ s/(.*)-.*/$1/;    # remove version and extension
        $file =~ s/-/::/g;         # convert dashes to colons
        if ( $file eq $name ) {
            $mod = $_;
            last;
        }
    }
    $mod = shift @mod unless ($mod);

    return $mod;
}

=item find_cpan_distribution

Returns CPAN::Distribution object that corresponds to the supplied argument.
Returns undef if no distribution is found by CPAN.

If the CPAN module needs to be configured in some way, that should be done
before calling this function.

=cut

sub find_cpan_distribution {
    my( $name ) = @_;

    $name =~ s/::/-/g;

    return CPAN::Shell->expand( 'Distribution',
        "/\\/$name-[^\\/]+\\.(tar|zip)/" );
}

=item is_core_module I<module>, I<version>

Returns the version of the C<perl> package containing the given I<module> (at
least version I<version>).

Returns C<undef> if I<module> is not a core module.

=cut

sub is_core_module {
    my ( $module, $ver ) = @_;

    my $v = Module::CoreList->first_release($module, $ver);   # 5.009002

    return unless defined $v;

    $v = version->new($v);                              # v5.9.2
    ( $v = $v->normal ) =~ s/^v//;                      # "5.9.2"

    return $v;
}

=item nice_perl_ver I<version_string>

Re-formats perl version to match Debian's perl package versions.

For example C<5.010> (and C<5.01>) is converted to C<5.10>.

=cut

sub nice_perl_ver {
    my( $v ) = @_;

    if( $v =~ /\.(\d+)$/ and $v !~ /\..+\./ ) { # do nothing for 5.9.1
        my $minor = $1;
        if( length($minor) % 3 ) {
            # right-pad with zeroes so that the number of digits after the dot
            # is a multiple of 3
            $minor .= '0' x ( 3 - length($minor) % 3 );
        }

        my $ver = 0 + substr( $minor, 0, 3 );
        if( length($minor) > 3 ) {
            $ver .= '.' . ( 0 + substr( $minor, 3 ) );
        }
        $v =~ s/\.\d+$/.$ver/;

        $v .= '.0' if $v =~ /^\d+\.\d+$/;   # force three-component version
    }

    return $v;
}

=item core_module_perls I<module>[, I<min-version>]

Returns a list of Perl versions that have I<module>. If I<min-version> is
given, the list contains only Perl versions containing I<module> at least
version I<min-version>.

=cut

sub core_module_perls {
    my( $module, $version ) = @_;

    my @ret;

    $version = version->new($version) if $version;

    for my $v(
        sort keys %Module::CoreList::version ){

        # Module::CoreList::version includes families (i.e. "5") as well as
        # full versions, skip the families.
        next unless ($v =~ /^\d+\.\d+(?:\.|$)/);

        next unless exists $Module::CoreList::version{$v}{$module};

        my $found = $Module::CoreList::version{$v}{$module};

        push @ret, $v
            if not $version
                or $found and version->new($found) >= $version;
    }

    return @ret;
}

=item find_core_perl_dependency( $module[, $version] )

return a dependency on perl containing the required module version. If the
module is not available in any perl released by Debian, return undef.

=cut

our %debian_perl = (
    '5.8'   => {
        min => Dpkg::Version->new('5.8.8'),
        max => Dpkg::Version->new('5.8.8'),
    },
    '5.10'  => {
        min => Dpkg::Version->new('5.10.0'),
        max => Dpkg::Version->new('5.10.1'),
    },
);

sub find_core_perl_dependency {
    my ( $module, $version ) = @_;

    if ( $module eq 'perl' ) {
        return Debian::Dependency->new('perl') unless $version;

        return Debian::Dependency->new( 'perl', nice_perl_ver($version) );
    }

    my $perl_dep;

    my @perl_releases = core_module_perls( $module, $version );

    for my $v (@perl_releases) {
        $v = nice_perl_ver($v);

        $v =~ /^(\d+\.\d+)(?:\.|$)/;
        my $major = $1 or die "[$v] is a strange version";

        # we want to avoid depending on things like 5.8.9 which aren't in
        # Debian and can contain stuff newer than in 5.10.0
        if (    $debian_perl{$major}
            and $debian_perl{$major}{max} >= $v )
        {
            return Debian::Dependency->new( 'perl', $v );
        }
    }

    # not a core module
    return undef;
}

=item split_version_relation I<string>

Splits the string, typically found in dependency fields' values in CPAN META
into relation and version. If no relation is found in the string, C<< >= >> is
assumed.

Returns a list of relation and version. The relation is suitable for using in
Debian package dependency version requirements.

For example

=over

=item split_version_relation('0.45') returns ( '>=', '0.45' )

=item split_version_relation('< 0.56') returns ( '<<', '0.56' )

=back

=cut

sub split_version_relation {
    my $in = shift;

    $in =~ s/^\s*([<>=!])\s*//;

    my $rel = $1 // '>=';

    $rel = '>>' if  $rel eq '>';

    $rel = '<<' if $rel eq '<';

    return ( $rel, $in );
}

=back

=head1 COPYRIGHT & LICENSE

=over

=item Copyright (C) 2008, 2009, 2010 Damyan Ivanov <dmn@debian.org>

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

1; # End of DhMakePerl
