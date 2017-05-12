package Filesys::MakeISO::Driver::Mkisofs;
use version; $VERSION = qv('0.0.1');

=head1 NAME

Filesys::MakeISO::Driver::Mkisofs - make iso images with mkisofs

=head1 VERSION

This document describes Filesys::MakeISO::Driver::Mkisofs version 0.0.1

=head1 SYNOPSIS

    use Filesys::MakeISO;

    my $iso = Filesys::MakeISO->new(
                class       => 'Filesys::MakeISO::Driver::Mkisofs',
                mkisofs_bin => '/usr/bin/mkisofs',
                                   );
    $iso->image('image.iso');
    $iso->dir('/path/to/burn');

    $iso->make_iso;

=cut

use strict;
use warnings;

use File::Which ();
use IPC::Run3   ();

use base 'Filesys::MakeISO';

#=head1 DESCRIPTION

=head1 INTERFACE

=head2 new [PARAMS]

Constructor. Returns C<undef> if no C<mkisofs> executable is found.

Valid PARAMS are:

=over 4

=item mkisofs_bin

Location (path and filename) of the C<mkisofs> binary.

=back

=cut

sub new {
    my ($class, %arg) = @_;
    my $self = bless({}, ref($class) || $class);

    # find mkisofs binary
    my $bin = delete $arg{mkisofs_bin} || File::Which::which('mkisofs');
    return undef unless $bin;

    # executable?
    return undef unless -x $bin;

    $self->{mkisofs_bin} = $bin;

    return $self;
}

=head2 make_iso

Create image, specific for mkisofs.

=cut

sub make_iso {
    my ($self) = @_;

    # check params
    $self->_check_params;

    my @cmd = ($self->{mkisofs_bin},
               $self->rock_ridge ? ('-r') : (),
               $self->joliet     ? ('-J') : (),
               '-o', $self->image,
               $self->dir,
              );

    return IPC::Run3::run3(\@cmd, \undef, \undef, \undef);
}


1;

=head1 DEPENDENCIES

L<File::Which>, L<IPC::Run3>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Filesys-MakeISO-Driver-Mkisofs@rt.cpan.org>, or through the
web interface at L<http://rt.cpan.org>.

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
