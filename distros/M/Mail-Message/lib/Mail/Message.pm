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

use base 'Mail::Reporter';

use strict;
use warnings;

use Mail::Message::Part ();
use Mail::Message::Head::Complete ();
use Mail::Message::Construct ();

use Mail::Message::Body::Lines ();
use Mail::Message::Body::Multipart ();
use Mail::Message::Body::Nested ();

use Carp;
use Scalar::Util   qw(weaken blessed);

BEGIN {
    unless($ENV{HARNESS_ACTIVE}) {   # no tests during upgrade
        # v3 splits Mail::Box in a few distributions
		eval { require Mail::Box };
		my $v = $Mail::Box::VERSION || 3;
		$v >= 3 or die "You need to upgrade the Mail::Box module";
    }
}


our $crlf_platform = $^O =~ m/win32/i;

#------------------------------------------


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    # Field initializations also in coerce()
    $self->{MM_modified} = $args->{modified}  || 0;
    $self->{MM_trusted}  = $args->{trusted}   || 0;

    # Set the header

    my $head;
    if(defined($head = $args->{head})) { $self->head($head) }
    elsif(my $msgid = $args->{messageId} || $args->{messageID})
    {   $self->takeMessageId($msgid);
    }

    # Set the body
    if(my $body = $args->{body})
    {   $self->{MM_body} = $body;
        $body->message($self);
    }

    $self->{MM_body_type} = $args->{body_type}
       if defined $args->{body_type};

    $self->{MM_head_type} = $args->{head_type}
       if defined $args->{head_type};

    $self->{MM_field_type} = $args->{field_type}
       if defined $args->{field_type};

    my $labels = $args->{labels} || [];
    my @labels = ref $labels eq 'ARRAY' ? @$labels : %$labels;
    push @labels, deleted => $args->{deleted} if exists $args->{deleted};
    $self->{MM_labels} = { @labels };

    $self;
}


sub clone(@)
{   my ($self, %args) = @_;

    # First clone body, which may trigger head load as well.  If head is
    # triggered first, then it may be decided to be lazy on the body at
    # moment.  And then the body would be triggered.

    my ($head, $body) = ($self->head, $self->body);
    $head = $head->clone
       unless $args{shallow} || $args{shallow_head};

    $body = $body->clone
       unless $args{shallow} || $args{shallow_body};

    my $clone = Mail::Message->new
     ( head  => $head
     , body  => $body
     , $self->logSettings
     );

    my $labels = $self->labels;
    my %labels = %$labels;
    delete $labels{deleted};

    $clone->{MM_labels} = \%labels;

    $clone->{MM_cloned} = $self;
    weaken($clone->{MM_cloned});

    $clone;
}

#------------------------------------------


sub messageId() { $_[0]->{MM_message_id} || $_[0]->takeMessageId}
sub messageID() {shift->messageId}   # compatibility


sub container() { undef } # overridden by Mail::Message::Part


sub isPart() { 0 } # overridden by Mail::Message::Part


sub partNumber()
{   my $self = shift;
    my $cont = $self->container;
    $cont ? $cont->partNumber : undef;
}


sub toplevel() { shift } # overridden by Mail::Message::Part


sub isDummy() { 0 }


sub print(;$)
{   my $self = shift;
    my $out  = shift || select;

    $self->head->print($out);
    my $body = $self->body;
    $body->print($out) if $body;
    $self;
}


sub write(;$)
{   my $self = shift;
    my $out  = shift || select;

    $self->head->print($out);
    $self->body->print($out);
    $self;
}


my $default_mailer;

sub send(@)
{   my $self = shift;

	# Loosely coupled module
    require Mail::Transport::Send;

    my $mailer;
    $default_mailer = $mailer = shift
        if ref $_[0] && $_[0]->isa('Mail::Transport::Send');

    my %args = @_;
    if( ! $args{via} && defined $default_mailer )
    {   $mailer = $default_mailer;
    }
    else
    {   my $via = delete $args{via} || 'sendmail';
        $default_mailer = $mailer = Mail::Transport->new(via => $via, %args);
    }

    $mailer->send($self, %args);
}


sub size()
{   my $self = shift;
    $self->head->size + $self->body->size;
}

#------------------------------------------


sub head(;$)
{   my $self = shift;
    return $self->{MM_head} unless @_;

    my $head = shift;
    unless(defined $head)
    {   delete $self->{MM_head};
        return undef;
    }

    $self->log(INTERNAL => "wrong type of head ($head) for message $self")
        unless ref $head && $head->isa('Mail::Message::Head');

    $head->message($self);

    if(my $old = $self->{MM_head})
    {   $self->{MM_modified}++ unless $old->isDelayed;
    }

    $self->{MM_head} = $head;

    $self->takeMessageId unless $head->isDelayed;

    $head;
}


sub get($)
{   my $self  = shift;
    my $field = $self->head->get(shift) || return undef;
    $field->body;
}


sub study($)
{  my $head = shift->head or return;
   scalar $head->study(@_);    # return only last
}


sub from()
{  my @from = shift->head->get('From') or return ();
   map $_->addresses, @from;
}


sub sender()
{   my $self   = shift;
    my $sender = $self->head->get('Sender') || $self->head->get('From')
               || return ();

    ($sender->addresses)[0];                 # first specified address
}


sub to() { map $_->addresses, shift->head->get('To') }


sub cc() { map $_->addresses, shift->head->get('Cc') }


sub bcc() { map $_->addresses, shift->head->get('Bcc') }


sub destinations()
{   my $self = shift;
    my %to = map +(lc($_->address) => $_), $self->to, $self->cc, $self->bcc;
    values %to;
}


sub subject()
{   my $subject = shift->get('subject');
    defined $subject ? $subject : '';
}


sub guessTimestamp() {shift->head->guessTimestamp}


sub timestamp()
{   my $head = shift->head;
    $head->recvstamp || $head->timestamp;
}


sub nrLines()
{   my $self = shift;
    $self->head->nrLines + $self->body->nrLines;
}

#-------------------------------------------

  
sub body(;$@)
{   my $self = shift;
    return $self->{MM_body} unless @_;

    my $head = $self->head;
    $head->removeContentInfo if defined $head;

    my ($rawbody, %args) = @_;
    unless(defined $rawbody)
    {   # Disconnect body from message.
        my $body = delete $self->{MM_body};
        $body->message(undef) if defined $body;
        return $body;
    }

    ref $rawbody && $rawbody->isa('Mail::Message::Body')
        or $self->log(INTERNAL => "wrong type of body for message $rawbody");

    # Bodies of real messages must be encoded for safe transmission.
    # Message parts will get encoded on the moment the whole multipart
    # is transformed into a real message.

    my $body = $self->isPart ? $rawbody : $rawbody->encoded;
    $body->contentInfoTo($self->head);

    my $oldbody = $self->{MM_body};
    return $body if defined $oldbody && $body==$oldbody;

    $body->message($self);
    $body->modified(1) if defined $oldbody;

    $self->{MM_body} = $body;
}


sub decoded(@)
{   my $body = shift->body->load;
    $body ? $body->decoded(@_) : undef;
}


sub encode(@)
{   my $body = shift->body->load;
    $body ? $body->encode(@_) : undef;
}


sub isMultipart() {shift->head->isMultipart}


sub isNested() {shift->body->isNested}


sub contentType()
{   my $head = shift->head;
    my $ct   = (defined $head ? $head->get('Content-Type', 0) : undef) || '';
    $ct      =~ s/\s*\;.*//;
    length $ct ? $ct : 'text/plain';
}


sub parts(;$)
{   my $self    = shift;
    my $what    = shift || 'ACTIVE';

    my $body    = $self->body;
    my $recurse = $what eq 'RECURSE' || ref $what;

    my @parts
     = $body->isNested     ? $body->nested->parts($what)
     : $body->isMultipart  ? $body->parts($recurse ? 'RECURSE' : ())
     :                       $self;

      ref $what eq 'CODE' ? (grep $what->($_), @parts)
    : $what eq 'ACTIVE'   ? (grep !$_->isDeleted, @parts)
    : $what eq 'DELETED'  ? (grep $_->isDeleted, @parts)
    : $what eq 'ALL'      ? @parts
    : $recurse            ? @parts
    : confess "Select parts via $what?";
}

#------------------------------------------


sub modified(;$)
{   my $self = shift;

    return $self->isModified unless @_;  # compatibility 2.036

    my $flag = shift;
    $self->{MM_modified} = $flag;
    my $head = $self->head;
    $head->modified($flag) if $head;
    my $body = $self->body;
    $body->modified($flag) if $body;

    $flag;
}


sub isModified()
{   my $self = shift;
    return 1 if $self->{MM_modified};

    my $head = $self->head;
    if($head && $head->isModified)
    {   $self->{MM_modified}++;
        return 1;
    }

    my $body = $self->body;
    if($body && $body->isModified)
    {   $self->{MM_modified}++;
        return 1;
    }

    0;
}


sub label($;$@)
{   my $self   = shift;
    return $self->{MM_labels}{$_[0]} unless @_ > 1;
    my $return = $_[1];

    my %labels = @_;
    @{$self->{MM_labels}}{keys %labels} = values %labels;
    $return;
}


sub labels()
{   my $self = shift;
    wantarray ? keys %{$self->{MM_labels}} : $self->{MM_labels};
}


sub isDeleted() { shift->label('deleted') }


sub delete()
{  my $self = shift;
   my $old = $self->label('deleted');
   $old || $self->label(deleted => time);
}


sub deleted(;$)
{   my $self = shift;

    @_ ? $self->label(deleted => shift)
       : $self->label('deleted')   # compat 2.036
}


sub labelsToStatus()
{   my $self    = shift;
    my $head    = $self->head;
    my $labels  = $self->labels;

    my $status  = $head->get('status') || '';
    my $newstatus
      = $labels->{seen}    ? 'RO'
      : $labels->{old}     ? 'O'
      : '';

    $head->set(Status => $newstatus)
        if $newstatus ne $status;

    my $xstatus = $head->get('x-status') || '';
    my $newxstatus
      = ($labels->{replied} ? 'A' : '')
      . ($labels->{flagged} ? 'F' : '');

    $head->set('X-Status' => $newxstatus)
        if $newxstatus ne $xstatus;

    $self;
}


sub statusToLabels()
{   my $self    = shift;
    my $head    = $self->head;

    if(my $status  = $head->get('status'))
    {   $status = $status->foldedBody;
        $self->label
         ( seen    => (index($status, 'R') >= 0)
         , old     => (index($status, 'O') >= 0)
	 );
    }

    if(my $xstatus = $head->get('x-status'))
    {   $xstatus = $xstatus->foldedBody;
        $self->label
         ( replied => (index($xstatus, 'A') >= 0)
         , flagged => (index($xstatus, 'F') >= 0)
	 );
    }

    $self;
}

#------------------------------------------


my $mail_internet_converter;
my $mime_entity_converter;
my $email_simple_converter;

sub coerce($@)
{   my ($class, $message) = @_;

    blessed $message
        or die "coercion starts with some object";

	return $message
		if ref $message eq $class;

    if($message->isa(__PACKAGE__)) {
        $message->head->modified(1);
        $message->body->modified(1);
        return bless $message, $class;
	}

    if($message->isa('MIME::Entity'))
    {   unless($mime_entity_converter)
        {   eval {require Mail::Message::Convert::MimeEntity};
                confess "Install MIME::Entity" if $@;
            $mime_entity_converter = Mail::Message::Convert::MimeEntity->new;
        }

        $message = $mime_entity_converter->from($message)
            or return;
    }

    elsif($message->isa('Mail::Internet'))
    {   unless($mail_internet_converter)
        {   eval {require Mail::Message::Convert::MailInternet};
            confess "Install Mail::Internet" if $@;
            $mail_internet_converter = Mail::Message::Convert::MailInternet->new;
        }

        $message = $mail_internet_converter->from($message)
            or return;
    }

    elsif($message->isa('Email::Simple'))
    {   unless($email_simple_converter)
        {   eval {require Mail::Message::Convert::EmailSimple};
            confess "Install Email::Simple" if $@;
            $email_simple_converter = Mail::Message::Convert::EmailSimple->new;
        }

        $message = $email_simple_converter->from($message)
            or return;
    }

    elsif($message->isa('Email::Abstract'))
    {   return $class->coerce($message->object);
    }

    else
    {   $class->log(INTERNAL =>  "Cannot coerce a ". ref($message)
              . " object into a ". __PACKAGE__." object");
    }

    $message->{MM_modified}  ||= 0;
    bless $message, $class;
}


sub clonedFrom() { shift->{MM_cloned} }

#------------------------------------------
# All next routines try to create compatibility with release < 2.0
sub isParsed()   { not shift->isDelayed }
sub headIsRead() { not shift->head->isDelayed }


sub readFromParser($;$)
{   my ($self, $parser, $bodytype) = @_;

    my $head = $self->readHead($parser)
     || Mail::Message::Head::Complete->new
          ( message     => $self
          , field_type  => $self->{MM_field_type}
          , $self->logSettings
          );

    my $body = $self->readBody($parser, $head, $bodytype)
        or return;

    $self->head($head);
    $self->storeBody($body);
    $self;
}


sub readHead($;$)
{   my ($self, $parser) = (shift, shift);

    my $headtype = shift
      || $self->{MM_head_type} || 'Mail::Message::Head::Complete';

    $headtype->new
      ( message     => $self
      , field_type  => $self->{MM_field_type}
      , $self->logSettings
      )->read($parser);
}


sub readBody($$;$$)
{   my ($self, $parser, $head, $getbodytype) = @_;

    my $bodytype
      = ! $getbodytype   ? ($self->{MM_body_type} || 'Mail::Message::Body::Lines')
      : ref $getbodytype ? $getbodytype->($self, $head)
      :                    $getbodytype;

    my $body;
    if($bodytype->isDelayed)
    {   $body = $bodytype->new
          ( message => $self
          , charset => undef     # we do not know, autodetect after transfer decode
          , $self->logSettings
          );
    }
    else
    {   my $ct   = $head->get('Content-Type', 0);
        my $type = defined $ct ? lc($ct->body) : 'text/plain';

        # Be sure you have acceptable bodies for multiparts and nested.
        if(substr($type, 0, 10) eq 'multipart/' && !$bodytype->isMultipart)
        {   $bodytype = 'Mail::Message::Body::Multipart';
        }
        elsif($type eq 'message/rfc822')
        {   my $enc = $head->get('Content-Transfer-Encoding') || 'none';
            $bodytype = 'Mail::Message::Body::Nested'
                if lc($enc) eq 'none' && ! $bodytype->isNested;
        }

        $body = $bodytype->new
          ( message => $self
          , checked => $self->{MM_trusted}
          , charset => undef
          , $self->logSettings
          );

        $body->contentInfoFrom($head);
    }

    my $lines   = $head->get('Lines');  # usually off-by-one
    my $size    = $head->guessBodySize;

    $body->read
      ( $parser, $head, $getbodytype,
      , $size, (defined $lines ? $lines : undef)
      );
}


sub storeBody($)
{   my ($self, $body) = @_;
    $self->{MM_body} = $body;
    $body->message($self);
    $body;
}


sub isDelayed()
{    my $body = shift->body;
     !$body || $body->isDelayed;
}


sub takeMessageId(;$)
{   my $self  = shift;
    my $msgid = (@_ ? shift : $self->get('Message-ID')) || '';

    if($msgid =~ m/\<([^>]*)\>/s)
    {   $msgid = $1;
        $msgid =~ s/\s//gs;
    }
 
    $msgid = $self->head->createMessageId
        unless length $msgid;

    $self->{MM_message_id} = $msgid;
}

#------------------------------------------


sub shortSize(;$)
{   my $self = shift;
    my $size = shift;
    $size = $self->head->guessBodySize unless defined $size;

      !defined $size     ? '?'
    : $size < 1_000      ? sprintf "%3d "  , $size
    : $size < 10_000     ? sprintf "%3.1fK", $size/1024
    : $size < 1_000_000  ? sprintf "%3.0fK", $size/1024
    : $size < 10_000_000 ? sprintf "%3.1fM", $size/(1024*1024)
    :                      sprintf "%3.0fM", $size/(1024*1024);
}


sub shortString()
{   my $self    = shift;
    sprintf "%4s %-30.30s", $self->shortSize, $self->subject;
}

#------------------------------------------


sub destruct() { $_[0] = undef }

#------------------------------------------


1;
