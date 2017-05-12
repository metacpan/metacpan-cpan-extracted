package Egg::Request::Apache;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Apache.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Egg::Request::handler /;

our $VERSION= '3.00';

sub _init_handler {
	my($class, $e)= @_;
	my $p= $e->namespace;
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{$e->namespace. '::handler'}= sub : method { shift->run(@_) };
	@_;
}
sub output {
	my $req   = shift;
	my $header= shift || croak q{ I want response header. };
	my $body  = shift || croak q{ I want response body.   };
	$req->r->send_cgi_header($$header);
	$req->r->print($$body);
}

1;

__END__

=head1 NAME

Egg::Request::Apache - Request class for mod_perl.

=head1 DESCRIPTION

It is a base class for
 L<Egg::Request::Apache::MP13>,
 L<Egg::Request::Apache::MP19>,
 L<Egg::Request::Apache::MP20>.

=head1 HANDLER METHODS

=head2 output ([HEADER_REF], [BODY_REF])

Override does the method of Egg::Request::handler.

The output and print of the request header are done on the object side of mod_perl.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<Egg::Request::Apache::MP13>,
L<Egg::Request::Apache::MP19>,
L<Egg::Request::Apache::MP20>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

