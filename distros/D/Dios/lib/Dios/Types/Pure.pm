package Dios::Types::Pure;
our $VERSION = '0.000001';

use 5.014; use warnings;
use Carp;
use Scalar::Util qw< reftype blessed looks_like_number openhandle >;
use overload;
use Sub::Uplevel;

$Carp::CarpInternal{'Dios::Types::Pure'}=1;


my %exportable = ( validate => 1, validator_for => 1 );
sub import {

    # Throw away the package name...
    shift @_;

    # Cycle through each SUB => AS pair...
    while (my ($exported, $export_as) = splice(@_, 0, 2)) {
        # If it's not a rename, don't change the name...
        if ($export_as && $exportable{$export_as}) {
            unshift @_, $export_as;
            undef $export_as;
        }

        # If it's not exported, don't export it...
        croak "Can't export $exported" if !$exportable{$exported};

        # Unrenamed exports are exported under their own names...
        $export_as //= $exported;

        # Do the export...
        no strict 'refs';
        *{caller.'::'.$export_as} = \&{$exported};
    }


}

my @user_defined_type;


sub _error_near ($$;$) {
    my ($where, $what, $previous_errors) = @_;

    { package Dios::Types::Pure::Error;
      use overload 'bool' => sub{0}, fallback => 1;
      sub msg {
        my $self = shift;
        return $self->[0] ne $self->[-1] ? "$self->[-1]\n(because $self->[0])" : $self->[0];
      }
    }

    $previous_errors = bless [], 'Dios::Types::Pure::Error' if (reftype($previous_errors)//q{}) ne 'ARRAY';
    push @{$previous_errors}, _perl($where) . " isn't of type $what";

    return $previous_errors;
}

# Standard type checking...
my %handler_for = (
    # Any Perl value or ref...
    Slurpy     => sub { 1 },
    Any        => sub { 1 },

    # Anything that is true or false (and that's everything in Perl!)
    Bool       => sub { 1 },

    # Anything defined, or not...
    Def        => sub {  defined $_[0] },
    Undef      => sub { !defined $_[0] },
    Void       => sub { !defined $_[0] || ref $_[0] eq 'ARRAY' && !@{$_[0]} },

    # Values, references, and filehandles...
    Value      => sub { defined($_[0]) && !ref($_[0]) },
    Ref        => sub { ref $_[0] },
    IO         => \&openhandle,
    Glob       => sub { ref($_[0]) eq 'GLOB' },

    # An integer...
    Int => sub {
        # If it's an object, must have a warning-less numeric overloading...
        if (ref($_[0])) {
            # Normal references aren't integers...
            return 0 if !blessed($_[0]);

            # Is there an overloading???
            my $converter = overload::Method($_[0],'0+')
                or return 0;

            # Does this object convert to a number without complaint???
            my $warned;
            local $SIG{__WARN__} = sub { $warned = 1 };
            my $value = eval{ $converter->($_[0]) }
                // return 0;
            return 0 if $warned;
            return $value =~ m{\A \s*+ [+-]?+ (?: \d++ (\.0*+)?+ | inf(?:inity)?+ ) \s*+ \Z}ixms;
        }

        # Value must be defined, non-reference, looks like an integer...
        return defined($_[0])
            && $_[0] =~ m{\A \s*+ [+-]?+ (?: \d++ (\.0*+)?+ | inf(?:inity)?+ ) \s*+ \Z}ixms;
    },

    # A number
    Num => sub {
        return 0 if !defined $_[0] || lc($_[0]) eq 'nan';
        &looks_like_number
    },

    # A string, or stringifiable object, or array ref, or hash ref, that is empty...
    Empty => sub {
        my $value = shift;

        # Must be defined...
        return 0 if !defined($value);

        # May be an empty array or hash...
        my $reftype = ref($value);
        return 1 if $reftype eq 'ARRAY' && !@{$value};
        return 1 if $reftype eq 'HASH'  && !keys %{$value};

        # May be an object that overloads stringification...
        return 1 if $reftype && overload::Method($value, q{""}) && "$value" eq q{};

        # Otherwise, has to be an empty string...
        return $value eq q{};
    },

    # A string, or stringifiable object...
    Str => sub { defined($_[0]) && (ref($_[0]) ? overload::Method(shift,q{""}) : 1) },

    # A blessed object...
    Obj   => \&blessed,

    # Any loaded class (must have @ISA or $VERSION or at least one method defined)...
    Class => sub {
        return 0 if ref $_[0] || not $_[0];
        my $stash = \%main::;
        for my $partial_name (split /::/, $_[0]) {
            return 0 if !exists $stash->{$partial_name.'::'};
            $stash = $stash->{$partial_name.'::'};
        }
        return 1 if exists $stash->{'ISA'};
        return 1 if exists $stash->{'VERSION'};
        for my $globref (values %$stash) {
            return 1 if *{$globref}{CODE};
        }
        return 0;
    },
);

# Built-in type checking...
for my $type (qw< SCALAR ARRAY HASH CODE GLOB >) {
    $handler_for{ ucfirst(lc($type)) } = sub { (reftype($_[0]) // q{}) eq $type };
}
$handler_for{ Regex } = sub { (reftype($_[0]) // q{}) eq 'REGEXP' };
$handler_for{ List  } = $handler_for{ Array };

# Standard type hierrachy...
my %BASIC_NARROWER = (
    Slurpy                           => {                                                               },
        Any                          => { map {$_=>1} qw< Slurpy                                       >},
            Bool                     => { map {$_=>1} qw< Slurpy Any                                   >},
                Undef                => { map {$_=>1} qw< Slurpy Any Bool                              >},
                Def                  => { map {$_=>1} qw< Slurpy Any Bool                              >},
                    Value            => { map {$_=>1} qw< Slurpy Any Bool Def                          >},
                        Num          => { map {$_=>1} qw< Slurpy Any Bool Def Value Str                >},
                            Int      => { map {$_=>1} qw< Slurpy Any Bool Def Value Str Num            >},
                        Str          => { map {$_=>1} qw< Slurpy Any Bool Def Value                    >},
                            Class    => { map {$_=>1} qw< Slurpy Any Bool Def Value Str                >},
                            Empty    => { map {$_=>1} qw< Slurpy Any Bool Def Value Str Ref Array List Hash >},
                    Ref              => { map {$_=>1} qw< Slurpy Any Bool Def                          >},
                        Scalar       => { map {$_=>1} qw< Slurpy Any Bool Def Ref                      >},
                        Regex        => { map {$_=>1} qw< Slurpy Any Bool Def Ref                      >},
                        Code         => { map {$_=>1} qw< Slurpy Any Bool Def Ref                      >},
                        Glob         => { map {$_=>1} qw< Slurpy Any Bool Def Ref                      >},
                        IO           => { map {$_=>1} qw< Slurpy Any Bool Def Ref                      >},
                        Obj          => { map {$_=>1} qw< Slurpy Any Bool Def Ref                      >},
                        Array        => { map {$_=>1} qw< Slurpy Any Bool Def Ref                      >},
                            List     => { map {$_=>1} qw< Slurpy Any Bool Def Ref Array                >},
                            Empty    => { map {$_=>1} qw< Slurpy Any Bool Def Value Str Ref Array Hash List >},
                        Hash         => { map {$_=>1} qw< Slurpy Any Bool Def Ref                      >},
                            Empty    => { map {$_=>1} qw< Slurpy Any Bool Def Value Str Ref Array Hash List >},
);

# This is the full typename syntax...
my $BASIC_TYPES = join('|', keys %handler_for);

my $TYPED_OR_PURE_ETC = qr{ \s*+ ,? \s*+ \.\.\.}xms;
my $TYPED_ETC         = qr{         \s*+ \.\.\.}xms;
my $PURE_ETC          = qr{ \s*+ ,  \s*+ \.\.\.}xms;

my $KEYED_TYPENAME = q{
    \\s*
    (?: ' (?<key> [^'\\\\]*+ (?: \\\\. [^'\\\\]*+ )*+ ) '
      |   (?<key> (?&IDENT)                           )
    )
    (?<optional> \\s* [?] )?
    (?: \\s* => \\s* (?<valtype> (?&CONJ_TYPENAME) )  )?
};

my $TYPENAME_GRAMMAR = qr{

    (?<ATOM_TYPENAME>
                  (?<user>        (?&QUAL_IDENT)              )
    |   Is    \[  (?<disj>   \s*+ (?&DISJ_TYPENAME_BAR)  \s*+ )  \]
    |   Is    \[  (?<conj>   \s*+ (?&CONJ_TYPENAME)      \s*+ )  \]
    |   Not   \[  (?<not>    \s*+ (?&DISJ_TYPENAME)      \s*+ )  \]
    |   List  \[  (?<list>   \s*+ (?&DISJ_TYPENAME)      \s*+ )  \]
    |   Array \[  (?<array>  \s*+ (?&DISJ_TYPENAME)      \s*+ )  \]
    |   Tuple \[  (?<tuple>  \s*+ (?&TUPLE_FORMAT)       \s*+ )  \]
    |   Hash  \[  (?<hash>   \s*+ (?&DISJ_TYPENAME) (?: \s*+ => \s*+ (?&DISJ_TYPENAME) )?+ \s*+ )  \]
    |   Dict  \[  (?<dict>   \s*+ (?&DICT_FORMAT)        \s*+ )  \]
    |   Ref   \[  (?<ref>    \s*+ (?&DISJ_TYPENAME)      \s*+ )  \]
    |   Eq    \[  (?<eq>     \s*+ (?&STR_SPEC)           \s*+ )  \]
    |   Match \[  (?<match>  \s*+ (?&REGEX_SPEC)         \s*+ )  \]
    |   Can   \[  (?<can>    \s*+ (?&OPT_QUAL_IDENT) \s*+ (?: , \s*+ (?&OPT_QUAL_IDENT) \s*+ )*+ ) \]
    |   Overloads \[  (?<overloads>  [^]]++ )  \]
    |             (?<basic>       (?&BASIC)                )
    |             (?<user>        (?!(?&BASIC)) (?&IDENT) (?: \s*+ \[ \s*+ (?&TYPE_LIST) \s*+ \] )?+  )
    )

    (?(DEFINE)

        (?<DISJ_TYPENAME_BAR> (?&CONJ_TYPENAME) (?: \s* [|] \s* (?&CONJ_TYPENAME) )++ )
        (?<DISJ_TYPENAME>     (?&CONJ_TYPENAME) (?: \s* [|] \s* (?&CONJ_TYPENAME) )*+ )
        (?<CONJ_TYPENAME>     (?&ATOM_TYPENAME) (?: \s* [&] \s* (?&ATOM_TYPENAME) )*+ )

        (?<NON_ATOM_TYPENAME>
                          (?&CONJ_TYPENAME) (?: \s* [|] \s* (?&CONJ_TYPENAME) )++
                        | (?&ATOM_TYPENAME) (?: \s* [&] \s* (?&ATOM_TYPENAME) )++
        )

        (?<TUPLE_FORMAT>
            (?&TYPE_LIST) (?: \s*+ ,? \s*+ \.\.\. )?
        )

        (?<TYPE_LIST>
            (?&CONJ_TYPENAME) (?: \s*,\s* (?&CONJ_TYPENAME) )*+
        )

        (?<DICT_FORMAT>
            (?&KEYED_TYPENAME) (?: \s*,\s* (?&KEYED_TYPENAME) )*+  $PURE_ETC?
        )

        (?<KEYED_TYPENAME>
            $KEYED_TYPENAME
        )

        (?<STR_SPEC>   (?: [^][\\]++ |  \\[][\\] )*+ )

        (?<REGEX_SPEC> (?: [^][\\]++ |  \\\S  |  \[ \^? \]? [^]]*+ \] )*+ )

        (?<BASIC> \b (?: $BASIC_TYPES ) \b )

        (?<QUAL_IDENT>     (?&IDENT) (?: :: (?&IDENT) )++ )

        (?<OPT_QUAL_IDENT> (?&IDENT) (?: :: (?&IDENT) )*+ )

        (?<IDENT> [^\W\d] \w*+ )
    )
}xms;

my $FROM_TYPENAME_GRAMMAR = qr{ (?(DEFINE) $TYPENAME_GRAMMAR ) }xms;

my $IS_REF_TYPE
    = qr/\A (?: List | Array | Hash | Code | Scalar | Regex | Tuple | Dict | Glob | IO | Obj ) \b/x;

# Complex types are built on the fly...
sub _build_handler_for {
    my ($type, $context, $level) = @_;

    # Reformat conjunctions and disjunctions to avoid left recursion...
    if ($type =~ m{\A \s*+ ((?&NON_ATOM_TYPENAME)) \s*+ \Z  $FROM_TYPENAME_GRAMMAR }xms) {
        $type = "Is[$1]";
    }

    # Parse the type specification...
    $type =~ m{\A \s*+ $TYPENAME_GRAMMAR \s*+ \Z }xms
        or croak "Incomprehensible type name: $type\n",
                 (defined $context ? $context : q{});

    my %type_is = %+;

    # Conjunction handlers test each component type and fail if any fails...
    if ( exists $type_is{conj}  ) { my @types = grep {defined} $type_is{conj} =~ m{ ((?&ATOM_TYPENAME))
                                                                                      $FROM_TYPENAME_GRAMMAR
                                                                                  }gxms;
                                        my @handlers = map {_build_handler_for($_)} @types;
                                        return sub {
                                            for (@handlers) {
                                                my $okay = $_->($_[0]);
                                                return _error_near($_[0], join(' or ', @types), $okay)
                                                    if !$okay;
                                            }
                                            return 1;
                                        }
                                  }

    # Disjunction handlers test each component type and fail if all of them fail...
    if ( exists $type_is{disj}  ) { my @types = grep {defined} $type_is{disj} =~ m{ ((?&CONJ_TYPENAME))
                                                                                      $FROM_TYPENAME_GRAMMAR
                                                                                  }gxms;
                                    my @handlers = map {_build_handler_for($_)} @types;
                                    return sub {
                                        for (@handlers) {
                                            return 1 if $_->($_[0]);
                                        }
                                        return _error_near($_[0], join(' or ', @types));
                                    }
                                  }

    # Basic types, just use the built-in handler...
    if ( exists $type_is{basic} ) { return $handler_for{$type_is{basic}}; }

    # User defined types match an object of that type...
    if ( exists $type_is{user}  ) { my $typename = $type_is{user};
                                    my $root_name = $typename =~ s{\[.*}{}rxms;
                                    my $idx = $Dios::Types::Pure::lexical_hints->{"Dios::Types::Pure subtype=$root_name"};
                                    return sub {
                                        # Is it user-defined???
                                        if (defined $idx) {
                                            for ($_[0]) {
                                                return $user_defined_type[$idx]($typename)($_)
                                                    || _error_near($_[0], $typename);
                                            }
                                        }

                                        return blessed($_[0]) && $_[0]->isa($typename)
                                            || _error_near($_[0], $typename);
                                    }
                                  }

    # Array[T] types require an array ref, whose every element is of type T...
    if ( exists $type_is{array} ) { my $value_handler = _build_handler_for($type_is{array});
                                    return sub {
                                        return _error_near($_[0], "Array[$type_is{array}]")
                                            if (reftype($_[0]) // q{}) ne 'ARRAY';

                                        for (@{$_[0]}) {
                                            next if my $okay = $value_handler->($_);
                                            return _error_near($_, $type_is{array}, $okay);
                                        }

                                        return 1;
                                    }
                                  }

    # List[T] types require an array ref, whose every element is of type T...
    if ( exists $type_is{list} ) { my $value_handler = _build_handler_for($type_is{list});
                                    return sub {
                                        return _error_near($_[0], "List[$type_is{list}]")
                                            if (reftype($_[0]) // q{}) ne 'ARRAY';

                                        for (@{$_[0]}) {
                                            next if my $okay = $value_handler->($_);
                                            return _error_near($_, $type_is{list}, $okay);
                                        }

                                        return 1;
                                    }
                                  }

    if ( exists $type_is{tuple} ) { my @types
                                        = grep {defined}
                                               $type_is{tuple} =~ m{ ((?&CONJ_TYPENAME) | $TYPED_OR_PURE_ETC )
                                                                        $FROM_TYPENAME_GRAMMAR
                                                                   }gxms;
                                    # Build type handlers for sequence...
                                    my ($final_any, $final_handler);
                                    if (@types > 1 && $types[-1] =~ /^$TYPED_ETC$/) {
                                        pop @types;
                                        $final_handler = _build_handler_for(pop @types);
                                    }
                                    elsif (@types > 0 && $types[-1] =~ /^$PURE_ETC$/) {
                                        pop @types;
                                        $final_any = 1;
                                        $final_handler = _build_handler_for('Any');
                                    }
                                    my @value_handlers = map {_build_handler_for($_)} @types;

                                    return sub {
                                        my $array_ref = shift;
                                        # Tuples must be array refs the same length as their specifications...
                                        return _error_near($array_ref, "Dict[$type_is{tuple}]")
                                            if (reftype($array_ref) // q{}) ne 'ARRAY'
                                            || !$final_handler && @{$array_ref} != @types;

                                        # The first N values must match the N types specified...
                                        for my $n (0..$#types) {
                                            my $okay = $value_handlers[$n]($array_ref->[$n]);
                                            return _error_near($array_ref, "Dict[$type_is{tuple}]", $okay)
                                                if !$okay;
                                        }

                                        # Succeed at once if no etcetera to test, or it etcetera guaranteed...
                                        return 1 if $final_any || @{$array_ref} == @types;

                                        # Any extra values must match the "et cetera" handler specified...
                                        for my $n ($#types+1..$#{$array_ref}) {
                                            my $okay = $final_handler->($array_ref->[$n]);
                                            return _error_near($array_ref, "Dict[$type_is{tuple}]", $okay)
                                                if !$okay;
                                        }

                                        return 1;
                                    }
                                  }

    # Hash[T] types require a hash ref, whose every value is of type T...
    if ( exists $type_is{hash}  ) { my ($type_k, $type_v) = split '=>', $type_is{hash};
                                    # Only value type specified...
                                    if (!defined $type_v) {
                                        my $value_handler = _build_handler_for($type_k);
                                        return sub {
                                            return _error_near($_[0], "Hash[$type_is{hash}]")
                                                if (reftype($_[0]) // q{}) ne 'HASH';

                                            for (values %{$_[0]}) {
                                                my $okay = $value_handler->($_);
                                                return _error_near($_, $type_is{hash}, $okay)
                                                    if !$okay;
                                            }

                                            return 1;
                                        }
                                    }
                                    # Both key and value type specified...
                                    else {
                                        my $key_handler   = _build_handler_for($type_k);
                                        my $value_handler = _build_handler_for($type_v);
                                        return sub {
                                            return _error_near($_[0], "Hash[$type_is{hash}]")
                                                if (reftype($_[0]) // q{}) ne 'HASH';

                                            for (keys %{$_[0]}) {
                                                my $okay = $key_handler->($_);
                                                return _error_near($_, $type_is{hash}, $okay)
                                                    if !$okay;
                                            }

                                            for (values %{$_[0]}) {
                                                my $okay = $value_handler->($_);
                                                return _error_near($_, $type_is{hash}, $okay)
                                                    if !$okay;
                                            }

                                            return 1;
                                        }
                                    }
                                  }

    # Dict[ k => T, k => T, ... ] requires a hash key, with the specified keys type-matched too...
    if ( exists $type_is{dict}  ) { my (%handler_for, @required_keys, $extra_keys_allowed);
                                    while ($type_is{dict} =~ m{ (?<keyed> $KEYED_TYPENAME)|(?<etc> $PURE_ETC)
                                                                    $FROM_TYPENAME_GRAMMAR}gxms
                                    ) {
                                        # Create a type checker for each specified key (once!)...
                                        if (exists $+{keyed}) {
                                            my ($key, $valtype, $optional) = @+{qw< key valtype optional >};
                                            croak qq{Two type specifications for key '$key' },
                                                  qq{in Dict[$type_is{dict}]}
                                                        if exists $handler_for{$key};
                                            $handler_for{$key}
                                                = _build_handler_for($valtype // 'Any');
                                            push @required_keys, $key if !$optional;
                                        }
                                        # And remember whether other keys are allowed...
                                        else {
                                            $extra_keys_allowed = 1;
                                        }
                                    }

                                    # Build type handlers for sequence...
                                    return sub {
                                        my $hash_ref = shift;
                                        # It has to be a hash reference...
                                        return _error_near($hash_ref, "Dict[$type_is{dict}]")
                                            if (reftype($hash_ref) // q{}) ne 'HASH';

                                        # With all the required keys...
                                        for my $key (@required_keys) {
                                            return _error_near($_, "Dict[$type_is{dict}]")
                                                if !exists $hash_ref->{$key};
                                        }

                                        # Each entry has to have a permitted key and the right type of value...
                                        while (my ($key, $value) = each %{$hash_ref}) {
                                            if (exists $handler_for{$key}) {
                                                my $okay = $handler_for{$key}($value);
                                                return _error_near($_, "Dict[$type_is{dict}]", $okay)
                                                    if !$okay;
                                            }
                                            else {
                                                return _error_near($_, "Dict[$type_is{dict}]")
                                                    if !$extra_keys_allowed;
                                            }
                                        }

                                        return 1;
                                    }
                                  }

    # Ref[T] types require a reference, whose dereferenced value is of type T...
    # but with special magic if T is already itself a reference type
    if ( exists $type_is{ref}   ) { my $value_handler = _build_handler_for($type_is{ref});
                                    return $value_handler if $type_is{ref} =~ $IS_REF_TYPE;
                                    return sub {
                                        my $reftype = reftype($_[0]);
                                        return _error_near($_[0], "Ref[$type_is{ref}]")
                                            if !$reftype || $reftype ne 'REF' && $reftype ne 'SCALAR';
                                        my $okay = $value_handler->(${$_[0]});
                                        return $okay ? 1 : _error_near($_[0], "Ref[$type_is{ref}]", $okay)
                                    }
                                  }

    # Not[T] negates the usual test...
    if ( exists $type_is{not}   ) { my $negated_handler = _build_handler_for($type_is{not});
                                    return sub {
                                        my $not_okay = $negated_handler->($_[0]);
                                        return _error_near($_[0], "Not[$type_is{not}]", $not_okay)
                                            if $not_okay;
                                        return 1;
                                    }
                                  }

    # Eq[S] types require a stringifiable, that matches 'S'...
    if ( exists $type_is{eq}    ) { my $str = eval "q[$type_is{eq}]";
                                    return sub {
                                        return 1 if defined $_[0]
                                                 && (!blessed($_[0]) || overload::Method($_[0],q{""}))
                                                 && eval{ "$_[0]" eq $str };
                                        return _error_near($_[0], "Eq[$type_is{eq}]");
                                    }
                                  }

    # Match[R] types require a stringifiable, that matches /R/x...
    if ( exists $type_is{match} ) { my $regex = eval { qr{$type_is{match}}x };
                                    croak "Invalid regex syntax in Match[$type_is{match}]:\n $@" if $@;
                                    return sub {
                                        return 1 if defined $_[0]
                                                 && (!blessed($_[0]) || overload::Method($_[0],q{""}))
                                                 && eval{ "$_[0]" =~ $regex };
                                        return _error_near($_[0], "Match[$type_is{match}]");
                                    }
                                  }

    # Can[M] types require a class or object with the specified methods...
    if ( exists $type_is{can}   ) { my @method_names = split q{,}, $type_is{can};
                                    s{\s*}{}g for @method_names;
                                    return sub {
                                        return 0 if !blessed($_[0]) && !$handler_for{Class}($_[0]);
                                        for my $method_name (@method_names) {
                                            return _error_near($_[0], "Can[$type_is{can}]")
                                                if !eval{ $_[0]->can($method_name) };
                                        }
                                        return 1
                                    }
                                  }

    # Overloads[O] types require a class or object with the specified overloads...
    if ( exists $type_is{overloads} ) { my @ops = split q{,}, $type_is{overloads};
                                        s{\s*}{}g for @ops;
                                        return sub {
                                            use overload;
                                            return 0 if !blessed($_[0]) && !$handler_for{Class}($_[0]);
                                            for my $op (@ops) {
                                                return _error_near($_[0], "Can[$type_is{overloads}]")
                                                    if !overload::Method($_[0], $op);
                                            }
                                            return 1
                                        }
                                      }

    die "Internal error: could not generate a type from '$type'. Please report this as a bug."
}

sub _complete_desc {
    my ($desc, $value) = @_;
    $desc //= q{Value (%s)};
    my $value_perl = _perl($value);
    return $desc =~ s{(?<!%)%s}{$value_perl}gr =~ s{%%(?=[[:alpha:]])}{%}gr;
}

sub validate {
    my ($typename, $value) = splice(@_,0,2);
    my ($value_desc, @constraints);
    for my $arg (@_) {
        # Subs are undescribed constraints...
        if (ref($arg) eq 'CODE') {
            push @constraints, $arg;
        }

        # Anything else is part of the value description...
        elsif (defined $arg) {
            $value_desc .= $arg;
        }
    }

    # What's happening in the caller's lexical scope???
    local $Dios::Types::Pure::lexical_hints = (caller 0)[10] // {};

    # All but the basic handlers are built late, as needed...
    if (!exists $handler_for{$typename}) {
        $handler_for{$typename} = _build_handler_for($typename)
            or die 'Internal error: unable to build type checker. Please report this as a bug.';
    }

    # Either the type matches or we die...
    if (!$handler_for{$typename}($value)) {
        $value_desc = _complete_desc($value_desc, $value);
        croak qq{\u$value_desc}
            . ($value_desc =~ /\s$/ ? q{} : q{ })
            . qq{is not of type $typename};
    }
    return 1 if !@constraints;

    # Either every constraint matches or we die...
    for my $test (@constraints) {
        local $@;

        # If it fails to match...
        if (! eval{ local $SIG{__WARN__} = sub{}; $test->(local $_ = $value) }) {
            $value_desc = _complete_desc($value_desc, $value);
            my $constraint_desc = _describe_constraint($value, $value_desc, $test, $@);
            croak qq{\u$value_desc}
                . ($value_desc =~ /\s$/ ? q{} : q{ })
                . qq{did not satisfy the constraint: $constraint_desc\n }
        }
    }

    return 1;
}

sub _up_validate {
    my ($uplevels, $typename, $value) = splice(@_,0,3);
    my ($value_desc, @constraints);
    for my $arg (@_) {
        # Subs are undescribed constraints...
        if (ref($arg) eq 'CODE') {
            push @constraints, $arg;
        }

        # Anything else is part of the value description...
        elsif (defined $arg) {
            $value_desc .= $arg;
        }
    }

    # What's happening in the caller's lexical scope???
    local $Dios::Types::Pure::lexical_hints = (caller $uplevels)[10] // {};

    # All but the basic handlers are built late, as needed...
    if (!exists $handler_for{$typename}) {
        $handler_for{$typename} = _build_handler_for($typename)
            or die 'Internal error: unable to build type checker. Please report this as a bug.';
    }

    # Either the type matches or we die...
    if (!$handler_for{$typename}($value)) {
        $value_desc = _complete_desc($value_desc, $value);
        croak qq{\u$value_desc}
            . ($value_desc =~ /\s$/ ? q{} : q{ })
            . qq{is not of type $typename};
    }
    return 1 if !@constraints;

    # Either every constraint matches or we die...
    for my $test (@constraints) {
        local $@;

        # If it fails to match...
        if (! eval{ local $SIG{__WARN__} = sub{}; $test->(local $_ = $value) }) {
            $value_desc = _complete_desc($value_desc, $value);
            my $constraint_desc = _describe_constraint($value, $value_desc, $test, $@);
            croak qq{\u$value_desc}
                . ($value_desc =~ /\s$/ ? q{} : q{ })
                . qq{did not satisfy the constraint: $constraint_desc\n }
        }
    }

    return 1;
}

sub validator_for {
    my $typename = shift;
    my ($value_desc, @constraints);
    for my $arg (@_) {
        # Subs are undescribed constraints...
        if (ref($arg) eq 'CODE') {
            push @constraints, $arg;
        }

        # Anything else is part of the value description...
        elsif (defined $arg) {
            $value_desc .= $arg;
        }
    }

    # What's happening in the caller's lexical scope???
    local $Dios::Types::Pure::lexical_hints = (caller 0)[10] // {};

    # All but the basic handlers are built late, as needed...
    if (!exists $handler_for{$typename}) {
        $handler_for{$typename} = _build_handler_for($typename)
            or die 'Internal error: unable to build type checker. Please report this as a bug.';
    }

    # Return the smallest sub that validates the type...
    my $handler = $handler_for{$typename};

    return $handler if !$value_desc && !@constraints;

    return sub {
        return 1 if $handler->($_[0]);

        my $desc = _complete_desc($value_desc, $_[0]);
        croak qq{\u$desc}
            . ($desc =~ /\s$/ ? q{} : q{ })
            . qq{is not of type $typename};
    } if !@constraints;

    return sub {
        # Either the type matches or we die...
        if (!$handler_for{$typename}($_[0])) {
            my $desc = _complete_desc($value_desc, $_[0]);
            croak qq{\u$desc}
                . ($desc =~ /\s$/ ? q{} : q{ })
                . qq{is not of type $typename};
        }
        return 1 if !@constraints;

        # Either every constraint matches or we die...
        for my $test (@constraints) {
            local $@;

            # If it fails to match...
            if (! eval{ local $SIG{__WARN__} = sub{}; $test->(local $_ = $_[0]) }) {
                my $desc = _complete_desc($value_desc, $_[0]);
                my $constraint_desc = _describe_constraint($_[0], $desc, $test, $@);
                croak qq{\u$desc}
                    . ($desc =~ /\s$/ ? q{} : q{ })
                    . qq{did not satisfy the constraint: $constraint_desc\n }
            }
        }

        return 1;
    }
}

package Dios::Types::Pure::TypedArray {
    our @CARP_NOT = ('Dios::Types::Pure');
    sub TIEARRAY  { bless [$_[1]], $_[0] }
    sub FETCHSIZE { @{$_[0]} - 1 }
    sub STORESIZE { $#{$_[0]} = $_[1] + 1 }
    sub STORE     { my ($type, $desc, @constraint) = @{$_[0][0]};
                    Dios::Types::Pure::_up_validate(1, $type, $_[2], $desc, @constraint);
                    $_[0]->[$_[1]+1] = $_[2];
                    }
    sub FETCH     { $_[0]->[$_[1]+1] }
    sub CLEAR     { @{$_[0]} = $_[0][0] }
    sub POP       { @{$_[0]} > 1 ? pop(@{$_[0]}) : undef }
    sub PUSH      { my $o = shift; push(@{$o}, @_) }
    sub SHIFT     { splice(@{$_[0]},1,1) }
    sub UNSHIFT   { my $o = shift; splice(@$o,1,0,@_) }
    sub EXISTS    { exists $_[0]->[$_[1]+1] }
    sub DELETE    { delete $_[0]->[$_[1]+1] }
    sub EXTEND    { }

    sub SPLICE
    {
        my $ob  = shift;
        my $sz  = @{$ob} - 1;
        my $off = @_ ? shift : 0;
        $off   += $sz if $off < 0;
        my $len = @_ ? shift : $sz-$off;
        return splice(@$ob,$off+1,$len,@_);
    }
}

package Dios::Types::Pure::TypedHash {
    our @CARP_NOT = ('Dios::Types::Pure');
    sub TIEHASH  { bless [$_[1], {}], $_[0] }
    sub STORE    { my ($type, $desc, @constraint) = @{$_[0][0]};
                   Dios::Types::Pure::_up_validate(1, $type, $_[2], $desc, @constraint);
                   $_[0][1]{$_[1]} = $_[2]
                 }
    sub FETCH    { $_[0][1]{$_[1]} }
    sub FIRSTKEY { my $a = scalar keys %{$_[0][1]}; each %{$_[0][1]} }
    sub NEXTKEY  { each %{$_[0][1]} }
    sub EXISTS   { exists $_[0][1]{$_[1]} }
    sub DELETE   { delete $_[0][1]{$_[1]} }
    sub CLEAR    { %{$_[0][1]} = () }
    sub SCALAR   { scalar %{$_[0][1]} }
}

sub _set_var_type {
    my ($type, $varref, $value_desc, @constraint) = @_;
    my $vartype = ref $varref;

    if ($vartype ne 'ARRAY' && $vartype ne 'HASH') {
        croak 'Typed attributes require the Variable::Magic module, which could not be loaded'
            if !eval{ require Variable::Magic };

        Variable::Magic::cast( ${$varref}, Variable::Magic::wizard( set => sub {
            # Code around awkward Object::Insideout behaviour...
            return if ((caller 3)[3]//"") eq 'Object::InsideOut::DESTROY';

            # Code around more awkward Object::Insideout behaviour...
            no warnings 'redefine';
            local *croak = *confess{CODE};
            return if eval { _up_validate(+2, $type, ${$_[0]}, $value_desc, @constraint) };
            die $@ =~ s{\s+at .*}{}r
                   =~ s{[\h\S]*Dios.*}{}gr
                   =~ s{.*\(eval .*}{}gr
                   =~ s{\s*[\h\S]*called at}{ at}r
                   =~ s{.*called at.*}{}gr;
        }));
    }
    elsif ($vartype eq 'ARRAY') {
        tie @{$varref}, 'Dios::Types::Pure::TypedArray', [$type, $value_desc, @constraint];
    }
    elsif ($vartype eq 'HASH') {
        tie %{$varref}, 'Dios::Types::Pure::TypedHash',  [$type, $value_desc, @constraint];
    }
    else {
        die 'Internal error: argument to _set_var_type() must be scalar, array ref, or hash ref';
    }
}

# Implement return-type checking...
sub _validate_return_type {

    # Type info is first arg (an arrayref), subroutine body is final arg (a sub ref)...
    my ($name, $type, $where) = @{shift()};
    $where //= sub{1};
    my $function = pop;

    # List return context...
    if (wantarray) {
        # Tidy up type...
        $type =~ s{\A Void \| | \| Void \Z}{}xmsg;
        my $void_warning = vec((caller 1)[9], $warnings::Offsets{'void'}, 1);
        warn sprintf "Call to $name() not in void context at %s line %d\n", (caller 1)[1,2]
            if $void_warning && $type eq 'Void';

        # Execute the subroutine body in (apparently) the right context...
        my @retvals = uplevel 2, $function, @_;

        # Adapt the constraint to produce a more appropriate error message...
        my $listwhere = sub {
            for (@{shift()}) {
                die _describe_constraint($_,undef,$where) if !$where->($_)
            }
            return 1;
        };

        # Validate the return values...
        eval {
            if (@retvals == 1) {
                _up_validate(+1,
                    $type, $retvals[0], $where,
                    "Return value (" . (_perl(@retvals)=~s/^\(|\)$//gr) . ") of call to $name()\n"
                );
            }
            else {
                undef;
            }
        }
        //
        eval {
            _up_validate(+1,
                $type, \@retvals, $listwhere,
                "List of return values (" . (_perl(@retvals)=~s/^\(|\)$//gr) . ") of call to $name()\n"
            )
        }

        # ..or convert the error message to report from the correct line number...
        // die $@ =~ s{\s*+at \S+ line \d++.*+}{sprintf "\nat %s line %d\n", (caller 1)[1,2]}ser;

        # If the return values are valid, return them...
        return @retvals;
    }

    # Scalar context...
    elsif (defined wantarray) {
        # Tidy up type...
        $type =~ s{\A Void \| | \| Void \Z}{}xmsg;
        my $void_warning = vec((caller 1)[9], $warnings::Offsets{'void'}, 1);
        warn sprintf "Call to $name() not in void context at %s line %d\n", (caller 1)[1,2]
            if $void_warning && $type eq 'Void';

        # Execute the subroutine body in (apparently) the right context...
        my $retval = uplevel 2, $function, @_;

        # Validate the return value...
        eval {
            _up_validate(+1,
                $type, $retval, $where,
                "Scalar return value (" . _perl($retval) . ") of call to $name()\n"
            )
        }
        # ...or convert the error message to report from the correct line number...
        // die $@ =~ s{\s*at \S+ line \d+.*}{sprintf "\nat %s line %d\n", (caller 1)[1,2]}er;

        # If the return value is valid, return it...
        return $retval;
    }

    # Void context...
    else {
        # Execute the subroutine body in (apparently) the right context...
        uplevel 2, $function, @_;

        # Warn about explicit return types in void context, unless return type implies void is okay...
        my $void_warning = vec((caller 1)[9], $warnings::Offsets{'void'}, 1);
        warn sprintf
            "Useless call to $name() with explicit return type $type\nin void context at %s line %d\n",
            (caller 1)[1,2]
                if $void_warning && !eval{ _up_validate(+1, $type, undef) };

    }
}




# Compare two types...
sub _is_narrower {
    my ($type_a, $type_b, $unnormalized) = @_;

    # Short-circuit on identity...
    return 0 if $type_a eq $type_b;

    # Otherwise, normalize and decompose...
    if (!$unnormalized && $type_a =~ m{\A (?: Ref ) \Z }xms) {
        $type_a = "Ref[Any]";
    }
    elsif (!$unnormalized && $type_a =~ m{\A (?: Array | List ) \Z }xms) {
        $type_a = "Ref[Array[Any]]";
    }
    elsif (!$unnormalized && $type_a eq 'Hash') {
        $type_a = "Ref[Hash[Any]]";
    }
    elsif ($type_a =~ m{\A \s*+ ((?&NON_ATOM_TYPENAME)) \s*+ \Z  $FROM_TYPENAME_GRAMMAR }xms) {
        $type_a = "Is[$1]";
    }
    $type_a =~ m{\A \s*+ $TYPENAME_GRAMMAR \s*+ \Z }xms;  my %type_a_is = %+;

    if (!$unnormalized && $type_b =~ m{\A (?: Ref ) \Z }xms) {
        $type_b = "Ref[Any]";
    }
    elsif (!$unnormalized && $type_b =~ m{\A (?: Array | List ) \Z }xms) {
        $type_b = "Ref[Array[Any]]";
    }
    elsif (!$unnormalized && $type_b eq 'Hash') {
        $type_b = "Ref[Hash[Any]]";
    }
    elsif ($type_b =~ m{\A \s*+ ((?&NON_ATOM_TYPENAME)) \s*+ \Z  $FROM_TYPENAME_GRAMMAR }xms) {
        $type_b = "Is[$1]";
    }
    $type_b =~ m{\A \s*+ $TYPENAME_GRAMMAR \s*+ \Z }xms;  my %type_b_is = %+;

    # If both are basic types, use the standard comparisons...
    if (exists $type_a_is{basic} && exists $type_b_is{basic}) {
        return +1 if $BASIC_NARROWER{$type_b}->{$type_a};
        return -1 if $BASIC_NARROWER{$type_a}->{$type_b};
    }

    # If both are array or hash or reference types, use the standard comparisons on their element-types...
    for my $elem_type (qw< array hash ref >) {
        if (exists $type_a_is{$elem_type} && exists $type_b_is{$elem_type}) {
            return _is_narrower($type_a_is{$elem_type}, $type_b_is{$elem_type}, 'unnormalized');
        }
    }

    # If either type is parameterized, try the generic unparameterized version...
    if ($type_a =~ s{\A(?:List|Array|Hash|Ref|Match|Eq)\K\[.*}{}xms
    ||  $type_b =~ s{\A(?:List|Array|Hash|Ref|Match|Eq)\K\[.*}{}xms) {
        return -1 if $type_a =~ m{\A(?:Match|Eq)\Z} && $BASIC_NARROWER{Class}->{$type_b};
        return +1 if $type_b =~ m{\A(?:Match|Eq)\Z} && $BASIC_NARROWER{Class}->{$type_a};
        return _is_narrower($type_a, $type_b, 'unnormalized');
    }

    # If both are user-defined types, try the standard inheritance hierarchy rules...
    if (exists $type_a_is{user} && exists $type_b_is{user}) {
        return +1 if $type_b->isa($type_a);
        return -1 if $type_a->isa($type_b);
    }

    # Otherwise, unable to compare...
    return 0;
}

# Compare two type signatures (of equal length)...
sub _cmp_signatures {
    my ($sig_a, $sig_b) = @_;

    # Extract named parameters of B...
    state %named_B_for;
    my $named_B =
        $named_B_for{$sig_b} //= { map { $_->{named} ? ($_->{named} => $_) : () } @{$sig_b} };

    # Track relative ordering parameter-by-parameter...
    my $partial_ordering = 0;
    for my $n (0 .. max($#$sig_a, $#$sig_b)) {
        # Unpack the next parameter types...
        my $sig_a_n = $sig_a->[$n] // {};
        my $sig_a_name = $sig_a_n->{named};
        my $sig_b_n = ($sig_a_name ? $named_B->{$sig_a_name} : $sig_b->[$n]) // {};
        my ($type_a, $type_b) = ($sig_a_n->{type} // 'Any', $sig_b_n->{type} // 'Any');

        # Find the ordering of the next parameter pair from the two signatures...
        my $is_narrower = _is_narrower($type_a, $type_b);

        # Tie-break in favour of the type with more constraints...
        if (!$is_narrower && $type_a eq $type_b) {
            my $where_a = $sig_a_n->{where} // 0;
            my $where_b = $sig_b_n->{where} // 0;
            $is_narrower = $where_a > $where_b ? -1
                         : $where_a < $where_b ? +1
                         :                        0;
        }

        # If this pair's ordering contradicts the ordering so far, there is no ordering...
        return 0 if $is_narrower && $is_narrower == -$partial_ordering;

        # Otherwise if there's an ordering, it becomes the "ordering so far"...
        $partial_ordering ||= $is_narrower;
    }

    # If we make it through the entire list, return the resulting ordering...
    return $partial_ordering;
}

# Resolve ambiguous argument lists using Perl6-ish multiple dispatch rules...
use List::Util qw< max first >;
sub _resolve_signatures {
    state %narrowness_for;
    my ($kind, @sigs) = @_;

    # Track narrownesses...
    my %narrower = map { $_ => [] } 0..$#sigs;

    # Compare all signatures, recording definitive differences in narrowness...
    for my $index_1 (0 .. $#sigs) {
        for my $index_2 ($index_1+1 .. $#sigs) {
            my $sig1 = $sigs[$index_1]{sig};
            my $sig2 = $sigs[$index_2]{sig};
            my $narrowness =
                $narrowness_for{$sig1,$sig2} //= _cmp_signatures($sig1, $sig2);

            if    ($narrowness < 0) { push @{$narrower{$index_1}}, $index_2; }
            elsif ($narrowness > 0) { push @{$narrower{$index_2}}, $index_1; }
        }
    }

    # Find the narrowest signature(s)...
    my $max_narrower = max map { scalar @{$_} } values %narrower;

    # If they're not sufficiently narrow, weed out the non-contenders...
    if ($max_narrower < @sigs-1) {
        @sigs = @sigs[ sort grep { @{$narrower{$_}} } keys %narrower ];
    }
    # Otherwise, locate the narrowest...
    else {
        @sigs = @sigs[ first { @{$narrower{$_}} >= $max_narrower } keys %narrower ];
    }

    # Tie-break methods on the class of the variants...
    if ($kind eq 'method' && @sigs > 1) {
        @sigs = sort { $a->{class} eq $b->{class}    ?  0
                     : $a->{class}->isa($b->{class}) ? -1
                     : $b->{class}->isa($a->{class}) ? +1
                     :                                  0
                     } @sigs;
        @sigs = grep { $_->{class} eq $sigs[0]{class} } @sigs;
    }

    return @sigs;
}


sub _describe_constraint {
    my ($value, $value_desc, $constraint, $constraint_desc) = @_;

    # Did the exception provide a constraint description???
    if ($constraint_desc) {
        $constraint_desc =~ s{\b at .* line .*+ \s*+}{}gx;
    }

    # Describe the value that failed...
    $value_desc = _complete_desc($value_desc, $value);

    # Try to describe the constraint by name, if it was a named sub...
    if (!length($constraint_desc//q{}) && eval{ require B }) {
        my $sub_name = B::svref_2object($constraint)->GV->NAME;
        if ($sub_name && $sub_name ne '__ANON__') {
            $sub_name =~ s/[:_]++/ /g;
            $constraint_desc = $sub_name;
        }
    }

    # Deparse the constraint sub (if necessary and possible)...
    if (!length($constraint_desc//q{}) && eval{ require B::Deparse }) {
        state $deparser = B::Deparse->new;
        my ($hint_bits, $warning_bits) = (caller 0)[8,9];
        $deparser->ambient_pragmas(
            hint_bits => $hint_bits, warning_bits => $warning_bits, '$[' => 0 + $[
        );
        $constraint_desc = $deparser->coderef2text($constraint);
        $constraint_desc =~ s{\s*+ BEGIN \s*+ \{ (?&CODE) \}
                                (?(DEFINE) (?<CODE> [^{}]*+ (\{ (?&CODE) \} [^{}]*+ )*+ ))}{}gxms;
        $constraint_desc =~ s{(?: (?:use|no) \s*+ (?: feature | warnings | strict ) | die \s*+ sprintf ) [^;]* ;}{}gxms;
        $constraint_desc =~ s{package \s*+ \S+ \s*+ ;}{}gxms;
        $constraint_desc =~ s{\s++}{ }g;
    }
    return $constraint_desc // "$constraint";
}

sub _perl {
    use Data::Dump 'dump';
    dump( map {
            if    (my $tiedclass = tied $_)    { $tiedclass =~ s/=.*//; "<$tiedclass tie>" }
            elsif (my $classname = blessed $_) { "<$classname object>"      }
            else                               { $_ }
          } @_ )
        =~ s{" (< \S++ \s (?:object|tie) >) "}{$1}xgmsr;

}



1; # Magic true value required at end of module
__END__

=head1 NAME

Dios::Types::Pure - Type checking for the Dios framework (and everyone else too)


=head1 VERSION

This document describes Dios::Types::Pure version 0.000001


=head1 SYNOPSIS

    use Dios::Types::Pure 'validate';

    # Throw an exception if the VALUE doesn't conform to the specified TYPE
    validate($TYPE, $VALUE);

    # Same, but report errors using the specified MESSAGE
    validate($TYPE, $VALUE, $MESSAGE);

    # Same, but VALUE must satisfy every one of the CONSTRAINTS as well
    validate($TYPE, $VALUE, $DESC, @CONSTRAINTS);

    # If you don't want exceptions in response to type mismatches, use an eval
    if (eval{ validate($TYPE, $VALUE) }) {
        warn "$VALUE not of type $TYPE. Proceeding anyway.";
    }

    use Dios::Types::Pure 'validator_for';

    # Same, but prebuild validator for faster checking...
    my $check = validator_for($TYPE, $DESC, @CONSTRAINTS);

    for my $VALUE (@MANY_VALUES) {
        $check->($VALUE);
    }




=head1 DESCRIPTION

=head2 Standard types

This module implements type-checking for all of the following
types...

=head3 C<< Any >>

Accepts any Perl value.


=head3 C<< Bool >>

Accepts any Perl value that can be used as a boolean.
So effectively: any Perl value (just like C<Any>).

This type exists mainly to allow you to be more specific about
using a value as a boolean.


=head3 C<< Undef >>

Accepts any value that is undefined.
In other words, only the value C<undef>.


=head3 C<< Def >>

Accepts any value that is defined.
That is, any value except C<undef>.


=head3 C<< Value >>

Accepts any value is defined...but not a reference.
For example: C<7> or C<0x093FA3D7> or C<'word'>.


=head3 C<< Num >>

Accepts any value that is defined and also something for which
C<Scalar::Util::looks_like_number()> returns true.

However, unlike C<looks_like_number()>, this type does B<not> accept the
special value C<'NaN'>. (I mean, what part of "I<not> a number" does
that function not understand???)

Note that this type B<does> accept other special values like
"Inf"/"Infinity", as well as objects with numeric overloadings.


=head3 C<< Int >>

Accepts any value for which C<Scalar::Util::looks_like_number()> returns
true I<and> which also matches the regex:

     /
        \A
        \s*                     # optional leading space
        [+-]?                   # optional sign
        (?:                     # either...
            \d++                #     digits
            (\.0*)?             #     plus optional decimal zeroes
        |                       # or...
            (?i) inf(?:inity)?  #     some "infinity" variant
        )                       #
        \s*                     # optional trailing space
        \Z
     /x

Note that this type also accepts objects with numeric overloadings that
produce integers.


=head3 C<< Str >>

Accepts any value that is a string, or a non-reference that can be
converted to a string (e.g. a number), or any objects with a
stringification overloading.


=head3 C<< Empty >>

Accepts any value that is a string, or a non-reference that can be
converted to a string (e.g. a number), or any objects with a
stringification overloading, provided the resulting string in
each case is of zero length.

Also accepts empty arrays and hashes (see below).


=head3 C<< Class >>

Accepts any value that's a string that is the name of a symbol-table
entry containing at least one of: C<$VERSION>, C<@ISA>, or some
C<CODE> entry.

In other words, the value must be the name of a package that is
plausibly also a class...either because it has a version number, or
because it inherits from some other class, or because it has at least
one method defined.


=head3 C<< Ref >> and C<< Ref[T] >>

Accepts any value that is a reference of some kind (including objects).

The parameterized form specifies what kind(s) of reference
the value must be:

    Ref[Str]       # accepts only a reference to a string
    Ref[Int]       # accepts only a reference to an integer
    Ref[Array]     # accepts only a reference to an array
    Ref[Hash]      # accepts only a reference to a hash
    Ref[Code]      # accepts only a reference to a subroutine
    Ref[Str|Num]   # accepts only a reference to a string or number

This implies that an unparameterized C<Ref> is just a shorthand for
C<Ref[Any]>.


=head3 C<< Scalar >>

Accepts any value that is a reference to a scalar.
For example: C<\1>, C<\2.34e56>, C<\"foo">, etc.


=head3 C<< Regex >>

Accepts any value that is a reference to a C<Regexp> object
(i.e. the value created by a C<qr/.../>).


=head3 C<< Code >>

Accepts any value that is a reference to a subroutine.
Either: C<\&named_sub> or C<sub {...}>.


=head3 C<< Glob >>

Accepts any value that is a reference to a typeglob.


=head3 C<< IO >>

Accepts any value that is a reference to an open filehandle
of some kind (as tested by C<Scalar::Util::openhandle()>).


=head3 C<< Obj >>

Accepts any value that is a reference to an object
(i.e. anything blessed).


=head3 C<< Array >> and C<< Array[T] >>

Accepts any value that is a reference to an array.

The parameterized form specifies what kind of values
the array must contain:

    Array[Str]         # reference to array containing only strings

    Array[Hash]        # reference to array containing only hash refs

    Array[Code|Array]  # reference to array containing
                       # subroutine refs and/or array refs

Hence an unparameterized C<Array> is just a shorthand for C<Array[Any]>.

The module also allows C<List> as a synonym for C<Array>.


=head3 C<< Empty >>

Accepts any value that is a reference to an array that contains no elements.

Also accepts empty strings and hashes (see above and below).


=head3 C<< Tuple[T1, T2, T3, ...], >>

Accepts any value that is a reference to an array in which the sequence of
array elements are of the specified types (in order). For example:

    Tuple[Str, Int, Int, Hash]    # accepts: ["Foo", 1, 2,   {bar=>1}]
                                  # but not: ["Foo", 1, 2.1, {bar=>1}]
                                  # and not: [1, 2,  "Foo",  {bar=>1}]

If the final specified type is followed by C<...>, the remainder of
the elements may be any number of values (including none) of that
type. For example:

    Tuple[Str, Hash, Str...]  # accepts:  ["Foo", {bar=>1}]
                              # and also: ["Foo", {bar=>1}, 'cat']
                              # and also: ["Foo", {bar=>1}, 'cat', 'dog']
                              # et cetera...

If the last component of a tuple's type list is just C<...> by itself,
the remainder of the elements may be anything (or nothing)...

    Tuple[Str, Hash, ...]     # accepts:  ["Foo", {bar=>1}]
                              # and also: ["Foo", {bar=>1}, 'etc']
                              # and also: ["Foo", {bar=>1}, 3, 4.5]
                              # et cetera...

That is, a trailing C<...> is just shorthand for a trailing C<Any...>


=head3 C<< Hash >>, Hash[T], and C<< Hash[T=>T] >>

The unparameterized type accepts any value that is a reference to a hash.

The singly parameterized form additionally constrains what kind of
values the hash may contain:

    Hash[Str]         # Each hash value must be a string

    Hash[Hash]        # Each hash value must be a hash reference

    Hash[Code|Array]  # Each hash value must be a subroutine or array reference

Hence an unparameterized C<Hash> is just a shorthand for C<< Hash[Any] >>.

The doubly parameterized form additionally constrains the type of keys
the hash may contain. The type specified before the arrow is the type of
each key; the type after the arrow is the type of each value:

    Hash[ Not[Empty] => Str ]  # Each key must be at least one character long
                               # and each value must be a string

    Hash[ Match[^q] => Any ]   # Each key must start with a 'q'
                               # but values can be of any type

    Hash[ Class => Obj|Undef ] # Each key must be the name of a class;
                               # Each value must be an object or C<undef>

Hence an unparameterized C<Hash> is also a shorthand for
C<< Hash[Str=>Any] >>.



=head3 C<< Empty >>

Accepts any value that is a reference to an hash that contains no entries.

Also accepts empty strings and arrays (see above).



=head3 C<< Dict[ k, k => T, k? => T, ...], >>

Accepts any value that is a reference to a hash containing specific keys
(and optionally with those keys having values of specific types).

Keys may be required or optional, and the corresponding values may be
typed or untyped (i.e. C<Any>). The set of keys listed may specify the
only permitted keys...or allow other keys as well. The following
examples cover the various possibilities.

To specify a reference to a hash with only four permitted keys
(C<'name'>, C<'rank'>, C<'ID'>, and C<'notes'>), I<all> of which must be
present in the hash:

    Dict[ name, rank, ID, notes ]

To specify a reference to a hash with four permitted keys,
only two of which are required to be present in the hash:

    Dict[ name, rank?, ID, notes? ]   # may have 'rank' and 'notes' entries
                                      # but not required to

To specify a reference to a hash with two to four permitted keys,
with values of specific types:

    Dict[ name => Str, rank? => Rank, ID => Int, notes? => Array ]

To specify a reference to a hash with two to four permitted keys,
only some of which have values of specific types:

    Dict[ name, rank? => Rank, ID => Int, notes? ]  # 'name' and 'notes entries
                                                    # can be of any type


To specify a reference to a hash with two to four specific keys, some
with specific types, and with any number of other keys also allowed:

    Dict[ name, rank? => Rank, ID => Int, notes?, ... ]

More complex relationships between keys and types can be specified using
disjunctive types. For example, a reference to a hash with required 'ID'
and 'name' entries and an optional 'rank' entry...but if the 'rank'
entry is present, there must also be a 'notes' array:

    Dict[name,ID]|Dict[name,ID,rank,notes=>Array]


=head3 C<< Eq[STR] >>

Accept a value whose stringification is C<eq> to C<'STR'>.

The string is always assumed to be non-interpolating.

Note that this type does not accept objects unless those objects
overload stringification...even if the string specified would match the
default C<'MyClass=HASH[0x1d15ed17]'> stringification of objects.


=head3 C<< Match[PATTERN] >>

Accept a value whose stringification matches the regex: C<m[PATTERN]x>

The pattern is always assumed to have the C</x> modifier in effect.
If you don't want that, you need to turn it off within the pattern:

    Match[      a b c ]     # accepts "abc"
    Match[(?-x) a b c ]     # accepts " a b c "

Note that this type does not accept objects unless those objects
overload stringification...even if the pattern specified would match the
default C<'MyClass=HASH[0x1d15ed17]'> stringification of objects.


=head3 C<< Can[METHODNAME1, METHODNAME2, ETC] >>

Accepts any value that is either an object or a classname (i.e. C<Obj|Class>)
and for which C<< $VALUE->can('METHODNAME') >> returns true for each
of the methodnames specified.

If you need to be more specific as to whether the value itself is an
object or a class, use a conjunction:

      Obj&Can[dump]    # i.e. $object->can('dump') returns true

    Class&Can[dump]    # i.e. MyClass->can('dump') returns true


=head3 C<< Overloads[OP1, OP2, ETC] >>

Accepts any value that is either an object or a classname (i.e. C<Obj|Class>)
and for which C<< overload::Method($VALUE,'OP') >> returns true for each
of the ops specified.

If you need to be more specific as to whether the value itself is an
object or a class, use a conjunction:

      Obj&Overloads["", 0+]   # object with overloaded stringification and numerification

    Class&Overloads["", 0+]   # class with overloaded stringification and numerification


=head3 C<T1&T2>

Accepts any value that both type I<T1> and type I<T2> individually accept.
For example:

    Obj&Device                # blessed($VALUE) && $VALUE->isa('Device')

    Class&Match[^Internal::]  # an actual class whose name begins: Internal::

Note that there cannot be space between the C<&> and either typename.

The C<&> is associative, so you can add as many types as needed. For
example, to accept only a hash-based object from a class in the
C<Storable> hierarchy, which must also have a valid C<restore()> method:

    Obj&Hash&Storable&Can[restore]

The component type tests are performed left-to-right and short-circuit on
any failure (like the normal Perl C<&&> operator), so it will often be
an optimization to put the most expensive type tests at the end.


=head3 C<T1|T2>

Accepts any value that either type I<T1> or type I<T2> individually
accepts. For example:

    Str|Obj       # accepts either a string or an object

    Num|Undef     # accepts either a number or undef

    Array|Hash    # accepts either an array or hash reference

Note that there cannot be space between the C<|> and either typename.

The C<|> is associative, so you can add as many type checks as needed.
For example, to accept a number or a specific string or a hash of integers:

    Num|Match[quit]|Hash[Int]

The component type tests are performed left-to-right and short-circuit
on any success (like the normal Perl C<||> operator), so it will often
be an optimization to put the most expensive type tests at the end.

The C<|> and C<&> type compositors have the usual precedences, so you can
combine them as expected. For example, to accept an object (of any kind),
or else the name of a class in the C<Storable> hierarchy:

    Obj|Class&Storable

If you need to circumvent the usual precedence, then use an C<Is[...]>.


=head3 C<< Is[T] >>

Accepts any value that type I<T> itself would accept.

This construct may be used anywhere within a typename, but is mainly
useful for "bracketing" types when composing them with C<|> and C<&>.

For example, to match an object of any class in the C<Storable> or
C<Disposable> hierarchies, or any object that has a C<reset()> method,
using normal C<&>/C<|> precedence, you'd have to write:

    Obj&Storeable|Obj&Disposable|Obj&Can[reset]

With C<Is[...]>, that's just:

    Obj&Is[Storeable|Disposable|Can[reset]]


=head3 C<< Not[T] >>

Accepts any value that type I<T> itself would B<not> accept.

For example:

    Not[Num]             # Anything except a number

    Not[Ref]             # Anything except a reference (i.e. a Value)

    Not[Obj]             # Anything unblessed

    Not[Match[error]]    # Anything that doesn't match /error/x

    Not[Obj|Class]       # Anything you can't call methods on

    Not[Obj&Storable]    # Anything that isn't an object of class Storable
                         # (could still be an object of some other hierarchy
                         #  or else a classname in the Storable hierarchy)


=head3 User-defined types

Any other type specification that is a valid Perl identifier or
qualified identifier is treated as a classname.

If the corresponding class exists, such a "classname type" accepts an
object or classname in the corresponding class hierarchy. For example:

    Storable               # object or classname in the Storable hierarchy

    Disk::DVD::Rewritable  # object or classname in D::D::R hierarchy

Such user-defined types can be composed with each other and with all the
other type specifiers listed above:

    Storable|Disk::DVD::Rewritable  # object or classname from either hierarchy

    Storable&Can[restore]           # a Storable with a restore() method

    Obj&Disk::DVD::Rewritable       # an object of the hierarchy



=head2 Type relationships

Most of the standard types and type compositors listed in the previous
section form a single hierarchy, like so:

    Any
      \__Bool
           |___Undef
           |
            \__Def
                |__Value
                |     |___Num
                |     |     \__Int
                |     |
                |      \__Str
                |          |___Empty
                |           \__Class
                |
                 \__Ref
                     |___Ref[<T>]
                     |___Scalar
                     |___Regex
                     |___Code
                     |___Glob
                     |___IO
                     |___Obj
                     |___Array
                     |      |___Empty
                     |      |___Array[<T>]
                     |       \__Tuple[<T>, <T>, <T>, ...],
                     |
                      \__Hash
                           |___Empty
                           |___Hash[<T>]
                            \__Dict[<k> => <T>, <k>? => <T>, ...],

That is, a value that is accepted by any specific type in this diagram
will also be accepted by all of its ancestral types. So, for example,
the type C<Tuple[Str,Int]> accepts the value S<C<['A',1]>>, so that
same value will also be accepted by all of the following types (amongst
many others): S<C<Tuple[Value,Int]>>, S<C<Tuple[Def,Num]>>,
S<C<Tuple[Any,Bool]>>, C<Array>, C<Ref>, C<Def>, C<Bool>, or C<Any>.

However, the converse is not generally true: a value that is accepted by
a "parent" type may not be accepted by all (or any) of its descendants.
So while the type C<Array> accepts the value S<C<['A',{}]>>, that same
value will B<not> be accepted by any of the "child" types:
C<Empty>, C<Array[Int]>, or C<Tuple[Int,Str]>.


=head1 INTERFACE

=head2 C<< use Dios::Types::Pure 'validate'; >>

The C<validate()> subroutine is B<not> exported by default, but must be
explicitly requested.


=head2 C<< use Dios::Types::Pure 'validator_for'; >>

The C<validator_for()> subroutine is B<not> exported by default, but must be
explicitly requested.


=head2 C<< use Dios::Types::Pure 'validate' => 'OTHER_NAME', 'validator_for' => 'ANOTHER_NAME'; >>

When importing C<validate()> or C<validator_for()>, you can request the
module rename it, by passing the desired alternative name as a second
argument. For example:

    use Dios::Types::Pure 'validate' => 'typecheck';

    # and later...

    typecheck('Array', $data);



=head2 C<< validate($type, $value, $value_desc, @constraint_subs) >>

This subroutine requires its first two arguments: a type specification
and a scalar value. If the type accepts the value, the subroutine returns true.
If the type doesn't accept the value, an exception is thrown.

For example:

    # Die if number of matches isn't an integer...
    validate('Int', $matches);

    # Die if any element isn't an open filehandle...
    validate('Array[IO]', \@filehandles);

    # Validate subroutine args...
    sub fill_text {
        validate('Str',                my $text  = shift);
        validate('Int',                my $width = shift);
        validate('Dict[fill?, just?]', my $opts  = shift);
        ...
    }

If you don't want the exception on failure, use an C<eval> to defuse it:

    while (1) {
        say 'Enter an integer: ';
        $input = readline;

        last if eval{ validate('Int', $input) };

        say "Warning: $@";
        redo;
    }

=head3 Describing the value passed to C<validate()>

You can also pass one or more extra strings to C<validate()>, which are
use to improve the error messages produced for unacceptable values. Any
extra arguments passed to the subroutine (that are not references) are
concatenated together and used as the description of the value in the
exception message. For example:

    my $input = 'seven';

    validate(Int, $input);
    # dies with: "Value ("seven") is not of type Int"

    validate(Int, $input, 'Error count reported by ', get_user_name());
    # dies with: "Error count reported by root is not of type Int"

If the description string contains a C<%s>, it is used as a C<sprintf>
format, and the value itself interpolated for the C<%s>. For example:

    validate(Int, $input, 'Error count (%s) reported by ', get_user_name());
    # dies with: "Error count (7.5) reported by root is not of type Int"


=head3 Constraining the value passed to C<validate()>

Any other extra arguments must be subroutine references, and these are
used as additional constraints on the type-checking.

That is, if the specified type accepts the value, that value is then
passed to each constraint subroutine in turn. If any of those
subroutines returns false or throws an exception, then the type is
considered B<not> to have matched the value.

For example:

    # Is $data a non-empty array of ints?
    validate('Array[Int]', $data, sub{ @{$_[0]} > 0 });

    # Is $filename a string in 8.3 format?
    validate('Str', $filename, sub{ shift =~ qr/^\w{1,8}\.\w{3}$/ };

    # Is $config a valid and normalized hash?
    validate('Hash', $config, \&is_valid, \&is_normalized);

When the constraint subroutines are called, the value being validated is
also temporarily aliased to C<$_>, which sometimes simplifies the
constraint:

    # Is $data a non-empty array of ints?
    validate('Array[Int]', $data, sub{ @$_ > 0 });

    # Is $filename a string in 8.3 format?
    validate('Str', $filename, sub{ /^\w{1,8}\.\w{3}$/ });

    # Is $ID an unused integer?
    validate('Int', $ID, sub{ !$used_ID[$_] });

When a constraint test fails, C<validate()> does its best to produce a
meaningful error message. For example, when C<$data> isn't long enough:

    my $data = [];

    validate('Array[Int]', $data, sub{ @$_ > 0 });

...then the exception thrown is:

    Value ([]) did not satisfy the constraint: { @$_ > 0; }

which is accurate, but maybe not sufficiently enlightening for all users.

There are two ways of improving the message produced. If a constraint
is specified as a named subroutine, as in the earlier example:

    validate('Hash', $config, \&is_valid, \&is_normalized);

then C<validate()> attempts to convert the subroutine name into a
description of the constraint:

    Value ({ a=>1, b=>2, c=>1 }) did not satisfy the constraint: is normalized

Alternatively, if a constraint subroutine throws an exception on failure,
the text of the exception is used as the description of the constraint:

    validate('Array[Int]', $data, sub{ @$_ > 0 or die 'must not be empty' });

Now the exception thrown is:

    Value ([]) did not satisfy the constraint: must not be empty


Note that the two kinds of extra arguments to C<validate()> (i.e. value
description strings and constraint subroutines) can be passed in any
order, or even intermixed, as there is no ambiguity in the meaning of
sub references vs non-references.

=head2 C<< validator_for($type, $value_desc, @constraint_subs) >>

This subroutine requires its first argument: a type specification.
It also accepts one or more additional arguments, specifying a
description of the value being checked, and any constraints.
All these arguments are exactly the same as for C<validate()>.

The C<validator_for()> subroutine returns a reference to an anonymous
subroutine that should be called with a single value, to check that the
specified type accepts that value. If the type accepts the value, the
anonymous subroutine returns true. If the type doesn't accept the value, an
exception is thrown.

In other words, C<validator_for()> returns the same subroutine that
C<validate()> would use to validate a value against a type. Or, in
other words:

    validate($type, $value, $desc, @constraints);

is just a shorthand for:

    my $check = validator_for($type, $desc, @constraints);
    $check->($value);

Because C<validator_for()> precompiles much of the checking API, it is
usually a more efficient choice when you want to perform the same type
check repeatedly. For example, to add type checking to a subroutine
parameter, instead of:

    sub delay {
        my $wait = shift;
        validate('Int', $wait, sub { $_ > 0 });

        my $code = shift;
        validate('Code', $code);

        sleep $wait;
        goto &$code;
    }

you could precompile each parameter's type check:

    sub delay {
        state $check_wait = validator_for('Int', sub { $_ > 0 });
        $check_wait->( my $wait = shift );

        state $check_code = validator_for('Code');
        $check_code->( my $code = shift );

        sleep $wait;
        goto &$code;
    }

which would make the checking approximately three times faster.



=head1 DIAGNOSTICS

=over

=item C<<  Can't export %s  >>

The module exports only a single subroutine: C<validate()>.
You asked it to export something else, which confused it.

If you were trying to export C<validate()> under a different name,
then you need:

    use Dios::Types::Pure validate => '<name>';


=item C<<  Two type specifications for key %s in Dict[%s] >>

The C<Dict[...]> type allows you to specify that a value must be of type
C<Hash>, and must only contain specific keys.

You're supposed to list each such key just once inside the square
brackets but you listed a key twice (or more). Delete all the repetitions.

If you repeated a key because you were trying to allow its value to have
two or more alternative types, like so:

    Dict[name => Str, name => Undef]

then you need to write that using a single junctive type instead:

    Dict[name => Str|Undef]


=item C<<  Incomprehensible type name: %s  >>

The type you specified wasn't one that the module understands.
Review the syntax for standard types and user-defined types.


=item C<<  Invalid regex syntax in Match[%s]: %s  >>

The contents of the square brackets must be a valid regex specification
(i.e. something you could validly put in an m/.../ or a qr/.../).

The full error message should point to the bad regex syntax. If that
message doesn't help, see L<perlre> for details of the standard Perl
regex syntax.


=item C<<  Missing specification for constraint: %s  >>

You passed a constraint to C<validate>, but it was not a subroutine
reference. Every constraint must be specified as a reference to a
subroutine that expects one argument (the value) and returns a boolean
value indicating whether the value satisfied the constraint.


=item C<<  %s is not of type %s  >>

This is the default message returned by C<validate()> if the value
passed as its second argument doesn't match the type passed as its
first argument.


=item C<<  %s did not satisfy the constraint: %s  >>

This is the default message returned by C<validate()> if the value
passed as its second argument failed to satisfy one of the constraint
subroutines that were also passed to it.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Dios::Types::Pure requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires Perl 5.14 or later.

Requires the Data::Dump module.

If typed attributes or parameters are used,
also requires the Variable::Magic module.




=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dios-types@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
