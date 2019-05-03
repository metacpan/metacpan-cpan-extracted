# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box-POP3.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Transport::POP3;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Transport::Receive';

use strict;
use warnings;

use IO::Socket  ();
use Socket      qw/$CRLF/;
use Digest::MD5 qw/md5_hex/;


sub _OK($) { substr(shift // '', 0, 3) eq '+OK' }

sub init($)
{   my ($self, $args) = @_;
    $args->{via}    = 'pop3';
    $args->{port} ||= 110;

    $self->SUPER::init($args) or return;

    $self->{MTP_auth}   = $args->{authenticate} || 'AUTO';
    $self->{MTP_ssl}    = $args->{use_ssl};
    $self->socket or return;   # establish connection

    $self;
}

#------------------------------------------

sub useSSL() { shift->{MTP_ssl} }

#------------------------------------------

sub ids(;@)
{   my $self = shift;
    $self->socket or return;
    wantarray ? @{$self->{MTP_n2uidl}} : $self->{MTP_n2uidl};
}


sub messages()
{   my $self = shift;

    $self->log(ERROR =>"Cannot get the messages of pop3 via messages()."), return ()
       if wantarray;

    $self->{MTP_messages};
}


sub folderSize() { shift->{MTP_folder_size} }


sub header($;$)
{   my ($self, $uidl) = (shift, shift);
    return unless $uidl;
    my $bodylines = shift || 0;;

    my $socket    = $self->socket      or return;
    my $n         = $self->id2n($uidl) or return;

    $self->sendList($socket, "TOP $n $bodylines$CRLF");
}


sub message($;$)
{   my ($self, $uidl) = @_;
    return unless $uidl;

    my $socket  = $self->socket      or return;
    my $n       = $self->id2n($uidl) or return;
    my $message = $self->sendList($socket, "RETR $n$CRLF");

    return unless $message;

    # Some POP3 servers add a trailing empty line
    pop @$message if @$message && $message->[-1] =~ m/^[\012\015]*$/;

    $self->{MTP_fetched}{$uidl} = undef   # mark this ID as fetched
        unless exists $self->{MTP_nouidl};

    $message;
}


sub messageSize($)
{   my ($self, $uidl) = @_;
    return unless $uidl;

    my $list;
    unless($list = $self->{MTP_n2length})
    {   my $socket = $self->socket or return;
        my $raw = $self->sendList($socket, "LIST$CRLF") or return;
        my @n2length;
        foreach (@$raw)
        {   m#^(\d+) (\d+)#;
            $n2length[$1] = $2;
        }   
        $self->{MTP_n2length} = $list = \@n2length;
    }

    my $n = $self->id2n($uidl) or return;
    $list->[$n];
}


sub deleted($@)
{   my $dele = shift->{MTP_dele} ||= {};
    (shift) ? @$dele{ @_ } = () : delete @$dele{ @_ };
}


sub deleteFetched()
{   my $self = shift;
    $self->deleted(1, keys %{$self->{MTP_fetched}});
}


sub disconnect()
{   my $self = shift;

    my $quit;
    if($self->{MTP_socket}) # can only disconnect once
    {   if(my $socket = $self->socket)
        {   my $dele  = $self->{MTP_dele} || {};
            while(my $uidl = each %$dele)
            {   my $n = $self->id2n($uidl) or next;
                $self->send($socket, "DELE $n$CRLF") or last;
            }

            $quit = $self->send($socket, "QUIT$CRLF");
            close $socket;
        }
    }

    delete @$self{ qw(
     MTP_socket
     MTP_dele
     MTP_uidl2n
     MTP_n2uidl
     MTP_n2length
     MTP_fetched
    ) };

    _OK $quit;
}


sub fetched(;$)
{   my $self = shift;
    return if exists $self->{MTP_nouidl};
    $self->{MTP_fetched};
}


sub id2n($;$) { shift->{MTP_uidl2n}{shift()} }

#------------------------------------------


sub socket()
{   my $self = shift;

    # Do we (still) have a working connection which accepts commands?
    my $socket = $self->_connection;
    return $socket if defined $socket;

    if(exists $self->{MTP_nouidl})
    {   $self->log(ERROR =>
           "Can not re-connect reliably to server which doesn't support UIDL");
        return;
    }

    # (Re-)establish the connection
    $socket = $self->login or return;
    $self->status($socket) or return;
    $self->{MTP_socket} = $socket;
}



sub send($$)
{   my $self = shift;
    my $socket = shift;
    my $response;
   
    if(eval {print $socket @_})
    {   $response = <$socket>;
        $self->log(ERROR => "Cannot read POP3 from socket: $!")
           unless defined $response;
    }
    else
    {   $self->log(ERROR => "Cannot write POP3 to socket: $@");
    }
    $response;
}


sub sendList($$)
{   my ($self, $socket) = (shift, shift);
    my $response = $self->send($socket, @_);
    $response && _OK $response or return;

    my @list;
    while(my $line = <$socket>)
    {   last if $line =~ m#^\.\r?\n#s;
        $line =~ s#^\.##;
        push @list, $line;
    }

    \@list;
}

sub DESTROY()
{   my $self = shift;
    $self->SUPER::DESTROY;
    $self->disconnect if $self->{MTP_socket}; # only when open
}

sub _connection()
{   my $self = shift;

    my $socket = $self->{MTP_socket};
    defined $socket or return;

    # Check if we (still) got a connection
    eval { print $socket "NOOP$CRLF" };
    if($@ || ! <$socket> )
    {   delete $self->{MTP_socket};
        return undef;
    }

    $socket;
}



sub login(;$)
{   my $self = shift;

    # Check if we can make a connection

    my ($host, $port, $username, $password) = $self->remoteHost;
    unless($username && $password)
    {   $self->log(ERROR => "POP3 requires a username and password.");
        return;
    }

    my $net    = $self->useSSL ? 'IO::Socket::SSL' : 'IO::Socket::INET';
    eval "require $net" or die $@;

    my $socket = eval { $net->new("$host:$port") };
    unless($socket)
    {   $self->log(ERROR => "Cannot connect to $host:$port for POP3: $!");
        return;
    }

    # Check if it looks like a POP server

    my $connected;
    my $authenticate = $self->{MTP_auth};
    my $welcome      = <$socket>;
    unless(_OK $welcome)
    {   $self->log(ERROR =>
           "Server at $host:$port does not seem to be talking POP3.");
        return;
    }

    # Check APOP login if automatic or APOP specifically requested
    if($authenticate eq 'AUTO' || $authenticate eq 'APOP')
    {   if($welcome =~ m#^\+OK .*(<\d+\.\d+\@[^>]+>)#)
        {   my $md5      = md5_hex $1.$password;
            my $response = $self->send($socket, "APOP $username $md5$CRLF");
            $connected   = _OK $response;
        }
    }

    # Check USER/PASS login if automatic and failed or LOGIN specifically
    # requested.
    unless($connected)
    {   if($authenticate eq 'AUTO' || $authenticate eq 'LOGIN')
        {   my $response = $self->send($socket, "USER $username$CRLF")
               or return;

            if(_OK $response)
            {   my $response2 = $self->send($socket, "PASS $password$CRLF")
                   or return;
                $connected = _OK $response2;
            }
        }
    }

    # If we're still not connected now, we have an error
    unless($connected)
    {   $self->log(ERROR => $authenticate eq 'AUTO' ?
         "Could not authenticate using any login method" :
         "Could not authenticate using '$authenticate' method");
        return;
    }

    $socket;
}



sub status($;$)
{   my ($self, $socket) = @_;

    # Check if we can do a STAT

    my $stat = $self->send($socket, "STAT$CRLF") or return;
    if($stat !~ m#^\+OK (\d+) (\d+)#)
    {   delete $self->{MTP_messages};
        delete $self->{MTP_size};
        $self->log(ERROR => "POP3 Could not do a STAT");
        return;
    }
    $self->{MTP_messages}    = my $nr_msgs = $1;
    $self->{MTP_folder_size} = $2;

    # Check if we can do a UIDL

    my $uidl = $self->send($socket, "UIDL$CRLF") or return;
    $self->{MTP_nouidl} = undef;
    delete $self->{MTP_uidl2n}; # drop the reverse lookup: UIDL -> number

    if(_OK $uidl)
    {   my @n2uidl;
        $n2uidl[$nr_msgs] = undef; # pre-alloc

        while(my $line = <$socket>)
        {   last if substr($line, 0, 1) eq '.';
            $line =~ m#^(\d+) (.+?)\r?\n# or next;
            $n2uidl[$1] = $2;
        }

        shift @n2uidl; # make message 1 into index 0
        $self->{MTP_n2uidl} = \@n2uidl;
        delete $self->{MTP_n2length};
        delete $self->{MTP_nouidl};
    }
    else
    {   # We can't do UIDL, we need to fake it
        my $list = $self->send($socket, "LIST$CRLF") or return;
        my (@n2length, @n2uidl);

        if(_OK $list)
        {   $n2length[$nr_msgs] = $n2uidl[$nr_msgs] = undef; # alloc all

            my ($host, $port)    = $self->remoteHost;
            while(my $line = <$socket>)
            {   last if substr($line, 0, 1) eq '.';
                $line =~ m#^(\d+) (\d+)# or next;
                $n2length[$1] = $2;
                $n2uidl[$1]   = "$host:$port:$1"; # fake UIDL, for id only
            }
            shift @n2length; shift @n2uidl; # make 1st message in index 0
        }
        $self->{MTP_n2length} = \@n2length;
        $self->{MTP_n2uidl}   = \@n2uidl;
    }

    my $i = 1;
    my %uidl2n = map +($_ => $i++), @{$self->{MTP_n2uidl}};
    $self->{MTP_uidl2n} = \%uidl2n;

    1;
}

#------------------------------------------


sub url(;$)
{   my $self = shift;
    my ($host, $port, $user, $pwd) = $self->remoteHost;
    my $proto = $self->useSSL ? 'pop3s' : 'pop3';
    "$proto://$user:$pwd\@$host:$port";
}

#------------------------------------------


1;
