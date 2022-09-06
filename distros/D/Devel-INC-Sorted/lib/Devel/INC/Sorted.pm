package Devel::INC::Sorted; # git description: v0.03-5-g064f0d2
# ABSTRACT: Keep your hooks in the beginning of @INC

use base 'Tie::Array';

use strict;
use warnings;

use Exporter;
use Scalar::Util qw(blessed reftype);
use Tie::RefHash;

our $VERSION = '0.04';

our @EXPORT_OK = qw(inc_add_floating inc_float_entry inc_unfloat_entry untie_inc);

tie our %floating, 'Tie::RefHash';

sub import {
	my ( $self, @args ) = @_;
	$self->tie_inc( grep { ref } @args ); # if a code ref is given, pass it to TIEARRAY
	goto &Exporter::import;
}

sub _args {
	my ( $self, @args );

	if (
		( blessed($_[0]) or defined($_[0]) && !ref($_[0]) ) # class or object
			and
		( $_[0]->isa(__PACKAGE__) )
	) {
		$self = shift;
	} else {
		$self = __PACKAGE__;
	}

	return ( $self->tie_inc, @_ );
}

sub inc_add_floating {
	my ( $self, @args ) = &_args;

	$self->inc_float_entry(@args);

	$self->PUSH(@args);
}

sub inc_float_entry {
	my ( $self, @args ) = &_args;

	@floating{@args} = ( (1) x @args );

	$self->_fixup;
}

sub inc_unfloat_entry {
	my ( $self, @args ) = &_args;

	delete @floating{@args};

	$self->_fixup;
}

sub tie_inc {
	my ( $self, @args ) = @_;
	return $self if ref $self;
	return tied @INC if tied @INC;
	tie @INC, $self, $args[0], @INC;
}

sub untie_inc {
	my ( $self ) = &_args;
	no warnings 'untie'; # untying while tied() is referenced elsewhere warns
	untie @INC;
	@INC = @{ $self->{array} };
}

# This code was adapted from Tie::Array::Sorted::Lazy
# the reason it's not a subclass is because neither ::Sorted nor ::Sorted::Lazy
# provide a stably sorted array, which is bad for our default comparison operator

sub TIEARRAY {
	my ( $class, $comparator, @orig ) = @_;

	$comparator ||= sub {
		my ( $left, $right ) = @_;
		exists $floating{$right} <=> exists $floating{$left};
	};

	bless {
		array => \@orig,
		comp  => $comparator,
	}, $class;
}

sub STORE {
	my ($self, $index, $elem) = @_;
	$self->{array}[$index] = $elem;
	$self->_fixup();
	$self->{array}[$index];
}

sub PUSH {
	my $self = shift;
	my $ret = push @{ $self->{array} }, @_;
	$self->_fixup();
	$ret;
}

sub UNSHIFT {
	my $self = shift;
	my $ret = unshift @{ $self->{array} }, @_;
	$self->_fixup();
	$ret;
}

sub _fixup {
	my $self = shift;
	$self->{array} = [ sort { $self->{comp}->($a, $b) } @{ $self->{array} } ];
	$self->{dirty} = 0;
}

sub FETCH {
	$_[0]->{array}->[ $_[1] ];
}

sub FETCHSIZE {
	scalar @{ $_[0]->{array} }
}

sub STORESIZE {
	$#{ $_[0]->{array} } = $_[1] - 1;
}

sub POP {
	pop(@{ $_[0]->{array} });
}

sub SHIFT {
	shift(@{ $_[0]->{array} });
}

sub EXISTS {
	exists $_[0]->{array}->[ $_[1] ];
}

sub DELETE {
	delete $_[0]->{array}->[ $_[1] ];
}

sub CLEAR {
	@{ $_[0]->{array} } = ()
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::INC::Sorted - Keep your hooks in the beginning of @INC

=head1 VERSION

version 0.04

=head1 SYNOPSIS

	use Devel::INC::Sorted qw(inc_add_floating);

	inc_add_floating( \&my_inc_hook );
	unshift @INC, \&other_hook;

	use lib 'blah';

	push @INC, 'foo';

	warn $INC[0]; # this is still \&my_inc_hook
	warn $INC[3]; # but \&other_hook was moved down to here

=head1 DESCRIPTION

This module keeps C<@INC> sorted much like L<Tie::Array::Sorted>.

The default comparison operator partitions the members into floating and non floating,
allowing you to easily keep certain hooks in the beginning of C<@INC>.

The sort used is a stable one, to make sure that the order of C<@INC> for
unsorted items remains unchanged.

=head1 EXPORTS

All exports are optional

=over 4

=item inc_add_floating

Add entries to C<@INC> and call C<inc_float_entry> on them.

=item inc_float_entry

Mark the arguments as floating (in the internal hashref).

=item inc_unfloat_entry

Remove the items from the hash.

=item untie_inc

Untie C<@INC>, leaving all it's current elements in place. Further
modifications to C<@INC> will not cause resorting to happen.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-INC-Sorted>
(or L<bug-Devel-INC-Sorted@rt.cpan.org|mailto:bug-Devel-INC-Sorted@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge José Joaquín Atria

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

José Joaquín Atria <jjatria@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
