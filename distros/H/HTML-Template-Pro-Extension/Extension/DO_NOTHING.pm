package HTML::Template::Pro::Extension::DO_NOTHING;

$VERSION 			= "0.11";
sub Version 		{ $VERSION; }

use Carp;
use strict;

my %fields_parent   =
                (
                 );

sub init {
    my $self = shift;
    while (my ($key,$val) = each(%fields_parent)) {
        $self->{$key} = $self->{$key} || $val;
    }
}

sub get_filter {
    my $self = shift;
    return _get_filter($self);
}

sub _get_filter {
	my $self = shift;
	my @ret ;
	push @ret,\&_do_nothing;
	return @ret;
}

sub _do_nothing {
       my $template = shift;
       $$template = $$template
}

1;
