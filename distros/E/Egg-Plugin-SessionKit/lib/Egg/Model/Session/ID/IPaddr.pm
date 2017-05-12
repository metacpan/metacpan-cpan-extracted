package Egg::Model::Session::ID::IPaddr;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: IPaddr.pm 256 2008-02-14 21:07:38Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.01';

sub make_session_id { $_[0]->e->request->address }
sub get_bind_data   { $_[0]->e->request->address }
sub set_bind_data   { 1 }

1;

__END__

=head1 NAME

Egg::Model::Session::ID::IPaddr - Internet Protocol address is used for session ID.

=head1 SYNOPSIS

  package MyApp::Model::Sesion;
  
  __PACKAGE__->startup(
   .....
   ID::IPaddr
   );

=head1 DESCRIPTION

It is a component module to use Internet Protocol address for session ID.

It uses it specifying 'IP::IPAddr' for 'startup'.

The connected client is thing accessed by different Internet Protocol address at
the connection in the ISP contract.

Therefore, please note that there is a possibility of sharing utter stranger's
session.

We will recommend the thing used using it together with the following plugins.

L<Egg::Model::Session::Plugin::AbsoluteIP>,
L<Egg::Model::Session::Plugin::AgreeAgent>,
L<Egg::Model::Session::Plugin::CclassIP>,

=head1 METHODS

=head2 make_session_id

The result of $e-E<gt>request-E<gt>address is returned.

=head2 get_bind_data

The result of $e-E<gt>request-E<gt>address is returned.

=head2 set_bind_data

Nothing is done.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session::Manager::TieHash>,
L<Egg::Request>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

