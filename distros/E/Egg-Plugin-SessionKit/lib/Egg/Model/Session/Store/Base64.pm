package Egg::Model::Session::Store::Base64;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base64.pm 256 2008-02-14 21:07:38Z lushe $
#
use strict;
use warnings;
use Storable qw/ nfreeze thaw /;
use MIME::Base64;

our $VERSION= '0.01';

sub store_encode {
	my $self= shift;
	my $data= shift || $self->data;
	\encode_base64( nfreeze( $data ) );
}
sub store_decode {
	my $self= shift;
	my $data= shift || die q{I want decode data.};
	thaw( decode_base64( $$data ) );
}

1;

__END__

=head1 NAME

Egg::Model::Session::Store::Base64 - Encode processing of session data by Base64.

=head1 SYNOPSIS

  package MyApp::Model::Sesion::MySession;
  
  __PACKAGE__->startup(
   .....
   Store::Base64
   );

=head1 DESCRIPTION

It is a component to use it together with Base system component that cannot 
preserve the session data as it is.

To use it, 'Store::Base64' is added to 'startup'.

  __PACKAGE__->startup(
   Base::DBI
   Store::Base64
   );

=head1 METHODS

=head2 store_encode

The result of passing the received session data through 'encode_base64' of 
L<MIME::Base64> is returned by the SCALAR reference.

=head2 store_decode

The result of passing the received Base64 encode ending data through 'decode_base64'
 of L<MIME::Base64> is returned.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session::Manager::TieHash>,
L<MIME::Base64>,
L<Storable>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

