package Linux::Info::KernelRelease;
use strict;
use warnings;
use Carp qw(confess carp);
use parent 'Class::Accessor';

our $VERSION = '2.01'; # VERSION

my @_attribs = qw(raw mainline_version abi_bump flavour major minor patch);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(@_attribs);

=pod

=head1 NAME

Linux::Info::KernelRelease - parses and provide Linux kernel detailed information

=head1 SYNOPSIS

Getting the current kernel information:

    my $current = Linux::Info::KernelRelease->new( Linux::Info::SysInfo->new->get_release );

Or using a given kernel information:

    my $kernel = Linux::Info::KernelRelease->new('2.4.20-0-generic');

Now you can compare both:

    if ($current > $kernel) {
        say 'System kernel was upgraded!';
    }

=head1 DESCRIPTION

This module parses the Linux kernel information obtained from sources like the
C<uname> command and others.

This make it easier to fetch each information piece of information from the
string and also to compare different kernel versions, since instances of this
class overload operators like ">=", ">" and "<".

=head1 METHODS

=head2 new

Creates a new instance.

Expects as parameter the kernel release information (like from C<uname -r>
output). This is required.

Optionally, you can pass the kernel mainline information if available (as from
F</proc/version_signature> on Ubuntu Linux). With this parameter, more
information will be available.

=cut

sub new {
    my ( $class, $release, $mainline ) = @_;

    confess "Must receive a string as kernel release information"
      unless ($release);

    # 6.5.0-28-generic
    confess "The received string for release '$release' is invalid"
      unless ( $release =~ /^\d\.\d+\.\d+(\-\d+\-[a-z]+)?/ );

    my @pieces = split( '-', $release );

    my $self = {
        raw      => $release,
        abi_bump => $pieces[-2],
        flavour  => $pieces[-1]
    };

    $self->{mainline_version} =
      ($mainline) ? ( split( /\s/, $mainline ) )[-1] : $pieces[0];
    bless $self, $class;
    $self->_parse_version();
    return $self;
}

=head2 get_raw

Returns the raw information stored, as passed to the C<new> method.

=head2 get_mainline_version

Returns the mainline kernel-version.

=head2 get_abi_bump

Returns the application binary interface (ABI) bump from the kernel.

=head2 get_flavour

Returns the kernel flavour parameter.

=head2 get_major

From the version, returns the integer corresponding to the major number.

=head2 get_minor

From the version, returns the integer corresponding to the minor number.

=head2 get_patch

From the version, returns the integer corresponding to the patch number.

=cut

sub _parse_version {
    my $self = shift;
    my ( $major, $minor, $patch ) = split( /\./, $self->{mainline_version} );
    $self->{major} = $major;
    $self->{minor} = $minor;
    $self->{patch} = $patch;
}

sub _validate_other {
    my ( $self, $other ) = @_;
    my $class     = ref $self;
    my $other_ref = ref $other;

    confess 'The other parameter must be a reference' if ( $other_ref eq '' );
    confess 'The other instance must be a instance of'
      . $class
      . ', not '
      . $other_ref
      unless ( $other->isa($class) );
}

sub _ge_version {
    my ( $self, $other ) = @_;
    $self->_validate_other($other);

    return 1 if ( $self->{major} > $other->get_major );
    return 0 if ( $self->{major} < $other->get_major );
    return 1 if ( $self->{minor} > $other->get_minor );
    return 0 if ( $self->{minor} < $other->get_minor );
    return 1 if ( $self->{patch} > $other->get_patch );
    return 0 if ( $self->{patch} < $other->get_patch );
    return 1;
}

sub _gt_version {
    my ( $self, $other ) = @_;
    $self->_validate_other($other);

    return 1 if ( $self->{major} > $other->get_major );
    return 0 if ( $self->{major} < $other->get_major );
    return 1 if ( $self->{minor} > $other->get_minor );
    return 0 if ( $self->{minor} < $other->get_minor );
    return 1 if ( $self->{patch} > $other->get_patch );
    return 0 if ( $self->{patch} < $other->get_patch );
    return 0;
}

sub _lt_version {
    my ( $self, $other ) = @_;
    $self->_validate_other($other);

    return 0 if ( $self->{major} > $other->get_major );
    return 1 if ( $self->{major} < $other->get_major );
    return 0 if ( $self->{minor} > $other->get_minor );
    return 1 if ( $self->{minor} < $other->get_minor );
    return 0 if ( $self->{patch} > $other->get_patch );
    return 1 if ( $self->{patch} < $other->get_patch );
    return 0;
}

use overload
  '>=' => '_ge_version',
  '>'  => '_gt_version',
  '<'  => '_lt_version';

=head1 SEE ALSO

=over

=item *

https://ubuntu.com/kernel

=item *

https://www.unixtutorial.org/use-proc-version-to-identify-your-linux-release/

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 of Alceu Rodrigues de Freitas Junior,
E<lt>glasswalk3r@yahoo.com.brE<gt>

This file is part of Linux Info project.

Linux-Info is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Linux-Info is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Linux Info. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
