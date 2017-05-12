package GMail::IMAPD;

use IO::Socket;
use IO::File;
use GMail::IMAPD::Gmail;
use strict;

our $VERSION = "0.93";

our @ISA = qw(Exporter);
our @EXPORT_OK = ();
our @EXPORT = ();


our @COMMANDS=qw(APPEND AUTHENTICATE CAPABILITY CHECK CLOSE COPY CREATE
                 DELETE EXPUNGE FETCH IDLE LIST LOGIN LOGOUT LSUB NAMESPACE 
                 NOOP RENAME SELECT STATUS STORE SUBSCRIBE UNSUBSCRIBE);

our @FOLDERS=('INBOX', 'All', 'Starred', 'Sent', 'Spam','Trash');

sub new {
  my($class, %args) = @_;
  my $self = {
    LocalAddr   => $args{LocalAddr} || '0.0.0.0',
    LocalPort	=> $args{LocalPort} || 143,
    Debug       => $args{Debug}  || 0,
    Detach      => defined $args{Detach} ? $args{Detach} : 1,
    LogFile     => $args{LogFile},
    CacheDBH    => $args{CacheDBH},
    Socket      => $args{Socket},
    Peer	=> undef,
    Gmail       => {},
    User	=> '',
    Folders	=> [], 
    SelFolder	=> '',
    Msgs	=> undef,
    UIDList	=> undef,
    CopyFolder  => '',
    CmdID	=> '',
    CmdArgs     => '',
    Cache       => undef,
  };
  bless($self, $class);   
  return $self;
}

sub run { my($self)=@_;
  if($self->{Detach}){
    close(STDIN); close(STDERR); close(STDOUT);
    fork && exit;
  } 
  
  $self->logit("Starting daemon");

  $SIG{CHLD}='IGNORE';
 
  my $l=IO::Socket::INET->new(Listen=>5,
                              LocalPort=>$self->{LocalPort},
                              LocalAddr=>$self->{LocalAddr},
                              Reuse=>1) || die("Socket: $!");

  my $s;
  for(;;close($s)){ $s=$l->accept();
    if(!fork){
      exit unless defined $s;
      $self->{Socket} = $s;
      $self->{Peer} = $s->peerhost; 
      $self->logit("Connect");
      $self->procimap();
      close($s); exit;
    }
  }
}

sub procimap { my($self)=@_;
  no strict 'refs';
  $self->writesock('* OK localhost IMAP4rev1 v11.237 server ready');
  for(;;){
    my($cmdid,$cmd,$args)=split(' ',$self->readsock(),3);
    if(uc($cmd) eq 'UID'){
      ($cmd,$args)=split(' ',$args,2);
      $args.=' UID';    
    }
    $cmd=uc($cmd);
    $cmdid = $cmdid || '*'; 
    if($cmd eq 'LOGOUT'){
      $self->logit("LOGOUT '$self->{User}'");
      $self->writesock("* BYE Logging out");
      $self->writesock("$cmdid OK Logout completed.");
      untie %{$self->{Cache}} if $self->{CacheDBH};
      return;
    }

    if(grep(/^$cmd$/,@COMMANDS)){
      $self->{CmdID} = $cmdid;
      $self->{CmdArgs} = $args;
      &{"cmd_$cmd"}($self);
    }
    else{
      $self->writesock("$cmdid BAD $cmd unknown");
    }
  }
}

sub cmd_APPEND { my($self)=@_;
  my($mbox,@args)=$self->parseargs($self->{CmdArgs});
  $self->writesock("+ Ready for data");
  my $dlength=$args[-1]; $dlength=~s/\D+//g;
  my $buf;
  while(length($buf) <= $dlength){ $buf.=$self->readsock('raw') }
 
  $self->sendemail('imap2gmail',$self->{User}. '@gmail.com',$buf);
  
  if($mbox eq 'INBOX'){
    $self->writesock("$self->{CmdID} OK Append completed.");
  }
  else{
    $self->writesock("$self->{CmdID} BAD Warning: Messages Appended to Inbox");
  }
}

sub cmd_AUTHENTICATE { my($self)=@_;
  $self->writesock("+\r\n");
  my($junk,$user,$pass)=split(/\0/,$self->mdecode($self->readsock()));
  $self->{CmdArgs}="$user $pass";
  $self->cmd_LOGIN();
}

sub cmd_CAPABILITY { my($self)=@_;
  $self->writesock("* CAPABILITY IMAP4rev1 AUTH=PLAIN");
  $self->writesock("$self->{CmdID} OK Capability completed.");
}

sub cmd_CHECK { my($self)=@_;
  $self->writesock("$self->{CmdID} OK Check completed.");
}

sub cmd_CLOSE { my($self)=@_;
  $self->writesock("$self->{CmdID} OK Close completed.");
}

sub cmd_COPY { my($self)=@_;
  my($msglist,$args)=split(/\s+/,$self->{CmdArgs},2);
  my $useuid = 1 if $args=~s/\s*UID$//;
  my $folder=$args;
  $folder=~s/"//g;
 
  my @msgs=@{$self->msgrange($useuid,$msglist)}; 
  my @msgids=map($_->{id},@msgs);
  $self->{CopyFolder}=$folder; 

  if($folder eq 'INBOX'){
    $self->logit("COPY: edit_archive(action =>'unarchive')",1);
    $self->{Gmail}->edit_archive(action =>'unarchive','msgid'=>\@msgids);
  }
  elsif($folder eq 'Trash'){
    $self->logit("COPY: delete_message (move to trash)",1);
    if($self->{SelFolder} eq 'Spam'){
      $self->{Gmail}->delete_message(msgid=>\@msgids, del_message=>0,
                                     search =>'spam');
    }
    else{
      $self->{Gmail}->delete_message(msgid=>\@msgids, del_message=>0);
    }
  }
  elsif($folder eq 'All'){
    $self->logit("COPY: edit_archive(action =>'archive')",1);
    $self->{Gmail}->edit_archive(action =>'archive','msgid'=>\@msgids);  
  }  
  elsif($folder eq 'Starred'){
    $self->logit("COPY: edit_star(action => 'add')",1);
    map($self->{Gmail}->edit_star( action => 'add','msgid' => $_),@msgids);
  }

  else{
    $self->logit("COPY: edit_labels(label=> $folder)",1);
    $self->{Gmail}->edit_labels(label=> $folder,action=>'add',msgid =>\@msgids);
    if($self->{SelFolder} eq 'INBOX'){
      $self->logit("COPY: edit_archive(action =>'archive')",1);
      $self->{Gmail}->edit_archive(action =>'archive','msgid'=>\@msgids)
    } 
  }
  map(delete $self->{UIDList}->{$_},@msgids);
  $self->writesock("$self->{CmdID} OK Copy completed.");
}

sub cmd_CREATE { my($self)=@_;
   my($folder)=$self->parseargs($self->{CmdArgs});
   $self->{Gmail}->edit_labels( label => $folder, action => 'create' );
   push(@{$self->{Folders}},$folder);
   $self->writesock("$self->{CmdID} OK Create completed.");
}

sub cmd_DELETE { my($self)=@_;
   my($folder)=$self->parseargs($self->{CmdArgs});
   $self->{Gmail}->edit_labels( label => $folder, action => 'delete' );
   $self->{Folders}=[grep !/$folder/,@{$self->{Folders}}];
   $self->writesock("$self->{CmdID} OK Delete completed.");
}

sub cmd_EXPUNGE { my($self)=@_;
  for my $msg (@{$self->{Msgs}}){
    if($msg->{Flags} && $msg->{Flags}=~/Deleted/){
      $self->writesock("* $msg->{n} EXPUNGE");
    }
  }
  $self->writesock("$self->{CmdID} OK Expunge completed.");
}

sub cmd_FETCH { my($self)=@_;
  my($msglist,$args)=split(/\s+/,$self->{CmdArgs},2);
  my $useuid=0; my @msgparts=();
  if($args=~s/UID$//){
    $useuid = 1;
    push(@msgparts,'UID');
    $args=~s/UID//g;
  }

  for my $ent ('UID','FLAGS','ENVELOPE','INTERNALDATE',
               'RFC822\S*','BODY[^\[]*\[[^\]]*\]'){
    while($args=~s/($ent)//i){ push(@msgparts,uc($1)) }
  }
  for my $msg (@{$self->msgrange($useuid,$msglist)}){
    my @resp=();
    for my $part (@msgparts){
      if($part eq 'UID'){
        push(@resp,'UID ' . $msg->{uid});
      }
      elsif($part eq 'FLAGS'){
        push(@resp,'FLAGS (' . ($msg->{new} ? '\Recent' : '\Seen') . ')');
      }
      else{
        my $mime=$self->cache_get_mime_email($msg);
	my $head=$self->get_header($mime);
	if($part eq 'ENVELOPE'){
          push(@resp,'ENVELOPE (' . $self->get_envelope($head) . ')' );
	}
        if($part eq 'INTERNALDATE'){
          push(@resp,'INTERNALDATE "' . $self->get_internaldate($head) . '"');
        }
        elsif($part=~/^(RFC822|BODY)/){
          $part=~s/\.PEEK//;
          if($part=~/SIZE/){
            push(@resp,"$part " . length($mime));
          }
          elsif($part=~/HEADER/){
            push(@resp,"$part {" . length($head) . "}\r\n$head");
          }
          else{
            push(@resp,"$part {" . length($mime) . "}\r\n$mime");
          }
        }
      }

    }
    $self->writesock("* $msg->{n} FETCH (@resp)"); 
  } 
  $self->writesock("$self->{CmdID} OK Fetch completed.");
}

sub cmd_IDLE { my($self)=@_;
  $self->writesock("+ idling");
  $self->readsock();
  $self->writesock("$self->{CmdID} OK Idle completed.");
}

sub cmd_LIST { my($self)=@_;
  map($self->writesock("* LIST () \"/\" $_"),
      map($_ eq 'INBOX' ? $_ : "\"$_\"",@{$self->{Folders}}));
  $self->writesock("$self->{CmdID} OK List completed.") 
}

sub cmd_LOGIN { my($self)=@_;
  $self->{CmdArgs}=~s/\"//g;
  my($user,$pass)=split(/\s+/,$self->{CmdArgs}); 
  $self->logit("LOGIN '$user'");
  $self->{Gmail}=GMail::IMAPD::Gmail->new(username => $user,
                                          password => $pass,
                                          timeout  => 10,
                                          cookies  => {});
  my $res=$self->{Gmail}->login;
  if($res == -1){
    $self->writesock("$self->{CmdID} NO Authentication failed.");
  } 
  elsif($res == 0){
    $self->logit("cmd_LOGIN: gmail error: " . $self->{Gmail}->error_msg);
    $self->writesock("$self->{CmdID} NO Gmail error.");
  }
  else{
    $self->{User}=$user;
    $self->{Folders}=[@FOLDERS,$self->{Gmail}->get_labels()];
    if($self->{CacheDBH}){
      require Tie::RDBM;
      $self->logit("tieing cache to table $user",1);
      tie %{$self->{Cache}},'Tie::RDBM',
           {db=>$self->{CacheDBH},table=>$user,create=>1};
      $self->{Cache}->{'seed'}=1; #create table
    }
    $self->writesock("$self->{CmdID} OK Logged in.");
  }
}

sub cmd_LSUB { my($self)=@_;
  map($self->writesock("* LSUB () \"/\" $_"),
      map($_ eq 'INBOX' ? $_ : "\"$_\"",@{$self->{Folders}}));
  $self->writesock("$self->{CmdID} OK Lsub completed.");
}

sub cmd_NAMESPACE { my($self)=@_;
  $self->writesock('* NAMESPACE (("" "/")) NIL NIL');
  $self->writesock("$self->{CmdID} OK Namespace completed.");
}

sub cmd_NOOP { my($self)=@_;
  $self->fetchmsgs();
  $self->writesock("* $self->{ExistMsgs} EXISTS");
  $self->writesock("* $self->{RecentMsgs} RECENT");
  $self->writesock("$self->{CmdID} OK NOOP completed.");
}

sub cmd_RENAME { my($self)=@_;
  my($old,$new)=$self->parseargs($self->{CmdArgs});
  $self->{Gmail}->edit_labels( label => $old, action => 'rename', 
                               new_name => $new );
  $self->writesock("$self->{CmdID} OK Rename completed.");
}

sub cmd_SELECT { my($self)=@_;
  ($self->{SelFolder})=$self->parseargs($self->{CmdArgs});
  $self->fetchmsgs();
  $self->writesock('* FLAGS (\Answered \Flagged \Deleted \Seen \Draft)');
  $self->writesock('* OK [PERMANENTFLAGS (\Answered \Flagged \Deleted \Seen \Draft \*)] Limited');
  $self->writesock("* $self->{ExistMsgs} EXISTS");
  $self->writesock("* $self->{RecentMsgs} RECENT");
  my $nextuid=@{$self->{Msgs}} ? $self->{Msgs}->[-1]->{uid} + 1 : 1;
  my $uidvalidity=$self->strcrc32($self->{SelFolder});
  $self->writesock("* OK [UIDVALIDITY $uidvalidity] UID validity status");
  $self->writesock("* OK [UIDNEXT $nextuid] Predicted next UID");

  $self->writesock("$self->{CmdID} OK [READ-WRITE] Select completed."); 
}

sub cmd_STATUS { my($self)=@_;
  my($folder,$flags)=$self->parseargs($self->{CmdArgs});
  $flags=~s/(\w+)/$1 0/g; #actual status is too expensive
  $self->writesock("* STATUS $folder ($flags)");
  $self->writesock("$self->{CmdID} OK STATUS completed.");
}

sub cmd_STORE { my($self)=@_;
  my($msglist,$args)=split(/\s+/,$self->{CmdArgs},2);
  my $useuid = 1 if $args=~s/\s*UID$//;

  my $msgs=$self->msgrange($useuid,$msglist);
  my @msgids=map($_->{id},@$msgs);
  
  if($args=~/\+FLAGS/i){  
    map($_->{Flags}=$args,@$msgs);
    if($args=~/Deleted/){  
      if($self->{SelFolder} eq 'INBOX'){
        unless($self->{CopyFolder} eq 'Trash'){
          $self->logit("STORE: edit_archive(action=>'archive')",1);
          $self->{Gmail}->edit_archive(action=>'archive','msgid'=>\@msgids);
        }
      }
      elsif($self->{SelFolder} eq 'Trash'){
        unless($self->{CopyFolder}){ #delete forever
          $self->logit("STORE: delete_message (permanent)",1);
          $self->{Gmail}->delete_message(msgid=>\@msgids);
        }
      }

      elsif($self->{SelFolder} eq 'All'){
        #Nothing needed here, unarchive done by copy
        $self->logit("STORE: do nothing",1);
      }
      elsif($self->{SelFolder} eq 'Starred'){
        $self->logit("STORE: edit_star(action => 'remove')",1);
        map($self->{Gmail}->edit_star(action => 'remove','msgid' =>$_),@msgids);
      }
      elsif($self->{SelFolder} eq 'Spam'){
        #Nothing needed here
        $self->logit("STORE: do nothing",1);
      }
      else{
        $self->logit("STORE: edit_labels(action=>'remove')",1);
        $self->{Gmail}->edit_labels(label=>$self->{SelFolder}, 
                                    action=>'remove',msgid=>\@msgids);
      }
    }
    if($args=~/Seen/){
      for my $msg (@{$msgs}){
        $self->logit("STORE: get_indv_email",1);
        $self->{Gmail}->get_indv_email(msg => $msg); #marks as read
      }
    }
    $self->{CopyFolder}='';
  }
  $self->writesock("$self->{CmdID} OK Store completed.");
}

sub cmd_SUBSCRIBE { my($self)=@_;
  $self->writesock("$self->{CmdID} OK Subscribe completed.");
}

sub cmd_UNSUBSCRIBE { my($self)=@_;
  $self->writesock("$self->{CmdID} OK UnSubscribe completed.");
}

sub mdecode { my($self,$str)=@_;
  $str=~y#A-Za-z0-9+/##cd; $str=~y#A-Za-z0-9+/# -_#;
  return unpack("u", pack("c", 32 + 0.75*length($str)) . $str);
}

sub parseargs { my($self,$s)=@_;
  my @args;
  while($s=~s/\s*(\S+)//){ my $arg=$1;
    if($arg=~s/^(['"(<])//){
      my $q=$1; $s="$arg$s";
      if($q eq '('){ $q='\)' }
      elsif($q eq '<'){ $q='>' }
      $arg=$1 if $s =~ s/([^$q]*)$q//;
    }
    push(@args,$arg);
  }
  return @args;
}


sub readsock { my($self,$fmt)=@_;
  my $s=$self->{Socket}; 
  my $line;
  while(!$line){$line=<$s>};
  $line=~s/\s+$// unless $fmt eq 'raw';
  $self->logit("readsock:'$line'",2);
  return $line;
}

sub writesock {  my($self,$msg,$fmt)=@_;
  $self->logit("writesock:'$msg'",2);
  my $s=$self->{Socket};
  unless($s){
    $self->logit("writesock: attempt to write on closed socket");
    return;
  }
  $msg=~s/\s*$/\r\n/ unless $fmt eq 'raw';
  print $s $msg;
}

sub fetchmsgs { my($self)=@_;
  ($self->{Msgs},$self->{ExistMsgs},$self->{RecentMsgs})=([],0,0);
  my $msgs=$self->{Gmail}->get_messages(label => $self->{SelFolder});
  return unless $msgs;
  my $n=1;
  for my $msg (sort { $a->{id} cmp $b->{id} } @$msgs){
    $msg->{uid}=hex(substr($msg->{id},0,8));
    $msg->{n}=$n++;
    $self->logit("fetchmsgs: $msg->{n} $msg->{uid}",2);
    $self->{ExistMsgs}++;
    $self->{RecentMsgs}++ if $msg->{new};
    push(@{$self->{Msgs}},$msg);
  }
}

sub msgrange{ my($self,$useuid,$msglist)=@_;
  my $msgs=[];
  for my $ent (split(',',$msglist)){
    my($start,$end)=split(':',$ent); 
    if(!$end){ $end = $start }
    elsif($end eq '*'){ $end=hex('ffffffff') }
    for my $msg (@{$self->{Msgs}}){
      if($useuid){
        if($msg->{uid} >= $start && $msg->{uid} <= $end){ push(@$msgs,$msg) }
      }
      elsif($msg->{n}>=$start && $msg->{n} <= $end){ push(@$msgs,$msg) }
    }
  }
  return $msgs;
}

sub cache_get_mime_email { my($self,$msg)=@_;
  unless($self->{Cache}->{$msg->{id}}){
    $self->{Cache}->{$msg->{id}}=$self->{Gmail}->get_mime_email( msg => $msg );
    select(undef, undef, undef, 0.25); #throttle
    $self->{Cache}->{$msg->{id}} =~ s/\n/\r\n/gm;
  }
  return $self->{Cache}->{$msg->{id}};
}

sub get_envelope { my($self,$head)=@_;
  my @buf;

  sub garbleaddr { my($addr)=@_;
    my $email=$1 if $addr=~s/\s*<*(\S+\@[^>\s]+)>*\s*//;
    my $name=$addr; $name=~s/"//g;
    my($em1,$em2)=split(/\@/,$email);
    return join(' ',map( $_ ? "\"$_\"" : 'NIL',($name,'',$em1,$em2)));
  };

  for my $ent ('Date','Subject'){
    push @buf, $head=~s/^$ent: ([^\r\n]+)//m ? "\"$1\"" : 'NIL';
  } 
  my @prevdata=();
  for my $ent ('From','Sender','Reply\-To'){ my @data=(); 
    push(@data,$1) while $head=~s/^$ent: ([^\r\n]+)//m;
    if(@data){
      push @buf, "(" . join(' ',map("(" . garbleaddr($_) . ")",@data)) 
	       . ")";
      @prevdata=@data;
    } 
    elsif(@prevdata){
      push @buf, "(" . join(' ',map("(" . garbleaddr($_) . ")",@prevdata)) .")";
    }
    else{ 
      push @buf,"NIL";
    } 
  }
  for my $ent ('To','Cc','Bcc'){ my @data=();
    push(@data,$1) while $head=~s/^$ent: ([^\r\n]+)//m;
    if(@data){ 
      push @buf, "(" . join(' ',map("(" . garbleaddr($_) . ")",@data)) . ")";
    }
    else{
      push @buf,"NIL";
    }
  }
  for my $ent ('In\-Reply\-To','Message\-ID'){
    push @buf, $head=~s/^$ent: ([^\r\n]+)//m ? "\"$1\"" : 'NIL';
  }
  return join(' ',@buf);
}

sub get_internaldate { my($self,$head)=@_;
  my($dates)=$head=~/^Date: (.*)/m;
  my($date,$time)=$dates=~/(\d+ \w+ \d+)\s+(.*)/;
  $date=~s/ /\-/g; $time=~s/\s+$//;
  return "$date $time";
}

sub get_header { my($self,$msg)=@_;
  return $1 if $msg=~/(.*?\r\n\r\n)/ms;
}

# From Digest::Crc32.  Thanks Faycal Chraibi
sub _crc32 {
  my ($comp) = @_;
  my $poly = 0xEDB88320;
  for (my $cnt = 0; $cnt < 8; $cnt++) {
    $comp = $comp & 1 ? $poly ^ ($comp >> 1) : $comp >> 1;
  }
  return $comp;
}

#from Digest::Crc32.  Thanks Faycal Chraibi
sub strcrc32 {
  my($self,$tcmp)=@_;
  my $crc = 0xFFFFFFFF;
  foreach (split(//,$tcmp)) {
    $crc = (($crc>>8) & 0x00FFFFFF) ^ _crc32(($crc ^ ord($_)) & 0xFF);
  }
  return $crc^0xFFFFFFFF;
}

sub sendemail { my($self,$from,$to,$msg)=@_;
  use Net::SMTP;
  my $smtp=Net::SMTP->new('127.0.0.1');
  die "Couldn't connect to server" unless $smtp;
  $smtp->mail($from);
  $smtp->to($to);
  $smtp->data($msg);
  $smtp->quit();
}

sub logit { my($self,$msg,$debug_level)=@_;
  $debug_level = 0 unless $debug_level;
  return unless $debug_level <= $self->{Debug};
  my $timestamp=scalar localtime(time);
  $msg="$self->{Peer}: $msg" if $self->{Peer};
  $msg="$timestamp: $msg\n"; 
  print $msg if !$self->{Detach};
  return unless $self->{LogFile};
  my $lf=new IO::File ">>$self->{LogFile}";
  print $lf $msg;
  close $lf;
}

__END__

=head1 NAME

GMail::IMAPD - An IMAP4 gateway to Google's webmail service

=head1 SYNOPSIS

    # Start an IMAP-to-Gmail daemon on port 1143 

    use GMail::IMAPD;

    my $daemon=GMail::IMAPD->new(LocalPort=>1143,
                                 LogFile=>'gmail_imapd.log',
                                 Debug=>1);
    $daemon->run();

    # Or if you prefer to use your own server socket, 
    # you can do something like:
    
    my $i2g=GMail::IMAPD->new(LogFile=>'imapd.log');

    for(;;){
      my $s=someserver();
      $i2g->procimap($s);
    }


=head1 DESCRIPTION

This module allows users to access their Gmail account with an IMAP client
by running a server which accepts IMAP connections.


=head1 METHODS

=over 4

=item new ( [ARGS] )

Creates a new object.  All arguments are optional and are in key => value form.
Valid arguments are: 

	LocalAddr	Local host bind address
        LocalPort	Local bind port
        Detach          Boolean to run in background.  Default = 1
        LogFile         Path to log file
        Debug		1 = extra information, 2 = raw socket data
        CacheDBH	Database handle, see below
        Socket		Socket handle for processing IMAP commands
                        

=item procimap ( $socket_handle )

Directly pass a handle to the module to process IMAP commands.


=head1 NOTES

The IMAP and Gmail models differ. How GMail::IMAPD translates these differences
is mostly intuitive.  For instance, folders translate to labels.  
You can even have subfolders which translate to label names such as 
'Work/NewProject'.  Some translations that aren't as intuitive are shown in the 
table below:

  - Copy message to folder -> Add label to message
  - Move message from Inbox to folder -> Add label to message and archive
  - Move message from folder to Inbox -> Remove label and unarchive
  - Delete message in Inbox -> Archive message
  - Delete message in folder -> Remove message label
  - Delete message in Trash -> Permanently delete message


Messages from other IMAP accounts can be appended to the Gmail Inbox, 
and Inbox only.  The module achieves this by emailing the message 
to the Gmail account.  Therefore, the append procedure may be slow
and the message will initially be marked unread.

To persistently cache Gmail messages, a database handle can be given as 
an argument.  Using the Tie::RDBM module, GMail::IMAPD will automatically 
create a table for each user and store messages in this table.   

GMail::IMAPD is not fully IMAP4 compliant and has just enough
functionality to get by. It has been tested with Firefox, Outlook,
Outlook Express, and mail2web.com.


=head1 CAVEATS

The IMAP client is automatically subscribed to all folders/labels.  Unsubscribe
has no effect.  This is to eliminate any need for persistent server side data
at the moment.

Once a message has been moved to Trash, it cannot be un-Trashed with the IMAP 
client.  This functionality might be missing in the L<Mail::Webmail::Gmail> 
module or I'm not sure how to do it with the module.

Access to large folders is slow.  To fetch simple header information 
requested by most IMAP clients (FLAGS, INTERNALDATE, etc) requires 
GMail::IMAPD to download the entire message.  Using persistent message caching 
with CacheDBH helps alleviate this problem.

To work, GMail::IMAPD currently bundles and uses patched versions of 
L<UserAgent> and L<Mail::Webmail::Gmail>.  One line of UserAgent was changed to
forward cookies to Gmail.  And, only a patched version of Mail::Webmail::Gmail 
works with the current version of Gmail.  Future versions of GMail::IMAPD will 
remove these patched modules when the actual modules are updated.  


=head1 BUGS

If a message is replied-to via the gmail web interface and the reply is 
discarded, the message becomes unavaible to interfaces such as
Mail::Webmail::Gmail.  I believe this is a Google bug.


=head1 PREREQUISITES


LWP

Crypt::SSLeay


=head1 TODO

- Better error handling

- Persistently cached messages, perhaps with DBI

- IMAPS support

- A contacts folder, perhaps containing messages with xml and vcf attachments

- Copy from other IMAP accounts to any Gmail folder

- Interface with Mail::Webmail::Yahoo ?

=head1 CREDITS

I'd like to thank Allen Holman (mincus) for the L<Mail::Webmail::Gmail> module.
His module greatly accelerated the development of GMail::IMAPD.


=head1 AUTHOR

Kurt Schellpeper  <krs - gmail - com> 


=head1 COPYRIGHT

Copyright 2005 Kurt Schellpeper. All rights reserved.

This library is a free software. You can redistribute it and/or modify it under
the same terms as Perl itself.




