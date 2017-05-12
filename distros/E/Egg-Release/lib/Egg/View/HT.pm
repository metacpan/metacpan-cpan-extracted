package Egg::View::HT;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: HT.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.00';

sub _setup {
	my($class, $e)= @_;
	"$e->{namespace}::View::HT"->config->{path} ||= $e->config->{template_path};
	$class->next::method($e);
}

package Egg::View::HT::handler;
use strict;
use warnings;
use HTML::Template;
use Egg::View::Template::GlobalParam;
use base qw/ Egg::View /;
use Carp qw/ croak /;

sub new {
	my $view= shift->SUPER::new(@_);
	$view->params({ Egg::View::Template::GlobalParam::set($view->e) });
	$view->{filter}   = [];
	$view->{associate}= [$view, $view->e->request];
	$view;
}
sub push_filter    { shift->_push('filter', @_) }
sub push_associate { shift->_push('associate', @_) }

sub render {
	my $option= shift->_create_option(@_);
	my $tmpl= HTML::Template->new(%$option);
	my $body= $tmpl->output;
	return \$body;
}
sub output {
	my $view= shift;
	my $tmpl= shift || $view->template || croak q{ I want template. };
	$view->e->response->body( $view->render($tmpl, @_) );
}
sub _push {
	my($view, $type)= splice @_, 0, 2;
	if (@_ > 1) {
		splice @{$view->{$type}}, scalar(@{$view->{$type}}), 0, @_;
	} else {
		push @{$view->{$type}}, $_[0];
	}
}
sub _create_option {
	my $view= shift;
	my $tmpl= shift || return (undef);
	my $args= $_[0] ? ($_[1] ? {@_}: $_[0]): {};
	my $params= $view->params;
	while (my($key, $value)= each %{$view->e->stash}) {
		$params->{$key} ||= $value;
	}
	my $class = $view->e->namespace. "::View::HT";
	my %option= ( %{$class->config}, %$args );
	if (ref($tmpl) eq 'SCALAR') {
		$option{scalarref}= $tmpl;
		$option{cache}    = 0;
	} elsif (ref($tmpl) eq 'ARRAY') {
		$option{arrayref}= $tmpl;
	} else {
		$option{filename}= $tmpl;
	}
	$option{associate}= $view->{associate};
	$option{filter}= $view->{filter} if @{$view->{filter}};
	\%option;
}

1;

__END__

=head1 NAME

Egg::View::HT - View for HTML::Template. 

=head1 SYNOPSIS

  __PACKAGE__->egg_startup(
   .....
   ...
   VIEW => [
      [ Template => {
        path  => [qw{ <$e.template> <$e.comp> }],
        cache             => 1,
        global_vars       => 1,
        die_on_bad_params => 0,
        ... etc.
        } ],
      ],
  
    );
  
  # The VIEW object is acquired.
  my $view= $e->view('HT');
  
  # Associate is set.
  $view->push_associate( $object );
  
  # Filter is set.
  $view->push_filter( $filter );
  
  # It outputs it specifying the template.
  my $content= $view->render('hoge.tmpl', \%option);

=head1 DESCRIPTION

L<HTML::Template> it is a view to drink and to use the template.

Please add HT to the setting of VIEW to make it use.

  VIEW => [
    [ HT => { ... HTML::Template option. (HASH) } ],
    ],

=head1 HANDLER METHODS

L<Egg::View> has been succeeded to.

=head2 new

Constructor.

L<Egg::View::Template::GlobalParam> is set up.

The object and $e-E<gt>request of associate are set.

  my $view= $e->view('HT');

=head2 push_filter ([FILTER])

FILTER is added to filter.

  $view->push_filter(sub { ... filter code });

=head2 push_associate ([CONTEXT])

CONTEXT is added to associate.

  $view->push_associate($context);

=head2 render ([TEMPLATE_STR], [OPTION])

It is L<HTML::Template> as for the template of TEMPLATE_STR.
The result of evaluating is returned by the SCALAR reference.

OPTION is L<HTML::Template>. It is an option to pass.
OPTION overwrites a set value of the configuration.

  my $body= $view->render( 'foo.tt', 
    ..........
    ....
    );

=head2 output ([TEMPLATE_STR], [OPTION])

The result of the render method is set in $e-E<gt>response-E<gt>body.

When TEMPLATE is omitted, it acquires it from $view-E<gt>template.

OPTION is passed to the render method as it is.

  $view->output;

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View>,
L<Egg::View::Template::GlobalParam>,
L<HTML::Template>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

