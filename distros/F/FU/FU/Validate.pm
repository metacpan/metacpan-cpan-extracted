package FU::Validate 0.2;

use v5.36;
use experimental 'builtin', 'for_list';
use builtin qw/true false blessed/;
use Carp 'confess';
use FU::Util 'to_bool';


# Unavailable as custom validation names
my %builtin = map +($_,1), qw/
    type
    default
    onerror
    rmwhitespace
    values scalar sort unique
    keys unknown missing
    func
/;

my %type_vals = map +($_,1), qw/scalar hash array any/;
my %unknown_vals = map +($_,1), qw/remove reject pass/;
my %missing_vals = map +($_,1), qw/create reject ignore/;

sub _length($exp, $min, $max) {
    +{ func => sub($v) {
        my $got = ref $v eq 'HASH' ? keys %$v : ref $v eq 'ARRAY' ? @$v : length $v;
        (!defined $min || $got >= $min) && (!defined $max || $got <= $max) ? 1 : { expected => $exp, got => $got };
    }}
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

    bool      => { type => 'any', func => sub { my $r = to_bool $_[0]; return {} if !defined $r; $_[0] = $r; 1 } },
    anybool   => { type => 'any', default => false, func => sub { $_[0] = $_[0] ? true : false; 1 } },

    num   => { _reg $re_num },
    int   => { _reg $re_int }, # implies num
    uint  => { _reg $re_uint }, # implies num
    min   => sub($min) { +{ num => 1, func => sub { $_[0] >= $min ? 1 : { expected => $min, got => $_[0] } } } },
    max   => sub($max) { +{ num => 1, func => sub { $_[0] <= $max ? 1 : { expected => $max, got => $_[0] } } } },
    range => sub { +{ min => $_[0][0], max => $_[0][1] } },

    ascii  => { _reg qr/^[\x20-\x7E]*$/ },
    sl     => { _reg qr/^[^\t\r\n]+$/ },
    ipv4   => { _reg $re_ip4 },
    ipv6   => { _reg $re_ip6 },
    ip     => { _reg $re_ip  },
    email  => { _reg($re_email),  maxlength => 254 },
    weburl => { _reg($re_weburl), maxlength => 65536 }, # the maxlength is a bit arbitrary, but better than unlimited
    date   => { _reg $re_date },
);


# Loads a hashref of validations and a schema definition, and converts it into
# an object with:
#
#   name        => $name_or_undef,
#   validations => [ $recursive_compiled_object, .. ],
#   schema      => $builtin_validations,
#   known_keys  => { $key => 1, .. }  # Extracted from 'keys', Used for the 'unknown' validation
#
sub _compile($schema, $validations, $rec) {
    my(%top, @val);
    my @keys = keys $schema->{keys}->%* if $schema->{keys};

    for my($name, $val) (%$schema) {
        if($builtin{$name}) {
            $top{$name} = $schema->{$name};
            next;
        }

        my $t = $validations->{$name} || $default_validations{$name};
        confess "Unknown validation: $name" if !$t;
        confess "Recursion limit exceeded while resolving validation '$name'" if $rec < 1;
        $t = ref $t eq 'HASH' ? $t : $t->($val);

        my $v = _compile($t, $validations, $rec-1);
        $v->{name} = $name;
        push @val, $v;
    }

    for my ($n,$t) (qw/keys hash unknown hash  values array sort array unique array/) {
        next if !exists $top{$n};
        confess "Incompatible types, the schema specifies '$top{type}' but the '$n' validation implies '$t'" if $top{type} && $top{type} ne $t;
        $top{type} = $t;
    }

    # Inherit some builtin options from validations
    for my $t (@val) {
        if($top{type} && $t->{schema}{type} && $top{type} ne $t->{schema}{type}) {
            confess "Incompatible types, the schema specifies '$top{type}' but validation '$t->{name}' requires '$t->{schema}{type}'" if $schema->{type};
            confess "Incompatible types, '$t->[0]' requires '$t->{schema}{type}', but another validation requires '$top{type}'";
        }
        exists $t->{schema}{$_} and !exists $top{$_} and $top{$_} = delete $t->{schema}{$_}
            for qw/default onerror rmwhitespace type scalar unknown missing sort unique/;

        push @keys, keys %{ delete $t->{known_keys} };
        push @keys, keys %{ $t->{schema}{keys} } if $t->{schema}{keys};
    }

    # Compile sub-schemas
    $top{keys} = { map +($_, __PACKAGE__->compile($top{keys}{$_}, $validations)), keys $top{keys}->%* } if $top{keys};
    $top{values} = __PACKAGE__->compile($top{values}, $validations) if $top{values};

    return {
        validations => \@val,
        schema      => \%top,
        known_keys  => { map +($_,1), @keys },
    };
}


sub compile($pkg, $schema, $validations={}) {
    return $schema if $schema isa __PACKAGE__;

    my $c = _compile $schema, $validations, 64;

    $c->{schema}{type} //= 'scalar';
    $c->{schema}{missing} //= 'create';
    $c->{schema}{rmwhitespace} //= 1 if $c->{schema}{type} eq 'scalar';
    $c->{schema}{unknown} //= 'remove' if $c->{schema}{type} eq 'hash';

    confess "Invalid value for 'type': $c->{schema}{type}" if !$type_vals{$c->{schema}{type}};
    confess "Invalid value for 'missing': $c->{schema}{missing}" if !$missing_vals{$c->{schema}{missing}};
    confess "Invalid value for 'unknown': $c->{schema}{unknown}" if exists $c->{schema}{unknown} && !$unknown_vals{$c->{schema}{unknown}};

    delete $c->{schema}{default} if ref $c->{schema}{default} eq 'SCALAR' && ${$c->{schema}{default}} eq 'required';

    if(exists $c->{schema}{sort}) {
        my $s = $c->{schema}{sort};
        $c->{schema}{sort} =
            ref $s eq 'CODE' ? $s
            :    $s eq 'str' ? sub($x,$y) { $x cmp $y }
            :    $s eq 'num' ? sub($x,$y) { $x <=> $y }
            : confess "Unknown value for 'sort': $c->{schema}{sort}";
    }
    $c->{schema}{unique} = sub { $_[0] } if $c->{schema}{unique} && !ref $c->{schema}{unique} && !$c->{schema}{sort};

    bless $c, $pkg;
}


sub _validate_rec($c, $input) {
    # hash keys
    if($c->{schema}{keys}) {
        my @err;
        for my ($k, $s) ($c->{schema}{keys}->%*) {
            if(!exists $input->{$k}) {
                next if $s->{schema}{missing} eq 'ignore';
                return [$input, { validation => 'missing', key => $k }] if $s->{schema}{missing} eq 'reject';
                $input->{$k} = ref $s->{schema}{default} eq 'CODE' ? $s->{schema}{default}->() : $s->{schema}{default} // undef;
                next if exists $s->{schema}{default};
            }

            my $r = _validate($s, $input->{$k});
            $input->{$k} = $r->[0];
            if($r->[1]) {
                $r->[1]{key} = $k;
                push @err, $r->[1];
            }
        }
        return [$input, { validation => 'keys', errors => \@err }] if @err;
    }

    # array values
    if($c->{schema}{values}) {
        my @err;
        for my $i (0..$#$input) {
            my $r = _validate($c->{schema}{values}, $input->[$i]);
            $input->[$i] = $r->[0];
            if($r->[1]) {
                $r->[1]{index} = $i;
                push @err, $r->[1];
            }
        }
        return [$input, { validation => 'values', errors => \@err }] if @err;
    }

    # validations
    for ($c->{validations}->@*) {
        my $r = _validate_rec($_, $input);
        $input = $r->[0];

        return [$input, {
            # If the error was a custom 'func' object, then make that the primary cause.
            # This makes it possible for validations to provide their own error objects.
            $r->[1]{validation} eq 'func' && (!exists $r->[1]{result} || keys $r->[1]->%* > 2) ? $r->[1]->%* : (error => $r->[1]),
            validation => $_->{name},
        }] if $r->[1];
    }

    # func
    if($c->{schema}{func}) {
        my $r = $c->{schema}{func}->($input);
        return [$input, { %$r, validation => 'func' }] if ref $r eq 'HASH';
        return [$input, { validation => 'func', result => $r }] if !$r;
    }

    return [$input]
}


sub _validate_array($c, $input) {
    return [$input] if $c->{schema}{type} ne 'array';

    $input = [sort { $c->{schema}{sort}->($a, $b) } @$input ] if $c->{schema}{sort};

    # Key-based uniqueness
    if($c->{schema}{unique} && ref $c->{schema}{unique} eq 'CODE') {
        my %h;
        for my $i (0..$#$input) {
            my $k = $c->{schema}{unique}->($input->[$i]);
            return [$input, { validation => 'unique', index_a => $h{$k}, value_a => $input->[$h{$k}], index_b => $i, value_b => $input->[$i], key => $k }] if exists $h{$k};
            $h{$k} = $i;
        }

    # Comparison-based uniqueness
    } elsif($c->{schema}{unique}) {
        for my $i (0..$#$input-1) {
            return [$input, { validation => 'unique', index_a => $i, value_a => $input->[$i], index_b => $i+1, value_b => $input->[$i+1] }]
                if $c->{schema}{sort}->($input->[$i], $input->[$i+1]) == 0
        }
    }

    return [$input]
}


sub _validate_input($c, $input) {
    # rmwhitespace (needs to be done before the 'default' test)
    if(defined $input && !ref $input && $c->{schema}{type} eq 'scalar' && $c->{schema}{rmwhitespace}) {
        $input =~ s/\r//g;
        $input =~ s/^\s*//;
        $input =~ s/\s*$//;
    }

    # default
    if(!defined $input || (!ref $input && $input eq '')) {
        return [ref $c->{schema}{default} eq 'CODE' ? $c->{schema}{default}->($input) : $c->{schema}{default}] if exists $c->{schema}{default};
        return [$input, { validation => 'required' }];
    }

    if($c->{schema}{type} eq 'scalar') {
        return [$input, { validation => 'type', expected => 'scalar', got => lc ref $input }] if ref $input;

    } elsif($c->{schema}{type} eq 'hash') {
        return [$input, { validation => 'type', expected => 'hash', got => lc ref $input || 'scalar' }] if ref $input ne 'HASH';

        # Each branch below makes a shallow copy of the hash, so that further
        # validations can perform in-place modifications without affecting the
        # input.
        if($c->{schema}{unknown} eq 'remove') {
            $input = { map +($_, $input->{$_}), grep $c->{known_keys}{$_}, keys %$input };
        } elsif($c->{schema}{unknown} eq 'reject') {
            my @err = grep !$c->{known_keys}{$_}, keys %$input;
            return [$input, { validation => 'unknown', keys => \@err, expected => [ sort keys %{$c->{known_keys}} ] }] if @err;
            $input = { %$input };
        } else {
            $input = { %$input };
        }

    } elsif($c->{schema}{type} eq 'array') {
        $input = [$input] if $c->{schema}{scalar} && !ref $input;
        return [$input, { validation => 'type', expected => $c->{schema}{scalar} ? 'array or scalar' : 'array', got => lc ref $input || 'scalar' }] if ref $input ne 'ARRAY';
        $input = [@$input]; # Create a shallow copy to prevent in-place modification.

    } elsif($c->{schema}{type} eq 'any') {
        # No need to do anything here.

    } else {
        confess "Unknown type '$c->{schema}{type}'"; # Already checked in compile(), but be extra safe
    }

    my $r = _validate_rec($c, $input);
    return $r if $r->[1];
    $input = $r->[0];

    _validate_array($c, $input);
}


sub _validate($c, $input) {
    my $r = _validate_input($c, $input);
    return $r if !$r->[1] || !exists $c->{schema}{onerror};
    [ ref $c->{schema}{onerror} eq 'CODE' ? $c->{schema}{onerror}->(bless $r, 'FU::Validate::Result') : $c->{schema}{onerror} ]
}


sub validate($c, $input) {
    bless _validate($c, $input), 'FU::Validate::Result';
}




package FU::Validate::Result;

use v5.36;
use Carp 'confess';

# A result object contains: [$data, $error]

# In boolean context, returns whether the validation succeeded.
use overload bool => sub { !$_[0][1] };

# Returns the validation errors, or undef if validation succeeded
sub err { $_[0][1] }

# Returns the validated and normalized input, dies if validation didn't succeed.
sub data {
    if($_[0][1]) {
        require Data::Dumper;
        my $s = Data::Dumper->new([$_[0][1]])->Terse(1)->Pair(':')->Indent(0)->Sortkeys(1)->Dump;
        confess "Validation failed: $s";
    }
    $_[0][0]
}

# Same as 'data', but returns partially validated and normalized data if validation failed.
sub unsafe_data { $_[0][0] }

# TODO: Human-readable error message formatting

1;
__END__

=head1 NAME

FU::Validate - Data and form validation and normalization

=head1 EXPERIMENTAL

This module is still in development and there will likely be a few breaking API
changes, see the main L<FU> module for details.

=head1 DESCRIPTION

This module provides an easy and simple interface for data validation. It can
handle most types of data structures (scalars, hashes, arrays and nested data
structures), and has some conveniences for validating form-like data.

That this module will not solve B<all> your input validation problems. It can
validate the format and the structure of the data, but it does not support
validations that depend on other input values. For example, it is not possible
to specify that the contents of a I<password> field must be equivalent to that
of a I<confirm_password> field, but you can specify that both fields need to be
filled out. Recursive data structures are not supported. There is also no
built-in support for validating hashes with dynamic keys or arrays where not
all elements conform to the same schema. These could technically still be
validated with custom validations, but it won't be as convenient.

This module is designed to validate any kind of program input after it has been
parsed into a Perl data structure. It should not be used to validate function
parameters within Perl code. In fact, the correct answer to "how do I validate
function parameters?" is "don't, document your assumptions instead".


=head2 Validation API

To validate some input, you first need a schema. A schema can be compiled as
follows:

  my $validator = FU::Validate->compile($schema, $validations);

C<$schema> is the schema that describes the data to be validated (see L</SCHEMA
DEFINITION> below) and C<$validations> is an optional hashref containing
L<custom validations|/Custom validations> that C<$schema> can refer to.

To validate input, run:

  my $result = $validator->validate($input);

C<$input> is the data to be validated, and the C<$result> object is L<described
below|/Result object>.

Both C<compile()> and C<validate()> may throw an error if the C<$validations>
or C<$schema> are invalid. Errors in the C<$input> should never cause an error
to be thrown, since these are always reported in the C<$result> object.

This module takes great care that C<$input> is not being modified in place,
even if data normalization is being performed. The normalized data can be read
from the C<$result> object.

=head2 Result object

The C<$result> object returned by C<validate()> overloads boolean context, so
you can check if the validation succeeded with a simple if statement:

  my $result = $validator->validate(..);
  if($result) {
    # Success!
    my $data = $result->data;
  } else {
    # Input failed to validate...
    my $error = $result->err;
  }

In addition, the result object implements the following methods:

=over

=item data()

Returns the validated and normalized data. This method throws an error if
validation failed, so if you're lazy and don't want to bother too much with
proper error reporting, you can safely I<validate-and-die> in a single step:

  my $validated_data = $v->validate(..)->data;

(Note regarding reference semantics: The returned data will usually be a
(possibly modified) copy of C<$input>, but may in some cases still have nested
references to data in C<$input> - so if you are working with nested hashrefs,
arrayrefs or other objects and are going to make modifications to the values
embedded within them, these changes may or may not also affect the values in
the original C<$input>. Make a deep copy of the data if you're concerned about
this).

=item err()

Returns I<undef> if validation succeeded, an error object otherwise.

An error object is a hashref containing at least one key: I<validation>, which
indicates the name of the validation that failed. Additional keys with more
detailed information may be present, depending on the validation. These are
documented in L</SCHEMA DEFINITION> below.

=back


=head1 SCHEMA DEFINITION

A schema is a hashref, each key is the name of a built-in option or of a
validation to be performed. None of the options or validations are required,
but some built-ins have default values. This means that the empty schema C<{}>
is actually equivalent to:

  { type         => 'scalar',
    rmwhitespace => 1,
    default      => \'required',
    missing      => 'create',
  }

=head2 Built-in options

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

The empty check is performed after I<rmwhitespace> and before any other
validations. So a string containing only whitespace is considered an empty
string and will be treated according to this I<default> option. As an
additional side effect, other validations will never get to validate undef or
an empty string, as these values are either rejected or substituted with a
default.

=item onerror => $val

Instead of reporting an error, return C<$val> if this input fails validation
for whatever reason. Setting this option in the top-level schema ensures that
the validation will always succeed regardless of the input.

If C<$val> is a CODE reference, the subroutine is called with the result object
for this validation as its first argument. The return value of the subroutine
is then returned for this validation.

=item rmwhitespace => 0/1

By default, any whitespace around scalar-type input is removed before testing
any other validations. Setting I<rmwhitespace> to a false value will disable
this behavior.

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

=item unknown => $option

Implies C<< type => 'hash' >>, this option specifies what to do with keys in
the input data that have not been defined in the I<keys> option. Possible
values are I<remove> to remove unknown keys from the output data (this is the
default), I<reject> to return an error if there are unknown keys in the input,
or I<pass> to pass through any unknown keys to the output data. Note that the
values for passed-through keys are not validated against any schema!

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
that is effectively the same as I<reject>.

In the case of I<reject>, the error object will look like:

  { validation => 'missing',
    key        => 'field'
  }

=item values => $schema

Implies C<< type => 'array' >>, this defines the schema that is applied to
every item in the array.  The schema definition may be a bare hashref or a
validator returned by C<compile()>.

Failure is reported in a similar fashion to I<keys>:

  { validation => 'values',
    errors => [
      { index => 1, validation => 'required' }
    ]
  }

=item scalar => 0/1

Implies C<< type => 'array' >>, this option will also permit the input to be a
scalar. In this case, the input is interpreted and returned as an array with
only one element. This option exists to make it easy to validate multi-value
form inputs. For example, consider C<query_decode()> in L<FU::Util>: a
parameter in a query string is decoded into an array if it is listed multiple
times, a scalar if it only occcurs once. So we could either end up with:

  { a => 1, b => 1 }
  # OR:
  { a => [1, 3], b => 1 }

With the I<scalar> option, we can accept both forms for C<a> and normalize into
an array. The following schema definition can validate the above examples:

  { type => 'hash',
    keys => {
      a => { type => 'array', scalar => 1 },
      b => { }
    }
  }

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
  { values => {
      type => 'hash',
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
  { values => { minlength => 1 },
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
normalization. The subroutine is only called after all other validations have
succeeded. The subroutine is called with the input as its only argument.
Normalization of the input can be done by assigning to the first argument or
modifying its value in-place.

On success, the subroutine should return a true value. On failure, it should
return either a false value or a hashref. The hashref will have the
I<validation> key set to I<func>, and this will be returned as error object.

When I<func> is used inside a custom validation, the returned error object will
have its I<validation> field set to the name of the custom validation. This
makes custom validations to behave as first-class validations in terms of error
reporting.


=back

=head2 Standard validations

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
not permitted.

=item int => 1

Implies C<< type => 'scalar' >>. Require the input to be an (arbitrarily large)
integer.

=item uint => 1

Implies C<< type => 'scalar' >>. Require the input to be an (arbitrarily large)
positive integer.

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


=head2 Custom validations

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
  # $result->data() eq 'true'

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

=head3 Custom validations and built-in options

Custom validations can also set built-in options, but the semantics differ a
little depending on the option. First, be aware that many of the built-in
options apply to the whole schema and not just to the custom validation.  For
example, if the top-level schema sets C<< rmwhitespace => 0 >>, then all
validations used in that schema may get input with whitespace around it.

All validations used in a schema need to agree upon a single I<type> option.
If a custom validation does not specify a I<type> option (and no type is
implied by another validation such as I<keys> or I<values>), then the
validation should work with every type. It is an error to define a schema that
mixes validations of different types. For example, the following throws an
error:

  FU::Validate->compile({
    # top-level schema says we expect a hash
    type => 'hash',
    # but the 'int' validation implies that the type is a scalar
    int => 1
  });

The I<keys>, I<values> and C<func> built-in options are validated separately
for each custom validation. So if you have multiple custom validations that set
the I<values> option, then the array elements must validate all the listed
schemas. The same applies to I<keys>: If the same key is listed in multiple
custom validations, then the key must conform to all schemas. With respect to
the I<unknown> option, a key that is mentioned in any of the I<keys> options is
considered "known".

All other built-in options follow inheritance semantics: These options can be
set in a custom validation, and they are inherited by the top-level schema.  If
the same option is set in multiple validations a random one will be inherited,
so that's not a good idea. The top-level schema can always override options set
by custom validations.


=head3 Global custom validations

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
