# Copyrights 2001-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Transport.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Transport::Send;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Transport';

use strict;
use warnings;

use Carp;
use File::Spec;
use Errno 'EAGAIN';


sub new(@)
{   my $class = shift;
    return $class->SUPER::new(@_)
       if $class ne __PACKAGE__;

    require Mail::Transport::Sendmail;
    Mail::Transport::Sendmail->new(@_);
}

#------------------------------------------


sub send($@)
{   my ($self, $message, %args) = @_;

    unless($message->isa('Mail::Message'))  # avoid rebless.
    {   $message = Mail::Message->coerce($message);
        confess "Unable to coerce object into Mail::Message."
            unless defined $message;
    }

    return 1 if $self->trySend($message, %args);
    return 0 unless $?==EAGAIN;

    my ($interval, $retry) = $self->retry;
    $interval = $args{interval} if exists $args{interval};
    $retry    = $args{retry}    if exists $args{retry};

    while($retry!=0)
    {   sleep $interval;
        return 1 if $self->trySend($message, %args);
        return 0 unless $?==EAGAIN;
        $retry--;
    }

    0;
}

#------------------------------------------


sub trySend($@)
{   my $self = shift;
    $self->log(ERROR => "Transporters of type ".ref($self). " cannot send.");
}

#------------------------------------------


sub putContent($$@)
{   my ($self, $message, $fh, %args) = @_;

       if($args{body_only})   { $message->body->print($fh) }
    elsif($args{undisclosed}) { $message->Mail::Message::print($fh) }
    else
    {   $message->head->printUndisclosed($fh);
        $message->body->print($fh);
    }

    $self;
}

#------------------------------------------


sub destinations($;$)
{   my ($self, $message, $overrule) = @_;
    my @to;

    if(defined $overrule)      # Destinations overruled by user.
    {   my @addr = ref $overrule eq 'ARRAY' ? @$overrule : ($overrule);
        @to = map { ref $_ && $_->isa('Mail::Address') ? ($_)
                    : Mail::Address->parse($_) } @addr;
    }
    elsif(my @rgs = $message->head->resentGroups)
    {   @to = $rgs[0]->destinations;
        $self->log(WARNING => "Resent group does not specify a destination"), return ()
            unless @to;
    }
    else
    {   @to = $message->destinations;
        $self->log(WARNING => "Message has no destination"), return ()
            unless @to;
    }

    @to;
}

#------------------------------------------


1;
