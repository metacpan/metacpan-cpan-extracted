# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box-POP3.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::POP3;
use vars '$VERSION';
$VERSION = '3.006';

use base 'Mail::Box::Net';

use strict;
use warnings;

use Mail::Box::POP3::Message;
use Mail::Box::Parser::Perl;
use Mail::Box::FastScalar;

use File::Spec;
use File::Basename;
use Carp;


sub init($)
{   my ($self, $args) = @_;

    $args->{server_port}  ||= 110;
    $args->{folder}       ||= 'inbox';
    $args->{message_type} ||= 'Mail::Box::POP3::Message';

    $self->SUPER::init($args);

    $self->{MBP_client}   = $args->{pop_client}; 
    $self->{MBP_auth}     = $args->{authenticate} || 'AUTO';
    $self->{MBP_use_ssl}  = $args->{use_ssl} || 0;
    $self->{MBP_ssl_opts} = $args->{ssl_options};

    $self;
}


sub create($@) { undef }         # fails

sub foundIn(@)
{   my $self = shift;
    unshift @_, 'folder' if @_ % 2;
    my %options = @_;

       (exists $options{type}   && lc $options{type} eq 'pop3')
    || (exists $options{folder} && $options{folder} =~ m/^pop/);
}


sub addMessage($)
{   my ($self, $message) = @_;

    $self->log(ERROR => "You cannot write a message to a pop server (yet)")
       if defined $message;

    undef;
}


sub addMessages(@)
{   my $self = shift;

    # error message described in addMessage()
    $self->log(ERROR => "You cannot write messages to a pop server (yet)")
        if @_;

    ();
}

sub type() {'pop3'}

sub close(@)
{   my $self = shift;

    $self->SUPER::close(@_);

    my $pop = delete $self->{MBP_client};
    $pop->disconnect if defined $pop;

    $self;
}


sub delete(@)
{   my $self = shift;
    $self->log(WARNING => "POP3 folders cannot be deleted.");
    undef;
}


sub listSubFolders(@) { () }     # no


sub openSubFolder($@) { undef }  # fails

sub topFolderWithMessages() { 1 }  # Yes: only top folder


sub update() {shift->notImplemented}

#-------------------------------------------


sub popClient(%)
{   my ($self, %args) = @_;

    return $self->{MBP_client}
        if defined $self->{MBP_client};

    my $auth = $self->{auth};

    require Mail::Transport::POP3;
    my $client  = Mail::Transport::POP3->new
      ( username     => $self->{MBN_username}
      , password     => $self->{MBN_password}
      , hostname     => $self->{MBN_hostname}
      , port         => $self->{MBN_port}
      , authenticate => $self->{MBP_auth}
      , use_ssl      => $args{use_ssl} || $self->{MBP_use_ssl}
      , ssl_options  => $args{ssl_options} || $self->{MBP_ssl_opts}
      );

    $self->log(ERROR => "Cannot create POP3 client for $self.")
       unless defined $client;

    $self->{MBP_client} = $client;
}

sub readMessages(@)
{   my ($self, %args) = @_;

    my $pop   = $self->popClient or return;
    my @log   = $self->logSettings;
    my $seqnr = 0;

    foreach my $id ($pop->ids)
    {   my $message = $args{message_type}->new
         ( head      => $args{head_delayed_type}->new(@log)
         , unique    => $id
         , folder    => $self
         , seqnr     => $seqnr++
         );

        my $body    = $args{body_delayed_type}->new(@log, message => $message);
        $message->storeBody($body);

        $self->storeMessage($message);
    }

    $self;
}
 

sub getHead($)
{   my ($self, $message) = @_;
    my $pop   = $self->popClient or return;

    my $uidl  = $message->unique;
    my $lines = $pop->header($uidl);

    unless(defined $lines)
    {   $lines = [];
        $self->log(WARNING  => "Message $uidl disappeared from POP3 server $self.");
    }

    my $text   = join '', @$lines;
    my $parser = Mail::Box::Parser::Perl->new   # not parseable by C parser
     ( filename  => "$pop"
     , file      => Mail::Box::FastScalar->new(\$text)
     , fix_headers => $self->{MB_fix_headers}
     );

    $self->lazyPermitted(1);

    my $head     = $message->readHead($parser);
    $parser->stop;

    $self->lazyPermitted(0);

    $self->log(PROGRESS => "Loaded head of $uidl.");
    $head;
}


sub getHeadAndBody($)
{   my ($self, $message) = @_;
    my $pop   = $self->popClient or return;

    my $uidl  = $message->unique;
    my $lines = $pop->message($uidl);

    unless(defined $lines)
    {   $lines = [];
        $self->log(WARNING  => "Message $uidl disappeared from POP3 server $self.");
     }

    my $parser = Mail::Box::Parser::Perl->new   # not parseable by C parser
     ( filename  => "$pop"
     , file      => IO::ScalarArray->new($lines)
     );

    my $head = $message->readHead($parser);
    unless(defined $head)
    {   $self->log(ERROR => "Cannot find head back for $uidl on POP3 server $self.");
        $parser->stop;
        return undef;
    }

    my $body = $message->readBody($parser, $head);
    unless(defined $body)
    {   $self->log(ERROR => "Cannot read body for $uidl on POP3 server $self.");
        $parser->stop;
        return undef;
    }

    $parser->stop;

    $self->log(PROGRESS => "Loaded message $uidl.");
    ($head, $body);
}


sub writeMessages($@)
{   my ($self, $args) = @_;

    if(my $modifications = grep {$_->isModified} @{$args->{messages}})
    {   $self->log(WARNING =>
           "Update of $modifications messages ignored for POP3 folder $self.");
    }

    $self;
}

#-------------------------------------------



1;
