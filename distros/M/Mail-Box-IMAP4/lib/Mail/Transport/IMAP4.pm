# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box-IMAP4.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Transport::IMAP4;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Transport::Receive';

use strict;
use warnings;

use Digest::HMAC_MD5;   # only availability check for CRAM_MD5
use Mail::IMAPClient  ();
use List::Util        qw/first/;


sub init($)
{   my ($self, $args) = @_;

    my $imap = $args->{imap_client} || 'Mail::IMAPClient';
    if(ref $imap)
    {   $args->{port}     = $imap->Port;
        $args->{hostname} = $imap->Server;
        $args->{username} = $imap->User;
        $args->{password} = $imap->Password;
    }
    else
    {   $args->{port}   ||= $args->{ssl} ? 993 : 143;
    }

    $args->{via}        ||= 'imap4';

    $self->SUPER::init($args) or return;

    $self->authentication($args->{authenticate} || 'AUTO');
    $self->{MTI_domain} = $args->{domain};

    unless(ref $imap)
    {   # Create the IMAP transporter
        my %opts;
		$opts{ucfirst lc} = delete $args->{$_}
			for grep /^[A-Z]/, keys %$args;

		# backwards compatibility
		$opts{Starttls}      ||= $args->{starttls};
		my $ssl = $opts{Ssl} ||= $args->{ssl};

		$opts{Ssl} = [ %$ssl ] if ref $ssl eq 'HASH';

        $imap = $self->createImapClient($imap, %opts)
             or return undef;
    }
 
    $self->imapClient($imap) or return undef;
    $self->login             or return undef;
    $self;
}

sub url()
{   my $self = shift;
    my ($host, $port, $user, $pwd) = $self->remoteHost;
    my $name = $self->folderName;
    my $proto = $self->usesSSL ? 'imap4s' : 'imap4';
    "$proto://$user:$pwd\@$host:$port$name";
}

#------------------------------------------


sub usesSSL() { shift->imapClient->Ssl }


sub authentication(@)
{   my ($self, @types) = @_;

    # What the client wants to use to login

    @types
        or @types = exists $self->{MTI_auth} ? @{$self->{MTI_auth}} : 'AUTO';

    @types = qw/CRAM-MD5 DIGEST-MD5 PLAIN NTLM LOGIN/
        if @types == 1 && $types[0] eq 'AUTO';

    $self->{MTI_auth} = \@types;

    my @clientside;
    foreach my $auth (@types)
    {   push @clientside
         , ref $auth eq 'ARRAY' ? $auth
         : $auth eq 'NTLM'      ? [ NTLM  => \&Authen::NTLM::ntlm ]
         :                        [ $auth => undef ];
    }

    my %clientside = map +($_->[0] => $_), @clientside;

    # What does the server support? in its order of preference.

    my $imap = $self->imapClient or return ();
    my @serverside = map { m/^AUTH=(\S+)/ ? uc($1) : () }
                        $imap->capability;

    my @auth;
    if(@serverside)  # server list auth capabilities
    {   @auth = map { $clientside{$_} ? delete $clientside{$_} : () }
             @serverside;
    }
    @auth = @clientside unless @auth;  # fallback to client's preference

    @auth;
}


sub domain(;$)
{   my $self = shift;
    return $self->{MTI_domain} = shift if @_;
    $self->{MTI_domain} || ($self->remoteHost)[0];
}

#------------------------------------------


sub imapClient(;$)
{   my $self = shift;
    @_ ? ($self->{MTI_client} = shift) : $self->{MTI_client};
}


sub createImapClient($@)
{   my ($self, $class, @args) = @_;

    my ($host, $port) = $self->remoteHost;

    my $debug_level = $self->logPriority('DEBUG')+0;
    if($self->log <= $debug_level || $self->trace <= $debug_level)
    {   tie *dh, 'Mail::IMAPClient::Debug', $self;
        push @args, Debug => 1, Debug_fh => \*dh;
    }

    my $client = $class->new
      ( Server => $host, Port => $port
      , User   => undef, Password => undef   # disable auto-login
      , Uid    => 1                          # Safer
      , Peek   => 1                          # Don't set \Seen automaticly
      , @args
      );

    $self->log(ERROR => $@), return undef if $@;
    $client;
}


sub login(;$)
{   my $self = shift;
    my $imap = $self->imapClient;

    return $self if $imap->IsAuthenticated;

    my ($interval, $retries, $timeout) = $self->retry;

    my ($host, $port, $username, $password) = $self->remoteHost;
    unless(defined $username)
    {   $self->log(ERROR => "IMAP4 requires a username and password");
        return;
    }
    unless(defined $password)
    {   $self->log(ERROR => "IMAP4 username $username requires a password");
        return;
    }

    my $warn_fail;
    while(1)
    {
        foreach my $auth ($self->authentication)
        {   my ($mechanism, $challenge) = @$auth;

            $imap->User(undef);
            $imap->Password(undef);
            $imap->Authmechanism(undef);   # disable auto-login
            $imap->Authcallback(undef);

            unless($imap->connect)
            {   $self->log(ERROR => "IMAP cannot connect to $host: "
                  , $imap->LastError);
                return undef;
            }

            $imap->User($username);
            $imap->Password($password);
            $imap->Authmechanism($mechanism);
            $imap->Authcallback($challenge) if defined $challenge;

            if($imap->login)
            {
                $self->log(NOTICE => "IMAP4 authenication $mechanism to "
                    . "$username\@$host:$port successful");
                return $self;
            }
        }

        $self->log(ERROR => "Couldn't contact to $username\@$host:$port")
            , return undef if $retries > 0 && --$retries == 0;

        $warn_fail++
            or $self->log(WARNING => "Failed attempt to login $username\@$host"
                . ", retrying ".($retries+1)." times");

        sleep $interval if $interval;
    }

    undef;
}


sub currentFolder(;$)
{   my $self = shift;
    return $self->{MTI_folder} unless @_;

    my $name = shift;

    if(defined $self->{MTI_folder} && $name eq $self->{MTI_folder})
    {   $self->log(DEBUG => "Folder $name already selected.");
        return $name;
    }

    # imap first deselects the old folder so if the next call
    # fails the server will not have anything selected.
    $self->{MTI_folder} = undef;

    my $imap = $self->imapClient or return;

    if($name eq '/' || $imap->select($name))
    {   $self->{MTI_folder} = $name;
        $self->log(NOTICE => "Selected folder $name");
        return 1;
    }

    # Just because we couldn't select the folder that doesn't mean it doesn't
    # exist.  It just means that this particular imap client is warning us
    # that it can't contain messages.  So we'll verify that it does exist
    # and, if so, we'll pretend like we could have selected it as if it were
    # a regular folder.
    # IMAPClient::exists() only works reliably for leaf folders so we need
    # to grep for it ourselves.

    if(first { $_ eq $name } $self->folders)
    {   $self->{MTI_folder} = $name;
        $self->log(NOTICE => "Couldn't select $name but it does exist.");
        return 0;
    }

    $self->log(NOTICE => "Folder $name does not exist!");
    undef;
}


sub folders(;$)
{   my $self = shift;
    my $top  = shift;

    my $imap = $self->imapClient or return ();
    $top = undef if defined $top && $top eq '/';

    # We need to force the remote IMAP client to only return folders
    # *underneath* the folder we specify.  By default they want to return
    # all folders.
    # Alas IMAPClient always appends the separator so, despite what it says
    # in its own docs, there's purpose to doing this.  We just need
    # to get whatever we get and postprocess it.  ???Still true???
    my @folders = $imap->folders($top);

    # We need to post-process the list returned by IMAPClient.
    # This selects out the level of directories we're interested in.
    my $sep   = $imap->separator;
    my $level = 1 + (defined $top ? () = $top =~ m/\Q$sep\E/g : -1);

    # There may be duplications, thanks to subdirs so we uniq it
    my %uniq;
    $uniq{(split /\Q$sep\E/, $_)[$level] || ''}++ for @folders;
    delete $uniq{''};

    keys %uniq;
}


sub ids($)
{   my $self = shift;
    my $imap = $self->imapClient or return ();
    $imap->messages;
}


# Explanation in Mail::Box::IMAP4::Message chapter DETAILS

my %flags2labels =
 ( # Standard IMAP4 labels
   '\Seen'     => [seen     => 1]
 , '\Answered' => [replied  => 1]
 , '\Flagged'  => [flagged  => 1]
 , '\Deleted'  => [deleted  => 1]
 , '\Draft'    => [draft    => 1]
 , '\Recent'   => [old      => 0]

   # For the Netzwert extension (Mail::Box::Netzwert), some labels were
   # added.  You'r free to support them as well.
 , '\Spam'     => [spam     => 1]
 );

my %labels2flags;
while(my ($k, $v) = each %flags2labels)
{  $labels2flags{$v->[0]} = [ $k => $v->[1] ];
}

# where IMAP4 supports requests for multiple flags at once, we here only
# request one set of flags a time (which will be slower)

sub getFlags($$)
{   my ($self, $id) = @_;
    my $imap   = $self->imapClient or return ();
    my $labels = $self->flagsToLabels(SET => $imap->flags($id));

    # Add default values for missing flags
    foreach my $s (values %flags2labels)
    {   $labels->{$s->[0]} = not $s->[1]
             unless exists $labels->{$s->[0]};
    }

    $labels;
}


sub listFlags() { keys %flags2labels }


# Mail::IMAPClient can only set one value a time, however we do more...
sub setFlags($@)
{   my ($self, $id) = (shift, shift);

    my $imap = $self->imapClient or return ();
    my (@set, @unset, @nonstandard);

    while(@_)
    {   my ($label, $value) = (shift, shift);
        if(my $r = $labels2flags{$label})
        {   my $flag = $r->[0];
            $value = $value ? $r->[1] : !$r->[1];
            # exor can not be used, because value may be string
            $value ? (push @set, $flag) : (push @unset, $flag);
        }
        else
        {   push @nonstandard, ($label => $value);
        }
    }

    $imap->set_flag($_, $id)   foreach @set;
    $imap->unset_flag($_, $id) foreach @unset;

    @nonstandard;
}


sub labelsToFlags(@)
{   my $thing = shift;
    my @set;
    if(@_==1)
    {   my $labels = shift;
        while(my ($label, $value) = each %$labels)
        {   if(my $r = $labels2flags{$label})
            {   push @set, $r->[0] if ($value ? $r->[1] : !$r->[1]);
            }
        }
    }
    else
    {   while(@_)
        {   my ($label, $value) = (shift, shift);
            if(my $r = $labels2flags{$label})
            {   push @set, $r->[0] if ($value ? $r->[1] : !$r->[1]);
            }
        }
    }

    join " ", sort @set;
}


sub flagsToLabels($@)
{   my ($thing, $what) = (shift, shift);
    my %labels;

    my $clear = $what eq 'CLEAR';

    foreach my $f (@_)
    {   if(my $lab = $flags2labels{$f})
        {   $labels{$lab->[0]} = $clear ? not($lab->[1]) : $lab->[1];
        }
        else
        {   (my $lab = $f) =~ s,^\\,,;
            $labels{$lab}++;
        }
    }

    if($what eq 'REPLACE')
    {   my %found = map { ($_ => 1) } @_;
        foreach my $f (keys %flags2labels)
        {   next if $found{$f};
            my $lab = $flags2labels{$f};
            $labels{$lab->[0]} = not $lab->[1];
        }
    }

    wantarray ? %labels : \%labels;
}


sub getFields($@)
{   my ($self, $id) = (shift, shift);
    my $imap   = $self->imapClient or return ();
    my $parsed = $imap->parse_headers($id, @_) or return ();

    my @fields;
    while(my($n,$c) = each %$parsed)
    {   push @fields, map { Mail::Message::Field::Fast->new($n, $_) } @$c;
    }

    @fields;
}


sub getMessageAsString($)
{   my $imap = shift->imapClient or return;
    my $uid = ref $_[0] ? shift->unique : shift;
    $imap->message_string($uid);
}


sub fetch($@)
{   my ($self, $msgs, @info) = @_;
    return () unless @$msgs;
    my $imap   = $self->imapClient or return ();

    my %msgs   = map { ($_->unique => {message => $_} ) } @$msgs;
    my $lines  = $imap->fetch( [keys %msgs], @info );

    # It's a pity that Mail::IMAPClient::fetch_hash cannot be used for
    # single messages... now I had to reimplement the decoding...
    while(@$lines)
    {   my $line = shift @$lines;
        next unless $line =~ /\(.*?UID\s+(\d+)/i;
        my $id   = $+;
        my $info = $msgs{$id} or next;  # wrong uid

        if($line =~ s/^[^(]* \( \s* //x )
        {   while($line =~ s/(\S+)   # field
                              \s+
                             (?:     # value
                                 \" ( (?:\\.|[^"])+ ) \"
                               | \( ( (?:\\.|[^)])+ ) \)
                               |  (\w+)
                             )//xi)
            {   $info->{uc $1} = $+;
            }

            if( $line =~ m/^\s* (\S+) [ ]*$/x )
            {   # Text block expected
                my ($key, $value) = (uc $1, '');
                while(@$lines)
                {   my $extra = shift @$lines;
                    $extra =~ s/\r\n$/\n/;
                    last if $extra eq ")\n";
                    $value .= $extra;
                }
                $info->{$key} = $value;
            }
        }

    }

    values %msgs;
}


sub appendMessage($$)
{   my ($self, $message, $foldername, $date) = @_;
    my $imap = $self->imapClient or return ();

    $date    = $imap->Rfc_822($date)
        if $date && $date !~ m/\D/;

    $imap->append_string
     ( $foldername, $message->string
     , $self->labelsToFlags($message->labels)
     , $date
     );
}


sub destroyDeleted($)
{   my ($self, $folder) = @_;
    defined $folder or return;

    my $imap = shift->imapClient or return;
    $imap->expunge($folder);
}


sub createFolder($)
{   my $imap = shift->imapClient or return ();
    $imap->create(shift);
}


sub deleteFolder($)
{   my $imap = shift->imapClient or return ();
    $imap->delete(shift);
}

#------------------------------------------

sub DESTROY()
{   my $self = shift;
    my $imap = $self->imapClient;

    $self->SUPER::DESTROY;
    $imap->logout if defined $imap;
}

#------------------------------------------

# Tied filehandle translates IMAP's debug system into Mail::Reporter
# calls.
sub  Mail::IMAPClient::Debug::TIEHANDLE($)
{   my ($class, $logger) = @_;
    bless \$logger, $class;
}

sub  Mail::IMAPClient::Debug::PRINT(@)
{   my $logger = ${ (shift) };
    $logger->log(DEBUG => @_);
}

1;
