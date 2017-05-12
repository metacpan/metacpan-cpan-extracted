package Filesys::MakeISO;
use version; $VERSION = qv('0.1.0');

=head1 NAME

Filesys::MakeISO - make iso images (portable)

=head1 VERSION

This document describes Filesys::MakeISO version 0.1.0

=head1 SYNOPSIS

    use Filesys::MakeISO;

    my $iso = Filesys::MakeISO->new;
    $iso->image('image.iso');
    $iso->dir('/path/to/burn');

    $iso->make_iso;

=cut

use strict;
use warnings;

use Carp ();
use Module::Pluggable
    sub_name    => 'drivers',
    search_path => [qw(Filesys::MakeISO::Driver)];

#=head1 DESCRIPTION

=head1 INTERFACE

=head2 drivers

Returns a list of available driver classes. This method is provied by
L<Module::Pluggable>.

=head2 new [PARAMS]

Create a new L<Filesys::MakeISO> object if a suitable driver class is
found. If not C<undef> is returned.

Valid PARAMS are:

=over 4

=item class

Use (only) this driver class.

=back

Additional parameters are passed to the driver classes, for example to
specify the binary location. Look in the C<Filesys::MakeISO::Driver>
namespace for driver classes.

=cut

sub new {
    my ($class, %arg) = @_;

    # which driver classes to try?
    my @driver = ();
    if ($arg{class}) {
        @driver = ($arg{class});
        delete $arg{class};
    }
    else {
        @driver = $class->drivers;
    }

    my $self = undef;
    foreach my $class (@driver) {
        eval "require $class";
        next if $@;
        $self = $class->new(%arg);
        last if $self;
    }

    return $self;
}

=head2 joliet [BOOLEAN]

Get/set Joliet extension (Win32).

=cut

sub joliet {
    my ($self, $joliet) = @_;

    if (defined $joliet) {
        $self->{joliet} = $joliet;
    }

    return $self->{joliet};
}

=head2 rock_ridge [BOOLEAN]

Get/set Rock Ridge extension (Unix).

=cut

sub rock_ridge {
    my ($self, $rock_ridge) = @_;

    if (defined $rock_ridge) {
        $self->{rock_ridge} = $rock_ridge;
    }

    return $self->{rock_ridge};
}

=head2 image [NAME]

Get/set name (and path) of image file.

=cut

sub image {
    my ($self, $image) = @_;

    if (defined $image) {
        $self->{image} = $image;
    }

    return $self->{image};
}

=head2 dir [DIRECTORY]

Get/set directory with files to make an iso of.

=cut

sub dir {
    my ($self, $dir) = @_;

    if (defined $dir) {
        $self->{dir} = $dir;
    }

    return $self->{dir};
}

=head2 make_iso

Create the iso image and save it to L<image|/image>. Return true on success
and false on failure.

=cut

sub _check_params {
    my ($self) = @_;

    Carp::croak("IMAGE missing") unless $self->image;

    Carp::croak("DIR missing") unless $self->dir;

    return 1;
}


1;

=head1 DIAGNOSTICS

=over 4

=item C<< IMAGE missing >>

A call to L<make_iso|/make_iso> without setting an L<image|/image>
L<croaks|Carp/croak> with this message.

=item C<< DIR missing >>

A call to L<make_iso|/make_iso> without setting an L<dir|/dir>
L<croaks|Carp/croak> with this message.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Filesys::MakeISO requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Module::Pluggable>

You need a driver class (and the matching tool) installed. See the
C<Filesys::MakeISO::Driver> namespace for drivers.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Filesys-MakeISO@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Uwe Voelker  C<< uwe.voelker@gmx.de >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Uwe Voelker C<< uwe.voelker@gmx.de >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See C<perldoc perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
