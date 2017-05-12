package Egg::Manager::View;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: View.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.00';

my $handler= 'Egg::Manager::View::handler';

sub init_view {
	my($class)= @_;
	$handler->initialize('view');
	$class->mk_classdata('view_manager') unless $class->can('view_manager');
	$class;
}
sub setup_view {
	my($e)= @_;
	$e->view_manager($handler->new($e))->setup_manager;
}
sub view {
	shift->view_manager->context(@_);
}
sub is_view {
	my $e= shift;
	my $label= shift || return 0;
	$e->view_manager->regists->{lc($label)} ? 1: 0;
}
sub _prepare {
	my($e)= @_;
	$e->view_manager->_prepare($e);
	$e->next::method;
}
sub _finalize {
	my($e)= @_;
	$e->view_manager->_finalize($e);
	$e->next::method;
}
sub _finalize_error {
	my($e)= @_;
	$e->view_manager->_finalize_error($e);
	$e->next::method;
}
sub _output {
	my($e)= @_;
	$e->view_manager->_output($e);
	$e->next::method;
}
sub _finish {
	my($e)= @_;
	$e->view_manager->_finish($e);
	$e->next::method;
}

package Egg::Manager::View::handler;
use base qw/ Egg::Manager /;

1;

__END__

=head1 NAME

Egg::Manager::View - View manager for Egg.

=head1 DESCRIPTION

It is a module to offer Egg the view function. 

When the view_manager method of Egg is called, the handler class for the view
is returned.

=head1 CONFIGURATION

The configuration of the model is done to 'VIEW' by the ARRAY form.

  VIEW => [
    [ Mason => {
       ...........
       ....
       } ],
    [ HT => {
       ...........
       ....
       } ],
    ],

=head1 METHODS

Because this class is registered in @ISA of the project, the method can be used
directly from the object of the project.

  $project->view( ... );

=head2 init_view

When starting for the view, it initializes it.

=head2 setup_view

The setup for the view is done.

=head2 view ([LABEL_STRING])

The object of the specific view specified with LABEL_STRING is returned.

When LABEL_STRING is omitted, the object of the view of default is restored.

  my $mason= $e->view;
     or
  my $mason= $e->view('mason');

The setting of the first element set to the configuration becomes default.

It is L<Egg::View::Mason> in the view. With L<Egg::View::HT> However, Ts belongs.

=head2 is_view ([LABEL_STRING])

If the view corresponding to LABEL_STRING can be used, true is returned.

  unless ($e->is_model('mason')) {
     die q{ mason is not active. };
  }

=head1 HANDLER METHODS

It is view manager's main body.

L<Egg::Manager> is succeeded to and the main function is used.

The method is called by way of view_manager.

This class is succeeding to L<Egg::Manager> and it doesn't have a peculiar method.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Manager>,
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

