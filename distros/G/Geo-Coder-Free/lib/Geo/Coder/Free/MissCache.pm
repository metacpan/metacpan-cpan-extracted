package Geo::Coder::Free::MissCache;

use strict;
use warnings;

use Carp ();

=head1 NAME

Geo::Coder::Free::MissCache - process-level memory of lookups that found nothing

=head1 VERSION

Version 0.52

=cut

our $VERSION = '0.52';

# How long a remembered miss lasts.  A miss is a statement about data on disk,
# which does not change while a batch or a request runs; the lifetime only has
# to be long enough to save the repeated search, and short enough that a
# rebuilt data set is noticed without a restart.
our $EXPIRES_AFTER = 60 * 60;

# scope => { key => expiry time }.  Scopes are scope_for() strings; the zero
# byte in them keeps a backend name from matching a data set of the same name.
my %misses;

# An expiry sweep costs a walk of the cache, so it runs at most this often as
# misses are added; missed() and size() discard what they look at regardless.
use constant SWEEP_INTERVAL => 60;
my $next_sweep = 0;

=head1 SYNOPSIS

    use Geo::Coder::Free::MissCache;

    my $scope  = Geo::Coder::Free::MissCache->scope_for('OpenAddresses', '/data/openaddresses');
    my $digest = 'AB12CD34';

    # A lookup found nothing: remember that, so the next caller does not
    # have to read the same database to learn it again.
    Geo::Coder::Free::MissCache->remember($scope, $digest);

    # A caller about to do the work asks first.
    if(Geo::Coder::Free::MissCache->missed($scope, $digest)) {
        print "already looked for $digest\n";
    }

    # The data behind the cache was rebuilt, so forget everything.
    Geo::Coder::Free->clear_miss_cache();

=head1 DESCRIPTION

Every backend in C<Geo::Coder::Free> has the same problem: an address that is
not in its data is not found on every call, and each call pays for the whole
search again.  C<Geo::Coder::Free::MissCache> is the one place where the
backends record those misses, so the process remembers the absence once and
every later call - through any instance of any backend - answers without
touching a database.

Entries are held in memory, in the process, and are not shared between
processes.  They expire after an hour by default.  That is long enough to
spare a batch, a web request or a test run the repeated work, and short enough
that a process which stays up after its data is rebuilt does not keep
answering from a stale memory forever; C<Geo::Coder::Free->clear_miss_cache()>
empties the cache at once for that case.  Expired entries are discarded when
they are next asked about, and a sweep runs at most once a minute as new
misses are recorded, so the cache does not grow without bound.

A miss is only ever remembered, never inferred: nothing here decides that an
answer will be missing, it only stores that a backend has already found that
it is.

=head1 METHODS

=head2 scope_for

    my $scope = Geo::Coder::Free::MissCache->scope_for('OpenAddresses', $dir);

Builds the name a backend stores its misses under.  The parts are joined with
a zero byte, so the first part names the backend and the rest say which data
set is being read - two OpenAddresses directories hold different data, and a miss in
one says nothing about the other.  C<clear()> uses the same convention: giving
it a backend name clears every data set that backend opened.

=head3 API SPECIFICATION

=head4 input

    backend => { type => 'string' }            # Local, MaxMind or OpenAddresses
    dataset => { type => 'string', optional => 1 }  # zero or more, which data set

Any number of parts, in any characters; no parts gives C<''>.  An empty data set
is still a part, so C<scope_for('a', '')> is not C<scope_for('a')>.

=head4 output

    { type => 'string' }

=cut

sub scope_for {
	my ($class, @parts) = @_;

	return join("\0", @parts);
}

=head2 missed

    my $seen = Geo::Coder::Free::MissCache->missed($scope, $key);

True if C<$key> was remembered as a miss in C<$scope> and has not expired.
An expired entry is deleted as it is found.  A missing entry is false and is
not an error.

=head3 API SPECIFICATION

=head4 input

    scope => { type => 'string' }   # from scope_for()
    key   => { type => 'string' }

A key can be any string: C<''>, C<'0'>, a zero byte, non-ASCII characters and a
very long string are all kept apart.  Characters and the UTF-8 bytes that encode
them are different keys; how perl stores a string makes no difference.  An unknown
scope or key is false, and not an error.  This applies to L</remember> and
L</forget> as well.

=head4 output

    { type => 'boolean' }

=cut

sub missed {
	my ($class, $scope, $key) = @_;

	my $entries = $misses{$scope} or return 0;
	my $expires_at = $entries->{$key};
	return 0 if !defined($expires_at);

	if($expires_at <= time()) {
		delete $entries->{$key};
		delete $misses{$scope} if !keys %{$entries};
		return 0;
	}

	return 1;
}

=head2 remember

    Geo::Coder::Free::MissCache->remember($scope, $key);

Records that C<$key> found nothing in C<$scope>, for as long as
L</expires_after> says.  Recording the same miss again refreshes it.
Returns true.

=head3 API SPECIFICATION

=head4 input

    scope => { type => 'string' }   # from scope_for()
    key   => { type => 'string' }

=head4 output

    { type => 'boolean', value => 1 }

=cut

sub remember {
	my ($class, $scope, $key) = @_;

	_sweep();
	$misses{$scope}{$key} = time() + $EXPIRES_AFTER;

	return 1;
}

=head2 forget

    Geo::Coder::Free::MissCache->forget($scope, $key);

Forgets one miss, leaving the rest of C<$scope> alone.  Returns true if there
was an entry to forget, and false if C<$scope> or C<$key> held none, so
forgetting the same miss twice returns false the second time.  A backend calls
this when a lookup that had been remembered as a miss now succeeds, so a hit is
never skipped on the strength of an older miss.

=head3 API SPECIFICATION

=head4 input

    scope => { type => 'string' }   # from scope_for()
    key   => { type => 'string' }

=head4 output

    { type => 'boolean' }

=cut

sub forget {
	my ($class, $scope, $key) = @_;

	my $entries = $misses{$scope} or return 0;
	return 0 if !exists($entries->{$key});

	delete $entries->{$key};
	delete $misses{$scope} if !keys %{$entries};

	return 1;
}

=head2 clear

    Geo::Coder::Free::MissCache->clear();
    Geo::Coder::Free::MissCache->clear('OpenAddresses');

With no argument, forgets every miss in every scope.  With a scope, forgets
the misses in that scope and in every scope below it: C<clear('OpenAddresses')>
empties every OpenAddresses data set this process has opened.  A scope that
holds nothing, or names no backend, forgets nothing.  Returns true.

=head3 API SPECIFICATION

=head4 input

    scope => { type => 'string', optional => 1 }   # a backend name or a scope_for() string

C<undef> is the same as absent.  A scope matches whole parts only:
C<OpenAddresses> doesn't cover C<OpenAddressesX>, and C<OpenAddresse> matches
nothing.  C<''> is a scope like any other.  This applies to L</size> as well.

=head4 output

    { type => 'boolean', value => 1 }

=cut

sub clear {
	my ($class, $scope) = @_;

	if(!defined($scope)) {
		%misses = ();
		return 1;
	}

	my $prefix = "$scope\0";
	foreach my $name(keys %misses) {
		delete $misses{$name} if($name eq $scope) || (index($name, $prefix) == 0);
	}

	return 1;
}

=head2 size

    my $count = Geo::Coder::Free::MissCache->size();
    my $count = Geo::Coder::Free::MissCache->size('Local');

How many misses are currently remembered, in all scopes or in one scope.
Expired entries are discarded first, so this is the number of live entries.

=head3 API SPECIFICATION

=head4 input

    scope => { type => 'string', optional => 1 }   # a backend name or a scope_for() string

=head4 output

    { type => 'integer', min => 0 }

=cut

sub size {
	my ($class, $scope) = @_;

	_sweep(1);

	my @names = defined($scope)
		? grep { ($_ eq $scope) || (index($_, "$scope\0") == 0) } keys %misses
		: keys %misses;

	my $total = 0;
	$total += scalar(keys %{$misses{$_}}) foreach @names;

	return $total;
}

=head2 expires_after

    my $seconds = Geo::Coder::Free::MissCache->expires_after();
    Geo::Coder::Free::MissCache->expires_after(600);

How long a remembered miss lasts, in seconds.  Without an argument it answers
with the current setting, which is one hour.  Setting it to 0 makes every miss
expire as soon as it is recorded, which turns the cache off.  It is a setting
of the process, not of an object, like the cache itself.

The lifetime is a whole number of seconds.  A negative number, a fraction or
anything that is not a number croaks
C<expires_after() expects a non-negative whole number of seconds>, and the
setting is left as it was.  Returns the setting in force after the call.

=head3 API SPECIFICATION

=head4 input

    seconds => { type => 'integer', min => 0, optional => 1 }

The lowest value is C<0>; no maximum applies.  Leading zeros are accepted.  C<undef>
only asks for the setting.  C<-1>, C<1.5>, C<1.0>, C<1e3>, C<''>, a space on either
side, a trailing newline, a digit of another script such as C<"\x{661}">, and a
reference all croak.

=head4 output

    { type => 'integer', min => 0 }

=cut

sub expires_after {
	my ($class, $seconds) = @_;

	if(defined($seconds)) {
		Carp::croak('expires_after() expects a non-negative whole number of seconds')
			unless $seconds =~ /\A[0-9]+\z/;
		$EXPIRES_AFTER = $seconds;
	}

	return $EXPIRES_AFTER;
}

sub _sweep {
	my ($force) = @_;

	my $now = time();
	return if !$force && ($now < $next_sweep);
	$next_sweep = $now + SWEEP_INTERVAL;

	foreach my $scope(keys %misses) {
		my $entries = $misses{$scope};
		foreach my $key(keys %{$entries}) {
			delete $entries->{$key} if $entries->{$key} <= $now;
		}
		delete $misses{$scope} if !keys %{$entries};
	}

	return;
}

1;

__END__

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 SEE ALSO

L<Geo::Coder::Free>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, and Government)
must apply in writing for a licence for use from Nigel Horne at C<< <njh at nigelhorne.com> >>.

=cut
