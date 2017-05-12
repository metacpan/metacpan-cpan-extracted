package Math::Geometry::Construction::Role::AlternativeSources;
use Moose::Role;

use 5.008008;

use Carp;

=head1 NAME

C<Math::Geometry::Construction::Role::AlternativeSources> - one out of some

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';

sub alternatives {
    my ($class, %args) = @_;
    my $meta           = Class::MOP::Class->initialize($class);

    # complete spec (except triggers)
    while(my ($alt_name, $alt_spec) = each %{$args{alternatives}}) {
	$alt_spec->{is}        = 'rw'
	    unless(exists($alt_spec->{is}));
	$alt_spec->{reader}    = '_'.$alt_name
	    unless(exists($alt_spec->{reader}));
	$alt_spec->{predicate} = '_has_'.$alt_name
	    unless(exists($alt_spec->{predicate}));
	$alt_spec->{clearer}   = '_clear_'.$alt_name
	    unless(exists($alt_spec->{clearer}));
    }

    # create attributes with triggers
    while(my ($alt_name, $alt_spec) = each %{$args{alternatives}}) {
	my $_rules = sub {
	    my ($self) = @_;
    
	    foreach(keys %{$args{alternatives}}) {
		unless($_ eq $alt_name) {
		    my $clearer = $args{alternatives}->{$_}->{clearer};
		    $self->$clearer;
		}
	    }

	    $self->clear_global_buffer if($args{clear_buffer});
	};
	$alt_spec->{trigger} = $_rules
	    unless(exists($alt_spec->{trigger}));

	$meta->add_attribute($alt_name, %$alt_spec);
    }

    my $_check = sub {
	my ($self) = @_;
	foreach(keys %{$args{alternatives}}) {
	    my $predicate = $args{alternatives}->{$_}->{predicate};
	    return if($self->$predicate);
	}
	croak('At least one of the attributes '.
	      join(', ', keys %{$args{alternatives}}).
	      ' has to be specified when construction a '.
	      $class.' object');
    };

    $meta->add_method('_check_'.$args{name} => $_check);
}

1;


__END__

=pod

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 Methods


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

