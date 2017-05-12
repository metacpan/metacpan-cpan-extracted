package Egg::Request::Apache::MP20;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: MP20.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Apache2::Request     ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::RequestIO   ();
use APR::Pool;
use base qw/ Egg::Request::Apache /;

our $VERSION= '3.00';

sub new {
	my($class, $e, $r)= @_;
	my $req = $class->SUPER::new($e);
	my $conf= $req->e->config->{request} ||= {};
	$req->r( Apache2::Request->new($r, %$conf) );
	$req;
}

1;

__END__

=head1 NAME

Egg::Request::Apache::MP20 - mod_perl2.0 for Egg request.

=head1 DESCRIPTION

It is a request class for mod_perl2.0.

This module is read by the automatic operation if L<Egg::Request> investigates
the environment and it is necessary. Therefore, it is not necessary to read
specifying it.

=head1 METHODS

=head2 new

The object is received from the constructor of the succession class, 
and L<Apache2::Request> object is defined in 'r' method.

=head1 SEE ALSO

L<Apache2::Request>,
L<Egg::Request>,
L<Egg::Request::Apache>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
