package Egg::Manager::Model;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Model.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.00';

my $handler= 'Egg::Manager::Model::handler';

sub init_model {
	my($class)= @_;
	$handler->initialize('model');
	$class->mk_classdata('model_manager') unless $class->can('model_manager');
	$class;
}
sub setup_model {
	my($e)= @_;
	$e->model_manager($handler->new($e))->setup_manager;
}
sub model {
	shift->model_manager->context(@_);
}
sub is_model {
	my $e= shift;
	my $label= lc(shift) || return 0;
	$e->model_manager->regists->{$label} ? $label: 0;
}
sub _prepare {
	my($e)= @_;
	$e->model_manager->_prepare($e);
	$e->next::method;
}
sub _finalize {
	my($e)= @_;
	$e->model_manager->_finalize($e);
	$e->next::method;
}
sub _finalize_error {
	my($e)= @_;
	$e->model_manager->_finalize_error($e);
	$e->next::method;
}
sub _output {
	my($e)= @_;
	$e->model_manager->_output($e);
	$e->next::method;
}
sub _finish {
	my($e)= @_;
	$e->model_manager->_finish($e);
	$e->next::method;
}

package Egg::Manager::Model::handler;
use base qw/ Egg::Manager /;

1;

__END__

=head1 NAME

Egg::Manager::Model - Model manager for Egg. 

=head1 DESCRIPTION

It is a module to offer Egg the model function.

When the model_manager method of Egg is called, the handler class for the model
is returned.

=head1 CONFIGURATION

The configuration of the model is done to 'MODEL' by the ARRAY form.

  MODEL => [
    [  DBI => {
       dsn => ...........
       ..........
       } ],
    ],

=head1 METHODS

Because this class is registered in @ISA of the project, the method can be used
directly from the object of the project.

  $project->model( .... );

=head2 init_model

When starting for the model, it initializes it.

=head2 setup_model

The setup for the model is done.

=head2 model ([LABEL_STRING])

The object of the specific model specified with LABEL_STRING is returned.

When LABEL_STRING is omitted, the object of the model of default is restored.

  my $dbi= $e->model;
     or
  my $dbi= $e->model('dbi::main');

The setting of the first element set to the configuration becomes default.

L<Egg::Model::DBI> is attached to the model.

=head2 is_model ([LABEL_STRING])

If the model corresponding to LABEL_STRING can be used, true is returned.

  unless ($e->is_model('dbi')) {
     die q{ dbi is not active. };
  }

=head1 HANDLER METHODS

It is model manager's main body.

L<Egg::Manager> is succeeded to and the main function is used.

The method is called by way of model_manager.

This class is succeeding to L<Egg::Manager> and it doesn't have a peculiar method.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Manager>,
L<Egg::Model::DBI>, 

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

