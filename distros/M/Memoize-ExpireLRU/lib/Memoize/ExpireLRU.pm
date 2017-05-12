###########################################################################
# File    - ExpireLRU.pm
#	    Created 12 Feb, 2000, Brent B. Powers
#
# Purpose - This package implements LRU expiration. It does this by
#	    using a bunch of different data structures. Tuning
#	    support is included, but costs performance.
#
# ToDo    - Test the further tie stuff
#
# Copyright(c) 2000 Brent B. Powers and B2Pi LLC
#
# You may copy and distribute this program under the same terms as
# Perl itself.
#
###########################################################################
package Memoize::ExpireLRU;
$Memoize::ExpireLRU::VERSION = '0.56';
use 5.006;
use warnings;
use strict;
use AutoLoader qw(AUTOLOAD);
use Carp;

our $DEBUG = 0;

# Usage:  memoize func ,
# 		TIE => [
# 			Memoize::ExpireLRU,
# 			CACHESIZE => n,
# 			TUNECACHESIZE => m,
#			INSTANCE => IDString
# 			TIE => [...]
# 		       ]

#############################################
##
## This used to all be a bit more reasonable, but then it turns out
## that Memoize doesn't call FETCH if EXISTS returns true and it's in
## scalar context. Thus, everything really has to be done in the
## EXISTS code. Harumph.
##
#############################################

our @AllTies;
our $EndDebug = 0;

1;

sub TIEHASH {
    my ($package, %args, %cache, @index, @Tune, @Stats);
    ($package, %args)= @_;
    my($self) = bless \%args => $package;
    $self->{CACHESIZE} or
	    croak "Memoize::ExpireLRU: CACHESIZE must be specified >0; aborting";
    $self->{TUNECACHESIZE} ||= 0;
    delete($self->{TUNECACHESIZE}) unless $self->{TUNECACHESIZE};
    $self->{C} = \%cache;
    $self->{I} = \@index;
    defined($self->{INSTANCE}) or $self->{INSTANCE} = "$self";
    foreach (@AllTies) {
	if ($_->{INSTANCE} eq $self->{INSTANCE}) {
	    croak "Memoize::ExpireLRU: Attempt to register the same routine twice; aborting";
	}
    }
    if ($self->{TUNECACHESIZE}) {
	$EndDebug = 1;
	for (my $i = 0; $i < $args{TUNECACHESIZE}; $i++) {
	    $Stats[$i] = 0;
	}
	$self->{T} = \@Stats;
	$self->{TI} = \@Tune;
	$self->{cm} = $args{ch} = $args{th} = 0;
	
    }

    if ($self->{TIE}) {
	my($module, $modulefile, @opts, $rc, %tcache);
	($module, @opts) = @{$args{TIE}};
	$modulefile = $module . '.pm';
	$modulefile =~ s{::}{/}g;
	eval { require $modulefile };
	if ($@) {
	    croak "Memoize::ExpireLRU: Couldn't load hash tie module `$module': $@; aborting";
	}
	$rc = (tie %tcache => $module, @opts);
	unless ($rc) {
	    croak "Memoize::ExpireLRU: Couldn't tie hash to `$module': $@; aborting";
	}

	## Preload our cache
	foreach (keys %tcache) {
	    $self->{C}->{$_} = $tcache{$_}
	}
	$self->{TiC} = \%tcache;
    }

    push(@AllTies, $self);
    return $self;
}

sub EXISTS {
    my($self, $key) = @_;

    $DEBUG and print STDERR " >> $self->{INSTANCE} >> EXISTS: $key\n";

    if (exists $self->{C}->{$key}) {
	my($t, $i);#, %t, %r);

	## Adjust the positions in the index cache
	##    1. Find the old entry in the array (and do the stat's)
	$i = _find($self->{I}, $self->{C}->{$key}->{t}, $key);
	if (!defined($i)) {
	    print STDERR "Cache trashed (unable to find $key)\n";
	    DumpCache($self->{INSTANCE});
	    ShowStats();
	    die "Aborting...";
	}

	##    2. Remove the old entry from the array
	$t = splice(@{$self->{I}}, $i, 1);

	##    3. Update the timestamp of the new array entry, as
	##  well as that in the cache
	$self->{C}->{$key}->{t} = $t->{t} = time;

	##    4. Store the updated entry back into the array as the MRU
	unshift(@{$self->{I}}, $t);

	##    5. Adjust stats
	if (defined($self->{T})) {
	    $self->{T}->[$i]++ if defined($self->{T});
	    $self->{ch}++;
	}

	if ($DEBUG) {
	    print STDERR "    Cache hit at $i";
	    print STDERR " ($self->{ch})" if defined($self->{T});
	    print STDERR ".\n";
	}

	return 1;
    } else {
	if (exists($self->{TUNECACHESIZE})) {
	    $self->{cm}++;
	    $DEBUG and print STDERR "    Cache miss ($self->{cm}).\n";
 	    ## Ughhh. A linear search
	    my($i, $j);
	    for ($i = $j = $self->{CACHESIZE}; $i <= $#{$self->{T}}; $i++) {
		next unless defined($self->{TI})
			&& defined($self->{TI}->[$i- $j])
			&& defined($self->{TI}->[$i - $j]->{k})
			&& $self->{TI}->[$i - $j]->{k} eq $key;
		$self->{T}->[$i]++;
		$self->{th}++;
		$DEBUG and print STDERR "    TestCache hit at $i. ($self->{th})\n";
		splice(@{$self->{TI}}, $i - $j, 1);
		return 0;
	    }
	} else {
	    $DEBUG and print STDERR "    Cache miss.\n";
	}
	return 0;
    }
}

sub STORE {
    my ($self, $key, $value) = @_;
    $DEBUG and print STDERR " >> $self->{INSTANCE} >> STORE: $key $value\n";

    my(%r, %t);
    $t{t} = $r{t} = time;
    $r{v} = $value;
    $t{k} = $key;

    # Store the value into the hash
    $self->{C}->{$key} = \%r;
    ## As well as the tied cache, if it exists
    $self->{TC}->{$key} = $value if defined($self->{TC});

    # By definition, this item is the MRU, so add it to the beginning
    # of the LRU queue. Since this is a STORE, we know it doesn't already
    # exist.
    unshift(@{$self->{I}}, \%t);
    ## Update the tied cache
    $self->{TC}->{$key} = $value if defined($self->{TC});

    ## Do we have too many entries?
    while (scalar(@{$self->{I}}) > $self->{CACHESIZE}) {
	## Chop off whatever is at the end
	## Get the key
	$key = pop(@{$self->{I}});
	delete($self->{C}->{$key->{k}});
	delete($self->{TC}->{$key->{k}}) if defined($self->{TC});
	## Throw it to the beginning of the test cache
	unshift(@{$self->{TI}}, $key) if defined($self->{T});
    }

    ## Now, what about the Tuning Index
    if (defined($self->{T})) {
	if (scalar(@{$self->{TI}}) > $self->{TUNECACHESIZE} - $self->{CACHESIZE}) {
	    $#{$self->{TI}} = $self->{TUNECACHESIZE} - $self->{CACHESIZE} - 1;
	}
    }

    $value;
}

sub FETCH {
    my($self, $key) = @_;

    $DEBUG and print STDERR " >> $self->{INSTANCE} >> FETCH: $key\n";

    return $self->{C}->{$key}->{v};
}

sub _find ( $$$ ) {
    my($Aref, $time, $key) = @_;
    my($t, $b, $n, $l);

    $t = $#{$Aref};
    $n = $b = 0;
    $l = -2;

    while ($time != $Aref->[$n]->{t}) {
	if ($time < $Aref->[$n]->{t}) {
	    $b = $n;
	} else {
	    $t = $n;
	}
	if ($t <= $b) {
	    ## Trouble, we're out.
	    if ($Aref->[$t]->{t} == $time) {
		$n = $t;
	    } elsif ($Aref->[$b]->{t} == $time) {
		$n = $b;
	    } else {
		## Really big trouble
		## Complain loudly
		print "Trouble\n";
		return undef;
	    }
	} else {
	    $n = $b + (($t - $b) >> 1);
	    $n++ if $l == $n;
	    $l = $n;
	}
    }
    ## Drop down in the array until the time isn't the time
    while (($n > 0) && ($time == $Aref->[$n-1]->{t})) {
	$n--;
    }
    while (($time == $Aref->[$n]->{t}) && ($key ne $Aref->[$n]->{k})) {
	$n++;
    }
    if ($key ne $Aref->[$n]->{k}) {
	## More big trouble
	print "More trouble\n";
	return undef;
    }
    return $n;
}

END {
    print STDERR ShowStats() if $EndDebug;
}

__END__

sub DumpCache ( $ ) {
    ## Utility routine to display the caches of the given instance
    my($Instance, $self, $p) = shift;
    foreach $self (@AllTies) {

	next unless $self->{INSTANCE} eq $Instance;

	$p = "$Instance:\n    Cache Keys:\n";

	foreach my $x (@{$self->{I}}) {
	    ## The cache is at $self->{C} (->{$key})
	    $p .= "        '$x->{k}'\n";
	}
	$p .= "    Test Cache Keys:\n";
	foreach my $x (@{$self->{TI}}) {
	    $p .= "        '$x->{k}'\n";
	}
	return $p;
    }
    return "Instance $Instance not found\n";
}


sub ShowStats () {
    ## Utility routine to show statistics
    my($k) = 0;
    my($p) = '';
    foreach my $self (@AllTies) {
	next unless defined($self->{T});
	$p .= "ExpireLRU Statistics:\n" unless $k;
	$k++;

	$p .= <<EOS;

                   ExpireLRU instantiation: $self->{INSTANCE}
                                Cache Size: $self->{CACHESIZE}
                   Experimental Cache Size: $self->{TUNECACHESIZE}
                                Cache Hits: $self->{ch}
                              Cache Misses: $self->{cm}
Additional Cache Hits at Experimental Size: $self->{th}
                             Distribution : Hits
EOS
	for (my $i = 0; $i < $self->{TUNECACHESIZE}; $i++) {
	    if ($i == $self->{CACHESIZE}) {
		$p .= "                                     ----   -----\n";
	    }
	    $p .= sprintf("                                      %3d : %s\n",
			  $i, $self->{T}->[$i]);
	}
    }
    return $p;
}

=head1 NAME

Memoize::ExpireLRU - Expiry plug-in for Memoize that adds LRU cache expiration

=head1 SYNOPSIS

    use Memoize;

    memoize('slow_function',
	    TIE => [Memoize::ExpireLRU,
		    CACHESIZE => n,
	           ]);

Note that one need not C<use> this module.
It will be found by the L<Memoize> module.

The argument to C<CACHESIZE> must be an integer.
Normally, this is all that is needed.
Additional options are available:

	TUNECACHESIZE => m,
	INSTANCE      => 'descriptive_name',
	TIE           => '[DB_File, $filename, O_RDWR | O_CREATE, 0666]'

=head1 DESCRIPTION

For the theory of Memoization, please see the Memoize module
documentation. This module implements an expiry policy for Memoize
that follows LRU semantics, that is, the last n results, where n is
specified as the argument to the C<CACHESIZE> parameter, will be
cached.

=head1 PERFORMANCE TUNING

It is often quite difficult to determine what size cache will give
optimal results for a given function. To aid in determining this,
ExpireLRU includes cache tuning support. Enabling this causes a
definite performance hit, but it is often useful before code is
released to production.

To enable cache tuning support, simply specify the optional
C<TUNECACHESIZE> parameter with a size greater than that of the
C<CACHESIZE> parameter.

When the program exits, a set of statistics will be printed to
stderr. If multiple routines have been memoized, separate sets of
statistics are printed for each routine. The default names are
somewhat cryptic: this is the purpose of the C<INSTANCE>
parameter. The value of this parameter will be used as the identifier
within the statistics report.

=head1 DIAGNOSTIC METHODS

Two additional routines are available but not
exported. Memoize::ExpireLRU::ShowStats returns a string identical to
the statistics report printed to STDERR at the end of the program if
test caches have been enabled; Memoize::ExpireLRU::DumpCache takes the
instance name of a memoized function as a parameter, and returns a
string describing the current state of that instance.


=head1 SEE ALSO

L<Memoize>


=head1 REPOSITORY

L<https://github.com/neilb/Memoize-ExpireLRU>


=head1 AUTHOR

Brent B. Powers (B2Pi), Powers@B2Pi.com


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 1999 by Brent B. Powers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
