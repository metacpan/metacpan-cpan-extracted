package Canary;
my $canaries = 0;

sub new {
    my ($class, $value) = @_;
    $canaries++;
    return bless [$value], "Canary";
}

sub DESTROY {
    $canaries--;
}

sub inc {
    $canaries++;
}

sub count {
    return $canaries;
}

sub meth {
    return -shift->[0];
}

*{"-'\$f#"} = sub {
    return -shift->[0];
};

package FakeHeap;
use strict;
use warnings;	# Remove this for production. Assumes perl 5.6
use Carp;
use Data::Dumper;
$Data::Dumper::Indent = 1;

use vars qw($VERSION);
$VERSION = "0.02";

my %order2code =
    ("<"  => sub { shift() <  shift },
     ">"  => sub { shift() >  shift },
     "lt" => sub { shift() lt shift },
     "gt" => sub { shift() gt shift },
     );

my %order2prefix =
    ("lt" => "A",
     "gt" => "A");

sub new {
    my ($class, %options) = @_;
    my $order = $options{order};
    $order = "<" unless defined $order;
    my $elements = $options{elements};
    $elements = "Scalar" if !defined $elements;
    $elements = [$elements] if !ref $elements;
    $elements->[0] = "Scalar" if lc($elements->[0]) eq "key";
    my $fake = bless {
        data      => [],
        heap      => Heap::Simple->new(%options),
        max_count => defined($options{max_count}) ? $options{max_count} : 9**9**9,
        prefix	  => $order2prefix{lc($order)},
        elements  => ucfirst(lc($elements->[0])),
        index	  => $elements->[1],
        num_order => $order !~ /t/,
        dirty	  => $options{dirty},
        less      => ref $order ? $order : $order2code{lc($order)} ||
            croak "Unhandled order '$order'",
    }, $class;
    my $t = $fake->{heap}->order;
    $order = lc($order) if !ref $order;
    $order eq $t || croak "Order is $t, but I expected $order";
    my @t = $fake->{heap}->elements;
    $fake->{elements} eq $t[0] ||
        croak "Element type is @t, but I expected $fake->{elements}";
    return $fake;
}

sub _make_element {
    my ($fake, $value) = @_;
    $value = $fake->{prefix} . $value if $fake->{prefix};
    my $type = $fake->{elements};
    return $value if $type eq "Scalar";
    if ($type eq "Array") {
        my $a = bless [], "Canary";
        $canaries++;
        $a->[$fake->{index} || 0] = $value;
        return $a;
    }
    if ($type eq "Hash") {
        $canaries++;
        return bless {$fake->{index} || croak("No index")=> $value }, "Canary";
    }
    if ($type eq "Function" || $type eq "Any" ||
        $type eq "Method" || $type eq "Object") {
        return Canary->new($value);
    }
    croak "Unknown element type $fake->{elements}";
}

sub _find_top_value {
    my ($fake, $top) = @_;
    defined $top || croak "_find_top_value should not be called on undef";
    my $less = $fake->{less};
    my @pos;
    my $i = 0;
    for (@{$fake->{data}}) {
        push @pos, $i if $_->{value} eq $top;
        $i++;
    }
    croak "Extracted value '$top' should not have been in the heap" if @pos == 0;
    my $pos = shift @pos;
    for (@pos) {
        $pos = $_ if
            $less->($fake->{data}[$_]{key}, $fake->{data}[$pos]{key});
    }
    my $key = $fake->{data}[$pos]{key};
    for (@{$fake->{data}}) {
        croak "'$_->{key}', not '$key' should have been the top key" if
            $less->($_->{key}, $key);
    }
    return $pos;
}

sub _find_lowest_key {
    my $fake = shift;
    die "_find_lowest_key on empty heap" unless @{$fake->{data}};
    my $less = $fake->{less};
    my @pos = 0..$#{$fake->{data}};
    my $pos = 0;
    for (@pos) {
        $pos = $_ if
            $less->($fake->{data}[$_]{key}, $fake->{data}[$pos]{key});
    }
    return $pos;
}

sub insert {
    my $fake = shift;
    my @values = map $fake->_make_element($_), @_;
    $fake->{heap}->insert(@values);
    for my $value (@values) {
        my $key = $fake->{heap}->key($value);
        if (@{$fake->{data}} == $fake->{max_count}) {
            next unless @{$fake->{data}};
            my $less = $fake->{less};
            my $pos = $fake->_find_lowest_key;
            next unless $less->($fake->{data}[$pos]{key}, $key);
            splice(@{$fake->{data}}, $pos, 1);
        }
        push @{$fake->{data}}, {
            key   => $key,
            value => $value,
        };
    }
}

sub key_insert {
    my $fake = shift;
    my @args;
    while (@_) {
        my $key	  = shift;
        $key = $fake->{prefix} . $key if $fake->{prefix};
        my $value = $fake->_make_element(shift);
        push @args, $key, $value;
    }
    $fake->{heap}->key_insert(@args);
    while (@args) {
        my $key   = shift @args;
        my $value = shift @args;
        if (@{$fake->{data}} == $fake->{max_count}) {
            next unless @{$fake->{data}};
            my $less = $fake->{less};
            my $pos = $fake->_find_lowest_key;
            next unless $less->($fake->{data}[$pos]{key}, $key);
            splice(@{$fake->{data}}, $pos, 1);
        }
        push @{$fake->{data}}, {
            key   => $key,
            value => $value};
    }
}

sub _key_insert {
    my $fake = shift;
    my (@values, @args);
    for my $element (@_) {
        my $value = $fake->_make_element($element->[1]);
        my $key =
            $fake->{prefix} ? $fake->{prefix} . $element->[0] : $element->[0];
        # Can't use local her since the arrayref itself gets inserted
        $element->[0] = $key;
        $element->[1] = $value;
    }
    $fake->{heap}->_key_insert(@_);
    for my $element (@_) {
        my $key   = $element->[0];
        my $value = $element->[1];
        if (@{$fake->{data}} == $fake->{max_count}) {
            next unless @{$fake->{data}};
            my $less = $fake->{less};
            my $pos = $fake->_find_lowest_key;
            next unless $less->($fake->{data}[$pos]{key}, $key);
            splice(@{$fake->{data}}, $pos, 1);
        }
        push @{$fake->{data}}, {
            key   => $key,
            value => $value};
    }
}

sub count {
    my $fake = shift;
    my $n2 = @{$fake->{data}};
    if (wantarray) {
        my @n1 = $fake->{heap}->count;
        croak "$fake->{heap} real count didn't return exactly 1 value" if
            @n1 != 1;
        croak "$fake->{heap} real count $n1[0], expected $n2" if $n2 != $n1[0];
    } else {
        my $n1 = $fake->{heap}->count;
        croak "$fake->{heap} real count $n1, expected $n2" if $n2 != $n1;
    }
    return $n2;
}

sub extract_top {
    my $fake = shift;
    my $top;
    if (wantarray) {
        my @top = eval { $fake->{heap}->extract_top };
        carp "$fake->{heap} extract_top returned not exactly one value" if
            @top != 1 && !$@;
        $top = $top[0];
    } else {
        $top = eval { $fake->{heap}->extract_top };
    }
    if (@{$fake->{data}}) {
        my $pos = $fake->_find_top_value($top);
        splice(@{$fake->{data}}, $pos, 1);
        return $top;
    } elsif ($@) {
        die $@;
    } else {
        carp("Supposedly empty didn't explode");
    }
}

sub extract_min {
    my $fake = shift;
    my $top;
    if (wantarray) {
        my @top = eval { $fake->{heap}->extract_min };
        carp "$fake->{heap} extract_min returned not exactly one value" if
            @top != 1 && !$@;
        $top = $top[0];
    } else {
        $top = eval { $fake->{heap}->extract_min };
    }
    if (@{$fake->{data}}) {
        my $pos = $fake->_find_top_value($top);
        splice(@{$fake->{data}}, $pos, 1);
        return $top;
    } elsif ($@) {
        die $@;
    } else {
        carp("Supposedly empty didn't explode");
    }
}

sub extract_first {
    my $fake = shift;
    my $top;
    if (wantarray) {
        my @top = $fake->{heap}->extract_first;
        if (@{$fake->{data}}) {
            carp "$fake->{heap} extract_first returned not exactly one value"
                if @top != 1;
        } else {
            carp "$fake->{heap} extract_first did not return zero values"
                if @top;
        }
        $top = $top[0];
    } else {
        $top = $fake->{heap}->extract_first;
    }
    if (@{$fake->{data}}) {
        my $pos = $fake->_find_top_value($top);
        splice(@{$fake->{data}}, $pos, 1);
        return $top;
    } else {
        croak "top should be undef" if defined $top;
        return;
    }
}

sub extract_upto {
    my $fake = shift;
    my @top;
    if (wantarray) {
        @top = $fake->{heap}->extract_upto(@_);
    } else {
        @top = scalar $fake->{heap}->extract_upto(@_);
    }
    @_ || croak "No limit was passed to extract_upto";
    my $limit = shift;
    my $less = $fake->{less};
    for my $top (@top) {
        @{$fake->{data}} || croak "Extracted value '$top' that should not exist";
        my $key = $fake->{heap}->key($top);
        my $i = 0;
        my $pos;
        for (@{$fake->{data}}) {
            croak "'$_->{key}', not '$key' should have been the next key" if
                $less->($_->{key}, $key);
            $pos = $i if $_->{value} eq $top;
            $i++;
        }
        defined $pos ||
            croak "Extracted value '$top' should not have been in the heap";
        splice(@{$fake->{data}}, $pos, 1);
    }
    for (@{$fake->{data}}) {
        croak "'$_->{value}' should have been returned too" if
            !$less->($limit, $_->{key});
    }
    return wantarray ? @top : $top[0];
}

sub extract_all {
    my $fake = shift;
    my @top;
    if (wantarray) {
        @top = $fake->{heap}->extract_all(@_);
    } else {
        croak "extract_all in list context is not specified";
        @top = scalar $fake->{heap}->extract_all(@_);
    }
    my $less = $fake->{less};
    for my $top (@top) {
        @{$fake->{data}} || croak "Extracted value '$top' that should not exist";
        my $key = $fake->{heap}->key($top);
        my $i = 0;
        my $pos;
        for (@{$fake->{data}}) {
            croak "'$_->{key}', not '$key' should have been the next key" if
                $less->($_->{key}, $key);
            $pos = $i if $_->{value} eq $top;
            $i++;
        }
        defined $pos ||
            croak "Extracted value '$top' should not have been in the heap";
        splice(@{$fake->{data}}, $pos, 1);
    }
    croak "Heap should have been empty" if @{$fake->{data}};
    return wantarray ? @top : $top[0];
}

sub top {
    my $fake = shift;
    my $top;
    if (wantarray) {
        my @top = eval { $fake->{heap}->top };
        carp "$fake->{heap} top returned not exactly one value" if
            @top != 1 && !$@;
        $top = $top[0];
    } else {
        $top = eval { $fake->{heap}->top };
    }
    if (@{$fake->{data}}) {
        $fake->_find_top_value($top);
        return $top;
    } elsif ($@) {
        die $@;
    } else {
        carp("Supposedly empty didn't explode");
    }
}

sub first {
    my $fake = shift;
    my $top;
    if (wantarray) {
        my @top = eval { $fake->{heap}->first };
        if (@top == 0) {
            croak "Got no first value on non-empty heap" if @{$fake->{data}};
            return;
        }
        croak "Got multiple values from first" if @top != 1;
        $top = $top[0];
        croak "Got first value on empty heap" if
            !@{$fake->{data}} && defined $top;
    } else {
        $top = eval { $fake->{heap}->first };
    }
    if (@{$fake->{data}}) {
        $fake->_find_top_value($top);
        return $top;
    } elsif (defined($top)) {
        croak "Got a defined first from an empty heap";
    } else {
        return undef;
    }
}

sub top_key {
    my $fake = shift;
    my ($top, $n);
    if (wantarray) {
        my @top = eval { $fake->{heap}->top_key };
        $n = @top;
        $top = $top[0];
    } else {
        $top = eval { $fake->{heap}->top_key };
        $n = 1;
    }
    if (@{$fake->{data}}) {
        $n == 1 || croak "top_key should have returned one value";
        my $less = $fake->{less};
        my $key = $top;
        my $i = 0;
        my $pos;
        my $numeric = $fake->{num_order} && $fake->{dirty};
        for (@{$fake->{data}}) {
            croak "'$_->{key}', not '$key' should have been the top key" if
                $less->($_->{key}, $key);
            $pos = $i if $numeric ? $_->{key} == $key : $_->{key} eq $key;
            $i++;
        }
        defined $pos ||
            croak "Extracted key $top should not have been in the heap";
    } else {
        my $err = $@;
        if (defined(my $inf = $fake->{heap}->infinity)) {
            $top eq $inf ||
                croak "Should have gotten infinity '$inf', but got '$top'";
            $n == 1 || croak "top_key should have returned one value";
        } elsif ($err) {
            die $err;
        } else {
            carp("Supposedly empty didn't explode");
        }
    }
    return $top;
}

sub min_key {
    my $fake = shift;
    my ($top, $n);
    if (wantarray) {
        my @top = eval { $fake->{heap}->min_key };
        $n = @top;
        $top = $top[0];
    } else {
        $top = eval { $fake->{heap}->min_key };
        $n = 1;
    }
    if (@{$fake->{data}}) {
        $n == 1 || croak "min_key should have returned one value";
        my $less = $fake->{less};
        my $key = $top;
        my $i = 0;
        my $pos;
        my $numeric = $fake->{num_order} && $fake->{dirty};
        for (@{$fake->{data}}) {
            croak "'$_->{key}', not '$key' should have been the top key" if
                $less->($_->{key}, $key);
            $pos = $i if $numeric ? $_->{key} == $key : $_->{key} eq $key;
            $i++;
        }
        defined $pos ||
            croak "Extracted key $top should not have been in the heap";
    } else {
        my $err = $@;
        if (defined(my $inf = $fake->{heap}->infinity)) {
            $top eq $inf ||
                croak "Should have gotten infinity '$inf', but got '$top'";
            $n == 1 || croak "min_key should have returned one value";
        } elsif ($err) {
            die $err;
        } else {
            carp("Supposedly empty didn't explode");
        }
    }
    return $top;
}

sub first_key {
    my $fake = shift;
    my $top;
    if (wantarray) {
        my @top = $fake->{heap}->first_key;
        if (@top == 0) {
            croak "Got no first_key value on non-empty heap" if
                @{$fake->{data}};
            return;
        }
        croak "Got multiple values from first_key" if @top != 1;
        $top = $top[0];
        croak "Got first_key value on empty heap" if
            !@{$fake->{data}} && defined $top;
    } else {
        $top = eval { $fake->{heap}->first_key };
    }
    if (@{$fake->{data}}) {
        my $less = $fake->{less};
        my $key = $top;
        my $i = 0;
        my $pos;
        my $numeric = $fake->{num_order} && $fake->{dirty};
        for (@{$fake->{data}}) {
            croak "'$_->{key}', not '$key' should have been the top key" if
                $less->($_->{key}, $key);
            $pos = $i if $numeric ? $_->{key} == $key : $_->{key} eq $key;
            $i++;
        }
        defined $pos ||
            croak "Extracted key '$top' should not have been in the heap";
        return $top;
    } elsif (defined($top)) {
        croak "Got a defined first_key from an empty heap";
    } else {
        return undef;
    }
}

sub values {
    my $fake = shift;
    my @values = $fake->{heap}->values;
    my @svalues = sort @values;
    my @fvalues = sort map $_->{value}, @{$fake->{data}};
    @fvalues == @svalues || croak "Number of returned values differ";
    for (@svalues) {
        my $n = shift @fvalues;
        $n eq $_ || croak "values: Unexpected value, either $_ or $n\nfake=", Dumper($fake), "Real heap values=", Dumper(\@values), "Giving up";
    }
    # No check for heap property. test suite will implicitely test it
    # when it checks compatibility of keys and values order
    return @values;
}

sub keys {
    my $fake = shift;
    my @keys = $fake->{heap}->keys;
    my (@skeys, @fkeys);
    if ($fake->{num_order}  && $fake->{dirty}) {
        @skeys = sort { $a <=> $b } @keys;
        @fkeys = sort { $a <=> $b } map $_->{key}, @{$fake->{data}};
    } else {
        @skeys = sort @keys;
        @fkeys = sort map $_->{key}, @{$fake->{data}};
    }
    @skeys == @fkeys || croak "Number of returned keys differ (real heap ", scalar @skeys, " versus control data ", scalar @fkeys, ")";
    for (@skeys) {
        my $n = shift @fkeys;
        ($fake->{num_order} && $fake->{dirty} ? $n == $_ : $n eq $_) ||
            croak "values: Unexpected key, either $_ or $n\nfake=", Dumper($fake), "Real heap keys=", Dumper(\@keys), "Giving up";
    }
    # Check heap property
    my $less = $fake->{less};
    my $n = 0;
    for (0..$#keys) {
        last if ++$n > $#keys;
        croak "heap property violated" if $less->($keys[$n], $keys[$_]);
        last if ++$n > $#keys;
        croak "heap property violated" if $less->($keys[$n], $keys[$_]);
    }
    return @keys;
}

sub key_index {
    my $fake = shift;
    my $pos;
    if (wantarray) {
        my @pos = eval { $fake->{heap}->key_index(@_) };
        croak "key_index returned multiple values: @pos" if @pos > 1;
        croak "key_index didn't return any values" if !@pos && !$@;
        $pos = $pos[0];
    } else {
        $pos = eval { $fake->{heap}->key_index(@_) };
    }
    if ($@) {
        die $@ if $fake->{elements} ne "Array";
        carp "key_index should not have died";
        croak "key_index should not have died";
    }
    croak "key_index should have died" if $fake->{elements} ne "Array";
    $pos eq ($fake->{index} || 0) || croak "key_index: Unexpected key index";
    return $pos;
}

sub key_name {
    my $fake = shift;
    my $pos;
    if (wantarray) {
        my @pos = eval { $fake->{heap}->key_name(@_) };
        croak "key_name returned multiple values: @pos" if @pos > 1;
        croak "key_name didn't return any values" if !@pos && !$@;
        $pos = $pos[0];
    } else {
        $pos = eval { $fake->{heap}->key_name(@_) };
    }
    if ($@) {
        die $@ if $fake->{elements} ne "Hash";
        carp "key_name should not have died";
        croak "key_name should not have died";
    }
    croak "key_name should have died" if $fake->{elements} ne "Hash";
    $pos eq ($fake->{index} || 0) || croak "key_name: Unexpected key name";
    return $pos;
}

sub key_method {
    my $fake = shift;
    my $pos;
    if (wantarray) {
        my @pos = eval { $fake->{heap}->key_method(@_) };
        croak "key_method returned multiple values: @pos" if @pos > 1;
        croak "key_method didn't return any values" if !@pos && !$@;
        $pos = $pos[0];
    } else {
        $pos = eval { $fake->{heap}->key_method(@_) };
    }
    if ($@) {
        die $@ if
            $fake->{elements} ne "Method" && $fake->{elements} ne "Object";
        carp "key_method should not have died";
        croak "key_method should not have died";
    }
    croak "key_method should have died" if
            $fake->{elements} ne "Method" && $fake->{elements} ne "Object";
    $pos eq ($fake->{index} || 0) || croak "key_method: Unexpected key method";
    return $pos;
}

sub key_function {
    my $fake = shift;
    my $pos;
    if (wantarray) {
        my @pos = eval { $fake->{heap}->key_function(@_) };
        croak "key_function returned multiple values: @pos" if @pos > 1;
        croak "key_function didn't return any values" if !@pos && !$@;
        $pos = $pos[0];
    } else {
        $pos = eval { $fake->{heap}->key_function(@_) };
    }
    if ($@) {
        die $@ if
            $fake->{elements} ne "Function" && $fake->{elements} ne "Any";
        carp "key_function should not have died";
        croak "key_function should not have died";
    }
    croak "key_function should have died" if
            $fake->{elements} ne "Function" && $fake->{elements} ne "Any";
    $pos eq ($fake->{index} || 0) ||
        croak "key_function: Unexpected key function";
    return $pos;
}

sub absorb {
    my $fake1 = shift;
    my @k2 = map $_->keys, @_;
    my @v2 = map $_->values, @_;
    $fake1->{heap}->absorb(@_);
    my $less = $fake1->{less};
    while (@v2) {
        my $value = shift @v2;
        my $key   = shift @k2;
        if (@{$fake1->{data}} == $fake1->{max_count}) {
            next unless @{$fake1->{data}};
            my $pos = $fake1->_find_lowest_key;
            next unless $less->($fake1->{data}[$pos]{key}, $key);
            splice(@{$fake1->{data}}, $pos, 1);
        }
        push @{$fake1->{data}}, {
            key   => $key,
            value => $value,
        };
    }
}

sub key_absorb {
    my $fake1 = shift;
    my @k2 = map $_->keys, @_;
    my @v2 = map $_->values, @_;
    $fake1->{heap}->key_absorb(@_);
    my $less = $fake1->{less};
    while (@v2) {
        my $value = shift @v2;
        my $key   = shift @k2;
        if (@{$fake1->{data}} == $fake1->{max_count}) {
            next unless @{$fake1->{data}};
            my $pos = $fake1->_find_lowest_key;
            next unless $less->($fake1->{data}[$pos]{key}, $key);
            splice(@{$fake1->{data}}, $pos, 1);
        }
        push @{$fake1->{data}}, {
            key   => $key,
            value => $value,
        };
    }
}

sub merge_arrays {
    my $fake = shift;
    my $less = $fake->{less};
    my @values = map [map $_->[1], sort {$less->($a->[0], $b->[0]) ? -1 : 1} map {
        my $element = $fake->_make_element($_);
        [$fake->{heap}->key($element), $element];
    } @$_], @_;
    my $out = $fake->{heap}->merge_arrays(@values);
    ref $out eq "ARRAY" || die "Expected an array reference, not '$out'";
    my @list = map {map { key => $fake->{heap}->key($_), value => $_}, @$_ } @values;
    if (@list > $fake->{max_count}) {
        @$out == $fake->{max_count} ||
            croak("$fake->{heap}: Unexpected number of values (" . @list .
                  " value in, " .
                  @$out . " values out, but max is " . $fake->{max_count}.")");
    } else {
        @$out == @list ||
            croak("$fake->{heap}: Unexpected number of values (" . @list .
                  " value in, " .
                  @$out . " values out)");
    }
    for my $top (reverse @$out) {
        @list || croak "Got value '$top' that should not exist";
        my $key = $fake->{heap}->key($top);
        my $i = 0;
        my $pos;
        for (@list) {
            croak "'$_->{key}', not '$key' should have been the next key" if
                $less->($key, $_->{key});
            $pos = $i if $_->{value} eq $top;
            $i++;
        }
        defined $pos ||
            croak "Extracted value '$top' should not have been in the list";
        splice(@list, $pos, 1);
    }
}

sub _absorb {
    my ($fake1, $fake2) = @_;
    $fake1->{heap}->_absorb($fake2);
    @{$fake1->{data}} = ();
}

sub _key_absorb {
    my ($fake1, $fake2) = @_;
    $fake1->{heap}->_key_absorb($fake2);
    @{$fake1->{data}} = ();
}

sub clear {
    my $fake = shift;
    @{$fake->{data}} = ();
    return $fake->{heap}->clear(@_);
}

sub user_data {
    return shift->{heap}->user_data(@_);
}

sub infinity {
    return shift->{heap}->infinity(@_);
}

sub order {
    return shift->{heap}->order(@_);
}

sub elements {
    return shift->{heap}->elements(@_);
}

sub wrapped {
    return shift->{heap}->wrapped(@_);
}

sub key {
    return shift->{heap}->key(@_);
}

sub max_count {
    return shift->{heap}->max_count(@_);
}

sub dirty {
    return shift->{heap}->dirty(@_);
}

sub can_die {
    return shift->{heap}->can_die(@_);
}

sub implementation {
    return shift->{heap}->implementation(@_);
}

sub heap {
    return shift->{heap};
}

1;
