package Egg::View::Template::GlobalParam;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: GlobalParam.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.00';

our %param= ();

sub set {
	my($e)= @_;
	(
	  page_title=> sub { $e->page_title },
	  remote_addr=> sub { $e->req->addr },
	  content_type=> sub {
		$e->req->content_type
		|| $e->config->{content_type} || 'text/html';
	    },
	  content_language=> sub {
		$e->req->content_language
		|| $e->config->{content_language} || '';
	    },
	  %param
	);
}

1;

__END__

=head1 NAME

Egg::View::Template::GlobalParam? - General parameter for template.

=head1 SYNOPSIS

  use base qw/ Egg::View /;
  use Egg::View::Template::GlobalParam;
  
  sub new {
     my $view= shift->SUPER::new(@_);
     $view->params({ Egg::View::Template::GlobalParam->set($view->e) });
  }

=head1 DESCRIPTION

For global parameter setting for template.

A global original parameter can be added from the controller etc. by setting %param.

  use Egg::View::Template::GlobalParam;
  
  %Egg::View::Template::GlobalParam::param= (
    hoge => 'booo',
    zuuu => sub { 'banban' },
    );

=head1 METHODS

=head2 set ([PROJECT_CONTEXT])

The content of the set parameter is returned.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View>,
L<Egg::View::Mason>, 
L<Egg::View::HT>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

