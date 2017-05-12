package Egg::Request::CGI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CGI.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use CGI;
use Carp 'croak';
use base qw/ Egg::Request::handler /;

our $VERSION= '3.01';

sub _setup_request {
	my($class, $e, $c, $g)= @_;
	my $conf= $c->{request} || {};
	if (my $max= $conf->{POST_MAX} || $ENV{POST_MAX}) { $CGI::POST_MAX= $max }
	if (my $dup= $conf->{DISABLE_UPLOADS}) { $CGI::DISABLE_UPLOADS= $dup }
	if (my $tmp= $conf->{TMPDIR} || $conf->{TEMP_DIR}
	   || $ENV{TMPDIR} || $ENV{TEMP_DIR}) { $CGITempFile::TMPDIRECTORY= $tmp }
	$class->SUPER::_setup_request($e, $c, $g);
}
sub new {
	my($class, $e, $r)= @_;
	my $req= $class->SUPER::new($e, $r);
	$req->r( CGI->new($r) );
#	$req->r( Egg::Request::CGI::handler->new($r) );
	$req;
}
sub parameters {
	$_[0]->{parameters} ||= $_[0]->r->Vars;
}

package Egg::Request::CGI::handler;
use strict;
our @ISA= 'CGI';

1;

__END__

=head1 NAME

Egg::Request::CGI - Request processing by CGI.pm

=head1 DESCRIPTION

The WEB request is processed by CGI.pm.

This module is loaded by L<Egg::Request>.

And, Egg::Request::handler is succeeded to. 

=head1 HANDLER METHODS

=head2 new

Constructor.

=head2 parameters

CGI->Vers is relaid.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<CGI>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

