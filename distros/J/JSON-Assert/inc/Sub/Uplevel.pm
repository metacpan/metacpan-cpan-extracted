#line 1
package Sub::Uplevel;
use 5.006;
use strict;
# ABSTRACT: apparently run a function in a higher stack frame
our $VERSION = '0.24'; # VERSION

# Frame check global constant
our $CHECK_FRAMES;
BEGIN {
  $CHECK_FRAMES = !! $CHECK_FRAMES;
}
use constant CHECK_FRAMES => $CHECK_FRAMES;

# We must override *CORE::GLOBAL::caller if it hasn't already been 
# overridden or else Perl won't see our local override later.

if ( not defined *CORE::GLOBAL::caller{CODE} ) {
  *CORE::GLOBAL::caller = \&_normal_caller;
}

# modules to force reload if ":aggressive" is specified
my @reload_list = qw/Exporter Exporter::Heavy/;

sub import {
  no strict 'refs'; ## no critic
  my ($class, @args) = @_;
  for my $tag ( @args, 'uplevel' ) {
    if ( $tag eq 'uplevel' ) {
      my $caller = caller(0);
      *{"$caller\::uplevel"} = \&uplevel;
    }
    elsif( $tag eq ':aggressive' ) {
      _force_reload( @reload_list );
    }
    else {
      die qq{"$tag" is not exported by the $class module\n}
    }
  }
  return;
}

sub _force_reload {
  no warnings 'redefine';
  local $^W = 0;
  for my $m ( @_ ) {
    $m =~ s{::}{/}g;
    $m .= ".pm";
    require $m if delete $INC{$m};
  }
}


# @Up_Frames -- uplevel stack
# $Caller_Proxy -- whatever caller() override was in effect before uplevel
our (@Up_Frames, $Caller_Proxy);

sub _apparent_stack_height {
    my $height = 1; # start above this function 
    while ( 1 ) {
        last if ! defined scalar $Caller_Proxy->($height);
        $height++;
    }
    return $height - 1; # subtract 1 for this function
}

sub uplevel {
    # Backwards compatible version of "no warnings 'redefine'"
    my $old_W = $^W;
    $^W = 0;

    # Update the caller proxy if the uplevel override isn't in effect
    local $Caller_Proxy = *CORE::GLOBAL::caller{CODE}
        if *CORE::GLOBAL::caller{CODE} != \&_uplevel_caller;
    local *CORE::GLOBAL::caller = \&_uplevel_caller;

    # Restore old warnings state
    $^W = $old_W;

    if ( CHECK_FRAMES and $_[0] >= _apparent_stack_height() ) {
      require Carp;
      Carp::carp("uplevel $_[0] is more than the caller stack");
    }

    local @Up_Frames = (shift, @Up_Frames );

    my $function = shift;
    return $function->(@_);
}

sub _normal_caller (;$) { ## no critic Prototypes
    my ($height) = @_;
    $height++;
    my @caller = CORE::caller($height);
    if ( CORE::caller() eq 'DB' ) {
        # Oops, redo picking up @DB::args
        package DB;
        @caller = CORE::caller($height);
    }

    return if ! @caller;                  # empty
    return $caller[0] if ! wantarray;     # scalar context
    return @_ ? @caller : @caller[0..2];  # extra info or regular
}

sub _uplevel_caller (;$) { ## no critic Prototypes
    my $height = $_[0] || 0;

    # shortcut if no uplevels have been called
    # always add +1 to CORE::caller (proxy caller function)
    # to skip this function's caller
    return $Caller_Proxy->( $height + 1 ) if ! @Up_Frames;


    my $saw_uplevel = 0;
    my $adjust = 0;

    # walk up the call stack to fight the right package level to return;
    # look one higher than requested for each call to uplevel found
    # and adjust by the amount found in the Up_Frames stack for that call.
    # We *must* use CORE::caller here since we need the real stack not what 
    # some other override says the stack looks like, just in case that other
    # override breaks things in some horrible way

    for ( my $up = 0; $up <= $height + $adjust; $up++ ) {
        my @caller = CORE::caller($up + 1); 
        if( defined $caller[0] && $caller[0] eq __PACKAGE__ ) {
            # add one for each uplevel call seen
            # and look into the uplevel stack for the offset
            $adjust += 1 + $Up_Frames[$saw_uplevel];
            $saw_uplevel++;
        }
    }

    # For returning values, we pass through the call to the proxy caller
    # function, just at a higher stack level
    my @caller = $Caller_Proxy->($height + $adjust + 1);
    if ( CORE::caller() eq 'DB' ) {
        # Oops, redo picking up @DB::args
        package DB;
        @caller = $Sub::Uplevel::Caller_Proxy->($height + $adjust + 1);
    }

    return if ! @caller;                  # empty
    return $caller[0] if ! wantarray;     # scalar context
    return @_ ? @caller : @caller[0..2];  # extra info or regular
}


1;

__END__
#line 386

