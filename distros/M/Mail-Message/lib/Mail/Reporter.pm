# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Reporter;
use vars '$VERSION';
$VERSION = '3.015';


use strict;
use warnings;

use Carp;
use Scalar::Util 'dualvar';


my @levelname = (undef, qw(DEBUG NOTICE PROGRESS WARNING ERROR NONE INTERNAL));

my %levelprio = (ERRORS => 5, WARNINGS => 4, NOTICES => 2);
for(my $l = 1; $l < @levelname; $l++)
{   $levelprio{$levelname[$l]} = $l;
    $levelprio{$l} = $l;
}

sub new(@)
{   my $class = shift;
#confess "Parameter list has odd length: @_" if @_ % 2;
    (bless {MR_log => 1, MR_trace => 1}, $class)->init({@_});
}

my($default_log, $default_trace, $trace_callback);
sub init($)
{   my ($self, $args) = @_;
    $self->{MR_log}   = $levelprio{$args->{log}   || $default_log};
    $self->{MR_trace} = $levelprio{$args->{trace} || $default_trace};
    $self;
}

#------------------------------------------


sub _trace_warn($$$)
{   my ($who, $level, $text) = @_;
    warn "$level: $text\n";
}

sub defaultTrace(;$$)
{   my $thing = shift;

    return ($default_log, $default_trace)
        unless @_;

    my $level = shift;
    my $prio  = $thing->logPriority($level)
        or croak "Unknown trace-level $level.";

    if( ! @_)
    {   $default_log    = $default_trace = $prio;
        $trace_callback = \&_trace_warn;
    }
    elsif(ref $_[0])
    {   $default_log    = $thing->logPriority('NONE');
        $default_trace  = $prio;
        $trace_callback = shift;
    }
    else
    {   $default_log    = $prio;
        $default_trace  = $thing->logPriority(shift);
        $trace_callback = \&_trace_warn;
    }

    ($default_log, $default_trace);
}

__PACKAGE__->defaultTrace('WARNINGS');

#------------------------------------------


sub trace(;$$)
{   my $self = shift;

    return $self->logPriority($self->{MR_trace})
        unless @_;

    my $level = shift;
    my $prio  = $levelprio{$level}
        or croak "Unknown trace-level $level.";

    $self->{MR_trace} = $prio;
}

#------------------------------------------


# Implementation detail: the Mail::Box::Parser::C code avoids calls back
# to Perl by checking the trace-level itself.  In the perl code of this
# module however, just always call the log() method, and let it check
# whether or not to display it.

sub log(;$@)
{   my $thing = shift;

    if(ref $thing)   # instance call
    {   return $thing->logPriority($thing->{MR_log})
            unless @_;

        my $level = shift;
        my $prio  = $levelprio{$level}
            or croak "Unknown log-level $level";

        return $thing->{MR_log} = $prio
            unless @_;

        my $text    = join '', @_;
        $trace_callback->($thing, $level, $text)
            if $prio >= $thing->{MR_trace};
use Carp;
$thing->{MR_trace} or confess;

        push @{$thing->{MR_report}[$prio]}, $text
            if $prio >= $thing->{MR_log};
    }
    else             # class method
    {   my $level = shift;
        my $prio  = $levelprio{$level}
            or croak "Unknown log-level $level";

        $trace_callback->($thing, $level, join('',@_)) 
           if $prio >= $default_trace;
    }

    $thing;
}


#------------------------------------------


sub report(;$)
{   my $self    = shift;
    my $reports = $self->{MR_report} || return ();

    if(@_)
    {   my $level = shift;
        my $prio  = $levelprio{$level}
            or croak "Unknown report level $level.";

        return $reports->[$prio] ? @{$reports->[$prio]} : ();
    }

    my @reports;
    for(my $prio = 1; $prio < @$reports; $prio++)
    {   next unless $reports->[$prio];
        my $level = $levelname[$prio];
        push @reports, map { [ $level, $_ ] } @{$reports->[$prio]};
    }

    @reports;
}

#-------------------------------------------


sub addReport($)
{   my ($self, $other) = @_;
    my $reports = $other->{MR_report} || return ();

    for(my $prio = 1; $prio < @$reports; $prio++)
    {   push @{$self->{MR_report}[$prio]}, @{$reports->[$prio]}
            if exists $reports->[$prio];
    }
    $self;
}
    
#-------------------------------------------


sub reportAll(;$)
{   my $self = shift;
    map { [ $self, @$_ ] } $self->report(@_);
}

#-------------------------------------------


sub errors(@)   {shift->report('ERRORS')}

#-------------------------------------------


sub warnings(@) {shift->report('WARNINGS')}

#-------------------------------------------


sub notImplemented(@)
{   my $self    = shift;
    my $package = ref $self || $self;
    my $sub     = (caller 1)[3];

    $self->log(ERROR => "Package $package does not implement $sub.");
    confess "Please warn the author, this shouldn't happen.";
}

#------------------------------------------


sub logPriority($)
{   my $level = $levelprio{$_[1]} or return undef;
    dualvar $level, $levelname[$level];
}

#-------------------------------------------


sub logSettings()
{  my $self = shift;
   (log => $self->{MR_log}, trace => $self->{MR_trace});
}

#-------------------------------------------


sub AUTOLOAD(@)
{   my $thing   = shift;
    our $AUTOLOAD;
    my $class   = ref $thing || $thing;
    (my $method = $AUTOLOAD) =~ s/^.*\:\://;

    $Carp::MaxArgLen=20;
    confess "Method $method() is not defined for a $class.\n";
}

#-------------------------------------------


#-------------------------------------------


sub DESTROY {shift}

1;
