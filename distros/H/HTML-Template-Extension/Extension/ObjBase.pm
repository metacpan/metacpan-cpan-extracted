package HTML::Template::Extension::ObjBase;

$VERSION 			= "0.02";
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

sub push_filter {
    my $self = shift;
	my $parent = shift;
    push @{$parent->{filter_internal}},@{$self->_get_filter()};
}

sub _get_filter {
	my $self = shift;
	my @ret ;
	no strict "refs";
	push @ret, \&{ref($self) . '::filter'};
	return \@ret;
}

sub filter {
	my $template = shift;
	return $$template;
}

1;
