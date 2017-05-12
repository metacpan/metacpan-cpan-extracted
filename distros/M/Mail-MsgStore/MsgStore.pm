=head1 NAME

Mail::MsgStore - Complete mail client back end.

=head1 SYNOPSIS

  use Mail::MsgStore;

  # set mailroot 
  Mail::MsgStore::mailroot($ENV{MAILROOT});
  # get new messages from server 
  $count= Mail::MsgStore::getmail(\&prompt);
  # send a Mail::Internet message 
  Mail::MsgStore::send($msg);

  # add an account
  Mail::MsgStore::acct_set('Joe User <user@server.com> (work)',$password);
  # delete an account 
  Mail::MsgStore::acct_del('Joe User <user@server.com> (work)');
  # change mailroot 
  Mail::MsgStore::mailroot('c:/mail');
  # change from address 
  Mail::MsgStore::from('Brian Lalonde <brianl@sd81.k12.wa.us>');
  # get SMTP server address 
  $smtp= Mail::MsgStore::smtp;
	
  # add message 
  $MsgStore{'/'}= $msg;                # auto-filter 
  $MsgStore{'path/to/folder/'}= $msg;  # add to specific folder 
  # delete message 
  delete $MsgStore{'path/to/folder/msgid'};
  # delete folder 
  delete $MsgStore{'path/to/folder/'};

  # get message 
  $msg= $MsgStore{'path/to/folder/msgid'};
  # mark message as read, unmark 'general' flag 
  $MsgStore{'path/to/folder/msgid'}= 'read, -general';
  # get folder's message id list 
  @msgids= $MsgStore{'path/to/folder/'};
  # get list of folders 
  @folders= keys %MsgStore;

  # move message 
  $MsgStore{'newfolder/'}= delete $MsgStore{'path/to/folder/msgid'};
  # copy message 
  $MsgStore{'path/to/newfolder/'}= $MsgStore{'path/to/folder/msgid'};


=head1 DESCRIPTION

The primary goal of this module is ease of use.
The Mail::Folder module, on top of not quite being complete yet, is a
pretty low-level API.  I was very impressed with how Win32::TieRegistry
simplified an otherwise complex task, and decided to adopt a similar 
interface for handling a mail store.

Another, equally important, reason for creating this module was 
user-configurability. 
I was unhappy with existing mail clients' filtering capabilities--
I wanted to pass every new message through some arbitrary Perl
code that was smart enough to forward, reply, send pages, activate
emergency-type alerts, etc. based on properties of the message.
What I didn't want was more bloatware--Exchange, Outlook and
Groupwise have already been written, and despite being huge,
still don't do enough.

=head2 Storage Format

MsgStore uses a modified form of qmail's maildir format.
Here's how it works: new messages are downloaded into a
file guaranteed to have a unique, but incomplete, name.
The filename is completed once the entire message has
been successfully downloaded (the finishing of the filename
replaces maildir's state subdirectories).

The unique filename is generated as a dot-separated list of (uppercase) 
hexadecimal numbers:  seconds past epoch (12 digits), IP address
(8 digits), process id (4 digits), and download number (2 digits).
The IP should guarantee uniqueness to a machine, the time and pid narrows 
it down to a specific process, and a simple incremental number ensures
that 256 messages can be downloaded per second and still retain
uniqueness.  The filename also begins and ends with 'mail',
also separated by dots.

Message flags are part of the message id (although requesting a
message by an id with the wrong flags still works).
The flags are five characters delimited by parens.
Each position is either a dash (off) or a letter (on).
Order is significant, but since the letters spell the word
FLAGS, that shouldn't be a problem.
Here are what the letters stand for:

  F  flame
  L  list/group
  A  answered/replied
  G  general/flag
  S  seen/opened/read

=head2 Warning

The storage format used for this module quickly becomes unusable for
large message stores; hundreds or thousands of tiny files are rarely
stored efficiently on the disk.

Although the module is completely usable, I hope it will inspire better 
storage formats to use the same simple tied-hash interface.

=head1 EVENTS

The message store allows definition of the following subroutines
in the F<events.pl> file located in the B<mailroot> directory:

=over 4

=item C<filter($msg)>

Accepts the Mail::Internet message object.
The message's recipient account is available as 
C<X-Recipient-Account> in the message header.

Returns the name of the folder that the Mail::Internet $msg belongs in.
Returning undef implies the C<Inbox>.
Also, all message flags should be stored in the C<X-Msg-Info> header,
either as the native C<(FLOR!)> format of the message ID, or the english
equivalents: C<flame, mailing-list, opened, replied, flagged>.

=item C<keep($msg)>

Accepts the Mail::Internet message object.
The message's recipient account is available as 
C<X-Recipient-Account> in the message header.

Returns a boolean value that determines whether the message should
be kept on the server.

=item C<sign($msg)>

Signs a message before it is sent.

=back


=head1 FUNCTIONS

=head2 Sending and Receiving

=over 4

=item C<getmail(\&prompt[,\&status])>

Logs on to each mail account, checking for new messages, which are 
downloaded, passed to C<filter()> and added.

Returns number of messages downloaded.
Requires a callback that will be used if there is a problem logging in:

=over 4

=item C<prompt($acct)>

Parameters: C<$acct> ISA Mail::Address: user is the POP3 username, 
host is the POP3 server. 

The function must return a password, or undef to cancel.
The password will be updated if it was initially set, or
left blank otherwise.

=item C<status($status_message[,$percent_done])>

Parameters: C<$status_message> is a string describing what is going on
suitable for GUI statusbars, etc.
C<$percent_done> is an integer between 0 and 100 (when included, else C<undef>)
suitable for feeding to progress bars, etc.

=back

=item C<signmsg($msg)>

Signs a Mail::Internet message, using the C<sign()> function from the 
user-defined F<events.pl>.

=item C<sendmsg($msg)>

Sends a Mail::Internet message, and stores a copy in C<Sent/>.

=back


=head2 Settings

=over 4

=item C<mailroot([$mailroot])>

Gets/sets the root directory of the mailstore.
The user's login is appended to this directory.
If the directory doesn't exist, it is created.
If the directory doesn't contain an F<events.pl>
file, one (fully commented) is created.

Defaults to C<$ENV{MAILROOT}> or current dir unless set.

=item C<load_events()>

Reloads the F<events.pl> file.
Useful if you provide an editing facility for that file,
or otherwise know that it has changed.

=item C<smtp([$smtp])>

Gets/sets the address of the outgoing mail server.

=item C<from([$from])>

Gets/sets the email C<From:> address.

=item C<accounts()>

Returns a list of account strings.

=item C<acct_set($acct,$pwd)>

Adds/sets an POP3 account to the list handled by C<getmail()>.
Parameters: account and optional password.

Accounts strings are parsed by Mail::Address; the server portion is
used to connect, and the user portion is used to log in.
Everything else is mnemonic.

=item C<acct_del($acct)>

Deletes an account. 

=back


=head2 The Address Book

=over 4

=item C<addresses()>

Returns a list of (references to) hashes for the entire address book.

=item C<address( field =E<gt> $value, ... )>

Add an entry to the address book.  
The key for the new entry is returned.
The full list of fields is available in C<@addr_field>, pretty names
for the fields are in C<%addr_field> (neither exported by default).

Some fields of note:

=over 4

=item key

A guaranteed unique identifier for the address entry.
Auto-generated on insert.

=item notes

The I<only> field allowed to contain tabs and newlines.

=item firstname, lastname, nickname, email

Standard mail-client stuff.

=item tons more...

(and in no guaranteed order)

=back

=item C<address($key)>

Retrive the hash for an address.

=item C<address($key, field =E<gt> $value, ...)>

Update fields on an existing address.
Boolean success is returned.

=item C<address($key, DELETE =E<gt> 1 )>

Delete an entry from the address book.

=item C<ldaps([$ldaps])>

Gets/sets a comma or space-delimited list of LDAP servers.

=item C<whosearch(qr/regex/, [ @fields ] )>

Searches the address book fields specified by fields, looking for
records that match the regex, the C<firstname> and C<lastname> fields
by default.
(Actually, matches with C<"@addr{@fields}"=~ /regex/>.)
The special field C<nickname> is also checked to match.
A list of (references to) hashes of matching records are returned,
plus a C<MATCHED> field in each hash that contains the value of
either C<$field[0]> or C<nickname>, depending on which field matched.

The result set is sorted by matching field.

This function is probably unneccessarily complex for most mail clients.

=item C<addrsearch( -starts =E<gt> $namestart, 
[ -number =E<gt> $hitnum, ] [ -fields =E<gt> \@fields, ] )>

This is a simpler version of L<"whosearch"> that just returns address strings
(rather than entire hashrefs for each record).
(Actually, matches with C<"@addr{@fields}"=~ /regex/>.)
By default, the C<firstname> and C<lastname> fields are used, just 
as in L<"whosearch">.
The special field C<nickname> is also checked to match.
In list context, the list of matching address strings is returned,
but in a scalar context, the C<$hitnum>-th element is returned
(this allows passing of a kind of "Nope, next one." request).

Each address is formatted this way:
  C<firstname> C<lastname> E<lt>C<email>E<gt>
unless the match was via C<nickname>, in which case the nickname and 
a tab character are prepended to the address string.

=item C<ldapsearch($startswith)>

Searches the server(s) specified by C<ldaps()> for an entry
that starts with C<$startswith>, and returns a list similar to
L<"addrsearch">.  Ignores queries shorter than 3 letters.

This function is called by L<"addrsearch">, and probably needn't be 
called directly.

=back


=head2 Utility

=over 4

=item C<msgsearch($folder,\&match)>

Searches messages in C<$folder> (and all subfolders) for messages
that produce a true value when passed to C<&match>.
Returns a list of fully-qualified message IDs.

=item C<simplifymsg($msg)>

Returns a text-only body of C<$msg>.
If the actual C<$msg> is a C<multipart/mixed> or C<multipart/alternative>, 
for example, this just gives you the text portion of the message for
display purposes.

=item C<msgpath($fullqid)>

Given a fully-qualified messsage ID (one that begins with the folder path),
breaks the string into folder path and message ID.
(Similar in spirit to the L<File::Basename> module.)

=item C<msgid($msgid)>

Given a message ID whose flags may have changed (the message ID contains
the message flags), returns the new message ID.

=item C<flags($string)>

Returns a valid flagstring for the Mail::MsgStore message ID,
given either a msgid or english string (C<'+read -list !flame'>) 
to parse.
Mostly for internal use.

=back

=head1 AUTHOR

v, E<lt>v@rant.scriptmania.comE<gt>

=head1 SEE ALSO

perl(1), 
Sys::UniqueId, 
Mail::Internet, 
Mail::Folder, 
Win32::TieRegistry,
Net::LDAP, 
Net::POP3, 
Time::ParseDate

=cut

package Mail::MsgStore;
require Exporter;
use strict;
use Carp;
use File::Find;
use File::Path;
use Mail::Address;
use Mail::Internet;
use MIME::Entity;
use Net::LDAP;
use Net::POP3 2.20;
use Time::ParseDate;
use Sys::UniqueID;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS &isa);
use vars qw($MsgStore %MsgStore $mailroot @folder);
use vars qw(@addr_field %addr_field %mime_ext);
use vars qw($_default_script %_folder_sort $_noflock);

$VERSION=     '1.51';
@ISA=         qw(Exporter);
@EXPORT=      qw(%MsgStore);
@EXPORT_OK=   qw(accounts acct_set acct_del 
                 getmail mailroot msgsearch simplifymsg
                 smtp from ldaps signmsg sendmsg %mime_ext
                 address addresses whosearch addrsearch ldapsearch
                 flags msgid msgpath load_events);
%EXPORT_TAGS= 
( 
  ALL  => [ @EXPORT, @EXPORT_OK ],
  ACCT => [ @EXPORT, qw(accounts acct_set acct_del) ],
  READ => [ @EXPORT, qw(getmail mailroot msgsearch simplifymsg) ],
  SEND => [ @EXPORT, qw(smtp from ldaps signmsg sendmsg %mime_ext) ],
  ADDR => [ @EXPORT, qw(address addresses whosearch addrsearch ldapsearch) ],
  UTIL => [ @EXPORT, qw(flags msgid msgpath load_events) ],
);
*isa = \&UNIVERSAL::isa;
$_noflock= 1 if $^O eq 'MSWin32' and Win32::IsWin95;
END { unlink $_noflock if -f $_noflock }

###################################
# 
# Methods 
# 

sub mailroot
{
  if(@_)
  { # change mailroot 
    unlink $_noflock if $_noflock and -f $_noflock;
    local $_= shift;
    y,\\,/,; s,/$,,;
    $_.= '/'.getlogin;
    unless(-d $_)
    {
      mkpath $_;
      # TODO: if(uname) chmod/Win32::FilePerms
      #       to secure mail dir
    }
    $mailroot= $_;
    load_events();
  }
  if($_noflock)
  {
    croak "Only one MsgStore application at a time, please!\n".
      "(Your system can't lock files.)\n"
      if -f "$mailroot/MsgStore.lck";
    $_noflock= "$mailroot/MsgStore.lck";
    open LOCK, ">$_noflock" 
      or croak "Unable to create lock file: $!\n";
    close LOCK;
  }
  return $mailroot;
}

sub _getkept(\%)
{
  my $kept= shift;
  if(open KEPT, "<$mailroot/kept")
  {
    local $_;
    while(<KEPT>)
    {
      chomp;
      my($key,$val)= split /\t/;
      $$kept{$key}= $val;
    }
    close KEPT;
  }
}

sub _savekept(\%)
{
  my $kept= shift;
  if(open KEPT, ">$mailroot/kept")
  {
    for(keys %$kept)
    { print KEPT $_, "\t", $$kept{$_}, "\n"; }
    close KEPT;
  }
}

sub getmail(&;&)
{
  my($prompt,$status)= @_;
  $status= sub{} unless $status;
  my $started= time;
  my %kept; _getkept(%kept);
  dbmopen my %acct, $mailroot.'/accounts', 0600
    or croak "Unable to open accounts database: $!\n";
  my($NewMsg,$index,@acct)= (0,0,keys %acct);
  my $grain= 10_000/@acct;
  ACCT: for(@acct)
  {
    my $progress= $index*$grain/100;
    &$status("Checking $_...",$progress); 
    my($acct)= Mail::Address->parse($_);

    # Connect and log in to POP3 server
    carp("Unable to connect to server ".$acct->host().": $!\n"), next ACCT
      unless my $conn= new Net::POP3($acct->host());
    my $count= $conn->apop($acct->user(),($acct{$_} ^ getlogin)) if $conn;
    unless(defined $count)
    { # APOP didn't work, try basic auth 
      &$status("Connecting to $_...",$progress); 
      $conn->quit() if $conn; # reset connection (some servers get stuck) 
      $conn= new Net::POP3($acct->host());
      $count= $conn->login($acct->user(),($acct{$_} ^ getlogin)) if $conn;
    }
    until(defined $count)
    {
      &$status("Login failed for $_...",$progress); 
      my $pass= &$prompt($acct);
      next ACCT unless defined $pass;
      unless(defined($count= $conn->apop($acct->user(),$pass)))
      { # APOP didn't work, try basic auth 
        $conn->quit() if $conn; # reset connection (some servers get stuck) 
        $conn= new Net::POP3($acct->host());
        $count= $conn->login($acct->user(),$pass) if $conn;
      }
      $acct{$_}= $pass ^ getlogin if $acct{$_};
    }

    # Get messages 
    &$status("Connected to $_...",$progress); 
    &$status("No new messages for $_...",$progress), next unless int $count; 
    load_events();
    my($newmsg,$msggrain)= (0, $grain/$count );
    for my $msgnum (1..$count)
    {
      &$status("$_: $msgnum of $count",
        ($msgnum-1)*$msggrain/100 + $progress);
      my $uidl= $conn->uidl($msgnum);
      unless($uidl)
      { # not all servers support UIDL, here's a substitute 
        my $head= new Mail::Header($conn->top($msgnum));
        $uidl= join($;,$head->get('Message-Id'),$conn->list($msgnum));
        $uidl=~ y/\n//d;
      }
      if($kept{$_,$uidl})
      { $kept{$_,$uidl}= time; next }
      # NULL-value headers really confuse Mail::Internet
      my @msgdata= grep { !/./..1 or /^(\s|\S+:\s*\S)/ } @{$conn->get($msgnum)};
      my $msg= new Mail::Internet(\@msgdata);
      $msg->head->add('X-Recipient-Account',$_);
      $MsgStore{'/'}= $msg;  # filter into message store 
      next unless $msg->get('Received'); # messages disappearing >:( 
      if(Mail::MsgStore::Event::keep($msg))
      { # keep message (remember uidl) 
        $kept{$_,$uidl}= time;
      }
      else
      { # delete from server 
        $conn->delete($msgnum);
      }
      $newmsg++;$NewMsg++;
    }
    $conn->quit();
    $newmsg= 'no' unless $newmsg;
    &$status("$_: $newmsg new messages.",++$index*$grain/100); 
  }
  dbmclose %acct;
  for(keys %kept) { delete $kept{$_} unless $kept{$_} > $started; }
  _savekept(%kept);
  $NewMsg= 'No' unless $NewMsg;
  &$status("$NewMsg New Messages.",100); 
  return $NewMsg;
}

sub from
{
  my($value)= @_;
  dbmopen my %settings, $mailroot.'/settings', 0600 
    or croak "Unable to open settings database: $!\n";
  $settings{from}= $value if $value;
  $value= $settings{from};
  dbmclose %settings;
  return $value;
}

sub smtp
{
  my($value)= @_;
  dbmopen my %settings, $mailroot.'/settings', 0600 
    or croak "Unable to open settings database: $!\n";
  $settings{smtp}= $value if $value;
  $value= $settings{smtp};
  dbmclose %settings;
  return $value;
}

sub ldaps
{
  my($value)= @_;
  dbmopen my %settings, $mailroot.'/settings', 0600 
    or croak "Unable to open settings database: $!\n";
  $settings{ldap}= $value if $value;
  $value= $settings{ldap};
  dbmclose %settings;
  return $value;
}

sub load_events
{ # event script default/init 
  my $script= $mailroot.'/events.pl';
  unless(-f $script)
  {
    open SCRIPT, ">$script" 
      or croak "Unable to create default event script file: $!\n";
    print SCRIPT $_default_script;
    close SCRIPT;
  }
  { package Mail::MsgStore::Event;
    do $script;
  }
  croak "Error(s) in user script: $script.\n$@\n" if $@;
}

sub flags
{
  return '(-----)' unless local $_= shift;
  return $_ if s/^([F\-][L\-][A\-][G\-][S\-])$/\(\U($1)\)/i;
  return uc$1 if m/(\([F\-][L\-][A\-][G\-][S\-]\))/i;
  shift=~ /\(?([F\-][L\-][A\-][G\-][S\-])\)?/i;
  my @flag= split //, ($1 or '-----');
  for(split /[^!\+\-\w]+/)
  {
    $flag[0]= ( /\-/ ? '-' : ( /!/ ? ( $flag[0] eq '-' ? 'F' : '-' ) : 'F' ) ) 
      and next if /\b(flame|troll)\b/i;
    $flag[1]= ( /\-/ ? '-' : ( /!/ ? ( $flag[1] eq '-' ? 'L' : '-' ) : 'L' ) ) 
      and next if /\b(list|group|sig)\b/i;
    $flag[2]= ( /\-/ ? '-' : ( /!/ ? ( $flag[2] eq '-' ? 'A' : '-' ) : 'A' ) ) 
      and next if /\b(answer(ed)?|repl(y|ied))\b/i;
    $flag[4]= ( /\-/ ? '-' : ( /!/ ? ( $flag[4] eq '-' ? 'S' : '-' ) : 'S' ) ) 
      and next if /\b(seen|open(ed)?|read)\b/i;
    $flag[3]= ( /\-/ ? '-' : ( /!/ ? ( $flag[3] eq '-' ? 'G' : '-' ) : 'G' ) );
  }
  local $";
  return "(@flag[0..4])";
}

sub sendmsg($)
{
  my $msg= shift;
  return unless isa($msg,'Mail::Internet');
  $msg->head->add('X-Mailer','Mail::MsgStore');
  $msg->head->combine('X-Mailer',' and ');
  return unless $msg->smtpsend( Host => smtp() );
  return 1;
}

sub signmsg($)
{
  my $msg= shift;
  die "[signmsg] No message to sign!" unless $msg;
  $msg->remove_sig; # may want to re-sign (random quotes, ...) 
  return Mail::MsgStore::Event::sign($msg);
  #return $msg;
}

sub msgpath
{
  local $_= shift;
  return '/' if m<^[@*/!?\\]$>; # convenience root 
  return if /^[<|>].*[<|>]$/;   # not a path 
  s</{2,}|\\></>g;              # clean path 
  return $_ if -d "$mailroot/$_" 
    or s</$><> or not m<^\W?(.*)/(mail[^/]+mail)$>i;
  return($1,$2);
}

sub msgid
{
  my($folder,$msgid)= @_;
  return unless $msgid; 
  return $msgid if -f "$mailroot/$folder/$msgid";
  $msgid=~ s/\./\\./g; 
  $msgid=~ s/\(.....\)/\\(.....\\)/; # flag-independant msgid search 
  opendir FOLDER, "$mailroot/$folder/" 
    or croak "Unable to open mail folder at '$mailroot/$folder/'.\n";
  $msgid= ( grep { /^$msgid$/i } readdir FOLDER )[0];
  closedir FOLDER;
  return unless $msgid;
  return $msgid;
}

sub accounts()
{ # list accounts 
  dbmopen my %acct, $mailroot.'/accounts', 0600
    or croak "Unable to open accounts database: $!\n";
  my @acct= keys %acct;
  dbmclose %acct;
  return @acct;
}

sub acct_set($;$)
{ # add account: name@server, password
  my($acct,$pass)= @_;
  dbmopen my %acct, $mailroot.'/accounts', 0600
    or croak "Unable to open accounts database: $!\n";
  $acct{$acct}= ($pass ^ getlogin);
  dbmclose %acct;
  return 1;
}

sub acct_del($)
{ # remove account 
  my($acct)= @_;
  dbmopen my %acct, $mailroot.'/accounts', 0600
    or croak "Unable to open accounts database: $!\n";
  delete $acct{$acct};
  dbmclose %acct;
  return 1;
}

sub msgsearch
{
  my $folder= msgid(shift);
  my $match= shift;
  my @match;
  my $wanted= sub 
  { 
    return unless /^mail.*mail$/i;
    (my $folder= $File::Find::dir.'/')=~ s<^$mailroot/><>;
    push @match, $folder.$_ if &$match($MsgStore{"$folder$_"});
  };
  finddepth( $wanted, "$mailroot/$folder" );
  return @match;
}

@addr_field= 
qw(
  key
  firstname
  lastname
  nickname
  email
  url
  chat
  title
  organization
  department
  birthdate
  workphone
  homephone
  cellphone
  pager
  fax
  modem
  street
  city
  state
  zip
  country
  notes
);
@addr_field{@addr_field}=
(
  '',
  'First Name',
  'Last Name',
  'Nickname',
  'email',
  'URL',
  'ICQ/AIM/IRC',
  'Title',
  'Organization',
  'Department',
  'Birthdate',
  'Work Phone',
  'Home Phone',
  'Cell Phone',
  'Pager',
  'Fax',
  'Modem',
  'Street Address',
  'City',
  'State',
  'ZIP',
  'Country',
  'Notes',
);

sub address
{
  local $_;
  my $key;
  $key= shift if @_&1;
  my %addr= @_;
  $key= $addr{key} unless $key;
  if($key and !@_)
  { # retrieve address 
    open ADDR, "<$mailroot/address.tsv" or return;
    while(<ADDR>) { last if /^$key\t/; }
    close ADDR;
    return unless /^$key\t/;
    chomp;
    @addr{@addr_field}= split /\t/;
    if($addr{notes} and $addr{notes}=~ /\\/) 
    { # unescape 
      $addr{notes}=~ s/\\\\/\\/g; 
      $addr{notes}=~ s/\\n/\n/g; 
      $addr{notes}=~ s/\\t/\t/g; 
    }
    return %addr;
  }
  else
  {
    if($addr{notes}) 
    { # escape 
      $addr{notes}=~ s/\\/\\\\/g; 
      $addr{notes}=~ s/\n/\\n/g; 
      $addr{notes}=~ s/\t/\\t/g; 
    }
    if($key)
    { # update/delete key 
      my $tempaddr= 'addr.'.&uniqueid.'.addr';
      open NADDR, ">$mailroot/$tempaddr" or return;
      open ADDR, "<$mailroot/address.tsv" or return;
      flock(ADDR,1) unless $_noflock;
      if($addr{Delete})
      { # delete entry 
        while(<ADDR>) { print NADDR unless /^$key\t/; }
      }
      else
      { # update entry 
        my %prev;
        while(<ADDR>) { last if /^$key\t/; print NADDR; }
        chomp;
        @prev{@addr_field}= split /\t/;
        for(keys %addr) { $prev{$_}= $addr{$_}; }
        print NADDR join("\t",@prev{@addr_field}),"\n";
        print NADDR while(<ADDR>);
      }
      close NADDR;
      close ADDR;
      unlink "$mailroot/address.tsv";
      rename "$mailroot/$tempaddr", "$mailroot/address.tsv";
      return 1;
    }
    else
    { # new: insert (append) 
      $addr{key}= &uniqueid;
      open ADDR, ">>$mailroot/address.tsv" or return;
      flock(ADDR,2) unless $_noflock;
      print ADDR join("\t",@addr{@addr_field}),"\n";
      close ADDR;
      return $addr{key};
    }
  }
  return;
}

sub addresses
{
  local $_;
  my $query= shift;
  my $field= (shift or 'firstname');
  my(%addr,@match);
  open ADDR, "<$mailroot/address.tsv" or return;
  while(<ADDR>)
  {
    chomp;
    @addr{@addr_field}= split /\t/;
    if($addr{notes})
    {
      $addr{notes}=~ s/\\t/\t/g; 
      $addr{notes}=~ s/\\n/\n/g; 
      $addr{notes}=~ s/\\\\/\\/g; 
    }
    push @match, { %addr };
  }
  close ADDR;
  return unless @match;
  return sort { $$a{$$a{MATCHED}} cmp $$b{$$b{MATCHED}} } @match;
}

sub whosearch 
{ # more comprehensive: find entire records 
  local $_;
  my $query= shift;
  my @field= (@_ or qw<firstname lastname>); 
  my(%addr,@match);
  open ADDR, "<$mailroot/address.tsv" or return;
  while(<ADDR>)
  {
    chomp;
    @addr{@addr_field}= split /\t/;
    if($addr{notes})
    {
      $addr{notes}=~ s/\\t/\t/g; 
      $addr{notes}=~ s/\\n/\n/g; 
      $addr{notes}=~ s/\\\\/\\/g; 
    }
    if("@addr{@field}"=~ /$query/)
    { push @match, { %addr, MATCHED => $field[0] }; }
    elsif($addr{nickname}=~ /$query/)
    { push @match, { %addr, MATCHED => 'nickname' }; }
  }
  close ADDR;
  return unless @match;
  @match= sort { $$a{$$a{MATCHED}} cmp $$b{$$b{MATCHED}} } @match;
  return( wantarray ? @match : ${$match[0]}{key} );
}

sub addrsearch
{ # less ambitious: just find addresses 
  local $_;
  my %param= @_;
  my $query= $param{-starts};
  my $number= $param{-number};
  my @field= ( $param{-fields} ? @{$param{-fields}} : qw<firstname lastname> ); 
  my(%addr,@match);
  open ADDR, "<$mailroot/address.tsv" or return;
  while(<ADDR>)
  {
    chomp;
    @addr{@addr_field}= split /\t/;
    if($addr{notes})
    {
      $addr{notes}=~ s/\\t/\t/g; 
      $addr{notes}=~ s/\\n/\n/g; 
      $addr{notes}=~ s/\\\\/\\/g; 
    }
    if("@addr{@field}"=~ /^$query/i)
    { push @match, "$addr{firstname} $addr{lastname} <$addr{email}>"; }
    elsif($addr{nickname}=~ /^$query/i)
    { push @match, 
      "$addr{nickname}\t$addr{firstname} $addr{lastname} <$addr{email}>"; }
  }
  close ADDR;
  @match= ( @match ? ( sort { lc$a cmp lc$b } @match ) : &ldapsearch($query) );
  return unless @match;
  return( wantarray ? @match : $match[$number] );
}

sub ldapsearch
{ # EXTREMELY simple LDAP search 
  my @found;
  my $query= shift;
  return unless length($query) > 2;
  my $filter;
  if($query=~ /\s/)
  { 
    my($first,$last)= split /\s+/, $query, 2;
    $filter= "(&(cn=$first*)(sn=$last*))";
  }
  else
  { $filter= "(cn=$query*)"; }
  for my $server (split /,?\s+|,/, &ldaps())
  {
    my $ldap= new Net::LDAP($server, timeout => 3 ) 
      or die "Unable to use LDAP: $! $@\n";
    $ldap->bind; # anonymous logon 
    my $result= $ldap->search ( filter => $filter, timelimit => 3 );
    carp("LDAP error. ".$result->error()), next if $result->code();
    push @found, map {$_->get('cn')->[0].' <'.$_->get('mail')->[0].'>'} 
      $result->all_entries;
    $ldap->unbind;   # take down session
  }
  return sort { lc$a cmp lc$b } @found;
}

sub simplifymsg
{
  return unless my $msg= shift;
  chomp(my $mtype= lc $msg->get('Content-Type'));
  if($mtype=~ m<^(text/plain|message/rfc822)\b> or not $mtype)
  { # message body 
    return join('',@{$msg->body})."\n";
  }
  elsif($mtype=~ m<^multipart/alternative\b>)
  { # attachments
    my $body;
    my $Brown= new MIME::Parser( output_dir => ( $ENV{TEMP} or $ENV{TMP} ) );
    my $mime= $Brown->parse_data([@{$msg->header}, "\n", @{$msg->body}]);
    for my $mimeitem ($mime->parts)
    { # look for the simplest alternative 
      return "\n\n".$mimeitem->stringify_body()."\n\n"
        if($mimeitem->head->get('Content-Type')=~ m<text/plain>i);
    }
    return "\n\n".$mime->parts(0)->stringify_body()."\n\n";
  }
  else
  { # alternative types 
    my $Brown= new MIME::Parser( output_dir => ( $ENV{TEMP} or $ENV{TMP} ) );
    my $mime= $Brown->parse_data([ split /^/m, $msg->as_string ]);
    my $body;
    for my $mimeitem ($mime->parts)
    {
      if(my $filename= $mimeitem->head->recommended_filename)
      {
        $body.= '['.$mimeitem->head->recommended_filename.'] ';
      }
      else #if($msg->get('Content-Type')=~ m<^(text/plain|message/rfc822)\b>)
      {
        $body.= $mimeitem->stringify_body;
      }
    }
    return $body;
  }
}

sub _folder_sort
{
  $_folder_sort{$a} ? 
    ( $_folder_sort{$b} ? 
      ( $_folder_sort{$a} <=> $_folder_sort{$b} ) : -1 ) : 
    ( $_folder_sort{$b} ? 
      1 : ( $a cmp $b ) );
}


###################################
# 
# Hash Tie Handlers 
# 

sub TIEHASH  { bless {}, $_[0] }
sub CLEAR    { %{$_[0]} = () }

sub STORE
{
  my($this,$key,$val)= @_;
  my($folder,$msgid)= msgpath $key;
  if($msgid)
  { # modify message flag(s) 
    $msgid= msgid($folder,$msgid);
    local $_= $msgid;
    s/(\(.....\))/flags($val,$1)/e;
    rename "$mailroot/$folder/$msgid", "$mailroot/$folder/$_";
    return "$folder/$_";
  }
  elsif($folder eq '/')
  { # use filter() to sort message 
    my @msg= ( isa($val,'ARRAY') ? @$val : ($val) );
    for my $msg (@msg)
    { 
      #print "[STORE:/] Got:\n"; $msg->print; # DEBUG 
      STORE($this,(Mail::MsgStore::Event::filter($msg) or 'Inbox'),$msg); 
    }
    return scalar @msg;
  }
  elsif($folder)
  { # add message(s) to folder 
    $folder= "$mailroot/$folder";
    # create folder unless exists 
    mkpath $folder unless -d $folder;
    croak "Unable to create folder $folder: $!\n" unless -d $folder;
    my @msg= ( isa($val,'ARRAY') ? @$val : ($val) );
    for my $msg (@msg)
    { # add message to folder 
      next unless isa($msg,'Mail::Internet');
      # build msgid: mail.000238C42D34.69FD09C3.00003082.001A.(FLAGS).mail
      $msgid= 'mail.'.&uniqueid;
      local $_= "$folder/$msgid";
      open MESSAGE, ">$_" or croak "Unable to create $_: $!";
      { local $_; $msg->print(\*MESSAGE); } # MIME::Entity isn't friendly to $_ 
      close MESSAGE;
      my $time= parsedate($msg->get('Date'));
      utime $time, $time, $_;
      # message fully saved, complete the msgid (filename) 
      $msg->head->combine('X-Msg-Flags');
      chomp(my $inflags= $msg->get('X-Msg-Flags'));
      rename $_, $_.flags($inflags).'.mail';
    }
    return scalar @msg;
  }
  else
  { # save an instance value 
    return $$this{$key}= $val;
  }
  return;
}

sub EXISTS
{
  my($this,$key)= @_;
  my($folder,$msgid)= msgpath $key;
  if($msgid)
  { # message
    return "$folder/$msgid" if -f "$mailroot/$folder/$msgid";
    return $folder.'/'.msgid($folder,$msgid); # maybe different flags 
  }
  elsif($folder)
  { # folder 
    if(opendir FOLDER, "$mailroot/$folder")
    { # check to see if the folder is empty 
      while($_= readdir FOLDER)
      {
        next unless /^mail\..*\.mail$/;
        close FOLDER;
        return 1;
      }
      close FOLDER;
    }
    return 0;
  }
  else
  {
    return exists $$this{$key};
  }
  return 0;
}

sub FETCH
{
  my($this,$key)= @_;
  my($folder,$msgid)= msgpath $key;
  if($msgid)
  { # message
    $msgid= msgid($folder,$msgid);
    return unless open MESSAGE, "<$mailroot/$folder/$msgid";
    my $msg= new Mail::Internet(\*MESSAGE);
    close MESSAGE;
    { local $_; # head->replace unfriendly to $_ 
      # save current flags internally (will be used if re-saved)
      $msgid=~ m<(\(.....\))>;
      my $curflags= $1;
      $msg->head->replace('X-Msg-Flags',$curflags);
    }
    return $msg;
  }
  elsif($folder eq '/')
  { # convenience root: get new, flagged messages 
    my @new;
    my $wanted= sub 
    { 
      return unless /\(--..-\)/i;
      (my $folder= $File::Find::dir.'/')=~ s<^$mailroot/><>;
      push @new, $folder.$_; 
    };
    finddepth( $wanted, $mailroot );
    return \@new;
  }
  elsif($folder)
  { # folder 
    my @msgid; 
    if(opendir FOLDER, "$mailroot/$folder")
    { 
      @msgid= sort { (stat "$mailroot/$folder/$b")[9] <=> 
          (stat "$mailroot/$folder/$a")[9] } 
        grep /^mail\..*\.mail$/, readdir FOLDER;
      close FOLDER;
    }
    return \@msgid;
  }
  else
  {
    return $$this{$key};
  }
  return;
}

sub DELETE
{
  my($this,$key)= @_;
  my($folder,$msgid)= msgpath $key;
  return if $folder eq '/';
  if($msgid)
  { # Trash, delete & return message 
    $msgid= msgid($folder,$msgid);
    my $msg;
    return  
      unless open MSG, "<$mailroot/$folder/$msgid" 
      and $msg= new Mail::Internet(\*MSG);
    close MSG;
    { local $_; # head->replace unfriendly to $_ 
      # save current flags internally (will be used if re-saved)
      $msgid=~ m<(\(.....\))>;
      my $curflags= $1;
      $msg->head->replace('X-Msg-Flags',$curflags);
    }
    return $msg if unlink "$mailroot/$folder/$msgid";
  }
  elsif($folder)
  { # folder 
    my @msg;
    my $wanted= sub
    {
      return unless /^mail\..*\.mail$/;
      (my $folder= $File::Find::dir.'/')=~ s<^$mailroot/><>;
      my $msg= $MsgStore{$folder.$_};
      push @msg, $msg;
    };
    finddepth( $wanted, "$mailroot/$folder" );
    rmtree "$mailroot/$folder";
    return \@msg;
  }
  else
  {
    return delete $$this{$key};
  }
  return;
}

sub FIRSTKEY
{
  undef @folder;
  my $wanted= sub 
  { 
    (my $folder= $File::Find::dir.'/')=~ s,^$mailroot/,,;
    push @folder, $folder.$_ if -d and $_ ne '.'; 
  };
  finddepth( $wanted, $mailroot );
  @folder= sort {&_folder_sort} @folder;
  return shift @folder;
}

sub NEXTKEY
{
  return shift @folder;
}


%_folder_sort=
(
  Inbox  =>  1,
  Outbox =>  2,
  Draft  =>  4,
  Sent   =>  3,
  Trash  =>  5,
);

%mime_ext=
(
  aif   => 'audio/x-aiff',
  aifc  => 'audio/x-aiff',
  aiff  => 'audio/x-aiff',
  asc   => 'text/plain',
  asp   => 'application/x-asp',
  au    => 'audio/ulaw',
  avi   => 'video/x-msvideo',
  bat   => 'application/x-batchfile',
  bin   => 'application/octet-stream',
  bmp   => 'image/bitmap',
  cgi   => 'application/x-perl',
  cmd   => 'application/x-nt-command-script',
  eps   => 'application/postscript',
  exe   => 'application/octet-stream',
  gif   => 'image/gif',
  gtar  => 'application/x-gtar',
  gz    => 'application/x-gunzip',
  htm   => 'text/html',
  html  => 'text/html',
  ief   => 'image/ief',
  jpe   => 'image/jpeg',
  jpeg  => 'image/jpeg',
  jpg   => 'image/jpeg',
  latex => 'application/x-latex',
  mid   => 'audio/midi',
  midi  => 'audio/midi',
  mov   => 'video/quicktime',
  movie => 'video/x-sgi-movie',
  mp2   => 'video/mpeg',
  mp3   => 'audio/mpeg-layer3',
  mpe   => 'video/mpeg',
  mpeg  => 'video/mpeg',
  mpg   => 'video/mpeg',
  pbm   => 'image/x-portable-bitmap',
  pdf   => 'application/pdf',
  pgm   => 'image/x-portable-graymap',
  pgp   => 'application/pgp',
  pl    => 'application/x-perl',
  pm    => 'application/x-perl',
  png   => 'image/png',
  pnm   => 'image/x-portable-anymap',
  ps    => 'application/postscript',
  qt    => 'video/quicktime',
  ra    => 'audio/x-pn-realaudio',
  ram   => 'audio/x-pn-realaudio',
  ras   => 'image/x-cmu-raster',
  rgb   => 'image/x-rgb',
  rm    => 'audio/x-pn-realaudio',
  rmi   => 'audio/midi',
  rtf   => 'text/richtext',
  rtx   => 'text/richtext',
  shtml => 'text/html',
  snd   => 'audio/basic',
  stm   => 'text/html',
  tar   => 'application/x-tar',
  tif   => 'image/tiff',
  tiff  => 'image/tiff',
  tsv   => 'text/tab-separated-values',
  txt   => 'text/plain',
  wav   => 'audio/x-wav',
  xbm   => 'image/x-bitmap',
  xpm   => 'image/x-pixmap',
  zip   => 'application/zip',
);

$_default_script= <<'SCRIPT_END';
##############################################################
# 
# events.pl - customized mail filtering and more
# 

##############################################################
#
# filter()
# 
# parameter: Mail::Internet object
# returns:   name of folder to store message in 
#            (undef implies 'Inbox')
#
# Message flags can be stored in the 'X-Msg-Flags' message 
# header, and can be either native '(FLAGS)' format, or
# the more readable english 'list, flag, answered' format.
# 
# Flag  English 
#   F   flame
#   L   list/group
#   A   answered/replied
#   G   green/general/flag (general purpose flag)
#   S   seen/read/opened
#
sub filter($) 
{ 
} 

##############################################################
#
# keep()
# 
# parameter: Mail::Internet object
# returns:   boolean - keep message on server?
#
# The source account is stored in the 'X-Recipient-Account'
# message header.
# 
sub keep($) 
{
  return; # delete by default (no return value = false)
}

##############################################################
#
# sign()
# 
# parameter: Mail::Internet object
# returns:   the modified Mail::Internet object
#
# Add a signature to a message.
#   $msg->sign( Signature => 'Your Signature Message' );
# 
sub sign($) 
{ 
  my $msg= shift;
  $msg->sign( Signature => 'Your Signature Message' );
  return $msg;
}

local $_;1
SCRIPT_END


###################################
# 
# Initialization 
# 

tie %MsgStore, __PACKAGE__;
if($ENV{MAILROOT})
{ mailroot($ENV{MAILROOT}); }
else
{
  $mailroot= '.';
  { package Mail::MsgStore::Event;
    sub filter($) { }
    sub keep($) { 1 }
    sub sign($) { }
  }
}

1