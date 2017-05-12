package Egg::View::TT;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: TT.pm 237 2008-02-03 13:42:55Z lushe $
#
use strict;
use warnings;

our $VERSION = '3.01';

sub _setup {
	my($class, $e)= @_;
	my $c= "$e->{namespace}::View::TT"->config;
	$c->{ABSOLUTE}= 1 unless exists($c->{ABSOLUTE});
	$c->{RELATIVE}= 1 unless exists($c->{RELATIVE});
	$c->{INCLUDE_PATH} ||= [ $e->config->{dir}{template} ];
	$c->{TEMPLATE_EXTENSION} ||= '.'. $e->config->{template_extention};
	$class->next::method($e);
}

package Egg::View::TT::handler;
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Egg::View /;
use Template;
use Egg::View::Template::GlobalParam;

sub new {
	my $view= shift->SUPER::new(@_);
	$view->params({ Egg::View::Template::GlobalParam::set($view->e) });
	$view;
}
sub render {
	my $view= shift;
	my $tmpl= shift || return (undef);
	my $tt= do {
		my $class= $view->e->namespace. '::View::TT';
		my %option= (
		  %{ $class->config },
		  %{ $_[0] ? ($_[1] ? {@_}: $_[0]): {} },
		  );
		if ($option{TIMER}) {
			require Template::Timer;
			$option{CONTEXT}= Template::Timer->new(%option);
		}
		Template->new(\%option) || die Template->error;
	  };
	my $body;
	$tt->process($tmpl, {
	  e => $view->{e},
	  s => $view->{e}->stash,
	  p => $view->params,
	  }, \$body) || die $tt->error;
	\$body;
}
sub output {
	my $view= shift;
	my $tmpl= shift || $view->template || croak q{ I want template. };
	$view->e->response->body( $view->render($tmpl, @_) );
}

1;

__END__

=head1 NAME

Egg::View::TT - View for TemplateToolKit.

=head1 SYNOPSIS

  __PACKAGE__->egg_startup(
   ...
   .....
   VIEW=> [
    [ 'TT' => {
     INCLUDE_PATH=> ['/path/to/root'],
      } ],
    ],
  
   );
  
  # The VIEW object is acquired.
  my $view= $e->view('TT');
  
  # It outputs it specifying the template.
  my $content= $view->render('hoge.tt', \%option);

=head1 DESCRIPTION

It is a view for TemplateToolKit.

L<http://www.template-toolkit.org/>

Please add TT to the setting of VIEW to make it use.

   VIEW=> [
    [ 'TT' => { ... TemplateToolKit option. (HASH) }
    ],

The object that can be used is as follows from the template.

  e ... Object of project.
  s ... $e->stash
  p ... $e->view('TT')->params

=head1 HANDLER METHODS

L<Egg::View> has been succeeded to.

=head2 new

Constructor.

L<Egg::View::Template::GlobalParam> is set up.

  my $view= $e->view('TT');

=head2 render ([TEMPLATE_STR], [OPTION])

The result of evaluating the template of TEMPLATE_STR with TemplateToolKit is
returned by the SCALAR reference.

OPTION is an option to pass to TemplateToolKit.
OPTION overwrites a set value of the configuration.

  my $body= $view->render( 'foo.tt', 
    ..........
    ....
    );

=head2 output ([TEMPLATE], [OPTION])

The result of the render method is set in $e-E<gt>response-E<gt>body.

When TEMPLATE is omitted, it acquires it from $view-E<gt>template.

OPTION is passed to the render method as it is.

  $view->output;

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View>,
L<Egg::View::Template::GlobalParam>,
L<Template>,
L<http://www.template-toolkit.org/>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

