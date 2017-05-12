package Leyland::Negotiator;

# ABSTRACT: Performs HTTP negotiations for Leyland requests

use strict;
use warnings;

use Carp;

=head1 NAME

Leyland::Negotiator - Performs HTTP negotiations for Leyland requests

=head1 SYNOPSIS

	# used internally

=head1 DESCRIPTION

This module performs HTTP negotiations for L<Leyland> requests. When a request
is handled by a Leyland application, it is first negotiated by this module
to make sure it can be handled, and to decide on how to handle it.

The following negotiations are performed:

=over

=item 1. Character set negotiation - Leyland only supports UTF-8, so if
the request defines a different character set, a 400 Bad Request error
is thrown.

=item 2. Path negotiation - The request path is compared against the application's
routes, and a list of routes is created. If none are found, a 404 Not Found
error is thrown.

=item 3. Request method negotiation - The list of routes is filtered
by the request method (GET, POST, etc.), so only routes of this method
remain. If none remain, a 405 Method Not Allowed error is thrown.

=item 4. Received content type negotiation - The list of routes is filtered
by the request content type (text/html for example), if it has any, so only
routes that accept this media type remain. If none remain, a 415 Unsupported
Media Type error is thrown.

=item 5. Returned content type negotiation - The list of routes is filtered
by the request accepted media types (residing in the Accept HTTP header),
if defined, so only routes that return a media type accepted by the client
remain. If none remain, a 406 Not Acceptable error is thrown.

=back

There's one thing this method doesn't perform, and that's language negotiation.
Since proper HTTP language negotiation is rare (and difficult to implement),
you are expect to perform that yourself (only if you wish, of course).
For that, L<Leyland::Localizer> is provided.

This module also finds routes that match a path when an HTTP OPTIONS request
is received.

=head1 CLASS METHODS

=head2 negotiate( $c, $app_routes, $path )

Performs a series of HTTP negotiations on the request and returns matching
routes. If none are found, an error is thrown. See L</"DESCRIPTION"> for
more information.

=cut

sub negotiate {
	my ($class, $c, $app_routes, $path) = @_;

	# 1. CHARACTER SET NEGOTIATION
	# --------------------------------------------------------------
	# Leyland only supports UTF-8 character encodings, so let's check
	# the client supports that. If not, let's return an error
	$c->log->debug('Negotiating character set.');
	Leyland::Negotiator->_negotiate_charset($c)
		|| $c->exception({ code => 400, error => "This server only supports the UTF-8 character set, unfortunately we are unable to fulfil your request." });

	# 2. PATH NEGOTIATION
	# --------------------------------------------------------------
	# let's find all possible prefix/route combinations
	# from the request path, and then find all routes matching
	# the request path
	my $routes = [];
	$path ||= $c->path;
	$routes = $class->_negotiate_path($c, { app_routes => $app_routes, path => $path });
	$c->exception({ code => 404 }) unless scalar @$routes;

	$c->log->debug('Found '.scalar(@$routes).' routes matching '.$path);

	# 3. REQUEST METHOD NEGOTIATION
	# --------------------------------------------------------------
	# weed out routes that do not match request method
	$c->log->debug('Negotiating request method.');
	$routes = $class->_negotiate_method($c->method, $routes);
	$c->exception({ code => 405 }) unless scalar @$routes;

	# 4. RECEIVED CONTENT TYPE NEGOTIATION
	# --------------------------------------------------------------
	# weed out all routes that do not accept the media type that the
	# client used for the request
	$c->log->debug('Negotiating media type received.');
	$routes = $class->_negotiate_receive_media($c, $routes);
	$c->exception({ code => 415 }) unless scalar @$routes;

	# 5. RETURNED CONTENT TYPE NEGOTIATION
	# --------------------------------------------------------------
	# weed out all routes that do not return any media type
	# the client accepts
	$c->log->debug('Negotiating media type returned.');
	$routes = $class->_negotiate_return_media($c, $routes);
	$c->exception({ code => 406 }) unless scalar @$routes;

	return $routes;
}

=head2 find_options( $c, $app_routes )

Finds all routes that match a certain path when an HTTP OPTIONS request
is received.

=cut

sub find_options {
	my ($class, $c, $app_routes) = @_;

	my $routes = $class->matching_routes($app_routes, $class->prefs_and_routes($c->path));

	# have we found any matching routes?
	$c->exception({ code => 404 }) unless scalar @$routes;

	# okay, we have, let's see which HTTP methods are supported by
	# these routes
	my %meths = ( 'OPTIONS' => 1 );
	foreach (@$routes) {
		$meths{$class->method_name($_->{method})} = 1;
	}

	return sort keys %meths;
}

=head2 method_name( $meth )

Receives the name of a Leyland-style HTTP method (like 'get', 'post',
'put' or 'del') and returns the correct HTTP name of it (like 'GET', 'POST',
'PUT' or 'DELETE').

=cut

sub method_name {
	my ($class, $meth) = @_;

	# replace 'del' with 'delete'
	$meth = 'delete' if $meth eq 'del';

	# return this in uppercase
	return uc($meth);
}

sub _negotiate_path {
	my ($class, $c, $args) = @_;

	$args->{path} ||= $c->path;

	# let's find all possible prefix/route combinations
	# from the request path and then find all routes matching the request path
	my $routes = $class->_matching_routes($args->{app_routes}, $class->_prefs_and_routes($args->{path}), $args->{internal});

	if ($args->{method}) {
		return $class->_negotiate_method($args->{method}, $routes);
	} else {
		return $routes;
	}
}

sub _prefs_and_routes {
	my ($class, $path) = @_;

	my $pref_routes = [{ prefix => '', route => $path }];
	my ($prefix) = ($path =~ m!^(/[^/]+)!);
	my $route = $' || '/';
	my $i = 0; # counter to prevent infinite loops, probably should be removed
	while ($prefix && $i < 1000) {
		push(@$pref_routes, { prefix => $prefix, route => $route });
		
		my ($suffix) = ($route =~ m!^(/[^/]+)!);
		last unless $suffix;
		$prefix .= $suffix;
		$route = $' || '/';
		$i++;
	}

	return $pref_routes;
}

sub _matching_routes {
	my ($class, $app_routes, $pref_routes, $internal) = @_;

	my $routes = [];
	foreach (@$pref_routes) {
		my $pref_name = $_->{prefix} || '_root_';

		next unless $app_routes->EXISTS($pref_name);

		my $pref_routes = $app_routes->FETCH($pref_name);
		
		next unless $pref_routes;
		
		# find matching routes in this prefix
		ROUTE: foreach my $r ($pref_routes->Keys) {
			# does the requested route match the current route?
			next unless my @captures = ($_->{route} =~ m/$r/);
			
			shift @captures if scalar @captures == 1 && $captures[0] eq '1';

			my $route_meths = $pref_routes->FETCH($r);

			# find all routes that support the request method (i.e. GET, POST, etc.)
			METH: foreach my $m (sort { $a eq 'any' || $b eq 'any' } keys %$route_meths) {
				# do not match internal routes
				RULE: foreach my $rule (@{$route_meths->{$m}->{rules}->{is} || []}) {
					next METH if $rule eq 'internal' && !$internal;
				}

				# okay, add this route
				push(@$routes, { method => $m, class => $route_meths->{$m}->{class}, prefix => $_->{prefix}, route => $r, code => $route_meths->{$m}->{code}, rules => $route_meths->{$m}->{rules}, captures => \@captures });
			}
		}
	}

	return $routes;
}

sub _negotiate_method {
	my ($class, $method, $routes) = @_;

	return [grep { $class->method_name($_->{method}) eq $method || $_->{method} eq 'any' } @$routes];
}

sub _negotiate_receive_media {
	my ($class, $c, $all_routes) = @_;

	return $all_routes unless my $ct = $c->content_type;

	# will hold all routes with acceptable receive types
	my $routes = [];

	# remove charset from content-type
	if ($ct =~ m/^([^;]+)/) {
		$ct = $1;
	}

	$c->log->debug("I have received $ct");

	ROUTE: foreach (@$all_routes) {
		# does this route accept all media types?
		unless (exists $_->{rules}->{accepts}) {
			push(@$routes, $_);
			next ROUTE;
		}

		# okay, it has, what are we accepting?
		foreach my $accept (@{$_->{rules}->{accepts}}) {
			if ($accept eq $ct) {
				push(@$routes, $_);
				next ROUTE;
			}
		}
	}

	return $routes;
}

sub _negotiate_return_media {
	my ($class, $c, $all_routes) = @_;

	my @mimes;
	foreach (@{$c->wanted_mimes}) {
		push(@mimes, $_->{mime});
	}
	$c->log->debug('Remote address wants '.join(', ', @mimes));

	# will hold all routes with acceptable return types
	my $routes = [];
	
	ROUTE: foreach (@$all_routes) {
		# does this route return any media type?
		if ($_->{rules}->{returns_all}) {
			$_->{media} = '*/*';
			push(@$routes, $_);
			next ROUTE;
		}

		# what media types does this route return?
		my @have = exists $_->{rules}->{returns} ? 
			@{$_->{rules}->{returns}} :
			('text/html');

		# what routes do the client want?
		if (@{$c->wanted_mimes}) {
			foreach my $want (@{$c->wanted_mimes}) {
				# does the client accept _everything_?
				# if so, just return the first type we support.
				# this will happen only in the end of the
				# wanted_mimes list, so if the client explicitely
				# accepts a type we support, it will have
				# preference over this
				if ($want->{mime} eq '*/*' && $want->{q} > 0) {
					$_->{media} = $have[0];
					push(@$routes, $_);
					next ROUTE;
				}
				
				# okay, the client doesn't support */*, let's see what we have
				foreach my $have (@have) {
					if ($want->{mime} eq $have) {
						# we return a MIME type the client wants
						$_->{media} = $want->{mime};
						push(@$routes, $_);
						next ROUTE;
					}
				}
			}
		} else {
			$_->{media} = $have[0];
			push(@$routes, $_);
			next ROUTE;
		}
	}
	
	return $routes;
}

sub _negotiate_charset {
	my ($class, $c) = @_;

	if ($c->header('Accept-Charset')) {
		my @chars = split(/,/, $c->header('Accept-Charset'));
		foreach (@chars) {
			my ($charset, $pref) = split(/;q=/, $_);
			next unless defined $pref;
			return if $charset =~ m/utf-?8/i && $pref == 0;
		}
	}

	return 1;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Leyland at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Leyland>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Leyland::Negotiator

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
