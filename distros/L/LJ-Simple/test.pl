# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

##
#
# Out of the box this script hardly touches the functionality of LJ::Simple
# thanks to the removal of the test user on www.livejournal.com.
#
# If people wish they can place another username and password in the $user
# and $pass variables in test.pl to run all of the test.pl Bear in mind that
# I'm not going to be held responsible for what happens to the journal that
# this script is pointed at though.
#
##

#########################
use Test;
BEGIN { plan tests => 42 };
use LJ::Simple;
ok(1); # If we made it this far, we're ok.
#########################

my $user="test";
my $pass="test";

$LJ::Simple::TestStopQuickPost = 1;
if (LJ::Simple::QuickPost() == 0) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost( user ) == 0) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost( user => $user ) == 0) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost( user => $user, pass => $pass, entry => "foo" ) == 1)
 { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost(
		user => $user, pass => $pass, entry => "foo",
                html => "foo", 
    ) == 0) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost(
		user => $user, pass => $pass, entry => "foo",
                html => 1,
    ) == 1) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost(
		user => $user, pass => $pass, entry => "foo",
                protect => "groups",
    ) == 0) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost(
		user => $user, pass => $pass, entry => "foo",
                protect => "groups",
		groups => "foo",
    ) == 0) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost(
		user => $user, pass => $pass, entry => "foo",
                protect => "groups",
		groups => [],
    ) == 1) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost(
		user => $user, pass => $pass, entry => "foo",
                tags => "groups",
    ) == 0) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost(
		user => $user, pass => $pass, entry => "foo",
                tags => [],
    ) == 1) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost(
		user => $user, pass => $pass, entry => "foo",
                results => "groups",
    ) == 0) { ok(1) } else { ok(0) }
if (LJ::Simple::QuickPost(
		user => $user, pass => $pass, entry => "foo",
                results => {},
    ) == 1) { ok(1) } else { ok(0) }
$LJ::Simple::TestStopQuickPost = 0;

#goto LOGIN;

## Test object creation via new - should fail
my $lj = new LJ::Simple();
if (!defined $lj) { ok(1) } else { ok(0) }

## Test object creation via login - should fail
$lj = LJ::Simple->login();
if (!defined $lj) { ok(1) } else { ok(0) }

if (1) {
#  $LJ::Simple::debug=1;
#  $LJ::Simple::protocol=1;
}

## Test object creation by going to a site not running LJ
$lj = new LJ::Simple ({
	user	=>	"test",
	pass	=>	"test",
	site	=>	"httpd.apache.org",
      });
if (!defined $lj) { 
  ok($LJ::Simple::error,'/HTTP request failed/');
} else {
  ok(0);
}

## Test object creation with what is (hopefully) an invalid username
$lj = new LJ::Simple ({
	user	=>	"testmmeekmooo",
	pass	=>	"test",
	site	=>	undef,
      });
if (!defined $lj) { 
  ok($LJ::Simple::error,'/LJ request failed: Invalid username/');
} else {
  ok(0);
}

## Test object creation with a valid user, but invalid password
$lj = new LJ::Simple ({
	user	=>	$user,
	pass	=>	"testy",
	site	=>	undef,
      });
if (!defined $lj) { 
  ok($LJ::Simple::error,'/LJ request failed: Invalid password/');
} else {
  ok(0);
}

##
## Some quick checks of the HTTP proxy support via environment variables
##
my %CopyEnv=();
my $ProxyTest="example.com";
my @ProxyVars=(qw( http_proxy HTTP_PROXY ));
map { (exists $ENV{$_}) && ($CopyEnv{$_}=$ENV{$_}) } (@ProxyVars);
map { delete $ENV{$_} } (@ProxyVars);

# proxy overrides EnvVar
$ENV{http_proxy}="http://$ProxyTest/";
$lj = new LJ::Simple({
	  user	=>	$user,
	  pass	=>	$pass,
	  fast	=>	1,	# Don't want to actually login
	  proxy	=>	undef,
	});
if (defined $lj) {
  if (defined $lj->{proxy}) { ok(0) } else { ok(1) }
} else {
  ok(0);
}
# http_proxy, default port
$ENV{http_proxy}="http://$ProxyTest/";
$lj = new LJ::Simple({
	  user	=>	$user,
	  pass	=>	$pass,
	  fast	=>	1,	# Don't want to actually login
	});
if (defined $lj) {
  if (ref($lj->{proxy}) ne "HASH") { ok(0)
  } else {
    if ($lj->{proxy}->{host} ne $ProxyTest) { ok(0)
    } else {
      if ($lj->{proxy}->{port} ne "3128") { ok(0)
      } else {
        ok(1);
      }
    }
  }
} else {
  ok(0);
}

# http_proxy, non-standard port
$ENV{http_proxy}="http://$ProxyTest:80/";
$lj = new LJ::Simple({
	  user	=>	$user,
	  pass	=>	$pass,
	  fast	=>	1,	# Don't want to actually login
	});
if (defined $lj) {
  if (ref($lj->{proxy}) ne "HASH") { ok(0)
  } else {
    if ($lj->{proxy}->{host} ne $ProxyTest) { ok(0)
    } else {
      if ($lj->{proxy}->{port} ne "80") { ok(0)
      } else {
        ok(1);
      }
    }
  }
} else {
  ok(0);
}

## Reset %ENV values to what we started with
foreach my $env (@ProxyVars) {
  if (exists $CopyEnv{$env}) {
    $ENV{$env}=$CopyEnv{$env};
  } else {
    delete $ENV{$env};
  }
}

##
## A couple of tests to make sure that certains occur as documented
##
$lj = new LJ::Simple ({
        user    =>      $user,
        pass    =>      $pass,
        site    =>      undef,
	moods	=>	0,
	pics	=>	0,
      });
if (defined $lj) {ok(1)} else {ok(0)}
my %Ref=();
if ((defined $lj)&&(!defined $lj->moods(\%Ref))) {
  if ($LJ::Simple::error=~/not requested at login/) {ok(1)} else {ok(0)}
} else {
  ok(0);
}
if ((defined $lj)&&(!defined $lj->pictures(\%Ref))) {
  if ($LJ::Simple::error=~/none defined/) {ok(1)} else {ok(0)}
} else {
  ok(0);
}
if ((defined $lj)&&(!defined $lj->DefaultPicURL())) {
  if ($LJ::Simple::error=~/none defined/) {ok(1)} else {ok(0)}
} else {
  ok(0);
}

# Fast login
$lj = new LJ::Simple ({
        user    =>      $user,
        pass    =>      $pass,
        site    =>      undef,
	fast	=>	1,
      });
if (defined $lj) {ok(1)} else {ok(0)}
my %Ref=();
if ((defined $lj)&&(!defined $lj->moods(\%Ref))) {
  if ($LJ::Simple::error=~/not requested at login/) {ok(1)} else {ok(0)}
} else {
  ok(0);
}
if ((defined $lj)&&(!defined $lj->pictures(\%Ref))) {
  if ($LJ::Simple::error=~/none defined/) {ok(1)} else {ok(0)}
} else {
  ok(0);
}
my @clst=$lj->communities();
if ($#clst==-1) {ok(1)} else {ok(0)}
if ((defined $lj)&&(!$lj->MemberOf("foooo"))) {ok(1)} else {ok(0)}
if ((defined $lj)&&(!defined $lj->groups(\%Ref))) {
  if ($LJ::Simple::error=~/none defined/) {ok(1)} else {ok(0)}
} else {
  ok(0);
}
if ((defined $lj)&&(!defined $lj->MapGroupToId("some group"))) {
  if ($LJ::Simple::error=~/none defined/) {ok(1)} else {ok(0)}
} else {
  ok(0);
}
if ((defined $lj)&&(!defined $lj->MapIdToGroup(1))) {
  if ($LJ::Simple::error=~/none defined/) {ok(1)} else {ok(0)}
} else {
  ok(0);
}
if ((defined $lj)&&(!$lj->SetProtectGroups(\%Ref,"group"))) {
  if ($LJ::Simple::error=~/not requested/) {ok(1)} else {ok(0)}
} else {
  ok(0);
}
if ((defined $lj)&&(!defined $lj->message())) {ok(1)} else {ok(0)}


LOGIN:;

## Test object creation with a valid username and password
$lj = new LJ::Simple ({
	user	=>	$user,
	pass	=>	$pass,
	site	=>	undef,
      });
if (defined $lj) { 
  ok(1);
} else {
  ok(0);
  print STDERR "  Error was: $LJ::Simple::error\n";
}

#goto JTEST;

if (defined $lj) {
  my $msg=$lj->message();
  ok(1);
} else {
  ok(0);
}

my %Moods=();
if ((defined $lj)&&(!defined $lj->moods(\%Moods))) {
  ok(0);
} else {
  ok(1);
}
if (defined $lj) {
  my @communities = $lj->communities();
  ok(1);
} else {
  ok(0);
}

my %Groups=();
if ((defined $lj)&&(!defined $lj->groups(\%Groups))) {
  if ($LJ::Simple::error=~/ - none defined/) {
    ok(1);
  } else {
    ok(0);
  }
} elsif (!defined $lj) {
  ok(0);
} else {
  ok(1);
}

if (defined $lj) {
  my %pictures=();
  $lj->pictures(\%pictures);
  ok(1);
} else {
  ok(0);
}

## We stop here if we're the now dead test user
($user eq "test") && exit 0;

my %Event=();

## Ensure that stuff for posting journal entrie doesn't work until
## NewEntry is called
if ((defined $lj)&&(!defined $lj->PostEntry(\%Event))) {
  if ($LJ::Simple::error=~/CODE: NewEntry not called/){ok(1);}else{ok(0);}
} else { ok(0); }
if ((defined $lj)&&(!$lj->SetDate(""))) {
  if ($LJ::Simple::error=~/Not given a hash reference/){ok(1);}else{ok(0);}
} else { ok(0); }
if ((defined $lj)&&(!$lj->Setprop_backdate("",1))) {
  if ($LJ::Simple::error=~/Not given a hash reference/){ok(1);}else{ok(0);}
} else { ok(0); }

if ((defined $lj)&&(!$lj->NewEntry(\%Event))) {
  ok(0);
} elsif (!defined $lj) {
  ok(0);
} else {
  ok(1);
}


## Post it - we are expecting an error due to no entry being present
if ((defined $lj)&&(!defined $lj->PostEntry(\%Event))) {
 if ($LJ::Simple::error=~/No journal entry set/){ok(1);}else{ok(0);}
} else {
  ok(0);
}

## Playing with shared journals
# Set to shared journal we assume doesn't exist
if ((defined $lj)&&(!$lj->UseJournal(\%Event,"communitydoesnotexisthopefully"))) {
 if ($LJ::Simple::error=~/user unable to post/){ok(1);}else{ok(0);}
} else {
  ok(0);
}
# Set to shared journal which should exist
if ((defined $lj)&&(!$lj->UseJournal(\%Event,"test2"))) { ok(0) } else { ok(1) }

## Setting date... we use $lj->{event}->{__timet} here
# Set to current time
if ((defined $lj)&&(!$lj->SetDate(\%Event,undef))) {
  ok(0);
} elsif (!defined $lj) {
  ok(0);
} else {
  my ($t,$r)=(time(),$Event{__timet});
  if ($t==$r) { ok(1); }
  elsif (($t>$r)&&($t<=($r+5))) { ok(1); }
  else { ok(0); }
}
# Set to current time less an hour
if ((defined $lj)&&(!$lj->SetDate(\%Event,-3600))) {
  ok(0);
} elsif (!defined $lj) {
  ok(0);
} else {
  my ($t,$r)=(time()-3600,$Event{__timet});
  if ($t==$r) { ok(1); }
  elsif (($t>$r)&&($t<=($r+5))) { ok(1); }
  else { ok(0); }
}

# Set to script start time and check GetDate()
if (defined $lj) {
  $lj->SetDate(\%Event,$^T);
  my $timet=$lj->GetDate(\%Event);
  if (!defined $timet) { ok(0) }
  else {
    if ($timet==$^T) { ok(1) } else { ok(0) }
  }
} else {
  ok(0);
}

## Set properties
if ((defined $lj)&&($lj->Setprop_backdate(\%Event,1))) { ok(1) } else { ok(0) }
if ((defined $lj)&&($lj->Setprop_current_mood(\%Event,"Meep"))) { ok(1) } else { ok(0) }
if ((defined $lj)&&($lj->Setprop_current_mood_id(\%Event,12))) { ok(1) } else { ok(0) }
if ((defined $lj)&&($lj->Setprop_current_music(\%Event,"Collected dance"))) { ok(1) } else { ok(0) }
if ((defined $lj)&&($lj->Setprop_preformatted(\%Event,1))) { ok(1) } else { ok(0) }
if ((defined $lj)&&($lj->Setprop_nocomments(\%Event,1))) { ok(1) } else { ok(0) }
if ((defined $lj)&&($lj->Setprop_noemail(\%Event,1))) { ok(1) } else { ok(0) }
if ((defined $lj)&&($lj->Setprop_unknown8bit(\%Event,1))) { ok(1) } else { ok(0) }

if ((defined $lj)&&(!$lj->Setprop_picture_keyword(\%Event,"Some photo"))) {
  if ($LJ::Simple::error=~/Picture keyword not associated/) {ok(1)} else {ok(0)}
} elsif (!defined $lj) {
  ok(0);
} else {
  ok(0);
}
if (defined $lj) {
  my $prop=undef;
  $prop=$lj->GetURL(\%Event);
  if (defined $prop) {ok(0)} else  {ok(1)}
  $prop=$lj->Getprop_backdate(\%Event);
  if (!defined $prop) {ok(0)} elsif ($prop==1) {ok(1)} else {ok(0)}
  $prop=$lj->Getprop_current_mood(\%Event);
  if (!defined $prop) {ok(0)} elsif ($prop=="Meep") {ok(1)} else {ok(0)}
  $prop=$lj->Getprop_current_mood_id(\%Event);
  if (!defined $prop) {ok(0)} elsif ($prop==12) {ok(1)} else {ok(0)}
  $prop=$lj->Getprop_current_music(\%Event);
  if (!defined $prop) {ok(0)} elsif ($prop=="Collected dance") {ok(1)} else {ok(0)}
  $prop=$lj->Getprop_preformatted(\%Event);
  if (!defined $prop) {ok(0)} elsif ($prop==1) {ok(1)} else {ok(0)}
  $prop=$lj->Getprop_nocomments(\%Event);
  if (!defined $prop) {ok(0)} elsif ($prop==1) {ok(1)} else {ok(0)}
  $prop=$lj->Getprop_noemail(\%Event);
  if (!defined $prop) {ok(0)} elsif ($prop==1) {ok(1)} else {ok(0)}
  $prop=$lj->Getprop_unknown8bit(\%Event);
  if (!defined $prop) {ok(0)} elsif ($prop==1) {ok(1)} else {ok(0)}
} else {
  foreach (1..9) { ok(0) }
}

if (defined $lj) {
  ## Set permissions
  if (!$lj->SetProtectPrivate(\%Event)) { ok(0) } else { ok(1) }
  if (!$lj->SetProtectFriends(\%Event)) { ok(0) } else { ok(1) }
  # This should fail
  if ($lj->SetProtectGroups(\%Event)) { ok(0) } else { ok(1) }
  # As should this
  if (!$lj->SetProtectGroups(\%Event,"meep foo bar baz")) {
    if ($LJ::Simple::error=~/Group "[^"]*" does not exist/) {ok(1)} else {ok(0)}
  } else {
    ok(0);
  }
} else {
  foreach (1..4) { ok(0) }
}
# This *should* work, but is disabled since its too unreliable
#if (!$lj->SetProtectGroups(\%Event,"Communities")) { ok(0) } else { ok(1) }

## Set subject
if ((defined $lj)&&($lj->SetSubject(\%Event,"a"x256))) { ok(0) } elsif (!defined $lj) {ok(0)} else { ok(1) }
if ((defined $lj)&&($lj->SetSubject(\%Event,"\n"))) { ok(0) } elsif (!defined $lj) {ok(0)} else { ok(1) }
if ((defined $lj)&&(!$lj->SetSubject(\%Event,"Meep"))) { ok(0) } elsif (!defined $lj) {ok(0)} else { ok(1) }

## Set entry
if ((defined $lj)&&($lj->SetEntry(\%Event,"Some val"))) { ok(1) } else { ok(0) }
if ((defined $lj)&&($lj->AddToEntry(\%Event,"Other val"))) { ok(1) } else { ok(0) }
if ($Event{event} ne "Some val\nOther val") { ok(0) } else { ok(1) }

my @stuff=("Line 1","Line 2","Line 3");
my @ts=(@stuff);
if ((defined $lj)&&($lj->SetEntry(\%Event,@stuff))) {
  if ($Event{event} eq join("\n",@ts)) { ok(1) } else { ok(0) }
} else {
  ok(0) 
}
@stuff=("Line 4","Line 5","Line 6");
push(@ts,@stuff);
if ((defined $lj)&&($lj->AddToEntry(\%Event,@stuff))) {
  if ($Event{event} eq join("\n",@ts)) { ok(1) } else { ok(0) }
} else {
  ok(0) 
}

#JTEST:

## Now re-create an entry
if ((defined $lj)&&($lj->NewEntry(\%Event))) {
  ok(1);
} else {
  ok(0);
}

my $entry=<<EOF;
Test of <tt>LJ::Simple</tt> version $LJ::Simple::VERSION
EOF
if ((defined $lj)&&($lj->SetEntry(\%Event,$entry))) { ok(1) } else { ok(0) }

if (defined $lj) {
  $lj->SetSubject(\%Event,"Test entry");
  $lj->SetMood(\%Event,"happy");
  $lj->Setprop_nocomments(\%Event,1);
  $lj->Setprop_backdate(\%Event,1);
}

## Finally fully test a post
if (defined $lj) {
  my ($item_id,$anum,$html_id)=$lj->PostEntry(\%Event);
  if (!defined $item_id) {
    ok(0);
    print STDERR "  Error message: $LJ::Simple::error\n";
  } else {
    ok(1);
  }
} else {
  ok(0);
}

#goto JTEST2;

if (defined $lj) {
  my ($num_of_items,@lst)=$lj->SyncItems(time()-86400);
  if ((defined $num_of_items)&&($num_of_items>0)) {
    my $ok=0;
    foreach (@lst) {
      if ($_->{item_id} == $item_id) {
        $ok=1;
        last;
      }
    }
    if ($ok) {ok(1)} else {ok(0)}
  } else {
    ok(0);
  }
} else {
  ok(0);
}

if (defined $lj) {
  my ($num_friends_of,@FriendOf)=$lj->GetFriendOf();
  if (defined $num_friends_of) { ok(1) } else {ok(0)}

  my ($num_friends,@Friends)=$lj->GetFriends();
  if (defined $num_friends) { ok(1) } else {ok(0)}

  my ($new_friends,$next_check)=$lj->CheckFriends();
  if (defined $new_friends) { ok(1) } else {ok(0)}
} else {
  foreach (1..3) { ok(0) }
}

if (defined $lj) {
  my $fooy="";
  my %gdc_hr=();
  if (defined $lj->GetDayCounts(\$fooy,undef)) { ok(0) } else {ok(1)}
  if (defined $lj->GetDayCounts(\%gdc_hr,undef)) { ok(1) } else {ok(0)}

  my %gfg_hr=();
  if (defined $lj->GetFriendGroups(\$fooy)) { ok(0) } else {ok(1)}
  if (defined $lj->GetFriendGroups(\%gfg_hr)) { ok(1) } else {ok(0)}

  # First the checks to make sure that validation works
  my %GE_hr=();
  if (defined $lj->GetEntries(\$fooy)) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"day")) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"day",-1)) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"lastn")) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"lastn",1,-1)) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"lastn",51,1)) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"one")) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"one","abc")) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"one","-2")) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"one",-1)) { ok(1) } else {ok(0)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"sync")) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"sync",-1)) { ok(0) } else {ok(1)}
  if (defined $lj->GetEntries(\%GE_hr,undef,"fooy")) { ok(0) } else {ok(1)}
  # Now we deal with stuff directly. First by day
  if (defined $lj->GetEntries(\%GE_hr,undef,"day",$^T)) {
    if (exists $GE_hr{$item_id}) {ok(1)} else {ok(0)}
  } else {
    ok(0);
  }
  my $ev=(values %GE_hr)[0];
  $prop=$lj->GetURL($ev);
  if (defined $prop) {ok(1)} else {ok(0)}
} else {
  foreach (1..19) { ok(0) }
}

if (defined $lj) {
  # lastn, get last 20 entries (default)
  if (defined $lj->GetEntries(\%GE_hr,undef,"lastn",undef,undef)) {
    if (exists $GE_hr{$item_id}) {ok(1)} else {ok(0)}
  } else {
    ok(0); print "  Error was: $LJ::Simple::error\n";
  }
} else {
  ok(0);
}

if (defined $lj) {
  # lastn, last 20 entries before current time
  if (defined $lj->GetEntries(\%GE_hr,undef,"lastn",undef,time()+800)) {
    if (exists $GE_hr{$item_id}) {ok(1)} else {ok(0)}
  } else {
    ok(0); print "  Error was: $LJ::Simple::error\n";
  }
} else {
  ok(0);
}


my %Entry=();
if (defined $lj) {
  # one, just our latest entry
  if (defined $lj->GetEntries(\%Entry,undef,"one",$item_id)) {
    if (exists $Entry{$item_id}) {ok(1)} else {ok(0)}
  } else {
    ok(0);
    print "  Error was: $LJ::Simple::error\n";
  }
} else {
  ok(0);
}

if (defined $lj) {
  # sync from yesturday
  if (defined $lj->GetEntries(\%GE_hr,undef,"sync",$^T-86400)) {
    if (exists $GE_hr{$item_id}) {ok(1)} else {ok(0)}
  } else {
    ok(0);
    print "  Error was: $LJ::Simple::error\n";
  }
} else {
  ok(0);
}

# Edit the latest entry
if (defined $lj) {
  my $event=$Entry{$item_id};
  my $NewText="Foooooooooo!";
  $lj->SetEntry($event,$NewText);
  if ($lj->EditEntry($event)) {
    ok(1) ;
  } else {
    ok(0); 
    print STDERR "  Error was: $LJ::Simple::error\n";
  }
} else {
  ok(0);
}

# Get entry again & compare
if (defined $lj) {
  if (defined $lj->GetEntries(\%Entry,undef,"one",$item_id)) {
    if (exists $Entry{$item_id}) {ok(1)} else {ok(0)}
  } else {
    ok(0); print STDERR "  Error was: $LJ::Simple::error\n";
  }
  if ($NewText eq $lj->GetEntry($Entry{$item_id})) { ok(1) } else { ok(0) }
} else {
  ok(0);
  ok(0);
}

## Be nice and remove the test entry
if ((defined $lj)&&($lj->DeleteEntry($item_id))) { ok(1) } else { ok(0) }

JTEST2:

exit 0;
