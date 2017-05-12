package HTML::Template::Pro::Extension::ObjBase;

$VERSION 			= "0.11";
sub Version 		{ $VERSION; }

use Carp;
use strict;

sub new {
               my $class = shift;
               my $self = {};
               bless $self, $class;
               return $self;
}
           

sub init {
  my $self = shift;
	my $parent = shift;
}

sub get_filter {
  my $self = shift;
	my $parent = shift;
  return $self->_get_filter();
}

sub _get_filter {
	my $self = shift;
	my @ret ;
	no strict "refs";
	push @ret, \&{ref($self) . '::filter'};
	return @ret;
}

sub filter {
	my $template = shift;
	return $$template;
}

1;

# vim: set ts=2:
