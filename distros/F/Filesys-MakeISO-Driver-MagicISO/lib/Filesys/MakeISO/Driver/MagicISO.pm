package Filesys::MakeISO::Driver::MagicISO;
use version; $VERSION = qv('0.0.1');

=head1 NAME

Filesys::MakeISO::Driver::MagicISO - make iso images with MagicISO (Win32)

=head1 VERSION

This document describes Filesys::MakeISO::Driver::MagicISO version 0.0.1

=head1 SYNOPSIS

    use Filesys::MakeISO;

    my $iso = Filesys::MakeISO->new(
                class        => 'Filesys::MakeISO::Driver::MagicISO',
                magiciso_bin => '/path/to/miso.exe',
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

=head1 DESCRIPTION

See http://www.magiciso.com/

=head1 INTERFACE

=head2 new [PARAMS]

Constructor. Returns C<undef> if no C<MagicISO> executable is found.

Valid PARAMS are:

=over 4

=item magiciso_bin

Location (path and filename) of the C<MagicISO> binary. The command line
version is called C<miso.exe>.

=back

=cut

sub new {
    my ($class, %arg) = @_;
    my $self = bless({}, ref($class) || $class);

    # find MagicISO binary
    my $bin = delete $arg{magiciso_bin} || File::Which::which('miso.exe');
    return undef unless $bin;

    # executable?
    return undef unless -x $bin;

    $self->{magiciso_bin} = $bin;

    return $self;
}

=head2 make_iso

Create image, specific for MagicISO.

=cut

sub make_iso {
    my ($self) = @_;

    # check params
    $self->_check_params;

    # delete old image
    unlink($self->image);

    my @cmd = ($self->{magiciso_bin},
               $self->image,
               $self->rock_ridge ? ('-ar') : ('-rr'),
               $self->joliet     ? ('-aj') : ('-rj'),
               '-a', $self->dir,
               '-py',
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
C<bug-Filesys-MakeISO-Driver-MagicISO@rt.cpan.org>, or through the
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
