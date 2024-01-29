# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message;
use vars '$VERSION';
$VERSION = '3.015';


use strict;
use warnings;

use Mail::Message::Body::Multipart;
use Mail::Address;
use Scalar::Util 'blessed';


# tests in t/55reply1r.t, demo in the examples/ directory

sub reply(@)
{   my ($self, %args) = @_;

    my $body   = $args{body};
    my $strip  = !exists $args{strip_signature} || $args{strip_signature};
    my $include  = $args{include}   || 'INLINE';

    if($include eq 'NO')
    {   # Throw away real body.
        $body    = Mail::Message::Body->new
           (data => ["\n[The original message is not included]\n\n"])
               unless defined $body;
    }
    elsif($include eq 'INLINE' || $include eq 'ATTACH')
    {
        unless(defined $body)
        {   # text attachment
            $body = $self->body;
            $body = $body->part(0)->body if $body->isMultipart && $body->parts==1;
            $body = $body->nested->body  if $body->isNested;

            $body
             = $strip && ! $body->isMultipart && !$body->isBinary
             ? $body->decoded->stripSignature
                 ( pattern   => $args{strip_signature}
                 , max_lines => $args{max_signature}
                 )
             : $body->decoded;
        }

        if($include eq 'INLINE' && $body->isMultipart) { $include = 'ATTACH' }
        elsif($include eq 'INLINE' && $body->isBinary)
        {   $include = 'ATTACH';
            $body    = Mail::Message::Body::Multipart->new(parts => [$body]);
        }

        if($include eq 'INLINE')
        {   my $quote
              = defined $args{quote} ? $args{quote}
              : exists $args{quote}  ? undef
              :                        '> ';

            if(defined $quote)
            {   my $quoting = ref $quote ? $quote : sub {$quote . $_};
                $body = $body->foreachLine($quoting);
            }
        }
    }
    else
    {   $self->log(ERROR => "Cannot include reply source as $include.");
        return;
    }

    #
    # Collect header info
    #

    my $mainhead = $self->toplevel->head;

    # Where it comes from
    my $from = delete $args{From};
    unless(defined $from)
    {   my @from = $self->to;
        $from    = \@from if @from;
    }

    # To whom to send
    my $to = delete $args{To}
          || $mainhead->get('reply-to') || $mainhead->get('from');
    defined $to or return;

    # Add Cc
    my $cc = delete $args{Cc};
    if(!defined $cc && $args{group_reply})
    {   my @cc = $self->cc;
        $cc    = [ $self->cc ] if @cc;
    }

    # Create a subject
    my $srcsub  = delete $args{Subject};
    my $subject
     = ! defined $srcsub ? $self->replySubject($self->subject)
     : ref $srcsub       ? $srcsub->($self->subject)
     :                     $srcsub;

    # Create a nice message-id
    my $msgid   = delete $args{'Message-ID'};
    $msgid      = "<$msgid>" if $msgid && $msgid !~ /^\s*\<.*\>\s*$/;

    # Thread information
    my $origid  = '<'.$self->messageId.'>';
    my $refs    = $mainhead->get('references');

    # Prelude
    my $prelude
      = defined $args{prelude} ? $args{prelude}
      : exists $args{prelude}  ? undef
      :                          [ $self->replyPrelude($to) ];

    $prelude     = Mail::Message::Body->new(data => $prelude)
        if defined $prelude && ! blessed $prelude;
 
    my $postlude = $args{postlude};
    $postlude    = Mail::Message::Body->new(data => $postlude)
        if defined $postlude && ! blessed $postlude;

    #
    # Create the message.
    #

    my $total;
    if($include eq 'NO') {$total = $body}
    elsif($include eq 'INLINE')
    {   my $signature = $args{signature};
        $signature = $signature->body
           if defined $signature && $signature->isa('Mail::Message');

        $total = $body->concatenate
          ( $prelude, $body, $postlude
          , (defined $signature ? "-- \n" : undef), $signature
          );
    }
    if($include eq 'ATTACH')
    {
         my $intro = $prelude->concatenate
           ( $prelude
           , [ "\n", "[Your message is attached]\n" ]
           , $postlude
           );

        $total = Mail::Message::Body::Multipart->new
         ( parts => [ $intro, $body, $args{signature} ]
        );
    }

    my $msgtype = $args{message_type} || 'Mail::Message';

    my $reply   = $msgtype->buildFromBody
      ( $total
      , From    => $from || 'Undisclosed senders:;'
      , To      => $to
      , Subject => $subject
      , 'In-Reply-To' => $origid
      , References    => ($refs ? "$refs $origid" : $origid)
      );

    my $newhead = $reply->head;
    $newhead->set(Cc  => $cc)  if $cc;
    $newhead->set(Bcc => delete $args{Bcc}) if $args{Bcc};
    $newhead->add($_ => $args{$_})
        for sort grep /^[A-Z]/, keys %args;

    # Ready

    $self->log(PROGRESS => 'Reply created from '.$origid);
    $self->label(replied => 1);
    $reply;
}

#------------------------------------------


# tests in t/35reply1rs.t

sub replySubject($)
{   my ($thing, $subject) = @_;
    $subject     = 'your mail' unless defined $subject && length $subject;
    my @subject  = split /\:/, $subject;
    my $re_count = 1;

    # Strip multiple Re's from the start.

    while(@subject)
    {   last if $subject[0] =~ /[A-QS-Za-qs-z][A-DF-Za-df-z]/;

        for(shift @subject)
        {   while( /\bRe(?:\[\s*(\d+)\s*\]|\b)/g )
            {   $re_count += defined $1 ? $1 : 1;
            }
        }
    }

    # Strip multiple Re's from the end.

    if(@subject)
    {   for($subject[-1])
        {   $re_count++ while s/\s*\(\s*(re|forw)\W*\)\s*$//i;
        }
    }

    # Create the new subject string.

    my $text = (join ':', @subject) || 'your mail';
    for($text)
    {  s/^\s+//;
       s/\s+$//;
    }

    $re_count==1 ? "Re: $text" : "Re[$re_count]: $text";
}

#------------------------------------------


sub replyPrelude($)
{   my ($self, $who) = @_;
 
    $who = $who->[0] if ref $who eq 'ARRAY';

    my $user
     = !defined $who                     ? undef
     : !ref $who                         ? (Mail::Address->parse($who))[0]
     : $who->isa('Mail::Message::Field') ? ($who->addresses)[0]
     :                                     $who;

    my $from
     = ref $user && $user->isa('Mail::Address')
     ? ($user->name || $user->address || $user->format)
     : 'someone';

    my $time = gmtime $self->timestamp;
    "On $time, $from wrote:\n";
}

1;
