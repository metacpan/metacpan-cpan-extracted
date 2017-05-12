package LJ::Simple;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw();
@EXPORT = qw();
$VERSION = '0.15';

## Bring in modules we use
use strict;		# Silly not to be strict
use Socket;		# Required for talking to the LJ server
use POSIX;		# For errno values and other POSIX functions

## Helper function prototypes
sub Debug(@);
sub EncVal($$);
sub DecVal($);
sub SendRequest($$$$);
sub dump_list($$);
sub dump_hash($$);

=pod

=head1 NAME

LJ::Simple - A perl module to access LiveJournal via its flat protocol

=head1 SYNOPSIS

C<LJ::Simple> is an object based C<perl> module which is used to access
LiveJournal-based web logs. This module implements most of the
flat protocol LiveJournal uses; for details of this protocol please
see: L<http://www.livejournal.com/developer/protocol.bml>

=head1 REQUIREMENTS

This module requires nothing other than the modules which come with the
standard perl 5.6.1 distribution. The only modules it B<requires> are
C<POSIX> and C<Socket>.

If you have the C<Digest::MD5> module available then the code will make use of
encrypted passwords automatically. However C<Digest::MD5> is not required for
this module to work.

=head1 DESCRIPTION

C<LJ::Simple> is a trival API to access LiveJournal. Currently it
allows you to:

=over 2

=item Login

Log into the LiveJournal system

=item Post

Post a new journal entry in the LiveJournal system

=item Synchronise

Returns a list of journal entries created or modified from a given
date.

=item Edit

Edit the contents of an existing entry within the LiveJournal system

=item Delete

Delete an existing post from the LiveJournal system

=back

=head1 EXAMPLE

The following simple examples shows you how to use the module to post a
simple LiveJournal entry.

=head2 Using LJ::Simple::QuickPost()

C<LJ::Simple::QuickPost()> is a routine which allows you to quickly post an entry into
LiveJournal; as such it lacks a lot of the abilities which using the object-based
interface provides. The C<LJ::Simple::QuickPost()> routine is explained in depth below, however
the following example shows how it can be used to easily post to LiveJournal:

  use LJ::Simple;
  
  LJ::Simple::QuickPost(
	user	=>	"test",
	pass	=>	"test",
	entry	=>	"Just a simple entry",
    ) || die "$0: Failed to post entry: $LJ::Simple::error\n";

=head2 Using the standard calls

  use LJ::Simple;

  # Log into the server
  my $lj = new LJ::Simple ({
          user    =>      "test",
          pass    =>      "test",
          site    =>      undef,
        });
  (defined $lj)
    || die "$0: Failed to log into LiveJournal: $LJ::Simple::error\n";
  
  # Prepare the event
  my %Event=();
  $lj->NewEntry(\%Event) ||
    die "$0: Failed to create new entry: $LJ::Simple::error\n";
  
  # Put in the entry
  my $entry=<<EOF;
  A simple entry made using <tt>LJ::Simple</tt> version $LJ::Simple::VERSION
  EOF
  $lj->SetEntry(\%Event,$entry)
    || die "$0: Failed to set entry: $LJ::Simple::error\n";
  
  # Say we are happy
  $lj->SetMood(\%Event,"happy")
    || die "$0: Failed to set mood: $LJ::Simple::error\n";
  
  # Post the event
  my ($item_id,$anum,$html_id)=$lj->PostEntry(\%Event);
  (defined $item_id)
    || die "$0: Failed to post journal entry: $LJ::Simple::error\n";

=head1 VARIABLES

There are various variables which can be used to control certain
aspects of the module. It is generally recommended that if you
wish to change these variables that you do so B<before> you
create the initial object.

The variable you are most likely to use is C<$LJ::Simple::error>
which holds error messages if any of the C<LJ::Simple> calls
fail.

=over 4

=item $LJ::Simple::error

Holds error messages, is set with a blank string at the
start of each method. Whilst the messages are relatively free-form,
there are some prefixes which are sometimes used:

  CODE:     An error in the code calling the API
  INTERNAL: An internal error in this module

=item $LJ::Simple::debug

If set to C<1>, debugging messages are sent to stderr. 

=item $LJ::Simple::protocol

If set to C<1> the protocol used to talk to the remote server is sent to stderr.

=item $LJ::Simple::raw_protocol

If set to C<1> the raw protocol used to talk to the remote server is sent to stderr;
this is only useful if you are doing debugging on C<LJ::Simple> itself as the protocol
is shown as the module gets it from the server; non-printable characters are converted
to their octal presentation form, I<ie> a newline becomes C<\012>.

It should be noted that if C<$LJ::Simple::raw_protocol> is set along with
C<$LJ::Simple::protocol> then the raw protocol display takes precedence for data
returning from the LJ server.

=item $LJ::Simple::UTF

If set to C<1> the LiveJournal server is told to expect UTF-8 encoded characters.
If you enable this the module will attempt to use the utf8 perl module.

The default is see if we have a version of Perl with UTF-8 support and use
it if its available.

=item $LJ::Simple::challenge

If set to C<1> we make use of the challenge-response system instead of using
plain or hashed passwords. This does add some overhead into processing requests
since every action has to be preceeded by a request for a challenge value from
the server.

The default is to see if we have the C<Digest::MD5> module available and if
so we make use of the challenge-response system. This can be disabled by
setting the variable to C<0>.

=item $LJ::Simple::timeout

The time - specified in seconds - to wait for data from the server. If
given a value of C<undef> the API will block until data is avaiable.

=item $LJ::Simple::NonBlock

By default this is set to C<undef>. When given a reference to a sub-routine this
module will call the given sub-routine at various stages of processing the responses
to the LiveJournal server. This is intended for GUI applications which need to process
event queues, update progress bars, I<etc>. When called the sub-routine is passed a
number of variables which maybe useful; the calling method is:

  &{sub}($mode,$status,$action,$bytes_in,$bytes_out,$time,$waiting)

    $mode      - The mode sent to the LJ server
    $status    - The status of the request; ranges from 0 to 1
    $action    - The action performed
    $bytes_in  - The number of bytes read from the remote server
    $bytes_out - The number of bytes written to the remote server
    $time      - The time taken so far in seconds
    $waiting   - Are we waiting for a response from the server ?

It should be noted that if C<$waiting> is set to C<1> then it is B<highly> recommended
that the sub-routine calls C<select()> itself to provide at least some time delay. If
this is not done it is likely that this module will consume far more CPU than necessary.

An example sub-routine follows:

  sub LJStatus {
    my ($mode,$status,$action,$bytes_in,$bytes_out,$time,$waiting) = @_;
    print "\$mode      = $mode\n";
    print "\$status    = $status\n";
    print "\$action    = $action\n";
    print "\$bytes_in  = $bytes_in\n";
    print "\$bytes_out = $bytes_out\n";
    print "\$time      = $time\n";
    print "\$waiting   = $waiting\n";
    print "\n";
    ($waiting) && select(undef,undef,undef,0.5);
  }
  
  $LJ::Simple::NonBlock=\&LJStatus;

=item $LJ::Simple::ProtoSub

By default this points to a sub-routine within the module; this is called when
the protocol between the module and LiveJournal server is to be shown, in other
words when C<$LJ::Simple::protocol> is set to C<1>. The sub-routine called must
take two variables; it is called in the following way:

  &{sub}($direction,$data,$server,$ip_addr)

    $direction - The direction of the flow; 0 means from client to server
                 and 1 means from server to client
    $data      - The data which has flowed; there should not be any newlines
                 with the data, but do not rely on this.
    $server    - The name of the LJ server we are talking to
    $ip_addr   - The IP address of the LJ server we are talking to

If both variables are C<undef> then data is about to flow. If just C<$direction> is
C<undef> then C<$data> holds an informational message.

The standard sub-routine which is called is:

  sub DefaultProtoSub {
    my ($direct,$data,$server,$ip_addr)=@_;
    my $arrow="--> ";
    if (!defined $direct) {
      if (!defined $data) {
        print STDERR "Connecting to $server [$ip_addr]\n";
        print STDERR "Lines starting with \"-->\" is data SENT to the server\n";
        print STDERR "Lines starting with \"<--\" is data RECEIVED from the server\n";
        return;
      }
      $arrow="";
    } else {
      ($direct) && ($arrow="<-- ");
    }
    print STDERR "$arrow$data\n";
  }
  
  $LJ::Simple::ProtoSub=\&DefaultProtoSub;

=item $LJ::Simple::buffer

The number of bytes to try and read in on each C<sysread()> call.

=back

=cut

sub DefaultProtoSub {
  my ($direct,$data,$server,$ip_addr)=@_;
  my $arrow="--> ";
  if (!defined $direct) {
    if (!defined $data) {
      print STDERR "Connecting to $server [$ip_addr]\n";
      print STDERR "Lines starting with \"-->\" is data SENT to the server\n";
      print STDERR "Lines starting with \"<--\" is data RECEIVED from the server\n";
      return;
    }
    $arrow="";
  } else {
    ($direct) && ($arrow="<-- ");
  }
  print STDERR "$arrow$data\n";
}


## Global variables - documented
# Debug ?
$LJ::Simple::debug=0;
# Show protocol ?
$LJ::Simple::protocol=0;
# Protocol handling code
$LJ::Simple::ProtoSub=\&DefaultProtoSub;
# Show raw protocol ?
$LJ::Simple::raw_protocol=0;
# Use UTF-8 ?
$LJ::Simple::UTF = undef;
# Use challenge-response ?
$LJ::Simple::challenge = undef;
# Use non-block sub-routine
$LJ::Simple::NonBlock = undef;
# Errors
$LJ::Simple::error="";
# Timeout for reading from sockets - default is 5 minutes
$LJ::Simple::timeout = 300;
# How much data to read from the socket in one read()
$LJ::Simple::buffer = 8192;

## Global variables - internal and undocumented
# Should we not fully run the QuickPost routine ?
$LJ::Simple::TestStopQuickPost = 0;

## Internal variables - private to this module
# Standard ports
my %StdPort = (
	http		=>	80,
	http_proxy	=>	3128,
);

=pod

=head1 AVAILABLE METHODS

=head2 LJ::Simple::QuickPost()

C<LJ::Simple::QuickPost()> is a routine which allows you to quick post to LiveJournal.
However it does this by hiding a lot of the details involved in using
C<LJ::Simple> to do this. This routine will do all of the work involved in
logging into the LiveJournal server, preparing the entry and then posting it.
If at any stage there is a failure then C<0> is returned and C<$LJ::Simple::error>
will contain the reason why. If the entry was successfully posted to the LiveJournal
server then the routine will return C<1>.

There are a number of options to the C<LJ::Simple::QuickPost()> routine:

  LJ::Simple::QuickPost(
	user	=>	Username
	pass	=>	Password
	entry	=>	Contents of the entry
	subject	=>	Subject line of the entry
	mood	=>	Current mood
	music	=>	Current music
	html	=>	HTML content ?
	protect	=>	Security settings of the entry
	groups	=>	Friends groups list
	tags	=>	Tags list
	results	=>	Hash to store results in
  );

Of these, only the C<user>, C<pass> and C<entry> options are required; all of the other
options are optional. The option names are all case insensitive.

=over 4

=item user

The username who owns the journal the entry should be posted to;
this option is B<required>.

=item pass

The password of the C<user>;
this option is B<required>.

=item entry

The actual entry itself;
this option is B<required>.

=item subject

The subject line of the post.

=item mood

The mood to associate with the post; the value is given to the C<SetMood()> method
for processing.

=item music

The music to associate with the post.

=item html

This is a boolean value of either C<1> or C<0>. If you want to say that the entry
contains HTML and thus should be considered to be preformatted then set C<html> to
C<1>. Otherwise you can either set it to C<0> or not give the option.

=item protect

By default the new entry will be public unless you give the C<protect> option. This
option should be given the protection level required for the post and can be one of
the following:

  public  - The entry is public
  friends - Entry is friends-only
  groups  - Entry is restricted to friends groups
  private - Entry is restricted to the journal's owner

If you set the C<protect> option to C<groups> you must also include the C<groups>
option - see below for details.

=item groups

If the C<protect> option is set to C<groups> then this option should contain a
list reference which contains the list of groups the entry should be restricted to.
This option is B<required> if the C<protect> option is set to C<groups>.

=item tags

Set tags for the entry; this should contain a list reference which contains the
tags to be set.

=item results

The results of posting the entry should be returned; this should contain a
hash reference. The hash given will be filled with the result of posting the
article; the hash refered to B<will be emptied> by this.

The keys in the hash point to:

  ok      - Return code of QuickPost
  item_id - Item_id as returned by the LiveJournal server
  anum    - Anum as returned by the LiveJournal server
  html_id - The item_id of the entry as used in HTML
  url     - A URL which could be used to access the entry

It should be noted that when C<QuickPost()> fails, C<ok> will point to
a value of C<0> and all other entries in the hash will be C<undef>.

=back

Example code:

  # Simple test post
  LJ::Simple::QuickPost(
	user	=>	"test",
	pass	=>	"test",
	entry	=>	"Just a simple entry",
    ) || die "$0: Failed to post entry: $LJ::Simple::error\n";
  
  # A friends-only preformatted entry
  LJ::Simple::QuickPost(
	user	=>	"test",
	pass	=>	"test",
	entry	=>	"<p>Friends-only, preformatted, entry</p>",
	html	=>	1,
	protect	=>	"friends",
    ) || die "$0: Failed to post entry: $LJ::Simple::error\n";
  
  # A entry restricted to several friends groups
  LJ::Simple::QuickPost(
	user	=>	"test",
	pass	=>	"test",
	entry	=>	"Entry limited to friends groups",
	protect	=>	"groups",
	groups	=>	[qw( one_group another_group )],
    ) || die "$0: Failed to post entry: $LJ::Simple::error\n";

  # Simple test post with tags and returning HTML
  my %Results=();
  LJ::Simple::QuickPost(
	user	=>	"test",
	pass	=>	"test",
	entry	=>	"Just a simple entry",
	tags	=>	[ "Just a test", "Testing" ],
	results	=>	\%Results,
    ) || die "$0: Failed to post entry: $LJ::Simple::error\n";
  print "URL = $Results{url}\n";

=cut
sub QuickPost(@) {
  my %opts=();
  my @prot_opts=();
  while($#_>-1) {
    my $k=lc(shift(@_));
    my $v=shift(@_);
    (defined $v) || next;
    $opts{$k}=$v;
  }
  foreach (qw( user pass entry )) {
    (exists $opts{$_}) && next;
    $LJ::Simple::error="CODE: QuickPost() called without the required $_ option";
    return 0;
  }
  if ((exists $opts{html}) && ($opts{html}!~/^[01]$/)) {
    $LJ::Simple::error="CODE: QuickPost() not given either 0 or 1 for html option";
    return 0;
  }
  if ((exists $opts{protect}) && ($opts{protect} eq "groups")) {
    if (!exists $opts{groups}) {
      $LJ::Simple::error="CODE: QuickPost() given protect=groups, but no groups option";
      return 0;
    }
    if (ref($opts{groups}) ne "ARRAY") {
      $LJ::Simple::error="CODE: QuickPost() not given a list reference for the groups option";
      return 0;
    }
    @prot_opts=@{$opts{groups}};
  }
  if ((exists $opts{tags}) && (ref($opts{tags}) ne "ARRAY")) {
    $LJ::Simple::error="CODE: QuickPost() not given a list reference for the tags option";
    return 0;
  }
  if ((exists $opts{results}) && (ref($opts{results}) ne "HASH")) {
    $LJ::Simple::error="CODE: QuickPost() not given a hash reference for the results option";
    return 0;
  }

  # Kludge so we can test the input validation
  ($LJ::Simple::TestStopQuickPost) && return 1;
  
  my $lj = new LJ::Simple({
	user	=>	$opts{user},
	pass	=>	$opts{pass},
  });
  (defined $lj) || return 0;

  my %Event=();
  $lj->NewEntry(\%Event) || return 0;
  $lj->SetEntry(\%Event,$opts{entry}) || return 0;
  (exists $opts{subject}) &&
    ($lj->SetSubject(\%Event,$opts{subject}) || return 0);
  (exists $opts{mood}) &&
    ($lj->SetMood(\%Event,$opts{mood}) || return 0);
  (exists $opts{music}) &&
    ($lj->Setprop_current_music(\%Event,$opts{music}) || return 0);
  (exists $opts{html}) &&
    ($lj->Setprop_preformatted(\%Event,$opts{html}) || return 0);
  (exists $opts{protect}) &&
    ($lj->SetProtect(\%Event,$opts{protect},@prot_opts) || return 0);
  (exists $opts{tags}) &&
    ($lj->Setprop_taglist(\%Event,@{$opts{tags}}) || return 0);

  my $RetCode = 0;
  my ($item_id,$anum,$html_id)=$lj->PostEntry(\%Event);
  (defined $item_id) && ($RetCode=1);
  if (exists $opts{results}) {
    my $user=$lj->user();
    my $server=$lj->{lj}->{host};
    my $port=$lj->{lj}->{port};
    %{$opts{results}}=(
	ok	=>	$RetCode,
	item_id	=>	$item_id,
	anum	=>	$anum,
	html_id	=>	$html_id,
	url	=>	"http://$server:$port/users/$user/$html_id.html",
    );
  }
  return $RetCode;
}

=pod

=head2 Object creation

=over 4

=item login

Logs into the LiveJournal system.

  ## Simplest logon method
  my $lj = new LJ::Simple ( {
		user	=>	"username",
		pass	=>	"password",
    } );
  
  ## Login with options
  my $lj = new LJ::Simple ( {
		user	=>	"username",
		pass	=>	"password",
		site	=>	"hostname[:port]",
		proxy	=>	"hostname[:port]",
		moods	=>	0 | 1,
		pics	=>	0 | 1,
		fast	=>	0 | 1,
    } );

  ## Login by using login()
  my $lj = LJ::Simple->login ( {
		user	=>	"username",
		pass	=>	"password",
		site	=>	"hostname[:port]",
		proxy	=>	"hostname[:port]",
		moods	=>	0 | 1,
		pics	=>	0 | 1,
		fast	=>	0 | 1,
    } );

Where:

  user     is the username to use
  pass     is the password associated with the username
  site     is the remote site to use
  proxy    is the HTTP proxy site to use; see below.
  moods    is set to 0 if we do not want to download the mood
           list. Defaults to 1
  pics     is set to 0 if we do not want to download the user
           picture information. Defaults to 1
  fast     is set to 1 if we want to perform a fast login.
           Default is 0. See below for details of this.

Sites defined in C<site> or C<proxy> are a hostname with an
optional port number, separated by a C<:>, i.e.:

  www.livejournal.com
  www.livejournal.com:80

If C<site> is given C<undef> then the code assumes that you wish to
connect to C<www.livejournal.com:80>. If no port is given then port
C<80> is the default.

If C<proxy> is given C<undef> then the code will go directly to the
C<$site> unless a suitable environment variable is set.
If no port is given then port C<3128> is the default.

C<LJ::Simple> also supports the use the environment variables C<http_proxy>
and C<HTTP_PROXY> to store the HTTP proxy server details. The format of these
environment variables is assumed to be:

  http://server[:port]/

Where C<server> is the name of the proxy server and the optional C<port> the
proxy server is on - port C<3128> is used if no port is explicitly given.

It should be noted that the proxy environment variables are B<only> checked
if the C<proxy> value is B<NOT> given to the C<LJ::Simple> object creation.
Thus to disable looking at the proxy environment variables use
C<proxy=E<gt>undef> in C<new()> or C<login()>.

If C<moods> is set to C<0> then the mood list will not be pulled from
the LiveJournal server and the following functions will be affected:

  o moods() will always return undef (error)
  o Setprop_current_mood_id() will not validate the mood_id
    given to it.
  o SetMood() will not attempt to convert the string it is
    given into a given mood_id

If C<pics> is set to C<0> then the data on the user pictures will
not be pulled from the LiveJournal server and the following
functions will be affected:

  o pictures() will always return undef (error)
  o Setprop_picture_keyword() will blindly set the picture keyword
    you give it - no validation will be performed.
  o DefaultPicURL() will always return undef (error)

If C<fast> is set to C<1> then we will perform a I<fast login>. Essentially
all this does is to set up the various entries in the object hash which
the routines called after C<login> expect to see; at no time does it talk to
the LiveJournal servers. What this means is that it is very fast. However it
also means that when you use parts of the API which B<do> talk to the LiveJournal
servers its quite possible that you will get back errors associated with
authentication errors, network outages, I<etc>. In other words, in C<fast> mode
the login will always succeed, no matter what the state the LiveJournal
server we're talking is in. It should be noted that the following functions
will be affected if you enable the I<fast login>:

  o moods() will always return undef (error)
  o Setprop_current_mood_id() will not validate the mood_id
    given to it
  o SetMood() will not attempt to convert the string it is
    given into a given mood_id
  o pictures() will always return undef (error)
  o Setprop_picture_keyword() will blindly set the picture keyword
    you give it - no validation will be performed
  o communities() will always return an empty list
  o MemberOf() will always return 0 (error)
  o UseJournal() will not validate the shared journal name you
    give it
  o groups() will always return undef (error)
  o MapGroupToId() will always undef (error)
  o MapIdToGroup() will always undef (error)
  o SetProtectGroups() will always 0 (error)
  o message() will always return undef (error)
  o The key of "groups" in the list of hashes returned by
    GetFriends() will always point to an empty list
  o CheckFriends() will return undef (error) if you give it a
    list of groups

On success this sub-routine returns an C<LJ::Simple> object. On
failure it returns C<undef> with the reason for the failure being
placed in C<$LJ::Simple::error>.

Example code:

  ## Simple example, going direct to www.livejournal.com:80
  my $lj = new LJ::Simple ({ user => "someuser", pass => "somepass" });
  (defined $lj) ||
    die "$0: Failed to access LiveJournal - $LJ::Simple::error\n";

  ## More complex example, going via a proxy server on port 3000 to a
  ## a LiveJournal system available on port 8080 on the machine
  ## www.somesite.com.
  my $lj = new LJ::Simple ({ 
	user	=> "someuser",
	pass	=> "somepass", 
	site	=> "www.somesite.com:8080",
	proxy	=> "proxy.internal:3000",
  });
  (defined $lj) ||
    die "$0: Failed to access LiveJournal - $LJ::Simple::error\n";

  ## Another complex example, this time saying that we do not want
  ## the mood list or user pictures downloaded
  my $lj = new LJ::Simple ({ 
	user	=> "someuser",
	pass	=> "somepass", 
	pics	=> 0,
	moods	=> 0,
  });
  (defined $lj) ||
    die "$0: Failed to access LiveJournal - $LJ::Simple::error\n";
  
  ## Final example - this one shows the use of the fast logon
  my $lj = new LJ::Simple ({ 
	user	=> "someuser",
	pass	=> "somepass", 
	fast	=> 1,
  });
  (defined $lj) ||
    die "$0: Failed to access LiveJournal - $LJ::Simple::error\n";

=cut
##
## Log into the LiveJournal system. Given that the LJ stuff is just
## layered over HTTP, its not essential to do this. However it does
## mean that we can check the auth details, get some useful info for
## later, etc.
##
sub login($$) {
  # Handle the OOP stuff
  my $this=shift;
  $LJ::Simple::error="";
  if ($#_ != 0) {
    $LJ::Simple::error="CODE: Incorrect usage of login() for argv - see docs";
    return undef;
  }
  # Get the hash
  my $hr = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self,$class;
  if ((!exists $hr->{user})||($hr->{user} eq "") ||
      (!exists $hr->{pass})||($hr->{pass} eq "")) {
    $LJ::Simple::error="CODE: Incorrect usage of login() - see docs";
    return undef;
  }
  $self->{auth}={
	user		=>	$hr->{user},
	pass		=>	$hr->{pass},
	challenge	=>	{},
  };
  if (! defined $LJ::Simple::UTF) {
    eval { require utf8 };
    if (!$@) {
      $LJ::Simple::UTF=1;
      Debug("UTF-8 support found");
    } else {
      $LJ::Simple::UTF=0;
      Debug("No UTF-8 support found");
    }
  } elsif ($LJ::Simple::UTF) {
    eval { require utf8 };
    if (!$@) {
      Debug("Using UTF-8 as requested");
    } else {
      $LJ::Simple::error="CODE: no UTF-8 support in your version of perl";
      return undef;
    }
  }
  eval { require Digest::MD5 };
  if (!$@) {
    Debug("Using Digest::MD5");
    my $md5=Digest::MD5->new;
    $md5->add($hr->{pass});
    $self->{auth}->{hash}=$md5->hexdigest;
    delete $self->{auth}->{pass};
    (!defined $LJ::Simple::challenge) && ($LJ::Simple::challenge=1);
  } else {
    if ((defined $LJ::Simple::challenge)&&($LJ::Simple::challenge)) {
      $LJ::Simple::error="Challenge-response auth requested, no Digest::MD5 found";
      return undef;
    }
    $LJ::Simple::challenge=0;
  }
  if ((exists $hr->{site})&&(defined $hr->{site})&&($hr->{site} ne "")) {
    my $site_port=$StdPort{http};
    if ($hr->{site}=~/\s*(.*?):([0-9]+)\s*$/) {
      $hr->{site} = $1;
      $site_port = $2;
    }
    $self->{lj}={
  	host	=>	$hr->{site},
  	port	=>	$site_port,
    }
  } else {
    $self->{lj}={
  	host	=>	"www.livejournal.com",
  	port	=>	$StdPort{http},
    }
  }
  if ((exists $hr->{proxy})&&(defined $hr->{proxy})&&($hr->{proxy} ne "")) {
    my $proxy_port=$StdPort{http_proxy};
    if ($hr->{proxy}=~/\s*(.*?):([0-9]+)\s*$/) {
      $hr->{proxy} = $1;
      $proxy_port = $2;
    }
    $self->{proxy}={
  	host	=>	$hr->{proxy},
  	port	=>	$proxy_port,
    };
  } elsif (!exists $hr->{proxy}) {
    # Getting proxy details from the environment; assumes that the proxy is
    # given as http://site[:port]/
    # The first matching env is used.
    foreach my $env (qw( http_proxy HTTP_PROXY )) {
      (exists $ENV{$env}) || next;
      ($ENV{$env}=~/^(?:http:\/\/)([^:\/]+)(?::([0-9]+)){0,1}/o) || next;
      $self->{proxy}={
  	host	=>	$1,
  	port	=>	$2,
      };
      (defined $self->{proxy}->{port}) || ($self->{proxy}->{port}=$StdPort{http_proxy});
    }
  } else {
    $self->{proxy}=undef;
  }

  # Set fastserver to 0 until we know better
  $self->{fastserver}=0;

  if ((exists $hr->{fast}) && ($hr->{fast}==1)) {
    ## Doing fast login, so return object
    Debug(dump_hash($self,""));
    return $self;
  }
  
  my $GetMoods=1;
  if ((exists $hr->{moods}) && ($hr->{moods}==0)) {
    $GetMoods=0;
  }
  my $GetPics=1;
  if ((exists $hr->{pics}) && ($hr->{pics}==0)) {
    $GetPics=0;
  }

  # Perform the actual login
  $self->SendRequest("login", {
	"moods"		=>	$GetMoods,
	"getpickws"	=>	$GetPics,
	"getpickurls"	=>	$GetPics,
    },undef) || return undef;

  # Now see if we can set fastserver
  if ( (exists $self->{request}->{lj}->{fastserver}) &&
       ($self->{request}->{lj}->{fastserver} == 1) ) {
    $self->{fastserver}=1;
  }

  # Moods
  $self->{moods}=undef;
  $self->{mood_map}=undef;
  # Shared access journals
  $self->{access}=undef;
  # User groups
  $self->{groups}=undef;
  # Images defined
  $self->{pictures}=undef;
  # Default URL
  $self->{defaultpicurl}=undef;
  # Message from LJ
  $self->{message}=undef;

  # Handle moods, etc.
  my ($k,$v)=(undef,undef);
  while(($k,$v) = each %{$self->{request}->{lj}}) {

    # Message from LJ
    if ($k eq "message") {
      $self->{message}=$v;

    # Moods
    } elsif ($k=~/^mood_([0-9]+)_([a-z]+)/o) {
      my ($id,$type)=($1,$2);
      if (!defined $self->{moods}) {
        $self->{moods}={};
      }
      if (!exists $self->{moods}->{$id}) {
        $self->{moods}->{$id}={};
      }
      if ($type eq "id") {
        $self->{moods}->{$id}->{id}=$v;
      } elsif ($type eq "name") {
        $self->{moods}->{$id}->{name}=$v
      }

    # Picture key words
    } elsif ($k=~/^(pickw_count)/o) {
      if (!defined $self->{pictures}) {
        $self->{pictures}={};
      }
    } elsif ($k eq "defaultpicurl") {
      $self->{defaultpicurl}=$v;
    } elsif ($k=~/^(pickw[^_]*)_([0-9]+)/o) {
      my ($type,$id)=($1,$2);
      if (!defined $self->{pictures}) {
        $self->{pictures}={};
      }
      if (!exists $self->{pictures}->{$id}) {
        $self->{pictures}->{$id}={};
      }
      if ($type eq "pickwurl") {
        $self->{pictures}->{$id}->{url}=$v;
      } elsif ($type eq "pickw") {
        $self->{pictures}->{$id}->{name}=$v
      }

    # Shared access journals
    } elsif ($k=~/^access_([0-9]+)/) {
      if (!defined $self->{access}) {
        $self->{access}={};
      }
      $self->{access}->{$v}=1;

    # Groups
    } elsif ($k=~/^frgrp_([0-9]+)_(.*)/) {
      my ($id,$type)=($1,$2);
      if (!defined $self->{groups}) {
        $self->{groups}={
          src  => {},  # Source data
          id   => {},  # Id -> name mapping
          name => {},  # Real data, name keyed
        };
      }
      if (!exists $self->{groups}->{src}->{$id}) {
        $self->{groups}->{src}->{$id}={};
      }
      if ($type eq "sortorder") {
        $self->{groups}->{src}->{$id}->{sort}=$v;
      } elsif ($type eq "name") {
        $self->{groups}->{src}->{$id}->{name}=$v
      }
    }
  }

  ## We now handle the group hash fully. Note in the case
  ## of groups having the same name, only the first will
  ## go into the name hash.
  ($k,$v)=(undef,undef);
  while(($k,$v)=each %{$self->{groups}->{src}}) {
    $self->{groups}->{id}->{$k}=$v->{name};
    if (!exists $self->{groups}->{name}->{$v->{name}}) {
      $self->{groups}->{name}->{$v->{name}} = {
        id   => $k,
        name => $v->{name},
        sort => $v->{sort},
      };
    }
  }

  ##
  ## And now we handle the mood map fully
  ##
  if ($GetMoods) {
    $self->{mood_map}={};
    foreach (values %{$self->{moods}}) {
      $self->{mood_map}->{lc($_->{name})}=$_->{id};
    }
  }

  Debug(dump_hash($self,""));
  
  ## Logged in, so return self.
  return $self;
}

## Define reference from new to login
*new="";
*new=\&login;


=pod

=back

=head2 Getting data from the LiveJournal login

=over 4

=item $lj->message()

Returns back a message set in the LiveJournal system. Either
returns back the message or C<undef> if no message is set.

Example code:

  my $msg = $lj->message();
  (defined $msg) &&
    print "LJ Message: $msg\n";

=cut
sub message($) {
  my $self=shift;
  return $self->{message};
}

=pod

=item $lj->moods($hash_ref)

Takes a reference to a hash and fills it with information about
the moods returned back by the server. Either returns back the
same hash reference or C<undef> on error.

Note that if the LiveJournal
object was created with either C<moods> set to C<0> or
with C<fast> set to C<1> then this function will always return
an error.

The hash the given reference is pointed to is emptied before
it is used and after a successful call the hash given will
contain:

  %hash = (
    list    => [ list of mood names, alphabetical ]
    moods   => {
      mood_name => mood_id
    }
    idents  => {
      mood_id   => mood_name
    }
  )


Example code:

  my %Moods=();
  if (!defined $lj->moods(\%Moods)) {
    die "$0: LJ error - $LJ::Simple::error";
  }
  foreach (@{$Moods{list}}) {
    print "$_ -> $Moods{moods}->{$_}\n";
  }
  

=cut
sub moods($$) {
  my $self=shift;
  my ($hr) = @_;
  $LJ::Simple::error="";
  if (ref($hr) ne "HASH") {
    $LJ::Simple::error="CODE: moods() not given a hash reference";
    return undef;
  }
  if (!defined $self->{moods}) {
    $LJ::Simple::error="Unable to return moods - not requested at login";
    return undef;
  }
  %{$hr}=(
    list	=> [],
    moods	=> {},
    idents	=> {},
  );
  my ($k,$v);
  while(($k,$v)=each %{$self->{moods}}) {
    push(@{$hr->{list}},$v->{name});
    $hr->{moods}->{$v->{name}}=$v->{id};
    $hr->{idents}->{$v->{id}}=$v->{name};
  }
  $hr->{list} = [ (sort { $a cmp $b } @{$hr->{list}}) ];
  return $hr;
}

=pod

=item $lj->communities()

Returns a list of shared access communities the user logged in can
post to. Returns an empty list if no communities are available

Example code:

  my @communities = $lj->communities();
  print join("\n",@communities),"\n";

=cut
sub communities($) {
  my $self=shift;
  $LJ::Simple::error="";
  (defined $self->{access}) || return ();
  return sort {$a cmp $b} (keys %{$self->{access}});
}


=pod

=item $lj->MemberOf($community)

Returns C<1> if the user is a member of the named community. Returns
C<0> otherwise.

Example code:

  if ($lj->MemberOf("some_community")) {
     :
     :
     :
  }

=cut
sub MemberOf($$) {
  my $self=shift;
  my ($community)=@_;
  $LJ::Simple::error="";
  (defined $self->{access}) || return 0;
  return (exists $self->{access}->{$community});
}

=pod

=item $lj->groups($hash_ref)

Takes a reference to a hash and fills it with information about
the friends groups the user has configured for themselves. Either
returns back the hash reference or C<undef> on error.

The hash the given reference points to is emptied before it is
used and after a successful call the hash given will contain
the following:

   %hash = (
     "name" => {
       "Group name" => {
         id   => "Number of the group",
         sort => "Sort order",
         name => "Group name (copy of key)",
       },
     },
     "id"   => {
       "Id"   => "Group name",
     },
   );

Example code:

  my %Groups=();
  if (!defined $lj->groups(\%Groups)) {
    die "$0: LJ error - $LJ::Simple::error";
  }
  my ($id,$name)=(undef,undef);
  while(($id,$name)=each %{$Groups{id}}) {
    my $srt=$Groups{name}->{$name}->{sort};
    print "$id\t=> $name [$srt]\n";
  }

=cut
sub groups($$) {
  my $self=shift;
  my ($hr) = @_;
  $LJ::Simple::error="";
  if (ref($hr) ne "HASH") {
    $LJ::Simple::error="CODE: groups() not given a hash reference";
    return undef;
  }
  if (!defined $self->{groups}) {
    $LJ::Simple::error="Unable to return groups - none defined";
    return undef;
  }
  %{$hr}=(
    name => {},
    id   => {},
  );
  my ($k,$v);
  while(($k,$v)=each %{$self->{groups}->{id}}) {
    $hr->{id}->{$k}=$v;
  }
  while(($k,$v)=each %{$self->{groups}->{name}}) {
    $hr->{name}->{$k}={};
    my ($lk,$lv);
    while(($lk,$lv)=each %{$self->{groups}->{name}->{$k}}) {
       $hr->{name}->{$k}->{$lk}=$lv;
    }
  }
  return $hr;
}


=pod

=item $lj->MapGroupToId($group_name)

Used to map a given group name to its identity. On
success returns the identity for the group name. On
failure it returns C<undef> and sets
C<$LJ::Simple::error>.

=cut
sub MapGroupToId($$) {
  my $self=shift;
  my ($grp)=@_;
  $LJ::Simple::error="";
  if (!defined $self->{groups}) {
    $LJ::Simple::error="Unable to map group to id - none defined";
    return undef;
  }
  if (!exists $self->{groups}->{name}->{$grp}) {
    $LJ::Simple::error="No such group";
    return undef;
  }
  return $self->{groups}->{name}->{$grp}->{id};
}


=pod

=item $lj->MapIdToGroup($id)

Used to map a given identity to its group name. On
success returns the group name for the identity. On
failure it returns C<undef> and sets
C<$LJ::Simple::error>.

=cut
sub MapIdToGroup($$) {
  my $self=shift;
  my ($id)=@_;
  $LJ::Simple::error="";
  if (!defined $self->{groups}) {
    $LJ::Simple::error="Unable to map group to id - none defined";
    return undef;
  }
  if (!exists $self->{groups}->{id}->{$id}) {
    $LJ::Simple::error="No such group ident";
    return undef;
  }
  return $self->{groups}->{id}->{$id};
}

=pod


=item $lj->pictures($hash_ref)

Takes a reference to a hash and fills it with information about
the pictures the user has configured for themselves. Either
returns back the hash reference or C<undef> on error. Note that
the user has to have defined picture keywords for this to work.

Note that if the LiveJournal
object was created with either C<pics> set to C<0> or
with C<fast> set to C<1> then this function will always return
an error.

The hash the given reference points to is emptied before it is
used and after a successful call the hash given will contain
the following:

   %hash = (
     "keywords"	=> "URL of picture",
   );

Example code:

  my %pictures=();
  if (!defined $lj->pictures(\%pictures)) {
    die "$0: LJ error - $LJ::Simple::error";
  }
  my ($keywords,$url)=(undef,undef);
  while(($keywords,$url)=each %pictures) {
    print "\"$keywords\"\t=> $url\n";
  }


=cut
sub pictures($$) {
  my $self=shift;
  my ($hr)=@_;
  $LJ::Simple::error="";
  if (!defined $self->{pictures}) {
    $LJ::Simple::error="Unable to return pictures - none defined";
    return undef;
  }
  if (ref($hr) ne "HASH") {
    $LJ::Simple::error="CODE: pictures() not given a hash reference";
    return undef;
  }
  %{$hr}=();
  foreach (values %{$self->{pictures}}) {
    $hr->{$_->{name}}=$_->{url};
  }
  return $hr;
}

=pod

=item $lj->DefaultPicURL()

Returns the URL of the default picture used by the user.

Note that if the LiveJournal
object was created with either C<pics> set to C<0> or
with C<fast> set to C<1> then this function will always return
an error.

Example code:

  print $lj->DefaultPicURL(),"\n";

=cut
sub DefaultPicURL($) {
  my $self=shift;
  $LJ::Simple::error="";
  if (!defined $self->{defaultpicurl}) {
    $LJ::Simple::error="Unable to return default picture URL - none defined";
    return undef;
  }
  return $self->{defaultpicurl};
}

=pod

=item $lj->user()

Returns the username used to log into LiveJournal

Example code:
 
  my $user = $lj->user();

=cut
sub user($) {
  my $self=shift;
  $LJ::Simple::error="";
  return $self->{auth}->{user};
}


=pod

=item $lj->fastserver()

Used to tell if the user which was logged into the LiveJournal system can use the
fast servers or not. Returns C<1> if the user can use the fast servers, C<0>
otherwise.

Example code:

  if ($lj->fastserver()) {
    print STDERR "Using fast server for ",$lj->user(),"\n";
  }

=cut
sub fastserver($) {
  my $self=shift;
  $LJ::Simple::error="";
  return $self->{fastserver};
}

=pod

=back

=head2 Tags

=over 4

=item $lj->GetTags()

Returns a list of the tags the user has defined. The list returned
contains at least one entry, the number of entries in the list.
This value can range from 0 to however
many tags are in the list. In the event of a failure this value is
undefined.

The list of tags is a list of hash references which contain data
about the tag; each hash referenced will contain the following:

  {
    name      => The name of the tag
    uses      => Number of times has the tag been used in total
    security  => Visibility of the tag; this can be "public", "private",
                 "friends" or "group"
    display   => If defined this indicates that the tag is visible to
                 the S2 style system. If set to undef the tag is usable,
                 just not exposed to S2
  }

The list of tags is returned ordered by the tag names.

Example code:

  # Print out the names of the tags
  my ($count,@Tags)=$lj->GetTags();
  (defined $count) || die "$0: Failed to get list of tags - $LJ::Simple::error\n";
  print "Total tags: $count\n";
  map { print "$_->{name}\n"; } (@Tags);

=cut
sub GetTags($) {
  my $self=shift;
  $LJ::Simple::error="";
  my %Event=();
  my %Resp=();
  $self->SendRequest("getusertags",\%Event,\%Resp) || return undef;
  my %Tags=();
  while(my ($name,$val) = each %Resp) {
    ($name=~/tag_([0-9]+)_(.*)/o) || next;
    my ($id,$key)=($1,$2);
    (exists $Tags{$id}) || ($Tags{$id}={});
    $Tags{$id}->{$key}=$val;
  }
  my @Return=();
  foreach my $tag_id (keys %Tags) {
    push(@Return,{});
    my $dest=$Return[$#Return];
    my $src=$Tags{$tag_id};
    map { $dest->{$_} = (exists $src->{$_})?$src->{$_}:undef } (qw( name uses security display ));
  }
  return(scalar(@Return),(sort {lc($a->{name}) cmp lc($b->{name})} @Return));
}


=pod

=back

=head2 Dealing with friends

=over 4

=item $lj->GetFriendOf()

Returns a list of the other LiveJournal users who list the current
user as a friend. The list returned contains at least one entry, the
number of entries in the list. This value can range from 0 to however
many users are in the list. In the event of a failure this value is
undefined.

The list of friends is a list of hash references which contain data
about the users who list the current user as a friend. Each hash
referenced will contain the following:

  {
    user     => The LiveJournal username
    name     => The full name of the user
    fg       => The foreground colour which represents the user
    bg       => The background colour which represents the user
    status   => The status of the user
    type     => The type of the user
  }

Both the C<bg> and C<fg> values are stored in the format of "C<#>I<RR>I<GG>I<BB>"
where the I<RR>, I<GG>, I<BB> values are given as two digit hexadecimal numbers which
range from C<00> to C<ff>.

The C<status> of a user can be one of C<active>, C<deleted>, C<suspended> or C<purged>.

The C<type> of a user can either be C<user> which means that the user is a normal
LiveJournal user or it can be C<community> which means that the user is actually a
community which the current LJ user is a member of.

It should be noted that any of the values in the hash above can be undefined if
that value was not returned from the LiveJournal server.

The returned list is ordered by the LiveJournal login names of the users.

Example code:

  my ($num_friends_of,@FriendOf)=$lj->GetFriendOf();
  (defined $num_friends_of) ||
    die "$0: Failed to get friends of user - $LJ::Simple::error\n";
  print "LJ login\tReal name\tfg\tbg\tStatus\tType\n";
  foreach (@FriendOf) {
    print "$_->{user}\t",
          "$_->{name}\t",
          "$_->{fg}\t",
          "$_->{bg}\t",
          "$_->{status}\t",
          "$_->{type}\n";
  }

=cut
sub GetFriendOf($) {
  my $self=shift;
  $LJ::Simple::error="";
  my %Event=();
  my %Resp=();
  $self->SendRequest("friendof",\%Event,\%Resp) || return undef;
  my %Friends=();
  my ($k,$v);
  while(($k,$v)=each %Resp) {
    ($k=~/^friendof_([0-9]+)_(.*)/) || next;
    my ($id,$type)=($1,$2);
    if (!exists $Friends{$id}) {
      $Friends{$id}={
	user	=>	undef,
	name	=>	undef,
	bg	=>	undef,
	fg	=>	undef,
	status	=>	"active",
	type	=>	"user",
      };
    }
    $Friends{$id}->{$type}=$v;
  }
  my @lst=sort {$a->{user} cmp $b->{user}} (values %Friends);
  return ($#lst+1,@lst);
}


=pod

=item $lj->GetFriends()

Returns a list of the other LiveJournal user who are listed as friends of
the current user. The list returned contains a least one entry, the
number of entries in the list. This value can range from 0 to however
many users are in the list. In the event of a failure this value is
undefined.

The list of friends is a list of hash references which contain data
about the users who list the current user as a friend. Each hash
referenced will contain the following:

  {
    user      => The LiveJournal username
    name      => The full name of the user
    fg        => The foreground colour which represents the user
    bg        => The background colour which represents the user
    dob       => The date of birth for the user
    birthday  => The birthday of the user
    groups    => The list of friends groups this user is in
    groupmask => The actual group mask for this user
    status    => The status of the user
    type      => The type of the user
  }

Both the C<bg> and C<fg> values are stored in the format of "C<#>I<RR>I<GG>I<BB>"
where the I<RR>, I<GG>, I<BB> values are given as two digit hexadecimal numbers which
range from C<00> to C<ff>.

The C<dob> value is stored as a Unix timestamp; that is seconds since epoch. If the
user has no date of birth defined B<or> they have only given their birthday then this
value will be C<undef>.

The C<birthday> value is the date of the user's next birthday given as a Unix timestamp.

The C<groups> value is a reference to a list of the friends group this user is a member
of. It should be noted that to have any items in the list the user must be a
member of a friends group and the C<login()> method must B<not> have been called
with the fast login option.

The C<groupmask> value is the actual group mask for the user. This is used to build
the C<groups> list. It is a 32-bit number where each bit represents membership of a
given friends group. Bits 0 and 31 are reserved; all other bits can be used. The bit
a group corresponds to is taken by bit-shifting 1 by the group id number.

The C<status> of a user can be one of C<active>, C<deleted>, C<suspended> or C<purged>.

The C<type> of a user can either be C<user> which means that the user is a normal
LiveJournal user or it can be C<community> which means that the user is actually a
community which the current LJ user is a member of.

It should be noted that any of the values in the hash above can be undefined if
that value was not returned from the LiveJournal server.

The returned list is ordered by the LiveJournal login names of the users.

Example code:

  use POSIX;
  
  my ($num_friends,@Friends)=$lj->GetFriends();
  (defined $num_friends) ||
    die "$0: Failed to get friends - $LJ::Simple::error\n";
  
  my $f=undef;
  foreach $f (@Friends) {
    foreach (qw(dob birthday)) {
      (defined $f->{$_}) || next;
      $f->{$_}=strftime("%Y/%m/%d",localtime($f->{$_}));
    }
    my ($k,$v)=(undef,undef);
    while(($k,$v)=each %{$f}) {
      (!defined $v) && ($f->{$k}="[undefined]");
    }
    print "$f->{user}\n";
    print "  Name         : $f->{name}\n";
    print "  Colors       : fg->$f->{fg} bg->$f->{bg}\n";
    print "  DOB          : $f->{dob}\n";
    print "  Next birthday: $f->{birthday}\n";
    print "  Status       : $f->{status}\n";
    print "  Type         : $f->{type}\n";
    if ($#{$f->{groups}}>-1) {
      print "  Friend groups:\n";
      print "    + ",join("\n    + ",@{$f->{groups}}),"\n";
    } else {
      print "  Friend groups: [none]\n";
    }
    print "\n";
  }

=cut
sub GetFriends($) {
  my $self=shift;
  $LJ::Simple::error="";
  my %Event=(
    includegroups	=>	1,
    includebdays	=>	1,
  );
  my %Resp=();
  $self->SendRequest("getfriends",\%Event,\%Resp) || return undef;
  my %Friends=();
  my ($k,$v);
  while(($k,$v)=each %Resp) {
    ($k=~/^friend_([0-9]+)_(.*)/) || next;
    my ($id,$type)=($1,$2);
    if (!exists $Friends{$id}) {
      $Friends{$id}={
        user    	=>      undef,
        name    	=>      undef,
        bg      	=>      undef,
        fg      	=>      undef,
	dob		=>	undef,
	birthday	=>	undef,
	groups		=>	[],
	groupmask	=>	undef,
        status  	=>      "active",
        type    	=>      "user",
      };
    }
    if ($type eq "birthday") {
      ($v=~/([0-9]+)-([0-9]{2})-([0-9]{2})/o) || next;
      my @tm=(0,0,0,$3,$2,$1-1900);
      if ($tm[5]>0) {
        $Friends{$id}->{dob}=mktime(@tm);
        if (!defined $Friends{$id}->{dob}) {
          $LJ::Simple::error="Failed to convert time $v into Unix timestamp";
          return undef;
        }
      }
      $tm[5]=(localtime(time()))[5];
      $Friends{$id}->{birthday}=mktime(@tm);
      if (!defined $Friends{$id}->{birthday}) {
        $LJ::Simple::error="Failed to convert time $v into Unix timestamp";
        return undef;
      }
    } else {
      $Friends{$id}->{$type}=$v;
    }
  }
  if (defined $self->{groups}) {
    my $id=undef;
    foreach $id (values %Friends) {
      (defined $id->{groupmask}) || next;
      foreach (values %{$self->{groups}->{name}}) {
        my $bit=1 << $_->{id};
        if (($id->{groupmask} & $bit) == $bit) {
          push(@{$id->{groups}},$_->{name});
        }
      }
    }
  }
  my @lst=sort {$a->{user} cmp $b->{user}} (values %Friends);
  return ($#lst+1,@lst);
}


=pod

=item $lj->CheckFriends(@groups)

This routine is used to poll the LiveJournal server to see if your friends list
has been updated or not. This routine returns a list. The first item in the
list is a value which holds C<1> if there has been an update
to your friends list and C<0> if not. The second item in the list holds the number
of seconds you must wait before calling C<CheckFriends()> again.
In the event of an error C<undef> is returned in the first item of the list.

The routine can be given an optional list of friends group to check instead of
just looking at all of the friends for the user.

Example code:

  while(1) {
    my ($new_friends,$next_update)=$lj->CheckFriends();
    (defined $new_friends) ||
      die "$0: Failed to check friends - $LJ::Simple::error\n";
    ($new_friends) && print "Friends list updated\n";
    sleep($next_update+1);
  }

=cut
sub CheckFriends($@) {
  my $self=shift;
  my (@groups)=@_;
  my %Event=();
  my %Resp=();
  if ($#groups>-1) {
    if (!defined $self->{groups}) {
      $LJ::Simple::error="Groups not requested at login";
      return 0;
    }
    my $g;
    my $mask=0;
    foreach $g (@groups) {
      if (!exists $self->{groups}->{name}->{$g}) {
        $LJ::Simple::error="Group \"$g\" does not exist";
        return 0;
      }
      $mask=$mask | (1 << $self->{groups}->{name}->{$g}->{id});
    }
    $Event{mask}=$mask;
  }
  if (exists $self->{checkfriends}) {
    $Event{lastupdate}=$self->{checkfriends}->{lastupdate};
    my $currtime=time();
    if ($currtime<$self->{checkfriends}->{interval}) {
      $LJ::Simple::error="Insufficent time left between CheckFriends() call";
      return undef;
    }
  } else {
    $self->{checkfriends}={};
  }
  $self->SendRequest("checkfriends",\%Event,\%Resp) || return undef;
  $self->{checkfriends}->{lastupdate}=$Resp{lastupdate};
  $self->{checkfriends}->{interval}=time() + $Resp{interval};
  return ($Resp{new},$Resp{interval});
}


=pod

=item $lj->GetDayCounts($hash_ref,$journal)

This routine is given a reference to hash which it fills with information
on the journal entries posted to the LiveJournal we are currently associated
with. On success the reference to the hash will be returned. On error
C<undef> is returned.

There is an optional argument - C<$journal> - which can be used to gather this
data for a shared journal the user has access to. If not required then this
value should be C<undef> or an empty string.

The key to the hash is a date, given as seconds since epoch (I<i.e.> C<time_t>)
and the value is the number of entries made on that day. Only dates which have
journal entries made against them will have values in the hash; thus it can be
assumed that if a date is B<not> in the hash then no journal entries were made
on that day.

The hash will be emptied before use.

Example code:

  use POSIX;
  (defined $lj->GetDayCounts(\%gdc_hr,undef))
    || die "$0: Failed to get day counts - $LJ::Simple::error\n";
  
  foreach (sort {$a<=>$b} keys %gdc_hr) {
    printf("%s %03d\n",strftime("%Y/%m/%d",localtime($_)),$gdc_hr{$_});
  }

=cut
sub GetDayCounts($$$) {
  my $self=shift;
  my ($hr,$journal)=@_;
  $LJ::Simple::error="";
  if (ref($hr) ne "HASH") {
    my $r=ref($hr);
    $LJ::Simple::error="CODE: GetDayCounts() given \"$r\", not a hash reference";
    return undef;
  }
  %{$hr}=();
  my %Event=();
  my %Resp=();
  if ((defined $journal) && ($journal ne "")) {
    $Event{usejournal}=$journal;
  }
  $self->SendRequest("getdaycounts",\%Event,\%Resp) || return undef;
  my ($k,$v);
  while(($k,$v)=each %Resp) {
    ($k=~/([0-9]+)-([0-9]+)-([0-9]+)/o) || next;
    ($v==0) && next;
    my $timet=mktime(0,0,0,$3,$2-1,$1-1900);
    if (!defined $timet) {
      $LJ::Simple::error="Failed to convert date $k into Unix timestamp";
      return undef;
    }
    if (exists $hr->{$timet}) {
      $hr->{$timet}=$hr->{$timet}+$v;
    } else {
      $hr->{$timet}=$v;
    }
  }
  return $hr;
}


=pod

=item $lj->GetFriendGroups($hash_ref)

This routine is given a reference to a hash which it fills with information
on the friends groups the user has defined. On success the reference to the
hash will be returned. On error C<undef> is returned.

The hash key is the id number of the friends group as it is possible to
have multiple friends groups with the same name. Each hash value is a hash
reference which points to the following hash:

  {
    id     => Id of the group; used to create permission masks
    name   => Name of the group
    sort   => Sort order number from 0 to 255
    public => Public group ? 1 for yes, 0 for no
  }

The hash given will be emptied before use.

Example code:

  my %fg=();
  (defined $lj->GetFriendGroups(\%fg)) || 
    die "$0: Failed to get groups - $LJ::Simple::error\n";
  
  my $format="| %-4s | %-2s | %-6s | %-40s |\n";
  my $line=sprintf($format,"","","","");
  $line=~s/\|/+/go;
  $line=~s/ /-/go;
  print $line;
  printf($format,"Sort","Id","Public","Group");
  print $line;
  
  foreach (sort {$fg{$a}->{sort}<=>$fg{$b}->{sort}} keys %fg) {
    my $hr=$fg{$_};
    my $pub="No";
    $hr->{public} && ($pub="Yes");
    printf($format,$hr->{sort},$hr->{id},$pub,$hr->{name});
  }
  
  print $line;

In case you're wondering, the above code outputs something similar to
the following:

  +------+----+--------+------------------------------------------+
  | Sort | Id | Public | Group                                    |
  +------+----+--------+------------------------------------------+
  | 5    | 1  | Yes    | Good Friends                             |
  | 10   | 2  | No     | Communities                              |
  +------+----+--------+------------------------------------------+

=cut
sub GetFriendGroups($$) {
  my $self=shift;
  my ($hr)=@_;
   $LJ::Simple::error="";
  if (ref($hr) ne "HASH") {
    my $r=ref($hr);
    $LJ::Simple::error="CODE: GetFriendGroups() given \"$r\", not a hash reference";
    return undef;
  }
  %{$hr}=();
  my %Event=();
  my %Resp=();
  $self->SendRequest("getfriendgroups",\%Event,\%Resp) || return undef;
  my ($k,$v);
  while(($k,$v)=each %Resp) {
    $k=~/^frgrp_([0-9]+)_(.*)$/o || next;
    my ($id,$name)=($1,$2);
    if (!exists $hr->{$id}) {
      $hr->{$id}={
	id	=> $id,
	public	=> 0,
      };
    }
    ($name eq "sortorder") && ($name="sort");
    $hr->{$id}->{$name}=$v;
  }
  return $hr;
}

=pod

=back

=head2 The creation and editing of entries

=over 4

=item $lj->NewEntry($event)

Prepares for a new journal entry to be sent into the LiveJournal system.
Takes a reference to a hash which will be emptied and prepared for use
by the other routines used to prepare a journal entry for posting.

On success returns C<1>, on failure returns C<0>

Example code:

  my %Entry=();
  $lj->NewEntry(\%Entry) 
    || die "$0: Failed to prepare new post - $LJ::Simple::error\n";

=cut
sub NewEntry($$) {
  my $self=shift;
  my ($event)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  ## Build the event hash - put defaults in
  my $ltime=time();
  my @ltime=localtime($ltime);
  %{$event}=(
	__new_entry	=>	1,
	event		=>	undef,
	lineenddings	=>	"unix",
	subject		=>	undef,
	year		=>	$ltime[5]+1900,
	mon		=>	$ltime[4]+1,
	day		=>	$ltime[3],
	hour		=>	$ltime[2],
	min		=>	$ltime[1],
	__timet		=>	$ltime,
  );
  return 1;
}


=pod 

=item $lj->SetDate($event,$time_t)

Sets the date for the event being built from the given C<time_t> (i.e. seconds
since epoch) value. Bare in mind that you may need to call
C<$lj-E<gt>Setprop_backdate(\%Event,1)> to backdate the journal entry if the journal being
posted to has events more recent than the date being set here. Returns C<1> on
success, C<0> on failure.

If the value given for C<time_t> is C<undef> then the current time is used.
If the value given for C<time_t> is negative then it is taken to be relative
to the current time, i.e. a value of C<-3600> is an hour earlier than the
current time.

Note that C<localtime()> is called to convert the C<time_t> value into
the year, month, day, hours and minute values required by LiveJournal.
Thus the time given to LiveJournal will be the local time as shown on
the machine the code is running on.

Example code:

  ## Set date to current time
  $lj->SetDate(\%Event,undef)
    || die "$0: Failed to set date of entry - $LJ::Simple::error\n";

  ## Set date to Wed Aug 14 11:56:42 2002 GMT
  $lj->SetDate(\%Event,1029326202)
    || die "$0: Failed to set date of entry - $LJ::Simple::error\n";

  ## Set date to an hour ago
  $lj->SetDate(\%Event,-3600)
    || die "$0: Failed to set date of entry - $LJ::Simple::error\n";

=cut
sub SetDate($$$) {
  my $self=shift;
  my ($event,$timet)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  (defined $timet) || ($timet=time());
  if ($timet<0) {
    $timet=time() + $timet;
  }
  my @ltime=localtime($timet);
  $event->{__timet}=$timet;
  $event->{year}=$ltime[5]+1900;
  $event->{mon}=$ltime[4]+1;
  $event->{day}=$ltime[3];
  $event->{hour}=$ltime[2];
  $event->{min}=$ltime[1];
  return 1;
}


=pod

=item $lj->SetMood($event,$mood)

Given a mood this routine sets the mood for the journal entry. Unlike the
more direct C<$lj-E<gt>Setprop_current_mood()> and C<$lj-E<gt>Setprop_current_mood_id(\%Event,)>
routines, this routine will attempt to first attempt to find the mood given
to it in the mood list returned by the LiveJournal server. If it is unable to
find a suitable mood then it uses the text given.

Note that if the LiveJournal
object was created with either C<moods> set to C<0> or
with C<fast> set to C<1> then this function will not attempt to find the
mood name given in C<$mood> in the mood list.

Returns C<1> on success, C<0> otherwise.

Example code:

  $lj->SetMood(\%Event,"happy")
    || die "$0: Failed to set mood - $LJ::Simple::error\n";

=cut
sub SetMood($$$) {
  my $self=shift;
  my ($event,$mood) = @_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  if (!defined $mood) {
    $LJ::Simple::error="CODE: given undef value for a mood";
    return 0;
  }
  ## Simple opt - none of the mood names have a space in them
  if (($mood!~/\s/)&&(defined $self->{mood_map})) { 
    my $lc_mood=lc($mood);
    if (exists $self->{mood_map}->{$lc_mood}) {
      return $self->Setprop_current_mood_id($event,$self->{mood_map}->{$lc_mood})
    }
  }
  return $self->Setprop_current_mood($event,$mood);
}



=pod

=item $lj->UseJournal($event,$journal)

The journal entry will be posted into the shared journal given
as an argument rather than the default journal for the user.

Returns C<1> on success, C<0> otherwise.

Example code:

  $lj->UseJournal(\%Event,"some_community")
    || die "$0: Failed to - $LJ::Simple::error\n";

=cut
sub UseJournal($$$) {
  my $self=shift;
  my ($event,$journal) = @_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  if (!defined $journal) {
    $LJ::Simple::error="CODE: Given undefined value for journal";
    return 0;
  }
  if ((defined $self->{access})&&(!exists $self->{access}->{$journal})) { 
    $LJ::Simple::error="user unable to post to journal \"$journal\"";
    return 0;
  }
  $event->{usejournal}=$journal;
  return 1;
}


=pod

=item $lj->SetSubject($event,$subject)

Sets the subject for the journal entry. The subject has the following
limitations:

  o Limited to a length of 255 characters
  o No newlines are allowed

Returns C<1> on success, C<0> otherwise.

Example code:

  $lj->SetSubject(\%Event,"Some subject")
    || die "$0: Failed to set subject - $LJ::Simple::error\n";

=cut
sub SetSubject($$$) {
  my $self=shift;
  my ($event,$subject) = @_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  (defined $subject) || ($subject="");
  if (length($subject)>255) {
    my $len=length($subject);
    $LJ::Simple::error="Subject length limited to 255 characters [given $len]";
    return 0;
  }
  if ($subject=~/[\r\n]/) {
    $LJ::Simple::error="New lines not allowed in subject";
    return 0;
  }
  $event->{subject}=$subject;
  return 1;
}


=pod

=item $lj->SetEntry($event,@entry)

Sets the entry for the journal; takes a list of strings. It should be noted
that this list will be C<join()>ed together with a newline between each
list entry.

If the list is null or C<undef> then any existing entry is removed.

Returns C<1> on success, C<0> otherwise.

Example code:

  # Single line entry
  $lj->SetEntry(\%Event,"Just a simple entry")
    || die "$0: Failed to set entry - $LJ::Simple::error\n";
  
  # Three lines of text
  my @stuff=(
       "Line 1",
       "Line 2",
       "Line 3",
  );
  $lj->SetEntry(\%Event,@stuff)
    || die "$0: Failed to set entry - $LJ::Simple::error\n";

  # Clear the entry
  $lj->SetEntry(\%Event,undef)
    || die "$0: Failed to set entry - $LJ::Simple::error\n";
  $lj->SetEntry(\%Event)
    || die "$0: Failed to set entry - $LJ::Simple::error\n";

=cut
sub SetEntry($$@) {
  my $self=shift;
  my ($event,@entry) = @_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  if ((!defined $entry[0]) || ($#entry == -1)) {
    $event->{event}=undef;
  } else {
    $event->{event}=join("\n",@entry);
  }
  return 1;
}


=pod

=item $lj->AddToEntry($event,@entry)

Adds a string to the existing journal entry being worked on. The new data
will be appended to the existing entry with a newline separating them.
It should be noted that as with C<$lj-E<gt>SetEntry()> the list given to
this routine will be C<join()>ed together with a newline between each 
list entry.

If C<$lj-E<gt>SetEntry()> has not been called then C<$lj-E<gt>AddToEntry()> acts
in the same way as C<$lj-E<gt>SetEntry()>.

If C<$lj-E<gt>SetEntry()> has already been called then calling C<$lj-E<gt>AddToEntry()>
with a null list or a list which starts with C<undef> is a NOP.

Returns C<1> on success, C<0> otherwise.

Example code:

  # Single line entry
  $lj->AddToEntry(\%Event,"Some more text")
    || die "$0: Failed to set entry - $LJ::Simple::error\n";
  
  # Three lines of text
  my @stuff=(
       "Line 5",
       "Line 6",
       "Line 7",
  );
  $lj->AddToEntry(\%Event,@stuff)
    || die "$0: Failed to set entry - $LJ::Simple::error\n";

=cut
sub AddToEntry($$@) {
  my $self=shift;
  my ($event,@entry) = @_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  if (!defined $event->{event}) {
    if ((!defined $entry[0]) || ($#entry == -1)) {
      $event->{event}=undef;
    } else {
      $event->{event}=join("\n",@entry);
    }
  } else {
    if ((!defined $entry[0]) || ($#entry == -1)) {
      return 1;
    }
    $event->{event}=join("\n",$event->{event},@entry);
  }
  return 1;
}


=pod

=back

=head2 Setting of journal entry security levels

=over 4

=item $lj->SetProtect($event,$type,@args)

A wrapper function which calls the underlying C<SetProtect*()> routines
for the caller. This takes two or more arguments; the first argument is
the hash reference of the current event. The second argument is the
type of security we are setting. Subsequent arguments are related to
the security type. Available types and their arguments are:

  +---------+------------------+------------------------------------+
  |  Type   | Additional args  | Security                           |
  +---------+------------------+------------------------------------+
  | public  |      None        | Public - the default               |
  | friends |      None        | Friends only                       |
  | groups  | A list of groups | Restricted to groups of friends    |
  | private |      None        | Private - only the user can access |
  +---------+------------------+------------------------------------+

On success this routine returns C<1>; otherwise it returns C<0> and
sets C<$LJ::Simple::error> to the reason why.

Example code:

  ## Make entry public (the default)
  $lj->SetProtect(\%Event,"public")
    || die "$0: Failed to make entry public - $LJ::Simple::error\n";
  
  ## Make entry friends only
  $lj->SetProtect(\%Event,"friends")
    || die "$0: Failed to make entry friends only - $LJ::Simple::error\n";
  
  ## Make entry only readable by friends in the groups "close" and "others"
  $lj->SetProtect(\%Event,"groups","close","others")
    || die "$0: Failed to make entry public - $LJ::Simple::error\n";
  
  ## Make entry private so only the journal owner can view it
  $lj->SetProtect(\%Event,"private")
    || die "$0: Failed to make entry private - $LJ::Simple::error\n";

=cut
sub SetProtect($$$@) {
  my $self=shift;
  my ($event,$type,@args)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  if (!defined $type) {
    $LJ::Simple::error="CODE: given undefined value for type";
    return 0;
  }
  if ($type eq "public") {
    return $self->SetProtectPublic($event);
  } elsif ($type eq "friends") {
    return $self->SetProtectFriends($event);
  } elsif ($type eq "groups") {
    return $self->SetProtectGroups($event,@args);
  } elsif ($type eq "private") {
    return $self->SetProtectPrivate($event);
  } else {
    $LJ::Simple::error="CODE: type \"$type\" not recognised by SetProtect()";
    return 0;
  }
};

=pod

=item $lj->SetProtectPublic($event)

Sets the current post so that anyone can read the journal entry. Note that this
is the default for a new post created by C<LJ::Simple> - this method is most
useful when working with an existing post. Returns C<1> on success, C<0>
otherwise.

Example code:

  $lj->SetProtectPublic(\%Event)
    || die "$0: Failed to make entry public - $LJ::Simple::error\n";

=cut
sub SetProtectPublic($$) {
  my $self=shift;
  my ($event)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  $event->{security}="public";
  (exists $event->{allowmask}) && delete $event->{allowmask};
  return 1;
}


=pod


=pod

=item $lj->SetProtectFriends($event)

Sets the current post so that only friends can read the journal entry. Returns
C<1> on success, C<0> otherwise.

Example code:

  $lj->SetProtectFriends(\%Event)
    || die "$0: Failed to protect via friends - $LJ::Simple::error\n";

=cut
sub SetProtectFriends($$) {
  my $self=shift;
  my ($event)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  $event->{security}="usemask";
  $event->{allowmask}=1;
  return 1;
}


=pod

=item $lj->SetProtectGroups($event,$group1, $group2, ... $groupN)

Takes a list of group names and sets the current entry so that only those
groups can read the journal entry. Returns
C<1> on success, C<0> otherwise.

Example code:

  $lj->SetProtectGroups(\%Event,"foo","bar")
    || die "$0: Failed to protect via group - $LJ::Simple::error\n";

=cut
sub SetProtectGroups($$@) {
  my $self=shift;
  my ($event,@grps) = @_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  if (!defined $self->{groups}) {
    $LJ::Simple::error="Groups not requested at login";
    return 0;
  }
  if ($#grps==-1) {
    $LJ::Simple::error="No group names given";
    return 0;
  }
  $event->{security}="usemask";
  my $g;
  my $mask=0;
  foreach $g (@grps) {
    if (!defined $g) {
      $LJ::Simple::error="Group list contains undefined value";
      return 0;
    }
    if (!exists $self->{groups}->{name}->{$g}) {
      $LJ::Simple::error="Group \"$g\" does not exist";
      return 0;
    }
    $mask=$mask | (1 << $self->{groups}->{name}->{$g}->{id});
  }
  $event->{allowmask}=$mask;
  return 1;
}

=pod

=item $lj->SetProtectPrivate($event)

Sets the current post so that the owner of the journal only can read the
journal entry. Returns C<1> on success, C<0> otherwise.

Example code:

  $lj->SetProtectPrivate(\%Event)
    || die "$0: Failed to protect via private - $LJ::Simple::error\n";

=cut
sub SetProtectPrivate($$) {
  my $self=shift;
  my ($event) = @_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  $event->{security}="private";
  (exists $event->{allowmask}) &&
    delete $event->{allowmask};
  return 1;
}


##
## Helper function used to set meta data
##
sub Setprop_general($$$$$$) {
  my ($self,$event,$prop,$caller,$type,$data)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  if (!defined $prop) {
    $LJ::Simple::error="CODE: given undefined value for property";
    return 0;
  }
  if (!defined $caller) {
    $LJ::Simple::error="CODE: given undefined value for caller setting $prop";
    return 0;
  }
  if (!defined $type) {
    $LJ::Simple::error="CODE: given undefined value for type by $caller setting $prop";
    return 0;
  }
  if (!defined $data) {
    $LJ::Simple::error="CODE: given undefined value for data by $caller setting $prop";
    return 0;
  }
  my $nd=undef;
  if ($type eq "bool") {
    if (($data == 1)||($data == 0)) {
      $nd=$data;
    } else {
      $LJ::Simple::error="INTERNAL: Invalid value [$data] for type bool [from $caller]";
      return 0;
    }
  } elsif ($type eq "char") {
    $nd=$data;
  } elsif ($type eq "num") {
    if ($data!~/^[0-9]+$/o) {
      $LJ::Simple::error="INTERNAL: Invalid value [$data] for type num [from $caller]";
      return 0;
    }
    $nd=$data;
  } else {
    $LJ::Simple::error="INTERNAL: Unknown type \"$type\" [from $caller]";
    return 0;
  }
  if (!defined $nd) {
    $LJ::Simple::error="INTERNAL: Setprop_general did not set \$nd [from $caller]";
    return 0;
  }
  $event->{"prop_$prop"}=$nd;
  return 1;
}

=pod

=back

=head2 Setting journal entry properties

=over 4

=item $lj->Setprop_taglist($event,@tags)

Set the tags for the entry; C<@tags> is a list of the tags to give the 
entry.

Example code:

  $lj->Setprop_taglist(\%Event,qw( gabe pets whatever )) ||
    die "$0: Failed to set back date property - $LJ::Simple::error\n";

=cut
sub Setprop_taglist($$@) {
  my ($self,$event,@tags)=@_;
  $LJ::Simple::error="";
  return $self->Setprop_general($event,"taglist","Setprop_taglist","char",join(", ",@tags));
}

=pod

=item $lj->Setprop_backdate($event,$onoff)

Used to indicate if the journal entry being written should be back dated or not. Back dated
entries do not appear on the friends view of your journal entries. The C<$onoff>
value takes either C<1> for switching the property on or C<0> for switching the
property off. Returns C<1> on success, C<0> on failure.

You will need to set this value if the journal entry you are sending has a
date earlier than other entries in your journal.

Example code:

  $lj->Setprop_backdate(\%Event,1) ||
    die "$0: Failed to set back date property - $LJ::Simple::error\n";

=cut
sub Setprop_backdate($$$) {
  my ($self,$event,$onoff)=@_;
  $LJ::Simple::error="";
  return $self->Setprop_general($event,"opt_backdated","Setprop_backdate","bool",$onoff);
}


=pod

=item $lj->Setprop_current_mood($event,$mood)

Used to set the current mood for the journal being written. This takes a string which
describes the mood.

It is better to use C<$lj-E<gt>SetMood()> as that will automatically use a
mood known to the LiveJournal server if it can.

Returns C<1> on success, C<0> on failure.

Example code:

  $lj->Setprop_current_mood(\%Event,"Happy, but tired") ||
    die "$0: Failed to set current_mood property - $LJ::Simple::error\n";

=cut
sub Setprop_current_mood($$$) {
  my ($self,$event,$mood)=@_;
  $LJ::Simple::error="";
  if ($mood=~/[\r\n]/) {
    $LJ::Simple::error="Mood may not contain a new line";
    return 0;
  }
  return $self->Setprop_general($event,"current_mood","Setprop_current_mood","char",$mood);
}

=pod

=item $lj->Setprop_current_mood_id($event,$id)

Used to set the current mood_id for the journal being written. This takes a number which
refers to a mood_id the LiveJournal server knows about.

Note that if the LiveJournal
object was created with either C<moods> set to C<0> or
with C<fast> set to C<1> then this function will not attempt to validate
the C<mood_id> given to it.

It is better to use C<$lj-E<gt>SetMood()> as that will automatically use a
mood known to the LiveJournal server if it can.

Returns C<1> on success, C<0> on failure.

Example code:

  $lj->Setprop_current_mood_id(\%Event,15) ||
    die "$0: Failed to set current_mood_id property - $LJ::Simple::error\n";

=cut
sub Setprop_current_mood_id($$$) {
  my ($self,$event,$data)=@_;
  $LJ::Simple::error="";
  if (defined $self->{moods}) {
    if (!exists $self->{moods}->{$data}) {
      $LJ::Simple::error="The mood_id $data is not known by the LiveJournal server";
      return 0;
    }
  }
  return $self->Setprop_general($event,"current_moodid","Setprop_current_mood_id","num",$data);
}


=pod

=item $lj->Setprop_current_music($event,$music)

Used to set the current music for the journal entry being written. This takes
a string.

Returns C<1> on success, C<0> on failure.

Example code:

  $lj->Setprop_current_music(\%Event,"Collected euphoric dance") ||
    die "$0: Failed to set current_music property - $LJ::Simple::error\n";

=cut
sub Setprop_current_music($$$) {
  my ($self,$event,$data)=@_;
  $LJ::Simple::error="";
  return $self->Setprop_general($event,"current_music","Setprop_current_music","char",$data);
}

=pod

=item $lj->Setprop_preformatted($event,$onoff)

Used to set if the text for the journal entry being written is preformatted in HTML
or not. This takes a boolean value of C<1> for true and C<0> for false.

Returns C<1> on success, C<0> on failure.

Example code:

  $lj->Setprop_preformatted(\%Event,1) ||
    die "$0: Failed to set property - $LJ::Simple::error\n";

=cut
sub Setprop_preformatted($$$) {
  my ($self,$event,$data)=@_;
  $LJ::Simple::error="";
  return $self->Setprop_general($event,"opt_preformatted","Setprop_preformatted","bool",$data);
}


=pod

=item $lj->Setprop_nocomments($event,$onoff)

Used to set if the journal entry being written can be commented on or not. This takes
a boolean value of C<1> for true and C<0> for false. Thus if you use a value
of C<1> (true) then comments will not be allowed.

Returns C<1> on success, C<0> on failure.

Example code:

  $lj->Setprop_nocomments(\%Event,1) ||
    die "$0: Failed to set property - $LJ::Simple::error\n";

=cut
sub Setprop_nocomments($$$) {
  my ($self,$event,$data)=@_;
  $LJ::Simple::error="";
  return $self->Setprop_general($event,"opt_nocomments","Setprop_nocomments","bool",$data);
}


=pod

=item $lj->Setprop_picture_keyword($event,$keyword)

Used to set the picture keyword for the journal entry being written. This takes
a string. We check to make sure that the picture keyword exists.

Note that if the LiveJournal
object was created with either C<pics> set to C<0> or
with C<fast> set to C<1> then this function will B<not> validate
the picture keyword before setting it.

Returns C<1> on success, C<0> on failure.

Example code:

  $lj->Setprop_picture_keyword(\%Event,"Some photo") ||
    die "$0: Failed to set property - $LJ::Simple::error\n";

=cut
sub Setprop_picture_keyword($$$) {
  my ($self,$event,$data)=@_;
  $LJ::Simple::error="";
  if (defined $self->{pictures}) {
    my $match=0;
    foreach (values %{$self->{pictures}}) {
      if ($_->{name} eq $data) {
        $match=1;
        last;
      }
    }
    if (!$match) {
      $LJ::Simple::error="Picture keyword not associated with journal";
      return 0;
    }
  }
  return $self->Setprop_general($event,"picture_keyword","Setprop_picture_keyword","char",$data);
}


=pod

=item $lj->Setprop_noemail($event,$onoff)

Used to say that comments on the journal entry being written should not be emailed.
This takes boolean value of C<1> for true and C<0> for false.

Returns C<1> on success, C<0> on failure.

Example code:

  $lj->Setprop_noemail(\%Event,1) ||
    die "$0: Failed to set property - $LJ::Simple::error\n";

=cut
sub Setprop_noemail($$$) {
  my ($self,$event,$data)=@_;
  $LJ::Simple::error="";
  return $self->Setprop_general($event,"opt_noemail","Setprop_noemail","bool",$data);
}


=pod

=item $lj->Setprop_unknown8bit($event,$onoff)

Used say that there is 8-bit data which is not in UTF-8 in the journal entry
being written. This takes a boolean value of C<1> for true and C<0> for false.

Returns C<1> on success, C<0> on failure.

Example code:

  $lj->Setprop_unknown8bit(\%Event,1) ||
    die "$0: Failed to set property - $LJ::Simple::error\n";

=cut
sub Setprop_unknown8bit($$$) {
  my ($self,$event,$data)=@_;
  $LJ::Simple::error="";
  return $self->Setprop_general($event,"unknown8bit","Setprop_unknown8bit","bool",$data);
}


=pod

=back

=head2 Posting, editing and deleting journal entries

=over 4

=item $lj->PostEntry($event)

Submit a journal entry into the LiveJournal system. This requires you to have
set up the journal entry with C<$lj-E<gt>NewEntry()> and to have at least called
C<$lj-E<gt>SetEntry()>.

On success a list containing the following is returned:

  o The item_id as returned by the LiveJournal server
  o The anum as returned by the LiveJournal server
  o The item_id of the posted entry as used in HTML - that is the
    value of C<($item_id * 256) + $anum)>

On failure C<undef> is returned.

  # Build the new entry
  my %Event;
  $lj->NewEntry(\%Event) ||
    die "$0: Failed to create new journal entry - $LJ::Simple::error\n";

  # Set the journal entry
  $lj->SetEntry(\%Event,"foo") ||
    die "$0: Failed set journal entry - $LJ::Simple::error\n";

  # And post it
  my ($item_id,$anum,$html_id)=$lj->PostEntry(\%Event);
  defined $item_id ||
    die "$0: Failed to submit new journal entry - $LJ::Simple::error\n";

=cut
##
## PostEntry - actually submit a journal entry.
##
sub PostEntry($$) {
  my $self=shift;
  my ($event)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return undef;
  }
  if (!exists $event->{"__new_entry"}) {
    $LJ::Simple::error="CODE: NewEntry not called";
    return undef;
  }

  ## Blat any key in $event which starts with a double underscore
  map {/^__/ && delete $event->{$_}} (keys %{$event});

  if (!defined $event->{event}) {
    $LJ::Simple::error="CODE: No journal entry set - call SetEntry() or AddToEntry() first";
    return undef;
  }

  ## Blat any entry in $self->{event} with an undef value
  map {defined $event->{$_} || delete $event->{$_}} (keys %{$event});

  ## Finally send the actual request
  my %Resp=();
  $self->SendRequest("postevent",$event,\%Resp) || return undef;

  if (!exists $Resp{itemid}) {
    $LJ::Simple::error="LJ server did not return itemid";
    return undef;
  }
  if (!exists $Resp{anum}) {
    $LJ::Simple::error="LJ server did not return anum";
    return undef;
  }

  return ($Resp{itemid},$Resp{anum},($Resp{itemid} * 256) + $Resp{anum});
}

=pod

=item $lj->EditEntry($event)

Edit an entry from the LiveJournal system which has the givem C<item_id>.
The entry should have been fetched from LiveJournal using the
C<$lj-E<gt>GetEntries()> function and then adjusted using the various
C<$lj-E<gt>Set...()> functions.

It should be noted that this function can be used to delete a journal entry
by setting the entry to a blank string, I<i.e.> by using
C<$lj-E<gt>SetEntry(\%Event,undef)>

Returns C<1> on success, C<0> on failure.

Example:

  # Fetch the most recent event
  my %Events = ();
  (defined $lj->GetEntries(\%Events,undef,"one",-1)) ||
    die "$0: Failed to get entries - $LJ::Simple::error\n";
  
  # Mark it as private
  foreach (values %Entries) {
    $lj->SetProtectPrivate($_);
    $lj->EditEntry($_) ||
      die "$0: Failed to edit entry - $LJ::Simple::error\n";
  }
  
  # Alternatively we could just delete it...
  my $event=(values %Entries)[0];
  $lj->SetEntry($event,undef);
  $lj->EditEntry($event) ||
    die "$0: Failed to edit entry - $LJ::Simple::error\n";

=cut
sub EditEntry($$) {
  my $self=shift;
  my ($event)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return 0;
  }
  if (!exists $event->{"__itemid"}) {
    $LJ::Simple::error="CODE: Not an existing entry; use GetEntry()";
    return 0;
  }
  $event->{itemid}=$event->{"__itemid"};

  ## Blat any key in $event which starts with a double underscore
  map {/^__/ && delete $event->{$_}} (keys %{$event});

  if (!defined $event->{event}) {
    $LJ::Simple::error="CODE: No journal entry set";
    return 0;
  }

  ## Blat any entry in $event with an undef value
  map {defined $event->{$_} || delete $event->{$_}} (keys %{$event});

  ## Make the request
  return $self->SendRequest("editevent",$event,undef);
}

=pod

=item $lj->DeleteEntry($item_id)

Delete an entry from the LiveJournal system which has the given C<item_id>.
On success C<1> is returned; on failure C<0> is returned.

Example:

  $lj->DeleteEntry($some_item_id) ||
    die "$0: Failed to delete journal entry - $LJ::Simple::error\n";

=cut
sub DeleteEntry($$) {
  my $self=shift;
  my ($item_id) = @_;
  $LJ::Simple::error="";
  if (!defined $item_id) {
    $LJ::Simple::error="CODE: DeleteEntry() given undefined item_id";
    return 0;
  }
  if ($item_id!~/^[0-9]+$/) {
    $LJ::Simple::error="CODE: DeleteEntry() given invalid item_id";
    return 0;
  }
  my %Event=(
	itemid	=>	$item_id,
	event	=>	"",
  );
  return $self->SendRequest("editevent",\%Event,undef);
}

=pod

=back

=head2 Retriving journal entries

=over 4

=item $lj->SyncItems($timestamp)

This routine returns a list of all of the items (journal entries, to-do items,
comments) which have been created or updated on LiveJournal. There is an optional
timestamp value for specifying the time you last synchronised with the server.
This timestamp value can either be a Unix-style C<time_t> value or a previously
returned timestamp from this routine. If not used specify the undefined value
C<undef>.

When specifying the time you must take into account the fact that the modification
or creation times of the entries in the LiveJournal database are stored as the
time local to the computer running the database rather than GMT. Due to this
it is safest to use the time from the latest item downloaded from the LiveJournal
from a previous C<SyncItems()> call.

On success this routine will return a list which contains first the number of
valid items in the list and then a list of hashes which contain the details
of the items found. This routine can return an empty list which signifies that
no new items could be found. On failure C<undef> is returned.

The format of the returned list is as follows. The list of hashes is ordered
by the timestamps of the entries, oldest to newest.

  @list = (
    number of items returned,
    {
      item_id   => Item_id of the entry changed
      type      => Type of entry
      action    => What happened to the entry
      time_t    => Time of change in Unix time (see note below)
      timestamp => Timestamp from server
    },
  );

The C<type> of entry can be one of the following letters:

  L: Journal entries
  C: Comments
  T: To-do items

It should be noted that currently the LiveJournal system will only ever
return C<L> types due to the C<C> and C<T> types not having been implemented
in the LiveJournal code yet.

The C<action> of the entry can be either C<create> for a new entry,
C<update> for an entry which has been modified or C<del> for a deleted entry.

The C<time_t> value is probably going to be wrong; as far as the author of
this code can tell, you can not get the timezone of the server which is
serving out the request. This means that converting the timestamps
returned by the server from their format of C<YYYY-MM-DD hh:mm:ss> into
a Unix C<time_t> value is inaccurate at best since C<time_t> is defined
as the number of seconds since 00:00 1st January 1970 B<GMT>. Functions
like C<mktime()> which can be used to create C<time_t> values have to
assume that the data they are being given is valid for the timezone the
machine it is running on is actually in. Given the nature of the net
this is rarely the case. I<sigh> I wish that the LJ developers had stored
timestamps in pure C<time_t> in the database... and if they have done they
should provide a way for developers to get access to this as its B<much>
more useful IMHO.

Given the above you're probably wondering why I included the C<time_t>
value. Well, whilst the value isn't much use when it really comes down
to it, it B<is> useful when it comes to sorting the list of entries as
all of the entries from the same server will be inaccurate to the same
amount.

The C<timestamp> from server takes the format of C<YYYY-MM-DD hh:mm:ss>

It should be noted that this routine can take a long time to return
if there are large numbers of entries to be returned. This is especially
true if you give C<undef> as the timestamp.

Example code:

  # All entries in the last day or so; this is fudged due to timezone
  # differences (WTF didn't they store stuff in GMT ?)
  my ($num_of_items,@lst)=$lj->SyncItems(time() - (86400 * 2));
  
  (defined $num_of_items) ||
    die "$0: Failed to sync - $LJ::Simple::error\n";

  my $hr=undef;
  print "Number of items: $num_of_items\n";
  print "Item_id\tType\tAction\tTime_t\t\tTimestamp\n";
  foreach $hr (@lst) {
    print "$hr->{item_id}\t" .
          "$hr->{type}\t" .
          "$hr->{action}\t" .
          "$hr->{time_t}\t" .
          "$hr->{timestamp}\n";
  }

There is also an example of how to work with all of the entries of a LiveJournal
shown in the C<examples/friends-only> script which accompanies the C<LJ::Simple>
distribution. This example script looks at a LiveJournal and makes sure that every
journal entry is at the very least marked as being friends-only.

=cut
sub SyncItems($$) {
  my $self=shift;
  my ($timet)=@_;
  $LJ::Simple::error="";
  if (!defined $timet) {
    $LJ::Simple::error="CODE: Invalid timestamp - undefined value not allowed";
    return undef;
  }
  if ($LJ::Simple::debug) {
    my $ts=undef;
    if (defined $timet) {
      $ts="\"$timet\"";
    } else {
      $ts="undef";
    }
    Debug "SyncItems($ts)";
  }
  my %Event=();
  my %Resp=();
  if (defined $timet) {
    if ($timet=~/^[0-9]+$/) {
      my @tm=localtime($timet);
      if ($#tm==-1) {
        $LJ::Simple::error="CODE: Invalid timestamp";
        return undef;
      }
      $Event{lastsync}=strftime("%Y-%m-%d %H:%M:%S",@tm);
    } else {
      $Event{lastsync}=$timet;
    }
  }
  $self->SendRequest("syncitems",\%Event,\%Resp) || return undef;
  my %Mh=();
  my $sync_count;
  my $sync_total;
  my $latest=0;
  my $latest_ts;
  my ($key,$val);
  while(($key,$val)=each %Resp) {
    if ($key=~/sync_([0-9]+)_(.*)$/o) {
      my ($id,$name)=($1,$2);
      (exists $Mh{$id}) || ($Mh{$id}={});
      if ($name eq "item") {
        my ($type,$item_id)=split(/-/,$val,2);
        $Mh{$id}->{item_id}=$item_id;
        $Mh{$id}->{type}=$type;
      } elsif ($name eq "action") {
        $Mh{$id}->{action}=$val;
      } elsif ($name eq "time") {
        $Mh{$id}->{timestamp}=$val;
        if ($val!~/([0-9]+)-([0-9]+)-([0-9]+)\s([0-9]+):([0-9]+):([0-9]+)/io) {
          $LJ::Simple::error="INTERNAL: failed to parse timestamp \"$val\"";
          return undef;
        }
        $Mh{$id}->{time_t}=mktime($6,$5,$4,$3,$2-1,$1-1900,0,0,0);
        if (!defined $Mh{$id}->{time_t}) {
          $LJ::Simple::error="INTERNAL: failed to create time_t from \"$val\"";
          return undef;
        }
        if ($Mh{$id}->{time_t}>$latest) {
          $latest_ts=$val;
          $latest=$Mh{$id}->{time_t};
        }
      } else {
        $LJ::Simple::error="INTERNAL: Unrecognised sync_[0-9]_* \"$key\"";
        return undef;
      }
    } elsif ($key eq "sync_total") {
      $sync_total=$val;
    } elsif ($key eq "sync_count") {
      $sync_count=$val;
    }
  }
  Debug "sync_count=$sync_count\n";
  Debug "sync_total=$sync_total\n";
  my @lst=();
  push(@lst,values %Mh);
  if ($sync_count != $sync_total) {
    my ($num,@nl)=$self->SyncItems($latest_ts);
    (defined $num) || return undef;
    push(@lst,@nl);
  }
  @lst=sort { $a->{time_t} <=> $b->{time_t} } @lst;
  map { $_->{kv}=join(":",$_->{item_id},$_->{type},$_->{action},$_->{time_t}) } @lst;
  my %seen=();
  @lst=grep((!exists $seen{$_->{kv}}) && ($seen{$_->{kv}}=1),@lst);
  my $tot=$#lst+1;
  return ($tot,@lst);
}

=pod

=item $lj->GetEntries($hash_ref,$journal,$type,@opt)

This routine allows you to pull events from the user's LiveJournal. There are
several different ways this routine can work depending on the value given in
the C<$type> argument.

This routine will currently only allow you to get a B<maximum of 50 journal entries>
thanks to restrictions imposed by LiveJournal servers. If you want to perform work
on I<every> journal entry within a LiveJournal account then you should look at the
C<SyncItems()> routine documented above.

The first argument - C<$hash_ref> is a reference to a hash which will be filled
with the details of the journal entries downloaded. The key to this hash is the
C<item_id> of the journal entries. The value is a hash reference which points to
a hash of the same type created by C<NewPost()> and used by C<PostEntry()> and
C<EditEntry()>. The most sensible way to access this hash is to use the various
C<Get*()> routines.

The second argument - C<$journal> - is an optional argument set if the journal
to be accessed is a shared journal. If this is set then the name of shared journal
will be propogated into the entries returned in the hash reference C<$hash_ref> as
if C<$lj->UseJournal($event,$journal)> was called. If not required set this to C<undef>.

The third argument - C<$type> - specifies how the journal entries are to be
pulled down. The contents of the fourth argument - C<@opt> - will depend on the
value in the C<$type> variable. Thus:

  +-------+------------+------------------------------------------+
  | $type | @opt       | Comments                                 |
  +-------+------------+------------------------------------------+
  | day   | $timestamp | Download a single day. $timestamp is a   |
  |       |            | Unix timestamp for the required day      |
  +-------+------------+------------------------------------------+
  | lastn |$num,$before| Download a number of entries. $num has a |
  |       |            | maximum value of 50. If $num is undef    |
  |       |            | then the default of 20 is used. $before  |
  |       |            | is an optional value which specifies a   |
  |       |            | date before which all entries must occur.|
  |       |            | The date is specified as a Unix          |
  |       |            | timestamp. If not specified the value    |
  |       |            | should be undef.                         |
  +-------+------------+------------------------------------------+
  | one   | $item_id   | The unique ItemID for the entry to be    |
  |       |            | downloaded. A value of -1 means to       |
  |       |            | download the most recent entry           |
  +-------+------------+------------------------------------------+
  | sync  | $date      | Get journal entries since the given date.|
  |       |            | The date should be specified as a Unix   |
  |       |            | timestamp.                               |
  +-------+------------+------------------------------------------+

If the operation is successful then C<$hash_ref> is returned. On failure
C<undef> is returned and C<$LJ::Simple::error> is updated with the
reason for the error.

Example code:

The following code only uses a single C<$type> from the above list; C<one>.
However the hash of hashes returned is the same in every C<$type> used. The
code below shows how to pull down the last journal entry posted and then uses
all of the various C<Get*()> routines to decode the hash returned.

  use POSIX;
  
  my %Entries=();
  (defined $lj->GetEntries(\%Entries,undef,"one",-1)) ||
    die "$0: Failed to get entries - $LJ::Simple::error\n";
  
  my $Entry=undef;
  my $Format="%-20s: %s\n";

  foreach $Entry (values %Entries) {
  
    # Get URL
    my $url=$lj->GetURL($Entry);
    (defined $url) && print "$url\n";
  
    # Get ItemId
    my ($item_id,$anum,$html_id)=$lj->GetItemId($Entry);
    (defined $item_id) && printf($Format,"Item_id",$item_id);
  
    # Get the subject
    my $subj=$lj->GetSubject($Entry);
    (defined $subj) && printf($Format,"Subject",$subj);
  
    # Get the date entry was posted
    my $timet=$lj->GetDate($Entry);
    if (defined $timet) {
      printf($Format,"Date",
             strftime("%Y-%m-%d %H:%M:%S",localtime($timet)));
    }
  
    # Is entry protected ?
    my $EntProt="";
    my ($protect,@prot_opt)=$lj->GetProtect($Entry);
    if (defined $protect) {
      if ($protect eq "public") {
         $EntProt="public";
      } elsif ($protect eq "friends") {
        $EntProt="friends only";
      } elsif ($protect eq "groups") {
        $EntProt=join("","only groups - ",join(", ",@prot_opt));
      } elsif ($protect eq "private") {
        $EntProt="private";
      }
      printf($Format,"Journal access",$EntProt);
    }
  
    ## Properties
    # Backdated ?
    my $word="no";
    my $prop=$lj->Getprop_backdate($Entry);
    if ((defined $prop) && ($prop==1)) { $word="yes" }
    printf($Format,"Backdated",$word);
  
    # Preformatted ?
    $word="no";
    $prop=$lj->Getprop_preformatted($Entry);
    if ((defined $prop) && ($prop==1)) { $word="yes" }
    printf($Format,"Preformatted",$word);
  
    # No comments allowed ?
    $word="no";
    $prop=$lj->Getprop_nocomments($Entry);
    if ((defined $prop) && ($prop==1)) { $word="yes" }
    printf($Format,"No comments",$word);
  
    # Do not email comments ?
    $word="no";
    $prop=$lj->Getprop_noemail($Entry);
    if ((defined $prop) && ($prop==1)) { $word="yes" }
    printf($Format,"No emailed comments",$word);
  
    # Unknown 8-bit ?
    $word="no";
    $prop=$lj->Getprop_unknown8bit($Entry);
    if ((defined $prop) && ($prop==1)) { $word="yes" }
    printf($Format,"Any 8 bit, non UTF-8",$word);
  
    # Current music
    $word="[None]";
    $prop=$lj->Getprop_current_music($Entry);
    if ((defined $prop) && ($prop ne "")) { $word=$prop }
    printf($Format,"Current music",$word);
  
    # Current mood [text]
    $word="[None]";
    $prop=$lj->Getprop_current_mood($Entry);
    if ((defined $prop) && ($prop ne "")) { $word=$prop }
    printf($Format,"Current mood",$word);
  
    # Current mood [id]
    $word="[None]";
    $prop=$lj->Getprop_current_mood_id($Entry);
    if ((defined $prop) && ($prop ne "")) { $word=$prop }
    printf($Format,"Current mood_id",$word);
  
    # Picture keyword
    $word="[None]";
    $prop=$lj->Getprop_picture_keyword($Entry);
    if ((defined $prop) && ($prop ne "")) { $word=$prop }
    printf($Format,"Picture keyword",$word);
  
    # Finally output the actual journal entry
    printf($Format,"Journal entry","");
    my $text=$lj->GetEntry($Entry);
    (defined $text) &&
      print "  ",join("\n  ",split(/\n/,$text)),"\n\n";
  }

=cut
sub GetEntries($$@) {
  my $self=shift;
  my ($hr,$journal,$type,@opts)=@_;
  $LJ::Simple::error="";
  if (ref($hr) ne "HASH") {
    $LJ::Simple::error="CODE: GetEntries() not given a hash reference";
    return undef;
  }
  if (!defined $type) {
    $LJ::Simple::error="CODE: GetEntries() given undefined value for type";
    return undef;
  }
  %{$hr}=();
  my %Event=();
  my %Resp=();
  if (defined $journal) {
    $Event{usejournal}=$journal;
  }
  my $ctype=lc($type);
  if ($ctype eq "day") {
    if ($#opts<0) {
      $LJ::Simple::error="CODE: GetEntries($type) requires year,month,day in \@opts";
      return undef;
    }
    my ($timestamp)=@opts;
    if ($timestamp!~/^[0-9]+$/) {
      $LJ::Simple::error="CODE: GetEntries($type) given invalid timestamp";
      return undef;
    }
    my @tm=localtime($timestamp);
    if ($#tm==-1) {
      $LJ::Simple::error="CODE: GetEntries($type) given invalid timestamp";
      return undef;
    }
    $Event{selecttype}=$ctype;
    $Event{year}=$tm[5]+1900;
    $Event{month}=$tm[4]+1;
    $Event{day}=$tm[3];
  } elsif ($ctype eq "lastn") {
    if ($#opts<1) {
      $LJ::Simple::error="CODE: GetEntries($type) requires num and beforedate in \@opts";
      return undef;
    }
    $Event{selecttype}=$ctype;
    my ($num,$beforedate)=@opts;
    if (defined $num) {
      if ($num!~/^[0-9]{1,2}$/) {
        $LJ::Simple::error="CODE: GetEntries($type) requires valid number for num";
        return undef;
      }
      if ($num>50) {
        $LJ::Simple::error="Maximum number of journal entries returned is 50";
        return undef;
      }
    } else {
      $num=20;
    }
    $Event{howmany}=$num;
    if (defined $beforedate) {
      if ($beforedate!~/^[0-9]+$/) {
        $LJ::Simple::error="Invalid Unix timestamp";
        return undef;
      }
      my @tm=localtime($beforedate);
      if ($#tm==-1) {
        $LJ::Simple::error="CODE: GetEntries($type) given invalid timestamp";
        return undef;
      }
      $Event{beforedate}=strftime("%Y-%m-%d %H:%M:%S",@tm);
    }
  } elsif ($ctype eq "one") {
    if ($#opts<0) {
      $LJ::Simple::error="CODE: GetEntries($type) requires item_id in \@opts";
      return undef;
    }
    my ($item_id)=@opts;
    if ($item_id!~/^-*[0-9]+$/) {
      $LJ::Simple::error="Invalid item_id";
      return undef;
    }
    if ($item_id<-1) {
      $LJ::Simple::error="Invalid item_id";
      return undef;
    }
    $Event{selecttype}=$ctype;
    $Event{itemid}=$item_id;
  } elsif ($ctype eq "sync") {
    if ($#opts<0) {
      $LJ::Simple::error="CODE: GetEntries($type) requires timestamp in \@opts";
      return undef;
    }
    my ($lastsync)=@opts;
    if ($lastsync!~/^[0-9]+$/) {
      $LJ::Simple::error="Invalid Unix timestamp";
      return undef;
    }
    my @tm=localtime($lastsync);
    if ($#tm==-1) {
      $LJ::Simple::error="CODE: GetEntries($type) given invalid timestamp";
      return undef;
    }
    $Event{lastsync}=strftime("%Y-%m-%d %H:%M:%S",@tm);
    $Event{selecttype}="syncitems";
  } else {
    $LJ::Simple::error="CODE: GetEntries() does not understand type $type\n";
    return undef;
  }
  $self->SendRequest("getevents",\%Event,\%Resp) || return undef;
  my %Ev=();
  my %Pr=();
  my ($k,$v);
  while(($k,$v)=each %Resp) {
    my ($num,$key,$hash)=(undef,undef,undef);
    if ($k=~/^events_([0-9]+)_(.*)$/) {
      ($num,$key,$hash)=($1,$2,\%Ev);
    } elsif ($k=~/^prop_([0-9]+)_(.*)$/) {
      ($num,$key,$hash)=($1,$2,\%Pr);
    }
    if (defined $hash) {
      (exists $hash->{$num}) || ($hash->{$num}={});
      $hash->{$num}->{$key}=$v;
    }
  }
  my $ehr=undef;
  foreach $ehr (values %Ev) {
    my $itemid=$ehr->{itemid};
    $hr->{$itemid}={};
    my $nhr=$hr->{$itemid};
    %{$nhr}=(
      __htmlid		=>	($ehr->{itemid} * 256) + $ehr->{anum},
      __anum		=>	$ehr->{anum},
      __itemid		=>	$itemid,
      event		=>	$ehr->{event},
      lineenddings	=>	"unix",
    );
    (defined $journal) && ($nhr->{usejournal}=$journal);
    (exists $ehr->{subject}) && ($nhr->{subject}=$ehr->{subject});
    (exists $ehr->{allowmask}) && ($nhr->{allowmask}=$ehr->{allowmask});
    (exists $ehr->{security}) && ($nhr->{security}=$ehr->{security});
    if ($ehr->{eventtime}=~/([0-9]+)-([0-9]+)-([0-9]+)\s([0-9]+):([0-9]+):([0-9]+)/o) {
      $nhr->{year}=int($1);
      $nhr->{mon}=int($2);
      $nhr->{day}=int($3);
      $nhr->{hour}=int($4);
      $nhr->{min}=int($5);
      my $timet=mktime($6,$5,$4,$3,$2-1,$1-1900);
      if (!defined $timet) {
        $LJ::Simple::error="Failed to mktime() from \"$ehr->{eventtime}\" for itemid $hr->{$ehr->{itemid}}->{__htmlid}";
        return undef;
      }
      $nhr->{__timet}=$timet;
    } else {
      $LJ::Simple::error="Failed to parse eventtime \"$ehr->{eventtime}\" for itemid $hr->{$ehr->{itemid}}->{__htmlid}";
      return undef;
    }
  }
  my $phr=undef;
  foreach $phr (values %Pr) {
    if (!exists $hr->{$phr->{itemid}}) {
      $LJ::Simple::error="Protocol error: properties returned for itemid not seen";
      return undef;
    }
    my $nhr=$hr->{$phr->{itemid}};
    my $k=join("_","prop",$phr->{name});
    if (!exists $nhr->{$k}) {
      $nhr->{$k}=$phr->{value};
    }
  }
  return $hr;
}

=pod 

=back

=head2 Getting information from an entry

=over 4

=item $lj->GetDate($event)

Gets the date for the event given. The date is returned as a C<time_t> (i.e. seconds
since epoch) value. Returns C<undef> on failure.

Example code:

  use POSIX;  # For strftime()
  
  ## Get date
  my $timet=$lj->GetDate(\%Event);
  (defined $timet)
    || die "$0: Failed to set date of entry - $LJ::Simple::error\n";
  
  # Get time list using localtime()
  my @tm=localtime($timet);
  ($#tm<0) &&
    die "$0: Failed to run localtime() on time_t $timet\n";
  
  # Format date in the normal way used by LJ "YYYY-MM-DD hh:mm:ss"
  my $jtime=strftime("%Y-%m-%d %H:%M:%S",@tm);

=cut
sub GetDate($$) {
  my $self=shift;
  my ($event)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return undef;
  }
  if (!exists $event->{__timet}) {
    $LJ::Simple::error="No time value stored";
    return undef;
  }
  return $event->{__timet};
}


=pod

=item $lj->GetItemId($event)

Returns a list which contains the real C<item_id>, C<anum> and HTMLised C<item_id> which
can be used to contruct a URL suitable for accessing the item via the web.
Returns C<undef> on failure. Note that you must only use this
routine on entries which have been returned by the C<GetEntries()>
routine.

Example code:

  my ($item_id,$anum,$html_id)=$lj->GetItemId(\%Event);
  (defined $item_id)
    || die "$0: Failed to get item id - $LJ::Simple::error\n";

=cut
sub GetItemId($$) {
  my $self=shift;
  my ($event)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return undef;
  }
  if (!exists $event->{__itemid}) {
    $LJ::Simple::error="item_id does not exist - must use GetEntries()";
    return undef;
  }
  if (!exists $event->{__anum}) {
    $LJ::Simple::error="anum does not exist - must use GetEntries()";
    return undef;
  }
  if (!exists $event->{__htmlid}) {
    $LJ::Simple::error="HTML id does not exist - must use GetEntries()";
    return undef;
  }
  return ($event->{__itemid},$event->{__anum},$event->{__htmlid});
}


=pod

=item $lj->GetURL($event)

Returns the URL which can be used to access the journal entry via a web
browser. Returns C<undef> on failure. Note that you must only use this
routine on entries which have been returned by the C<GetEntries()>
routine.

Example code:

  my $url=$lj->GetURL(\%Event);
  (defined $url)
    || die "$0: Failed to get URL - $LJ::Simple::error\n";
  system("netscape -remote 'openURL($url)'");

=cut
sub GetURL($$) {
  my $self=shift;
  my ($event)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return undef;
  }
  if (!exists $event->{__htmlid}) {
    $LJ::Simple::error="HTML id does not exist - must use GetEntries()";
    return undef;
  }
  my $user=$self->user();
  my $server=$self->{lj}->{host};
  my $port=$self->{lj}->{port};
  my $htmlid=$event->{__htmlid};
  return "http://$server:$port/talkpost.bml\?journal=$user\&itemid=$htmlid";
}

=pod

=item $lj->GetSubject($event)

Gets the subject for the journal entry. Returns the subject if it is
available, C<undef> otherwise.

Example code:

  my $subj=$lj->GetSubject(\%Event)
  if (defined $subj) {
    print "Subject: $subj\n";
  }

=cut
sub GetSubject($$) {
  my $self=shift;
  my ($event) = @_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return undef;
  }
  if (!exists $event->{subject}) {
    $LJ::Simple::error="No subject set";
    return undef;
  }
  return $event->{subject};
}


=pod

=item $lj->GetEntry($event)

Gets the entry for the journal. Returns either a single string which contains
the entire journal entry or C<undef> on failure.

Example code:

  my $ent = $lj->GetEntry(\%Event);
  (defined $ent)
    || die "$0: Failed to get entry - $LJ::Simple::error\n";
  print "Entry: $ent\n";

=cut
sub GetEntry($$) {
  my $self=shift;
  my ($event) = @_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return undef;
  }
  if (!exists $event->{event}) {
    $LJ::Simple::error="No journal entry set";
    return undef;
  }
  return $event->{event};
}


=pod

=item $lj->GetProtect($event)

Gets the protection information on the event given. Returns a list with
details of the protection set on the post. On failure C<undef> is returned.

There are several different types of protection which can be returned for a
journal entry. These include public, friends only, specific friends groups
and private. The list returned will always have the type of protection listed
first followed by any details of that protection. Thus the list can contain:

  ("public")
    A publically accessable journal entry
  
  ("friends")
    Only friends may read the entry
    
  ("groups","group1" ...)
    Only users listed in the friends groups given after the "groups"
    may read the entry
  
  ("private")
    Only the owner of the journal may read the entry

Example code:

  my ($protect,@prot_opt)=$lj->GetProtect(\%Event);
  (defined $protect) ||
    die "$0: Failed to get entry protection type - $LJ::Simple::error\n";
  if ($protect eq "public") {
    print "Journal entry is public\n";
  } elsif ($protect eq "friends") {
    print "Journal entry only viewable by friends\n"; 
  } elsif ($protect eq "groups") {
    print "Journal entry only viewable by friends in the following groups:\n";
    print join(", ",@prot_opt),"\n";
  } elsif ($protect eq "private") {
    print "Journal entry only viewable by the journal owner\n"; 
  }

=cut
sub GetProtect($$) {
  my $self=shift;
  my ($event)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return undef;
  }
  if ((!exists $event->{security})||($event->{security} eq "")) {
    return "public";
  }
  if ($event->{security} eq "private") {
    return "private";
  }
  if ($event->{security} ne "usemask") {
    $LJ::Simple::error="INTERNAL: security contains unknown value \"$event->{security}\"";
    return undef;
  }
  if (($event->{allowmask} & 1) == 1) {
    return "friends";
  }
  my @lst=("groups");
  my $g=undef;
  foreach $g (keys %{$self->{groups}->{name}}) {
    my $bit=1 << $self->{groups}->{name}->{$g}->{id};
    if (($event->{allowmask} & $bit) == $bit) {
      push(@lst,$g);
    }
  }
  return @lst;
}


##
## Helper function used to get meta data
##
sub Getprop_general($$$$$) {
  my ($self,$event,$prop,$caller,$type)=@_;
  $LJ::Simple::error="";
  if (ref($event) ne "HASH") {
    $LJ::Simple::error="CODE: Not given a hash reference";
    return undef;
  }
  my $key=join("_","prop",$prop);
  if (!exists $event->{$key}) {
    if ($type eq "bool") {
      return 0;
    }
    return "";
  }
  return $event->{$key};
}

=pod

=item $lj->Getprop_backdate($event)

Indicates if the journal entry is back dated or not. Back dated
entries do not appear on the friends view of your journal entries. Returns
C<1> if the entry is backdated, C<0> if it is not. C<undef> is returned in the
event of an error.

Example code:

  my $prop=$lj->Getprop_backdate(\%Event);
  (defined $prop) ||
    die "$0: Failed to get property - $LJ::Simple::error\n";
  if ($prop) {
    print STDERR "Journal is backdated\n";
  } else {
    print STDERR "Journal is not backdated\n";
  }
  

=cut
sub Getprop_backdate($$) {
  my ($self,$event)=@_;
  $LJ::Simple::error="";
  return $self->Getprop_general($event,"opt_backdated","Getprop_backdate","bool");
}


=pod

=item $lj->Getprop_current_mood($event)

Used to get the current mood for the journal being written. This returns the
mood if one exists, an empty string if none exists or C<undef> in the event
of an error.

Example code:

  my $prop=$lj->Getprop_current_mood(\%Event);
  (defined $prop) ||
    die "$0: Failed to get property - $LJ::Simple::error\n";
  if ($prop ne "") {
    print STDERR "Journal has mood of $prop\n";
  } else {
    print STDERR "Journal has no mood set\n";
  }


=cut
sub Getprop_current_mood($$) {
  my ($self,$event)=@_;
  $LJ::Simple::error="";
  return $self->Getprop_general($event,"current_mood","Getprop_current_mood","char");
}

=pod

=item $lj->Getprop_current_mood_id($event)

Used to get the current mood_id for the journal being written. Will return
the mood_id if one is set, a null string is one is not set and C<undef> in
the event of an error.

Example code:

  my $prop=$lj->Getprop_current_mood_id(\%Event);
  (defined $prop) ||
    die "$0: Failed to get property - $LJ::Simple::error\n";
  if ($prop ne "") {
    print STDERR "Journal has mood_id of $prop\n";
  } else {
    print STDERR "Journal has no mood_id set\n";
  }


=cut
sub Getprop_current_mood_id($$) {
  my ($self,$event)=@_;
  $LJ::Simple::error="";
  return $self->Getprop_general($event,"current_moodid","Getprop_current_mood_id","num");
}


=pod

=item $lj->Getprop_current_music($event)

Used to get the current music for the journal entry being written. Returns
the music if one is set, a null string is one is not set and C<undef> in
the event of an error.

Example code:

  my $prop=$lj->Getprop_current_music(\%Event);
  (defined $prop) ||
    die "$0: Failed to get property - $LJ::Simple::error\n";
  if ($prop) {
    print STDERR "Journal has the following music: $prop\n";
  } else {
    print STDERR "Journal has no music set for it\n";
  }

=cut
sub Getprop_current_music($$) {
  my ($self,$event)=@_;
  $LJ::Simple::error="";
  return $self->Getprop_general($event,"current_music","Getprop_current_music","char");
}

=pod

=item $lj->Getprop_preformatted($event)

Used to see if the text for the journal entry being written is preformatted in HTML
or not. This returns true (C<1>) if so, false (C<0>) if not.

Example code:

  $lj->Getprop_preformatted(\%Event) &&
    print "Journal entry is preformatted\n";

=cut
sub Getprop_preformatted($$) {
  my ($self,$event)=@_;
  $LJ::Simple::error="";
  return $self->Getprop_general($event,"opt_preformatted","Getprop_preformatted","bool");
}


=pod

=item $lj->Getprop_nocomments($event)

Used to see if the journal entry being written can be commented on or not.
This returns true (C<1>) if so, false (C<0>) if not.

Example code:

  $lj->Getprop_nocomments(\%Event) &&
    print "Journal entry set to disallow comments\n";

=cut
sub Getprop_nocomments($$) {
  my ($self,$event)=@_;
  $LJ::Simple::error="";
  return $self->Getprop_general($event,"opt_nocomments","Getprop_nocomments","bool");
}


=pod

=item $lj->Getprop_picture_keyword($event)

Used to get the picture keyword for the journal entry being written. Returns
the picture keyword if one is set, a null string is one is not set and C<undef> in
the event of an error.

Example code:

  my $prop=$lj->Getprop_picture_keyword(\%Event);
    (defined $prop) ||
    die "$0: Failed to get property - $LJ::Simple::error\n";
  if ($prop) {
    print STDERR "Journal has picture keyword $prop set\n";
  } else {
    print STDERR "Journal has no picture keyword set\n";
  }


=cut
sub Getprop_picture_keyword($$) {
  my ($self,$event)=@_;
  $LJ::Simple::error="";
  return $self->Getprop_general($event,"picture_keyword","Getprop_picture_keyword","char");
}


=pod

=item $lj->Getprop_noemail($event)

Used to see if comments on the journal entry being written should be emailed or
not. This returns true (C<1>) if so comments should B<not> be emailed and false
(C<0>) if they should be emailed.

Example code:

  $lj->Getprop_noemail(\%Event) &&
    print "Comments to journal entry not emailed\n";

=cut
sub Getprop_noemail($$) {
  my ($self,$event)=@_;
  $LJ::Simple::error="";
  return $self->Getprop_general($event,"opt_noemail","Getprop_noemail","bool");
}


=pod

=item $lj->Getprop_unknown8bit($event)

Used see if there is 8-bit data which is not in UTF-8 in the journal entry
being written. This returns true (C<1>) if so, false (C<0>) if not.

Example code:

  $lj->Getprop_unknown8bit(\%Event) &&
    print "Journal entry contains 8-bit data not in UTF-8 format\n";

=cut
sub Getprop_unknown8bit($$) {
  my ($self,$event)=@_;
  $LJ::Simple::error="";
  return $self->Getprop_general($event,"unknown8bit","Getprop_unknown8bit","bool");
}



##### Start of helper functions

##
## A helper function which takes a key and value pair;
## both are encoded for HTTP transit.
##
sub EncVal($$) {
  my ($key,$val)=@_;
  (defined $key) || ($key="");
  (defined $val) || ($val="");
  $key=~s/([^a-z0-9])/sprintf("%%%x",ord($1))/egsi;
  $key=~s/ /\+/go;
  $val=~s/([^a-z0-9])/sprintf("%%%02x",ord($1))/egsi;
  $val=~s/ /\+/go;
  return "$key=$val";
}

##
## A helper function which takes an encoded value from HTTP
## transit and decodes it
##
sub DecVal($) {
  my ($val)=@_;
  (defined $val) || ($val="");
  $val=~s/\+/ /go;
  $val=~s/%([0-9A-F]{2})/pack("C", hex($1))/egsi;
  return "$val";
}

##
## Actually make the LJ request; could be called directly, but isn't
## documented.
##
## The first argument is the the mode to use. The list of currently
## supported modes is:
##  o login
##  o postevent
##
## The second argument is a hash reference to arguments specific to the
## mode.
##
## The third argument is a reference to a hash which contain the response
## from the LJ server. This can be undef.
##
## Returns 1 on success, 0 on failure. On failure $LJ::Simple::error is
## populated.
##
sub SendRequest($$$$) {
  my ($self,$mode,$args,$req_hash)=@_;
  $LJ::Simple::error="";
  my $sub=$LJ::Simple::NonBlock;
  my $bytes_in=0;
  my $bytes_out=0;
  my $timestart=time();
  if ((defined $sub) && (ref($sub) ne "CODE")) { 
    my $reftype=ref($sub);
    $LJ::Simple::error="\$LJ::Simple::NonBlock given a $reftype reference, not CODE";
    return 0;
  }
  $self->{request}={};
  if ((ref($args) ne "HASH")&&($mode ne "getchallenge")) {
    $LJ::Simple::error="INTERNAL: SendRequest() not given hashref for arguments";
    return 0;
  }
  if ((defined $req_hash) && (ref($req_hash) ne "HASH")) {
    $LJ::Simple::error="INTERNAL: SendRequest() not given hashref for responses";
    return 0;
  }
  $mode=lc($mode);
  my @request=(
	"mode=$mode",
  );
  if ($mode ne "getchallenge") {
    push(@request,
		EncVal("user",$self->{auth}->{user}),
	);
    # Much fun here - see if we use the challenge-response stuff
    if ($LJ::Simple::challenge) {
      Debug("Trying to use challenge-response system");
      Debug("  Getting new challenge");
      my %chall=();
      $self->SendRequest("getchallenge",undef,\%chall) || return 0;
      if ($chall{auth_scheme} ne "c0") {
        $LJ::Simple::error="Server returned unsupported auth_scheme \"$chall{auth_scheme}\"";
        return 0;
      }
      Debug("    Got challenge from server:");
      Debug("        challenge: $chall{challenge}");
      Debug("      expire_time: $chall{expire_time}");
      Debug("      server_time: $chall{server_time}");

      # Work out our own timeout point, basically the livetime of the
      # challenge less 10 seconds of fudge factor.
      my $chall_livetime=$chall{expire_time} - $chall{server_time} - 10;
      my $ctime=time();
      $self->{auth}->{challenge}->{timeout}=$ctime + $chall_livetime;
      Debug("    Challenge lifetime is $chall_livetime seconds");
      Debug("      Current: $ctime");
      Debug("       Expire: $self->{auth}->{challenge}->{timeout}");

      $self->{auth}->{challenge}->{challenge}=$chall{challenge};
      # We assume that the Digest::MD5 module is loaded already; also
      # means that we have an MD5 hash of the password to hand.
      my $md5=Digest::MD5->new;
      $md5->add($chall{challenge});
      $md5->add($self->{auth}->{hash});
      $self->{auth}->{challenge}->{hash}=$md5->hexdigest;
    }
    if (exists $self->{auth}->{challenge}->{hash}) {
      push(@request,
		EncVal("auth_method","challenge"),
		EncVal("auth_challenge",$self->{auth}->{challenge}->{challenge}),
		EncVal("auth_response",$self->{auth}->{challenge}->{hash}),
	);
    } else {
      if (exists $self->{auth}->{hash}) {
        push(@request,EncVal("hpassword",$self->{auth}->{hash}));
      } else {
        push(@request,EncVal("password",$self->{auth}->{pass}));
      }
    }
    my $ljprotver=0;
    if ($LJ::Simple::UTF) { $ljprotver=1; }
    push(@request,
	"ver=$ljprotver",
    );
  }
  (defined $sub) && &{$sub}($mode,0.1,"Preparing request data",$bytes_in,$bytes_out,time()-$timestart,0);
  if ($mode eq "login") {
    push(@request,EncVal("clientversion","Perl-LJ::Simple/$VERSION"));
    if ((exists $args->{moods}) && ($args->{moods} == 1)) {
      push(@request,EncVal("getmoods",0));
    }
    if ((exists $args->{getpickws}) && ($args->{getpickws} == 1)) {
      push(@request,EncVal("getpickws",1));
      push(@request,EncVal("getpickwurls",1));
    }
  } elsif ( ($mode eq "postevent")
         || ($mode eq "editevent") 
         || ($mode eq "syncitems") 
         || ($mode eq "getevents") 
         || ($mode eq "getfriends") 
         || ($mode eq "friendof") 
         || ($mode eq "checkfriends") 
         || ($mode eq "getdaycounts") 
         || ($mode eq "getfriendgroups") 
         || ($mode eq "getusertags") 
          ) {
    if (defined $args) {
      my ($k,$v);
      while(($k,$v)=each %{$args}) {
        if (!defined $k) {
          $LJ::Simple::error="CODE: SendRequest() given undefined key value";
          return 0;
        }
        if (!defined $v) {
          $LJ::Simple::error="CODE: SendRequest() given undefined value for \"$k\"";
          return 0;
        }
        push(@request,EncVal($k,$v));
      }
    }
  } elsif ($mode eq "getchallenge") {
    # NOP - nothing required
  } else {
    $LJ::Simple::error="INTERNAL: SendRequest() given unsupported mode \"$mode\"";
    return 0;
  }
  my $req=join("&",@request);
  my $ContLen=length($req);

  (defined $sub) && &{$sub}($mode,0.2,"Preparing connection to server",$bytes_in,$bytes_out,time()-$timestart,0);

  ## Now we've got the request ready, time to start talking to the web
  # Work out where we're talking to and the URI to do it with
  my $server=$self->{lj}->{host};
  my $host=$server;
  my $port=$self->{lj}->{port};
  my $uri="/interface/flat";
  if (defined $self->{proxy}) {
    $uri="http://$server:$port$uri";
    $server=$self->{proxy}->{host};
    $port=$self->{proxy}->{port};
  }

  # Prepare the HTTP request now we've got the URI
  my @HTTP=(
	"POST $uri HTTP/1.0",
	"Host: $host",
	"Content-type: application/x-www-form-urlencoded",
	"User-Agent: LJ::Simple/$VERSION; http://www.bpfh.net/computing/software/LJ::Simple/; lj-simple\@bpfh.net",
	"Content-length: $ContLen",
  );
  if ($self->{fastserver}) {
    push(@HTTP,"Cookie: ljfastserver=1");
  }
  push(@HTTP,
	"",
	$req,
	"",
  );

  # Prepare the socket
  my $tcp_proto=getprotobyname("tcp");
  socket(SOCK,PF_INET,SOCK_STREAM,$tcp_proto);

  # Resolve the server name we're connecting to
  (defined $sub) && &{$sub}($mode,0.3,"Starting to resolve $server to IP address",$bytes_in,$bytes_out,time()-$timestart,0);
  my $addr=inet_aton($server);
  if (!defined $addr) {
    $LJ::Simple::error="Failed to resolve server $server";
    return 0;
  }
  my $sin=sockaddr_in($port,$addr);

  my $ip_addr=join(".",unpack("CCCC",$addr));

  my $proto=$LJ::Simple::ProtoSub;
  ($LJ::Simple::protocol) && &{$proto}(undef,undef,$server,$ip_addr);
  if ($LJ::Simple::raw_protocol) {
    print STDERR "Connecting to $server [$ip_addr]\n";
    print STDERR "Lines starting with \"-->\" is data SENT to the server\n";
    print STDERR "Lines starting with \"<--\" is data RECEIVED from the server\n";
  }

  # Connect to the server
  (defined $sub) && &{$sub}($mode,0.4,"Trying to connect to server $server",$bytes_in,$bytes_out,time()-$timestart,0);
  if (!connect(SOCK,$sin)) {
    $LJ::Simple::error="Failed to connect to $server - $!";
    return 0;
  }

  ($LJ::Simple::protocol) && &{$proto}(undef,"Connected to $server [$ip_addr]",$server,$ip_addr);
  ($LJ::Simple::raw_protocol) &&
     print STDERR "Connected to $server [$ip_addr]\n";

  # Send the HTTP request
  (defined $sub) && &{$sub}($mode,0.5,"Starting to send HTTP request to $server",$bytes_in,$bytes_out,time()-$timestart,0);
  my $cp=0.5;
  foreach (@HTTP) {
    my $line="$_\r\n";
    my $len=length($line);
    my $pos=0;
    my $fail=0;
    while($pos!=$len) {
      my $nbytes=syswrite(SOCK,$line,$len,$pos);
      if (!defined $nbytes) {
	if ( ($! == EAGAIN) || ($! == EINTR) ) {
          $fail++;
          if ($fail>4) {
            $LJ::Simple::error="Write to socket failed with EAGAIN/EINTR $fail times";
            shutdown(SOCK,2);
            close(SOCK);
            return 0;
          }
          next;
        } else {
          $LJ::Simple::error="Write to socket failed - $!";
          shutdown(SOCK,2);
          close(SOCK);
          return 0;
        }
      }
      $pos+=$nbytes;
      $bytes_out+=$nbytes;
      $cp=$cp+0.001;
      (defined $sub) && &{$sub}($mode,$cp,"Sending HTTP request to $server",$bytes_in,$bytes_out,time()-$timestart,0);
    }
    ($LJ::Simple::protocol) && &{$proto}(0,$_,$server,$ip_addr);
    ($LJ::Simple::raw_protocol) && print STDERR "--> $_\n";
  }

  # Read the response from the server - use select()
  (defined $sub) && &{$sub}($mode,0.6,"Getting HTTP response from $server",$bytes_in,$bytes_out,time()-$timestart,0);
  $cp=0.6001;
  my ($rin,$rout,$eout)=("","","");
  vec($rin,fileno(SOCK),1) = 1;
  my $ein = $rin;
  my $response="";
  my $done=0;
  while (!$done) {
    my $nfound;
    if (defined $sub) {
      $nfound = select($rout=$rin,undef,$eout=$ein,0);
      my $ttaken=time()-$timestart;
      if ($nfound!=1) {
        if ($ttaken>$LJ::Simple::timeout) {
          &{$sub}($mode,1,"Connection with server $server timed out",$bytes_in,$bytes_out,$ttaken,0);
          $LJ::Simple::error="Failed to receive data from $server [$ip_addr]";
          shutdown(SOCK,2);
          close(SOCK);
          return 0;
        }
        &{$sub}($mode,$cp,"Waiting for response from $server",$bytes_in,$bytes_out,time()-$timestart,1);
        next;
      }
    } else {
      $nfound = select($rout=$rin,undef,$eout=$ein,$LJ::Simple::timeout);
      if ($nfound!=1) {
        $LJ::Simple::error="Failed to receive data from $server [$ip_addr]";
        shutdown(SOCK,2);
        close(SOCK);
        return 0;
      }
    }
    my $resp="";
    my $nbytes=sysread(SOCK,$resp,$LJ::Simple::buffer);
    if (!defined $nbytes) {
      $LJ::Simple::error="Error in getting data from $server [$ip_addr] - $!";
      shutdown(SOCK,2);
      close(SOCK);
      (defined $sub) && &{$sub}($mode,1,$LJ::Simple::error,$bytes_in,$bytes_out,time()-$timestart,0);
      return 0;
    } elsif ($nbytes==0) {
      $done=1;
    } else { 
      $bytes_in=$bytes_in+$nbytes;
      (defined $sub) && &{$sub}($mode,$cp,"Getting response from server $server",$bytes_in,$bytes_out,time()-$timestart,0);
      $cp=$cp+0.001;
      $response="$response$resp";
      if ($LJ::Simple::raw_protocol) {
        print STDERR "<-- ";
        foreach (split(//,$resp)) {
          s/([\x00-\x20\x7f-\xff])/sprintf("\\%o",ord($1))/ei;
          print "$_";
        }
        print STDERR "\n";
      } elsif ($LJ::Simple::protocol) {
        foreach (split(/[\r\n]{1,2}/o,$resp)) {
          &{$proto}(1,$_,$server,$ip_addr);
        }
      }
    }
  }
  (defined $sub) && &{$sub}($mode,0.7,"Finished getting data from server $server",$bytes_in,$bytes_out,time()-$timestart,0);
  
  # Shutdown the socket
  if (!shutdown(SOCK,2)) {
    $LJ::Simple::error="Failed to shutdown socket - $!";
    (defined $sub) && &{$sub}($mode,1,$LJ::Simple::error,$bytes_in,$bytes_out,time()-$timestart,0);
    return 0;
  }

  # Close the socket
  close(SOCK);

  (defined $sub) && &{$sub}($mode,0.8,"Parsing data from server $server",$bytes_in,$bytes_out,time()-$timestart,0);
  ## We've got the response from the server, so we now parse it
  if (!defined $response) {
    $LJ::Simple::error="Failed to get result from server";
    return 0;
  }

  ## Ensure that response isn't zero length
  if (length($response) == 0) {
    $LJ::Simple::error="Zero length response from server";
    (defined $sub) && &{$sub}($mode,1,"$LJ::Simple::error $server",$bytes_in,$bytes_out,time()-$timestart,0);
    return 0;
  }

  # Split into headers and body
  my ($http,$body)=split(/\r\n\r\n/,$response,2);

  if (!defined $http) {
    $LJ::Simple::error="Failed to get HTTP headers from server";
    (defined $sub) && &{$sub}($mode,1,"$LJ::Simple::error $server",$bytes_in,$bytes_out,time()-$timestart,0);
    return 0;
  }
  if (!defined $body) {
    $LJ::Simple::error="Failed to get HTTP body from server";
    (defined $sub) && &{$sub}($mode,1,"$LJ::Simple::error $server",$bytes_in,$bytes_out,time()-$timestart,0);
    return 0;
  }

  # First lets see if we got a valid response
  $self->{request}->{http}={};
  $self->{request}->{http}->{headers}=[(split(/\r\n/,$http))];
  my $srv_resp=$self->{request}->{http}->{headers}->[0];
  $srv_resp=~/^HTTP\/[^\s]+\s([0-9]+)\s+(.*)/;
  my ($srv_code,$srv_msg)=($1,$2);
  $self->{request}->{http}->{code}=$srv_code;
  $self->{request}->{http}->{msg}=$srv_msg;
  if ($srv_code != 200) {
    $LJ::Simple::error="HTTP request failed with $srv_code $srv_msg";
    return 0;
  }

  # We did, so lets pull in the LJ stuff for processing
  $self->{request}->{lj}={};

  # The response from LJ takes the form of a key\nvalue\n
  # Note that the value can be null tho
  $done=0;
  while (!$done) {
    if ($body=~/^([^\n]+)\n([^\n]*)\n(.*)$/so) {
      my ($k,$v)=(undef,undef);
      ($k,$v,$body)=(lc($1),DecVal($2),$3);
      $v=~s/\r\n/\n/go;
      $self->{request}->{lj}->{$k}=$v;
    } else {
      $done=1;
    }
  }

  # Got it into a hash - lets see if we made a successful request
  if ( (!exists $self->{request}->{lj}->{success}) ||
       ($self->{request}->{lj}->{success} ne "OK") ) {
    my $errmsg="Server Error, try again later";
    if (exists $self->{request}->{lj}->{errmsg}) {
      $errmsg=$self->{request}->{lj}->{errmsg};
    }
    $LJ::Simple::error="LJ request failed: $errmsg";
    (defined $sub) && &{$sub}($mode,1,"$LJ::Simple::error $server",$bytes_in,$bytes_out,time()-$timestart,0);
    return 0;
  }

  # We did!
  # Now to populate the hash we were given (if asked to)
  if (defined $req_hash) {
    %{$req_hash}=();
    my ($k,$v);
    while(($k,$v)=each %{$self->{request}->{lj}}) {
      $req_hash->{$k}=$v;
    }
  }

  (defined $sub) && &{$sub}($mode,1,"Finished processing request to server $server",$bytes_in,$bytes_out,time()-$timestart,0);
  return 1;
}

##
## Output debugging info
##
sub Debug(@) {
  ($LJ::Simple::debug) || return;
  my $msg=join("",@_);
  foreach (split(/\n/,$msg)) {
    print STDERR "DEBUG> $_\n";
  }
}


##
## Dump out a list recursively. Will call dump_hash
## for any hash references in the list.
##
## Generally used for debugging
##
sub dump_list($$) {
  my ($lr,$sp)=@_;
  my $le="";
  my $res="";
  foreach $le (@{$lr}) {
    if (ref($le) eq "HASH") {
      $res="$res$sp\{\n";
      $res=$res . dump_hash($le,"$sp  ");
      $res="$res$sp},\n";
    } elsif (ref($le) eq "ARRAY") {
      $res="$res$sp\[\n" . dump_list($le,"$sp  ") . "$sp],\n";
    } else {
      my $lv=$le;
      if (defined $lv) {
        $lv=~s/\n/\\n/go;
        $lv=quotemeta($lv);
        $lv=~s/\\-/-/go;
        $lv="\"$lv\"";
      } else {
        $lv="undef";
      }
      $res="$res$sp$lv,\n";
    }
  }
  return $res;
}

##
## Dump out a hash recursively. Will call dump_list
## for any list references in the hash values.
##
## Generally used for debugging
##
sub dump_hash($$) {
  my ($hr,$sp)=@_;
  my ($k,$v)=();
  my $res="";
  while(($k,$v)=each %{$hr}) {
    $k=quotemeta($k);
    $k=~s/\\-/-/go;
    if (ref($v) eq "HASH") {
      $res="$res$sp\"$k\"\t=> {\n";
      $res=$res . dump_hash($v,"$sp  ");
      $res="$res$sp},\n";
    } elsif (ref($v) eq "ARRAY") {
      $res="$res$sp\"$k\"\t=> \[\n" . dump_list($v,"$sp  ") . "$sp],\n";
    } else {
      if (defined $v) {
        $v=~s/\n/\\n/go;
        $v=quotemeta($v);
        $v=~s/\\\\n/\\n/go;
        $v=~s/\\-/-/go;
        $v="\"$v\"";
      } else {
        $v="undef";
      }
      my $out="$sp\"$k\"\t=> $v,";
      $res="$res$out\n";
    }
  }
  return $res;
}

1;
__END__

=pod

=back

=head1 AUTHOR

Simon Burr E<lt>simes@bpfh.netE<gt>

=head1 SEE ALSO

perl
L<http://www.livejournal.com/>

=head1 LICENSE

Copyright (c) 2002, Simon Burr E<lt>F<simes@bpfh.net>E<gt>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer. 
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution. 
  * Neither the name of the author nor the names of its contributors may
    be used to endorse or promote products derived from this software
    without specific prior written permission. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
