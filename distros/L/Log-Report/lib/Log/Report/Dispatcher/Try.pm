# Copyrights 2007-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Log-Report. Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Dispatcher::Try;{
our $VERSION = '1.40';
}

use base 'Log::Report::Dispatcher';

use warnings;
use strict;

use Log::Report 'log-report', syntax => 'SHORT';
use Log::Report::Exception ();
use Log::Report::Util      qw/%reason_code expand_reasons/;
use List::Util             qw/first/;


use overload
    bool     => 'failed'
  , '""'     => 'showStatus'
  , fallback => 1;

#-----------------

sub init($)
{   my ($self, $args) = @_;
    defined $self->SUPER::init($args) or return;
    $self->{exceptions} = delete $args->{exceptions} || [];
    $self->{died}       = delete $args->{died};
    $self->hide($args->{hide} // 'NONE');
    $self->{on_die}     = $args->{on_die} // 'ERROR';
    $self;
}

#-----------------

sub died(;$)
{   my $self = shift;
    @_ ? ($self->{died} = shift) : $self->{died};
}


sub exceptions() { @{shift->{exceptions}} }


sub hides($) { $_[0]->{LRDT_hides}{$_[1]} }


sub hide(@)
{   my $self = shift;
    my @reasons = expand_reasons(@_ > 1 ? \@_ : shift);
    $self->{LRDT_hides} = +{ map +($_ => 1), @reasons };
}


sub die2reason() { shift->{on_die} }

#-----------------

sub log($$$$)
{   my ($self, $opts, $reason, $message, $domain) = @_;

    unless($opts->{stack})
    {   my $mode = $self->mode;
        $opts->{stack} = $self->collectStack
            if $reason eq 'PANIC'
            || ($mode==2 && $reason_code{$reason} >= $reason_code{ALERT})
            || ($mode==3 && $reason_code{$reason} >= $reason_code{ERROR});
    }

    $opts->{location} ||= '';

    my $e = Log::Report::Exception->new
      ( reason      => $reason
      , report_opts => $opts
      , message     => $message
      );

    push @{$self->{exceptions}}, $e;

    $self;
}


sub reportFatal(@) { $_->throw(@_) for shift->wasFatal   }
sub reportAll(@)   { $_->throw(@_) for shift->exceptions }

#-----------------

sub failed()  {   defined shift->{died} }
sub success() { ! defined shift->{died} }


sub wasFatal(@)
{   my ($self, %args) = @_;
    defined $self->{died} or return ();

    my $ex = first { $_->isFatal } @{$self->{exceptions}}
        or return ();

    # There can only be one fatal exception.  Is it in the class?
    (!$args{class} || $ex->inClass($args{class})) ? $ex : ();
}


sub showStatus()
{   my $self  = shift;
    my $fatal = $self->wasFatal or return '';
    __x"try-block stopped with {reason}: {text}"
      , reason => $fatal->reason
      , text   => $self->died;
}

1;
