# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box-IMAP4.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::IMAP4;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Box::Net';

use strict;
use warnings;

use Mail::Box::IMAP4::Message;
use Mail::Box::IMAP4::Head;
use Mail::Transport::IMAP4;

use Mail::Box::Parser::Perl;
use Mail::Message::Head::Complete;
use Mail::Message::Head::Delayed;

use Scalar::Util 'weaken';


sub init($)
{   my ($self, $args) = @_;

    my $folder = $args->{folder};

    # MailBox names top folder directory '=', but IMAP needs '/'
    $folder = '/'
        if ! defined $folder || $folder eq '=';

    # There's a disconnect between the URL parser and this code.
    # The URL parser always produces a full path (beginning with /)
    # while this code expects to NOT get a full path.  So, we'll
    # trim the / from the front of the path.
    # Also, this code can't handle a trailing slash and there's
    # no reason to ever offer one.  Strip that too.
    if($folder ne '/')
    {   $folder =~ s,^/+,,g;
        $folder =~ s,/+$,,g;
    }

    $args->{folder} = $folder;

    my $access    = $args->{access} ||= 'r';
    my $writeable = $access =~ m/w|a/;
    my $ch        = $self->{MBI_c_head}
      = $args->{cache_head} || ($writeable ? 'NO' : 'DELAY');

    $args->{head_type}    ||= 'Mail::Box::IMAP4::Head'
        if $ch eq 'NO' || $ch eq 'PARTIAL';

    $args->{body_type}    ||= 'Mail::Message::Body::Lines';
	$args->{message_type} ||= 'Mail::Box::IMAP4::Message';

    $self->SUPER::init($args);

    $self->{MBI_domain}   = $args->{domain};
    $self->{MBI_c_labels}
      = $args->{cache_labels} || ($writeable ? 'NO' : 'DELAY');
    $self->{MBI_c_body}
      = $args->{cache_body}   || ($writeable ? 'NO' : 'DELAY');


    my $transport = $args->{transporter} || 'Mail::Transport::IMAP4';
    $transport = $self->createTransporter($transport, %$args)
        unless ref $transport;

    $self->transporter($transport);

    defined $transport
        or return;

      $args->{create}
    ? $self->create($transport, $args)
    : $self;
}

sub create($@)
{   my($self, $name, $args) =  @_;

    if($args->{access} !~ /w|a/)
    {   $self->log(ERROR =>
           "You must have write access to create folder $name.");
        return undef;
    }

    $self->transporter->createFolder($name);
}

sub foundIn(@)
{   my $self = shift;
    unshift @_, 'folder' if @_ % 2;
    my %options = @_;

       (exists $options{type}   && $options{type}   =~ m/^imap/i)
    || (exists $options{folder} && $options{folder} =~ m/^imap/);
}

sub type() {'imap4'}



sub close(@)
{   my $self = shift;
    $self->SUPER::close(@_) or return ();
    $self->transporter(undef);
    $self;
}

sub listSubFolders(@)
{   my ($thing, %args) = @_;
    my $self = $thing;

    $self = $thing->new(%args) or return ()  # list toplevel
        unless ref $thing;

    my $imap = $self->transporter;
    defined $imap ? $imap->folders($self) : ();
}

sub nameOfSubfolder($;$) { $_[1] }

#-------------------------------------------

sub readMessages(@)
{   my ($self, %args) = @_;

    my $name  = $self->name;
    return $self if $name eq '/';

    my $imap  = $self->transporter;
    defined $imap or return ();

    my @log   = $self->logSettings;
    my $seqnr = 0;

    my $cl    = $self->{MBI_c_labels} ne 'NO';
    my $wl    = $self->{MBI_c_labels} ne 'DELAY';

    my $ch    = $self->{MBI_c_head};
    my $ht    = $ch eq 'DELAY' ? $args{head_delayed_type} : $args{head_type};
    my @ho    = $ch eq 'PARTIAL' ? (cache_fields => 1) : ();

    $self->{MBI_selectable}
        or return $self;

    foreach my $id ($imap->ids)
    {   my $head    = $ht->new(@log, @ho);
        my $message = $args{message_type}->new
         ( head      => $head
         , unique    => $id
         , folder    => $self
         , seqnr     => $seqnr++

         , cache_labels => $cl
         , write_labels => $wl
         , cache_head   => ($ch eq 'DELAY')
         , cache_body   => ($ch ne 'NO')
         );

        my $body    = $args{body_delayed_type}
           ->new(@log, message => $message);

        $message->storeBody($body);

        $self->storeMessage($message);
    }

    $self;
}
 


sub getHead($)
{   my ($self, $message) = @_;
    my $imap   = $self->transporter or return;

    my $uidl   = $message->unique;
    my @fields = $imap->getFields($uidl, 'ALL');

    unless(@fields)
    {   $self->log(WARNING => "Message $uidl disappeared from $self.");
        return;
    }

    my $head = $self->{MB_head_type}->new;
    $head->addNoRealize($_) for @fields;

    $self->log(PROGRESS => "Loaded head of $uidl.");
    $head;
}



sub getHeadAndBody($)
{   my ($self, $message) = @_;
    my $imap  = $self->transporter or return;
    my $uid   = $message->unique;
    my $lines = $imap->getMessageAsString($uid);

    unless(defined $lines)
    {   $self->log(WARNING => "Message $uid disappeared from $self.");
        return ();
     }

    my $parser = Mail::Box::Parser::Perl->new   # not parseable by C parser
     ( filename  => "$imap"
     , file      => Mail::Box::FastScalar->new(\$lines)
     );

    my $head = $message->readHead($parser);
    unless(defined $head)
    {   $self->log(WARNING => "Cannot find head back for $uid in $self.");
        $parser->stop;
        return ();
    }

    my $body = $message->readBody($parser, $head);
    unless(defined $body)
    {   $self->log(WARNING => "Cannot read body for $uid in $self.");
        $parser->stop;
        return ();
    }

    $parser->stop;

    $self->log(PROGRESS => "Loaded message $uid.");
    ($head, $body->contentInfoFrom($head));
}



sub body(;$)
{   my $self = shift;
    unless(@_)
    {   my $body = $self->{MBI_cache_body} ? $self->SUPER::body : undef;
    }

    $self->unique();
    $self->SUPER::body(@_);
}



sub write(@)
{   my ($self, %args) = @_;
    my $imap  = $self->transporter or return;

    $self->SUPER::write(%args, transporter => $imap) or return;

    if($args{save_deleted})
    {   $self->log(NOTICE => "Impossible to keep deleted messages in IMAP");
    }
    else { $imap->destroyDeleted($self->name) }

    $self;
}

sub delete(@)
{   my $self   = shift;
    my $transp = $self->transporter;
    $self->SUPER::delete(@_);   # subfolders
    $transp->deleteFolder($self->name);
}



sub writeMessages($@)
{   my ($self, $args) = @_;

    my $imap = $args->{transporter};
    my $fn   = $self->name;

    $_->writeDelayed($fn, $imap) for @{$args->{messages}};

    $self;
}



my %transporters;
sub createTransporter($@)
{   my ($self, $class, %args) = @_;

    my $hostname = $self->{MBN_hostname} || 'localhost';
    my $port     = $self->{MBN_port}     || '143';
    my $username = $self->{MBN_username} || $ENV{USER};

    my $join     = exists $args{join_connection} ? $args{join_connection} : 1;

    my $linkid;
    if($join)
    {   $linkid  = "$hostname:$port:$username";
        return $transporters{$linkid} if defined $transporters{$linkid};
    }

    my $transporter = $class->new
     ( %args,
     , hostname => $hostname, port     => $port
     , username => $username, password => $self->{MBN_password}
     , domain   => $self->{MBI_domain}
     ) or return undef;

    if(defined $linkid)
    {   $transporters{$linkid} = $transporter;
        weaken($transporters{$linkid});
    }

    $transporter;
}



sub transporter(;$)
{   my $self = shift;

    my $imap;
    if(@_)
    {   $imap = $self->{MBI_transport} = shift;
        defined $imap or return;
    }
    else
    {   $imap = $self->{MBI_transport};
    }

    unless(defined $imap)
    {   $self->log(ERROR => "No IMAP4 transporter configured");
        return undef;
    }

    my $name = $self->name;

    $self->{MBI_selectable} = $imap->currentFolder($name);
    return $imap
        if defined $self->{MBI_selectable};

    $self->log(ERROR => "Couldn't select IMAP4 folder $name");
    undef;
}



sub fetch($@)
{   my ($self, $what, @info) = @_;
    my $imap = $self->transporter or return [];
    $what = $self->messages($what) unless ref $what eq 'ARRAY';
    $imap->fetch($what, @info);
}


#-------------------------------------------

1;
