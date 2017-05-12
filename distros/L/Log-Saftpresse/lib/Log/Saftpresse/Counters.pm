package Log::Saftpresse::Counters;

use Moose;

# ABSTRACT: objects to hold and manipulate counters
our $VERSION = '1.6'; # VERSION

use Carp;

has 'counters' => (
	is => 'ro', isa => 'HashRef', lazy => 1,
	default => sub { {} },
);

sub incr_one {
	my $self = shift;
	return $self->incr(@_, 1);
}

sub incr {
	my $self = shift;
	my $incr = pop;
	my $key = pop;
	my $cur_level = $self->counters;
	while( my $cur_key = shift ) {
		if( ! defined $cur_level->{ $cur_key }) {
			$cur_level->{ $cur_key } = {};
		} elsif( ref($cur_level->{$cur_key}) ne 'HASH' ) {
			confess('counter sub element is not a hash!');
		}
		$cur_level = $cur_level->{ $cur_key };
	}
	if( ! defined $cur_level->{$key} ) {
		$cur_level->{$key} = $incr;
	} else {
		$cur_level->{$key} += $incr;
	}
	return( $cur_level->{$key} );
}

sub incr_max {
	my $self = shift;
	my $max = pop;
	my $key = pop;
	my $cur_level = $self->counters;
	while( my $cur_key = shift ) {
		if( ! defined $cur_level->{ $cur_key }) {
			$cur_level->{ $cur_key } = {};
		} elsif( ref($cur_level->{$cur_key}) ne 'HASH' ) {
			die('counter sub element is not a hash!');
		}
		$cur_level = $cur_level->{ $cur_key };
	}
	if( ! defined $cur_level->{$key} ) {
		$cur_level->{$key} = $max;
	} elsif( $max > $cur_level->{$key} ) {
		$cur_level->{$key} = $max;
	}
	return( $cur_level->{$key} );
}

sub get_value {
	my $self = shift;
	my $value = $self->get_node( @_ );
	# if the element is a reference and not a value
	if( ref($value) ) {
		return;
	}
	return( $value );
}
*get = \&get_value;

sub get_key_count {
	my $self = shift;
	if( my $node = $self->get_node(@_) ) {
		return( scalar keys %$node );
	}
	return 0;
}

sub get_value_or_zero {
	my $self = shift;
	if( my $value = $self->get_value(@_) ) {
		return( $value );
	}
	return 0;
}

sub get_node {
	my $self = shift;
	my $key = pop;
	my $cur_level = $self->counters;
	while( my $cur_key = shift ) {
		if( ! defined $cur_level->{ $cur_key } ) {
			return;
		} elsif( ref($cur_level->{$cur_key}) ne 'HASH' ) {
			return;
		}
		$cur_level = $cur_level->{ $cur_key };
	}
	return( $cur_level->{$key} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Counters - objects to hold and manipulate counters

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
