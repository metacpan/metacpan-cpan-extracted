package LTSV::LINQ;
######################################################################
#
# LTSV::LINQ - LINQ-style query interface for LTSV files
#
# https://metacpan.org/dist/LTSV-LINQ
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org>
######################################################################
#
# Compatible : Perl 5.005_03 and later
# Platform   : Windows and UNIX/Linux
#
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
                # Perl 5.005_03 compatibility for historical toolchains
# use 5.008001; # Lancaster Consensus 2013 for toolchains

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use vars qw($VERSION);
$VERSION = '1.06';
$VERSION = $VERSION;
# $VERSION self-assignment suppresses "used only once" warning under strict.

###############################################################################
# Constructor and Iterator Infrastructure
###############################################################################

sub new {
    my($class, $iterator) = @_;
    return bless { iterator => $iterator }, $class;
}

sub iterator {
    my $self = $_[0];
    # If this object was created by _from_snapshot, _factory provides
    # a fresh iterator closure each time iterator() is called.
    if (exists $self->{_factory}) {
        return $self->{_factory}->();
    }
    return $self->{iterator};
}

###############################################################################
# Data Source Methods
###############################################################################

# From - create query from array
sub From {
    my($class, $source) = @_;

    if (ref($source) eq 'ARRAY') {
        my $i = 0;
        return $class->new(sub {
            return undef if $i >= scalar(@$source);
            return $source->[$i++];
        });
    }

    die "From() requires ARRAY reference";
}

# FromLTSV - read from LTSV file
sub FromLTSV {
    my($class, $file) = @_;

    my $fh;
    if ($] >= 5.006) {
        # Avoid "Too many arguments for open at" error when running with Perl 5.005_03
        eval q{ open($fh, '<', $file) } or die "Cannot open '$file': $!";
    }
    else {
        $fh = \do { local *_ };
        open($fh, "< $file") or die "Cannot open '$file': $!";
    }
    binmode $fh;    # Treat as raw bytes; handles all multibyte encodings
                    # and prevents \r\n -> \n translation on Windows

    return $class->new(sub {
        while (my $line = <$fh>) {
            chomp $line;
            $line =~ s/\r\z//;  # Remove CR for CRLF files on any platform
            next unless length $line;

            my %record = map {
                /\A(.+?):(.*)\z/ ? ($1, $2) : ()
            } split /\t/, $line;

            return \%record if %record;
        }
        close $fh;
        return undef;
    });
}

# Range - generate sequence of integers
sub Range {
    my($class, $start, $count) = @_;

    my $current = $start;
    my $remaining = $count;

    return $class->new(sub {
        return undef if $remaining <= 0;
        $remaining--;
        return $current++;
    });
}

# Empty - return empty sequence
sub Empty {
    my($class) = @_;

    return $class->new(sub {
        return undef;
    });
}

# Repeat - repeat element specified number of times
sub Repeat {
    my($class, $element, $count) = @_;

    my $remaining = $count;

    return $class->new(sub {
        return undef if $remaining <= 0;
        $remaining--;
        return $element;
    });
}

###############################################################################
# Filtering Methods
###############################################################################

# Where - filter elements
sub Where {
    my($self, @args) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);

    # Support both code reference and DSL form
    my $cond;
    if (@args == 1 && ref($args[0]) eq 'CODE') {
        $cond = $args[0];
    }
    else {
        # DSL form: Where(key => value, ...)
        my %match = @args;
        $cond = sub {
            my $row = shift;
            for my $k (keys %match) {
                return 0 unless defined $row->{$k};
                return 0 unless $row->{$k} eq $match{$k};
            }
            return 1;
        };
    }

    return $class->new(sub {
        while (1) {
            my $item = $iter->();
            return undef unless defined $item;
            return $item if $cond->($item);
        }
    });
}

###############################################################################
# Projection Methods
###############################################################################

# Select - transform elements
sub Select {
    my($self, $selector) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);

    return $class->new(sub {
        my $item = $iter->();
        return undef unless defined $item;
        return $selector->($item);
    });
}

# SelectMany - flatten sequences
sub SelectMany {
    my($self, $selector) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);

    my @buffer;

    return $class->new(sub {
        while (1) {
            if (@buffer) {
                return shift @buffer;
            }

            my $item = $iter->();
            return undef unless defined $item;

            my $result = $selector->($item);
            unless (ref($result) eq 'ARRAY') {
                die "SelectMany: selector must return an ARRAY reference";
            }
            @buffer = @$result;
        }
    });
}

# Concat - concatenate two sequences
sub Concat {
    my($self, $second) = @_;
    my $class = ref($self);

    my $first_iter = $self->iterator;
    my $second_iter;
    my $first_done = 0;

    return $class->new(sub {
        if (!$first_done) {
            my $item = $first_iter->();
            if (defined $item) {
                return $item;
            }
            $first_done = 1;
            $second_iter = $second->iterator;
        }

        return $second_iter ? $second_iter->() : undef;
    });
}

# Zip - combine two sequences element-wise
sub Zip {
    my($self, $second, $result_selector) = @_;

    my $iter1 = $self->iterator;
    my $iter2 = $second->iterator;
    my $class = ref($self);

    return $class->new(sub {
        my $item1 = $iter1->();
        my $item2 = $iter2->();

        # Return undef if either sequence ends
        return undef unless defined($item1) && defined($item2);

        return $result_selector->($item1, $item2);
    });
}

###############################################################################
# Partitioning Methods
###############################################################################

# Take - take first N elements
sub Take {
    my($self, $count) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);
    my $taken = 0;

    return $class->new(sub {
        return undef if $taken >= $count;
        my $item = $iter->();
        return undef unless defined $item;
        $taken++;
        return $item;
    });
}

# Skip - skip first N elements
sub Skip {
    my($self, $count) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);
    my $skipped = 0;

    return $class->new(sub {
        while ($skipped < $count) {
            my $item = $iter->();
            return undef unless defined $item;
            $skipped++;
        }
        return $iter->();
    });
}

# TakeWhile - take while condition is true
sub TakeWhile {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);
    my $done = 0;

    return $class->new(sub {
        return undef if $done;
        my $item = $iter->();
        return undef unless defined $item;

        if ($predicate->($item)) {
            return $item;
        }
        else {
            $done = 1;
            return undef;
        }
    });
}

# SkipWhile - skip elements while predicate is true
sub SkipWhile {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);
    my $skipping = 1;

    return $class->new(sub {
        while (1) {
            my $item = $iter->();
            return undef unless defined $item;

            if ($skipping) {
                if (!$predicate->($item)) {
                    $skipping = 0;
                    return $item;
                }
            }
            else {
                return $item;
            }
        }
    });
}

###############################################################################
# Ordering Methods
###############################################################################

# OrderBy - sort ascending (smart: numeric when both keys look numeric)
sub OrderBy {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return LTSV::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => 1, type => 'smart' }]
    );
}

# OrderByDescending - sort descending (smart comparison)
sub OrderByDescending {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return LTSV::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => -1, type => 'smart' }]
    );
}

# OrderByStr - sort ascending by string comparison
sub OrderByStr {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return LTSV::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => 1, type => 'str' }]
    );
}

# OrderByStrDescending - sort descending by string comparison
sub OrderByStrDescending {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return LTSV::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => -1, type => 'str' }]
    );
}

# OrderByNum - sort ascending by numeric comparison
sub OrderByNum {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return LTSV::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => 1, type => 'num' }]
    );
}

# OrderByNumDescending - sort descending by numeric comparison
sub OrderByNumDescending {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return LTSV::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => -1, type => 'num' }]
    );
}

# Reverse - reverse order
sub Reverse {
    my($self) = @_;
    my @items = reverse $self->ToArray();
    my $class = ref($self);
    return $class->From([ @items ]);
}

###############################################################################
# Grouping Methods
###############################################################################

# GroupBy - group elements by key
sub GroupBy {
    my($self, $key_selector, $element_selector) = @_;
    $element_selector ||= sub { $_[0] };

    my %groups;
    my @key_order;

    $self->ForEach(sub {
        my $item = shift;
        my $key = $key_selector->($item);
        $key = '' unless defined $key;
        unless (exists $groups{$key}) {
            push @key_order, $key;
        }
        push @{$groups{$key}}, $element_selector->($item);
    });

    my @result;
    for my $key (@key_order) {
        push @result, {
            Key => $key,
            Elements => $groups{$key},
        };
    }

    my $class = ref($self);
    return $class->From([ @result ]);
}

###############################################################################
# Set Operations
###############################################################################

# Distinct - remove duplicates
sub Distinct {
    my($self, $key_selector) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);
    my %seen;

    return $class->new(sub {
        while (1) {
            my $item = $iter->();
            return undef unless defined $item;

            my $key = $key_selector ? $key_selector->($item) : _make_key($item);
            $key = '' unless defined $key;

            unless ($seen{$key}++) {
                return $item;
            }
        }
    });
}

# Internal helper for set operations - make key from item
sub _make_key {
    my($item) = @_;

    return '' unless defined $item;

    if (ref($item) eq 'HASH') {
        # Hash to stable key
        my @pairs = ();
        for my $k (sort keys %$item) {
            my $v = defined($item->{$k}) ? $item->{$k} : '';
            push @pairs, "$k\x1F$v";  # \x1F = Unit Separator
        }
        return join("\x1E", @pairs);  # \x1E = Record Separator
    }
    elsif (ref($item) eq 'ARRAY') {
        # Array to key
        return join("\x1E", map { defined($_) ? $_ : '' } @$item);
    }
    else {
        # Scalar
        return $item;
    }
}

# _from_snapshot - internal helper for GroupJoin.
# Returns a LTSV::LINQ object backed by a plain array that can be iterated
# multiple times within a single result_selector call.
# Each LINQ terminal method (Count, Sum, ToArray, etc.) calls iterator()
# to get a fresh iterator.  We achieve re-iterability by overriding the
# iterator() method so it always creates a new closure over the same array.
sub _from_snapshot {
    my($class_or_self, $aref) = @_;

    my $class = ref($class_or_self) || $class_or_self;

    # Build a sentinel sub that, when called, returns a brand-new
    # index-based iterator every time.
    my $iter_factory = sub {
        my $i = 0;
        return sub {
            return undef if $i >= scalar(@$aref);
            return $aref->[$i++];
        };
    };

    # The object stores the factory in place of a plain iterator.
    # The iterator() accessor returns the result of calling the factory,
    # so every consumer gets its own fresh iterator starting at index 0.
    my $obj = bless {
        iterator => $iter_factory->(),
        _factory => $iter_factory,
    }, $class;

    return $obj;
}

# Union - set union with distinct
sub Union {
    my($self, $second, $key_selector) = @_;

    return $self->Concat($second)->Distinct($key_selector);
}

# Intersect - set intersection
sub Intersect {
    my($self, $second, $key_selector) = @_;

    # Build hash of second sequence
    my %second_set = ();
    $second->ForEach(sub {
        my $item = shift;
        my $key = $key_selector ? $key_selector->($item) : _make_key($item);
        $second_set{$key} = $item;
    });

    my $class = ref($self);
    my $iter = $self->iterator;
    my %seen = ();

    return $class->new(sub {
        while (defined(my $item = $iter->())) {
            my $key = $key_selector ? $key_selector->($item) : _make_key($item);

            next if $seen{$key}++;  # Skip duplicates
            return $item if exists $second_set{$key};
        }
        return undef;
    });
}

# Except - set difference
sub Except {
    my($self, $second, $key_selector) = @_;

    # Build hash of second sequence
    my %second_set = ();
    $second->ForEach(sub {
        my $item = shift;
        my $key = $key_selector ? $key_selector->($item) : _make_key($item);
        $second_set{$key} = 1;
    });

    my $class = ref($self);
    my $iter = $self->iterator;
    my %seen = ();

    return $class->new(sub {
        while (defined(my $item = $iter->())) {
            my $key = $key_selector ? $key_selector->($item) : _make_key($item);

            next if $seen{$key}++;  # Skip duplicates
            return $item unless exists $second_set{$key};
        }
        return undef;
    });
}

# Join - correlates elements of two sequences
sub Join {
    my($self, $inner, $outer_key_selector, $inner_key_selector, $result_selector) = @_;

    # Build hash table from inner sequence
    my %inner_hash = ();
    $inner->ForEach(sub {
        my $item = shift;
        my $key = $inner_key_selector->($item);
        $key = _make_key($key) if ref($key);
        push @{$inner_hash{$key}}, $item;
    });

    # Process outer sequence with lazy evaluation
    my $class = ref($self);
    my $iter = $self->iterator;
    my @buffer = ();

    return $class->new(sub {
        while (1) {
            # Return from buffer if available
            return shift @buffer if @buffer;

            # Get next outer element
            my $outer_item = $iter->();
            return undef unless defined $outer_item;

            # Find matching inner elements
            my $key = $outer_key_selector->($outer_item);
            $key = _make_key($key) if ref($key);

            if (exists $inner_hash{$key}) {
                for my $inner_item (@{$inner_hash{$key}}) {
                    push @buffer, $result_selector->($outer_item, $inner_item);
                }
            }
            # If no match, continue to next outer element
        }
    });
}

# GroupJoin - group join (LEFT OUTER JOIN-like operation)
sub GroupJoin {
    my($self, $inner, $outer_key_selector, $inner_key_selector, $result_selector) = @_;
    my $class = ref($self);
    my $outer_iter = $self->iterator;

    # 1. Build lookup table from inner sequence.
    #    Group all inner items by their keys for efficient lookup.
    #    The inner sequence is fully materialized into memory here.
    my %inner_lookup = ();
    $inner->ForEach(sub {
        my $item = shift;
        my $key = $inner_key_selector->($item);
        $key = _make_key($key) if ref($key);
        $key = '' unless defined $key;
        push @{$inner_lookup{$key}}, $item;
    });

    # 2. Return lazy iterator over outer sequence
    return $class->new(sub {
        my $outer_item = $outer_iter->();
        return undef unless defined $outer_item;

        # Get key from outer item
        my $key = $outer_key_selector->($outer_item);
        $key = _make_key($key) if ref($key);
        $key = '' unless defined $key;

        # Get matching inner items (empty array ref if no matches)
        my $matched_inners = exists $inner_lookup{$key} ? $inner_lookup{$key} : [];

        # Snapshot the matched items into a plain array.
        # We create a LTSV::LINQ object whose iterator sub always reads
        # from a fresh index variable, so the group can be traversed
        # multiple times inside result_selector (e.g. Count() then Sum()).
        my @snapshot = @$matched_inners;
        my $inner_group = $class->_from_snapshot([ @snapshot ]);

        return $result_selector->($outer_item, $inner_group);
    });
}

###############################################################################
# Quantifier Methods
###############################################################################

# All - test if all elements satisfy condition
sub All {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;

    while (defined(my $item = $iter->())) {
        return 0 unless $predicate->($item);
    }
    return 1;
}

# Any - test if any element satisfies condition
sub Any {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;

    if ($predicate) {
        while (defined(my $item = $iter->())) {
            return 1 if $predicate->($item);
        }
        return 0;
    }
    else {
        my $item = $iter->();
        return defined($item) ? 1 : 0;
    }
}

# Contains - check if sequence contains element
sub Contains {
    my($self, $value, $comparer) = @_;

    if ($comparer) {
        return $self->Any(sub { $comparer->($_[0], $value) });
    }
    else {
        return $self->Any(sub {
            my $item = $_[0];
            return (!defined($item) && !defined($value)) ||
                   (defined($item) && defined($value) && $item eq $value);
        });
    }
}

# SequenceEqual - compare two sequences for equality
sub SequenceEqual {
    my($self, $second, $comparer) = @_;
    $comparer ||= sub {
        my($a, $b) = @_;
        return (!defined($a) && !defined($b)) ||
               (defined($a) && defined($b) && $a eq $b);
    };

    my $iter1 = $self->iterator;
    my $iter2 = $second->iterator;

    while (1) {
        my $item1 = $iter1->();
        my $item2 = $iter2->();

        # Both ended - equal
        return 1 if !defined($item1) && !defined($item2);

        # One ended - not equal
        return 0 if !defined($item1) || !defined($item2);

        # Compare items
        return 0 unless $comparer->($item1, $item2);
    }
}

###############################################################################
# Element Access Methods
###############################################################################

# First - get first element
sub First {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;

    if ($predicate) {
        while (defined(my $item = $iter->())) {
            return $item if $predicate->($item);
        }
        die "No element satisfies the condition";
    }
    else {
        my $item = $iter->();
        return $item if defined $item;
        die "Sequence contains no elements";
    }
}

# FirstOrDefault - get first element or default
sub FirstOrDefault {
    my $self = shift;
    my($predicate, $default);

    if (@_ >= 2) {
        # Two arguments: ($predicate, $default)
        ($predicate, $default) = @_;
    }
    elsif (@_ == 1) {
        # One argument: distinguish CODE (predicate) vs non-CODE (default)
        if (ref($_[0]) eq 'CODE') {
            $predicate = $_[0];
        }
        else {
            $default = $_[0];
        }
    }

    my $result = eval { $self->First($predicate) };
    return $@ ? $default : $result;
}

# Last - get last element
sub Last {
    my($self, $predicate) = @_;
    my @items = $self->ToArray();

    if ($predicate) {
        for (my $i = $#items; $i >= 0; $i--) {
            return $items[$i] if $predicate->($items[$i]);
        }
        die "No element satisfies the condition";
    }
    else {
        die "Sequence contains no elements" unless @items;
        return $items[-1];
    }
}

# LastOrDefault - return last element or default
sub LastOrDefault {
    my $self = shift;
    my($predicate, $default);

    if (@_ >= 2) {
        # Two arguments: ($predicate, $default)
        ($predicate, $default) = @_;
    }
    elsif (@_ == 1) {
        # One argument: distinguish CODE (predicate) vs non-CODE (default)
        if (ref($_[0]) eq 'CODE') {
            $predicate = $_[0];
        }
        else {
            $default = $_[0];
        }
    }

    my @items = $self->ToArray();

    if ($predicate) {
        for (my $i = $#items; $i >= 0; $i--) {
            return $items[$i] if $predicate->($items[$i]);
        }
        return $default;
    }
    else {
        return @items ? $items[-1] : $default;
    }
}

# Single - return the only element
sub Single {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;
    my $found;
    my $count = 0;

    while (defined(my $item = $iter->())) {
        next if $predicate && !$predicate->($item);

        $count++;
        if ($count > 1) {
            die "Sequence contains more than one element";
        }
        $found = $item;
    }

    die "Sequence contains no elements" if $count == 0;
    return $found;
}

# SingleOrDefault - return the only element or undef
sub SingleOrDefault {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;
    my $found;
    my $count = 0;

    while (defined(my $item = $iter->())) {
        next if $predicate && !$predicate->($item);

        $count++;
        if ($count > 1) {
            return undef;  # More than one element
        }
        $found = $item;
    }

    return $count == 1 ? $found : undef;
}

# ElementAt - return element at specified index
sub ElementAt {
    my($self, $index) = @_;
    die "Index must be non-negative" if $index < 0;

    my $iter = $self->iterator;
    my $current = 0;

    while (defined(my $item = $iter->())) {
        return $item if $current == $index;
        $current++;
    }

    die "Index out of range";
}

# ElementAtOrDefault - return element at index or undef
sub ElementAtOrDefault {
    my($self, $index) = @_;
    return undef if $index < 0;

    my $iter = $self->iterator;
    my $current = 0;

    while (defined(my $item = $iter->())) {
        return $item if $current == $index;
        $current++;
    }

    return undef;
}

###############################################################################
# Aggregation Methods
###############################################################################

# Count - count elements
sub Count {
    my($self, $predicate) = @_;

    if ($predicate) {
        return $self->Where($predicate)->Count();
    }

    my $count = 0;
    my $iter = $self->iterator;
    $count++ while defined $iter->();
    return $count;
}

# Sum - calculate sum
sub Sum {
    my($self, $selector) = @_;
    $selector ||= sub { $_[0] };

    my $sum = 0;
    $self->ForEach(sub {
        $sum += $selector->(shift);
    });
    return $sum;
}

# Min - find minimum
sub Min {
    my($self, $selector) = @_;
    $selector ||= sub { $_[0] };

    my $min;
    $self->ForEach(sub {
        my $val = $selector->(shift);
        $min = $val if !defined($min) || $val < $min;
    });
    return $min;
}

# Max - find maximum
sub Max {
    my($self, $selector) = @_;
    $selector ||= sub { $_[0] };

    my $max;
    $self->ForEach(sub {
        my $val = $selector->(shift);
        $max = $val if !defined($max) || $val > $max;
    });
    return $max;
}

# Average - calculate average
sub Average {
    my($self, $selector) = @_;
    $selector ||= sub { $_[0] };

    my $sum = 0;
    my $count = 0;
    $self->ForEach(sub {
        $sum += $selector->(shift);
        $count++;
    });

    die "Sequence contains no elements" if $count == 0;
    return $sum / $count;
}

# AverageOrDefault - calculate average or return undef if empty
sub AverageOrDefault {
    my($self, $selector) = @_;
    $selector ||= sub { $_[0] };

    my $sum = 0;
    my $count = 0;
    $self->ForEach(sub {
        $sum += $selector->(shift);
        $count++;
    });

    return undef if $count == 0;
    return $sum / $count;
}

# Aggregate - apply accumulator function over sequence
sub Aggregate {
    my($self, @args) = @_;

    my($seed, $func, $result_selector);

    if (@args == 1) {
        # Aggregate($func) - use first element as seed
        $func = $args[0];
        my $iter = $self->iterator;
        $seed = $iter->();
        die "Sequence contains no elements" unless defined $seed;

        # Continue with rest of elements
        while (defined(my $item = $iter->())) {
            $seed = $func->($seed, $item);
        }
    }
    elsif (@args == 2) {
        # Aggregate($seed, $func)
        ($seed, $func) = @args;
        $self->ForEach(sub {
            $seed = $func->($seed, shift);
        });
    }
    elsif (@args == 3) {
        # Aggregate($seed, $func, $result_selector)
        ($seed, $func, $result_selector) = @args;
        $self->ForEach(sub {
            $seed = $func->($seed, shift);
        });
    }
    else {
        die "Invalid number of arguments for Aggregate";
    }

    return $result_selector ? $result_selector->($seed) : $seed;
}

###############################################################################
# Conversion Methods
###############################################################################

# ToArray - convert to array
sub ToArray {
    my($self) = @_;
    my @result;
    my $iter = $self->iterator;

    while (defined(my $item = $iter->())) {
        push @result, $item;
    }
    return @result;
}

# ToList - convert to array reference
sub ToList {
    my($self) = @_;
    return [$self->ToArray()];
}

# ToDictionary - convert sequence to hash reference
sub ToDictionary {
    my($self, $key_selector, $value_selector) = @_;

    # Default value selector returns the element itself
    $value_selector ||= sub { $_[0] };

    my %dictionary = ();

    $self->ForEach(sub {
        my $item = shift;
        my $key = $key_selector->($item);
        my $value = $value_selector->($item);

        # Convert undef key to empty string
        $key = '' unless defined $key;

        # Later values overwrite earlier ones (Perl hash behavior)
        $dictionary{$key} = $value;
    });

    return \%dictionary;
}

# ToLookup - convert sequence to hash of arrays
sub ToLookup {
    my($self, $key_selector, $value_selector) = @_;

    # Default value selector returns the element itself
    $value_selector ||= sub { $_[0] };

    my %lookup = ();

    $self->ForEach(sub {
        my $item = shift;
        my $key = $key_selector->($item);
        my $value = $value_selector->($item);

        # Convert undef key to empty string
        $key = '' unless defined $key;

        push @{$lookup{$key}}, $value;
    });

    return \%lookup;
}

# DefaultIfEmpty - return default value if empty
sub DefaultIfEmpty {
    my($self, $default_value) = @_;
    # default_value defaults to undef
    my $has_default_arg = @_ > 1;
    if (!$has_default_arg) {
        $default_value = undef;
    }

    my $class = ref($self);
    my $iter = $self->iterator;
    my $has_elements = 0;
    my $returned_default = 0;

    return $class->new(sub {
        my $item = $iter->();
        if (defined $item) {
            $has_elements = 1;
            return $item;
        }

        # EOF reached
        if (!$has_elements && !$returned_default) {
            $returned_default = 1;
            return $default_value;
        }

        return undef;
    });
}

# ToLTSV - write to LTSV file
sub ToLTSV {
    my($self, $filename) = @_;

    my $fh;
    if ($] >= 5.006) {
        # Avoid "Too many arguments for open at" error when running with Perl 5.005_03
        eval q{ open($fh, '>', $filename) } or die "Cannot open '$filename': $!";
    }
    else {
        $fh = \do { local *_ };
        open($fh, "> $filename") or die "Cannot open '$filename': $!";
    }
    binmode $fh;    # Write raw bytes; prevents \r\n translation on Windows
                    # and is consistent with FromLTSV

    $self->ForEach(sub {
        my $record = shift;
        # LTSV spec: tab is the field separator; newline terminates the record.
        # Sanitize values to prevent structural corruption of the output file.
        my $line = join("\t", map {
            my $v = defined($record->{$_}) ? $record->{$_} : '';
            $v =~ s/[\t\n\r]/ /g;
            "$_:$v"
        } sort keys %$record);
        print $fh $line, "\n";
    });

    close $fh;
    return 1;
}

###############################################################################
# Utility Methods
###############################################################################

# ForEach - execute action for each element
sub ForEach {
    my($self, $action) = @_;
    my $iter = $self->iterator;

    while (defined(my $item = $iter->())) {
        $action->($item);
    }
    return;
}

1;

######################################################################
#
# LTSV::LINQ::Ordered - Ordered query supporting ThenBy/ThenByDescending
#
# Returned by OrderBy* methods.  Inherits all LTSV::LINQ methods via @ISA.
# ThenBy* methods are only available on this class, mirroring the way
# .NET LINQ's IOrderedEnumerable<T> exposes ThenBy/ThenByDescending while
# plain IEnumerable<T> does not.
#
# Stability guarantee: every sort uses a Schwartzian-Transform-style
# decorated array that appends the original element index as a final
# tie-breaker.  This makes the multi-key sort completely stable on all
# Perl versions including 5.005_03, where built-in sort stability is not
# guaranteed.
######################################################################

package LTSV::LINQ::Ordered;

# 5.005_03-compatible inheritance (no 'use parent', no 'our')
@LTSV::LINQ::Ordered::ISA = ('LTSV::LINQ');

# _new_ordered($items_aref, $specs_aref) - internal constructor
#
# $specs_aref is an arrayref of sort-spec hashrefs:
#   { sel  => $code_ref,          # key selector: ($item) -> $key
#     dir  => 1 or -1,            # 1 = ascending, -1 = descending
#     type => 'smart'|'str'|'num' # comparison family
#   }
sub _new_ordered {
    my($class, $items, $specs) = @_;
    # Use _factory so that iterator() returns a fresh sorted iterator on
    # each call (enables re-iteration, e.g. in GroupJoin result selectors).
    # Methods like Take/Where/Select that call ref($self)->new(sub{...})
    # will create a plain object with an {iterator} field (no _factory),
    # so they are unaffected by this override.
    return bless {
        _items   => $items,
        _specs   => $specs,
        _factory => sub {
            my @sorted = _perform_sort($items, $specs);
            my $i = 0;
            return sub { $i < scalar(@sorted) ? $sorted[$i++] : undef };
        },
    }, $class;
}

# _perform_sort($items_aref, $specs_aref) - core stable multi-key sort
#
# Decorated-array (Schwartzian Transform) technique:
#   1. Build [ orig_index, [key1, key2, ..., keyN], item ] per element
#   2. Sort by key1..keyN in sequence; original index as final tie-breaker
#   3. Strip decoration and return plain item list
#
# The original-index tie-breaker guarantees stability on every Perl version.
sub _perform_sort {
    my($items, $specs) = @_;

    # Step 1: decorate
    my @decorated = map {
        my $idx  = $_;
        my $item = $items->[$idx];
        my @keys = map { _extract_key($_->{sel}->($item), $_->{type}) } @{$specs};
        [$idx, [ @keys ], $item]
    } 0 .. $#{$items};

    # Step 2: sort
    my @sorted_dec = sort {
        my $r = 0;
        for my $i (0 .. $#{$specs}) {
            my $cmp = _compare_keys($a->[1][$i], $b->[1][$i], $specs->[$i]{type});
            if ($specs->[$i]{dir} < 0) { $cmp = -$cmp }
            if ($cmp != 0) { $r = $cmp; last }
        }
        $r != 0 ? $r : ($a->[0] <=> $b->[0]);
    } @decorated;

    # Step 3: undecorate
    return map { $_->[2] } @sorted_dec;
}

# _extract_key($raw_value, $type) - normalise one sort key
#
# Returns a scalar (num/str) or a two-element arrayref [flag, value]
# for 'smart' type:
#   [0, $numeric_val]  - key is numeric
#   [1, $string_val ]  - key is string
sub _extract_key {
    my($val, $type) = @_;
    $val = '' unless defined $val;
    if ($type eq 'num') {
        # Force numeric; undef/empty/non-numeric treated as 0
        return defined($val) && length($val) ? $val + 0 : 0;
    }
    elsif ($type eq 'str') {
        return "$val";
    }
    else {
        # smart: detect whether value looks like a number
        my $t = $val;
        $t =~ s/^\s+|\s+$//g;
        if ($t =~ /^[+-]?(?:\d+\.?\d*|\d*\.\d+)(?:[eE][+-]?\d+)?$/) {
            return [0, $t + 0];
        }
        else {
            return [1, "$val"];
        }
    }
}

# _compare_keys($ka, $kb, $type) - compare two extracted keys
sub _compare_keys {
    my($ka, $kb, $type) = @_;
    if ($type eq 'num') {
        return $ka <=> $kb;
    }
    elsif ($type eq 'str') {
        return $ka cmp $kb;
    }
    else {
        # smart: both are [flag, value] arrayrefs
        my $fa = $ka->[0];  my $va = $ka->[1];
        my $fb = $kb->[0];  my $vb = $kb->[1];
        if    ($fa == 0 && $fb == 0) { return $va <=> $vb }  # both numeric
        elsif ($fa == 1 && $fb == 1) { return $va cmp $vb }  # both string
        else                         { return $fa <=> $fb  }  # mixed: numeric before string
    }
}

# (No iterator() override needed: _factory in {_items,_specs,_factory} objects
# is handled by LTSV::LINQ::iterator(), which calls _factory->() each time.
# Objects produced by Take/Where/Select etc. via ref($self)->new(sub{...})
# store their closure in {iterator} and do not have _factory, so they use
# the normal non-re-entrant path.)

# _thenby($key_selector, $dir, $type) - shared implementation for all ThenBy*
#
# Non-destructive: builds a new spec list and returns a new
# LTSV::LINQ::Ordered object.  The original object is unchanged, so
# branching sort chains work correctly:
#
#   my $by_dept = From(\@data)->OrderBy(sub { $_[0]{dept} });
#   my $by_dept_name   = $by_dept->ThenBy(sub { $_[0]{name} });
#   my $by_dept_salary = $by_dept->ThenByNum(sub { $_[0]{salary} });
#   # $by_dept_name and $by_dept_salary are independent queries
sub _thenby {
    my($self, $key_selector, $dir, $type) = @_;
    my @new_specs = (@{$self->{_specs}}, { sel => $key_selector, dir => $dir, type => $type });
    return LTSV::LINQ::Ordered->_new_ordered($self->{_items}, [ @new_specs ]);
}

# ThenBy - ascending secondary key, smart comparison
sub ThenBy            { my($s, $k)=@_; $s->_thenby($k, 1, 'smart') }

# ThenByDescending - descending secondary key, smart comparison
sub ThenByDescending  { my($s, $k)=@_; $s->_thenby($k, -1, 'smart') }

# ThenByStr - ascending secondary key, string comparison
sub ThenByStr         { my($s, $k)=@_; $s->_thenby($k, 1, 'str')   }

# ThenByStrDescending - descending secondary key, string comparison
sub ThenByStrDescending { my($s, $k)=@_; $s->_thenby($k, -1, 'str') }

# ThenByNum - ascending secondary key, numeric comparison
sub ThenByNum         { my($s, $k)=@_; $s->_thenby($k, 1, 'num')   }

# ThenByNumDescending - descending secondary key, numeric comparison
sub ThenByNumDescending { my($s, $k)=@_; $s->_thenby($k, -1, 'num') }

1;

=encoding utf8

=head1 NAME

LTSV::LINQ - LINQ-style query interface for LTSV files

=head1 VERSION

Version 1.06

=head1 SYNOPSIS

  use LTSV::LINQ;

  # Read LTSV file and query
  my @results = LTSV::LINQ->FromLTSV("access.log")
      ->Where(sub { $_[0]{status} eq '200' })
      ->Select(sub { $_[0]{url} })
      ->Distinct()
      ->ToArray();

  # DSL syntax for simple filtering
  my @errors = LTSV::LINQ->FromLTSV("access.log")
      ->Where(status => '404')
      ->ToArray();

  # Grouping and aggregation
  my @stats = LTSV::LINQ->FromLTSV("access.log")
      ->GroupBy(sub { $_[0]{status} })
      ->Select(sub {
          my $g = shift;
          return {
              Status => $g->{Key},
              Count => scalar(@{$g->{Elements}})
          };
      })
      ->OrderByDescending(sub { $_[0]{Count} })
      ->ToArray();

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</INCLUDED DOCUMENTATION> -- eg/ samples and doc/ cheat sheets

=item * L</METHODS> -- Complete method reference (60 methods)

=item * L</EXAMPLES> -- 8 practical examples

=item * L</FEATURES> -- Lazy evaluation, method chaining, DSL

=item * L</ARCHITECTURE> -- Iterator design, execution flow

=item * L</PERFORMANCE> -- Memory usage, optimization tips

=item * L</COMPATIBILITY> -- Perl 5.005+ support, pure Perl

=item * L</DIAGNOSTICS> -- Error messages

=item * L</FAQ> -- Common questions and answers

=item * L</COOKBOOK> -- Common patterns

=item * L</DESIGN PHILOSOPHY>

=item * L</LIMITATIONS AND KNOWN ISSUES>

=item * L</BUGS>

=item * L</SUPPORT>

=item * L</SEE ALSO>

=back

=head1 DESCRIPTION

LTSV::LINQ provides a LINQ-style query interface for LTSV (Labeled
Tab-Separated Values) files. It offers a fluent, chainable API for
filtering, transforming, and aggregating LTSV data.

Key features:

=over 4

=item * B<Lazy evaluation> - O(1) memory usage for most operations

=item * B<Method chaining> - Fluent, readable query composition

=item * B<DSL syntax> - Simple key-value filtering

=item * B<60 LINQ methods> - Comprehensive query capabilities

=item * B<Pure Perl> - No XS dependencies

=item * B<Perl 5.005_03+> - Works on ancient and modern Perl

=back

=head2 What is LTSV?

LTSV (Labeled Tab-Separated Values) is a text format for structured logs and
data records. Each line consists of tab-separated fields, where each field is
a C<label:value> pair. A single LTSV record occupies exactly one line.

B<Format example:>

  time:2026-02-13T10:00:00	host:192.0.2.1	status:200	url:/index.html	bytes:1024

=head3 LTSV Characteristics

=over 4

=item * B<One record per line>

A complete record is always a single newline-terminated line. This makes
streaming processing trivial: read a line, parse it, process it, discard it.
There is no multi-line quoting problem, no block parser required.

=item * B<Tab as field delimiter>

Fields are separated by a single horizontal tab character (C<0x09>).
The tab is a C0 control character in the ASCII range (C<0x00>-C<0x7F>),
which has an important consequence for multibyte character encodings.

=item * B<Colon as label-value separator>

Within each field, the label and value are separated by a single colon
(C<0x3A>, US-ASCII C<:>). This is also a plain ASCII character with the same
multibyte-safety guarantees as the tab.

=back

=head3 LTSV Advantages

=over 4

=item * B<Multibyte-safe delimiters (Tab and Colon)>

This is perhaps the most important technical advantage of LTSV over formats
such as CSV (comma-delimited) or TSV without labels.

In many multibyte character encodings used across Asia and beyond, a
single logical character is represented by a sequence of two or more bytes.
The danger in older encodings is that a byte within a multibyte sequence can
coincidentally equal the byte value of an ASCII delimiter, causing a naive
byte-level parser to split the field in the wrong place.

The following table shows well-known encodings and their byte ranges:

  Encoding     First byte range       Following byte range
  ----------   --------------------   -------------------------------
  Big5         0x81-0xFE              0x40-0x7E, 0xA1-0xFE
  Big5-HKSCS   0x81-0xFE              0x40-0x7E, 0xA1-0xFE
  CP932X       0x81-0x9F, 0xE0-0xFC   0x40-0x7E, 0x80-0xFC
  EUC-JP       0x8E-0x8F, 0xA1-0xFE   0xA1-0xFE
  GB 18030     0x81-0xFE              0x30-0x39, 0x40-0x7E, 0x80-0xFE
  GBK          0x81-0xFE              0x40-0x7E, 0x80-0xFE
  Shift_JIS    0x81-0x9F, 0xE0-0xFC   0x40-0x7E, 0x80-0xFC
  RFC 2279     0xC2-0xF4              0x80-0xBF
  UHC          0x81-0xFE              0x41-0x5A, 0x61-0x7A, 0x81-0xFE
  UTF-8        0xC2-0xF4              0x80-0xBF
  WTF-8        0xC2-0xF4              0x80-0xBF

The tab character is C<0x09>.  The colon is C<0x3A>.  Both values are
strictly below C<0x40>, the lower bound of any following byte in the encodings
listed above.  Neither C<0x09> nor C<0x3A> appears anywhere as a first byte
either.  Therefore:

  TAB  (0x09) never appears as a byte within any multibyte character
              in Big5, Big5-HKSCS, CP932X, EUC-JP, GB 18030, GBK, Shift_JIS,
              RFC 2279, UHC, UTF-8, or WTF-8.
  ':'  (0x3A) never appears as a byte within any multibyte character
              in the same set of encodings.

This means that LTSV files containing values in B<any> of those encodings
can be parsed correctly by a B<simple byte-level split> on tab and colon,
with no knowledge of the encoding whatsoever. There is no need to decode
the text before parsing, and no risk of a misidentified delimiter.

By contrast, CSV has encoding problems of a different kind.
The comma (C<0x2C>) and the double-quote (C<0x22>) do B<not> appear as
following bytes in Shift_JIS or Big5, so they are not directly confused with
multibyte character content.  However, the backslash (C<0x5C>) B<does>
appear as a valid following byte in both Shift_JIS (following byte range
C<0x40>-C<0x7E> includes C<0x5C>) and Big5 (same range).  Many CSV
parsers and the C runtime on Windows use backslash or backslash-like
sequences for escaping, so a naive byte-level search for the escape
character can be misled by a multibyte character whose second byte is
C<0x5C>.  Beyond this, CSV's quoting rules are underspecified (RFC 4180
vs. Excel vs. custom dialects differ), which makes writing a correct,
encoding-aware CSV parser considerably harder than parsing LTSV.
LTSV sidesteps all of these issues by choosing delimiters (tab and colon)
that fall below C<0x40>, outside every following-byte range of every traditional
multibyte encoding.

UTF-8 is safe for all ASCII delimiters because continuation bytes are
always in the range C<0x80>-C<0xBF>, never overlapping ASCII.  But LTSV's
choice of tab and colon also makes it safe for the traditional multibyte
encodings that predate Unicode, which is critical for systems that still
operate on traditional-encoded data.

=item * B<Self-describing fields>

Every field carries its own label. A record is human-readable without a
separate schema or header line. Fields can appear in any order, and
optional fields can simply be omitted. Adding a new field to some records
does not break parsers that do not know about it.

=item * B<Streaming-friendly>

Because each record is one line, LTSV files can be processed with line-by-line
streaming. Memory usage is proportional to the longest single record, not
the total file size. This is why C<FromLTSV> in this module uses a lazy
iterator rather than loading the whole file.

=item * B<Grep- and awk-friendly>

Standard Unix text tools (C<grep>, C<awk>, C<sed>, C<sort>, C<cut>) work
naturally on LTSV files. A field can be located with a pattern like
C<status:5[0-9][0-9]> without any special parser. This makes ad-hoc
analysis and shell scripting straightforward.

=item * B<No quoting rules>

CSV requires quoting fields that contain commas or newlines, and the quoting
rules differ between implementations (RFC 4180 vs. Microsoft Excel vs. others).
LTSV has no quoting: the tab delimiter and the colon separator do not appear
inside values in any of the supported encodings (by the multibyte-safety
argument above), so no escaping mechanism is needed.

=item * B<Wide adoption in server logging>

LTSV originated in the Japanese web industry as a structured log format for
HTTP access logs. Many web servers (Apache, Nginx) and log aggregation tools
support LTSV output or parsing. The format is particularly popular for
application and infrastructure logging where grep-ability and streaming
analysis matter.

=back

For the formal LTSV specification, see L<http://ltsv.org/>.

=head2 What is LINQ?

LINQ (Language Integrated Query) is a set of query capabilities introduced
in the .NET Framework 3.5 (C# 3.0, 2007) by Microsoft. It defines a
unified model for querying and transforming data from diverse sources --
in-memory collections, relational databases (LINQ to SQL), XML documents
(LINQ to XML), and more -- using a single, consistent API.

This module brings LINQ-style querying to Perl, applied specifically to
LTSV data sources.

=head3 LINQ Characteristics

=over 4

=item * B<Unified query model>

LINQ provides a single set of operators that works uniformly across
data sources. Whether the source is an array, a file, or a database,
the same C<Where>, C<Select>, C<OrderBy>, C<GroupBy> methods apply.
LTSV::LINQ follows this principle: the same methods work on in-memory
arrays (C<From>) and LTSV files (C<FromLTSV>) alike.

=item * B<Declarative style>

LINQ queries express I<what> to retrieve, not I<how> to retrieve it.
A query like C<-E<gt>Where(sub { $_[0]{status} >= 400 })-E<gt>Select(...)>
describes the intent clearly, without explicit loop management.
This reduces cognitive overhead and makes queries easier to read and verify.

=item * B<Composability>

Each LINQ operator takes a sequence and returns a new sequence (or a
scalar result for terminal operators). Because operators are ordinary
method calls that return objects, they compose naturally:

  $query->Where(...)->Select(...)->OrderBy(...)->GroupBy(...)->ToArray()

Any intermediate result is itself a valid query object, ready for
further transformation or immediate consumption.

=item * B<Lazy evaluation (deferred execution)>

Intermediate operators (C<Where>, C<Select>, C<Take>, etc.) do not
execute immediately. They construct a chain of iterator closures.
Evaluation is deferred until a terminal operator (C<ToArray>, C<Count>,
C<First>, C<Sum>, C<ForEach>, etc.) pulls items through the chain.
This means:

=over 4

=item - Memory usage is bounded by the window of data in flight, not by the
total data size. A C<Where-E<gt>Select-E<gt>Take(10)> over a million-line
file reads at most 10 records past the first matching one.

=item - Short-circuiting is free. C<First> stops at the first match.
C<Any> stops as soon as one match is found.

=item - Pipelines can be built without executing them, and executed
multiple times by wrapping in a factory (see C<_from_snapshot>).

=back

=item * B<Method chaining (fluent interface)>

LINQ's design makes chaining natural. In C# this is supported by
extension methods; in Perl it is supported by returning C<$self>-class
objects from every intermediate operator. The result is readable,
left-to-right query expressions.

=item * B<Separation of query definition from execution>

A LINQ query object is a description of a computation, not its result.
You can pass query objects around, inspect them, extend them, and decide
later when to execute them. This separation is valuable in library and
framework code.

=back

=head3 LINQ Advantages for LTSV Processing

=over 4

=item * B<Readable log analysis>

LTSV log analysis often involves the same logical steps: filter records
by a condition, extract a field, aggregate. LINQ methods map directly
onto these steps, making the code read like a description of the analysis.

=item * B<Memory-efficient processing of large log files>

Web server access logs can be gigabytes in size. LTSV::LINQ's lazy
C<FromLTSV> iterator reads one line at a time. Combined with C<Where>
and C<Take>, only the needed records are ever in memory simultaneously.

=item * B<No new language syntax required>

Unlike C# LINQ (which has query comprehension syntax C<from x in xs where ...
select ...>), LTSV::LINQ works with ordinary Perl method calls and
anonymous subroutines. There is no source filter, no parser extension,
and no dependency on modern Perl features. The same code runs on Perl
5.005_03 and Perl 5.40.

=item * B<Composable, reusable query fragments>

A C<Where> clause stored in a variable can be applied to multiple
data sources. Query logic can be parameterized and reused across scripts.

=back

For the original LINQ documentation, see
L<https://learn.microsoft.com/en-us/dotnet/csharp/linq/>.

=head1 INCLUDED DOCUMENTATION

The C<eg/> directory contains sample programs demonstrating LTSV::LINQ features:

  eg/01_ltsv_query.pl    LTSV file query: FromLTSV/Where/Select/OrderByNumDescending/
                         Distinct/ToLookup
  eg/02_array_query.pl   In-memory array queries, aggregation (Sum/Average/Min/Max),
                         Any/All, Skip/Take paging, Zip
  eg/03_grouping.pl      GroupBy, ToLookup, GroupJoin (left outer join),
                         SelectMany with array-ref selector
  eg/04_sorting.pl       OrderBy/ThenBy multi-key sort, OrderByNum vs OrderByStr,
                         Reverse

The C<doc/> directory contains LTSV::LINQ cheat sheets in 21 languages:

  doc/linq_cheatsheet.EN.txt   English
  doc/linq_cheatsheet.JA.txt   Japanese
  doc/linq_cheatsheet.ZH.txt   Chinese (Simplified)
  doc/linq_cheatsheet.TW.txt   Chinese (Traditional)
  doc/linq_cheatsheet.KO.txt   Korean
  doc/linq_cheatsheet.FR.txt   French
  doc/linq_cheatsheet.ID.txt   Indonesian
  doc/linq_cheatsheet.VI.txt   Vietnamese
  doc/linq_cheatsheet.TH.txt   Thai
  doc/linq_cheatsheet.HI.txt   Hindi
  doc/linq_cheatsheet.BN.txt   Bengali
  doc/linq_cheatsheet.TR.txt   Turkish
  doc/linq_cheatsheet.MY.txt   Malay
  doc/linq_cheatsheet.TL.txt   Filipino
  doc/linq_cheatsheet.KM.txt   Khmer
  doc/linq_cheatsheet.MN.txt   Mongolian
  doc/linq_cheatsheet.NE.txt   Nepali
  doc/linq_cheatsheet.SI.txt   Sinhala
  doc/linq_cheatsheet.UR.txt   Urdu
  doc/linq_cheatsheet.UZ.txt   Uzbek
  doc/linq_cheatsheet.BM.txt   Burmese

Each cheat sheet covers: creating queries, filtering, projection, sorting,
paging, grouping, set operations, joins, aggregation, and links to the
official LTSV and LINQ specifications.

=head1 METHODS

=head2 Complete Method Reference

This module implements 60 LINQ-style methods organized into 15 categories:

=over 4

=item * B<Data Sources (5)>: From, FromLTSV, Range, Empty, Repeat

=item * B<Filtering (1)>: Where (with DSL)

=item * B<Projection (2)>: Select, SelectMany

=item * B<Concatenation (2)>: Concat, Zip

=item * B<Partitioning (4)>: Take, Skip, TakeWhile, SkipWhile

=item * B<Ordering (13)>: OrderBy, OrderByDescending, OrderByStr, OrderByStrDescending, OrderByNum, OrderByNumDescending, Reverse, ThenBy, ThenByDescending, ThenByStr, ThenByStrDescending, ThenByNum, ThenByNumDescending

=item * B<Grouping (1)>: GroupBy

=item * B<Set Operations (4)>: Distinct, Union, Intersect, Except

=item * B<Join (2)>: Join, GroupJoin

=item * B<Quantifiers (3)>: All, Any, Contains

=item * B<Comparison (1)>: SequenceEqual

=item * B<Element Access (8)>: First, FirstOrDefault, Last, LastOrDefault, Single, SingleOrDefault, ElementAt, ElementAtOrDefault

=item * B<Aggregation (7)>: Count, Sum, Min, Max, Average, AverageOrDefault, Aggregate

=item * B<Conversion (6)>: ToArray, ToList, ToDictionary, ToLookup, ToLTSV, DefaultIfEmpty

=item * B<Utility (1)>: ForEach

=back

B<Method Summary Table:>

  Method                 Category        Lazy?  Returns
  =====================  ==============  =====  ================
  From                   Data Source     Yes    Query
  FromLTSV               Data Source     Yes    Query
  Range                  Data Source     Yes    Query
  Empty                  Data Source     Yes    Query
  Repeat                 Data Source     Yes    Query
  Where                  Filtering       Yes    Query
  Select                 Projection      Yes    Query
  SelectMany             Projection      Yes    Query
  Concat                 Concatenation   Yes    Query
  Zip                    Concatenation   Yes    Query
  Take                   Partitioning    Yes    Query
  Skip                   Partitioning    Yes    Query
  TakeWhile              Partitioning    Yes    Query
  SkipWhile              Partitioning    Yes    Query
  OrderBy                Ordering        No*    OrderedQuery
  OrderByDescending      Ordering        No*    OrderedQuery
  OrderByStr             Ordering        No*    OrderedQuery
  OrderByStrDescending   Ordering        No*    OrderedQuery
  OrderByNum             Ordering        No*    OrderedQuery
  OrderByNumDescending   Ordering        No*    OrderedQuery
  Reverse                Ordering        No*    Query
  ThenBy                 Ordering        No*    OrderedQuery
  ThenByDescending       Ordering        No*    OrderedQuery
  ThenByStr              Ordering        No*    OrderedQuery
  ThenByStrDescending    Ordering        No*    OrderedQuery
  ThenByNum              Ordering        No*    OrderedQuery
  ThenByNumDescending    Ordering        No*    OrderedQuery
  GroupBy                Grouping        No*    Query
  Distinct               Set Operation   Yes    Query
  Union                  Set Operation   No*    Query
  Intersect              Set Operation   No*    Query
  Except                 Set Operation   No*    Query
  Join                   Join            No*    Query
  GroupJoin              Join            No*    Query
  All                    Quantifier      No     Boolean
  Any                    Quantifier      No     Boolean
  Contains               Quantifier      No     Boolean
  SequenceEqual          Comparison      No     Boolean
  First                  Element Access  No     Element
  FirstOrDefault         Element Access  No     Element
  Last                   Element Access  No*    Element
  LastOrDefault          Element Access  No*    Element or undef
  Single                 Element Access  No*    Element
  SingleOrDefault        Element Access  No*    Element or undef
  ElementAt              Element Access  No*    Element
  ElementAtOrDefault     Element Access  No*    Element or undef
  Count                  Aggregation     No     Integer
  Sum                    Aggregation     No     Number
  Min                    Aggregation     No     Number
  Max                    Aggregation     No     Number
  Average                Aggregation     No     Number
  AverageOrDefault       Aggregation     No     Number or undef
  Aggregate              Aggregation     No     Any
  DefaultIfEmpty         Conversion      Yes    Query
  ToArray                Conversion      No     Array
  ToList                 Conversion      No     ArrayRef
  ToDictionary           Conversion      No     HashRef
  ToLookup               Conversion      No     HashRef
  ToLTSV                 Conversion      No     Boolean
  ForEach                Utility         No     Void

  * Materializing operation (loads all data into memory)
  OrderedQuery = LTSV::LINQ::Ordered (subclass of LTSV::LINQ;
                 all LTSV::LINQ methods available plus ThenBy* methods)

=head2 Data Source Methods

=over 4

=item B<From(\@array)>

Create a query from an array.

  my $query = LTSV::LINQ->From([{name => 'Alice'}, {name => 'Bob'}]);

=item B<FromLTSV($filename)>

Create a query from an LTSV file.

  my $query = LTSV::LINQ->FromLTSV("access.log");

B<File handle management:> C<FromLTSV> opens the file immediately and
holds the file handle open until the iterator reaches end-of-file.
If the query is not fully consumed (e.g. you call C<First> or C<Take>
and stop early), the file handle remains open until the query object
is garbage collected.

This is harmless for a small number of files, but if you open many
LTSV files concurrently without consuming them fully, you may exhaust
the OS file descriptor limit. In such cases, consume the query fully
or use C<ToArray()> to materialise the data and close the file
immediately:

  # File closed as soon as all records are loaded
  my @records = LTSV::LINQ->FromLTSV("access.log")->ToArray();

=item B<Range($start, $count)>

Generate a sequence of integers.

  my $query = LTSV::LINQ->Range(1, 10);  # 1, 2, ..., 10

=item B<Empty()>

Create an empty sequence.

B<Returns:> Empty LTSV::LINQ query

B<Examples:>

  my $empty = LTSV::LINQ->Empty();
  $empty->Count();  # 0

  # Conditional empty sequence
  my $result = $condition ? $query : LTSV::LINQ->Empty();

B<Note:> Equivalent to C<From([])> but more explicit.

=item B<Repeat($element, $count)>

Repeat the same element a specified number of times.

B<Parameters:>

=over 4

=item * C<$element> - Element to repeat

=item * C<$count> - Number of times to repeat

=back

B<Returns:> LTSV::LINQ query with repeated elements

B<Examples:>

  # Repeat scalar
  LTSV::LINQ->Repeat('x', 5)->ToArray();  # ('x', 'x', 'x', 'x', 'x')

  # Repeat reference (same reference repeated)
  my $item = {id => 1};
  LTSV::LINQ->Repeat($item, 3)->ToArray();  # ($item, $item, $item)

  # Generate default values
  LTSV::LINQ->Repeat(0, 10)->ToArray();  # (0, 0, 0, ..., 0)

B<Note:> The element reference is repeated, not cloned.

=back

=head2 Filtering Methods

=over 4

=item B<Where($predicate)>

=item B<Where(key =E<gt> value, ...)>

Filter elements. Accepts either a code reference or DSL form.

B<Code Reference Form:>

  ->Where(sub { $_[0]{status} == 200 })
  ->Where(sub { $_[0]{status} >= 400 && $_[0]{bytes} > 1000 })

The code reference receives each element as C<$_[0]> and should return
true to include the element, false to exclude it.

B<DSL Form:>

The DSL (Domain Specific Language) form provides a concise syntax for
simple equality comparisons. All conditions are combined with AND logic.

  # Single condition
  ->Where(status => '200')

  # Multiple conditions (AND)
  ->Where(status => '200', method => 'GET')

  # Equivalent to:
  ->Where(sub {
      $_[0]{status} eq '200' && $_[0]{method} eq 'GET'
  })

B<DSL Specification:>

=over 4

=item * Arguments must be an even number of C<key =E<gt> value> pairs

The DSL form interprets its arguments as a flat list of key-value pairs.
Passing an odd number of arguments produces a Perl warning
(C<Odd number of elements in hash assignment>) and the unpaired key
receives C<undef> as its value, which will never match. Always use
complete pairs:

  ->Where(status => '200')              # correct: 1 pair
  ->Where(status => '200', method => 'GET')  # correct: 2 pairs
  ->Where(status => '200', 'method')    # wrong: 3 args, Perl warning

=item * All comparisons are string equality (C<eq>)

=item * All conditions are combined with AND

=item * Undefined values are treated as failures

=item * For numeric or OR logic, use code reference form

=back

B<Examples:>

  # DSL: Simple and readable
  ->Where(status => '200')
  ->Where(user => 'alice', role => 'admin')

  # Code ref: Complex logic
  ->Where(sub { $_[0]{status} >= 400 && $_[0]{status} < 500 })
  ->Where(sub { $_[0]{user} eq 'alice' || $_[0]{user} eq 'bob' })

=back

=head2 Projection Methods

=over 4

=item B<Select($selector)>

Transform each element using the provided selector function.

The selector receives each element as C<$_[0]> and should return
the transformed value.

B<Parameters:>

=over 4

=item * C<$selector> - Code reference that transforms each element

=back

B<Returns:> New query with transformed elements (lazy)

B<Examples:>

  # Extract single field
  ->Select(sub { $_[0]{url} })

  # Transform to new structure
  ->Select(sub {
      {
          path => $_[0]{url},
          code => $_[0]{status}
      }
  })

  # Calculate derived values
  ->Select(sub { $_[0]{bytes} * 8 })  # bytes to bits

B<Note:> Select preserves one-to-one mapping. For one-to-many, use
SelectMany.

=item B<SelectMany($selector)>

Flatten nested sequences into a single sequence.

The selector should return an array reference. All arrays are flattened
into a single sequence.

B<Parameters:>

=over 4

=item * C<$selector> - Code reference returning array reference

=back

B<Returns:> New query with flattened elements (lazy)

B<Examples:>

  # Flatten array of arrays
  my @nested = ([1, 2], [3, 4], [5]);
  LTSV::LINQ->From(\@nested)
      ->SelectMany(sub { $_[0] })
      ->ToArray();  # (1, 2, 3, 4, 5)

  # Expand related records
  ->SelectMany(sub {
      my $user = shift;
      return [ map {
          { user => $user->{name}, role => $_ }
      } @{$user->{roles}} ];
  })

B<Use Cases:>

=over 4

=item * Flattening nested arrays

=item * Expanding one-to-many relationships

=item * Generating multiple outputs per input

=back

B<Important:> The selector B<must> return an ARRAY reference. If it returns
any other value (e.g. a hashref or scalar), this method throws an exception:

  die "SelectMany: selector must return an ARRAY reference"

This matches the behaviour of .NET LINQ's C<SelectMany>, which requires
the selector to return an C<IEnumerable>. Always wrap results in C<[...]>:

  ->SelectMany(sub { [ $_[0]{items} ] })   # correct: arrayref
  ->SelectMany(sub {   $_[0]{items}   })   # wrong: dies at runtime

=back

=head2 Concatenation Methods

=over 4

=item B<Concat($second)>

Concatenate two sequences into one.

B<Parameters:>

=over 4

=item * C<$second> - Second sequence (LTSV::LINQ object)

=back

B<Returns:> New query with both sequences concatenated (lazy)

B<Examples:>

  # Combine two data sources
  my $q1 = LTSV::LINQ->From([1, 2, 3]);
  my $q2 = LTSV::LINQ->From([4, 5, 6]);
  $q1->Concat($q2)->ToArray();  # (1, 2, 3, 4, 5, 6)

  # Merge LTSV files
  LTSV::LINQ->FromLTSV("jan.log")
      ->Concat(LTSV::LINQ->FromLTSV("feb.log"))
      ->Where(status => '500')

B<Note:> This operation is lazy - sequences are read on-demand.

=item B<Zip($second, $result_selector)>

Combine two sequences element-wise using a result selector function.

B<Parameters:>

=over 4

=item * C<$second> - Second sequence (LTSV::LINQ object)

=item * C<$result_selector> - Function to combine elements: ($first, $second) -> $result

=back

B<Returns:> New query with combined elements (lazy)

B<Examples:>

  # Combine numbers
  my $numbers = LTSV::LINQ->From([1, 2, 3]);
  my $letters = LTSV::LINQ->From(['a', 'b', 'c']);
  $numbers->Zip($letters, sub {
      my($num, $letter) = @_;
      return "$num-$letter";
  })->ToArray();  # ('1-a', '2-b', '3-c')

  # Create key-value pairs
  my $keys = LTSV::LINQ->From(['name', 'age', 'city']);
  my $values = LTSV::LINQ->From(['Alice', 30, 'NYC']);
  $keys->Zip($values, sub {
      return {$_[0] => $_[1]};
  })->ToArray();

  # Stops at shorter sequence
  LTSV::LINQ->From([1, 2, 3, 4])
      ->Zip(LTSV::LINQ->From(['a', 'b']), sub { [$_[0], $_[1]] })
      ->ToArray();  # ([1, 'a'], [2, 'b'])

B<Note:> Iteration stops when either sequence ends.

=back

=head2 Partitioning Methods

=over 4

=item B<Take($count)>

Take the first N elements from the sequence.

B<Parameters:>

=over 4

=item * C<$count> - Number of elements to take (integer >= 0)

=back

B<Returns:> New query limited to first N elements (lazy)

B<Examples:>

  # Top 10 results
  ->OrderByDescending(sub { $_[0]{score} })
    ->Take(10)

  # First record only
  ->Take(1)->ToArray()

  # Limit large file processing
  LTSV::LINQ->FromLTSV("huge.log")->Take(1000)

B<Note:> Take(0) returns empty sequence. Negative values treated as 0.

=item B<Skip($count)>

Skip the first N elements, return the rest.

B<Parameters:>

=over 4

=item * C<$count> - Number of elements to skip (integer >= 0)

=back

B<Returns:> New query skipping first N elements (lazy)

B<Examples:>

  # Skip header row
  ->Skip(1)

  # Pagination: page 3, size 20
  ->Skip(40)->Take(20)

  # Skip first batch
  ->Skip(1000)->ForEach(sub { ... })

B<Use Cases:>

=over 4

=item * Pagination

=item * Skipping header rows

=item * Processing in batches

=back

=item B<TakeWhile($predicate)>

Take elements while the predicate is true. Stops at first false.

B<Parameters:>

=over 4

=item * C<$predicate> - Code reference returning boolean

=back

B<Returns:> New query taking elements while predicate holds (lazy)

B<Examples:>

  # Take while value is small
  ->TakeWhile(sub { $_[0]{count} < 100 })

  # Take while timestamp is in range
  ->TakeWhile(sub { $_[0]{time} lt '2026-02-01' })

  # Process until error
  ->TakeWhile(sub { $_[0]{status} < 400 })

B<Important:> TakeWhile stops immediately when predicate returns false.
It does NOT filter - it terminates the sequence.

  # Different from Where:
  ->TakeWhile(sub { $_[0] < 5 })  # 1,2,3,4 then STOP
  ->Where(sub { $_[0] < 5 })      # 1,2,3,4 (checks all)

=item B<SkipWhile($predicate)>

Skip elements while the predicate is true. Returns rest after first false.

B<Parameters:>

=over 4

=item * C<$predicate> - Code reference returning boolean

=back

B<Returns:> New query skipping initial elements (lazy)

B<Examples:>

  # Skip header lines
  ->SkipWhile(sub { $_[0]{line} =~ /^#/ })

  # Skip while value is small
  ->SkipWhile(sub { $_[0]{count} < 100 })

  # Process after certain timestamp
  ->SkipWhile(sub { $_[0]{time} lt '2026-02-01' })

B<Important:> SkipWhile only skips initial elements. Once predicate is
false, all remaining elements are included.

  [1,2,3,4,5,2,1]->SkipWhile(sub { $_[0] < 4 })  # (4,5,2,1)

=back

=head2 Ordering Methods

B<Sort stability:> C<OrderBy*> and C<ThenBy*> use a Schwartzian-Transform
decorated-array technique that appends the original element index as a
final tie-breaker.  This guarantees completely stable multi-key sorting on
B<every Perl version including 5.005_03>, where built-in C<sort> stability
is not guaranteed.

B<Comparison type:> LTSV::LINQ provides three families:

=over 4

=item * C<OrderBy> / C<OrderByDescending> / C<ThenBy> / C<ThenByDescending>

Smart comparison: numeric (C<E<lt>=E<gt>>) when both keys look numeric,
string (C<cmp>) otherwise. Convenient for LTSV data where field values
are always strings but commonly hold numbers.

=item * C<OrderByStr> / C<OrderByStrDescending> / C<ThenByStr> / C<ThenByStrDescending>

Unconditional string comparison (C<cmp>). Use when keys must sort
lexicographically regardless of content (e.g. version strings, codes).

=item * C<OrderByNum> / C<OrderByNumDescending> / C<ThenByNum> / C<ThenByNumDescending>

Unconditional numeric comparison (C<E<lt>=E<gt>>). Use when keys are
always numeric. Undefined or empty values are treated as C<0>.

=back

B<IOrderedEnumerable:> C<OrderBy*> methods return a C<LTSV::LINQ::Ordered>
object (a subclass of C<LTSV::LINQ>).  This mirrors the way .NET LINQ's
C<OrderBy> returns C<IOrderedEnumerable<T>>, which exposes C<ThenBy> and
C<ThenByDescending>.  All C<LTSV::LINQ> methods (C<Where>, C<Select>,
C<Take>, etc.) are available on the returned object through inheritance.
C<ThenBy*> methods are B<only> available on C<LTSV::LINQ::Ordered> objects,
not on plain C<LTSV::LINQ> objects.

B<Non-destructive:> C<ThenBy*> always returns a B<new> C<LTSV::LINQ::Ordered>
object; the original is unchanged.  Branching sort chains work correctly:

  my $by_dept = LTSV::LINQ->From(\@data)->OrderBy(sub { $_[0]{dept} });
  my $asc  = $by_dept->ThenBy(sub    { $_[0]{name}   });
  my $desc = $by_dept->ThenByNum(sub { $_[0]{salary} });
  # $asc and $desc are completely independent queries

=over 4

=item B<OrderBy($key_selector)>

Sort in ascending order using smart comparison: if both keys look like
numbers (integers, decimals, negative, or exponential notation), numeric
comparison (C<E<lt>=E<gt>>) is used; otherwise string comparison (C<cmp>)
is used. Returns a C<LTSV::LINQ::Ordered> object.

  ->OrderBy(sub { $_[0]{timestamp} })   # string keys: lexicographic
  ->OrderBy(sub { $_[0]{bytes} })       # "1024", "256" -> numeric (256, 1024)

B<Note:> When you need explicit control over the comparison type, use
C<OrderByStr> (always C<cmp>) or C<OrderByNum> (always C<E<lt>=E<gt>>).

=item B<OrderByDescending($key_selector)>

Sort in descending order using the same smart comparison as C<OrderBy>.
Returns a C<LTSV::LINQ::Ordered> object.

  ->OrderByDescending(sub { $_[0]{count} })

=item B<OrderByStr($key_selector)>

Sort in ascending order using string comparison (C<cmp>) unconditionally.
Returns a C<LTSV::LINQ::Ordered> object.

  ->OrderByStr(sub { $_[0]{code} })    # "10" lt "9" (lexicographic)

=item B<OrderByStrDescending($key_selector)>

Sort in descending order using string comparison (C<cmp>) unconditionally.
Returns a C<LTSV::LINQ::Ordered> object.

  ->OrderByStrDescending(sub { $_[0]{name} })

=item B<OrderByNum($key_selector)>

Sort in ascending order using numeric comparison (C<E<lt>=E<gt>>)
unconditionally. Returns a C<LTSV::LINQ::Ordered> object.

  ->OrderByNum(sub { $_[0]{bytes} })   # 9 < 10 (numeric)

B<Note:> Undefined or empty values are treated as C<0>.

=item B<OrderByNumDescending($key_selector)>

Sort in descending order using numeric comparison (C<E<lt>=E<gt>>)
unconditionally. Returns a C<LTSV::LINQ::Ordered> object.

  ->OrderByNumDescending(sub { $_[0]{response_time} })

=item B<Reverse()>

Reverse the order.

  ->Reverse()

=item B<ThenBy($key_selector)>

Add an ascending secondary sort key using smart comparison.  Must be
called on a C<LTSV::LINQ::Ordered> object (i.e., after C<OrderBy*>).
Returns a new C<LTSV::LINQ::Ordered> object; the original is unchanged.

  ->OrderBy(sub { $_[0]{dept} })->ThenBy(sub { $_[0]{name} })

=item B<ThenByDescending($key_selector)>

Add a descending secondary sort key using smart comparison.

  ->OrderBy(sub { $_[0]{dept} })->ThenByDescending(sub { $_[0]{salary} })

=item B<ThenByStr($key_selector)>

Add an ascending secondary sort key using string comparison (C<cmp>).

  ->OrderByStr(sub { $_[0]{dept} })->ThenByStr(sub { $_[0]{code} })

=item B<ThenByStrDescending($key_selector)>

Add a descending secondary sort key using string comparison (C<cmp>).

  ->OrderByStr(sub { $_[0]{dept} })->ThenByStrDescending(sub { $_[0]{name} })

=item B<ThenByNum($key_selector)>

Add an ascending secondary sort key using numeric comparison (C<E<lt>=E<gt>>).

  ->OrderByStr(sub { $_[0]{dept} })->ThenByNum(sub { $_[0]{salary} })

=item B<ThenByNumDescending($key_selector)>

Add a descending secondary sort key using numeric comparison (C<E<lt>=E<gt>>).
Undefined or empty values are treated as C<0>.

  ->OrderByStr(sub { $_[0]{host} })->ThenByNumDescending(sub { $_[0]{bytes} })

=back

=head2 Grouping Methods

=over 4

=item B<GroupBy($key_selector [, $element_selector])>

Group elements by key.

B<Returns:> New query where each element is a hashref with two fields:

=over 4

=item * C<Key> - The group key (string)

=item * C<Elements> - Array reference of elements in the group

=back

B<Note:> This operation is eager - the entire sequence is loaded into memory
immediately. Groups are returned in the order their keys first appear in
the source sequence, matching the behaviour of .NET LINQ's C<GroupBy>.

B<Examples:>

  # Group access log by status code
  my @groups = LTSV::LINQ->FromLTSV('access.log')
      ->GroupBy(sub { $_[0]{status} })
      ->ToArray();

  for my $g (@groups) {
      printf "status=%s count=%d\n", $g->{Key}, scalar @{$g->{Elements}};
  }

  # With element selector
  ->GroupBy(sub { $_[0]{status} }, sub { $_[0]{path} })

B<Note:> C<Elements> is a plain array reference, not a LTSV::LINQ object.
To apply further LINQ operations on a group, wrap it with C<From>:

  for my $g (@groups) {
      my $total = LTSV::LINQ->From($g->{Elements})
          ->Sum(sub { $_[0]{bytes} });
      printf "status=%s total_bytes=%d\n", $g->{Key}, $total;
  }

=back

=head2 Set Operations

B<Evaluation model:>

=over 4

=item * C<Distinct> is fully lazy: elements are tested one by one as the
output sequence is consumed.

=item * C<Union>, C<Intersect>, C<Except> are B<partially eager>: when
the method is called, the B<second> sequence is consumed in full and
stored in an in-memory hash for O(1) lookup. The B<first> sequence is
then iterated lazily. This matches the behaviour of .NET LINQ, which
also buffers the second (hash-side) sequence up front.

=back

=over 4

=item B<Distinct([$key_selector])>

Remove duplicate elements.

B<Parameters:>

=over 4

=item * C<$key_selector> - (Optional) Code ref: C<($element) -E<gt> $key>.
Extracts a comparison key from each element. This is a single-argument
function (unlike Perl's C<sort> comparator), and is I<not> a two-argument
comparison function.

=back

  ->Distinct()
  ->Distinct(sub { lc($_[0]) })          # case-insensitive strings
  ->Distinct(sub { $_[0]{id} })          # hashref: dedupe by field

=item B<Union($second [, $key_selector])>

Produce set union of two sequences (no duplicates).

B<Parameters:>

=over 4

=item * C<$second> - Second sequence (LTSV::LINQ object)

=item * C<$key_selector> - (Optional) Code ref: C<($element) -E<gt> $key>.
Single-argument key extraction function (not a two-argument sort comparator).

=back

B<Returns:> New query with elements from both sequences (distinct)

B<Evaluation:> B<Partially eager.> The first sequence is iterated lazily;
the second is fully consumed at call time and stored in memory.

B<Examples:>

  # Simple union
  my $q1 = LTSV::LINQ->From([1, 2, 3]);
  my $q2 = LTSV::LINQ->From([3, 4, 5]);
  $q1->Union($q2)->ToArray();  # (1, 2, 3, 4, 5)

  # Case-insensitive union
  ->Union($other, sub { lc($_[0]) })

B<Note:> Equivalent to Concat()->Distinct(). Automatically removes duplicates.

=item B<Intersect($second [, $key_selector])>

Produce set intersection of two sequences.

B<Parameters:>

=over 4

=item * C<$second> - Second sequence (LTSV::LINQ object)

=item * C<$key_selector> - (Optional) Code ref: C<($element) -E<gt> $key>.
Single-argument key extraction function (not a two-argument sort comparator).

=back

B<Returns:> New query with common elements only (distinct)

B<Evaluation:> B<Partially eager.> The second sequence is fully consumed
at call time and stored in a hash; the first is iterated lazily.

B<Examples:>

  # Common elements
  LTSV::LINQ->From([1, 2, 3])
      ->Intersect(LTSV::LINQ->From([2, 3, 4]))
      ->ToArray();  # (2, 3)

  # Find users in both lists
  $users1->Intersect($users2, sub { $_[0]{id} })

B<Note:> Only includes elements present in both sequences.

=item B<Except($second [, $key_selector])>

Produce set difference (elements in first but not in second).

B<Parameters:>

=over 4

=item * C<$second> - Second sequence (LTSV::LINQ object)

=item * C<$key_selector> - (Optional) Code ref: C<($element) -E<gt> $key>.
Single-argument key extraction function (not a two-argument sort comparator).

=back

B<Returns:> New query with elements only in first sequence (distinct)

B<Evaluation:> B<Partially eager.> The second sequence is fully consumed
at call time and stored in a hash; the first is iterated lazily.

B<Examples:>

  # Set difference
  LTSV::LINQ->From([1, 2, 3])
      ->Except(LTSV::LINQ->From([2, 3, 4]))
      ->ToArray();  # (1)

  # Find users in first list but not second
  $all_users->Except($inactive_users, sub { $_[0]{id} })

B<Note:> Returns elements from first sequence not present in second.

=back

=head2 Join Operations

B<Evaluation model:> Both C<Join> and C<GroupJoin> are B<partially eager>:
when the method is called, the B<inner> sequence is consumed in full and
stored in an in-memory lookup table (hash of arrays, keyed by inner key).
The B<outer> sequence is then iterated lazily, producing results on demand.

This matches the behaviour of .NET LINQ's hash-join implementation.
The memory cost is O(inner size); for very large inner sequences, consider
reversing the join or pre-filtering the inner sequence before passing it.

=over 4

=item B<Join($inner, $outer_key_selector, $inner_key_selector, $result_selector)>

Correlate elements of two sequences based on matching keys (inner join).

B<Parameters:>

=over 4

=item * C<$inner> - Inner sequence (LTSV::LINQ object)

=item * C<$outer_key_selector> - Function to extract key from outer element

=item * C<$inner_key_selector> - Function to extract key from inner element

=item * C<$result_selector> - Function to create result: ($outer_item, $inner_item) -> $result

=back

B<Returns:> Query with joined results

B<Examples:>

  # Join users with their orders
  my $users = LTSV::LINQ->From([
      {id => 1, name => 'Alice'},
      {id => 2, name => 'Bob'}
  ]);

  my $orders = LTSV::LINQ->From([
      {user_id => 1, product => 'Book'},
      {user_id => 1, product => 'Pen'},
      {user_id => 2, product => 'Notebook'}
  ]);

  $users->Join(
      $orders,
      sub { $_[0]{id} },          # outer key
      sub { $_[0]{user_id} },     # inner key
      sub {
          my($user, $order) = @_;
          return {
              name => $user->{name},
              product => $order->{product}
          };
      }
  )->ToArray();
  # [{name => 'Alice', product => 'Book'},
  #  {name => 'Alice', product => 'Pen'},
  #  {name => 'Bob', product => 'Notebook'}]

  # Join LTSV files by request ID
  LTSV::LINQ->FromLTSV('access.log')->Join(
      LTSV::LINQ->FromLTSV('error.log'),
      sub { $_[0]{request_id} },
      sub { $_[0]{request_id} },
      sub {
          my($access, $error) = @_;
          return {
              url => $access->{url},
              error => $error->{message}
          };
      }
  )

B<Note:> This is an inner join - only matching elements are returned.
The inner sequence is fully loaded into memory.

=item B<GroupJoin($inner, $outer_key_selector, $inner_key_selector, $result_selector)>

Correlates elements of two sequences with group join (LEFT OUTER JOIN-like).
Each outer element is matched with a group of inner elements (possibly empty).

B<Parameters:>

=over 4

=item * C<$inner> - Inner sequence (LTSV::LINQ object)

=item * C<$outer_key_selector> - Function to extract key from outer element

=item * C<$inner_key_selector> - Function to extract key from inner element

=item * C<$result_selector> - Function: ($outer_item, $inner_group) -> $result.
The C<$inner_group> is a LTSV::LINQ object containing matched inner elements
(empty sequence if no matches).

=back

B<Returns:> New query with one result per outer element (lazy)

B<Examples:>

  # Order count per user (including users with no orders)
  my $users = LTSV::LINQ->From([
      {id => 1, name => 'Alice'},
      {id => 2, name => 'Bob'},
      {id => 3, name => 'Carol'}
  ]);

  my $orders = LTSV::LINQ->From([
      {user_id => 1, product => 'Book', amount => 10},
      {user_id => 1, product => 'Pen', amount => 5},
      {user_id => 2, product => 'Notebook', amount => 15}
  ]);

  $users->GroupJoin(
      $orders,
      sub { $_[0]{id} },
      sub { $_[0]{user_id} },
      sub {
          my($user, $orders) = @_;
          return {
              name  => $user->{name},
              count => $orders->Count(),
              total => $orders->Sum(sub { $_[0]{amount} })
          };
      }
  )->ToArray();
  # [
  #   {name => 'Alice', count => 2, total => 15},
  #   {name => 'Bob', count => 1, total => 15},
  #   {name => 'Carol', count => 0, total => 0},  # no orders
  # ]

  # Flat list with no-match rows included (LEFT OUTER JOIN, cf. Join for inner join)
  $users->GroupJoin(
      $orders,
      sub { $_[0]{id} },
      sub { $_[0]{user_id} },
      sub {
          my($user, $user_orders) = @_;
          my @rows = $user_orders->ToArray();
          return @rows
              ? [ map { {name => $user->{name}, product => $_->{product}} } @rows ]
              : [ {name => $user->{name}, product => 'none'} ];
      }
  )->SelectMany(sub { $_[0] }) # Flatten the array references
   ->ToArray();

B<Note:> Unlike Join, every outer element appears in the result even when
there are no matching inner elements (LEFT OUTER JOIN semantics).
The inner sequence is fully loaded into memory.

B<Important:> The C<$inner_group> LTSV::LINQ object is highly flexible.
It is specifically designed to be iterated multiple times within the
result selector (e.g., calling C<Count()> followed by C<Sum()>) because
it generates a fresh iterator for every terminal operation.

=back

=head2 Quantifier Methods

=over 4

=item B<All($predicate)>

Test if all elements satisfy condition.

  ->All(sub { $_[0]{status} == 200 })

=item B<Any([$predicate])>

Test if any element satisfies condition.

  ->Any(sub { $_[0]{status} >= 400 })
  ->Any()  # Test if sequence is non-empty

=item B<Contains($value [, $comparer])>

Check if sequence contains specified element.

B<Parameters:>

=over 4

=item * C<$value> - Value to search for

=item * C<$comparer> - (Optional) Custom comparison function

=back

B<Returns:> Boolean (1 or 0)

B<Examples:>

  # Simple search
  ->Contains(5)  # 1 if found, 0 otherwise

  # Case-insensitive search
  ->Contains('foo', sub { lc($_[0]) eq lc($_[1]) })

  # Check for undef
  ->Contains(undef)

=item B<SequenceEqual($second [, $comparer])>

Determine if two sequences are equal (same elements in same order).

B<Parameters:>

=over 4

=item * C<$second> - Second sequence (LTSV::LINQ object)

=item * C<$comparer> - (Optional) Comparison function ($a, $b) -> boolean

=back

B<Returns:> Boolean (1 if equal, 0 otherwise)

B<Examples:>

  # Same sequences
  LTSV::LINQ->From([1, 2, 3])
      ->SequenceEqual(LTSV::LINQ->From([1, 2, 3]))  # 1 (true)

  # Different elements
  LTSV::LINQ->From([1, 2, 3])
      ->SequenceEqual(LTSV::LINQ->From([1, 2, 4]))  # 0 (false)

  # Different lengths
  LTSV::LINQ->From([1, 2])
      ->SequenceEqual(LTSV::LINQ->From([1, 2, 3]))  # 0 (false)

  # Case-insensitive comparison
  $seq1->SequenceEqual($seq2, sub { lc($_[0]) eq lc($_[1]) })

B<Note:> Order matters. Both content AND order must match.

=back

=head2 Element Access Methods

=over 4

=item B<First([$predicate])>

Get first element. Dies if empty.

  ->First()
  ->First(sub { $_[0]{status} == 404 })

=item B<FirstOrDefault([$predicate,] $default)>

Get first element or default value.

  ->FirstOrDefault(undef, {})

=item B<Last([$predicate])>

Get last element. Dies if empty.

  ->Last()

=item B<LastOrDefault([$predicate,] $default)>

Get last element or default value. Never throws exceptions.

B<Parameters:>

=over 4

=item * C<$predicate> - (Optional) Condition

=item * C<$default> - (Optional) Value to return when no element is found.
Defaults to C<undef> when omitted.

=back

B<Returns:> Last element or C<$default>

B<Examples:>

  # Get last element (undef if empty)
  ->LastOrDefault()

  # Specify a default value
  LTSV::LINQ->From([])->LastOrDefault(undef, 0)  # 0

  # With predicate and default
  ->LastOrDefault(sub { $_[0] % 2 == 0 }, -1)  # Last even, or -1

=item B<Single([$predicate])>

Get the only element. Dies if sequence has zero or more than one element.

B<Parameters:>

=over 4

=item * C<$predicate> - (Optional) Condition

=back

B<Returns:> Single element

B<Exceptions:>
- Dies with "Sequence contains no elements" if empty
- Dies with "Sequence contains more than one element" if multiple elements

B<.NET LINQ Compatibility:> Exception messages match .NET LINQ behavior exactly.

B<Performance:> Uses lazy evaluation. Stops iterating immediately when
second element is found (does not load entire sequence).

B<Examples:>

  # Exactly one element
  LTSV::LINQ->From([5])->Single()  # 5

  # With predicate
  ->Single(sub { $_[0] > 10 })

  # Memory-efficient: stops at 2nd element
  LTSV::LINQ->FromLTSV("huge.log")->Single(sub { $_[0]{id} eq '999' })

=item B<SingleOrDefault([$predicate])>

Get the only element, or undef if zero or multiple elements.

B<Returns:> Single element or undef (if 0 or 2+ elements)

B<.NET LINQ Compatibility:> B<Note:> .NET's C<SingleOrDefault> throws
C<InvalidOperationException> when the sequence contains more than one
element. LTSV::LINQ returns C<undef> in that case instead of throwing,
which makes it more convenient for Perl code that checks return values.
If you require the strict .NET behaviour (exception on multiple elements),
use C<Single()> wrapped in C<eval>.

B<Performance:> Uses lazy evaluation. Memory-efficient.

B<Examples:>

  LTSV::LINQ->From([5])->SingleOrDefault()  # 5
  LTSV::LINQ->From([])->SingleOrDefault()   # undef (empty)
  LTSV::LINQ->From([1,2])->SingleOrDefault()  # undef (multiple)

=item B<ElementAt($index)>

Get element at specified index. Dies if out of range.

B<Parameters:>

=over 4

=item * C<$index> - Zero-based index

=back

B<Returns:> Element at index

B<Exceptions:> Dies if index is negative or out of range

B<Performance:> Uses lazy evaluation (iterator-based). Does NOT load
entire sequence into memory. Stops iterating once target index is reached.

B<Examples:>

  ->ElementAt(0)  # First element
  ->ElementAt(2)  # Third element

  # Memory-efficient for large files
  LTSV::LINQ->FromLTSV("huge.log")->ElementAt(10)  # Reads only 11 lines

=item B<ElementAtOrDefault($index)>

Get element at index, or undef if out of range.

B<Returns:> Element or undef

B<Performance:> Uses lazy evaluation (iterator-based). Memory-efficient.

B<Examples:>

  ->ElementAtOrDefault(0)   # First element
  ->ElementAtOrDefault(99)  # undef if out of range

=back

=head2 Aggregation Methods

All aggregation methods are B<terminal operations> - they consume the
entire sequence and return a scalar value.

=over 4

=item B<Count([$predicate])>

Count the number of elements.

B<Parameters:>

=over 4

=item * C<$predicate> - (Optional) Code reference to filter elements

=back

B<Returns:> Integer count

B<Examples:>

  # Count all
  ->Count()  # 1000

  # Count with condition
  ->Count(sub { $_[0]{status} >= 400 })  # 42

  # Equivalent to
  ->Where(sub { $_[0]{status} >= 400 })->Count()

B<Performance:> O(n) - must iterate entire sequence

=item B<Sum([$selector])>

Calculate sum of numeric values.

B<Parameters:>

=over 4

=item * C<$selector> - (Optional) Code reference to extract value.
Default: identity function

=back

B<Returns:> Numeric sum

B<Examples:>

  # Sum of values
  LTSV::LINQ->From([1, 2, 3, 4, 5])->Sum()  # 15

  # Sum of field
  ->Sum(sub { $_[0]{bytes} })

  # Sum with transformation
  ->Sum(sub { $_[0]{price} * $_[0]{quantity} })

B<Note:> Non-numeric values may produce warnings. Use numeric context.

B<Empty sequence:> Returns C<0>.

=item B<Min([$selector])>

Find minimum value.

B<Parameters:>

=over 4

=item * C<$selector> - (Optional) Code reference to extract value

=back

B<Returns:> Minimum value, or C<undef> if sequence is empty.

B<Examples:>

  # Minimum of values
  ->Min()

  # Minimum of field
  ->Min(sub { $_[0]{response_time} })

  # Oldest timestamp
  ->Min(sub { $_[0]{timestamp} })

=item B<Max([$selector])>

Find maximum value.

B<Parameters:>

=over 4

=item * C<$selector> - (Optional) Code reference to extract value

=back

B<Returns:> Maximum value, or C<undef> if sequence is empty.

B<Examples:>

  # Maximum of values
  ->Max()

  # Maximum of field
  ->Max(sub { $_[0]{bytes} })

  # Latest timestamp
  ->Max(sub { $_[0]{timestamp} })

=item B<Average([$selector])>

Calculate arithmetic mean.

B<Parameters:>

=over 4

=item * C<$selector> - (Optional) Code reference to extract value

=back

B<Returns:> Numeric average (floating point)

B<Examples:>

  # Average of values
  LTSV::LINQ->From([1, 2, 3, 4, 5])->Average()  # 3

  # Average of field
  ->Average(sub { $_[0]{bytes} })

  # Average response time
  ->Average(sub { $_[0]{response_time} })

B<Empty sequence:> Dies with "Sequence contains no elements".
Unlike C<Sum> (returns 0) and C<Min>/C<Max> (return C<undef>), C<Average>
throws on an empty sequence. Use C<AverageOrDefault> to avoid the exception.

B<Note:> Returns floating point. Use C<int()> for integer result.

=item B<AverageOrDefault([$selector])>

Calculate arithmetic mean, or return undef if sequence is empty.

B<Parameters:>

=over 4

=item * C<$selector> - (Optional) Code reference to extract value

=back

B<Returns:> Numeric average (floating point), or undef if empty

B<Examples:>

  # Safe average - returns undef for empty sequence
  my @empty = ();
  my $avg = LTSV::LINQ->From(\@empty)->AverageOrDefault();  # undef

  # With data
  LTSV::LINQ->From([1, 2, 3])->AverageOrDefault();  # 2

  # With selector
  ->AverageOrDefault(sub { $_[0]{value} })

B<Note:> Unlike Average(), this method never throws an exception.

=item B<Aggregate([$seed,] $func [, $result_selector])>

Apply an accumulator function over a sequence.

B<Signatures:>

=over 4

=item * C<Aggregate($func)> - Use first element as seed

=item * C<Aggregate($seed, $func)> - Explicit seed value

=item * C<Aggregate($seed, $func, $result_selector)> - Transform result

=back

B<Parameters:>

=over 4

=item * C<$seed> - Initial accumulator value (optional for first signature)

=item * C<$func> - Code reference: ($accumulator, $element) -> $new_accumulator

=item * C<$result_selector> - (Optional) Transform final result

=back

B<Returns:> Accumulated value

B<Examples:>

  # Sum (without seed)
  LTSV::LINQ->From([1,2,3,4])->Aggregate(sub { $_[0] + $_[1] })  # 10

  # Product (with seed)
  LTSV::LINQ->From([2,3,4])->Aggregate(1, sub { $_[0] * $_[1] })  # 24

  # Concatenate strings
  LTSV::LINQ->From(['a','b','c'])
      ->Aggregate('', sub { $_[0] ? "$_[0],$_[1]" : $_[1] })  # 'a,b,c'

  # With result selector
  LTSV::LINQ->From([1,2,3])
      ->Aggregate(0,
          sub { $_[0] + $_[1] },      # accumulate
          sub { "Sum: $_[0]" })       # transform result
  # "Sum: 6"

  # Build complex structure
  ->Aggregate([], sub {
      my($list, $item) = @_;
      push @$list, uc($item);
      return $list;
  })

B<.NET LINQ Compatibility:> Supports all three .NET signatures.

=back

=head2 Conversion Methods

=over 4

=item B<ToArray()>

Convert to array.

  my @array = $query->ToArray();

=item B<ToList()>

Convert to array reference.

  my $arrayref = $query->ToList();

=item B<ToDictionary($key_selector [, $value_selector])>

Convert sequence to hash reference with unique keys.

B<Parameters:>

=over 4

=item * C<$key_selector> - Function to extract key from element

=item * C<$value_selector> - (Optional) Function to extract value, defaults to element itself

=back

B<Returns:> Hash reference

B<Examples:>

  # ID to name mapping
  my $users = LTSV::LINQ->From([
      {id => 1, name => 'Alice'},
      {id => 2, name => 'Bob'}
  ]);

  my $dict = $users->ToDictionary(
      sub { $_[0]{id} },
      sub { $_[0]{name} }
  );
  # {1 => 'Alice', 2 => 'Bob'}

  # Without value selector (stores entire element)
  my $dict = $users->ToDictionary(sub { $_[0]{id} });
  # {1 => {id => 1, name => 'Alice'}, 2 => {id => 2, name => 'Bob'}}

  # Quick lookup table
  my $status_codes = LTSV::LINQ->FromLTSV('access.log')
      ->Select(sub { $_[0]{status} })
      ->Distinct()
      ->ToDictionary(sub { $_ }, sub { 1 });

B<Note:> If duplicate keys exist, later values overwrite earlier ones.

B<.NET LINQ Compatibility:> .NET's C<ToDictionary> throws C<ArgumentException>
on duplicate keys. This module silently overwrites with the later value,
following Perl hash semantics. Use C<ToLookup> if you need to preserve all
values for each key.

=item B<ToLookup($key_selector [, $value_selector])>

Convert sequence to hash reference with grouped values (multi-value dictionary).

B<Parameters:>

=over 4

=item * C<$key_selector> - Function to extract key from element

=item * C<$value_selector> - (Optional) Function to extract value, defaults to element itself

=back

B<Returns:> Hash reference where values are array references

B<Examples:>

  # Group orders by user ID
  my $orders = LTSV::LINQ->From([
      {user_id => 1, product => 'Book'},
      {user_id => 1, product => 'Pen'},
      {user_id => 2, product => 'Notebook'}
  ]);

  my $lookup = $orders->ToLookup(
      sub { $_[0]{user_id} },
      sub { $_[0]{product} }
  );
  # {
  #   1 => ['Book', 'Pen'],
  #   2 => ['Notebook']
  # }

  # Group LTSV by status code
  my $by_status = LTSV::LINQ->FromLTSV('access.log')
      ->ToLookup(sub { $_[0]{status} });
  # {
  #   '200' => [{...}, {...}, ...],
  #   '404' => [{...}, ...],
  #   '500' => [{...}]
  # }

B<Note:> Unlike ToDictionary, this preserves all values for each key.

=item B<DefaultIfEmpty([$default_value])>

Return default value if sequence is empty, otherwise return the sequence.

B<Parameters:>

=over 4

=item * C<$default_value> - (Optional) Default value, defaults to undef

=back

B<Returns:> New query with default value if empty (lazy)

B<Examples:>

  # Return 0 if empty
  ->DefaultIfEmpty(0)->ToArray()  # (0) if empty, or original data

  # With undef default
  ->DefaultIfEmpty()->First()  # undef if empty

  # Useful for left joins
  ->Where(condition)->DefaultIfEmpty({id => 0, name => 'None'})

B<Note:> This is useful for ensuring a sequence always has at least
one element.

=item B<ToLTSV($filename)>

Write to LTSV file.

  $query->ToLTSV("output.ltsv");

=back

=head2 Utility Methods

=over 4

=item B<ForEach($action)>

Execute action for each element.

  $query->ForEach(sub { print $_[0]{url}, "\n" });

=back

=head1 EXAMPLES

=head2 Basic Filtering

  use LTSV::LINQ;

  # DSL syntax
  my @successful = LTSV::LINQ->FromLTSV("access.log")
      ->Where(status => '200')
      ->ToArray();

  # Code reference
  my @errors = LTSV::LINQ->FromLTSV("access.log")
      ->Where(sub { $_[0]{status} >= 400 })
      ->ToArray();

=head2 Aggregation

  # Count errors
  my $error_count = LTSV::LINQ->FromLTSV("access.log")
      ->Where(sub { $_[0]{status} >= 400 })
      ->Count();

  # Average bytes for successful requests
  my $avg_bytes = LTSV::LINQ->FromLTSV("access.log")
      ->Where(status => '200')
      ->Average(sub { $_[0]{bytes} });

  print "Average bytes: $avg_bytes\n";

=head2 Grouping and Ordering

  # Top 10 URLs by request count
  my @top_urls = LTSV::LINQ->FromLTSV("access.log")
      ->Where(sub { $_[0]{status} eq '200' })
      ->GroupBy(sub { $_[0]{url} })
      ->Select(sub {
          my $g = shift;
          return {
              URL => $g->{Key},
              Count => scalar(@{$g->{Elements}}),
              TotalBytes => LTSV::LINQ->From($g->{Elements})
                  ->Sum(sub { $_[0]{bytes} })
          };
      })
      ->OrderByDescending(sub { $_[0]{Count} })
      ->Take(10)
      ->ToArray();

  for my $stat (@top_urls) {
      printf "%5d requests - %s (%d bytes)\n",
          $stat->{Count}, $stat->{URL}, $stat->{TotalBytes};
  }

=head2 Complex Query Chain

  # Multi-step analysis
  my @result = LTSV::LINQ->FromLTSV("access.log")
      ->Where(status => '200')              # Filter successful
      ->Select(sub { $_[0]{bytes} })         # Extract bytes
      ->Where(sub { $_[0] > 1000 })          # Large responses only
      ->OrderByDescending(sub { $_[0] })     # Sort descending
      ->Take(100)                             # Top 100
      ->ToArray();

  print "Largest 100 successful responses:\n";
  print "  ", join(", ", @result), "\n";

=head2 Lazy Processing of Large Files

  # Process huge file with constant memory
  LTSV::LINQ->FromLTSV("huge.log")
      ->Where(sub { $_[0]{level} eq 'ERROR' })
      ->ForEach(sub {
          my $rec = shift;
          print "ERROR at $rec->{time}: $rec->{message}\n";
      });

=head2 Quantifiers

  # Check if all requests are successful
  my $all_ok = LTSV::LINQ->FromLTSV("access.log")
      ->All(sub { $_[0]{status} < 400 });

  print $all_ok ? "All OK\n" : "Some errors\n";

  # Check if any errors exist
  my $has_errors = LTSV::LINQ->FromLTSV("access.log")
      ->Any(sub { $_[0]{status} >= 500 });

  print "Server errors detected\n" if $has_errors;

=head2 Data Transformation

  # Read LTSV, transform, write back
  LTSV::LINQ->FromLTSV("input.ltsv")
      ->Select(sub {
          my $rec = shift;
          return {
              %$rec,
              processed => 1,
              timestamp => time(),
          };
      })
      ->ToLTSV("output.ltsv");

=head2 Working with Arrays

  # Query in-memory data
  my @data = (
      {name => 'Alice', age => 30, city => 'Tokyo'},
      {name => 'Bob',   age => 25, city => 'Osaka'},
      {name => 'Carol', age => 35, city => 'Tokyo'},
  );

  my @tokyo_residents = LTSV::LINQ->From(\@data)
      ->Where(city => 'Tokyo')
      ->OrderBy(sub { $_[0]{age} })
      ->ToArray();

=head1 FEATURES

=head2 Lazy Evaluation

All query operations use lazy evaluation via iterators. Data is
processed on-demand, not all at once.

  # Only reads 10 records from file
  my @top10 = LTSV::LINQ->FromLTSV("huge.log")
      ->Take(10)
      ->ToArray();

=head2 Method Chaining

All methods (except terminal operations like ToArray) return a new
query object, enabling fluent method chaining.

  ->Where(...)->Select(...)->OrderBy(...)->Take(10)

=head2 DSL Syntax

Simple key-value filtering without code references.

  # Readable and concise
  ->Where(status => '200', method => 'GET')

  # Instead of
  ->Where(sub { $_[0]{status} eq '200' && $_[0]{method} eq 'GET' })

=head1 ARCHITECTURE

=head2 Iterator-Based Design

LTSV::LINQ uses an iterator-based architecture for lazy evaluation.

B<Core Concept:>

Each query operation returns a new query object wrapping an iterator
(a code reference that produces one element per call).

  my $iter = sub {
      # Read next element
      # Apply transformation
      # Return element or undef
  };

  my $query = LTSV::LINQ->new($iter);

B<Benefits:>

=over 4

=item * B<Memory Efficiency> - O(1) memory for most operations

=item * B<Lazy Evaluation> - Elements computed on-demand

=item * B<Composability> - Iterators chain naturally

=item * B<Early Termination> - Stop processing when done

=back

=head2 Method Categories

The table below shows, for every method, whether it is lazy or eager,
and what it returns.  Knowing this prevents surprises about memory use
and iterator consumption.

  Method                Category        Evaluation         Returns
  ------                --------        ----------         -------
  From                  Source          Lazy (factory)     Query
  FromLTSV              Source          Lazy (factory)     Query
  Range                 Source          Lazy               Query
  Empty                 Source          Lazy               Query
  Repeat                Source          Lazy               Query
  Where                 Filter          Lazy               Query
  Select                Projection      Lazy               Query
  SelectMany            Projection      Lazy               Query
  Concat                Concatenation   Lazy               Query
  Zip                   Concatenation   Lazy               Query
  Take                  Partitioning    Lazy               Query
  Skip                  Partitioning    Lazy               Query
  TakeWhile             Partitioning    Lazy               Query
  SkipWhile             Partitioning    Lazy               Query
  Distinct              Set Operation   Lazy (1st seq)     Query
  DefaultIfEmpty        Conversion      Lazy               Query
  OrderBy               Ordering        Eager (full)       Query
  OrderByDescending     Ordering        Eager (full)       Query
  OrderByStr            Ordering        Eager (full)       Query
  OrderByStrDescending  Ordering        Eager (full)       Query
  OrderByNum            Ordering        Eager (full)       Query
  OrderByNumDescending  Ordering        Eager (full)       Query
  Reverse               Ordering        Eager (full)       Query
  GroupBy               Grouping        Eager (full)       Query
  Union                 Set Operation   Eager (2nd seq)    Query
  Intersect             Set Operation   Eager (2nd seq)    Query
  Except                Set Operation   Eager (2nd seq)    Query
  Join                  Join            Eager (inner seq)  Query
  GroupJoin             Join            Eager (inner seq)  Query
  All                   Quantifier      Lazy (early exit)  Boolean
  Any                   Quantifier      Lazy (early exit)  Boolean
  Contains              Quantifier      Lazy (early exit)  Boolean
  SequenceEqual         Comparison      Lazy (early exit)  Boolean
  First                 Element Access  Lazy (early exit)  Element
  FirstOrDefault        Element Access  Lazy (early exit)  Element
  Last                  Element Access  Eager (full)       Element
  LastOrDefault         Element Access  Eager (full)       Element
  Single                Element Access  Lazy (stops at 2)  Element
  SingleOrDefault       Element Access  Lazy (stops at 2)  Element
  ElementAt             Element Access  Lazy (early exit)  Element
  ElementAtOrDefault    Element Access  Lazy (early exit)  Element
  Count                 Aggregation     Eager (full)       Integer
  Sum                   Aggregation     Eager (full)       Number
  Min                   Aggregation     Eager (full)       Number
  Max                   Aggregation     Eager (full)       Number
  Average               Aggregation     Eager (full)       Number
  AverageOrDefault      Aggregation     Eager (full)       Number or undef
  Aggregate             Aggregation     Eager (full)       Scalar
  ToArray               Conversion      Eager (full)       Array
  ToList                Conversion      Eager (full)       ArrayRef
  ToDictionary          Conversion      Eager (full)       HashRef
  ToLookup              Conversion      Eager (full)       HashRef
  ToLTSV                Conversion      Eager (full)       (file written)
  ForEach               Utility         Eager (full)       (void)

B<Legend:>

=over 4

=item * B<Lazy> - returns a new Query immediately; no data is read yet.

=item * B<Lazy (early exit)> - reads only as many elements as needed, then stops.

=item * B<Lazy (stops at 2)> - reads until it finds a second match, then stops.

=item * B<Eager (full)> - must read the entire input sequence before returning.

=item * B<Eager (2nd seq) / Eager (inner seq)> - the indicated sequence is read
in full up front; the other sequence remains lazy.

=back

B<Practical guidance:>

=over 4

=item * Chain lazy operations freely - no cost until a terminal is called.

=item * Each terminal operation exhausts the iterator; to reuse data, call
C<ToArray()> first and rebuild with C<From(\@array)>.

=item * For very large files, avoid eager operations (C<OrderBy>, C<GroupBy>,
C<Join>, etc.) unless the data fits in memory, or pre-filter with C<Where>
to reduce the working set first.

=back

=head2 Query Execution Flow

  # Build query (lazy - no execution yet)
  my $query = LTSV::LINQ->FromLTSV("access.log")
      ->Where(status => '200')      # Lazy
      ->Select(sub { $_[0]{url} })  # Lazy
      ->Distinct();                  # Lazy

  # Execute query (terminal operation)
  my @results = $query->ToArray();  # Now executes entire chain

B<Execution Order:>

  1. FromLTSV opens file and creates iterator
  2. Where wraps iterator with filter
  3. Select wraps with transformation
  4. Distinct wraps with deduplication
  5. ToArray pulls elements through chain

Each element flows through the entire chain before the next element
is read.

=head2 Memory Characteristics

B<O(1) / Streaming Operations:>

These hold at most one element in memory at a time:

=over 4

=item * Where, Select, SelectMany, Concat, Zip

=item * Take, Skip, TakeWhile, SkipWhile

=item * DefaultIfEmpty

=item * ForEach, Count, Sum, Min, Max, Average, AverageOrDefault

=item * First, FirstOrDefault, Any, All, Contains

=item * Single, SingleOrDefault, ElementAt, ElementAtOrDefault

=back

B<O(unique) Operations:>

=over 4

=item * Distinct - hash grows with the number of distinct keys seen

=back

B<O(second/inner sequence) Operations:>

The following are partially eager: one sequence is buffered in full,
the other is streamed:

=over 4

=item * Union, Intersect, Except - second sequence is fully loaded

=item * Join, GroupJoin - inner sequence is fully loaded

=back

B<O(n) / Full-materialisation Operations:>

=over 4

=item * ToArray, ToList, ToDictionary, ToLookup, ToLTSV (O(n))

=item * OrderBy, OrderByDescending and Str/Num variants, Reverse (O(n))

=item * GroupBy (O(n))

=item * Last, LastOrDefault (O(n))

=item * Aggregate (O(n), O(1) intermediate accumulator)

=back

=head1 PERFORMANCE

=head2 Memory Efficiency

Lazy evaluation means memory usage is O(1) for most operations,
regardless of input size.

  # Processes 1GB file with constant memory
  LTSV::LINQ->FromLTSV("1gb.log")
      ->Where(status => '500')
      ->ForEach(sub { print $_[0]{url}, "\n" });

=head2 Terminal Operations

These operations materialize the entire result set:

=over 4

=item * ToArray, ToList

=item * OrderBy, OrderByDescending, Reverse

=item * GroupBy

=item * Last

=back

For large datasets, use these operations carefully.

=head2 Optimization Tips

=over 4

=item * Filter early: Place Where clauses first

  # Good: Filter before expensive operations
  ->Where(status => '200')->OrderBy(...)->Take(10)

  # Bad: Order all data, then filter
  ->OrderBy(...)->Where(status => '200')->Take(10)

=item * Limit early: Use Take to reduce processing

  # Process only what you need
  ->Take(1000)->GroupBy(...)

=item * Avoid repeated ToArray: Reuse results

  # Bad: Calls ToArray twice
  my $count = scalar($query->ToArray());
  my @items = $query->ToArray();

  # Good: Call once, reuse
  my @items = $query->ToArray();
  my $count = scalar(@items);

=back

=head1 COMPATIBILITY

=head2 Perl Version Support

This module is compatible with B<Perl 5.00503 and later>.

Tested on:

=over 4

=item * Perl 5.005_03 (released 1999)

=item * Perl 5.6.x

=item * Perl 5.8.x

=item * Perl 5.10.x - 5.42.x

=back

=head2 Compatibility Policy

B<Ancient Perl Support:>

This module maintains compatibility with Perl 5.005_03 through careful
coding practices:

=over 4

=item * No use of features introduced after 5.005

=item * C<use warnings> compatibility shim for pre-5.6

=item * C<our> keyword avoided (5.6+ feature)

=item * Three-argument C<open> used on Perl 5.6 and later (two-argument form retained for 5.005_03)

=item * No Unicode features required

=item * No module dependencies beyond core

=back

B<Why Perl 5.005_03 Specification?:>

This module adheres to the B<Perl 5.005_03 specification>, which was the
final version of JPerl (Japanese Perl). This is not about using the old
interpreter, but about maintaining the B<simple, original programming model>
that made Perl enjoyable.

B<The Strength of Modern Times:>

Some people think the strength of modern times is the ability to use
modern technology. That thinking is insufficient. The strength of modern
times is the ability to use B<all> technology up to the present day.

By adhering to the Perl 5.005_03 specification, we gain access to the
entire history of Perl--from 5.005_03 to 5.42 and beyond--rather than
limiting ourselves to only the latest versions.

Key reasons:

=over 4

=item * B<Simplicity> - The original Perl approach keeps programming fun and easy

Perl 5.6 and later introduced character encoding complexity that made
programming harder. The confusion around character handling contributed
to Perl's decline. By staying with the 5.005_03 specification, we maintain
the simplicity that made Perl "rakuda" (camel) -> "raku" (easy/fun).

=item * B<JPerl Compatibility> - Preserves the last JPerl version

Perl 5.005_03 was the final version of JPerl, which handled Japanese text
naturally. Later versions abandoned this approach for Unicode, adding
unnecessary complexity for many use cases.

=item * B<Universal Compatibility> - Runs on ANY Perl version

Code written to the 5.005_03 specification runs on B<all> Perl versions
from 5.005_03 through 5.42 and beyond. This maximizes compatibility across
two decades of Perl releases.

=item * B<Production Systems> - Real-world enterprise needs

Many production systems, embedded environments, and enterprise deployments
still run Perl 5.005, 5.6, or 5.8. This module provides modern query
capabilities without requiring upgrades.

=item * B<Philosophy> - Programming should be enjoyable

As readers of the "Camel Book" (Programming Perl) know, Perl was designed
to make programming enjoyable. The 5.005_03 specification preserves this
original vision.

=back

B<The ina CPAN Philosophy:>

All modules under the ina CPAN account (including mb, Jacode, UTF8-R2,
mb-JSON, and this module) follow this principle: Write to the Perl 5.005_03
specification, test on all versions, maintain programming joy.

This is not nostalgia--it's a commitment to:

=over 4

=item * Simple, maintainable code

=item * Maximum compatibility

=item * The original Perl philosophy

=item * Making programming "raku" (easy and fun)

=back

B<Build System:>

This module uses C<pmake.bat> instead of traditional make, since Perl 5.005_03
on Microsoft Windows lacks make. All tests pass on Perl 5.005_03 through
modern versions.

=head2 .NET LINQ Compatibility

This section documents where LTSV::LINQ's behaviour matches .NET LINQ
exactly, where it intentionally differs, and where it cannot differ due
to Perl's type system.

B<Exact matches with .NET LINQ:>

=over 4

=item * C<Single> - throws when sequence is empty or has more than one element

=item * C<First>, C<Last> - throw when sequence is empty or no element matches

=item * C<Aggregate(seed, func)> and C<Aggregate(seed, func, result_selector)>
- matching 2- and 3-argument forms

=item * C<GroupBy> - groups are returned in insertion order (first-seen key order)

=item * C<GroupJoin> - every outer element appears even with zero inner matches

=item * C<Join> - inner join semantics; unmatched outer elements are dropped

=item * C<Union> / C<Intersect> / C<Except> - partially eager (second/inner
sequence buffered up front), matching .NET's hash-join approach

=item * C<Take>, C<Skip>, C<TakeWhile>, C<SkipWhile> - identical semantics

=item * C<All> / C<Any> with early exit

=back

B<Intentional differences from .NET LINQ:>

=over 4

=item * C<SingleOrDefault>

.NET throws C<InvalidOperationException> when the sequence contains more
than one element. LTSV::LINQ returns C<undef> instead. This makes it
more natural in Perl code that checks return values with C<defined>.

If you require strict .NET behaviour (exception on multiple elements),
use C<Single()> inside an C<eval>:

  my $val = eval { $query->Single() };
  # $val is undef and $@ is set if empty or multiple

=item * C<DefaultIfEmpty(undef)>

.NET's C<DefaultIfEmpty> can return a sequence containing C<null>
(the reference-type default). LTSV::LINQ cannot: the iterator protocol
uses C<undef> to signal end-of-sequence, so a default value of C<undef>
is indistinguishable from EOF and is silently lost.

  # .NET: seq.DefaultIfEmpty() produces one null element
  # Perl:
  LTSV::LINQ->From([])->DefaultIfEmpty(undef)->ToArray()  # () - empty!
  LTSV::LINQ->From([])->DefaultIfEmpty(0)->ToArray()      # (0) - works

Use a sentinel value (C<0>, C<''>, C<{}>) and handle it explicitly.

=item * C<OrderBy> smart comparison

.NET's C<OrderBy> is strongly typed: the key type determines the
comparison. In Perl there is no static type, so LTSV::LINQ's C<OrderBy>
uses a heuristic: if both keys look like numbers, C<E<lt>=E<gt>> is used;
otherwise C<cmp>. For explicit control, use C<OrderByStr> (always C<cmp>)
or C<OrderByNum> (always C<E<lt>=E<gt>>).

=item * EqualityComparer / IComparer

.NET LINQ accepts C<IEqualityComparer> and C<IComparer> interface objects
for custom equality and ordering. LTSV::LINQ uses code references (C<sub>)
that extract a I<key> from each element. This is equivalent in power but
different in calling convention: the sub receives one element and returns a
key, rather than receiving two elements and returning a comparison result.

=item * C<Concat> on typed sequences

.NET's C<Concat> is type-checked. LTSV::LINQ accepts any two sequences
regardless of element type.

=item * No query expression syntax

.NET's C<from x in ... where ... select ...> syntax compiles to LINQ
method calls. Perl has no equivalent; use method chaining directly.

=back

=head2 Pure Perl Implementation

B<No XS Dependencies:>

This module is implemented in Pure Perl with no XS (C extensions).
Benefits:

=over 4

=item * Works on any Perl installation

=item * No C compiler required

=item * Easy installation in restricted environments

=item * Consistent behavior across platforms

=item * Simpler debugging and maintenance

=back

=head2 Core Module Dependencies

B<None.> This module uses only Perl core features available since 5.005.

No CPAN dependencies required.

=head1 DIAGNOSTICS

=head2 Error Messages

This module may throw the following exceptions:

=over 4

=item C<From() requires ARRAY reference>

Thrown by From() when the argument is not an array reference.

Example:

  LTSV::LINQ->From("string");  # Dies
  LTSV::LINQ->From([1, 2, 3]); # OK

=item C<SelectMany: selector must return an ARRAY reference>

Thrown by SelectMany() when the selector function returns anything
other than an ARRAY reference. Wrap the return value in C<[...]>:

  # Wrong - hashref causes die
  ->SelectMany(sub { {key => 'val'} })

  # Correct - arrayref
  ->SelectMany(sub { [{key => 'val'}] })

  # Correct - empty array for "no results" case
  ->SelectMany(sub { [] })

=item C<Sequence contains no elements>

Thrown by First(), Last(), or Average() when called on an empty sequence.

Methods that throw this error:

=over 4

=item * First()

=item * Last()

=item * Average()

=back

To avoid this error, use the OrDefault variants:

=over 4

=item * FirstOrDefault() - returns undef instead of dying

=item * LastOrDefault() - returns undef instead of dying

=item * AverageOrDefault() - returns undef instead of dying

=back

Example:

  my @empty = ();
  LTSV::LINQ->From(\@empty)->First();          # Dies
  LTSV::LINQ->From(\@empty)->FirstOrDefault(); # Returns undef

=item C<No element satisfies the condition>

Thrown by First() or Last() with a predicate when no element matches.

Example:

  my @data = (1, 2, 3);
  LTSV::LINQ->From(\@data)->First(sub { $_[0] > 10 });          # Dies
  LTSV::LINQ->From(\@data)->FirstOrDefault(sub { $_[0] > 10 }); # Returns undef

=item C<Sequence contains more than one element>

Thrown by Single() when the sequence (or matching elements) contains
more than one element.  Use First() if multiple matches are acceptable.

Example:

  my @data = (1, 2, 3);
  LTSV::LINQ->From(\@data)->Single();               # Dies (3 elements)
  LTSV::LINQ->From(\@data)->Single(sub { $_[0]>1 });# Dies (2 match)
  LTSV::LINQ->From(\@data)->Single(sub { $_[0]==1 });# OK (1 match)

=item C<Index must be non-negative>

Thrown by ElementAt() when the supplied index is less than zero.

=item C<Index out of range>

Thrown by ElementAt() when the supplied index is equal to or greater
than the number of elements in the sequence.  Use ElementAtOrDefault()
to avoid this error.

Example:

  my @data = (10, 20, 30);
  LTSV::LINQ->From(\@data)->ElementAt(2);  # OK: returns 30
  LTSV::LINQ->From(\@data)->ElementAt(5);  # Dies: index out of range
  LTSV::LINQ->From(\@data)->ElementAt(-1); # Dies: must be non-negative
  LTSV::LINQ->From(\@data)->ElementAtOrDefault(5); # Returns undef

=item C<Invalid number of arguments for Aggregate>

Thrown by Aggregate() when called with a number of arguments other
than 2 (seed + function).

Example:

  # Correct usage
  LTSV::LINQ->From([1,2,3])->Aggregate(0, sub { $_[0] + $_[1] });

  # Incorrect: single argument -- dies
  LTSV::LINQ->From([1,2,3])->Aggregate(sub { $_[0] + $_[1] });

=item C<Cannot open 'filename': ...>

File I/O error when FromLTSV() cannot open the specified file.

Common causes:

=over 4

=item * File does not exist

=item * Insufficient permissions

=item * Invalid path

=back

Example:

  LTSV::LINQ->FromLTSV("/nonexistent/file.ltsv"); # Dies with this error

=back

=head2 Methods That May Throw Exceptions

=over 4

=item B<From($array_ref)>

Dies if argument is not an array reference.

=item B<FromLTSV($filename)>

Dies if file cannot be opened.

B<Note:> The file handle is held open until the iterator is fully
consumed. Partially consumed queries keep their file handles open.
See C<FromLTSV> in L</Data Source Methods> for details.

=item B<First([$predicate])>

Dies if sequence is empty or no element matches predicate.

Safe alternative: FirstOrDefault()

=item B<Last([$predicate])>

Dies if sequence is empty or no element matches predicate.

Safe alternative: LastOrDefault()

=item B<Average([$selector])>

Dies if sequence is empty.

Safe alternative: AverageOrDefault()

=item B<Single([$predicate])>

Dies with C<Sequence contains more than one element> if the sequence
contains more than one matching element.  Also dies with
C<Sequence contains no elements> if no element matches.

=item B<ElementAt($index)>

Dies with C<Index must be non-negative> if C<$index> is less than 0.
Dies with C<Index out of range> if C<$index> is beyond the end of
the sequence.

=item B<Aggregate($seed, $func)>

Dies with C<Invalid number of arguments for Aggregate> if called
with an argument count other than 2 (seed + function).

=back

=head2 Safe Alternatives

For methods that may throw exceptions, use the OrDefault variants:

  First()   -> FirstOrDefault()   (returns undef)
  Last()    -> LastOrDefault()    (returns undef)
  Average() -> AverageOrDefault() (returns undef)

Example:

  # Unsafe - may die
  my $first = LTSV::LINQ->From(\@data)->First();

  # Safe - returns undef if empty
  my $first = LTSV::LINQ->From(\@data)->FirstOrDefault();
  if (defined $first) {
      # Process $first
  }

=head2 Exception Format and Stack Traces

All exceptions thrown by this module are plain strings produced by
C<die "message">. Because no trailing newline is appended, Perl
automatically appends the source location:

  Sequence contains no elements at lib/LTSV/LINQ.pm line 764.

This is intentional: the location helps when diagnosing unexpected
failures during development.

When catching exceptions with C<eval>, the full string including the
location suffix is available in C<$@>. Use a prefix match if you want
to test only the message text:

  eval { LTSV::LINQ->From([])->First() };
  if ($@ =~ /^Sequence contains no elements/) {
      # handle empty sequence
  }

If you prefer exceptions without the location suffix, wrap the call
in a thin eval and re-die with a newline:

  eval { $result = $query->First() };
  die "$@\n" if $@;   # strip " at ... line N" from the message

=head1 FAQ

=head2 General Questions

=over 4

=item B<Q: Why LINQ-style instead of SQL-style?>

A: LINQ provides:

=over 4

=item * Method chaining (more Perl-like)

=item * Type safety through code

=item * No string parsing required

=item * Composable queries

=back

=item B<Q: Can I reuse a query object?>

A: No. Query objects use iterators that can only be consumed once.

  # Wrong - iterator consumed by first ToArray
  my $query = LTSV::LINQ->FromLTSV("file.ltsv");
  my @first = $query->ToArray();   # OK
  my @second = $query->ToArray();  # Empty! Iterator exhausted

  # Right - create new query for each use
  my $query1 = LTSV::LINQ->FromLTSV("file.ltsv");
  my @first = $query1->ToArray();

  my $query2 = LTSV::LINQ->FromLTSV("file.ltsv");
  my @second = $query2->ToArray();

=item B<Q: How do I do OR conditions in Where?>

A: Use code reference form with C<||>:

  # OR condition requires code reference
  ->Where(sub {
      $_[0]{status} == 200 || $_[0]{status} == 304
  })

  # DSL only supports AND
  ->Where(status => '200')  # Single condition only

=item B<Q: Why does my query seem to run multiple times?>

A: Some operations require multiple passes:

  # This reads the file TWICE
  my $avg = $query->Average(...);    # Pass 1: Calculate
  my @all = $query->ToArray();       # Pass 2: Collect (iterator reset!)

  # Save result instead
  my @all = $query->ToArray();
  my $avg = LTSV::LINQ->From(\@all)->Average(...);

=back

=head2 Performance Questions

=over 4

=item B<Q: How can I process a huge file efficiently?>

A: Use lazy operations and avoid materializing:

  # Good - constant memory
  LTSV::LINQ->FromLTSV("huge.log")
      ->Where(status => '500')
      ->ForEach(sub { print $_[0]{message}, "\n" });

  # Bad - loads everything into memory
  my @all = LTSV::LINQ->FromLTSV("huge.log")->ToArray();

=item B<Q: Why is OrderBy slow on large files?>

A: OrderBy must load all elements into memory to sort them.

  # Slow on 1GB file - loads everything
  ->OrderBy(sub { $_[0]{timestamp} })->Take(10)

  # Faster - limit before sorting (if possible)
  ->Where(status => '500')->OrderBy(...)->Take(10)

=item B<Q: How do I process files larger than memory?>

A: Use ForEach or streaming terminal operations:

  # Process 100GB file with 1KB memory
  my $error_count = 0;
  LTSV::LINQ->FromLTSV("100gb.log")
      ->Where(sub { $_[0]{level} eq 'ERROR' })
      ->ForEach(sub { $error_count++ });

  print "Errors: $error_count\n";

=back

=head2 DSL Questions

=over 4

=item B<Q: Can DSL do numeric comparisons?>

A: No. DSL uses string equality (C<eq>). Use code reference for numeric:

  # DSL - string comparison
  ->Where(status => '200')  # $_[0]{status} eq '200'

  # Code ref - numeric comparison
  ->Where(sub { $_[0]{status} == 200 })
  ->Where(sub { $_[0]{bytes} > 1000 })

=item B<Q: How do I do case-insensitive matching in DSL?>

A: DSL doesn't support it. Use code reference:

  # Case-insensitive requires code reference
  ->Where(sub { lc($_[0]{method}) eq 'get' })

=item B<Q: Can I use regular expressions in DSL?>

A: No. Use code reference:

  # Regex requires code reference
  ->Where(sub { $_[0]{url} =~ m{^/api/} })

=back

=head2 Compatibility Questions

=over 4

=item B<Q: Does this work on Perl 5.6?>

A: Yes. Tested on Perl 5.005_03 through 5.40+.

=item B<Q: Do I need to install any CPAN modules?>

A: No. Pure Perl with no dependencies beyond core.

=item B<Q: Can I use this on Windows?>

A: Yes. Pure Perl works on all platforms.

=item B<Q: Why support such old Perl versions?>

A: Many production systems cannot upgrade. This module provides
modern query capabilities without requiring upgrades.

=back

=head1 COOKBOOK

=head2 Common Patterns

=over 4

=item B<Find top N by value>

  ->OrderByDescending(sub { $_[0]{score} })
    ->Take(10)
    ->ToArray()

=item B<Group and count>

  ->GroupBy(sub { $_[0]{category} })
    ->Select(sub {
        {
            Category => $_[0]{Key},
            Count => scalar(@{$_[0]{Elements}})
        }
    })
    ->ToArray()

=item B<Running total>

  my $total = 0;
  ->Select(sub {
      $total += $_[0]{amount};
      { %{$_[0]}, running_total => $total }
  })

=item B<Pagination>

  # Page 3, size 20
  ->Skip(40)->Take(20)->ToArray()

=item B<Unique values>

  ->Select(sub { $_[0]{category} })
    ->Distinct()
    ->ToArray()

=item B<Conditional aggregation>

Note: A query object can only be consumed once. To compute multiple
aggregations over the same source, materialise it first with C<ToArray()>.

  my @all = LTSV::LINQ->FromLTSV("access.log")->ToArray();

  my $success_avg = LTSV::LINQ->From(\@all)
      ->Where(status => '200')
      ->Average(sub { $_[0]{response_time} });

  my $error_avg = LTSV::LINQ->From(\@all)
      ->Where(sub { $_[0]{status} >= 400 })
      ->Average(sub { $_[0]{response_time} });

=item B<Iterator consumption: when to snapshot with ToArray()>

A query object wraps a single-pass iterator.  Once consumed, it is
exhausted and subsequent terminal operations return empty results or die.

  # WRONG - $q is exhausted after the first Count()
  my $q = LTSV::LINQ->FromLTSV("access.log")->Where(status => '200');
  my $n     = $q->Count();          # OK
  my $first = $q->First();          # WRONG: iterator already at EOF

  # RIGHT - snapshot into array, then query as many times as needed
  my @rows  = LTSV::LINQ->FromLTSV("access.log")->Where(status => '200')->ToArray();
  my $n     = LTSV::LINQ->From(\@rows)->Count();
  my $first = LTSV::LINQ->From(\@rows)->First();

The snapshot approach is also the correct pattern for any multi-pass
computation such as computing both average and standard deviation,
comparing the same sequence against two different filters, or iterating
once to validate and once to transform.

=item B<Efficient large-file pattern>

For files too large to fit in memory, keep the chain fully lazy by
ensuring only one terminal operation is performed per pass:

  # One pass - pick only what you need
  my @slow = LTSV::LINQ->FromLTSV("access.log")
      ->Where(sub { $_[0]{response_time} > 1000 })
      ->OrderByNum(sub { $_[0]{response_time} })
      ->Take(20)
      ->ToArray();

  # Never do two passes on the same FromLTSV object -
  # open the file again for a second pass:
  my $count = LTSV::LINQ->FromLTSV("access.log")->Count();
  my $sum   = LTSV::LINQ->FromLTSV("access.log")
                  ->Sum(sub { $_[0]{bytes} });

=back

=head1 DESIGN PHILOSOPHY

=head2 Historical Compatibility: Perl 5.005_03

This module maintains compatibility with Perl 5.005_03 (released 1999-03-28),
following the B<Universal Consensus 1998 for primetools>.

B<Why maintain such old compatibility?>

=over 4

=item * B<Long-term stability>

Code written in 1998-era Perl should still run in 2026 and beyond.
This demonstrates Perl's commitment to backwards compatibility.

=item * B<Embedded systems and traditional environments>

Some production systems, embedded devices, and enterprise environments
cannot easily upgrade Perl. Maintaining compatibility ensures this module
remains useful in those contexts.

=item * B<Minimal dependencies>

By avoiding modern Perl features, this module has zero non-core dependencies.
It works with only the Perl core that has existed since 1999.

=back

B<Technical implications:>

=over 4

=item * No C<our> keyword - uses package variables

=item * No C<warnings> pragma - uses C<local $^W=1>

=item * No C<use strict 'subs'> improvements from 5.6+

=item * All features implemented with Perl 5.005-era constructs

=back

The code comment C<# use 5.008001; # Lancaster Consensus 2013 for toolchains>
marks where modern code would typically start. We intentionally stay below
this line.

=head2 US-ASCII Only Policy

All source code is strictly US-ASCII (bytes 0x00-0x7F). No UTF-8, no
extended characters.

B<Rationale:>

=over 4

=item * B<Universal portability>

US-ASCII works everywhere - ancient terminals, modern IDEs, web browsers,
email systems. No encoding issues, ever.

=item * B<No locale dependencies>

The code behaves identically regardless of system locale settings.

=item * B<Clear separation of concerns>

Source code (ASCII) vs. data (any encoding). The module processes LTSV
data in any encoding, but its own code remains pure ASCII.

=back

This policy is verified by C<t/010_ascii_only.t>.

=head2 The C<$VERSION = $VERSION> Idiom

You may notice:

  $VERSION = '1.05';
  $VERSION = $VERSION;

This is B<intentional>, not a typo. Under C<use strict>, a variable used
only once triggers a warning. The self-assignment ensures C<$VERSION>
appears twice, silencing the warning without requiring C<our> (which
doesn't exist in Perl 5.005).

This is a well-known idiom from the pre-C<our> era.

=head2 Design Principles

=over 4

=item * B<Lazy evaluation by default>

Operations return query objects, not arrays. Data is processed on-demand
when terminal operations (C<ToArray>, C<Count>, etc.) are called.

=item * B<Method chaining>

All query operations return new query objects, enabling fluent syntax:

  $query->Where(...)->Select(...)->OrderBy(...)->ToArray()

=item * B<No side effects>

Query operations never modify the source data. They create new lazy
iterators.

=item * B<Perl idioms, LINQ semantics>

We follow LINQ's method names and semantics, but use Perl idioms for
implementation (closures for iterators, hash refs for records).

=item * B<Zero dependencies>

This module has zero non-core dependencies. It works with only the Perl
core that has existed since 1999. Even C<warnings.pm> is optional (stubbed
for Perl E<lt> 5.6). This ensures installation succeeds on minimal Perl
installations, avoids dependency chain vulnerabilities, and provides
permanence - the code will work decades into the future.

=back

=head1 LIMITATIONS AND KNOWN ISSUES

=head2 Current Limitations

=over 4

=item * B<Iterator Consumption>

Query objects can only be consumed once. The iterator is exhausted
after terminal operations.

Workaround: Create new query object or save ToArray() result.

=item * B<Undef Values in Sequences>

Due to iterator-based design, undef cannot be distinguished from end-of-sequence.
Sequences containing undef values may not work correctly with all operations.

This is not a practical limitation for LTSV data (which uses hash references),
but affects operations on plain arrays containing undef.

  # Works fine (LTSV data - hash references)
  LTSV::LINQ->FromLTSV("file.ltsv")->Contains({status => '200'})

  # Limitation (plain array with undef)
  LTSV::LINQ->From([1, undef, 3])->Contains(undef)  # May not work

=item * B<No Parallel Execution>

All operations execute sequentially in a single thread.

=item * B<No Index Support>

All filtering requires full scan. No index optimization.

=item * B<Distinct Uses String Keys>

Distinct with custom comparer uses stringified keys. May not work
correctly for complex objects.

=item * B<DefaultIfEmpty(undef) Cannot Be Distinguished from End-of-Sequence>

Because the iterator protocol uses C<undef> to signal end-of-sequence,
C<DefaultIfEmpty(undef)> cannot reliably deliver its C<undef> default
to downstream operations.

  # Works correctly (non-undef default)
  LTSV::LINQ->From([])->DefaultIfEmpty(0)->ToArray()    # (0)
  LTSV::LINQ->From([])->DefaultIfEmpty({})->ToArray()   # ({})

  # Does NOT work (undef default is indistinguishable from EOF)
  LTSV::LINQ->From([])->DefaultIfEmpty(undef)->ToArray() # () - empty!

Workaround: Use a sentinel value such as C<0>, C<''>, or C<{}> instead
of C<undef>, and treat it as "no element" after the fact.

=back

=head2 Not Implemented

The following LINQ methods from the .NET standard library are intentionally
not implemented in LTSV::LINQ. This section explains the design rationale
for each omission.

=head3 Parallel LINQ (PLINQ) Methods

The following methods belong to B<Parallel LINQ (PLINQ)>, the .NET
parallel-execution extension to LINQ introduced in .NET 4.0. They exist
to distribute query execution across multiple CPU cores using the .NET
Thread Pool and Task Parallel Library.

Perl does not have native shared-memory multithreading that maps onto
this execution model. Perl threads (C<threads.pm>) copy the interpreter
state and communicate through shared variables, making them unsuitable
for the fine-grained, automatic work-stealing parallelism that PLINQ
provides. LTSV::LINQ's iterator-based design assumes a single sequential
execution context; introducing PLINQ semantics would require a completely
different architecture and would add heavy dependencies.

Furthermore, the primary use case for LTSV::LINQ -- parsing and querying
LTSV log files -- is typically I/O-bound rather than CPU-bound.
Parallelizing I/O over a single file provides little benefit and
considerable complexity.

For these reasons, the entire PLINQ surface is omitted:

=over 4

=item * B<AsParallel>

Entry point for PLINQ. Converts an C<IEnumerable<T>> into a
C<ParallelQuery<T>> that the .NET runtime executes in parallel using
multiple threads. Not applicable: Perl lacks the runtime infrastructure.

=item * B<AsSequential>

Converts a C<ParallelQuery<T>> back to a sequential C<IEnumerable<T>>,
forcing subsequent operators to run on a single thread. Since
C<AsParallel> is not implemented, C<AsSequential> has no counterpart
to convert from.

=item * B<AsOrdered>

Instructs PLINQ to preserve the source order in the output even during
parallel execution. This is a hint to the PLINQ scheduler; it does not
exist outside of PLINQ. Not applicable.

=item * B<AsUnordered>

Instructs PLINQ that output order does not need to match source order,
potentially allowing more efficient parallel execution. Not applicable.

=item * B<ForAll>

PLINQ terminal operator that applies an action to each element in
parallel, without collecting results. It is the parallel equivalent of
C<ForEach>. LTSV::LINQ provides C<ForEach> for sequential iteration.
A parallel C<ForAll> is not applicable.

=item * B<WithCancellation>

Attaches a .NET C<CancellationToken> to a C<ParallelQuery<T>>, allowing
cooperative cancellation of a running parallel query. Cancellation tokens
are a .NET threading primitive. Not applicable.

=item * B<WithDegreeOfParallelism>

Sets the maximum number of concurrent tasks that PLINQ may use. A
tuning knob for the PLINQ scheduler. Not applicable.

=item * B<WithExecutionMode>

Controls whether PLINQ may choose sequential execution for efficiency
(C<Default>) or is forced to parallelize (C<ForceParallelism>). Not
applicable.

=item * B<WithMergeOptions>

Controls how PLINQ merges results from parallel partitions back into the
output stream (buffered, auto-buffered, or not-buffered). Not applicable.

=back

=head3 .NET Type System Methods

The following methods are specific to .NET's static type system. They
exist to work with .NET generics and interface hierarchies, which have
no Perl equivalent.

=over 4

=item * B<Cast>

Casts each element of a non-generic C<IEnumerable> to a specified type
C<T>, returning C<IEnumerable<T>>. In .NET, C<Cast<T>> is needed when
working with legacy APIs that return C<IEnumerable> (without a type
parameter) and you need to treat the elements as a specific type.

Perl is dynamically typed. Every Perl value already holds type
information at runtime (scalar, reference, blessed object), and Perl
does not have a concept of a "non-generic enumerable" that needs to be
explicitly cast before it can be queried. There is no meaningful
operation to implement.

=item * B<OfType>

Filters elements of a non-generic C<IEnumerable>, returning only those
that can be successfully cast to a specified type C<T>. Like C<Cast>,
it exists to bridge generic and non-generic .NET APIs.

In LTSV::LINQ, all records from C<FromLTSV> are hash references.
Records from C<From> are whatever the caller puts in the array.
Perl's C<ref()>, C<UNIVERSAL::isa()>, or a C<Where> predicate can
perform any type-based filtering the caller needs. A dedicated
C<OfType> adds no expressiveness.

  # Perl equivalent of OfType for blessed objects of class "Foo":
  $query->Where(sub { ref($_[0]) && $_[0]->isa('Foo') })

=back

=head3 64-bit and Large-Count Methods

=over 4

=item * B<LongCount>

Returns the number of elements as a 64-bit integer (C<Int64> in .NET).
On 32-bit .NET platforms, a sequence can theoretically contain more than
C<2**31 - 1> (~2 billion) elements, which would overflow C<int>; hence
the need for C<LongCount>.

In Perl, integers are represented as native signed integers or floating-
point doubles (C<NV>). On 64-bit Perl (which is universal in practice
today), the native integer type is 64 bits, so C<Count> already handles
any realistic sequence length. On 32-bit Perl, the floating-point C<NV>
provides 53 bits of integer precision (~9 quadrillion), far exceeding
any in-memory sequence. There is no semantic gap between C<Count> and
C<LongCount> in Perl.

=back

=head3 IEnumerable Conversion Method

=over 4

=item * B<AsEnumerable>

In .NET, C<AsEnumerable<T>> is used to force evaluation of a query as
C<IEnumerable<T>> rather than, for example, C<IQueryable<T>> (which
might be translated to SQL). It is a type-cast at the interface level,
not a data transformation.

LTSV::LINQ has only one query type: C<LTSV::LINQ>. There is no
C<IQueryable> counterpart that would benefit from being downgraded to
C<IEnumerable>. The method has no meaningful semantics to implement.

=back

=head1 BUGS

Please report any bugs or feature requests to:

=over 4

=item * Email: C<ina@cpan.org>

=back

=head1 SUPPORT

=head2 Documentation

Full documentation is available via:

  perldoc LTSV::LINQ

=head2 CPAN

  https://metacpan.org/pod/LTSV::LINQ

=head1 SEE ALSO

=over 4

=item * LTSV specification

http://ltsv.org/

=item * Microsoft LINQ documentation

https://learn.microsoft.com/en-us/dotnet/csharp/linq/

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

=head2 Contributors

Contributions are welcome! See file: CONTRIBUTING.

=head1 ACKNOWLEDGEMENTS

=head2 LINQ Technology

This module is inspired by LINQ (Language Integrated Query), which was
developed by Microsoft Corporation for the .NET Framework.

LINQ(R) is a registered trademark of Microsoft Corporation.

We are grateful to Microsoft for pioneering the LINQ technology and
making it a widely recognized programming pattern. The elegance and
power of LINQ has influenced query interfaces across many programming
languages, and this module brings that same capability to LTSV data
processing in Perl.

This module is not affiliated with, endorsed by, or sponsored by
Microsoft Corporation.

=head2 References

This module was inspired by:

=over 4

=item * Microsoft LINQ (Language Integrated Query)

L<https://learn.microsoft.com/en-us/dotnet/csharp/linq/>

=item * LTSV specification

L<http://ltsv.org/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 INABA Hitoshi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head2 License Details

This module is released under the same license as Perl itself:

=over 4

=item * Artistic License 1.0

L<http://dev.perl.org/licenses/artistic.html>

=item * GNU General Public License version 1 or later

L<http://www.gnu.org/licenses/gpl-1.0.html>

=back

You may choose either license.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS
WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
