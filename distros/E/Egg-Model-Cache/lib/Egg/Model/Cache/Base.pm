package Egg::Model::Cache::Base;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 293 2008-02-28 11:00:55Z lushe $
#
use strict;
use warnings;
use base qw/ Egg::Model Egg::Component::Base /;

our $VERSION= '0.01';

our $AUTOLOAD;

sub setup_cache {
	my $class= shift;
	$class->can('cache') and die q{'cache' method has already been setup.};
	my $pkg= shift || die q{I want cache module name.};
	$pkg->require or die __PACKAGE__. "- $@";
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{"${class}::cache"}= sub {
		$_[0]->{cache_context}
		   ||= $pkg->new( wantarray ? %{$_[0]->config}: $_[0]->config );
	  };
}
sub AUTOLOAD {
	my $self= shift;
	my($method)= $AUTOLOAD=~m{([^\:]+)$};
	$self->can('cache') || die q{'setup_cache' is not done.};
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{__PACKAGE__."::$method"}= sub {
		my $proto= shift;
		$proto->cache->$method(@_);
	  };
	$self->$method(@_);
}
sub DESTROY { }

1;

__END__

=head1 NAME

Egg::Model::Cache::Base - Base class to succeed to from CACHE controller.

=head1 DESCRIPTION

It is a base class to succeed to from the CACHE controller who generates it with
L<Egg::Helper::Model::Cache>.

=head1 METHODS

This module operates as Wrapper of the module passed to 'setup_cache' method.

Therefore, the method that can be used in the module set by 'setup_cache' method
is different.

=head2 setup_cache ([CACHE_MODULE])

It is set up to use CACHE_MODULE.

  __PACKAGE__->setup_cache('Cache::Memcached');

=head2 cache

It is a method of can use and when 'setup_cache' is done.

The object of the module passed by 'setup_cache' is returned.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model>,
L<Egg::Model::Cache>,
L<Egg::Helper::Model::Cache>,
L<Egg::Component::Base>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

