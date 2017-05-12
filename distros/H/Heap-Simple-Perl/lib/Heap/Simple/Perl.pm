package Heap::Simple::Perl;
use strict;
use Carp;

use vars qw($VERSION $auto %used);
$VERSION = "0.12";
$auto = "Auto";
%used = ();

use AutoLoader qw(AUTOLOAD);

use constant DEBUG => 0;

sub _use {
    my $name = shift();
    $name =~ s|::|/|g;
    print STDERR "require Heap/Simple/$name.pm\n" if DEBUG;
    return require "Heap/Simple/$name.pm";
}

my %order = ("<"  => "Number",
             ">"  => "NumberReverse",
             "lt" => "String",
             "gt" => "StringReverse",
             );
sub _order {
    my ($heap, $order) = @_;
    # Default order if nothing specified
    $order = "<" unless defined($order) && $order ne "";
    my $name;
    if (ref($order) eq "CODE") {
        $heap->[0]{order} = $order;
        $name = "Less";
    } else {
        $name = $order{lc $order} || croak "Unknown order '$order'";
    }
    $used{$name} ||= _use($name);
    return $name;
}

sub _elements {
    my ($heap, $elements) = @_;
    $elements = ["Scalar"] unless defined($elements);
    $elements = [$elements] if ref($elements) eq "";
    croak "option elements is not an array reference" unless
        ref($elements) eq "ARRAY";
    croak "option elements has no type defined at index 0" unless
        defined($elements->[0]);
    my $name = ucfirst(lc($elements->[0]));
    $name = "Scalar" if $name eq "Key";
    $used{$name} ||= _use($name);
    # $name is passed for the case that Heap::Simple::$name uses inheritance
    return "Heap::Simple::$name"->_elements($heap, $name, $elements);
}

sub _max_count {
    my ($heap, $max_count) = @_;
    return unless defined $max_count;
    $max_count == int($max_count) ||
        croak "max_count should be an integer";
    croak "max_count should not be negative" if $max_count < 0;
    croak "max_count should not be zero" if $max_count == 0;
    return $max_count == 9**9**9 ? () : (Limit => $heap->[0]{max_count} = $max_count);
    # my $name = "Limit";
    # $used{$name} ||= _use($name);
    # return "Heap::Simple::$name"->_max_count($heap, $name, $max_count);
}

sub new {
    croak "Odd number of elements in options" if @_ % 2 == 0;
    my ($class, %options) = @_;
    # note: the array starts at elements 1 to make the subscripting
    # operations (much!) cleaner.
    # So elements 0 is used for associated data
    my $heap = bless [{}], $class;
    # We temporarily bless $heap into $class so you can play OO games with it
    my @max	 = $heap->_max_count(delete $options{max_count});
    my @die	 = delete $options{can_die} ? "Die" : ();
    $heap->[0]{can_die} = 1 if @die;
    my @order    = $heap->_order(delete $options{order});
    my @elements = $heap->_elements(delete $options{elements});
    my $gclass = join("::", $class, $auto, @max, @die, @order, @elements);
    # Pure perl version is never dirty
    $heap->[0]{dirty} = 1 if delete $options{dirty};
    no strict "refs";
    @{"${gclass}::ISA"} = ("Heap::Simple::$elements[0]",
                           "Heap::Simple::$order[0]",
                           $class) unless @{"${gclass}::ISA"};
    print STDERR "Generated class $gclass\n" if DEBUG;
    # Now rebless the result into its final generated class
    bless $heap, $gclass;
    $heap->[0]{infinity} = exists($options{infinity}) ?
        delete $options{infinity} : $heap->_INF;
    $heap->[0]{user_data} = delete $options{user_data} if
        exists $options{user_data};
    croak "Unknown option ", join(", ", map "'$_'", CORE::keys %options) if
        %options;
    return $heap;
}

sub _ELEMENTS_PREPARE {
    return "";
}

sub _ORDER_PREPARE {
    return "";
}

sub _PREPARE {
    my $heap = shift;
    return join("", $heap->_ORDER_PREPARE, $heap->_ELEMENTS_PREPARE);
}

sub _VALUE {
    return $_[1];
}

sub _WRAPPER {
    return $_[2];
}

sub _INF {
    return;
}

sub _CAN_DIE {
    return shift->[0]{can_die} ? shift : @_ > 1 ? $_[1] : "";
}

sub _CANT_DIE {
    return shift->[0]{can_die} ? "" : shift;
}

sub _MAX_COUNT {
    return shift->[0]{max_count} ? shift : @_ > 1 ? $_[1] : "";
}

sub _THE_MAX_COUNT {
    return shift->[0]{max_count} || croak "undefined max_count";
}

sub _REAL_KEY {
    return shift->_KEY(@_);
}

sub _REAL_ELEMENTS_PREPARE {
    return shift->_ELEMENTS_PREPARE(@_);
}

sub _REAL_PREPARE {
    my $heap = shift;
    return join("", $heap->_ORDER_PREPARE, $heap->_REAL_ELEMENTS_PREPARE);
}

# Returning "-" means it should not get used
# (should cause a syntax error on accidental use)
sub _QUICK_KEY {
    return "-";
}

sub _COMMA {
    return ",";
}

my %stringify =
    ("\"" => "\\\"",
     "\\" => "\\\\",
     "\$" => "\\\$",
     "\@" => "\\\@",
     "\n" => "\\n",
     "\r" => "\\r");

# currently loses utf8 when the resulting string gets used
sub _stringify {
    defined(my $str = shift) || croak "undefined access";
    $str =~ s/([\"\\\n\r\$\@])/$stringify{$1}/g;	# "
    return qq("$str");
}

my ($balanced, $sequence);
# String with balanced parenthesis (but not balanced {}. We use that)
$balanced = qr{[^()\[\],]*(?:(?:\((??{$sequence})\)|\[(??{$sequence})\])[^()\[\],]*)*};
$sequence = qr{$balanced(?:,$balanced)*};

sub _make {
    # Use $_self so there is less chance of the eval using $heap and surviving
    my $_self  = shift;
    die "Cannot determine caller class from '$_self'" unless ref($_self);
    my $subroutine = (caller(1))[3];
    $subroutine =~ s/.*:://s || die "Cannot parse caller '$subroutine'";
    my $package = ref($_self);

    my $string = "package $package;\n" . shift;
    # Very simple macro expander, but ignore literal strings
    my $f = "a";
    # 1 while $string =~ s{(\b_[A-Z_]+)\(($sequence)\)}{$f=$1; $_self->$f($2 =~ /($balanced),?/g)}eg;
    # Previous line ought to work but actually fails on perl 5.6.2 because
    # the return value from s///e cannot be trusted
    $f="",$string =~ s{(\b_[A-Z_]+)\(($sequence)\)}{$f=$1; $_self->$f($2 =~ /($balanced),?/g)}eg while $f;
    if ($string =~ /\bmy\s+\$(\w+)\s*=\s*shift;/g) {
        my $var = $1;
        $string =~ /\$$var\b/g || croak "$_self uses \$$var only once ($string)";
        unless ($string =~ /\$$var\b/g) {
            # Should also check for extra shifts really
            croak "Candidate uses $1:\n$string" if $string =~ /(\$_\[[^\]]\])/;
            # main::diag("Candidate: $string");
            $string =~ s/\bmy\s+\$$var\s*=\s*shift;(?:\s*\n)?(.*)\$$var\b/$1shift/s;
            # main::diag("Now: $string");
        }
    }
    # $string =~ s/(sub\s+\w+)\s*{.*\bCarp::croak\b\s*(\"[^\"]+\");.*}/$1 { Carp::croak $2 }/s; # "
    # Important that these are last one since they can expand to something
    # that contain the others
    $string =~ s{\b_(LITERAL|STRING)\b}{
        $1 eq "LITERAL" ?
            defined $_self->[0]{index} ? $_self->[0]{index} : croak("undefined access") :
            _stringify($_self->[0]{index})}eg;
    $string
        =~ s/^([^\S\n]*sub\s+(\w+)\s*\{)/#line 1 "${package}::$2"\n$1/mg;
    print STDERR "Code:\n$string\n" if DEBUG;
    my $err = $@;
    eval $string;
    die $@ if $@;
    $@ = $err;
}

sub count {
    return $#{+shift};
}

sub extract_all {
    my $heap = shift;
    return map $heap->extract_top, 2..@$heap;
}

sub clear {
    $#{+shift} = 0;
}

sub absorb {
    my $heap = shift;
    $_->_absorb($heap) for @_;
}

sub key_absorb{
    my $heap = shift;
    $_->_key_absorb($heap) for @_;
}

sub wrapped {
    return;
}

sub max_count {
    return shift->[0]{max_count} || 9**9**9;
}

sub dirty {
    return shift->[0]{dirty} || (wantarray() ? () : !1);
}

sub can_die {
    return shift->[0]{can_die} || (wantarray() ? () : !1);
}

sub key_index {
    croak "Heap elements are not of type 'Array'";
}

sub key_name {
    croak "Heap elements are not of type 'Hash'";
}

sub key_method {
    croak "Heap elements are not of type 'Method' or 'Object'";
}

sub key_function {
    croak "Heap elements are not of type 'Function' or 'Any'";
}

sub key_insert {
    croak "This heap type does not support key_insert";
}

sub _key_insert {
    croak "This heap type does not support _key_insert";
}

sub implementation() {
    return __PACKAGE__;
}

1;

__END__

sub insert {
    my $heap = shift;
    if ($heap->_KEY("") eq "") {
        $heap->_make('sub insert {
    my $heap = shift;
    _ORDER_PREPARE()
    _CANT_DIE(
    _MAX_COUNT(my $available = _THE_MAX_COUNT()-$#$heap;)
    if (@_ > 1 _MAX_COUNT(&& $available > 1)) {
	my $first = @$heap;
        my $i = push(@$heap, _MAX_COUNT(splice(@_, 0, $available), @_))-1;
	my @todo = reverse $first/2..$#$heap/2;
        while (my $j = shift @todo) {
	    my $key = $heap->[$j];
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
                $heap->[$l] = $key;
                $l >>= 1;
                push(@todo, $l) if !@todo || $l < $todo[0];
            }
        }
	return _MAX_COUNT(unless @_);
    })
    for my $key (@_) {
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
    $heap->[$l >> 1] = $key;
    next;})
    _CAN_DIE(eval {)
        $i = $i >> 1 while $i > 1 && _SMALLER($key, ($heap->[$i] = $heap->[$i >> 1]))
    _CAN_DIE(; 1} || $heap->_i_recover($i));
    $heap->[$i] = $key;
    }}');
    } else {
        $heap->_make('sub insert {
    my $heap = shift;
    _PREPARE()
    _CANT_DIE(
    _MAX_COUNT(my $available = _THE_MAX_COUNT()-$#$heap;)
    if (@_ > 1 _MAX_COUNT(&& $available > 1)) {
	my $first = @$heap;
        my $i = push(@$heap, _MAX_COUNT(splice(@_, 0, $available), @_))-1;
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
    }
    $heap->insert(@_);
}

sub extract_upto {
    my $heap = shift;
    $heap->_make('sub extract_upto {
    my $heap   = shift;
    my $border = shift;
    _PREPARE()
    my @result;
    push(@result, $heap->extract_top) until
        @$heap <= 1 || _SMALLER($border, _KEY($heap->[1]));
    return @result
}');
    $heap->extract_upto(@_);
}

sub first {
    my $heap = shift;
    if ($heap->_VALUE("") eq "") {
        $heap->_make('sub first {
    return shift->[1]
}');
    } else {
        $heap->_make('sub first {
    my $heap = shift;
    return _VALUE(($heap->[1] || return undef))
}');
    }
    return $heap->first(@_);
}

sub top {
    my $heap = shift;
    if ($heap->_KEY("") eq "") {
    $heap->_make('sub top {
    Carp::croak "Empty heap" if @{$_[0]} < 2;
    return _VALUE(shift->[1])
}');
    } else {
        $heap->_make('sub top {
    my $heap = shift;
    return _VALUE(($heap->[1] || Carp::croak "Empty heap"))
}');
    }
    $heap->top(@_);
}

sub extract_top {
    my $heap = shift;
    $heap->_make('sub extract_top {
    my $heap = shift;
    if (@$heap <= 3) {
        return _VALUE(pop(@$heap)) if @$heap == 2;
        Carp::croak "Empty heap" if @$heap < 2;
        my $min = $heap->[1];
        $heap->[1] = pop @$heap;
        return _VALUE($min);
    }
    my $min = $heap->[1];
    _PREPARE()
    my $key = _KEY($heap->[-1]);
    my $n = @$heap-2;
    my $l = 2;
    _CAN_DIE(eval {)
        while ($l < $n) {
            if (_SMALLER(_KEY($heap->[$l]), $key)) {
                $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
            } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                $l--;
                last;
            }
            $heap->[$l >> 1] = $heap->[$l];
            $l *= 2;
        }
        if ($l == $n && _SMALLER(_KEY($heap->[$l]), $key)) {
            $heap->[$l >> 1] = $heap->[$l];
            $l *= 2;
        }
    _CAN_DIE(        1
    } || $heap->_e_recover($l, $min);)
    $heap->[$l >> 1] = pop(@$heap);
    return _VALUE($min);
}');
    $heap->extract_top(@_);
}

sub extract_min {
    my $heap = shift;
    $heap->_make('sub extract_min {
    my $heap = shift;
    if (@$heap <= 3) {
        return _VALUE(pop(@$heap)) if @$heap == 2;
        Carp::croak "Empty heap" if @$heap < 2;
        my $min = $heap->[1];
        $heap->[1] = pop @$heap;
        return _VALUE($min);
    }
    my $min = $heap->[1];
    _PREPARE()
    my $key = _KEY($heap->[-1]);
    my $n = @$heap-2;
    my $l = 2;
    _CAN_DIE(eval {)
        while ($l < $n) {
            if (_SMALLER(_KEY($heap->[$l]), $key)) {
                $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
            } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                $l--;
                last;
            }
            $heap->[$l >> 1] = $heap->[$l];
            $l *= 2;
        }
        if ($l == $n && _SMALLER(_KEY($heap->[$l]), $key)) {
            $heap->[$l >> 1] = $heap->[$l];
            $l *= 2;
        }
    _CAN_DIE(        1;
    } || $heap->_e_recover($l, $min);)
    $heap->[$l >> 1] = pop(@$heap);
    return _VALUE($min)
}');
    $heap->extract_min(@_);
}

sub extract_first {
    my $heap = shift;
    $heap->_make('sub extract_first {
    my $heap = shift;
    if (@$heap <= 3) {
        return _VALUE(pop(@$heap)) if @$heap == 2;
        return if @$heap < 2;
        my $min = $heap->[1];
        $heap->[1] = pop @$heap;
        return _VALUE($min);
    }
    my $min = $heap->[1];
    _PREPARE()
    my $key = _KEY($heap->[-1]);
    my $n = @$heap-2;
    my $l = 2;
    _CAN_DIE(eval {)
        while ($l < $n) {
            if (_SMALLER(_KEY($heap->[$l]), $key)) {
                $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
            } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                $l--;
                last;
            }
            $heap->[$l >> 1] = $heap->[$l];
            $l *= 2;
        }
        if ($l == $n && _SMALLER(_KEY($heap->[$l]), $key)) {
            $heap->[$l >> 1] = $heap->[$l];
            $l *= 2;
        }
    _CAN_DIE(        1;
    } || $heap->_e_recover($l, $min);)
    $heap->[$l >> 1] = pop(@$heap);
    return _VALUE($min)
}');
    $heap->extract_first(@_);
}

sub top_key {
    my $heap = shift;
    if ($heap->_QUICK_KEY("") ne "-") {
        $heap->_make('sub top_key {
    my $heap = shift;
    return @$heap > 1 ? _QUICK_KEY($heap->[1]) :
        defined($heap->[0]{infinity}) ? $heap->[0]{infinity} : Carp::croak "Empty heap"
}');
    } else {
        $heap->_make('sub top_key {
    my $heap = shift;
    return defined($heap->[0]{infinity}) ? $heap->[0]{infinity} : Carp::croak "Empty heap" if @$heap <= 1;
    _ELEMENTS_PREPARE()
    return _KEY($heap->[1])
}');
    }
    $heap->top_key(@_);
}

sub min_key {
    my $heap = shift;
    if ($heap->_QUICK_KEY("") ne "-") {
        $heap->_make('sub min_key {
    my $heap = shift;
    return @$heap > 1 ? _QUICK_KEY($heap->[1]) :
        defined($heap->[0]{infinity}) ? $heap->[0]{infinity} : Carp::croak "Empty heap"
}');
    } else {
        $heap->_make('sub min_key {
    my $heap = shift;
    return defined($heap->[0]{infinity}) ? $heap->[0]{infinity} : Carp::croak "Empty heap" if
        @$heap <= 1;
    _ELEMENTS_PREPARE()
    return _KEY($heap->[1])
}');
    }
    $heap->min_key(@_);
}

sub first_key {
    my $heap = shift;
    if ($heap->_KEY("") eq "") {
        $heap->_make('sub first_key {
    return shift->[1]}');
    } elsif ($heap->_QUICK_KEY("") ne "-") {
        $heap->_make('sub first_key {
    my $heap = shift;
    return _QUICK_KEY(($heap->[1] || return undef))
}');
    } else {
    $heap->_make('sub first_key {
        my $heap = shift;
    return undef if @$heap <= 1;	# avoid autovivify
    _ELEMENTS_PREPARE()
    return _KEY($heap->[1])
}');
    }
    return $heap->first_key(@_);
}

sub key {
    my $heap = shift;
    if ($heap->_KEY("") eq "") {
        $heap->_make('sub key {
    return $_[1]}');
    } elsif ($heap->_QUICK_KEY("") ne "-") {
        $heap->_make('sub key {
    return _QUICK_KEY($_[1])}');
    } else {
        $heap->_make('sub key {
    my $heap = shift;
    _REAL_ELEMENTS_PREPARE()
    return _REAL_KEY(shift)}');
    }
    return $heap->key(@_);
}

sub keys {
    my $heap = shift;
    if($heap->_KEY("") eq "") {
        $heap->_make('sub keys {
    my $heap = shift;
    return @$heap[1..$#$heap]}');
    } else {
        $heap->_make('sub keys {
    my $heap = shift;
    _ELEMENTS_PREPARE()
    return map _KEY($_), @$heap[1..$#$heap]}');
    }
    return $heap->keys(@_);
}

sub values {
    my $heap = shift;
    if($heap->_VALUE("") eq "") {
        $heap->_make('sub values {
    my $heap = shift;
    return @$heap[1..$#$heap]}');
    } else {
        $heap->_make('sub values {
    my $heap = shift;
    return map _VALUE($_), @$heap[1..$#$heap]}');
    }
    return $heap->values(@_);
}

sub _absorb {
    my $heap = shift;
    if ($heap->_VALUE("") eq "") {
        $heap->_make('sub _absorb {
    my ($heap, $to) = @_;
    Carp::croak "Self absorption" if $heap == $to;
    if (@$heap > 2 && !$to->can_die) {
        $to->insert(@$heap[1..$#$heap]);
        $#$heap = 0;
        return;
    }
    while (@$heap > 1) {
        $to->insert(_VALUE($heap->[-1]));
        pop @$heap;
    }
}');
    } else {
        $heap->_make('sub _absorb {
    my ($heap, $to) = @_;
    Carp::croak "Self absorption" if $heap == $to;
    if (@$heap > 2 && !$to->can_die) {
        $to->insert(map _VALUE($_), @$heap[1..$#$heap]);
        $#$heap = 0;
        return;
    }
    while (@$heap > 1) {
        $to->insert(_VALUE($heap->[-1]));
        pop @$heap;
    }
}');
    }
    return $heap->_absorb(@_);
}

sub _key_absorb {
    my $heap = shift;
    $heap->_make('sub _key_absorb {
    my ($heap, $to) = @_;
    Carp::croak "Self absorption" if $heap == $to;
    _ELEMENTS_PREPARE()
    if (@$heap > 2 && !$to->can_die) {
        $to->key_insert(map +(_KEY($_), _VALUE($_)), @$heap[1..$#$heap]);
        $#$heap = 0;
        return;
    }
    while (@$heap > 1) {
        $to->key_insert(_KEY($heap->[-1]), _VALUE($heap->[-1]));
        pop @$heap;
    }
}');
    return $heap->_key_absorb(@_);
}

sub user_data {
    return shift->[0]{user_data} if @_ <= 1;
    my $heap = shift;
    my $old = $heap->[0]{user_data};
    $heap->[0]{user_data} = shift;
    return $old;
}

sub infinity {
    return shift->[0]{infinity} if @_ <= 1;
    my $heap = shift;
    my $old = $heap->[0]{infinity};
    $heap->[0]{infinity} = shift;
    return $old;
}

# Recover from a partially executed insert
sub _i_recover {
    my ($heap, $end, $err) = @_;
    $err ||= $@ || die "Assertion failed: No exception pending";
    my @indices;
    for (my $i = $#$heap; $i>$end; $i >>=1) {
        unshift @indices, $i;
    }
    for my $i (@indices) {
        $heap->[$end] = $heap->[$i];
        $end = $i;
    }
    pop @$heap;
    die $err;
}

# Recover from a partially executed extract
sub _e_recover {
    my ($heap, $end, $min, $err) = @_;
    $err ||= $@ || die "Assertion failed: No exception pending";
    $end >>= 1;
    $heap->[$end] = $heap->[$end >> 1] while ($end >>=1) > 1;
    $heap->[1] = $min;
    die $err;
}

sub merge_arrays {
    my $heap = shift;
    $heap->_make('sub merge_arrays {
    if (@_ <= 2) {
        return [] if @_ <= 1;
        my $array = $_[1];
        _MAX_COUNT(my $start = @$array - _THE_MAX_COUNT();
        return [@$array[$start..$#$array]] if $start > 0;)
        return [@$array];
    }
    my $heap = shift;
    my @heap = (undef);
    _REAL_PREPARE()
    my $key;
    my $left = 0;
    _MAX_COUNT(my $sorted;)
    for my $array (@_) {
        next if !@$array;
        _MAX_COUNT(if ($#heap == _THE_MAX_COUNT()) {
            unless ($sorted) {
                my $half = _THE_MAX_COUNT() >> 1;
                while ($half) {
                    my $l = $half * 2;
                    my $work = $heap[$half--];
                    while ($l < _THE_MAX_COUNT()) {
                        if (_SMALLER($heap[$l][0], $work->[0])) {
                            $l++ if _SMALLER($heap[$l+1][0], $heap[$l][0]);
                        } elsif (!(_SMALLER($heap[++$l][0], $work->[0]))) {
                            $l--;
                            last;
                        }
                        $heap[$l >> 1] = $heap[$l];
                        $l *= 2;
                    }
                    if ($l == _THE_MAX_COUNT() && _SMALLER($heap[_THE_MAX_COUNT()][0], $work->[0])) {
                        $heap[_THE_MAX_COUNT() >> 1] = $heap[_THE_MAX_COUNT()];
                        $l = _THE_MAX_COUNT() * 2;
                    }
                    $heap[$l >> 1] = $work;
                }
                $sorted = 1;
            }

            $key = _REAL_KEY($array->[-1]);
            next unless _SMALLER($heap[1][0], $key);
            my $l = 2;
            while ($l < _THE_MAX_COUNT()) {
                if (_SMALLER($heap[$l][0], $key)) {
                    $l++ if _SMALLER($heap[$l+1][0], $heap[$l][0]);
                } elsif (!(_SMALLER($heap[++$l][0], $key))) {
                    $l--;
                    last;
                }
                $heap[$l >> 1] = $heap[$l];
                $l *= 2;
            }
            if ($l == _THE_MAX_COUNT() && _SMALLER($heap[_THE_MAX_COUNT()][0], $key)) {
                $heap[_THE_MAX_COUNT() >> 1] = $heap[_THE_MAX_COUNT()];
            } else {
                $l >>= 1;
            }
            $left -= $heap[$l][2];
            $heap[$l] = [$key, $array, $#$array];
            $left += $heap[$l][2];
            next;
        })
        push(@heap, [_REAL_KEY($array->[-1]), $array, $#$array]);
        $left += @$array;
    }

    if (@heap <= 2) {
        return [] if @heap <= 1;
        my $array = $heap[1][1];
        _MAX_COUNT(my $start = @$array - _THE_MAX_COUNT();
        return [@$array[$start..$#$array]] if $start > 0;)
        return [@$array];
    }

    my $n = $#heap;
    my $half = $n >> 1;
    while ($half) {
        my $l = $half * 2;
        my $work = $heap[$half--];
        while ($l < $n) {
            if (_SMALLER($work->[0], $heap[$l][0])) {
                $l++ if _SMALLER($heap[$l][0], $heap[$l+1][0]);
            } elsif (!(_SMALLER($work->[0], $heap[++$l][0]))) {
                $l--;
                last;
            }
            $heap[$l >> 1] = $heap[$l];
            $l *= 2;
        }
        if ($l == $n && _SMALLER($work->[0], $heap[$l][0])) {
            $heap[$l >> 1] = $heap[$l];
            $l *= 2;
        }
        $heap[$l >> 1] = $work;
    }

    _MAX_COUNT($left = _THE_MAX_COUNT() if $left > _THE_MAX_COUNT();)
    my @result;
    while (1) {
        my $work = $heap[1];
        my $j = $work->[2];
        $result[--$left] = $work->[1][$j--];
        _MAX_COUNT(return \@result unless $left;)
        if ($j >= 0) {
            $key = _REAL_KEY($work->[1][$j]);
            $work->[0] = $key;
            $work->[2] = $j;
        } else {
            $work = pop @heap;
            if (--$n <= 1) {
                $left--;
                @result[0..$left] = @{$work->[1]}[$work->[2]-$left..$work->[2]];
                return \@result;
            }
            $key = $work->[0];
        }
        my $l = 2;
        while ($l < $n) {
            if (_SMALLER($key, $heap[$l][0])) {
                $l++ if _SMALLER($heap[$l][0], $heap[$l+1][0]);
            } elsif (!(_SMALLER($key, $heap[++$l][0]))) {
                $l--;
                last;
            }
            $heap[$l >> 1] = $heap[$l];
            $l *= 2;
        }
        if ($l == $n && _SMALLER($key, $heap[$l][0])) {
            $heap[$l >> 1] = $heap[$l];
            $l *= 2;
        }
        $heap[$l >> 1] = $work;
    }
}');
    $heap->merge_arrays(@_);
}

1;
__END__

=head1 NAME

Heap::Simple::Perl - A pure perl implementation of the Heap::Simple interface

=head1 SYNOPSIS

    # Let Heap::Simple decide which implementation that provides its interface
    # it will load and use. This may be Heap::Simple::Perl or it may not be.
    # Still, this is the normal way of using Heap::Simple
    use Heap::Simple;
    my $heap = Heap::Simple->new(...);
    # Use heap as described in the Heap::Simple documentation

    # If for some reason you insist on using this version:
    use Heap::Simple::Perl;
    my $heap = Heap::Simple::Perl->new(...);
    # Use the pure perl heap as described in the Heap::Simple documentation

=head1 DESCRIPTION

This module provides a pure perl implementation of the interface described
in L<Heap::Simple|Heap::Simple>. Look there for a description.

=head1 NOTES

=over

=item

The L<dirty option|Heap::Simple/new_dirty> has no effect. This heap type
doesn't currently do any potentially unsafe optimizations.

=item

Heap::Simple->implementation will return C<"Heap::Simple::Perl"> if it selected
this module.

=back

=head1 EXPORT

None.

=head1 SEE ALSO

L<Heap::Simple>,
L<Heap::Simple::XS>

=head1 AUTHOR

Ton Hospel, E<lt>Heap-Simple@ton.iguana.beE<gt>

Parts are inspired by code by Joseph N. Hall
L<http://www.perlfaq.com/faqs/id/196>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
