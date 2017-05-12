package Egg::Model::Session::Store::UUencode;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: UUencode.pm 256 2008-02-14 21:07:38Z lushe $
#
use strict;
use warnings;
use Storable qw/ nfreeze thaw /;
use Convert::UU qw/ uudecode uuencode /;

our $VERSION= '0.01';

sub store_encode {
	my $self= shift;
	my $data= shift || $self->data;
	\uuencode( nfreeze( $data ) );
}
sub store_decode {
	my $self= shift;
	my $data= shift || die q{I want decode data.};
	thaw( uudecode( $$data ) );
}

1;

__END__

=head1 NAME

Egg::Model::Session::Store::UUencode - Encode processing of session data by UUencode.

=head1 SYNOPSIS

  package MyApp::Model::Sesion::MySession;
  
  __PACKAGE__->startup(
   .....
   Store::UUencode
   );

=head1 DESCRIPTION

It is a component to use it together with Base system component that cannot 
preserve the session data as it is.

To use it, 'Store::UUencode' is added to 'startup'.

  __PACKAGE__->startup(
   Base::DBI
   Store::UUencode
   );

=head1 METHODS

=head2 store_encode

The result of passing the received session data through 'uuencode' of 
L<Convert::UU> is returned by the SCALAR reference.

=head2 store_decode

The result of passing the received Base64 encode ending data through 'uudecode'
 of L<Convert::UU> is returned.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session::Manager::TieHash>,
L<Convert::UU>,
L<Storable>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

