package FU::Validate 1.2;

use v5.36;
use experimental 'builtin', 'for_list';
use builtin qw/true false blessed trim/;
use Carp 'confess';
use FU::Util 'to_bool';


# Unavailable as custom validation names
my %builtin = map +($_,1), qw/
    type
    default
    onerror
    trim
    elems sort unique
    accept_scalar accept_array
    keys values unknown missing
    func
/;

my %type_vals = map +($_,1), qw/scalar hash array any/;
my %unknown_vals = map +($_,1), qw/remove reject pass/;
my %missing_vals = map +($_,1), qw/create reject ignore/;
my %implied_type = qw/
    accept_array scalar
    keys hash values hash unknown hash
    elems array sort array unique array accept_scalar array
/;
my %sort_vals = (
    str => sub($x,$y) { $x cmp $y },
    num => sub($x,$y) { $x <=> $y },
);

sub _length($exp, $min, $max) {
    [ func => sub($v) {
        my $got = ref $v eq 'HASH' ? keys %$v : ref $v eq 'ARRAY' ? @$v : length $v;
        (!defined $min || $got >= $min) && (!defined $max || $got <= $max) ? 1 : { expected => $exp, got => $got };
    }]
}

# Basically the same as ( regex => $arg ), but hides the regex error
sub _reg($reg) {
    ( type => 'scalar', func => sub { $_[0] =~ $reg ? 1 : { got => $_[0] } } );
}


our $re_num       = qr/^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?$/;
our $re_int       = qr/^-?(?:0|[1-9][0-9]*)$/;
our $re_uint      = qr/^(?:0|[1-9][0-9]*)$/;
our $re_fqdn      = qr/(?:[a-zA-Z0-9][\w-]*\.)+[a-zA-Z][a-zA-Z0-9-]{1,25}\.?/;
our $re_ip4_digit = qr/(?:0|[1-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])/;
our $re_ip4       = qr/($re_ip4_digit\.){3}$re_ip4_digit/;
# This monstrosity is based on http://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses
# Doesn't allow IPv4-mapped-IPv6 addresses or other fancy stuff.
our $re_ip6       = qr/(?:[0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?:(?::[0-9a-fA-F]{1,4}){1,6})|:(?:(?::[0-9a-fA-F]{1,4}){1,7}|:)/;
our $re_ip        = qr/(?:$re_ip4|$re_ip6)/;
our $re_domain    = qr/(?:$re_fqdn|$re_ip4|\[$re_ip6\])/;
our $re_email     = qr/^[-\+\.#\$=\w]+\@$re_fqdn$/;
our $re_weburl    = qr/^https?:\/\/$re_domain(?::[1-9][0-9]{0,5})?(?:\/[^\s<>"]*)$/;
our $re_date      = qr/^(?:19[0-9][0-9]|20[0-9][0-9])-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])$/;


# There's a special '_scalartype' option used for coerce() and empty(), with the following values:
#   0/undef/missing: string, 1:num, 2:int, 3:bool
# The highest number, i.e. most restrictive type, is chosen when multiple validations exist.

our %default_validations = (
    regex => sub($reg) {
        # Error objects should be plain data structures so that they can easily
        # be converted to JSON for debugging. We have to stringify $reg in the
        # error object to ensure that.
        +{ type => 'scalar', func => sub { $_[0] =~ $reg ? 1 : { regex => "$reg", got => $_[0] } } }
    },
    enum => sub($vals) {
        my @l = ref $vals eq 'HASH' ? sort keys %$vals : ref $vals eq 'ARRAY' ? @$vals : ($vals);
        my %opts = map +($_,1), @l;
        +{ type => 'scalar', func => sub { $opts{ (my $v = $_[0]) } ? 1 : { expected => \@l, got => $_[0] } } }
    },

    minlength => sub($v) { _length $v, $v, undef },
    maxlength => sub($v) { _length $v, undef, $v },
    length    => sub($v) { _length $v, ref $v eq 'ARRAY' ? @$v : ($v, $v) },

    bool      => { _scalartype => 3, type => 'any', func => sub { my $r = to_bool $_[0]; return {} if !defined $r; $_[0] = $r; 1 } },
    anybool   => { _scalartype => 3, type => 'any', default => false, func => sub { $_[0] = $_[0] ? true : false; 1 } },

    num   => [ _scalartype => 1, _reg($re_num), func => sub { $_[0] = $_[0]*1; 1 } ],
    int   => [ _scalartype => 2, _reg($re_int), func => sub { return { message => 'integer out of range' } if $_[0] < -9223372036854775808 || $_[0] > 9223372036854775807; $_[0] = int $_[0]; 1 } ],
    uint  => [ _scalartype => 2, _reg($re_uint), func => sub { return { message => 'integer out of range' } if $_[0] > 18446744073709551615; $_[0] = int $_[0]; 1 } ],
    min   => sub($min) { +{ num => 1, func => sub { $_[0] >= $min ? 1 : { expected => $min, got => $_[0] } } } },
    max   => sub($max) { +{ num => 1, func => sub { $_[0] <= $max ? 1 : { expected => $max, got => $_[0] } } } },
    range => sub { [ min => $_[0][0], max => $_[0][1] ] },

    ascii  => { _reg qr/^[\x20-\x7E]*$/ },
    sl     => { _reg qr/^[^\t\r\n]+$/ },
    ipv4   => { _reg $re_ip4 },
    ipv6   => { _reg $re_ip6 },
    ip     => { _reg $re_ip  },
    email  => { _reg($re_email),  maxlength => 254 },
    weburl => { _reg($re_weburl), maxlength => 65536 }, # the maxlength is a bit arbitrary, but better than unlimited
    date   => { _reg $re_date },
);


sub _new { bless { validations => [], @_ }, __PACKAGE__ }


sub _compile($schema, $custom, $rec, $top, $validations=$top->{validations}) {
    my $iscompiled = $schema isa __PACKAGE__;

    # For hashref schemas, builtins always override other validations
    $schema = [
        map +($_, $schema->{$_}),
            (grep !$builtin{$_}, keys %$schema),
            (grep $builtin{$_}, keys %$schema),
    ] if ref $schema ne 'ARRAY';

    for my($name, $val) (@$schema) {
        if ($name eq 'type') {
            confess "Invalid value for 'type': $val" if $name eq 'type' && !$type_vals{$val};
            confess "Incompatible types, the schema specifies '$val', but another validation requires '$top->{type}'" if $top->{type} && $top->{type} ne $val;;
            $top->{type} = $val;
            next;
        }

        my $type = $implied_type{$name};
        if ($type) {
            confess "Incompatible types, the schema specifies '$top->{type}' but the '$name' validation implies '$type'" if $top->{type} && $top->{type} ne $type;
            $top->{type} = $type;
        }

        if ($name eq 'elems' || $name eq 'values') {
            $top->{$name} ||= _new;
            _compile($val, $custom, $rec-1, $top->{$name});
            next;
        }

        if ($name eq 'keys') {
            $top->{keys} ||= {};
            for my($n,$v) (%$val) {
                $top->{keys}{$n} ||= _new;
                _compile($v, $custom, $rec-1, $top->{keys}{$n});
            }
            next;
        }

        if ($name eq 'func') {
            push @$validations, $val;
            next;
        }

        if ($name eq 'default') {
            $top->{default} = $val;
            delete $top->{default} if ref $val eq 'SCALAR' && $$val eq 'required';
            next;
        }

        if ($name eq '_scalartype') {
            $top->{_scalartype} = $val if ($top->{_scalartype}||0) < $val;
            next;
        }

        if ($builtin{$name}) {
            confess "Invalid value for 'missing': $val" if $name eq 'missing' && !$missing_vals{$val};
            confess "Invalid value for 'unknown': $val" if $name eq 'unknown' && !$unknown_vals{$val};
            confess "Invalid value for 'accept_array': $val" if $name eq 'accept_array' && $val && $val ne 'first' && $val ne 'last';
            $val = $sort_vals{$val} || confess "Unknown value for 'sort': $val" if $name eq 'sort' && ref $val ne 'CODE';
            $top->{$name} = $val;
            next;
        }

        if ($iscompiled && $name eq 'validations') {
            push @$validations, @$val;
            next;
        }

        my $t = $custom->{$name} || $default_validations{$name};
        confess "Unknown validation: $name" if !$t;
        confess "Recursion limit exceeded while resolving validation '$name'" if $rec < 1;
        $t = ref $t eq 'CODE' ? $t->($val) : $t;

        my $v = _new name => $name;
        _compile($t, $custom, $rec-1, $top, $v->{validations});
        push @$validations, $v if $v->{validations}->@*;
    }
}


sub compile($pkg, $schema, $custom={}) {
    return $schema if $schema isa __PACKAGE__;
    my $c = _new;
    _compile $schema, $custom, 64, $c;
    $c
}


sub _validate_hash {
    my $c = $_[0];

    if ($c->{keys}) {
        my @err;
        for my ($k, $s) ($c->{keys}->%*) {
            if (!exists $_[1]{$k}) {
                next if $s->{missing} && $s->{missing} eq 'ignore';
                return { validation => 'missing', key => $k } if $s->{missing} && $s->{missing} eq 'reject';
                $_[1]{$k} = ref $s->{default} eq 'CODE' ? $s->{default}->() : $s->{default} // undef;
                next if exists $s->{default};
            }

            my $r = _validate($s, $_[1]{$k});
            if ($r) {
                $r->{key} = $k;
                push @err, $r;
            }
        }
        return { validation => 'keys', errors => [ sort { $a->{key} cmp $b->{key} } @err ] } if @err;
    }

    if ($c->{values}) {
        my @err;
        for my ($k, $v) ($_[1]->%*) {
            my $r = _validate($c->{values}, $v);
            if ($r) {
                $r->{key} = $k;
                push @err, $r;
            }
        }
        return { validation => 'values', errors => [ sort { $a->{key} cmp $b->{key} } @err ] } if @err;
    }
}

sub _validate_elems {
    my @err;
    for my $i (0..$#{$_[1]}) {
        my $r = _validate($_[0]{elems}, $_[1][$i]);
        if ($r) {
            $r->{index} = $i;
            push @err, $r;
        }
    }
    return { validation => 'elems', errors => \@err } if @err;
}


sub _validate_rec {
    my $c = $_[0];
    for my $v ($c->{validations}->@*) {
        if (ref $v eq 'CODE') {
            my $r = $v->($_[1]);
            return { %$r, validation => 'func' } if ref $r eq 'HASH';
            return { validation => 'func', result => $r } if !$r;
        } else {
            my $r = _validate_rec($v, $_[1]);
            return {
                # If the error was a custom 'func' object, then make that the primary cause.
                # This makes it possible for validations to provide their own error objects.
                $r->{validation} eq 'func' && (!exists $r->{result} || keys $r->%* > 2) ? $r->%* : (error => $r),
                validation => $v->{name},
            } if $r;
        }
    }
}


sub _validate_array {
    my $c = $_[0];

    $_[1] = [sort { $c->{sort}->($a, $b) } $_[1]->@* ] if $c->{sort};

    # Key-based uniqueness
    if ($c->{unique} && (!$c->{sort} || ref $c->{unique} eq 'CODE')) {
        my %h;
        for my $i (0..$#{$_[1]}) {
            my $k = ref $c->{unique} eq 'CODE' ? $c->{unique}->($_[1][$i]) : $_[1][$i];
            return { validation => 'unique', index_a => $h{$k}, value_a => $_[1][$h{$k}], index_b => $i, value_b => $_[1][$i], key => $k } if exists $h{$k};
            $h{$k} = $i;
        }

    # Comparison-based uniqueness
    } elsif ($c->{unique}) {
        for my $i (0..$#{$_[1]}-1) {
            return { validation => 'unique', index_a => $i, value_a => $_[1][$i], index_b => $i+1, value_b => $_[1][$i+1] }
                if $c->{sort}->($_[1][$i], $_[1][$i+1]) == 0
        }
    }
}


sub _validate_input {
    my $c = $_[0];

    my $type = $c->{type} // 'scalar';

    # accept_array (needs to be done before 'trim')
    $_[1] = $_[1]->@* == 0 ? undef : $c->{accept_array} eq 'first' ? $_[1][0] : $_[1][ $#{$_[1]} ]
        if $c->{accept_array} && ref $_[1] eq 'ARRAY';

    # trim (needs to be done before the 'default' test)
    $_[1] = trim $_[1] =~ s/\r//rg if defined $_[1] && !ref $_[1] && $type eq 'scalar' && (!exists $c->{trim} || $c->{trim});

    # default
    if (!defined $_[1] || (!ref $_[1] && $_[1] eq '')) {
        if (exists $c->{default}) {
            $_[1] = ref $c->{default} eq 'CODE' ? $c->{default}->($_[1]) : $c->{default};
            return;
        }
        return { validation => 'required' };
    }

    if ($type eq 'scalar') {
        return { validation => 'type', expected => 'scalar', got => lc ref $_[1] } if ref $_[1];

    } elsif ($type eq 'hash') {
        return { validation => 'type', expected => 'hash', got => lc ref $_[1] || 'scalar' } if ref $_[1] ne 'HASH';

        # Each branch below makes a shallow copy of the hash, so that further
        # validations can perform in-place modifications without affecting the
        # input.
        if (!$c->{keys} || ($c->{unknown} && $c->{unknown} eq 'pass')) {
            $_[1] = { $_[1]->%* };
        } elsif (!$c->{unknown} || $c->{unknown} eq 'remove') {
            $_[1] = { map +($_, $_[1]{$_}), grep $c->{keys}{$_}, keys $_[1]->%* };
        } else {
            my @err = grep !$c->{keys}{$_}, keys $_[1]->%*;
            return { validation => 'unknown', keys => \@err, expected => [ sort keys $c->{keys}->%* ] } if @err;
            $_[1] = { $_[1]->%* };
        }

    } elsif ($type eq 'array') {
        $_[1] = [$_[1]] if $c->{accept_scalar} && !ref $_[1];
        return { validation => 'type', expected => $c->{accept_scalar} ? 'array or scalar' : 'array', got => lc ref $_[1] || 'scalar' } if ref $_[1] ne 'ARRAY';
        $_[1] = [$_[1]->@*]; # Create a shallow copy to prevent in-place modification.

    } elsif ($type eq 'any') {
        # No need to do anything here.
    }

    ($type eq 'hash' && &_validate_hash) ||
    ($c->{elems} && &_validate_elems) ||
    &_validate_rec ||
    ($type eq 'array' && &_validate_array)
}


sub _validate {
    my $c = $_[0];
    my $r = &_validate_input;
    ($r, $_[1]) = (undef, ref $c->{onerror} eq 'CODE' ? $c->{onerror}->($_[0], bless $r, 'FU::Validate::err') : $c->{onerror})
        if $r && exists $c->{onerror};
    $r
}


sub validate($c, $input) {
    my $r = _validate($c, $input);
    return $input if !$r;
    $r = bless $r, 'FU::Validate::err';;
    my @e = $r->errors;
    $r->{longmess} = Carp::longmess(@e > 1 ? join("\n",@e)."\n" : $e[0]);
    die $r;
}


sub coerce {
    my $c = $_[0];
    my %opt = @_[2..$#_];
    if (!defined $_[1]) {
        $_[1] = undef;
    } elsif ($c->{_scalartype}) {
        $_[1] = $c->{_scalartype} == 3 ? !!$_[1] : $c->{_scalartype} == 2 ? int $_[1] : $_[1]+0;
    } elsif (!$c->{type} || $c->{type} eq 'scalar') {
        $_[1] = "$_[1]";
    } elsif ($c->{type} eq 'array' && $c->{elems} && ref $_[1] eq 'ARRAY') {
        coerce($c->{elems}, $_, %opt) for $_[1]->@*;
    } elsif ($c->{type} eq 'hash' && $c->{keys} && ref $_[1] eq 'HASH') {
        $opt{unknown} ||= $c->{unknown};
        delete @{$_[1]}{ grep !$c->{keys}{$_}, keys $_[1]->%* }
            if $opt{unknown} && $opt{unknown} ne 'pass';
        $_[1]{$_} = exists $_[1]{$_} ? coerce($c->{keys}{$_}, $_[1]{$_}, %opt) : empty($c->{keys}{$_})
            for keys $c->{keys}->%*;
    }
    return $_[1];
}


sub empty($c) {
    return ref $c->{default} eq 'CODE' ? $c->{default}->(undef) : $c->{default} if exists $c->{default};
    return [] if $c->{type} && $c->{type} eq 'array';
    return $c->{keys} ? +{ map +($_, empty($c->{keys}{$_})), keys $c->{keys}->%* } : {} if $c->{type} && $c->{type} eq 'hash';
    return undef if $c->{type} && $c->{type} eq 'any';
    # Only scalar types remain
    return !$c->{_scalartype} ? '' : $c->{_scalartype} == 3 ? !1 : 0;
}



sub _fmtkey($k) { $k =~ /^[a-zA-Z0-9_-]+$/ ? $k : FU::Util::json_format($k); }
sub _fmtval($v) { eval { $v = FU::Util::json_format($v) }; "$v" }
sub _inval($t,$v) { sprintf 'invalid %s: %s', $t, _fmtval $v }

# validation name => formatting sub
# TODO: document.
our %error_format = (
    required  => sub { 'required value missing' },
    type      => sub($e) { "invalid type, expected '$e->{expected}' but got '$e->{got}'" },
    unknown   => sub($e) { sprintf 'unknown key%s: %s', $e->{keys}->@* == 1 ? '' : 's', join ', ', map _fmtkey($_), $e->{keys}->@* },
    minlength => sub($e) { sprintf "input too short, expected minimum of %d but got %d", $e->{expected}, $e->{got} },
    maxlength => sub($e) { sprintf "input too long, expected maximum of %d but got %d", $e->{expected}, $e->{got} },
    length    => sub($e) {
        !ref $e->{expected}
        ? sprintf 'invalid input length, expected %d but got %d', $e->{expected}, $e->{got}
        : sprintf 'invalid input length, expected between %d and %d but got %d', $e->{expected}->@*, $e->{got}
    },
    num       => sub($e) { _inval 'number', $e->{got} },
    min       => sub($e) { $e->{error} ? _inval 'number', $e->{error}{got} : sprintf 'expected minimum %s but got %s', $e->{expected}, $e->{got} },
    max       => sub($e) { $e->{error} ? _inval 'number', $e->{error}{got} : sprintf 'expected maximum %s but got %s', $e->{expected}, $e->{got} },
    range     => sub($e) { FU::Validate::err::errors($e->{error}) },
);


package FU::Validate::err;
use v5.36;

use overload '""' => sub { $_[0]{longmess} || join "\n", $_[0]->errors };

# TODO: document.
sub errors($e, $prefix='') {
    my $val = $e->{validation};
    my $p = $prefix ? "$prefix: " : '';
    $FU::Validate::error_format{$val} ? map "$p$_", $FU::Validate::error_format{$val}->($e) :
    $val eq 'keys'     ? map errors($_, $prefix.'.'.FU::Validate::_fmtkey($_->{key})), $e->{errors}->@* :
    $val eq 'values'   ? map errors($_, $prefix.'.'.FU::Validate::_fmtkey($_->{key})), $e->{errors}->@* :
    $val eq 'missing'  ? $prefix.'.'.FU::Validate::_fmtkey($e->{key}).': required key missing' :
    $val eq 'elems'    ? map errors($_, $prefix."[$_->{index}]"), $e->{errors}->@* :
    $val eq 'unique'   ? $prefix."[$e->{index_b}] value '".FU::Validate::_fmtval($e->{value_a})."' duplicated" :
    $e->{error}        ? errors($e->{error}, "${p}validation '$val'") :
    $e->{message}      ? "${p}validation '$val': $e->{message}" :
                         "${p}failed validation '$val'";
}


1;
__END__

=head1 NAME

FU::Validate - Data and form validation and normalization

=head1 DESCRIPTION

This module provides an easy and simple interface for data validation. It can
handle most types of data structures (scalars, hashes, arrays and nested data
structures), and has some conveniences for validating form-like data.

That this module will not solve B<all> your input validation problems. It can
validate the format and the structure of the data, but it does not support
validations that depend on other input values. For example, it is not possible
to specify that the contents of a I<password> field must be equivalent to that
of a I<confirm_password> field, but you can specify that both fields need to be
filled out. Recursive data structures are not supported. There is also no good
support for validating hashes with dynamic keys or arrays where not all
elements conform to the same schema. These could technically still be validated
with custom validations, but it won't be as convenient.

This module is designed to validate any kind of program input after it has been
parsed into a Perl data structure. It should not be used to validate function
parameters within Perl code. In fact, the correct answer to "how do I validate
function parameters?" is "don't, document your assumptions instead".


=head1 Validation API

To validate some input, you first need a schema. A schema can be compiled as
follows:

  my $validator = FU::Validate->compile($schema, $validations);

C<$schema> is the schema that describes the data to be validated (see L</Schema
Definition> below) and C<$validations> is an optional hashref containing
L<custom validations|/Custom validations> that C<$schema> can refer to.  An
error is thrown if the C<$validations> or C<$schema> are invalid.

To validate input, run:

  my $validated_input = $validator->validate($input);

C<validate()> returns a validated and (depending on the schema) normalized copy
of C<$input>. Great care is taken that C<$input> is not being modified
in-place, even if data normalization is being performed.

An error is thrown if the input does not validate. The error object is a
C<FU::Validate::err>-blessed hashref containing at least one key:
I<validation>, which indicates the name of the validation that failed.
Additional keys with more detailed information may be present, depending on the
validation. These are documented in L</Schema Definition> below.

Additional utility methods:

=over

=item $validator->empty

Returns an "empty" value that roughly follows the data structure described by
the schema. The returned value does not necessarily validate but can still be
useful as a template. Works roughly as follows:

=over

=item * If the schema has a I<default>, then that is returned.

=item * If the schema describes a hash, then a hash is returned with each key
in I<keys> initialized to an empty value.

=item * If the schema describes an array, an empty array is returned.

=item * If the schema describes a bool, return C<false>.

=item * If the schema describes a number, return C<0>.

=item * If the schema describes a string, return C<''>.

=item * Otherwise, return C<undef>.

=back

=item $validator->coerce($input, %opt)

Perform in-place coercion of C<$input> to the data types described by the
schema. Also returns the modified C<$input> for convenience. This method assumes
that C<$input> already has the general structure described by the schema and is
mainly useful to ensure that encoding the value as JSON will end up with the
correct data types. i.e. booleans are encoded as booleans, integers as integers
(truncating if necessary), numbers as numbers, etc.

If an input hash is missing keys described in the schema, then those are
created with C<< ->empty >>. If the schema has I<unknown> set to either
I<reject> or I<remove>, unknown keys are removed. This behavior can be
overriden by passing different I<unknown> value in C<%opt>.

This method does NOT perform any sort of validation and will happily pass
through garbage if the given C<$input> does not follow the structure of the
schema. It's basically a faster and lousier normalization-only alternative to
C<< ->validate() >>.

=back


=head1 Schema Definition

A schema is an arrayref or hashref, where each key is the name of a built-in
option or of a validation to be performed and the values are the arguments to
those validations. None of the options or validations are required, but some
built-ins have default values. This means that the empty schema C<{}> is
actually equivalent to:

  { type    => 'scalar',
    trim    => 1,
    default => \'required',
    missing => 'create',
  }

Built-in options are always validated in a fixed order, but the order in which
standard and custom validations are performed is random when the schema is
given as a hashref. This is rarely a problem, but it can in some cases affect
the returned error message or whether a later validation will receive data
normalized by a previous validation. An arrayref can be used to enforce a
validation order:

  [ enum => [1, 2, 'a'], int => 1 ]

Or to use the same validation multiple times:

  [ regex => qr/^a/, regex => qr/z$/ ]

=head1 Built-in options

=over

=item type => $type

Specify the type of the input, this can be I<scalar>, I<array>, I<hash> or
I<any>. If no type is specified or implied by other validations, the default
type is I<scalar>.

Upon failure, the error object will look something like:

  { validation => 'type',
    expected   => 'hash',
    got        => 'scalar'
  }

=item default => $val

If not set, or set to C<\'required'> (note: scalarref), then a value is required
for this field. Specifically, this means that a value must exist and must not
be C<undef> or an empty string, i.e. C<exists($x) && defined($x) && $x ne ''>.

If set to any other value, then the input is considered optional and the given
C<$val> is returned instead. If C<$val> is a CODE reference, the subroutine is
called with the original value (which is either no argument, undef or an empty
string) and the return value of the subroutine is used as value instead.

The empty check is performed after I<trim> and before any other validations. So
a string containing only whitespace is considered an empty string and will be
treated according to this I<default> option. As an additional side effect,
other validations will never get to validate undef or an empty string, as these
values are either rejected or substituted with a default.

=item onerror => $val

Instead of reporting an error, return C<$val> if this input fails validation
for whatever reason. Setting this option in the top-level schema ensures that
the validation will always succeed regardless of the input.

If C<$val> is a CODE reference, the subroutine is called with the (partially
normalized) input as first argument and error object as second argument. The
return value of the subroutine is then returned for this validation.

=item trim => 0/1

By default, any whitespace around scalar-type input is removed before testing
any other validations. Setting I<trim> to a false value will disable this
behavior.

=item keys => $hashref

Implies C<< type => 'hash' >>, this option specifies which keys are permitted,
and how to validate the values. Each key in C<$hashref> corresponds to a key
with the same name in the input. Each value is a schema definition by which the
value in the input will be validated. The schema definition may be a bare
hashref or a validator returned by C<compile()>. If a key is not present in
the input hash, it will be created in the output with the default value (or
undef), but see the I<missing> option for how to change that behavior.

For example, the following schema specifies that the input must be a hash with
three keys:

  { type => 'hash',
    keys => {
      username => { maxlength => 16 },
      password => { minlength => 8 },
      email    => { default => '', email => 1 }
    }
  }

If validation on one or more keys fail, the error object that is returned looks
like:

  { validation => 'keys',
    errors => [
      # List of error objects, each with an additional 'key' field.
      { key => 'username', validation => 'required' }
      # In this case, the username was required but either absent or empty.
    ]
  }

=item values => $schema

Implies C<< type => 'hash' >>, set a schema that is used to validate every hash
value. Can be used together with I<keys>, in which case values must validate
both this C<$schema> and the schema corresponding to the key.

=item unknown => $option

Implies C<< type => 'hash' >>, this option specifies what to do with keys in
the input data that have not been defined in the I<keys> option. Possible
values are I<remove> to remove unknown keys from the output data (this is the
default), I<reject> to return an error if there are unknown keys in the input,
or I<pass> to pass through any unknown keys to the output data. Values for
passed-through keys are only validated when the I<values> option is set,
otherwise they are passed through as-is. This option has no effect when the
I<keys> option is never set, in that case all values are always passed through.

In the case of I<reject>, the error object will look like:

  { validation => 'unknown',
    # List of unknown keys present in the input
    keys       => ['unknown1', .. ],
    # List of known keys (which may or may not be present
    # in the input - that is checked at a later stage)
    expected   => ['known1', .. ]
  }

=item missing => $option

For values inside a hash I<keys> schema, this option specifies what to do when
the key is not present in the input data. Possible values are I<create> to
insert the key with a default value (if the I<default> option is set, otherwise
undef), I<reject> to return an error if the option is missing or I<ignore> to
leave the key out of the returned data.

The default is I<create>, but if no I<default> option is set for this key then
that is effectively the same as I<reject>. Values created through I<create> are
still validated through I<values> if that has been set.

In the case of I<reject>, the error object will look like:

  { validation => 'missing',
    key        => 'field'
  }

=item elems => $schema

Implies C<< type => 'array' >>, this defines the schema that is applied to
every element in the array.  The schema definition may be a bare hashref or a
validator returned by C<compile()>.

Failure is reported in a similar fashion to I<keys>:

  { validation => 'elems',
    errors => [
      { index => 1, validation => 'required' }
    ]
  }

=item accept_scalar => 0/1

Implies C<< type => 'array' >>, this option will also permit the input to be a
scalar. In that case, the input is interpreted and returned as an array with
only one element. This option exists to make it easy to validate multi-value
form inputs. For example, consider C<query_decode()> in L<FU::Util>: a
parameter in a query string is decoded into an array if it is listed multiple
times, a scalar if it only occcurs once. So we could either end up with:

  { a => 1, b => 1 }
  # OR:
  { a => [1, 3], b => 1 }

With the I<accept_scalar> option, we can accept both forms for C<a> and
normalize into an array. The following schema definition can validate the above
examples:

  { type => 'hash',
    keys => {
      a => { type => 'array', accept_scalar => 1 },
      b => { }
    }
  }

=item accept_array => false/'first'/'last'

Implies C<< type => 'scalar' >>. Similar to I<accept_scalar> but normalizes in
the other direction: when the input is an array, only the first or last item is
extracted and the other elements are ignored. If the input is an empty array,
the value is taken to be C<undef>.

=item sort => $option

Implies C<< type => 'array' >>, sort the array after validating its elements.
C<$option> determines how the array is sorted, possible values are I<str> for
string comparison, I<num> for numeric comparison, or a subroutine reference for
custom comparison function. The subroutine must be similar to the one given to
Perl's C<sort()> function, except it should compare C<$_[0]> and C<$_[1]>
instead of C<$a> and C<$b>.

=item unique => $option

Implies C<< type => 'array' >>, require elements to be unique. That is, don't
allow duplicate elements. There are several ways to specify what uniqueness
means in this context:

If C<$option> is a subroutine reference, then the subroutine is given an
element as first argument, and it should return a string that is used to check
for uniqueness. For example, if array elements are hashes, and you want to
check for uniqueness of a hash key named I<id>, you can specify this as
C<< unique => sub { $_[0]{id} } >>.

Otherwise, if C<$option> is true and the I<sort> option is set, then the
comparison function used for sorting is also used as uniqueness check. Two
elements are the same if the comparison function returns C<0>.

If C<$option> is true and I<sort> is not set, then the elements will be
interpreted as strings, similar to setting C<< unique => sub { $_[0] } >>.

All of that may sound complicated, but it's quite easy to use. Here's a few
examples:

  # This describes an array of hashes with keys 'id' and 'name'.
  { elems => {
      keys => {
        id   => { uint => 1 },
        name => {}
      }
    },
    # Sort the array on 'id'
    sort => sub { $_[0]{id} <=> $_[1]{id} },
    # And require that 'id' fields are unique
    unique => 1
  }

  # Contrived example: An array of strings, and we want
  # each string to start with a different character.
  { elems => { minlength => 1 },
    unique => sub { substr $_[0], 0, 1 }
  }

On failure, this validation returns the following error object. This output
assumes the first schema from the previous example.

  { validation => 'unique',
    # Index and value of element a
    index_a => 1,
    value_a => { id => 3, name => 'whatever' }
    # Index and value of duplicate element b
    index_b => 4,
    value_b => { id => 3, name => 'something else' },
    # If string-based uniqueness was used, this is included as well:
    # key => '..'
  }


=item func => $sub

Run the input through a subroutine to perform additional validation or
normalization. When the schema is a hashref, the subroutine is only called
after all other validations have succeeded. The subroutine is called with the
input as its only argument.  Normalization of the input can be done by
assigning to the first argument or modifying its value in-place.

On success, the subroutine should return a true value. On failure, it should
return either a false value or a hashref. The hashref will have the
I<validation> key set to I<func>, and this will be returned as error object.

When I<func> is used inside a custom validation, the returned error object will
have its I<validation> field set to the name of the custom validation. This
makes custom validations to behave as first-class validations in terms of error
reporting.


=back

=head1 Standard validations

Standard validations are provided by the module. It is possible to override,
re-implement and supplement these with custom validations. Internally, these
are, in fact, implemented as custom validations.

=over

=item regex => $re

Implies C<< type => 'scalar' >>. Validate the input against a regular
expression.

=item enum => $options

Implies C<< type => 'scalar' >>. Validate the input against a list of known
values. C<$options> can be either a scalar (in which case that is the only
permitted input), an array (listing all possible inputs) or a hash (where the
hash keys are considered to be the list of permitted inputs).

=item minlength => $num

Minimum length of the input. The I<length> is the string C<length()> if the
input is a scalar, the number of elements if the input is an array, or the
number of keys if the input is a hash.

=item maxlength => $num

Maximum length of the input.

=item length => $option

If C<$option> is a number, then this specifies the exact length of the input.
If C<$option> is an array, then this is a shorthand for
C<[$minlength,$maxlength]>.

=item anybool => 1

Accept any value of any type as input, and normalize it to either C<true> or
C<false> according to Perl's idea of truth.

=item bool => 1

Require the input to be a boolean type as per C<to_bool()> in L<FU::Util>.

=item num => 1

Implies C<< type => 'scalar' >>. Require the input to be a number formatted
using the format permitted by JSON. Note that this is slightly more restrictive
from Perl's number formatting, in that 'NaN', 'Inf' and thousand separators are
not permitted. The value is normalized to a Perl integer or floating point
value, which means precision for large numbers may be lost.

=item int => 1

Implies C<< type => 'scalar' >>. Require the input to be an (at most) 64-bit
integer.

=item uint => 1

Implies C<< type => 'scalar' >>. Require the input to be an (at most) 64-bit
unsigned integer.

=item min => $num

Implies C<< num => 1 >>. Require the input to be larger than or equal to
C<$num>.

=item max => $num

Implies C<< num => 1 >>. Require the input to be smaller than or equal to
C<$num>.

=item range => [$min,$max]

Equivalent to C<< min => $min, max => $max >>.

=item ascii => 1

Implies C<< type => 'scalar' >>. Require the input to wholly consist of
printable ASCII characters.

=item sl => 1

Implies C<< type => 'scalar' >>. Require the input to be a single line of text.
Useful for validating C<< <input type="text"> >> form elements, which really
should not result in multi-line input.

=item ipv4 => 1

Implies C<< type => 'scalar' >>. Require the input to be an IPv4 address.

=item ipv6 => 1

Implies C<< type => 'scalar' >>. Require the input to be an IPv6 address. Note
that the IP address is not normalized, and fancy features such as
IPv4-manned-IPv6 addresses are not permitted.

=item ip => 1

Require either C<< ipv4 => 1 >> or C<< ipv6 => 1 >>.

=item email => 1

Implies C<< type => 'scalar' >>. Validate the email address against a
monstrosity of a regular expression. This email validation is designed to catch
obviously invalid addresses and addresses that, while compliant with some RFCs,
will not be accepted by most actual SMTP implementations.

Email validation is quite a minefield, see L<Data::Validate::Email> for an
alternative solution.

=item weburl => 1

Implies C<< type => 'scalar' >>. Requires the input to be a C<http://> or
C<https://> url.

=item date => 1

Implies C<< type => 'scalar' >>. Requires the input to be a date string in the
form of C<YYYY-MM-DD>. Does not validate that the day number is valid for the
given the year and month.

=back


=head1 Custom validations

Custom validations can be passed to C<compile()> as the C<$validations> hashref
argument.  A custom validation is, in simple terms, either a schema or a
subroutine that returns a schema.  The custom validation can then be referenced
from other schemas.

Here's a simple example that defines and uses a custom validation named
I<stringbool>, which accepts either the string I<true> or I<false>.

  my $validations = {
      stringbool => { enum => ['true', 'false'] }
  };
  my $schema = { stringbool => 1 };
  my $result = FU::Validate->compile($schema, $validations)->validate('true');
  # $result eq 'true'

A custom validation can also be defined as a subroutine, in which case it can
accept options. Here is an example of a I<prefix> custom validation, which
requires that the string starts with the given prefix. The subroutine returns a
schema that contains the I<func> built-in option to do the actual validation.

  my $validations = {
      prefix => sub($prefix) {
          return { func => sub { $_[0] =~ /^\Q$prefix/ } }
      }
  };
  my $schema = { prefix => 'Hello, ' };
  my $result = FU::Validate->compile($schema, $validations)->validate('Hello, World!');

=head2 Custom validations and built-in options

Custom validations can also set built-in options, but the semantics differ a
little depending on the option. First, be aware that many of the built-in
options apply to the whole schema and not just to the custom validation.  For
example, if the top-level schema sets C<< trim => 0 >>, then all validations
used in that schema may get input with whitespace around it.

All validations used in a schema need to agree upon a single I<type> option.
If a custom validation does not specify a I<type> option (and no type is
implied by another validation such as I<keys> or I<elems>), then the
validation should work with every type. It is an error to define a schema that
mixes validations of different types. For example, the following throws an
error:

  FU::Validate->compile({
      # top-level schema says we expect a hash
      type => 'hash',
      # but the 'int' validation implies that the type is a scalar
      int => 1
  });

The I<func> option is validated separately for each custom validation.

Multiple I<keys>, I<values> and I<elems> validations are merged into a single
validation.  So if you have multiple custom validations that set the I<elems>
option, a single combined schema is created that validates all array elements.
The same applies to I<keys>: if the same key is listed in multiple custom
validations, then the key must conform to all schemas. With respect to the
I<unknown> option, a key that is mentioned in any of the I<keys> options is
considered "known".

All other built-in options follow inheritance semantics: These options can be
set in a custom validation, and they are inherited by the top-level schema.  If
the same option is set in multiple validations, the final one will be
inherited. The top-level schema can always override options set by custom
validations.


=head2 Global custom validations

Instead of passing a C<$validations> argument every time you call C<compile()>,
you can also add custom validations to the global list of built-in validations:

  $FU::Validate::default_validations{stringbool} = { enum => ['true', 'false'] };


=head1 SEE ALSO

L<FU>.

This module is a fork of L<TUWF::Validate>.

=head1 COPYRIGHT

MIT.

=head1 AUTHOR

Yorhel <projects@yorhel.nl>
