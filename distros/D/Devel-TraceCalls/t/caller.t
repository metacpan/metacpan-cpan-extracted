#!/usr/local/bin/perl -w

use Test;
use strict;

my $has_diff = eval "use Test::Differences; 1";

sub flatten {  ## In case !$has_diff
    join( "",
        map(
            "[" . join( ",", map defined $_ ? "'$_'" : "undef", @$_ ) . "]\n",
            shift()
        )
    );
}


sub aok {
    if ( $has_diff ) {
        goto &eq_or_diff;
    }
    else {
        @_ = (
            flatten( $_[0] ),
            flatten( $_[1] ),
            @_[2..$#_],
        );
        goto &ok;
    }
}


use Carp;

## This next bit needs to be compiled twice, once before we use
## Devel::TraceCalls and once after.
sub compile_stack_checker {
    eval <<'END' or die $@;
$^W = 0;  ## No redeclared warnings
use strict;
sub stack {
    my ( $context ) = @_;
    my @s;
    my $i = 0;
    while (1) {
        my @c ;
        if ( $context eq "scalar" ) {
            $c[0] = caller $i;
        }
        else {
            push @c, caller $i;
        }
        ++$i;
        last unless $c[0];
        my $j = 0;
        @c =
            map "depth " . $i . "[" . $j++ . "]: $_",
            map { s/\(eval \d+\)/(eval <<number>>)/g; $_ }
            map defined() ? $_ : "<<undef>>",
            @c;
#warn join ",", @c;
        push @s, @c;
    }
    return @s;
}

sub dive {
    my ( $context, $depth ) = @_;
    Devel::TraceCalls::emit_trace_message( "in dive" )
        if defined &Devel::TraceCalls::emit_trace_message;
    $depth ||= 1;
    $depth >= 3
        ? stack( $context )
        : dive( $context, $depth + 1 ) ;
}

1;
END
}

sub check_stack {
    ( scalar => [ dive( "scalar" ) ], list => [ dive( "list" ) ] );
}

## before and after_use are testing what happens without a tracepoint, to
## make sure we're not affecting normal operation.
my %before;
my %after_use;
my %in_trace;

sub caller_before { caller @_ }

BEGIN{ compile_stack_checker }
## The various check_stacks need to be on the same line :).
## There are more BEGIN blocks here than would seem necessary because
## putting the check_stack() call after another statement in a BEGIN
## block seems to change the internal use only "hints" field (caller[8])
## to a 2 in perl5.6.1
BEGIN { %before = check_stack } use Devel::TraceCalls; BEGIN { compile_stack_checker } BEGIN { %after_use = check_stack } BEGIN { trace_calls "dive", "stack" } BEGIN { %in_trace = check_stack }

sub caller_after_use { caller @_ }

my $t;

my @tests = (
sub { ok scalar caller_before,        "main", "scalar caller_before" },
sub { ok scalar caller_before(0),     "main", "scalar caller_before(0)" },

sub { ok scalar caller_after_use,     "main", "scalar caller_after_use" },
sub { ok scalar caller_after_use(0),  "main", "scalar caller_after_use(0)" },

sub {
    my @calls;
    ## Note: we can't really check caller_before, since it really refers to
    ## the caller() before, so if we trace it, it gets Devel::TraceCalls
    $t = Devel::TraceCalls->new( {
        Subs       => [ "caller_after_use" ],
        LogTo      => \@calls, ## Ignore calls
    } );
    ok scalar $t->_trace_points, 1;
},

## Not sure why I am adding the the -1 and +1 here, but I do not ever
## want to fail these tests, and if the system clock is tweaked or there
## is some off-by-one problem...
sub { ok scalar caller_before,        "main", "scalar caller_before" },
sub { ok scalar caller_before(0),     "main", "scalar caller_before(0)" },

sub { ok scalar caller_after_use,     "main", "scalar caller_after_use" },
sub { ok scalar caller_after_use(0),  "main", "scalar caller_after_use(0)" },

sub { ok scalar @{$before   {scalar}} > 0, 1, "before{scalar}}"    },
sub { ok scalar @{$before   {list}  } > 0, 1, "before{list}}"      },

sub { ok scalar @{$after_use{scalar}} > 0, 1, "after_use{scalar}}" },
sub { ok scalar @{$after_use{list}  } > 0, 1, "after_use{list}}"   },

sub { ok scalar @{$in_trace {scalar}} > 0, 1, "in_trace{scalar}}"  },
sub { ok scalar @{$in_trace {list}  } > 0, 1, "in_trace{list}}"    },

sub { aok $after_use{scalar}, $before{scalar}, "after_use scalar callstack" },
sub { aok $after_use{list},   $before{list},   "after_use list callstack"   },

sub { aok $in_trace{scalar},  $before{scalar}, "in_trace scalar callstack"  },
sub { aok $in_trace{list},    $before{list},   "in_trace list callstack"    },

sub {
    my @calls;
    $t = Devel::TraceCalls->new( {
        Subs       => [ "dive" ],
        LogTo      => \@calls, ## Ignore calls
    } );
    ok scalar $t->_trace_points, 1;
},

);

plan tests => scalar @tests;

$_->() for @tests;
