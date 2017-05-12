package Egg::Model::Cache;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Cache.pm 315 2008-04-17 11:33:06Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.01';

sub _setup {
	my($class, $e)= @_;
	Egg::Model::Cache::handler->_setup($e);
	$class->next::method($e);
}

package Egg::Model::Cache::handler;
use strict;

sub new {
	my($class, $e, $c, $default)= @_;
	my $pkg= $e->project_name. '::Model::Cache';
	$e->model_manager->context($pkg->default);
}
sub _setup {
	my($class, $e)= @_;
	my $base= $e->project_name. '::Model::Cache';
	my $path= $e->path_to(qw{ lib_project  Model/Cache });
	no strict 'refs';  ## no critic.
	push @{"${base}::ISA"}, 'Egg::Base';
	$base->mk_classdata($_) for qw/ default labels /;
	my $labels= $base->labels($e->ixhash);
	for (sort (grep /.+\.pm$/, <$path/*>)) {  ## no critic.
		m{([^\\\/\:]+)\.pm$} || next;
		my $name = $1;
		my $dc   = "${base}::$name";
		$dc->require or die $@;
		my $c= $dc->config || {};
		my $label= lc( $c->{label_name} || "Cache::$name" );
		$e->model_manager->add_register(0, $label, $dc);
		$base->default($label) if $c->{default};
		$labels->{$label}= $dc;
		$dc->_setup($e);
	}
	%$labels || die __PACKAGE__. q{ - The Cache controller is not found.};
	$base->default((keys %$labels)[0]) unless $base->default;
	@_;
}

1;

__END__

=head1 NAME

Egg::Model::Cache - Model for cashe.

=head1 SYNOPSIS

  my $cahce= $e->model('cache_label');
  
  # Data is set in the cache.
  $cache->set( data_name => 'HOGE' );
  
  # Data is acquired from cashe.
  my $data= $cache->get('data_name');
  
  # Cashe is deleted.
  $cache->remove('data_name');

=head1 DESCRIPTION

It is a model to use cashe.

To use it, the CACHE controller is generated under the control of the project 
with the helper.

see L<Egg::Helper::Model::Cache>.

  % cd /path/to/MyApp/bin
  % ./egg_helper M::Cache [MODULE_NAME]

The CACHE controller is set up when the project is started by this and using it 
becomes possible.

Two or more CACHE controllers can be used at the same time. 

=head1 HOW TO CACHE CONTROLLER

It is necessary to set up the cashe module used by 'setup_cache' method in the 
CACHE controller.

  __PACKAGE__->setup_cache('Cache::FileCache');

It is L<Cache::FileCache> in default, and the thing changed to an arbitrary module
can be done.

The data set by the config method is passed by the constructor of all modules 
set up by 'setup_cache'.

When 'label_name' is set, the model call can be done by an arbitrary label name.

  __PACKAGE__->config(
    label_name => 'mylabel',
    );
  
  my $cache= $e->model('mylabel');

Additionally, please construct the CACHE controller while arbitrarily adding a 
convenient code to obtain the cash data.

=head1 METHODS

Please refer to L<Egg::Model::Cache::Base> for the method that the CACHE controller
can use.

=head2 new

Constructor.

The object of the CACHE controller who default and has been treated is returned.

  my $cache= $e->model('cache');

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Cache::Base>,
L<Egg::Helper::Model::Cache>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

