package Devel::TraceCalls;

=head1 NAME

Devel::TraceCalls - Track calls to subs, classes and object instances

=head1 SYNOPSIS

  ## From the command line
    perl -d:TraceCalls=Subs,foo,bar script.pl

  ## Quick & dirty via use
    use Devel::TraceCalls { Package => "Foo" };

  ## Procedural
    use Devel::TraceCalls;

    trace_calls qw( foo bar Foo::bar ); ## Explicitly named subs

    trace_calls {
         Subs => [qw( foo bar Foo::bar )],
        ...options...
    };

    trace_calls {
        Package => "Foo",        ## All subs in this package
        ...options...
    };

    trace_calls {         ## Just these subs
        Package => "Foo",        ## Optional
        Subs    => qw( foo, bar ),
        ...options...
    };

    trace_calls $object;  ## Just track this instance

    trace_calls {
        Objects => [ $obj1, $obj2 ];  ## Just track these instances
        ...options...
    };

    ... time passes, sub calls happen ...

    my @calls = $t1->calls;  ## retrieve what happned

  ## Object orented
    my $t = Devel::TraceCalls->new( ...parameters... );

    undef $t;  ## disable tracing

  ## Emitting additional messages:
    use Devel::TraceCalls qw( emit_trace_message );

    emit_trace_message( "ouch!" );

=head1 DESCRIPTION

B<ALPHA CODE ALERT.  This module may change before "official" release">.

Devel::TraceCalls allows subroutine calls to be tracked on a per-subroutine,
per-package, per-class, or per object instance basis.  This can be quite useful
when trying to figure out how some poor thing is being misused in a program you
don't fully understand.

Devel::TraceCalls works on subroutines and classes by installing wrapper
subroutines and on objects by temporarily reblessing the objects in to
specialized subclasses with "shim" methods.  Such objects are reblessed back
when the tracker is DESTROYed.

The default action is to log the calls to STDERR.  Passing in a C<PreCall>, or
C<PostCall> options disables this default behavior, you can reenable it
by manually setting C<<LogTo => \*STDERR>>.

There are 4 ways to specify what to trace.

=over

=item 1

By Explicit Sub Name

    trace_calls "foo", "bar";   ## trace to STDOUT.
    
    trace_calls {
        Subs => [ "foo", "bar" ],
        ...options...
    };

The first form enables tracking with all Capture options enabled (other than
CaptureSelf which has no effect when capturing plain subs).  The second allows
you to control the options.

=item 2

By Package Name

    trace_calls {
        Package => "My::Module",
        ...options...
    };

    # Multiple package names
    trace_calls {
        Package => [ "My::Module", "Another::Module" ],
        ...options...
    };

    trace_calls {
        Package => "My::Module",
        Subs    => [ "foo", "bar" ],
        ...options...
    };

This allows you to provide a package prefix for subroutine names
to be tracked.  If no "Subs" option is provided, all subroutines
in the package will be tracked.

This does not examine @ISA like the C<Class> and C<Objects> (covered
next) techniques do.

=item 3

By Class Name

    trace_calls {
        Class => "My::Class",
        ...options...
    };

    trace_calls {
        Class => "My::Class",
        ...options...
    };

    trace_calls {
        Class => "My::Class",
        Subs  => [ "foo", "bar" ],
        ...options...
    };

This allows tracking of method calls (or things that look like method
calls) for a class and it's base classes.  The $self ($_[0]) will not be
captured in C<Args> (see L</Data Capture Format>), but may be captured
in C<Self> if C<CaptureSelf> is enabled.

C<Devel::TraceCalls> can't differentiate between C<$obj->foo( ... )> and
C<foo( $obj, ... )>, which can lead to extra calls being tracked if the
latter form is used.  The good news is that this means that idioms like:

    $meth = $obj->can( "foo" );
    $meth->( $obj, ... ) if $meth;

are captured.

If a C<Subs> parameter is provided, only the named methods will be
tracked.  Otherwise all subs in the class and in all parent classes are
tracked.

=item 3

By Object Instance

    trace_calls $obj1, $obj2;

    trace_calls {
        Objects => [ $obj1, $obj2 ],
        ...options...
    };

    trace_calls {
        Objects => [ $obj1, $obj2 ],
        Subs    => [ "foo", "bar" ],
        ...options...
    };

This allows tracking of method calls (or things that look like method
calls) for specific instances.  The $self ($_[0]) will not be captured
in C<Args>, but may be captured in Self if CaptureSelf is enabled.

The first form (C<track $obj, ...>) enables all capture options,
including CaptureSelf.

=back

=head2 Emitting messages if and only if Devel::TraceCalls is loaded

    use constant _tracing => defined $Devel::TraceCalls::VERSION;

    BEGIN {
        eval "use Devel::TraceCalls qw( emit_trace_message )"
            if _tracing;
    }

    emit_trace_message( "hi!" ) if _tracing;

Using the constant C<_tracing> allows expressions like

    emit_trace_message(...) if _tracing;

to be optimized away at compile time, resulting in little or
no performance penalty.

=head1 OPTIONS

there are several options that may be passed in the HASH ref style
parameters in addition to the C<Package>, C<Subs>, C<Objects> and
C<Class> settings covered above.

=over

=item LogTo

    LogTo => \*FOO,
    LogTo => \@array,
    LogTo => undef,

Setting this to a filehandle causes tracing messages to be emitted to
that filehandle.  This is set to STDERR by default if no PreCall or
PostCall intercepts are given.  It may be set to undef to suppress
tracing if you need to.

Setting this to an ARRAY reference allows call data to be captured,
see below for more details.

=item LogFormatter

This is not supported yet, the API will be changing.

But, it allows you some small control over how the parameters list
gets traced when LogTo points to a filehandle.

=item ShowStack

Setting this causes the call stack to be logged.

=item PreCall

    PreCall => \&sub_to_call_before_calling_the_target,

A reference to a subroutine to call before calling the target sub.  This
will be passed a reference to the data captured before the call and
a reference to the options passed in when defining the trace point
(this does not contain the C<Package>, C<Subs>, C<Objects> and
C<Class> settings.

The parameters are:

    ( $trace_point, $captured_data, $params )

=item PostCall

    PreCall => \&sub_to_call_after_calling_the_target,

    ( $trace_point, $captured_data, $params )

A reference to a subroutine to call after calling the target sub.  This
will be passed a reference to the data captured before and after the call and
a reference to the options passed in when defining the trace point
(this does not contain the C<Package>, C<Subs>, C<Objects> and
C<Class> settings.

The parameters are:

    ( $trace_point, $captured_data, $params )

=item Wrapper

B<TODO>

    Wrapper => \&sub_to_delegate_the_target_call_to,

A reference to a subroutine that will be called instead of calling
the target sub.  The parameters are:

    ( $code_ref, $trace_point, $captured_data, $params )

=item Data Capture Options

These options affect the data captured in the C<Calls> array (see L</The
Calls ARRAY>) and passed to the C<PreCall> and C<PostCall> handlers.

Options may be added to the hash refs passed to C<trace_calls>.  Here are
the options and their default values (all defaults chosen to minimize
overhead):

    CaptureStack       => 0,
    CaptureCallTimes   => 0,
    CaptureReturnTimes => 0,
    CaptureSelf        => 0,
    CaptureArgs  => 0,
    CaptureResult      => 0,

    CaptureAll         => 0,  ## Shorthand for setting all of the others

Is CaptureStack is true, the

    StackCaptureDepth => 1_000_000,

option controls the maximum number of stack frames that will be captured.
Set this to "1" to capture just a single stack frame (equiv. to caller 0).

=back

=head1 Captured Data Format

The LogTo option can be used to log all data to an array instead of
to a filehandle by passing it an array reference:

    LogTo => \@data,

When passing in an array to capture call data (by using the C<Calls>
option), the elements will look like:

    {
        Name       => "SubName",
        Self       => "$obj",
        CallTime   => $seconds,  ## A float if Time::HiRes installed
        ReturnTime => $seconds,  ## A float if Time::HiRes installed
        TraceDepth => $count,    ## How deeply nested the trace is.
        WantArray  => $wantarray_result,
        Result     => [ "c" ],   ## Dumped with Data::Dumper, if need be
        Exception  => "$@",
        Args       => [
            "foo",               ## A scalar was passed
            "{ a => 'b' }",      ## A HASH (dumped with Data::Dumper)
            ...
        ],
        Stack      => [
            [ ... ],             ## Results of caller(0).
            ....                 ## More frames if requested
        ],
    }

NOTE: Many of these fields are optional and off by default.  See
the L</OPTIONS> section for details.  Tracing (via the C<LogTo>
parameter) enables several Capture options regardless of the
passed-in settings.

C<Result> is an array of 0 or more elements.  It will always be empty if
the sub was called in void context ( WantArray => undef ).

Note that C<Self>, C<Args> and C<Result> are converted to strings
to avoid keeping references that might prevent things from being
destroyed in a timely manner.  Data::Dumper is used for C<Args> and
Result, plain stringification is used for Self.

=cut

$VERSION = 0.04;

@ISA = qw( Exporter );
@EXPORT = qw( trace_calls );
%EXPORT_TAGS = ( all => \@EXPORT );

use strict;
use Exporter;

use Carp ();
use Data::Dumper;
use UNIVERSAL;

sub debugging() { 0 }
sub debugging_caller() { 0 }

BEGIN { eval "use Time::HiRes qw( time )" }

my @trace_after_compile;
CHECK {
    return unless @trace_after_compile;
    trace_calls( @trace_after_compile );
}

##
## Camouflage the call stack., kinda like Sub::Uplevel
##
## When reading this, it helps to see a "raw" call stack:
##
## +------+-----------------+----------------------------+----+----------------------------+-----+---------+---------+----------+-----+------------+
## |height|package          |file                        |line|subroutine                  |has  |wantarray|eval text|is_require|hints|bitmask     |
## |      |                 |                            |    |                            |args |         |         |          |     |            |
## |0     |main             |(eval 3)                    |9   |Devel::TraceCalls::__ANON__ |1    |0        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |1     |Devel::TraceCalls|blib/lib/Devel/TraceCalls.pm|529 |main::stack                 |1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |2     |Devel::TraceCalls|blib/lib/Devel/TraceCalls.pm|529 |(eval)                      |0    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |3     |Devel::TraceCalls|(eval 5)                    |2   |Devel::TraceCalls::_call_sub|1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |4     |main             |(eval 3)                    |32  |Devel::TraceCalls::__ANON__ |1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |5     |Devel::TraceCalls|blib/lib/Devel/TraceCalls.pm|529 |main::dive                  |1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |6     |Devel::TraceCalls|blib/lib/Devel/TraceCalls.pm|529 |(eval)                      |0    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |7     |Devel::TraceCalls|(eval 4)                    |2   |Devel::TraceCalls::_call_sub|1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |8     |main             |(eval 3)                    |32  |Devel::TraceCalls::__ANON__ |1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |9     |Devel::TraceCalls|blib/lib/Devel/TraceCalls.pm|529 |main::dive                  |1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |10    |Devel::TraceCalls|blib/lib/Devel/TraceCalls.pm|529 |(eval)                      |0    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |11    |Devel::TraceCalls|(eval 4)                    |2   |Devel::TraceCalls::_call_sub|1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |12    |main             |(eval 3)                    |32  |Devel::TraceCalls::__ANON__ |1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |13    |Devel::TraceCalls|blib/lib/Devel/TraceCalls.pm|529 |main::dive                  |1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |14    |Devel::TraceCalls|blib/lib/Devel/TraceCalls.pm|529 |(eval)                      |0    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |15    |Devel::TraceCalls|(eval 4)                    |2   |Devel::TraceCalls::_call_sub|1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |16    |main             |t/caller.t                  |79  |Devel::TraceCalls::__ANON__ |1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |17    |main             |t/caller.t                  |96  |main::check_stack           |1    |1        |<<undef>>|<<undef>> |0    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |18    |main             |t/caller.t                  |96  |main::BEGIN                 |1    |0        |<<undef>>|<<undef>> |2    |^@^@^@^@^@^@^@^@^@^@^@^@|
## |19    |main             |t/caller.t                  |96  |(eval)                      |0    |0        |<<undef>>|<<undef>> |2    |^@^@^@^@^@^@^@^@^@^@^@^@|
## +------+-----------------+----------------------------+----+----------------------------+-----+---------+---------+----------+-----+------------+
##
## Not sure why the Devel::TraceCalls::__ANON__ is showing up in column 3, but
## there's extra logic below to deal with it.  Sub::Uplevel does not have this
## issue.
##

use vars qw( $show_all );

sub carp   { local $show_all = 1; &Carp::carp    }
sub croak  { local $show_all = 1; &Carp::croak   }
sub confess{ local $show_all = 1; &Carp::confess }
sub cluck  { local $show_all = 1; &Carp::cluck   }

my %hide_packages;

=item hide_package

    Devel::TraceCalls::hide_package;
    Devel::TraceCalls::hide_package $pkg;

Tells Deve::TraceCalls to ignore stack frames with caller eq $pkg.
The caller's package is used by default.  This is useful when overloading
require().

=cut

sub hide_package {
    my $pkg = @_ ? shift : caller;
    ++$hide_packages{$pkg};
}

=item unhide_package

    Devel::TraceCalls::unhide_package;
    Devel::TraceCalls::unhide_package $pkg;

Undoes the last hide_package.  These calls nest, so

    Devel::TraceCalls::hide_package;
    Devel::TraceCalls::hide_package;
    Devel::TraceCalls::unhide_package;

leaves the caller's package hidden.

=cut

sub unhide_package {
    my $pkg = @_ ? shift : caller;
    --$hide_packages{$pkg} if $hide_packages{$pkg};
}

hide_package;

BEGIN {
    use vars qw( $in_caller );

    *CORE::GLOBAL::caller = sub {
        if ( $in_caller ) {
            ## This is only needed when something called in here
            ## (Text::Formatter when I break it, for instance) call caller.
            warn "Not recursing in caller()";
            return ();
        }

        local $in_caller = 1;
        my $d = $_[0] || 0;
        my @rows;

        if ( debugging_caller ) {
            my $j= 0;
            while (1) {
                my @d = CORE::caller $j ;
                last unless @d ;
                push @rows, [ "", "xxx", map defined $_ ? $_ : "<<undef>>", $j, @d ];
                ++$j;
            }
        }

        $rows[0]->[0] = "---"
            if debugging_caller;

        my $i = 1;
        my $h = 0;
        my @caller;
        my $callee;

        warn "hide_packages = (", join( ", ", keys %hide_packages ), ")\n"
            if debugging_caller;

        while ( $h <= $d ) {
            my @c = CORE::caller $i;

            unless ( @c ) {
                @caller = @c;
                last;
            }

            if ( @c && exists $hide_packages{$c[0]} && ! $show_all ) {
                ## We need to set the fields in @caller that refer to the callee
                ## and not count this frame.
                $callee = $c[3] unless defined $callee;
                $rows[$i]->[0] = "---"
                    if debugging_caller;
            }
            else {
                ## We need to return this frame verbatim
                @caller = @c;
                if ( @caller && defined $callee ) {
                    $caller[3] = $callee;
                    $callee = undef;
                }
                ++$h;
            }
            $rows[$i]->[1] = $d
                if debugging_caller;
            ++$i;
        }

        if ( debugging_caller ) {
            require Text::FormatTable;
            my $t = Text::FormatTable->new( "|l|r|r|l|l|r|l|r|r|l|r|r|r|");
            $t->rule( "-" );
            $t->head( "del", "eff_height", "height", "package", "file", "line", "subroutine", "has_args", "wantarray", "eval_text", "is_require", "hints", "bitmask" );
            $t->rule( "-" );
            $t->row( @$_ ) for @rows;
            $t->rule( "-" );
            warn $t->render;
        }

        ! wantarray ?         $caller[0]    ## Scalar context
                    : ! @_  ? @caller[0..2] ## list context, no args
                            : @caller;      ## list context with args
    };
}

## Being lazy about installing this sub allows other Devel:: modules to
## use this module.
use vars qw( @db_args );
my $DB_DB = <<'DB_DB_END';
my $initted;

sub DB::DB {
    return if $initted;
    $initted = 1;

    ## TODO: correct this message.
    die qq{No parameters passed to -d.  Need something like "-d:TraceCalls { Subs => [qw(...)] }" (including the quotes)\n}
        unless @db_args;
    trace_calls( @db_args );
}
DB_DB_END


sub import {
    my $self = shift;
    ## line 0 seems to indicate that we're in -M or -D land.
    if ( ! (caller(0))[2] ) {
        push @db_args, @_;
        eval $DB_DB if $DB_DB;
        undef $DB_DB;
        return;
    }

    @_ = (
        $self,
        grep {
            my $is_ref = ref;
            push @trace_after_compile, {
                     exists $_->{Subs}
                && ! exists $_->{Package}
                && ! exists $_->{Class}
                && ! exists $_->{Objects}
                    ? ( Package => scalar caller )
                    : (),
                %$_,
            } if $is_ref;
            $is_ref ? () : $_;
        } @_
    );

    goto &Exporter::import;
}

=head1 Showing skipped traces

Sometimes it's nice to see what you're missing.  This can be helpful
if you want to be sure that all the methods of a class are being
logged for all instance, for instance.

Set the environment variable C<SHOWSKIPPED> to "yes" or calling
C<show_skipped_trace_points> to enable or disable this.

To enable:

    Devel::TraceCalls::set_show_skipped_trace_points;
    Devel::TraceCalls::set_show_skipped_trace_points( 1 );

To disable:

    Devel::TraceCalls::set_show_skipped_trace_points( 0 );

Calling the subroutine overrides the environment variable.

=cut

my $show_skipped_trace_points = $ENV{SHOWSKIPPED};

sub set_show_skipped_trace_points {
    $show_skipped_trace_points = @_ ? shift : 1;
}

=head1 Showing the call stack

To show the call stack in the log at each trace point, set the environment
variable C<SHOWSTACK> to "yes" or calling C<show_stack> to enable or
disable this.

To enable:

    Devel::TraceCalls::set_show_stack;
    Devel::TraceCalls::set_show_stack( 1 );

To disable:

    Devel::TraceCalls::set_show_stack( 0 );

Calling the subroutine overrides the environment variable.

=cut

my $show_stack = $ENV{SHOWSTACK};


## This is not documented or supported, it needs to be made better,
## 'My::Class::Name' should be made to look like \(My::Class::Name)
## or something and the depth at which it kicks in needs to be
## controllable.
my $stringify_blessed_refs = $ENV{STRINGIFY};

sub set_stringify_blessed_refs {
    $stringify_blessed_refs = @_ ? shift : 1;
}

my %builtin_types = map { ( $_ => undef ) } qw(
    SCALAR
    ARRAY
    Regexp
    REF
    HASH
    CODE
);

sub _stringify_blessed_refs {
    my $s = shift;
    my $type = ref $s;

    return $s if ! $type || $type eq "Regexp" ;

    if ( $type eq "HASH" ) {
        $s = {
            map {
                ( $_  => _stringify_blessed_refs( $s->{$_} ) );
            } keys %$s
        };
    }
    elsif ( $type eq "ARRAY" ) {
        $s = [ map _stringify_blessed_refs( $_ ), @$s ];
    }
    elsif( $type eq "Regexp" ) {
        $s = "$s";
    }
    elsif ( !exists $builtin_types{$type} ) {
        ## A blessed ref...
        $s = $type;
    }

    return $s;
}


##
## %trace_points is the master registry of all active trace points.
##
## It is keyed on sub name and contains / refers to HASHes that
## contain the Name and Ref of the original subroutine (for logging and
## calling purposes, respectively) and an ARRAY of all of the trace points
## active for that subroutine.
## 
my %trace_points;

##
## This is the wrapper subroutine used when tracing a sub or a class's methods.
## It's not used when tracing an object instance, see below for that.
##
use vars qw( $nesting_level );
$nesting_level = 0;

sub _call_sub {
    my $sub_id = shift;

    my $context = wantarray;
    my @result;

    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Quotekeys = 0;

    ## use local on this one just in case some exception happens,
    ## or an "exiting subroutine via next" kinda thing.
    local $nesting_level = $nesting_level + 1;

confess unless defined $trace_points{$sub_id}->{TracePoints};

    my $sub_name     = $trace_points{$sub_id}->{Name};
    my $sub_ref      = $trace_points{$sub_id}->{Ref};
    my @trace_points = @{$trace_points{$sub_id}->{TracePoints}};
    my @r;

    warn "tracing $sub_name\n" if debugging;

    my $record_call_time;
    my $record_return_time;

    my $log_formatter;

    my @tps = grep {
        my $is_instance_method = exists $_->{_TraceInstance};
        my $is_class_method    = exists $_->{_TraceClasses};

        ( ! $is_instance_method || @_ && $_->{_TraceInstance} == $_[0] )
        && ( ! $is_class_method
            || ( @_
                && grep UNIVERSAL::isa( $_[0], $_ ), keys %{$_->{_TraceClasses}}
            )
        );
    } @trace_points;


    if ( ! @tps && $show_skipped_trace_points ) {
        ## Sometimes it's nice to see what you're missing
        push @tps, {
            _Signature => "MISSING",
            LogTo      => \*STDERR,
        };
    }

    my %master_r = (
        Name         => $sub_name,
        TraceDepth   => $nesting_level,
        WantArray    => $context,
    );

    my %log_to;
    my $params_cache;

    --$nesting_level unless @tps;

    for my $tp ( @tps ) {
        my %r = %master_r;

        warn "...to tracepoint $tp->{_Signature}\n"
            if debugging;

        my $is_method = exists $tp->{_TraceInstance}
            || exists $tp->{_TraceClasses};

        $r{LooksLikeAMethod} = $is_method;

        $record_call_time   ||= $tp->{CaptureCallTime};
        $record_return_time ||= $tp->{CaptureReturnTime};

        $r{Args} = [
            @{
                $params_cache ||= [
                    map {
                        my $d = Dumper(
                            $stringify_blessed_refs
                                ? _stringify_blessed_refs $_
                                : $_
                        );
                        chomp $d;
                        $d;
                    } $is_method
                        ? @_[1..$#_]
                        : @_
                ]
            }
        ] if $tp->{CaptureArgs} || $tp->{LogTo};

        $r{Self} = "$_[0]"
            if $is_method && ( $tp->{CaptureSelf} || $tp->{LogTo} ) ;

        ## Doing this for each $r instead of caching them for a couple
        ## of reasons: code simplicity, multiple traces on a func should
        ## be rare, and we'd need to copy them anyway to give each $r it's
        ## own copy so that changing one can't change the others, and
        ## different trace points can go to different stack depths.
        if ( $tp->{CaptureStack} || $tp->{ShowStack} || $show_stack ) {
            for ( 1..( $tp->{StackCaptureDepth} || 1_000_000 ) ) {
                my @c = caller( $_ );
                last unless @c;
                push @{$r{Stack}}, \@c;
            }
        }

        push @r, \%r;

        $tp->{PreCall}->( \%r, \@_ ) if $tp->{PreCall};

        ##
        ## Logging
        ##
        if ( $tp->{LogTo} ) {
            if ( ref $tp->{LogTo} eq "ARRAY" ) {
                push @{$tp->{LogTo}}, \%r;
            }
            else {
                my $msg;
                $msg = $tp->{LogFormatter}->( $tp, \%r, \@_ )
                    if $tp->{LogFormatter};

                my %l;
                if ( ref $msg eq "HASH" ) {
                    %l = %$msg;
                    $msg = undef;
                }

                if ( ! defined $msg ) {
                    ## Shorten the subname if possible
                    my $sub_name = $r{Name};
                    if ( $r{LooksLikeAMethod} ) {
                        my $object_id = $r{Self};
                        my $sub_name_prefix = $sub_name;
                        $sub_name_prefix =~ s/::[^:]*$//;
                        if (   length( $object_id ) > length( $sub_name_prefix )
                            && index( $object_id, $sub_name_prefix ) == 0
                        ) {
                            $sub_name =~ s/.*://;
                        }
                    }

                    $l{Object} =
                        exists $tp->{ObjectId} && defined $tp->{ObjectId}
                            ? $tp->{ObjectId} . "->"
                            : $r{Self} . "->"
                        if ! defined $l{Object} && $r{LooksLikeAMethod};

                    $l{Sub} = $sub_name
                        if ! defined $l{Sub};

                    if ( ! defined $l{Args} ) {
                        ## get the dumped args list out of %r
                        $l{Args} = $r{Args};
                    }
                    elsif ( ref $l{Args} ) {
                        ## dump it, just like $r{Args} was.
                        $l{Args} = [
                            map {
                                my $d = Dumper( $_ );
                                chomp $d;
                                $d;
                            } $is_method
                                ? @{$l{Args}}[1..$#{$l{Args}}]
                                : @{$l{Args}}
                        ];
                    }

                    $l{Args} = join( "",
                        "(",
                        @{$l{Args}} ? " " : (),
                        join( ", ", @{$l{Args}} ),
                        @{$l{Args}} ? " " : (),
                        ")",
                    ) if ref $l{Args};

                    $msg = join( "",
                        $l{Prefix} || "",
                        $l{Object} || "",
                        $l{Sub}    || "",
                        $l{Args}   || "",
                        $l{Suffix} || "",
                    );
                }

                chomp $msg;
                $msg .= "\n";

                if ( $tp->{ShowStack} || $show_stack ) {
                    $msg .= join( "",
                        map(
                            join( " ",
                                $_->[3],
                                "at",
                                $_->[1],
                                "line",
                                $_->[2],
                            ) . "\n",
                            @{$r{Stack}}
                        )
                    );
                }

                my $indent = "| ! " x ( ( $r{TraceDepth} - 1 ) >> 1 );
                $indent .= "| " if ( $r{TraceDepth} - 1 ) & 1;

                $msg =~ s{(.)^}{
                    $1 . "     : $indent|   "
                }gmes;

                $indent =~ s/..$/+-/;

                my $dest = $tp->{LogTo};
                print $dest join( "",
                    "TRACE: ",
                    $indent,
                    $msg
                );

                $tp->{_LogInfo} = \%l;
            }
        }
    }

    ## Using the &$ref form here on the off chance it might
    ## avoid the subroutine prototypes
    my $call_time;
    my $return_time;
    my $no_exception;
    if ( $context ) {
        $call_time = time if $record_call_time;
        eval { @result = &$sub_ref( @_ ); $no_exception = 1 };
        $return_time = time if $record_return_time;
    }
    elsif ( defined $context ) {
        $call_time = time if $record_call_time;
        eval { $result[0] = &$sub_ref( @_ ); $no_exception = 1 };
        $return_time = time if $record_return_time;
    }
    else {
        $call_time = time if $record_call_time;
        ## DON'T BREAK THE VOID CONTEXT IF YOU EDIT THIS.
        eval { &$sub_ref( @_ ); $no_exception = 1 };
        $return_time = time if $record_return_time;
    }
    my $exception;
    $exception = $@ unless $no_exception;

    for my $tp ( reverse @tps ) {
        my $r = pop @r;
        $r->{CallTime}   = $call_time    if defined $call_time;
        $r->{ReturnTime} = $return_time  if defined $return_time;
        $r->{Exception}  = $exception;
        ## See comment above about build the call stack each time through
        ## instead of caching it.
        $r->{Result} = [
            map ref $_ ? Dumper( $_ ) : $_, @result
        ];
        $tp->{PostCall}->( $r, \@_ ) if $tp->{PostCall};
        $r->{Exception}  = "$exception" if defined $exception;

        if ( $exception && $tp->{LogTo} && ref $tp->{LogTo} ne "ARRAY" ) {
            my $l = $tp->{_LogInfo};

            my $msg = join( "",
                "EXCEPTION:",
                $l->{Prefix} || "",
                $l->{Object},
                $l->{Sub},
                " threw: ",
                $exception
            );
            
            chomp $msg;
            $msg .= "\n";

            $msg =~ s{(.)^}{
                $1 . "     :" . "  " x ( $r->{TraceDepth} - 1 ) . "    "
            }gmes;

            my $dest = $tp->{LogTo};
            print $dest join( "",
                "TRACE: ",
                "  " x ( $r->{TraceDepth} - 1 ),
                $msg
            );

        }

        delete $tp->{_LogInfo};
    }

    die $exception if $exception;
    return $context ? @result : $result[0];
};


sub _intercept_sub {
    my ( $name, $proto, $sub_id ) = @_;
    $proto = defined $proto ? "($proto)" : "";
    $sub_id = $name unless defined $sub_id;
die if $name =~ /^Devel::TraceCalls/;
cluck if grep ! defined, $proto, $sub_id;
    return <<INTERCEPT_END;
        sub $proto {
            Devel::TraceCalls::_call_sub( "$sub_id", \@_ ) ;
        }
INTERCEPT_END
}

sub _get_named_subs {
    my %options = %{pop()};

    my $package = $options{Package};

    delete $options{Package};
    delete $options{Subs};
    delete $options{Objects};
    delete $options{Class};

    return map {
        my $name = index( $_, ":" ) >= 0 ? $_ : "${package}::$_";
        my $ref = do {
            no strict "refs";
            defined &$name? \&$name: undef;
        };
        $ref
            ? {
                %options,  ## first in case a "Name" or Ref sneaks in, say.
                Name       => $name,
                Ref        => $ref,
                _Signature => "sub $name",
            }
            : "Subroutine $name not defined";
    } @_;
}


sub _get_methods {
    ## Traipses through @ISA hierarchy.
    my $package = shift;
    my $orig_options = pop;

cluck Dumper $orig_options unless defined $orig_options;

    my $options = { %$orig_options };

    $package = $options->{Package} unless defined $package;
    confess "undef package" unless defined $package;

    my $pattern = delete $options->{_Pattern};

    delete $options->{Subs};
    delete $options->{Package};
    delete $options->{Objects};
    delete $options->{Class};

    no strict "refs";
    return (
        map(
            ! defined $pattern || $_ =~ $pattern
                ? {
                    %$options,
                    _Signature => $options->{_Signature} . "->sub $_",
                    Name       => $_,
                    Ref        => \&$_,
                }
                : (),
            grep
                defined &$_,
                map "${package}::$_",
                    keys %{"${package}::"}
        ),
        map( _get_methods( $_, $orig_options ),
#            grep $_ ne "Exporter",
               @{"${package}::ISA"} ),
    ) ;
}


my $tracer;
sub trace_calls {
    my $caller = caller;
    $tracer ||= __PACKAGE__->new;
    $tracer->add_trace_points(
        map {
            ref $_
                ? ( exists $_->{Subs}
                    && ! exists $_->{Package}
                    && ! exists $_->{Objects}
                    && ! exists $_->{Class}
                )
                    ? { Package => $caller, %$_ }
                    : $_
                : /(.*)::$/
                    ? { Package => $1 }
                : /(.*)->$/
                    ? { Class   => $1 }
                : { Package => $caller, Subs => [ $_ ] }
        } @_
    );
}

my $devel_trace_calls_pkg_re = "^" . __PACKAGE__;
$devel_trace_calls_pkg_re = qr/$devel_trace_calls_pkg_re/;

sub emit_trace_message {
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Quotekeys = 0;

    ## use local on this one just in case some exception happens,
    ## or an "exiting subroutine via next" kinda thing.

    my $msg = join "", map {
        my $d = ref()
            ? Dumper(
                $stringify_blessed_refs
                    ? _stringify_blessed_refs $_
                    : $_
            )
            : $_;
        chomp $d;
        $d;
    } @_;

    chomp $msg;
    $msg .= "\n";

    my $indent = "| ! " x ( $nesting_level >> 1 );
    $indent .= "| " if $nesting_level & 1;

    $msg =~ s{(.)^}{
        $1 . "     : $indent|   "
    }gmes;

    $indent =~ s/..$/+=/;

    ## TODO: allow log formatting and emission to custom trace destinations.
    print STDERR "TRACE: ", $indent, $msg;
};

=head1 OO API

The object oriented interface provides for more flexible than the other
APIs.  A tracer will remove all of it's trace points when it is deleted
and you can add (and someday, remove) trace points from a running
tracer.

Someday you'll also be able to enable and disable tracers.

=over

=item new

    my $t = Devel::TraceCalls->new(
        ... any params you might pass to trace_calls...
    );

=cut

sub new {
    my $self = do {
        my $proto = shift;
        my $class = ref $proto || $proto;
        bless {}, $class;
    };
    $self->add_trace_points( @_ );
    return $self;
}

=item add_trace_points

    $t->add_trace_points( 
        ...any params you might pass to trace_calls...
    );

Add trace points to an existing tracer.  Trace points for subs that
already have trace points will be ignored (we can add an option to
enable this; send me a patch or contact me if need be).

=cut

## Class trace points are oddballs.  We need to attach multiple class objects
## to a class trace point so the trace point will fire for any class it
## exists in.

sub add_trace_points {
    my $self = shift;

    my $package = caller;

    ##
    ## Parse the parameters
    ##
    my @trace_points;
    my @objects;
    my @errors;
    for my $parm (@_ ) {
        if ( ! ref $parm ) {
            ## It's the name of a subroutine
            push @trace_points, _get_named_subs $parm, {
                Package            => $package,
                CaptureCallTime    => 1,
                CaptureReturnTime  => 1,
                CaptureArgs        => 1,
                CaptureResult      => 1,
                CaptureStack       => 1,
            };
        }
        elsif ( ref $parm eq "HASH" ) {
            ## It's a HASH of options
            if ( exists $parm->{Package} ) {
                ## It's a package trace request
                unless ( defined $parm->{Package} ) {
                    push @errors, "Undefined Package parameter";
                    next;
                }

                if ( exists $parm->{Subs} ) {
                    unless ( defined $parm->{Subs} ) {
                        push @errors, "Undefined Subs parameter";
                        next;
                    }
                    unless ( ref $parm->{Subs} eq "ARRAY" ) {
                        push @errors,
                            "Subs parameter must be an ARRAY, not '$parm->{Subs}'";
                        next;
                    }
                    push @trace_points, _get_named_subs @{$parm->{Subs}}, $parm;
                }
                else {
                    my $p = $parm->{Package};
                    ## We don't want to look at @ISA, so grab the sub
                    ## names manually instead of calling _get_methods
                    no strict "refs";
                    my @sub_names;
                    my @packages = $p;
                    @packages = @$p if ref $p eq 'ARRAY';

                    for my $pkg (@packages)
                    {
                        @sub_names = grep
                            defined &$_,
                            map "${pkg}::$_",
                                keys %{"${pkg}::"};
                        push @trace_points, _get_named_subs @sub_names, $parm;
                    }
                }
            }
            elsif ( exists $parm->{Class} ) {
                unless ( defined $parm->{Class} ) {
                    push @errors, "Undefined Class parameter";
                    next;
                }

                my $pat;
                if ( exists $parm->{Subs} ) {
                    unless ( defined $parm->{Subs} ) {
                        push @errors, "Undefined Subs parameter";
                        next;
                    }
                    unless ( ref $parm->{Subs} eq "ARRAY" ) {
                        push @errors,
                            "Subs parameter must be an ARRAY, not '$parm->{Subs}'";
                        next;
                    }

                    ## Throw away unwanted methods
                    $pat = join
                        "|",
                        map(
                            ( /:/ ? "^$_" : $_ ) . "(?!\n)\$",
                            @{$parm->{Subs}}
                        );
                }

                ## All class subs use a single trace point with
                ## possibly multiple _TraceClasses, so the signature
                ## is set to indicate that it's a class trace point and
                ## the sub name is left to differentiate it.  We
                ## decode these signals below where the trace points are
                ## actually set.
                push @trace_points, _get_methods
                    $parm->{Class},
                    {
                        %$parm,
                        _Pattern    => $pat,
                        _TraceClass => $parm->{Class},
                        _Signature  => "(class)",
                    };
            }
            elsif ( exists $parm->{Objects} ) {
                unless ( defined $parm->{Objects} ) {
                    push @errors, "Undefined Objects parameter";
                    next;
                }
                unless ( ref $parm->{Objects} eq "ARRAY" ) {
                    push @errors,
                        "Object parameter must be an ARRAY, not '$parm->{Objects}'";
                    next;
                }

                my $pat;
                if ( exists $parm->{Subs} ) {
                    unless ( defined $parm->{Subs} ) {
                        push @errors, "Undefined Subs parameter";
                        next;
                    }
                    unless ( ref $parm->{Subs} eq "ARRAY" ) {
                        push @errors,
                            "Subs parameter must be an ARRAY, not '$parm->{Subs}'";
                        next;
                    }

                    ## Throw away unwanted methods
                    $pat = join
                        "|",
                        map(
                            ( /:/ ? "^$_" : $_ ) . "(?!\n)\$",
                            @{$parm->{Subs}}
                        );

                }
                push @trace_points, map
                    _get_methods(
                        ref $_,
                        {
                            %$parm,
                            _Pattern       => $pat,
                            _TraceInstance => int $_,
                            _Signature     => int $_,
                        }
                    ),
                    @{$parm->{Objects}};
            }
            elsif ( exists $parm->{Subs} ) {
                ## Named subs, perhaps with options.
                unless ( defined $parm->{Subs} ) {
                    push @errors, "Undefined Subs parameter";
                    next;
                }
                push @trace_points, _get_named_subs @{$parm->{Subs}}, {
                    Package => $package,
                    %$parm,
                };
            }
            else {
                push @errors,
                    "options hash does not have Package, Objects, or Subs" ;
                    next;
            }
        }
        elsif ( index( "GLOB|SCALAR|ARRAY|Regexp|REF|CODE|HASH", ref $parm )<0 ){
            ## Object instance... we hope.
            ## TODO: Improve the blessedness check :).
            push @trace_points, _get_methods
                ref $parm,
                {
                    CaptureCallTime   => 1,
                    CaptureReturnTime => 1,
                    CaptureArgs       => 1,
                    CaptureResult     => 1,
                    CaptureStack      => 1,
                    CaptureSelf       => 1,
                    _TraceInstance    => int $parm,
                    _Signature        => int $_,
                };
        }
        else {
            push @errors, "Invalid parameter '$parm'";
        }
    }

    push @errors, grep !ref, @trace_points;
    croak join "\n", @errors if @errors;

    @trace_points = map {
        my $tp = $_;
        if ( exists $tp->{CaptureAll} && $tp->{CaptureAll} ) {
            $tp->{$_} = 1 for qw(
                CaptureCallTime
                CaptureReturnTime
                CaptureArgs
                CaptureResult
                CaptureStack
                CaptureSelf
            );
        }

        $tp->{LogTo} = \*STDERR
            if ! exists $tp->{LogTo}
                && ! $tp->{PreCall}
                && ! $tp->{PostCall};

        $tp;
    } @trace_points;

    ##
    ## Install sub wrappers
    ##
    {
        for my $tp ( @trace_points ) {
            my $sub_id = $tp->{Name};
            my $sig    = $tp->{_Signature};

            confess "No signature for ", Dumper( $tp ) unless
                defined $sig and length $sig;

            ## Don't add more traces to the one we're already
            ## tracing.
            if ( exists $self->{TracePoints}->{$sig} ) {
                if ( substr( $sig, 0, 7 ) eq "(class)" ) {
                    ## Just add the _TraceClass to the existing
                    ## trace point's _TraceClasses.
                    warn "adding a tracepoint $sig (",
                        join( ", ", sort keys %$tp),
                        ") to existing _TraceClasses for $sub_id\n"
                    if debugging;

                    $self->{TracePoints}->{$sig}->{_TraceClasses}
                        ->{$tp->{_TraceClass}} = undef;
                    next;
                }

                warn(
                    "NOT adding an additional tracepoint $sig (",
                    join( ", ", sort keys %$tp),
                    ") for $sub_id)\n"
                ) if debugging;

                next;
            }

            $tp->{_TraceClasses}->{$tp->{_TraceClass}} = undef
                if exists $tp->{_TraceClass};

            if ( $sub_id =~ $devel_trace_calls_pkg_re ) {
                cluck "Can't place a trace inside ", __PACKAGE__, ", ignoring";
                next;
            }

            if ( $trace_points{$sub_id} ) {
                warn( "adding a tracepoint $sig (",
                    join( ", ", sort keys %$tp),
                    ") for $sub_id\n"
                ) if debugging;

                push @{$trace_points{$sub_id}->{TracePoints}}, $tp;
            }
            else {
confess if $sub_id =~ /^::/;
confess if $sub_id =~ /^Devel::TraceCalls/;

                warn( "creating tracepoint $sig (",
                    join( ", ", sort keys %$tp),
                    ") for $sub_id\n"
                ) if debugging;

                my $proto = prototype $tp->{Ref};

                $trace_points{$sub_id} = {
                    Name        => $sub_id,
                    Ref         => $tp->{Ref},
                    TracePoints => [ $tp ],
                };

                my $sub = eval _intercept_sub( $tp->{Name}, $proto ) or die $@;
                no strict "refs";
                local $^W = 0;  ## Suppress subroutine redefined warnings.
                *{$tp->{Name}} = $sub;
            }

            ## Do this last in case of problems above
            $self->{TracePoints}->{$tp->{_Signature}} = $tp;
        }
    }
}

## NOTE: when and if we write a "remove_trace_point" sub, it's going to
## have to deal with (class) trace points very carefully.


## This is private until we come up with an API for individual trace points.
sub _trace_points {
    croak "Can't set subs" if @_ > 1;
    return values %{shift()->{TracePoints}};
}


sub DESTROY {
    my $self = shift;

    ##
    ## Remove trace points.
    ##
    for my $tp ( $self->_trace_points ) {
        my $name = $tp->{Name};
        my $tps = $trace_points{$name}->{TracePoints};

        ## Remove all of our trace points from this sub
        @$tps = grep $_ != $tp, @$tps;

        if ( ! @$tps ) {
            my $ref = $trace_points{$name}->{Ref};

            warn "Restoring tracepoint $name ($tp->{_Signature}) to $ref\n"
                if debugging;

            delete $trace_points{$name};
            no strict "refs";
            local $^W = 0;
            *{$name} = $ref;
        }
        else {
            warn "Removing tracepoint $name ($tp->{_Signature})\n" if debugging;
        }
    }
}

=back

=head1 Using in other Devel:: modules

The main advantage of the Devel:: namespace is that the C<perl -d:Foo
...> syntax is pretty handy.  Other modules which use this might want
to be in the Devel:: namespace.  The only trick is avoiding
calling Devel::TraceCalls' import() routine when you do this (unless
you want to for some reason).

To do this, you can either carefully avoid placing C<Devel::TraceCalls> in
your Devel::* module's C<@ISA> hierarchy or make sure that your module's
C<import()> method is called instead of C<Devel::TraceCalls>'.  If you
do this, you'll need to have a C<sub DB::DB> defined, because
C<Devel::TraceCalls>' wont be.  See the source and the
L<Devel::TraceSAX> module for details.

=head1 A Word on Devel::TraceCall Overhead

Massive.

Devel::TraceCall is a debugging aid and is designed to provide a lot
of detail and flexibility.  This comes at a price, namely overhead.

One of the side effects of this overhead is that Devel::TraceCall is
useless as a profiling tool, since a function that calls a number of
other functions, all of them being traced, will see all of the overhead
of Devel::TraceCall in its elapsed time.  This could be worked around,
but it is outside the scope of this module, see L<Devel::DProf> for
profiling needs.

=head1 TODO

=over

=item *

Wrap AUTOLOAD and automatically enable tracing on subs handled by and
created by AUTOLOADing.

=item *

Wrapper subs.

=item *

Does not get parameters from the call stack.  It will be optional, on by
default.

=item *

Flesh out and debug the -d:TraceCalls=... feature.

=item *

Add testing for PreCall and PostCall features.

=item *

Migrate the CORE::GLOBAL::require feature from Devel::TraceSAX so that
run-time C<require> statements can result in classes being traced.

=item *

Enable wildcards, probably by passing qr/.../ refs, in class, package
and sub names.

=item *

Migrate the namespace walking feature from Devel::TraceSAX, so that the
above wildcards can be used to specify categories of classes and
packages to trace.

=item *

Optional logging of returned values.

=back

=head1 LIMITATIONS

There are several minor limitations.

Exports a subroutine by default.  Do a C<use Devel::TraceCalls ();> to
suppress that.

If perl's optimized away constant functions, well, there is no call
to trace.

Because a wrapper subroutine gets installed in place of the original
subroutine, anything that has cached a reference (with code like
$foo = \&foo or $foo = Bar->can( "foo" )) will bypass the tracing.

If a subroutine reference is taken while tracing is enabled and then
used after tracing is disabled, it will refer to the wrapper subroutine
that no longer has something to wrap.  Devel::TraceCalls does not pass
these through in that case, but it could.

The import based C<use Devel::TraceCalls { ... }> feature relies on a
C<CHECK> subroutine, which is not present on older perls.  See
L<perlmod> for details.

Doesn't warn if you point it at an empty class, or if you pass no subs.
This is because you might be passing in a possibly empty list.  Check
the return value's subs method to count up how many overrides occured.

=head1 PRIOR ART

See Devel::TraceMethods and Aspect::Trace for similar functionality.

Merlyn also suggested using Class::Prototyped to implement the
instance subclassing, but it seems too simple to do without incurring
a prerequisite module.

A miscellany of tricky modules like Sub::Versive, Hook::LexWrap, and
Sub::Uplevel.

=head1 SEE ALSO

L<Devel::DProf> for profiling, L<Devel::TraceSAX> for an example of
a client module.

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

    Maintainer from version 0.04 is
    Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT

    Copyright (c) 2002 Barrie Slaymaker, All Rights Reserved.

You may use this module under the terms of the Artistic License or the
GPL, any version.

=cut

1;
