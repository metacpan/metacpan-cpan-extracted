package Leyland::Controller;

# ABSTRACT: Leyland controller base class

use Moo::Role;

our %INFO;

=head1 NAME

Leyland::Controller - Leyland controller base class

=head1 SYNOPSIS

	# used internally

=head1 DESCRIPTION

This L<Moo role|Moo::Role> describes how L<Leyland> controllers are
to be created. For information about creating controllers, please see
L<Leyland::Manual::Controllers>.

=head1 CLASS ATTRIBUTES

=head2 prefix

The prefix of the controller. Defaults to the empty string (denoting a root
controller).

=head2 routes

A L<Tie::IxHash> object with all the controller's routes.

=cut

sub prefix {
	my $class = shift;

	$class = ref $class
		if ref $class;

	return $INFO{$class} ? $INFO{$class}->{prefix} : '';
}

sub routes {
	my $class = shift;

	$class = ref $class
		if ref $class;

	return $INFO{$class} ? $INFO{$class}->{routes} : Tie::IxHash->new;
}

=head1 CLASS METHODS

=head2 add_route( $method, $regex, \&code )

Receives an HTTP request method, a regular expression for path matching,
and a subroutine reference that together describe a route, and adds the
route to the controller's "routes" list.

=cut

sub add_route {
	my ($class, $method, $regex, $code) = (shift, shift, shift, pop);

	my $rules = {};
	while (scalar @_) {
		my ($key, $value) = split(/=/, shift);
		if (defined $key && defined $value) {
			$rules->{$key} = [split(/\|/, $value)];
		}
	}

	$rules->{accepts} ||= [];
	$rules->{returns} ||= [$Leyland::INFO{default_mime}];
	$rules->{is} ||= ['external'];

	# if this is a POST/PUT route, make sure it accepts application/x-www-form-urlencoded
	my $xwfu;
	foreach (@{$rules->{accepts}}) {
		if ($_ eq 'application/x-www-form-urlencoded') {
			$xwfu = 1;
			last;
		}
	}
	push(@{$rules->{accepts}}, 'application/x-www-form-urlencoded')
		if (($method eq 'post' || $method eq 'put') && !$xwfu);

	# handle routes that return anything
	foreach (@{$rules->{returns}}) {
		if ($_ eq '*/*') {
			$rules->{returns_all} = 1;
			last;
		}
	}

	$INFO{$class} ||= { prefix => '', routes => Tie::IxHash->new };
	my $routes = $INFO{$class}->{routes};

	if ($routes->EXISTS($regex)) {
		my $thing = $routes->FETCH($regex);
		$thing->{$method} = { class => $class, code => $code, rules => $rules };
	} else {
		$routes->Push($regex => { $method => { class => $class, code => $code, rules => $rules } });
	}
}

=head2 set_prefix()

Sets the prefix for all routes in the controller.

=cut

sub set_prefix {
	my ($class, $code) = @_;

	$INFO{$class} ||= { prefix => '', routes => Tie::IxHash->new };
	$INFO{$class}->{prefix} = $code->();
}

=head1 METHODS MEANT TO BE OVERRIDDEN

The following methods are meant to be overridden by consuming classes
(i.e. controllers). For information on their purpose, see L<Leyland::Manual::Controllers>.

=head2 auto( $c )

Provides Leyland controllers with a default C<auto()> method that doesn't
do anything. Controllers are expected to override this.

=cut

sub auto { 1 }

=head2 pre_route( $c )

Provides Leyland controllers with a default C<pre_route()> method that doesn't
do anything.

=cut

sub pre_route { 1 }

=head2 pre_template( $c, $tmpl_name, [ \%context, $use_layout ] )

Provides Leyland controllers with a default C<pre_template()> method that doesn't
do anything.

=cut

sub pre_template { 1 }

=head2 post_route( $c, $ret )

Provides Leyland controllers with a default C<post_route()> method that doesn't
do anything.

=cut

sub post_route { 1 }

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Leyland at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Leyland>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Leyland::Controller

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Leyland>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Leyland>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Leyland>

=item * Search CPAN

L<http://search.cpan.org/dist/Leyland/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
