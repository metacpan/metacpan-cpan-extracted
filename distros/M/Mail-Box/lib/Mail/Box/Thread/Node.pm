# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Thread::Node;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Reporter';

use strict;
use warnings;

use Carp;


sub new(@)
{   my ($class, %args) = @_;
    (bless {}, $class)->init(\%args);
}

sub init($)
{   my ($self, $args) = @_;

    if(my $message = $args->{message})
    {   push @{$self->{MBTN_messages}}, $message;
        $self->{MBTN_msgid} = $args->{msgid} || $message->messageId;
    }
    elsif(my $msgid = $args->{msgid})
    {   $self->{MBTN_msgid} = $msgid;
    }
    else
    {   croak "Need to specify message or message-id";
    }

    $self->{MBTN_dummy_type} = $args->{dummy_type};
    $self;
}

#-------------------------------------------


sub message()
{   my $self = shift;

    unless($self->{MBTN_messages})
    {   return () if wantarray;

        my $dummy = $self->{MBTN_dummy_type}->new
          ( messageId =>$self->{MBTN_msgid}
          );

        push @{$self->{MBTN_messages}}, $dummy;
        return $dummy;
    }

    my @messages = @{$self->{MBTN_messages}};
    return @messages    if wantarray;
    return $messages[0] if @messages==1;

    foreach (@messages)
    {   return $_ unless $_->isDeleted;
    }

    $messages[0];
}


sub addMessage($)
{   my ($self, $message) = @_;
 
    return $self->{MBTN_messages} = [ $message ]
        if $self->isDummy;

    push @{$self->{MBTN_messages}}, $message;
    $message;
}


sub isDummy()
{   my $self = shift;
    !defined $self->{MBTN_messages} || $self->{MBTN_messages}[0]->isDummy;
}


sub messageId() { shift->{MBTN_msgid} }


sub expand(;$)
{   my $self = shift;
    return $self->message->label('folded') || 0
        unless @_;

    my $fold = not shift;
    $_->label(folded => $fold) foreach $self->message;
    $fold;
}

sub folded(;$)    # compatibility <2.0
{  @_ == 1 ? shift->expand : shift->expand(not shift) }

#-------------------------------------------

sub repliedTo()
{   my $self = shift;

    return wantarray
         ? ($self->{MBTN_parent}, $self->{MBTN_quality})
         : $self->{MBTN_parent};
}


sub follows($$)
{   my ($self, $thread, $how) = @_;
    my $quality = $self->{MBTN_quality};

    # Do not create cyclic constructs caused by erroneous refs.

    my $msgid = $self->messageId;       # Look up for myself, upwards in thread
    for(my $walker = $thread; defined $walker; $walker = $walker->repliedTo)
    {   return undef if $walker->messageId eq $msgid;
    }

    my $threadid = $thread->messageId;  # a->b and b->a  (ref order reversed)
    foreach ($self->followUps)
    {   return undef if $_->messageId eq $threadid;
    }

    # Register

    if($how eq 'REPLY' || !defined $quality)
    {   $self->{MBTN_parent}  = $thread;
        $self->{MBTN_quality} = $how;
        return $self;
    }
    
    return $self if $quality eq 'REPLY';

    if($how eq 'REFERENCE' || ($how eq 'GUESS' && $quality ne 'REFERENCE'))
    {   $self->{MBTN_parent}  = $thread;
        $self->{MBTN_quality} = $how;
    }

    $self;
}


sub followedBy(@)
{   my $self = shift;
    $self->{MBTN_followUps}{$_->messageId} = $_ foreach @_;
    $self;
}


sub followUps()
{   my $self    = shift;
    $self->{MBTN_followUps} ? values %{$self->{MBTN_followUps}} : ();
}


sub sortedFollowUps()
{   my $self    = shift;
    my $prepare = shift || sub {shift->startTimeEstimate||0};
    my $compare = shift || sub {(shift) <=> (shift)};

    my %value   = map { ($prepare->($_) => $_) } $self->followUps;
    map { $value{$_} } sort {$compare->($a, $b)} keys %value;
}

#-------------------------------------------

sub threadToString(;$$$)   # two undocumented parameters for layout args
{   my $self    = shift;
    my $code    = shift || sub {shift->head->study('subject')};
    my ($first, $other) = (shift || '', shift || '');
    my $message = $self->message;
    my @follows = $self->sortedFollowUps;

    my @out;
    if($self->folded)
    {   my $text = $code->($message) || '';
        chomp $text;
        return "    $first [" . $self->nrMessages . "] $text\n";
    }
    elsif($message->isDummy)
    {   $first .= $first ? '-*-' : ' *-';
        return (shift @follows)->threadToString($code, $first, "$other   " )
            if @follows==1;

        push @out, (shift @follows)->threadToString($code, $first, "$other | " )
            while @follows > 1;
    }
    else
    {   my $text  = $code->($message) || '';
        chomp $text;
        my $size  = $message->shortSize;
        @out = "$size$first $text\n";
        push @out, (shift @follows)
                       ->threadToString($code, "$other |-", "$other | " )
            while @follows > 1;
    }

    push @out, (shift @follows)->threadToString($code, "$other `-","$other   " )
        if @follows;

    join '', @out;
}


sub startTimeEstimate()
{   my $self = shift;

    return $self->message->timestamp
        unless $self->isDummy;

    my $earliest;
    foreach ($self->followUps)
    {   my $stamp = $_->startTimeEstimate;

        $earliest = $stamp
	    if !defined $earliest || (defined $stamp && $stamp < $earliest);
    }

    $earliest;
}


sub endTimeEstimate()
{   my $self = shift;

    my $latest;
    $self->recurse
     (  sub { my $node = shift;
              unless($node->isDummy)
              {   my $stamp = $node->message->timestamp;
                  $latest = $stamp if !$latest || $stamp > $latest;
              }
            }
     );

    $latest;
}


sub recurse($)
{   my ($self, $code) = @_;

    $code->($self) or return $self;

    $_->recurse($code) or last
        foreach $self->followUps;

    $self;
}


sub totalSize()
{   my $self  = shift;
    my $total = 0;

    $self->recurse
     ( sub {
          my @msgs = shift->messages;
          $total += $msgs[0]->size if @msgs;
          1;}
     );

    $total;
}


sub numberOfMessages()
{   my $self  = shift;
    my $total = 0;
    $self->recurse( sub {++$total unless shift->isDummy; 1} );
    $total;
}

sub nrMessages() {shift->numberOfMessages}  # compatibility


sub threadMessages()
{   my $self = shift;
    my @messages;
    $self->recurse
     ( sub
       { my $node = shift;
         push @messages, $node->message unless $node->isDummy;
         1;
       }
     );

    @messages;
}



sub ids()
{   my $self = shift;
    my @ids;
    $self->recurse( sub {push @ids, shift->messageId} );
    @ids;
}

#-------------------------------------------



1;
