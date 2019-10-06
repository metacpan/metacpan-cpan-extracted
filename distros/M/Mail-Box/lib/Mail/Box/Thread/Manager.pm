# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Thread::Manager;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Reporter';

use strict;
use warnings;

use Carp;
use Mail::Box::Thread::Node;
use Mail::Message::Dummy;


sub init($)
{   my ($self, $args) = @_;

    $self->{MBTM_manager} = $args->{manager}
        or croak "Need a manager to work with.";

    $self->{MBTM_thread_body}= $args->{thread_body}|| 0;
    $self->{MBTM_thread_type}= $args->{thread_type}||'Mail::Box::Thread::Node';
    $self->{MBTM_dummy_type} = $args->{dummy_type} ||'Mail::Message::Dummy';

    for($args->{timespan} || '3 days')
    {    $self->{MBTM_timespan} = $_ eq 'EVER' ? 'EVER'
                               : Mail::Box->timespan2seconds($_);
    }

    for($args->{window} || 10)
    {   $self->{MBTM_window} = $_ eq 'ALL'  ? 'ALL' : $_;
    }
    $self;
}

#-------------------------------------------

sub folders() { values %{shift->{MBTM_folders}} }


sub includeFolder(@)
{   my $self = shift;

    foreach my $folder (@_)
    {   croak "Not a folder: $folder"
            unless ref $folder && $folder->isa('Mail::Box');

        my $name = $folder->name;
        next if exists $self->{MBTM_folders}{$name};

        $self->{MBTM_folders}{$name} = $folder;
        foreach my $msg ($folder->messages)
        {   $self->inThread($msg) unless $msg->head->isDelayed;
        }
    }

    $self;
}


sub removeFolder(@)
{   my $self = shift;

    foreach my $folder (@_)
    {   croak "Not a folder: $folder"
            unless ref $folder && $folder->isa('Mail::Box');

        my $name = $folder->name;
        next unless exists $self->{MBTM_folders}{$name};

        delete $self->{MBTM_folders}{$name};

        $_->headIsRead && $self->outThread($_)
            foreach $folder->messages;

        $self->{MBTM_cleanup_needed} = 1;
    }

    $self;
}

#-------------------------------------------

sub thread($)
{   my ($self, $message) = @_;
    my $msgid     = $message->messageId;
    my $timestamp = $message->timestamp;

    $self->_process_delayed_nodes;
    my $thread    = $self->{MBTM_ids}{$msgid} || return;

    my @missing;
    $thread->recurse
       ( sub { my $node = shift;
               push @missing, $node->messageId if $node->isDummy;
               1;
             }
       );

    return $thread unless @missing;

    foreach my $folder ($self->folders)
    {
        # Pull-in all messages received after this-one, from any folder.
        my @now_missing = $folder->scanForMessages
          ( $msgid
          , [ @missing ]
          , $timestamp - 3600 # some clocks are wrong.
          , 0
          );

        if(@now_missing != @missing)
        {   $self->_process_delayed_nodes;
            last unless @now_missing;
            @missing = @now_missing;
        }
    }

    $thread;
}


sub threadStart($)
{   my ($self, $message) = @_;

    my $thread = $self->thread($message) || return;

    while(my $parent = $thread->repliedTo)
    {   unless($parent->isDummy)
        {   # Message already found, no special action to be taken.
            $thread = $parent;
            next;
        }

        foreach ($self->folders)
        {   my $message  = $thread->message;
            my $timespan = $message->isDummy ? 'ALL'
              : $message->timestamp - $self->{MBTM_timespan};

            last unless $_->scanForMessages
              ( $thread->messageId, $parent->messageId
              , $timespan, $self->{MBTM_window}
              );
        }

        $self->_process_delayed_nodes;
        $thread = $parent;
    }

    $thread;
}


sub all()
{   my $self = shift;
    $_->find('not-existing') for $self->folders;
    $self->known;
}


sub sortedAll(@)
{   my $self = shift;
    $_->find('not-existing') for $self->folders;
    $self->sortedKnown(@_);
}


sub known()
{   my $self      = shift->_process_delayed_nodes->_cleanup;
    grep {!defined $_->repliedTo} values %{$self->{MBTM_ids}};
}


sub sortedKnown(;$$)
{   my $self    = shift;
    my $prepare = shift || sub {shift->startTimeEstimate||0};
    my $compare = shift || sub {(shift) <=> (shift)};
 
    # Special care for double keys.
    my %value;
    push @{$value{$prepare->($_)}}, $_ for $self->known; 
    map @{$value{$_}}, sort {$compare->($a, $b)} keys %value;
}

# When a whole folder is removed, many threads can become existing
# only of dummies.  They must be removed.

sub _cleanup()
{   my $self = shift;
    return $self unless $self->{MBTM_cleanup_needed};

    foreach ($self->known)
    {   my $real = 0;
        $_->recurse
          ( sub { my $node = shift;
                  foreach ($node->messages)
                  {   next if $_->isDummy;
                      $real = 1;
                      return 0;
                  }
                  1;
                }
          );

        next if $real;

        $_->recurse
          ( sub { my $node  = shift;
                  my $msgid = $node->messageId;
                  delete $self->{MBTM_ids}{$msgid};
                  1;
                }
          );
    }

    delete $self->{MBTM_cleanup_needed};
    $self;
}

#-------------------------------------------

sub toBeThreaded($@)
{   my ($self, $folder) = (shift, shift);
    return $self unless exists $self->{MBTM_folders}{$folder->name};
    $self->inThread($_) foreach @_;
    $self;
}


sub toBeUnthreaded($@)
{   my ($self, $folder) = (shift, shift);
    return $self unless exists $self->{MBTM_folders}{$folder->name};
    $self->outThread($_) foreach @_;
    $self;
}


sub inThread($)
{   my ($self, $message) = @_;
    my $msgid = $message->messageId;
    my $node  = $self->{MBTM_ids}{$msgid};

    # Already known, but might reside in many folders.
    if($node) { $node->addMessage($message) }
    else
    {   $node = Mail::Box::Thread::Node->new(message => $message
           , msgid => $msgid, dummy_type => $self->{MBTM_dummy_type}
           );
        $self->{MBTM_ids}{$msgid} = $node;
    }

    $self->{MBTM_delayed}{$msgid} = $node; # removes doubles.
}

# The relation between nodes is delayed, to avoid that first
# dummy nodes have to be made, and then immediately upgrades
# to real nodes.  So: at first we inventory what we have, and
# then build thread-lists.

sub _process_delayed_nodes()
{   my $self    = shift;
    return $self unless $self->{MBTM_delayed};

    foreach my $node (values %{$self->{MBTM_delayed}})
    {   $self->_process_delayed_message($node, $_)
            foreach $node->message;
    }

    delete $self->{MBTM_delayed};
    $self;
}

sub _process_delayed_message($$)
{   my ($self, $node, $message) = @_;
    my $msgid = $message->messageId;

    # will force parsing of head when not done yet.
    my $head  = $message->head or return $self;

    my $replies;
    if(my $irt  = $head->get('in-reply-to'))
    {   for($irt =~ m/\<(\S+\@\S+)\>/)
        {   my $msgid = $1;
            $replies  = $self->{MBTM_ids}{$msgid} || $self->createDummy($msgid);
        }
    }

    my @refs;
    if(my $refs = $head->get('references'))
    {   while($refs =~ s/\<(\S+\@\S+)\>//s)
        {   my $msgid = $1;
            push @refs, $self->{MBTM_ids}{$msgid} || $self->createDummy($msgid);
        }
    }

    # Handle the `In-Reply-To' message header.
    # This is the most secure relationship.

    if($replies)
    {   $node->follows($replies, 'REPLY')
        and $replies->followedBy($node);
    }

    # Handle the `References' message header.
    # The (ordered) list of message-IDs give an impression where this
    # message resides in the thread.  There is a little less certainty
    # that the list is correctly ordered and correctly maintained.

    if(@refs)
    {   push @refs, $node unless $refs[-1] eq $node;
        my $from = shift @refs;

        while(my $to = shift @refs)
        {   $to->follows($from, 'REFERENCE')
            and $from->followedBy($to);
            $from = $to;
        }
    }

    $self;
}

#-------------------------------------------


sub outThread($)
{   my ($self, $message) = @_;
    my $msgid = $message->messageId;
    my $node  = $self->{MBTM_ids}{$msgid} or return $message;

    $node->{MBTM_messages}
        = [ grep {$_ ne $message} @{$node->{MBTM_messages}} ];

    $self;
}

#-------------------------------------------


sub createDummy($)
{   my ($self, $msgid) = @_;
    $self->{MBTM_ids}{$msgid} = $self->{MBTM_thread_type}->new
            (msgid => $msgid, dummy_type => $self->{MBTM_dummy_type});
}

#-------------------------------------------


1;
