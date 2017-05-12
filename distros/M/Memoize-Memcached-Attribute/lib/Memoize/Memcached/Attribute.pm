package Memoize::Memcached::Attribute;
# ABSTRACT: auto-memoize function results using memcached and subroutine attributes

use strict;
use warnings;

use Sub::Attribute;

use Digest::MD5 ();
use Storable ();

our $VERSION = '0.11'; # VERSION
our $MEMCACHE;
our %CLIENT_PARAMS = (
	servers => ['127.0.0.1:11211']
);

sub import {
	my $package = shift;
	my %attrs   = (UNIVERSAL::isa($_[0], 'HASH')) ? %{ $_[0] } : @_;

	unless ($attrs{'-noattrimport'}) {
		my ($caller) = caller();
		no strict 'refs';
		*{ "$caller\::CacheMemoize" } = \&CacheMemoize;
		*{ "$caller\::MODIFY_CODE_ATTRIBUTES" } = \&MODIFY_CODE_ATTRIBUTES;
	}

	delete $attrs{'-noattrimport'};

	if ($attrs{'-client'}) {
		$MEMCACHE = $attrs{'-client'};
	}
	else {
		%CLIENT_PARAMS = %attrs;
		$MEMCACHE = _connect();
	}
}

sub reset {
	undef $MEMCACHE;
	if (@_) {
		$MEMCACHE = $_[0];
	}
	elsif (%CLIENT_PARAMS) {
		$MEMCACHE = _connect();
	}
}

sub _connect {
	my $memcache_pkg;
	eval {
		require Cache::Memcached::Fast;
		$memcache_pkg = 'Cache::Memcached::Fast';
	};
	if ($@) {
		require Cache::Memcached;
		$memcache_pkg = 'Cache::Memcached';
	}
	return $memcache_pkg->new(\%CLIENT_PARAMS);
}

sub CacheMemoize :ATTR_SUB {
	my ($package, $symbol, $referent, $attr, $params) = @_;

	no strict 'refs';

	$params = _parse_attr_params($params);

	my $is_method   = 0;
	if (@$params > 1) {
		my $type   = shift @$params;
		$is_method = 1 if (lc($type) eq 'method');
	}

	my $duration    = $params->[0];

	my $symbol_name = join('::', $package, *{ $symbol }{NAME});

	no warnings 'redefine';
	my $original = \&{ $symbol_name };
	*{$symbol_name} = sub {
		my @args   = @_;

		# if we're in a method, don't use the object to build the key
		my @key_args = @args;
		shift @key_args if ($is_method);

		my $key = _build_key($symbol_name, @key_args);

		if (wantarray) {
			$key .= '-wantarray';
			my $ref = $MEMCACHE->get($key) || do {
				my @list = $original->(@args);
				$MEMCACHE->set($key, \@list, $duration) if (@list);
				\@list;
			};
			return @$ref;
		}



		my $cached = $MEMCACHE->get($key);
		return $cached if (defined $cached);

		my $result = $original->(@args);
		$MEMCACHE->set($key, $result, $duration) if (defined $result);
		return $result;
	};
}

sub invalidate {
	my $symbol_name = shift;
	if ($symbol_name !~ /::/) {
		# build the full method from the caller's namespace if necessary
		$symbol_name = join('::', (caller)[0], $symbol_name);
	}

	my $key = Memoize::Memcached::Attribute::_build_key($symbol_name, @_);
	$MEMCACHE->delete($key);
	$MEMCACHE->delete("${key}-wantarray");
}

sub _parse_attr_params {
	my ($string) = @_;

	return [] unless defined $string;

	my $data = eval "
		no warnings;
		no strict;
		[$string]
	";

	return $data || [$string];
}

sub _build_key {
	local $Storable::canonical = 1;
	return Digest::MD5::md5_base64(Storable::nfreeze(\@_));
}

1;


=pod

=head1 NAME

Memoize::Memcached::Attribute - auto-memoize function results using memcached and subroutine attributes

=head1 VERSION

version 0.11

=head1 SYNOPSIS

If you're running memcache on your local box, with the default port, you can initialize without passing any
parameters:

	use Memoize::Memcached::Attribute;

This will use the default server list of 127.0.0.1:11211

If you want to specify the constructor parameters for your Cache::Memcached or Cache::Memcached::Fast client object,
you can pass them in during import:

	use Memoize::Memcached::Attribute (
		servers => [ '192.168.1.2:11211', '192.168.1.3:11211' ],
		_connect_timeout => 0.1,
		max_failures => 5,
	);

Alternatively, you can pass in your memcache client object entirely (we use this because
we subclass Cache::Memcached::Fast to add some additional methods and default parameters):

	use Memoize::Memcached::Attribute (-client => Cache::Memcached::Fast->new(\%some_params));

Or you can specify it at runtime, the only caveat being that you must do this prior to calling any memoized function:

	use Memoize::Memcache::Attribute;
	Memoize::Memcache::Attribute::reset(Cache::Memcached::Fast->new(\%some_params));

And that's basically it.  Now you have a :CacheMemoize subroutine attribute that will memoize subroutine results
based on their parameters, storing the memoized data in memcache for a specified duration.

To use the memoization, you just pass your cache duration to the :CacheMemoize subroutine attribute:

	# cache the results in memcache for 5 minutes
	sub myfunc :CacheMemoize(300) {
		my @params = @_;
		my $total;
		$total += $_ for @params;
		return $total;
	}

Sometimes you have an object method that is not dependent on object state, and you want to memoize those results,
independent of the object used to generate them.  So we provide that option by passing in 'method' as your first
parameter with the cache duration as the second:

	# cache the results in memcache for 30 seconds
	# but don't look at the object as part of the input data
	sub mymethod :CacheMemoize(method => 30) {
		my $self = shift;
		my @params = @_;
		return join('.', @params);
	}

Really, you can pass anything in as a first parameter and it will be ignored if it isn't case-insensitively equal to 'method'.

While not generally recommended as good design, we do support the ability to
invalidate caches.  If you find yourself using the invalidation often, this module
is probably not really how you want to go about achieving your caching strategy.
Here's how you do it:

	Memoize::Memcached::Attribute::invalidate('Some::Package::myfunc', @params);

If you're invalidating the cache from inside the same package as the cached function (which
is probably the only place you should be), you can omit the package name:

	Memoize::Memcached::Attribute::invalidate('mymethod', @params);

=head1 DESCRIPTION

Memoization is a process whereby you cache the results of a function, based on its input,
in memory so that repeated calls to the same function don't waste cycles recalculating the results.  Generally you use
it with functions that are somewhat expensive to run (or that you have to run so frequently they become expensive), and that
always return the same results based on the same input (i.e. they have no side effects).  This module expands that concept to
use memcache to provide a shared memory cache, rather than a per-process cache like a lot of other memoization modules, so
that multiple processes can reuse the results.  It gives you the added benefit that the memoization is not permanent, because
you specify a timeout on the cached data.  So, if you have a method that has no side effects, but the data it's returning might
become stale, you can still get the benefits of memoization while also having it automatically recalculate the results
from time to time.

=head1 METHODS

=head2 reset

Allows you to reset the package global memcache client after forking.

=head2 invalidate

Allows you to invalidate cached data.

=head2 import

Allows you to specify memcache connection parameters or your own client object to be used.

=head2 CacheMemoize

Should not be called directly.  This is the subroutine attribute handler exported by this package.

=head1 METHODS

=head1 OPTIONS

When you import the package, you can pass a few options in:

=over 4

=item -noattrimport - By default, we import some methods to make the attribute work properly in subclasses.
This flag prevents that behavior.  It allows you to avoid cluttering your namespace a little, at the expense of
not working with inheritance.

=item -client - Allows you to specify your own memcache client object.  Useful if you subclass
Cache::Memcached in your codebase.

=back

Any remaining options will be used to _connect to the Cache::Memcached client object, if passed.

=head1 THREADS/FORKING

Because this module internally stores the memcached client as a package global, and the memcached clients
have issues with threads and forking, it would be wise to reset the package global after forking or creating
a new thread.  This can be done like this:

	if (my $pid = fork) {
		# parent
	}
	else {
		# create a new client using the parameters you used to create the original object
		Memoize::Memcached::Attribute::reset();
		# or pass in your own object
		Memoize::Memcached::Attribute::reset($new_memcached_client);
	}

=head1 ACKNOWLEDGEMENTS

Thanks to Chris Reinhardt and David Dierauer for finding and fixing some issues.  And to
LiquidWeb for allowing me to contribute this to CPAN.

=head1 BUGS

None known.  This has been in use in LiquidWeb production code for a few years without any known issues.
It was slightly modified to remove some dependence on other LiquidWeb code, so there's an extremely
remote chance that something broke in the process.

If you find a bug, or have a feature request, submit it here:
https://github.com/jimbobhickville/perl-Memoize-Memcached-Attribute/issues/new

=head1 AUTHOR

Greg Hill <jimbobhickville@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Greg Hill.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

