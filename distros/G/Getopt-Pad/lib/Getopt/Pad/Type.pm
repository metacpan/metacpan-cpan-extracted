package Getopt::Pad::Type;

use v5.26;
use strict;
use warnings;
use experimental 'signatures';

use Object::Pad;
use Getopt::Pad::Registry;
use Getopt::Pad::Util qw(specError);

our $VERSION = '0.06';

my @builtins = map { "Getopt::Pad::Type::$_" } qw(Flag Bool Counter String Int Float File Dir Url Date Duration);
my $registry;

sub registry() {
	return $registry //= Getopt::Pad::Registry->new(kind => 'option type')->register(@builtins);
}

sub registerType($class) {
	return registry()->register($class);
}

# Build the Type an option or arg spec names. Takes the type name (or
# $defaultName when the spec has none) and the keys the Type declares in
# SPEC_KEYS out of %$spec, so the caller can treat whatever is left as
# unknown. The Type checks those keys first; a problem is reported for
# $owner (e.g. "option 'retries'"). Returns the Type and the name it was
# resolved under.
sub takeFromSpec($spec, $defaultName, $owner) {
	my $typeName  = delete $spec->{type} // $defaultName;
	my $typeClass = registry()->resolve($typeName, $owner);
	my @typeKeys  = $typeClass->can('SPEC_KEYS') ? $typeClass->SPEC_KEYS->@* : ();
	my %typeArgs  = map { $_ => delete $spec->{$_} } grep { exists $spec->{$_} } @typeKeys;

	my $problem = $typeClass->checkSpecKeys(%typeArgs);
	specError("%s: %s", $owner, $problem) if defined $problem;
	return ($typeClass->new(%typeArgs), $typeName);
}

class Getopt::Pad::Type :abstract {
	method glSuffix;

	# Types with SPEC_KEYS check them here, before construction: return a
	# problem description without the option name, or undef.
	method checkSpecKeys :common (%args) {
		return undef;
	}

	method takesValue() {
		return $self->glSuffix =~ /=/ ? 1 : 0;
	}

	method negatable() {
		return $self->glSuffix eq '!' ? 1 : 0;
	}

	method glSpec($names, %flags) {
		my $suffix = $self->glSuffix;
		$suffix =~ s/^=/:/ if $flags{optionalValue};
		my $glSpec = $names . $suffix;
		$glSpec .= '@' if $flags{multiple};
		$glSpec .= '%' if $flags{hash};
		return $glSpec;
	}

	method coerce($value) {
		return $value;
	}

	method check($value) {
		return undef;
	}

	# Runs once per parse on every scalar of the value an option or arg
	# settles on, for checks that depend on the machine rather than on the
	# value (a path exists). Never runs on a spec default when the spec is
	# built. Return a problem description without the option name, or
	# undef.
	method verify($value) {
		return undef;
	}

	# Like verify, for types whose values need the world arranged (a path
	# created on demand). Runs only after every value of the parse passed
	# verify, so a parse that fails arranges nothing.
	method prepare($value) {
		return undef;
	}

	method label() {
		return undef;
	}

	method constraintNotes() {
		return ();
	}

	# Which of the shell's own completions a value of this type gets:
	# 'files', 'dirs', or undef for none.
	method completes() {
		return undef;
	}
}

class Getopt::Pad::Type::Flag :isa(Getopt::Pad::Type) :strict(params) {
	use JSON::PP ();

	use constant NAMES => ['flag'];

	method glSuffix() { return '' }

	# Config files give JSON or YAML booleans, 1/0 or ''; an undefined spec
	# default stays undefined.
	method check($value) {
		return undef if !defined $value || JSON::PP::is_bool($value) || $value =~ /\A[01]?\z/;
		return sprintf("'%s' is not a boolean (use true or false)", $value);
	}

	method coerce($value) {
		return $value if !defined $value;
		return $value ? 1 : 0;
	}
}

class Getopt::Pad::Type::Bool :isa(Getopt::Pad::Type::Flag) :strict(params) {
	use constant NAMES => ['!', 'bool', 'boolean'];

	method glSuffix() { return '!' }
}

class Getopt::Pad::Type::Counter :isa(Getopt::Pad::Type) :strict(params) {
	use constant NAMES => ['+', 'counter', 'count'];

	method glSuffix() { return '+' }

	method check($value) {
		return undef if !defined $value || $value =~ /\A[0-9]+\z/;
		return sprintf("'%s' is not a count", $value);
	}

	method coerce($value) {
		return $value if !defined $value;
		return $value + 0;
	}
}

class Getopt::Pad::Type::String :isa(Getopt::Pad::Type) :strict(params) {
	use constant NAMES => ['s', 'string', 'str'];

	method glSuffix() { return '=s' }
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type - Base class of option types, and how to write your own

=head1 SYNOPSIS

=for highlighter language=perl

    use v5.26;
    use Object::Pad;
    use Getopt::Pad;
    use Getopt::Pad::Type;

    class My::Type::Even :isa(Getopt::Pad::Type) {
        use constant NAMES => ['even'];

        method glSuffix() { return '=s' }

        method check($value) {
            return sprintf("'%s' is not an integer", $value) if $value !~ /\A-?[0-9]+\z/;
            return sprintf('%s is not an even number', $value) if $value % 2;
            return undef;
        }

        method coerce($value) { return $value + 0 }
    }

    Getopt::Pad::Type::registerType('My::Type::Even');

    my $opt = GetOptions(
        options => {
            workers => { type => 'even', default => 2, help => 'Number of workers, in pairs' },
        },
    );

=for highlighter language=plain

    $ tool --workers 8          # $opt->workers is 8
    $ tool --workers 7
    ERROR: option '--workers': 7 is not an even number

=head1 DESCRIPTION

A type decides how the value of an option or arg is checked and converted,
and how it is presented in the help output and in shell completion. Every
built-in type (see L<Getopt::Pad/TYPES>) is a subclass of
Getopt::Pad::Type, and so is every type you write yourself.

A type is an L<Object::Pad> class. Getopt::Pad creates one instance per
option or arg that uses the type, so the instance can hold settings of
that option, such as the C<min> and C<max> of an C<int> option.

To add a type:

=over 4

=item 1.

Write a class that inherits from Getopt::Pad::Type.

=item 2.

Give it a C<NAMES> constant and a C<glSuffix> method, and override the
optional methods you need (see L</THE TYPE CONTRACT>).

=item 3.

Register it with L</registerType> before the first C<GetOptions> call that
uses one of its names.

=back

After that, every spec in the program can use the names in its C<type>
keys.

=head1 THE TYPE CONTRACT

=head2 NAMES

=for highlighter language=perl

    use constant NAMES => ['seconds', 'secs'];

Required. A constant that returns an arrayref of the names the type
answers to in the C<type> key of an option or arg spec. Names are matched
case-insensitively. A name that another class has already registered,
built-in or not, cannot be taken over: L</registerType> dies. So a custom
type can never replace C<string> or C<int> by accident.

=head2 glSuffix

=for highlighter language=perl

    method glSuffix() { return '=s' }

Required. Tells the command line parser whether the option takes a value.
It returns one of these strings:

=for highlighter language=plain

    ''      no value (--name), like the flag type
    '!'     no value, negatable (--name, --no-name), like the bool type
    '+'     no value, counts how often it is given, like the counter type
    '=s'    takes a value

Almost every custom type returns C<'=s'>. It is the right choice for
numbers too: return C<'=s'> and check the value in L</check>, so that every
invalid value produces a Getopt::Pad error message. Types that take no
value can be used for options only, not for args, and not with
C<multiple>, C<hash> or C<objectlist>.

The suffix is the L<Getopt::Long> option specification suffix. It is the
only part of that notation a type deals with; the base class builds the
rest.

=head2 check

=for highlighter language=perl

    method check($value) {
        return undef if $value =~ /\A[0-9a-f]+\z/;
        return sprintf("'%s' is not a hexadecimal number", $value);
    }

Optional. Called with one value, from the command line, a config file or
the spec's default. Returns C<undef> when the value is acceptable,
otherwise a short description of the problem, B<without> the option name:
Getopt::Pad adds it, producing messages like C<option '--color':
'fff0' is not a hexadecimal number>. The default accepts every value.

C<check> always receives a single defined value: lists and mappings are
taken apart before, and missing values are reported before. Values from
config files can be numbers, or booleans: for C<true> and C<false>, JSON
files give 1 and 0, and YAML files give 1 and the empty string. A config
format of your own may also give boolean objects such as
L<JSON::PP::Boolean>. A value that fails
C<check> is not passed to any other method.

The spec's default is checked when C<GetOptions> builds the spec, on
every run. Checks whose answer depends on the machine the program runs
on, such as whether a path exists, belong in L</verify> instead.

=head2 coerce

=for highlighter language=perl

    method coerce($value) { return hex $value }

Optional. Called with a value that passed L</check>. Returns the value the
reader should return. The default returns the value unchanged. The
numeric types use it to turn strings into numbers.

The C<valid> list and the C<lazyValid> check of an option see the
converted value. The C<Default> line of the help output and
C<--create-default-config> show the default as the spec wrote it, not
converted.

=head2 verify

=for highlighter language=perl

    method verify($value) {
        return undef if !defined $value || -r $value;
        return sprintf("'%s' is not readable", $value);
    }

Optional. Called with the final, converted value of an option or arg
(once per value for options with several values), like L</prepare>, for
checks that depend on the machine rather than on the value. It is never
called with a default when the spec is built, only when the parse
settles on the default. Returns C<undef> when the value is acceptable,
otherwise a short description of the problem B<without> the option name,
which becomes a user error. The built-in C<file> and C<dir> types check
C<mustExist> here.

C<verify> runs on the values of every level the command line selects
before L</prepare> runs on any of them. It can be called with C<undef>
when the option's default is C<undef>. The default accepts every value.

=head2 prepare

=for highlighter language=perl

    method prepare($value) {
        return undef if !defined $value || -e $value;
        return sprintf("cannot create '%s': %s", $value, $!) if !mkdir $value;
        return undef;
    }

Optional. Called with the final, converted value of an option or arg
(once per value for options with several values), and never with a
value that is overridden, such as a default when the command line sets
the option. Use it for side effects the value needs; the built-in
C<file> and C<dir> types create missing paths here for
C<createPathIfMissing>. It runs only after the values of every selected
level passed L</check> and L</verify>, so a parse that fails earlier
changes nothing. A C<prepare> that fails can still follow another that
succeeded in the same parse.

Returns C<undef> on success, or a short description of the problem
B<without> the option name, which becomes a user error. It can be called
with C<undef> when the option's default is C<undef>. It is not called for
C<--help> and the other automatic options, or for shell completion
requests. The default does nothing.

=head2 label

=for highlighter language=perl

    method label() { return 'Duration' }

Optional. A short tag that the help output shows in brackets at the end of
the option's help text, such as C<[Duration]>. Returns C<undef> for no tag,
which is the default. An option or arg spec can override it with
C<typehint>.

=head2 constraintNotes

=for highlighter language=perl

    method constraintNotes() { return ('at most 1 hour') }

Optional. A list of short notes that the help output shows in brackets
before the help text, such as C<[at most 1 hour]>. The built-in path types
return C<has to exist> or C<created if missing>. The default is an empty
list.

=head2 completes

=for highlighter language=perl

    method completes() { return 'files' }

Optional. Which completion of its own the shell should offer for a value
of this type: C<'files'>, C<'dirs'>, or C<undef> for none (the default).
The C<file> and C<dir> types use it. The values of an option's C<valid>
list are completed in any case.

=head2 SPEC_KEYS

=for highlighter language=perl

    use constant SPEC_KEYS => ['maxSeconds'];

    field $maxSeconds :param = undef;

Optional. A constant that returns an arrayref of extra keys that option
and arg specs may use with this type. Getopt::Pad takes these keys out of
the spec and passes the ones that are present to the type's constructor
as named parameters. Declare a C<:param> field with a default for each
key. With any other type, the keys are unknown keys and a spec error.
This is how C<min>, C<max>, C<mustExist> and C<createPathIfMissing> reach
the built-in types.

=head2 checkSpecKeys

=for highlighter language=perl

    method checkSpecKeys :common (%keys) {
        return undef if !defined $keys{maxSeconds} || $keys{maxSeconds} =~ /\A[0-9]+\z/;
        return sprintf("maxSeconds must be a whole number, not '%s'", $keys{maxSeconds});
    }

Optional. A class method (C<:common>) that checks the L</SPEC_KEYS> values
of one option or arg before the type is constructed. It receives the keys
that are present and returns C<undef> when they are acceptable, otherwise
a short description of the problem without the option name. The problem
becomes a spec error: C<Getopt::Pad spec: option 'timeout': maxSeconds
must be a whole number, not '1h' at ...>. The default accepts everything.

=head2 Methods you do not need to write

The base class derives C<takesValue> and C<negatable> from L</glSuffix>,
and builds the complete parser specification in C<glSpec>. Overriding them
is rarely useful.

=head1 HOW A VALUE PASSES THROUGH A TYPE

For every value of an option, Getopt::Pad calls, in this order:

=over 4

=item 1.

C<check>. On a problem, the value is rejected with the returned message.

=item 2.

C<coerce>.

=item 3.

The option's C<valid> list and C<lazyValid> check, with the converted
value (not part of the type).

=item 4.

C<prepare>, for the value that is finally used.

=back

For args, steps 1, 2 and 4 apply. Defaults pass steps 1 to 3 when
C<GetOptions> builds the spec; a problem there is a spec error.

=head1 FUNCTIONS

=head2 registerType

=for highlighter language=perl

    Getopt::Pad::Type::registerType('My::Type::Seconds');

Registers a type class under the names in its L</NAMES> constant, for all
specs in the program. The argument is the class name. If the class
is not defined yet (it has no C<new> method), its module file is loaded
first (for example
F<My/Type/Seconds.pm> from C<@INC>). So a type in its own module file
needs no separate C<use>.

It dies when a name is already registered by another class, with
C<Getopt::Pad: option type name 'NAME' is already registered by CLASS>,
and when the class has no C<NAMES> constant. Registering the same class
again does nothing. Registration must happen before the C<GetOptions>
call whose spec uses the names.

The function is not exported; call it with its full name.

=head1 EXAMPLES

=head2 A type with an extra spec key

This type accepts durations such as C<90s>, C<5m>, C<2h> or C<1d>, and its
readers return seconds. The extra spec key C<maxSeconds> sets an upper
limit:

=for highlighter language=perl

    use v5.26;
    use Object::Pad;
    use Getopt::Pad;
    use Getopt::Pad::Type;

    class My::Type::Seconds :isa(Getopt::Pad::Type) {
        use constant NAMES     => ['seconds'];
        use constant SPEC_KEYS => ['maxSeconds'];

        my %secondsPer = (s => 1, m => 60, h => 3600, d => 86400);

        field $maxSeconds :param = undef;

        # Runs once per option, before the type is constructed.
        method checkSpecKeys :common (%keys) {
            return undef if !defined $keys{maxSeconds} || $keys{maxSeconds} =~ /\A[0-9]+\z/;
            return sprintf("maxSeconds must be a whole number, not '%s'", $keys{maxSeconds});
        }

        method glSuffix() { return '=s' }

        method check($value) {
            my ($amount, $unit) = $value =~ /\A([0-9]+)([smhd])\z/
                or return sprintf("'%s' is not a duration such as 90s, 5m, 2h or 1d", $value);
            my $seconds = $amount * $secondsPer{$unit};
            return undef if !defined $maxSeconds || $seconds <= $maxSeconds;
            return sprintf('%s is longer than %d seconds', $value, $maxSeconds);
        }

        method coerce($value) {
            my ($amount, $unit) = $value =~ /\A([0-9]+)([smhd])\z/;
            return $amount * $secondsPer{$unit};
        }

        method label() { return 'Duration' }

        method constraintNotes() {
            return defined $maxSeconds ? (sprintf('at most %d seconds', $maxSeconds)) : ();
        }
    }

    Getopt::Pad::Type::registerType('My::Type::Seconds');

    my $opt = GetOptions(
        options => {
            timeout => {
                type       => 'seconds',
                default    => '30s',
                maxSeconds => 3600,
                help       => 'How long to wait',
            },
        },
    );

    say $opt->timeout;

=for highlighter language=plain

    $ sleeper
    30
    $ sleeper --timeout 5m
    300
    $ sleeper --timeout 2h
    ERROR: option '--timeout': 2h is longer than 3600 seconds
    $ sleeper --timeout soon
    ERROR: option '--timeout': 'soon' is not a duration such as 90s, 5m, 2h or 1d

The help output shows the constraint note, the label and the default as
the spec wrote it:

=for highlighter language=plain

    ## Options
       --timeout <>                [at most 3600 seconds] How long to wait
                                   [Duration]
                                       Default = 30s

A spec with C<< maxSeconds => '1h' >> fails with C<Getopt::Pad spec:
option 'timeout': maxSeconds must be a whole number, not '1h'>, and one
with C<< default => '2h' >> with C<Getopt::Pad spec: option 'timeout':
default value: 2h is longer than 3600 seconds>.

=head2 A type with shell completion

This type accepts only Perl scripts and lets the shell complete file
names for it:

=for highlighter language=perl

    class My::Type::Script :isa(Getopt::Pad::Type) {
        use constant NAMES => ['script'];

        method glSuffix()  { return '=s' }
        method completes() { return 'files' }
        method label()     { return 'Perl Script' }

        method check($value) {
            return undef if $value =~ /\.pl\z/;
            return sprintf("'%s' is not a .pl file", $value);
        }
    }

    Getopt::Pad::Type::registerType('My::Type::Script');

    my $opt = GetOptions(
        options => {
            run => { type => 'script', help => 'The script to run' },
        },
    );

With the completion script installed (see
L<Getopt::Pad/SHELL COMPLETION>), C<tool --run >E<lt>TABE<gt> offers the
file names in the current directory, like the built-in C<file> type does.
A value that does not end in C<.pl> is rejected with C<option '--run':
'notes.txt' is not a .pl file>.

=head2 More examples

The distribution's F<examples/04-custom-type.pl> is a runnable version of
the C<even> type from the L</SYNOPSIS>. The built-in types are small and
readable examples as well; see L</BUILT-IN TYPE CLASSES>.

=head1 BUILT-IN TYPE CLASSES

=over 4

=item Getopt::Pad::Type::Flag

C<flag>. A switch without a value. Defined in this module.

=item Getopt::Pad::Type::Bool

C<bool>, C<boolean>, C<!>. A switch that can be negated. A subclass of the
flag type, defined in this module.

=item Getopt::Pad::Type::Counter

C<counter>, C<count>, C<+>. Defined in this module.

=item Getopt::Pad::Type::String

C<string>, C<str>, C<s>. Accepts any value. Defined in this module.

=item L<Getopt::Pad::Type::Int>, L<Getopt::Pad::Type::Float>

C<int> and C<float>, both subclasses of L<Getopt::Pad::Type::Number>,
which provides C<min> and C<max>.

=item L<Getopt::Pad::Type::File>, L<Getopt::Pad::Type::Dir>

C<file> and C<dir>, both subclasses of L<Getopt::Pad::Type::Path>, which
provides C<mustExist> and C<createPathIfMissing>.

=item L<Getopt::Pad::Type::Url>

C<url>, C<uri>.

=item L<Getopt::Pad::Type::Date>, L<Getopt::Pad::Type::Duration>

C<date> and C<duration>, both subclasses of
L<Getopt::Pad::Type::Temporal>, which provides C<timezone> and needs
L<DateTime::Format::Natural>.

=back

What each type accepts is described in L<Getopt::Pad/TYPES>.

=head1 SEE ALSO

L<Getopt::Pad>, L<Getopt::Pad::Config::Format> (the other extension
point), L<Object::Pad>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
