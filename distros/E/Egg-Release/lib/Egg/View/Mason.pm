package Egg::View::Mason;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Mason.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.00';

sub _setup {
	my($class, $e)= @_;
	my $c= "$e->{namespace}::View::Mason"->config;
	$c->{comp_root} ||= [ 'main' => $e->config->{template_path}[0] ];
	$c->{data_dir}  ||= $e->config->{dir}{tmp};
	$class->next::method($e);
}

package Egg::View::Mason::handler;
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Egg::View /;
use HTML::Mason;
use Egg::View::Template::GlobalParam;

sub new {
	my $view= shift->SUPER::new(@_);
	$view->params({ Egg::View::Template::GlobalParam::set($view->e) });
	$view;
}
sub render {
	my $view = shift;
	my $tmpl = shift || return(undef);
	   $tmpl =~m{^[^/]} and $tmpl= "/$tmpl";
	my $args = $_[0] ? ($_[1] ? {@_}: $_[0]): {};
	my $class= $view->e->namespace. '::View::Mason';
	my $body;
	my $mason= HTML::Mason::Interp->new(
	  %{$class->config}, %$args,
	  out_method    => \$body,
	  allow_globals => [qw/$e $s $p/],
	  );
	$mason->set_global(@$_) for (
	  [ '$e' => $view->{e} ],
	  [ '$s' => $view->{e}->stash ],
	  [ '$p' => $view->params ],
	  );
	$mason->exec($tmpl);
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

Egg::View::Mason - View for HTML::Mason 

=head1 SYNOPSIS

  __PACKAGE__->egg_startup(
    ...
    .....
  
  VIEW=> [
    [ 'Mason' => {
      comp_root=> [
        [ main   => '/path/to/root' ],
        [ private=> '/path/to/comp' ],
        ],
      data_dir=> '/path/to/temp',
      ... other HTML::Mason option.
      } ],
    ],
  
   );
  
  # The VIEW object is acquired.
  my $view= $e->view('Mason');
  
  # It outputs it specifying the template.
  my $content= $view->render('hoge.tt', \%option);

=head1 DESCRIPTION

It is a view to use the template of HTML::Mason.

Please add Mason to the setting of VIEW to make it use.

  VIEW => [
    [ Mason => { ... HTML::Mason option. (HASH) } ],
    ],

The global variable that can be used is as follows from the template.

  $e ... Object of project.
  $s ... $e->stash
  $p ... $e->view('Mason')->params
  $m ... Object of HTML::Mason.

=head1 HANDLER METHODS

L<Egg::View> has been succeeded to.

=head2 new

Constructor.

L<Egg::View::Template::GlobalParam> is set up.

  my $view= $e->view('Mason');

=head2 render ([TEMPLATE_STR], [OPTION])

It is L<HTML::Mason> as for the template of TEMPLATE_STR.
The result of evaluating is returned by the SCALAR reference.

OPTION is HTML::Mason?. It is an option to pass. OPTION overwrites a set value
of the configuration.

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
L<HTML::Mason>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

