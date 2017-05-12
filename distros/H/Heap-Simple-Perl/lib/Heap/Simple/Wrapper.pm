package Heap::Simple::Wrapper;
$VERSION = "0.04";
use strict;

sub _ELEMENTS_PREPARE {
    return "";
}

sub _QUICK_KEY {
    return shift->_KEY(@_);
}

sub _KEY {
    return $_[1] . "->[0]";
}

sub _VALUE {
    return $_[1] . "->[1]";
}

sub _WRAPPER {
    return "[$_[1], $_[2]]";
}

sub insert {
    my $heap = shift;
    Carp::croak "Wrapped class with noop key" if $heap->_KEY("") eq "";
    $heap->_make('sub insert {
    my $heap = shift;
    _REAL_PREPARE()
    _CANT_DIE(
    _MAX_COUNT(my $available = _THE_MAX_COUNT()-$#$heap;)
    if (@_ > 1 _MAX_COUNT(&& $available > 1)) {
	my $first = @$heap;
        my $i = push(@$heap, map _WRAPPER(_REAL_KEY($_), $_), _MAX_COUNT(splice(@_, 0, $available), @_))-1;
	my @todo = reverse $first/2..$#$heap/2;
        while (my $j = shift @todo) {
	    my $value = $heap->[$j];
            my $key = _KEY($value);
            my $l = $j*2;
            while ($l < $i) {
                if (_SMALLER(_KEY($heap->[$l]), $key)) {
                    $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
                } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                    $l--;
                    last;
                }
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
            if ($l == $i && _SMALLER(_KEY($heap->[$l]), $key)) {
                $heap->[$l >> 1] = $heap->[$l];
            } else {
		$l >>= 1;
	    }
            if ($j != $l) {
                $heap->[$l] = $value;
                $l >>= 1;
                push(@todo, $l) if !@todo || $l < $todo[0];
            }
        }
	return _MAX_COUNT(unless @_);
    })
    for my $value (@_) {
    my $key = _REAL_KEY($value);
    my $i = @$heap;
    _MAX_COUNT(if ($i > _THE_MAX_COUNT()) {
        next unless _SMALLER(_KEY($heap->[1]), $key);
        $i--;
        my $l = 2;
        _CAN_DIE(my $min = $heap->[1]; eval {)
            while ($l < $i) {
                if (_SMALLER(_KEY($heap->[$l]), $key)) {
                    $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
                } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                    $l--;
                    last;
                }
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
            if ($l == $i && _SMALLER(_KEY($heap->[$l]), $key)) {
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
        _CAN_DIE(        1
    } || $heap->_e_recover($l, $min);)
    $heap->[$l >> 1] = _WRAPPER($key, $value);
    next;})
    _CAN_DIE(eval {)
        $i = $i >> 1 while
        $i > 1 && _SMALLER($key, _KEY(($heap->[$i] = $heap->[$i >> 1])));
    _CAN_DIE(1} || $heap->_i_recover($i);)
    $heap->[$i] = _WRAPPER($key, $value);
    }}');
    $heap->insert(@_);
}

sub key_insert {
    my $heap = shift;
    $heap->_make('sub key_insert {
    my $heap = shift;
    _PREPARE()
    while (@_) {
    my $key  = shift;
    my $i = @$heap;
    _MAX_COUNT(if ($i > _THE_MAX_COUNT()) {
        shift _COMMA() next unless _SMALLER(_KEY($heap->[1]), $key);
        $i--;
        my $l = 2;
        _CAN_DIE(my $min = $heap->[1]; eval {)
            while ($l < $i) {
                if (_SMALLER(_KEY($heap->[$l]), $key)) {
                    $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
                } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                    $l--;
                    last;
                }
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
            if ($l == $i && _SMALLER(_KEY($heap->[$l]), $key)) {
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
        _CAN_DIE(        1
    } || $heap->_e_recover($l, $min);)
    $heap->[$l >> 1] = _WRAPPER($key, shift);
    next;})
    _CAN_DIE(eval {)
    $i = $i >> 1 while 
        $i > 1 && _SMALLER($key, _KEY(($heap->[$i] = $heap->[$i >> 1])));
    _CAN_DIE(1} || $heap->_i_recover($i);)
    $heap->[$i] = _WRAPPER($key, shift);
    }}');
    $heap->key_insert(@_);
}

sub _key_insert {
    my $heap = shift;
    $heap->_make('sub _key_insert {
    my $heap = shift;
    _PREPARE()
    for my $pair (@_) {
    my $key  = $pair->[0];
    my $i = @$heap;
    _MAX_COUNT(if ($i > _THE_MAX_COUNT()) {
        next unless _SMALLER(_KEY($heap->[1]), $key);
        $i--;
        my $l = 2;
        _CAN_DIE(my $min = $heap->[1]; eval {)
            while ($l < $i) {
                if (_SMALLER(_KEY($heap->[$l]), $key)) {
                    $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
                } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                    $l--;
                    last;
                }
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
            if ($l == $i && _SMALLER(_KEY($heap->[$l]), $key)) {
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
        _CAN_DIE(        1
    } || $heap->_e_recover($l, $min);)
    $heap->[$l >> 1] = $pair;
    next;})
    _CAN_DIE(eval {)
    $i = $i >> 1 while 
        $i > 1 && _SMALLER($key, _KEY(($heap->[$i] = $heap->[$i >> 1])));
    _CAN_DIE(1} || $heap->_i_recover($i);)
    $heap->[$i] = $pair;
    }}');
    $heap->_key_insert(@_);
}

sub _key_absorb {
    my ($from, $to) = @_;
    Carp::croak "Self absorption" if $from == $to;
    if (@$from > 2 && !$to->can_die) {
        $to->_key_insert(@$from[1..$#$from]);
        $#$from = 0;
        return;
    }
    while (@$from > 1) {
        $to->_key_insert($from->[-1]);
        pop @$from;
    }
}

sub wrapped {
    return 1;
}

1;
