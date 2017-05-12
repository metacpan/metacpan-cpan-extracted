package Lexical::Failure;

use 5.014; use warnings;
no if $] >= 5.018, 'warnings', "experimental";
use Scope::Upper qw< want_at unwind uplevel UP SUB CALLER >;
use Carp qw< carp croak confess cluck >;
use Keyword::Simple;

use Lexical::Failure::Objects;

our $VERSION = '0.000007';

# Be invisible to Carp...
our @CARP_NOT = __PACKAGE__;

# Lexical hints are always at index 10 of caller()...
my $HINTS = 10;

# How to fail...
my %STD_FAILURE_HANDLERS = (
    'die'     => sub { _uplevel_die(@_);                      },
    'croak'   => sub { uplevel { croak(@_)   } @_, CALLER(2); },
    'confess' => sub { uplevel { confess(@_) } @_, CALLER(2); },
    'null'    => sub { return;                                },
    'undef'   => sub { return undef;                          },

    'failobj' => sub {
        uplevel { croak(@_)   } @_, CALLER(2) if !defined wantarray;
        return Lexical::Failure::Objects->new(
                    msg => (@_==1 ? $_[0] : "@_"),
                    context => [caller 2],
               );
    },
);

# Track handlers for lexical installations of fail()
my @ACTIVE_FAILURE_HANDLER_FOR_SCOPE;
my @VALID_FAILURE_HANDLERS_FOR_SCOPE;

# # 'croak' is the universal default failure handler...
my $DEF_NAMED_HANDLER = 'croak';
my $DEFAULT_SCOPE_ID = 0;
$ACTIVE_FAILURE_HANDLER_FOR_SCOPE[$DEFAULT_SCOPE_ID] = $STD_FAILURE_HANDLERS{$DEF_NAMED_HANDLER};

# Load the module...
sub import {
    my ($fail, $ON_FAILURE, $default, $handlers) = _process_import_args(@_);

    # Export API...
    Keyword::Simple::define $ON_FAILURE, _replace_keyword_with('Lexical::Failure::ON_FAILURE');
    Keyword::Simple::define $fail,       _replace_keyword_with('Lexical::Failure::fail');

    # Install specified failure handlers for the caller's scope...
    my $handlers_scope_ID = scalar @VALID_FAILURE_HANDLERS_FOR_SCOPE;
    $^H{'Lexical::Failure::handlers_scope_ID'} = $handlers_scope_ID;
    push @VALID_FAILURE_HANDLERS_FOR_SCOPE, { %STD_FAILURE_HANDLERS, %{$handlers} };

    # Install default failure handler for the caller's scope...
    if (ref($default) ne 'CODE') {
        croak "Unknown default failure handler: '$default'"
            if !exists $VALID_FAILURE_HANDLERS_FOR_SCOPE[-1]{$default};
        $default = $VALID_FAILURE_HANDLERS_FOR_SCOPE[-1]{$default};
    }
    my $default_scope_ID = scalar @ACTIVE_FAILURE_HANDLER_FOR_SCOPE;
    $^H{'Lexical::Failure::default_scope_ID'} = $default_scope_ID;
    push @ACTIVE_FAILURE_HANDLER_FOR_SCOPE, $default;

    return;
}

sub _process_import_args {
    my $package = shift;

    # What we're looking for (and their values if we don't find them)...
    my $fail       = 'fail';
    my $ON_FAILURE = 'ON_FAILURE';
    my $default    = 'croak';
    my $handlers   = {};

    # Trawl through the argument list...
    while (defined( my $next_arg = shift @_)) {
        if ($next_arg eq 'fail') {
            $fail = shift(@_) 
                or croak "Missing rename for 'fail' in use $package";
            croak "Value for 'fail' option must be a string"
                if ref $fail;
        }
        elsif ($next_arg eq 'ON_FAILURE') {
            $ON_FAILURE = shift(@_) 
                or croak "Missing rename for 'fail_width' in use $package";
            croak "Value for 'ON_FAILURE' option must be a string"
                if ref $fail;
        }
        elsif ($next_arg eq 'default') {
            $default = shift(@_) 
                or croak "Missing specification for 'default' in use $package";
            croak "Value for 'default' option must be a string or subroutine reference"
                if ref $fail && ref $fail ne 'CODE';
        }
        elsif ($next_arg eq 'handlers') {
            $handlers = shift(@_) 
                or croak "Missing specification for 'handlers' in use $package";
            croak "Value for 'handlers' option must be a hash reference"
                if !ref $handlers || ref $handlers ne 'HASH';
            croak "Handlers in 'handlers' hash must all be code references"
                if grep { ref($_) ne 'CODE' } values %{$handlers};
        }
        else {
            croak "Unexpected argument ($next_arg) in use $package"
        }
    }

    return ($fail, $ON_FAILURE, $default, $handlers);
}

sub _replace_keyword_with {
    my $replacement = shift;

    return sub {
        my ($src_ref) = @_;
        substr(${$src_ref}, 0, 0) = $replacement;
    }
}

sub ON_FAILURE {
    my $handler = shift;

    # No arg or undef arg --> no-op...
    return if !defined $handler;

    # Can't be called at runtime...
    if (${^GLOBAL_PHASE} ne 'START') {
        croak "Can't call ON_FAILURE after compilation"
    }

    # Can't be called outside a subroutine...
    if ((caller 1)[3] eq '(eval)') {
        croak "Can't call ON_FAILURE outside a subroutine"
    }

    # Can only be called with certain types of arguments...
    my $handler_type = ref $handler;
    croak "Invalid handler type ($handler_type ref) in call to ON_FAILURE"
        if $handler_type !~ m{\A (?: CODE | SCALAR | ARRAY | HASH | (?#STRING) ) \z}xms;

    # Which package is setting this handler???
    my $owner = caller;

    # Locate valid failure handlers...
    my $handlers_scope_ID = (caller 0)[$HINTS]{'Lexical::Failure::handlers_scope_ID'};
    my $valid_handlers_ref = $VALID_FAILURE_HANDLERS_FOR_SCOPE[$handlers_scope_ID];

    # Translate failure handlers (if necessary)...
    given (ref $handler) {
        # Find handler for symbolic failure modes ('die', 'confess', etc.)...
        when (q{}) {
            croak "Unknown failure handler: '$handler'"
                if !exists $valid_handlers_ref->{$handler};
            $handler = $valid_handlers_ref->{$handler};
        }

        my $target_var = $handler;
        # _check_scoping_of($target_var); # Experimentally removed (may not be necessary)

        # Scalars are simply assigned to...
        when ('SCALAR') {
            $handler = sub { ${$target_var} = [@_]; return; }
        }

        # Arrays are simply pushed onto...
        when ('ARRAY') {
            $handler = sub { push @{$target_var}, [@_]; return; }
        }

        # Hashes are simply added to...
        when ('HASH') {
            $handler = sub {
                my $caller_sub = (caller 2)[3];
                $target_var->{$caller_sub} = [@_];
                return;
            }
        }
    }

    # Install failure handler for the scope...
    my $scope_ID = scalar @ACTIVE_FAILURE_HANDLER_FOR_SCOPE;
    $^H{"Lexical::Failure::scope_ID::$owner"} = $scope_ID;
    push @ACTIVE_FAILURE_HANDLER_FOR_SCOPE, $handler;

    return;
}

# Fail by calling the appropriate handler...
sub fail {
    my (@msg) = @_;

    # Find the requested lexical handler...
    my $caller       = caller;
    my $fail_handler = _find_callers_handler($caller);

    # Determine original context of sub that's failing...
    my $context = want_at(UP SUB);

    # Ignore this code when croaking/carping from a handler
    package
    Carp;
    use Scope::Upper qw< unwind UP SUB>;

    # Simulate a return...
    unwind +( !defined $context ?    do{ $fail_handler->(@msg); undef; }
            :        ! $context ? scalar $fail_handler->(@msg)
            :                            $fail_handler->(@msg)
            ) => UP SUB;
}

# (Experimentally remove these checks as they may not be necessary...or reliable)
#
#sub _check_scoping_of {
#    my ($target_var) = @_;
#
#    # Is this something we can check???
#    my $var_type = ref $target_var;
#    return if $var_type !~ m{\A (?: SCALAR | ARRAY | HASH  ) \z}x;
#
#    # Look up the potential variables it could be...
#    use PadWalker qw< peek_my peek_our var_name >;
#    my %vars = ( %{peek_our(3)}, %{peek_my(3)} );
#
#    # If it isn't any of them, warn us...
#    if (!grep { $vars{$_} == $target_var } keys %vars) {
#        return if _is_package_var($target_var);
#
#        cluck 'Lexical ' . lc($var_type) . ' used as failure handler may not stay shared at runtime';
#    }
#}
#
#sub _is_package_var {
#    my ($target_ref) = @_;
#
#    my @packages = ('main');
#    my %seen;
#
#    while (my $package = shift @packages) {
#        no strict;
#        while (($name, $entry) = each(%{*{"$package\::"}})) {
#            local(*ENTRY) = $entry // next;
#
#            # Check for match...
#            return 1 if defined *ENTRY{SCALAR} && *ENTRY{SCALAR} == $target_ref
#                     || defined *ENTRY{ARRAY}  && *ENTRY{ARRAY}  == $target_ref
#                     || defined *ENTRY{HASH}   && *ENTRY{HASH}   == $target_ref;
#
#            # Check down tree...
#            if (defined *ENTRY{HASH} && $name =~ m{ (?<child> .* ) :: \z }xms) {
#                next if $seen{$+{child}}++;
#                push @packages, $+{child};
#            }
#        }
#    }
#
#    return 0;
#}

# Locate hints hash of first scope outside caller (if any)...
sub _find_callers_handler {
    my ($immediate_caller_package) = @_;

    # Scope ID for default handler...
    my $default_scope_ID
        = (caller 1)[$HINTS]{'Lexical::Failure::default_scope_ID'}
        // $DEFAULT_SCOPE_ID;

    # Search upwards for first namespace different from $caller...
    LEVEL:
    for my $uplevel (2..10000) {
        my @uplevel_caller = caller($uplevel);

        # Give up if no higher contexts...
        last LEVEL if !@uplevel_caller;

        # Return handler for first different namespace (or else default handler)...
        if ($uplevel_caller[0] ne $immediate_caller_package) {
            my $target_scope_ID
                = $uplevel_caller[10]{"Lexical::Failure::scope_ID::$immediate_caller_package"}
                // $default_scope_ID;
            return $ACTIVE_FAILURE_HANDLER_FOR_SCOPE[ $target_scope_ID ];
        }
    }

    # If no such uplevel context, return a "null" hints hash...
    return $ACTIVE_FAILURE_HANDLER_FOR_SCOPE[ $default_scope_ID ];
}


# Simulate a die() called at 2 levels higher up the stack...
sub _uplevel_die {
    my $exception = @_ ? join(q{},@_)
                  : $@ ? qq{$@\t...propagated}
                  :      q{Died};

    die $exception if ref $exception;

    if (!ref $exception && substr($exception, -1) ne "\n") {
        my (undef, $file, $line) = caller(2);
        $exception .= " at $file line $line\n";
    }

    die $exception;
}

1; # Magic true value required at end of module

__END__

=head1 NAME

Lexical::Failure - User-selectable lexically-scoped failure signaling


=head1 VERSION

This document describes Lexical::Failure version 0.000007


=head1 SYNOPSIS

    package Your::Module;

    # Set up this module for lexical failure handling...
    use Lexical::Failure;

    # Each time module is imported, set up failure handler...
    sub import {
        my ($package, %named_arg) = @_;

        ON_FAILURE( $named_arg{'fail'} );
    }

    # Then, in the module's subs/methods, call fail() to fail...
    sub inverse_square {
        my ($n) = @_;

        if ($n == 0) {
            fail "Can't invert zero";
        }

        return 1/$n**2;
    }

    sub load_file {
        my ($filename) = @_;

        fail 'No such file: ', $filename
            if ! -r $filename;

        local (@ARGV, $/) = $filename;
        return readline;
    }



=head1 DESCRIPTION

This module sets up two new keywords: C<fail> and C<ON_FAILURE>,
with which you can quickly create modules whose failure signaling
is lexicially scoped, under the control of client code.

Normally, modules specify some fixed mechanism for error handling and
require client code to adapt to that policy. One module may signal
errors by returning C<undef>, or perhaps some special "error object".
Another may C<die> or C<croak> on failure. A third may set a flag
variable. A fourth may require the client code to set up a callback,
which is executed on failure.

If you are using all four modules, your own code now has to check for
failure in four different ways, depending on where the failing
component originated. If you would rather that I<all> components throw
exceptions, or all return C<undef>, you will probably have to write
wrappers around 3/4 of them, to convert from their "native" failure
mechanism to your preferred one.

Lexical::Failure offers an alternative: a simple mechanism with which
module authors can generically specify "fail here with this message"
(using the C<fail> keyword), but then allow each block of client
code to decide how that failure is reported to it within its own lexical
scope (using the C<ON_FAILURE> keyword).

Module authors can still provide a default failure signaling mechanism,
for when client code does not specify how errors are to be reported.
This is handy for ensuring backwards compatibility in existing modules
that are converted to this new failure signaling approach.


=head1 INTERFACE

=head2 Accessing the API

To install the new C<fail> and C<ON_FAILURE> keywords, simple
load the module:

    use Lexical::Failure;

=head3 Changing the names of the API keywords

To avoid name conflicts, you can change the name of either (or both) of
the keywords that the module sets up, by passing a named argument when
loading the module. The name of the argument should be the standard name
of the keyword you want to rename, and the value of the argument should
be a string containing the new name. For example:

    use Lexical::Failure (
        fail       => 'return_error',
        ON_FAILURE => 'set_error_handler',
    );

    sub import {
        my ($package, %named_arg) = @_;

        set_error_handler( $named_arg{'fail'} );
    }

    sub inverse_square {
        my ($n) = @_;

        return_error "Can't invert zero" if $n == 0;

        return 1/$n**2;
    }


=head2 Signaling failure with C<fail>

Once the module is loaded, you simply use the C<fail> keyword
in place of C<return>, C<return undef>, C<die>, C<croak>, C<confess>,
or any other mechanism by which you would normally indicate
failure.

You can call C<fail> with any number of arguments, including 
none, and these will be passed to whichever failure handler
the client code eventually selects (see below).

Note that C<fail> is a keyword, not a subroutine
(that is, it's like C<return> itself, and not something
you can call as part of a larger expression).


=head2 Specifying a lexically scoped failure handler with C<ON_FAILURE>

You set up a failure-signaling interface for client code by placing the
C<ON_FAILURE> keyword in your module's C<import()> subroutine (or in a
subroutine called from your C<import()>).

The keyword expects one argument, which specifies how failures in the module
are to be handled in the lexical scope where your module was loaded.
The single argument can be:

=over

=item *

a string containing the name of a named failure handler

=item *

a reference to a variable, into which failure signals will be stored

=item *

a reference to a subroutine, which will be used as a callback and invoked 
whenever a failure is to be signalled

=item *

C<undef> (or no argument at all), in which case C<ON_FAILURE> does nothing.
This means you don't need to bother checking whether a failure specifier
was passed in to your C<import()>. Just pass in the resulting C<undef> 
value...and it's ignored.

=back

Typically, then, you have your C<import()> subroutine accept an argument
through which client code indicates its desired failure mode:

    package Your::Module;

    sub import {
        my ($package, %named_arg) = @_;

        ON_FAILURE $named_arg{'fail'};
    }

Then the client code can specify different reporting strategies
in different lexical scopes:

    # Hereafter, report failures by returning undef...
    use Your::Module  fail => 'undef';

    {
        # But in this block, make errors fatal...
        use Your::Module  fail => 'croak';

        {
            # And in here, set a flag...
            my $nested_error_flag;
            use Your::Module  fail => \$nested_error_flag;

            {
                # And in here, any error is quietly loggged...
                use Your::Module  fail => sub { $logger->error(@_) };
            }
        }

        # Back to croaking errors here
    }

    # Back to returning undef here

Each C<use Your::Module> invokes C<Your::Module::import()>, whereupon
the call to C<ON_FAILURE> installs the specified failure handler into
the lexical scope in which C<use Your::Module> occurred. The installed
handler is specific to Your::Module, so if two or more modules are
each using Lexical::Failure, client code can set failure-signaling
policies for each module independently in the same scope.


=head3 Named failure handlers

If C<ON_FAILURE> is passed a string, that string is treated as the name
of a predefined failure handler.  Lexical::Failure provides six standard 
named handlers:

=over

=item C<ON_FAILURE 'null'>

Specifies that each C<fail @args> should act like:

    return;

That is: return C<undef> in scalar context or return an empty list in
list context.

Note that, this context-sensitive behaviour can occasionally lead
to subtle errors. For example, if these three subroutines are using
C<ON_FAILURE 'null'> failure signaling:


    my %personal_data = (
        name   => get_name(),
        age    => get_age(),
        status => get_status(),
    );

then if any of them fails, it will return an empty list, messing up the
initialization of the hash. In such cases, C<ON_FAILURE 'undef'> is a
better alternative.

=item C<ON_FAILURE 'undef'>

Specifies that each C<fail @args> should act like:

    return undef;

Note that to get this behaviour, the argument needs to be C<'undef'> (a
five letter string), not C<undef> (the special undefined value).

Note too that, when this handler is selected, C<fail> returns an
C<undef> even in list context. This can be problematical, as an C<undef>
is (to many people's surprise) I<true> in list context. For example, if
C<get_results()> returns C<undef> on failure, the conditional test of
this C<if> will still be true:

    if (my @results = get_results($data)) {
        ....
    }

because C<@results> will then contain one element (the C<undef>), and a
non-empty array always evaluates true in boolean context.

For this reason it's usually better to use C<ON_FAILURE 'null'> instead.



=item C<ON_FAILURE 'die'>

Specifies that each C<fail @args> should act like:

    die @args;


=item C<ON_FAILURE 'croak'>

Specifies that each C<fail @args> should act like:

    Carp::croak(@args);


=item C<ON_FAILURE 'confess'>

Specifies that each C<fail @args> should act like:

    Carp::confess(@args);


=item C<ON_FAILURE 'failobj'>

Specifies that each C<fail @args> should act like:

    return Lexical::Failure::Objects->new(
                msg     => ( @args == 1 ? $args[0] : "@args" ),
                context => [caller 1]
           );

In other words, C<ON_FAILURE 'failobj'> causes C<fail> to return a
special object encapsulating the arguments passed to C<fail> and the
call context in which the C<fail> occurred.

See the documentation of L<Lexical::Failure::Objects> for more details
on this alternative.

=back

You can also set up other named failure handlers of your
own devising (see L<"Specifying additional named failure handlers">).


=head3 Variables as failure handlers

If C<ON_FAILURE> is passed a reference to a scalar, array, or hash,
that variable becomes the "receiver" of subsequent failure reports,
as follows:

=over

=item C<ON_FAILURE \$scalar>

Specifies that C<fail @args> should act like:

    $scalar = [@args];
    return undef;


=item C<ON_FAILURE \@array>

Specifies that C<fail @args> should act like:

    push @array, [@args];
    return undef;


=item C<ON_FAILURE \%hash>

Specifies that C<fail @args> should act like:

    $hash{ $CURRENT_SUBNAME } = [@args];
    return undef;

=back

=head3 Subroutines as failure handlers

C<ON_FAILURE> can also be passed a reference to a 
subroutine, which then acts like a callback when
failures are signalled.

In other words:

    ON_FAILURE $subroutine_ref;

causes C<fail @args> to act like:

    return $subroutine_ref->(@args);

The availability of this alternative means that client
code can create entirely new failure-signaling behaviours
whenever needed. For example:

    # Signal failure by logging an error and returning negatively...
    use Your::Module  fail => sub { $logger->error(@_); return -1; };


    # Signal failure by returning undef/empty list,
    # except in one critical case...
    use Your::Module  fail => sub { 
                                  my $msg = "@_";
                                  croak $msg if $msg =~ /dangerous/;
                                  return;
                              };


    # The very first failure is instantly (and unluckily) fatal...
    use Your::Module  fail => sub { carp(@_); exit(13) };



=head3 Restricting how client code can signal failure

Because the call to C<ON_FAILURE> must occur in your module's
C<import()> subroutine, you always have ultimate control over what types
of failure signaling the client code may request from your module.

For example, to prevent client code from requesting C<return undef>
behaviours:

    sub import {
        my ($package, %named_arg) = @_;

        croak "Can't specify 'undef' as a failure handler"
            if $named_arg{'fail'} eq 'undef';

        ON_FAILURE $named_arg{'fail'};
    }

or to quietly convert 'die' behaviours into (much more useful) 'croak' 
behaviours:

    sub import {
        my ($package, %named_arg) = @_;

        $named_arg{'fail'} =~ s/^die$/croak/;

        ON_FAILURE $named_arg{'fail'};
    }


=head3 Specifying a module's default failure handler

In any scope where no explicit failure signaling behaviour
has been specified, Lexical::Failure defaults to its standard
C<'croak'> behaviour (see L<"Named failure handlers">).

However, you can also specify a different default for your module,
by adding a named argument when you load Lexical::Failure:

    # Default to full confession on failure...
    use Lexical::Failure  default => 'confess';

    # Default to 'return undef or empty list' on failure...
    use Lexical::Failure  default => 'null';

    # Default to instant fatality on failure...
    use Lexical::Failure  default => sub { carp(@_); exit() };

The values allowed for the C<'default'> option are somewhat more
restrictive than those which can be passed directly to C<ON_FAILURE>;
you can specify only standard named handlers (see L<"Named failure handlers">)
or a subroutine reference.

If you need your default to be a non-standard named handler (see
L<"Specifying additional named failure handlers">) or a reference
to a variable, you must arrange that in your C<import()> instead.
For example:

    sub import {
        my ($package, %named_arg) = @_;

        # Install failure signaling, if specified...
        if (defined $named_arg{'fail'}) {
            ON_FAILURE $named_arg{'fail'};
        }

        # Otherwise, default to pushing errors onto a package variable
        # (yeah, this is a HORRIBLE idea, but it's what our boss decided!)
        else {
            ON_FAILURE \@Your::Module::errors;
        }
    }


=head3 Specifying additional named failure handlers

The six standard L<named failure handlers|"Named failure handlers">
provide convenient declarative shortcuts for client code. That is,
instead of constantly having to create messy subroutines like:

    use Your::Module 
        fail => sub {
            return Lexical::Failure::Objects->new(
                        msg     => (@_ == 1 ? $_[0] : "@_"),
                        context => [caller 1],
                   );
        };

client code can just request:

    use Your::Module  fail => 'failobj';

However, you may wish to offer a similar declarative interface for other
failure-signaling behaviours that your client code is likely to need.
For example:

    use Your::Module  fail => 'logged';

    use Your::Module  fail => 'exit';

    use Your::Module  fail => 'loud undef';

Lexical::Failure provides a simple way to set up extra named handlers
like these. You just specify the name and associated callback for each
when loading the module:

    package Your::Module;

    use Lexical::Failure  handlers => {
        'logged'     =>  sub { $logger->error(@_);     },
        'exit'       =>  sub { say @_; exit;           },
        'loud undef' =>  sub { carp(@_); return undef; },
    };

The C<'handlers'> option expects a reference to a hash, in which each
key is the name of a new named failure handler, and each corresponding
value is a reference to a subroutine implementing the behaviour of 
that named handler.

Once specified, any of the new handler names may be passed to
C<ON_FAILURE> to specify that C<fail> should use the corresponding
callback to signal failures.

Note that any extra named handlers defined in this way are only available
from the module in which they are defined.


=head1 DIAGNOSTICS

=over

=item C<< Unknown failure handler: %s >>

You called C<ON_FAILURE> with a string as the handler
specification. However, that string was not one of the standard named
handlers (C<'confess'>, C<'croak'>, C<'die'>, C<'failobj'>, C<'undef'>, or C<'null'>),
nor any of the extra handlers you may have specified with a C<'handlers'>
option when loading Lexical::Failure.

Did you perhaps misspell the handler name?


=item C<< Unknown default failure handler: %s >>

When loading Lexical::Failure, you specified a default handler for all
scopes like so:

    use Lexical::Failure  default => 'SOME_STRING';

However, the string you specified did not match the name of any of the
standard handlers (C<'confess'>, C<'croak'>, C<'die'>, C<'failobj'>,
C<'undef'>, or C<'null'>) nor the name of any handler you had specified
yourself using the C<'handlers'> option.

Did you perhaps misspell the handler name?


=item C<< Can't call ON_FAILURE after compilation >>

Lexical failure handlers must be specified at compile-time
(usually in your module's C<import()> subroutine).
However, you called C<ON_FAILURE> at runtime.

Move the call into your module's C<import()>, or into some
other subroutine that C<import()> calls.

=item C<< Can't call ON_FAILURE outside a subroutine >>

You probably attempted to set up a lexical handler at the 
top level of your module's source code. For example:

    package Your::Module;

    use Lexical::Failure;
    ON_FAILURE('die');

The lexical hinting mechanism that Lexical::Failure uses only
works when C<ON_FAILURE> is called from within your module's
C<import()> subroutine (or from a subroutine that C<import()>
itself calls).

To achieve the "set a default handler for my module" effect
intended in the previous example, rewrite it either as:

    package Your::Module;

    use Lexical::Failure;
    sub import { ON_FAILURE('die'); }

or simply:

    package Your::Module;

    use Lexical::Failure default => 'die';


=item C<< Missing rename for %s >>

You tried to rename either C<fail> or C<ON_FAILURE> as part of your
C<use Lexical::Failure> call, but forgot to include the new name for the
subroutine (i.e. you left out the argument expected after C<'fail'> or
C<'ON_FAILURE'>).


=item C<< Missing specification for %s >>

You tried to specify either the C<'default'> or C<'handlers'> option as
part of your C<use Lexical::Failure> call, but forgot to include the
corresponding default value or handlers hash (i.e. you left out the
argument expected after C<'default'> or C<'handlers'>).


=item C<< Value for %s option must be a %s >>

You passed a I<keyword> C<< => >> I<value> pair to C<use Lexical::Failure>,
but the value was of the wrong type for that particular keyword. See
L<"Changing the names of the API keywords"> or L<"Specifying a module's
default failure handler"> or L<"Specifying additional named failure
handlers"> for the correct usage.


=item C<< Handlers in 'handlers' hash must all be code references >>

The C<'handlers'> option to C<use Lexical::Failure> expects a reference
to a hash in which each value is a code reference. At least one of the
values in the hash you passed was something else.


=item C<< Unexpected argument (%s) >>

C<use Lexical::Failure> accepts only four arguments:

    use Lexical::Failure (
        fail       => $NEW_NAME,
        ON_FAILURE => $NEW_NAME,
        default    => $HANDLER_NAME,
        handlers   => \%HANDLER_HASH,
    );

You attempted to pass it something else. Or perhaps you misspelled
one of the above keywords?

=item C<< Invalid handler type (%s) in call to ON_FAILURE >>

The argument passed to C<ON_FAILURE> must be either a string
(i.e. the name of a named handler) or a reference to a subroutine
(i.e. the handler itself) or a reference to a variable (i.e.
the lvalue into which error messages are to be assigned).

You passed it something else (probably a regex or a reference to a
reference).

=back

=head1 CONFIGURATION AND ENVIRONMENT

Lexical::Failure requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires the modules:
L<Scope::Upper>,
L<Keyword::Simple>,
L<PadWalker>, and
L<Test::Effects>.

Also requires the L<Lexical::Failure::Objects> helper module
included in its distribution.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-lexical-failure@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

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
