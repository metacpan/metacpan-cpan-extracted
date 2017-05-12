package Debian::DpkgLists;

use strict;
use warnings;

our $VERSION = '0.71';

use Cwd;

=head1 NAME

Debian::DpkgLists - scan /var/lib/dpkg/info/*.list for files/patterns

=head1 SYNOPSIS

    my @packages = Debian::DpkgLists->scan_full_path('/full/file/path');
    my @packages = Debian::DpkgLists->scan_partial_path('file/path');
    my @packages = Debian::DpkgLists->scan_pattern(qr{freedom$});
    my @packages = Debian::DpkgLists->scan_perl_mod('Some::Module');

=head1 DESCRIPTION

B<Debian::DpkgLists> is a module for easy searching of L<dpkg(1)>'s package
file lists. These are located in F</var/lib/dpkg/info/*.list> and contain a
simple list of full file names (including the leading slash).

There are a couple of different class methods for searching by full or partial
path, a regular expression or a Perl module name.

Note that dpkg's file lists represent only dpkg's idea of what is installed on
the system. If you want to also search in packages, available from the Debian
archive but not installed locally, see L<Debian::AptContents>.

=cut

sub _cat_lists
{
    my ( $class, $callback ) = @_;
    while ( defined( my $f = </var/lib/dpkg/info/*.list> ) ) {
        my $pkg = $f;
        $pkg =~ s{^/var/lib/dpkg/info/}{};
        $pkg =~ s/\.list$//;
        open my $fh, '<', $f or die "open($f): $!\n";
        while ( defined( my $l = <$fh> ) ) {
            chomp $l;
            &$callback( $pkg, $l );
        }
    }
}

=head1 CLASS-METHODS

=over

=item scan_full_path ( I<path> )

Scans dpkg file lists for files, whose full path is equal to I<path>. Use when
you have the full path of the file you want, like C</usr/bin/perl>.

Returns a (possibly empty) list of packages containing I<path>.

=cut

sub scan_full_path
{
    my ( $class, $path ) = @_;

    my %found;
    $class->_cat_lists(
        sub {
            $found{ $_[0] } = 1 if $_[1] eq $path;
        }
    );

    return sort keys %found;
}

=item scan_partial_path ( I<path> )

Scans dpkg file lists for files, whose full path ends with I<path>. Use when
you only care about the file name or other trailing portion of the full path
like C<bin/perl> (matches C</usr/bin/perl> and C</sbin/perl>).

Returns a (possibly empty) list of packages containing files whose full path
ends with I<path>.

=cut

sub scan_partial_path {
    my ( $class, $path ) = @_;

    my $start = -length($path);
    my %result;
    $class->_cat_lists(
        sub {
            $result{ $_[0] } = 1 if substr( $_[1], $start ) eq $path;
        }
    );

    return sort keys %result;
}

=item scan_pattern ( I<pattern> )

Scans dpkg file lists for files, whose full path matched I<pattern>.

Returns a (possibly empty) list of packages containing files whose full path
matches I<pattern>.

=cut

sub scan_pattern {
    my ( $class, $pat ) = @_;

    my %result;
    $class->_cat_lists(
        sub {
            $result{ $_[0] } = 1 if $_[1] =~ $pat;
        }
    );

    return sort keys %result;
}

=item scan_perl_mod ( I<Module::Name> )

Scans dpkg file lists for files, corresponding to given I<Module::Name>. This
is a shorthand method for L</scan_pattern> with a pattern that matches
C</Module/Name.pm$> in all directories in C<@INC>.

Returns a (possibly empty) list of packages containing possible I<Module::Name>
files.

=cut

sub scan_perl_mod {
    my ( $class, $mod ) = @_;

    $mod =~ s{::}{/}g;
    $mod .= ".pm" unless $mod =~ /\.pm$/;

    my @dirs = grep { defined and m{^/} and not m{/usr/local/} }
        map { Cwd::realpath($_) } @INC;
    my $re
        = "^(?:"
            . join( '|', map( quotemeta($_), @dirs ) ) . ")/"
            . quotemeta($mod) . "\$";
    $re = qr($re);

    return $class->scan_pattern($re);
}

=back

=head1 AUTHOR

=over 4

=item Damyan Ivanov <dmn@debian.org>

=back

=head1 COPYRIGHT & LICENSE

=over 4

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
