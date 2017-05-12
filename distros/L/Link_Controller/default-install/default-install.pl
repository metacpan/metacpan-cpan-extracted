#!/usr/bin/perl -w

=head1 NAME

default-install - Configure LinkController to run in a basic way.

=head1 DESCRIPTION

This is an attempt to build a default installation of link-controller
to make it plug in and play.  This is designed for an installation
where the system adminstrator will run LinkController whilst users
will use the central database of links, but repair their own web
pages.  This would be suitable for use by e.g. a web hosting company.
We want the following attributes.

=over 4

=item *

reasonable security

=item *

near instant usability

=item *

easy control by root

=item *

accountability

=item *

No network traffic if nobody uses link controller.

=back

Currently the default installation is designed for the following
model..

There is a B<linkcont> user and a group B<lcuser>.  A program running
as the link-controller user collects link lists from each user on the
system who is in the group from the file

       ~$user/.link-control-links

The script /etc/cron.daily/linkcontroller then runks link checking
every night based on those links.  The link checking runs as the
linkcont user.

We then log the activities of link controller to /var/log/link-controller

=head1 OPTIONS

=head2 --help

This option gives a full summary of the options and their aliases and
short forms.

=head2 --all

This option is the same as 
"B<--cron --config --user-config --directory --create-user>".
That is to say it does everything that is needed to get
B<LinkController> running.  However it doesn't activate any users.
You should activate users to use LinkControlller with
B<--user> and/or B<--group>.

=head2 --cron

This option installs two cron scripts.  One /etc/cron.daily which runs
B<LinkController> and one in /etc/cron.weekly which does a database
cleanup.  This should mean that link controller is run automatically
each night, which hopefully is your network low usage time.

=head2 --config

Install the configuration files.  This creates /etc/link-control.pl

=head2 --base-dir

This option can be used in during building a package (e.g. RPM) of
LinkController.  It will put all of the files created under the
directory given.  This doesn't however mean that the installation will
work in that location.  It is assumed that the files will either be
linked or moved into their normal locations by some other means.  In
the case of RPM this means using the B<--build-root> option at package
build time.

=head2 --disable

With the B<--disable> option link controller reverses the actions it
would have taken normally.

B<N.B. --disable does not stop anyone from running linkcontroller
themselves>.  It is just that link controller will not run from the
linkcont user.  In order to safely disable the use of link controller,
either remove it completely and stop your users installing programs
(and editing or creating any executable files) or disconnect your
network connection!!

=head2 --user and --group

These options activate users by putting them into the C<linkcont>
group.  The B<--group> option does this for all of the members in a
particular group.

=head1 BUGS

This mode of operation requires that the users home directory is
readable to the linkcont user.  A crontab like mechanism should maybe
be considered?

=head1 SEE ALSO

L<copy-links-from-users>

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont - the
LinkController homepage.

=cut

sub install_cron_scripts ();
sub remove_cron_scripts ();
sub install_central_config_file ();
sub remove_central_config_file ();
sub install_user_config_file ();
sub remove_user_config_file ();
sub create_user ();
sub delete_user ();
sub activate_users (@);
sub deactivate_users (@);
sub create_workingdir ();
sub delete_workingdir ();

use Getopt::Function qw(maketrue makevalue);
use strict;
use vars qw/$config $user_config $cron $linkcont_user $user $disable
            $directory $all $base_dir $verbose/;
use File::Path;

@::ORIG_ARGS=@::ARGV;

#for filenames the variable postfixed with _INSTALL is where the file will
#be finally be installed.

$::LC_USERS_GROUP='lnctusr';
#N.B. the following three are also copied to pkg-data-rpm/pre.sh
$::LC_USER='linkcont';
$::LC_GROUP=$::LC_USER;
$::LC_DIR_INSTALL='/var/lib/linkcontroller';
$::LOG_FILE_INSTALL='/var/log/link-controller';


$base_dir="";
my %users = ();


sub group;

{
  my $opened=0;
  $::opthandler = new Getopt::Function
    [ "version V>version",
      "usage h>usage help>usage",
      "help-opt=s",
      "verbose:i v>verbose",
      "cron C>cron",
      "config N>config",
      "directory D>directory",
      "linkcont-user L>linkcont-user",
      "user=s U>user",
      "all A>all",
      "group=s g>group",
      "disable d>disable",
      "base-dir=s b>base-dir",
    ],  {
	 "user" => [ sub {$::user=1, $users{$::value}=1; },
		   "(de)activate users in the linkcontroller group",
		   "USERNAME"],
	 group => [
		   sub {
		     $::user=1;
		     my ($name,$passwd,$gid,$members) = getgrnam($::value);
		     die "Unknown group $::value" unless defined($gid);
		     #FIXME arbitrary parameter (100) which is often wrong,
		     #e.g. on redhat where 500 would be correct!!
		     foreach my $user (my @more_users = split ($members)) {
		       $users{$user}=1;
		     }
		   },
		   "(de)activate all group members to the linkcont group.",
		   "GROUP",
		  ],
	 "base-dir" => [ \&makevalue,
		       "use DIRECTORY as the base for file creation",
		       "DIRECTORY" ],
	 cron => [ \&maketrue,
		   "install cron scripts to run LinkController regularly" ],
	 config => [ \&maketrue,
		   "install system config. file /etc/link-control.pl" ],
	 "user-config" => [ \&maketrue,
		   "install linkcont config. in ~linkcont/.link-control.pl" ],
	 directory => [ \&maketrue,
		   "make LinkController working directory" ],
	 "linkcont-user" => [ \&maketrue,
		   "create $::LC_USER user for file ownership" ],
	 all => [ sub {  $::all=1; $::cron=1; $::config=1; $::directory=1;
			$::linkcont_user=1; $::user_config=1; },
		   "Same as --cron --config --directory --create-user" ],
	 disable => [ \&maketrue,
		   "uninstall/deactivate rather than installing/activating" ],
	};
}
$::opthandler->std_opts;

$::opthandler->check_opts;

sub usage() {
  print <<EOF;
default-install [options]

EOF
  $::opthandler->list_opts;
  print <<EOF;

Setup LinkController to work in the default way, activating it as a
service for everybody on the system to use.

Default way:
default-install --all --user=[USERNAME]
EOF

}

sub version() {
  print <<'EOF';
default-install version
$Id: default-install.pl,v 1.9 2002/01/06 10:38:31 mikedlr Exp $
EOF
}

$::LOG_FILE=$base_dir . $::LOG_FILE_INSTALL;
$::LC_DIR=$base_dir . $::LC_DIR_INSTALL;

#log information may be privilaged.  Some people might not want others
#to know what links they are checking.

#$LOGPERM="700"; #FIXME : not used??


$::DAILY_FILE_INSTALL="/etc/cron.daily/link-controller";
$::DAILY_FILE =$base_dir . $::DAILY_FILE_INSTALL;
$::DAILY_SCRIPT = <<"EOF";
#!/bin/sh
exec >> $::LOG_FILE_INSTALL 2>&1
echo Starting Daily Link Checking `date`
TODAYFILE=`date '+links-%Y-%d-%m'`

su - $::LC_USER -c \\
  "copy-links-from-users --group $::LC_USER > $::LC_DIR_INSTALL/\$TODAYFILE"
su - $::LC_USER -c \\
  "extract-links --in-url-list $::LC_DIR_INSTALL/\$TODAYFILE"
su - $::LC_USER -c "build-schedule --verbose"
su - $::LC_USER -c "test-link --verbose"
echo Finished Daily Link Checking `date`
EOF

$::WEEKLY_FILE_INSTALL = "/etc/cron.weekly/link-controller";
$::WEEKLY_FILE =$base_dir . $::WEEKLY_FILE_INSTALL;
$::WEEKLY_SCRIPT = <<"EOF";
#!/bin/sh
#exec >> $::LOG_FILE_INSTALL 2>&1
#su linkcont -c clean-database
#no clean database is needed right now..
EOF

$::CONFIG_FILE_INSTALL = "/etc/link-control.pl";
$::CONFIG_FILE =$base_dir . $::CONFIG_FILE_INSTALL;
$::CONFIG_SCRIPT = <<'EOF';
#linkcontroller default system wide configuration file..  See man
#page for WWW::Link_Controller::ReadConf for details.

use vars qw($schedule $links $page_index $link_index $fixlink_cgi);

#we don't put the user address here since one of your users might run this
#you shouldn't really run link-controller as root anyway..
#$::user_address="root@" . $hostname;

$::schedule="/var/lib/linkcontroller/schedule.bdbm";
$::links="/var/lib/linkcontroller/links.bdbm";
$::page_index="/var/lib/linkcontroller/page_has_link.cdb";
$::link_index="/var/lib/linkcontroller/link_on_page.cdb" ;
$::infostrucs="/var/lib/linkcontroller/infostrucs" ;

#$::fixlink_cgi=
#   "http://$realhostname/cgi-bin/users/$realusername/fix-link.cgi";

1;
EOF

$::USER_CONFIG_FILE_INSTALL = "$::LC_DIR_INSTALL/.link-control.pl";
$::USER_CONFIG_FILE =$base_dir . $::USER_CONFIG_FILE_INSTALL;
$::USER_CONFIG_SCRIPT = <<'EOF';

#default configuration file for link-controller user.  Sets the email
#address to root@[this host] to guarantee that something that is likely
#to get a response is sent.  You should probably change this.

use vars qw($user_address $hostname);

require "hostname.pl";
$hostname=hostname();

#basic sanity checks on hostname...
#this rejects valid hostnames like
#a-.az
# and
#com (at least I think it's valid)
#if you have such a hostname just comment out the following
#two lines or send in a patch with your hostname..

die "hostname $hostname seems unrealistic"
  unless $hostname=~ m/[a-z].*[a-z0-9]\.[a-z].*[a-z0-9]/;

#it would be a seriously good idea to change this mail address.  When
#you start to put this out into people's server logs, you are bound to
#eventually start getting junkmail.. However we have to make sure that
#any compaints about the behaviour of your robot get back to you to an
#account you read and root seems to be the best hope..

$::user_address="root@" . $hostname;

1;
EOF


sub remove_cron_scripts();
sub delete_user();
sub install_cron_scripts();
sub create_user();

unless ($cron or $user or $config or $linkcont_user or $directory) {
  print STDERR <<EOF;
default-install: no options given.  You must say what to do.

use default-install --help for usage information.
EOF
exit
}

#we write to the LOG file under base dir..

open (LOG, ">>$::LOG_FILE" ) or die "can't open log file script $!";
my $date=`date`;
chomp $date;
print LOG $date, ": default-install run with args ", join (" ", @::ORIG_ARGS), "\n";
close LOG;

if ( $disable ) {
  remove_user_config_file() if $user_config;
  delete_user() if $linkcont_user;
  remove_cron_scripts() if $cron;
  remove_central_config_file() if $config;
  deactivate_users(keys(%users)) if $user;
  delete_workingdir() if $directory;
} else {
  create_user() if $linkcont_user;
  install_cron_scripts() if $cron;
  install_central_config_file() if $config;
  activate_users(keys(%users)) if $user;
  create_workingdir() if $directory;
  install_user_config_file() if $user_config;
  print STDERR "Remember to activate users separately\n" if $all and not $user;
}

open (LOG, ">>$::LOG_FILE" ) or die "can't open log file script $!";
$date=`date`;
chomp $date;
print LOG $date, ": default-install completed with args ", join (" ", @::ORIG_ARGS), "\n";
close LOG;

print STDERR "default-install completed\n";

exit 0;

sub install_cron_scripts () {
  print STDERR "installing cron scripts\n" if $verbose;
  -e $::DAILY_FILE and warn "The file $::DAILY_FILE already exists";
  -e $::WEEKLY_FILE and warn "The file $::WEEKLY_FILE already exists";
    open (DAILY, ">$::DAILY_FILE" ) or die "can't open daily script $!";
    eval {
	print DAILY $::DAILY_SCRIPT or die "writing daily script failed $!";
	close (DAILY) or die "close failed" ;
	system ('chmod', '+x', $::DAILY_FILE ) and die "chmod failed";
	$? & 127 and die "chmod recieved signal";
	$? & 128 and die "chmod dumped core";
	1;
    } or do {
	#close file in case we created it.
	#it's too late to worry about the exit status
	close(DAILY);
	unlink $::DAILY_FILE  or warn "couldn't unlink $::DAILY_FILE";
	die $@;
    };
    # ignored race condition here.  It's possible to create the weekly
    # file after our test of existence and then to have us delete it.
    # This could happen e.g. if the program ran twice at the same time..
    eval {
	open (WEEKLY, ">$::WEEKLY_FILE" ) or die "lc daily no open";
	print WEEKLY $::WEEKLY_SCRIPT or die "writing weekly script failed $!";
	close WEEKLY or die "closing weekly script failed $!";
	system ('chmod', '+x', $::WEEKLY_FILE ) and die "chmod failed";
	$? & 127 and die "chmod recieved signal";
	$? & 128 and die "chmod dumped core";
	1;
    } or do {
	#close file in case we created it.
	#it's too late to worry about the exit status
	close (WEEKLY);
	unlink $::DAILY_FILE or
	  warn "couldn't unlink $::DAILY_FILE after failure";
	unlink $::WEEKLY_FILE or
	  warn "couldn't unlink $::WEEKLY_FILE after failure";
	die $@;
    };
}

sub remove_cron_scripts () {
  print STDERR "removing cron scripts\n" if $verbose;
  unlink $::DAILY_FILE or warn "deleting daily script failed $!";
  unlink $::WEEKLY_FILE or warn "deleting weekly script failed $!";
}

sub install_central_config_file () {
  print STDERR "installing central configuration script\n" if $verbose;
  -e $::CONFIG_FILE and do {
    warn "The file $::CONFIG_FILE already exists; not overwriting";
    return 0;
  };
  open (CONFIG, ">$::CONFIG_FILE" ) or die "can't open config script $!";
  eval {
    print CONFIG $::CONFIG_SCRIPT or die "writing config script failed $!";
	close (CONFIG) or die "close failed" ;
	system ('chmod', '+x', $::CONFIG_FILE ) and die "chmod failed";
	$? & 127 and die "chmod recieved signal";
	$? & 128 and die "chmod dumped core";
	1;
    } or do {
	#close file in case we created it.
	#it's too late to worry about the exit status
	close(CONFIG);
	unlink $::CONFIG_FILE  or warn "couldn't unlink $::CONFIG_FILE";
	die $@;
    };
    # ignored race condition here.  It's possible to create the weekly
    # file after our test of existence and then to have us delete it.
    # This could happen e.g. if the program ran twice at the same time..
}

sub remove_central_config_file () {
  if (-e $::CONFIG_FILE ) {
    open (CONFIG, $::CONFIG_FILE);
    my $config;
    while (<CONFIG>) {
      $config .= $_;
    }
    unless ($config eq $::CONFIG_SCRIPT) {
      warn "$::CONFIG_FILE has been edited (or is old).  Delete by hand";
      return 0;
    }
  }

  print STDERR "removing central config script\n" if $verbose;
  unlink $::CONFIG_FILE or warn "deleting config script failed $!";
}

sub install_user_config_file () {
  print STDERR "installing user configuration script\n" if $verbose;
  -e $::USER_CONFIG_FILE and do {
    warn "The file $::USER_CONFIG_FILE already exists; not overwriting";
    return 0;
  };
  open (CONFIG, ">$::USER_CONFIG_FILE" ) or die "can't open config script $!";
  eval {
    print CONFIG $::USER_CONFIG_SCRIPT or die "writing config script failed $!";
	close (CONFIG) or die "close failed" ;
	system ('chmod', '+x', $::USER_CONFIG_FILE ) and die "chmod failed";
	$? & 127 and die "chmod recieved signal";
	$? & 128 and die "chmod dumped core";
	1;
    } or do {
	#close file in case we created it.
	#it's too late to worry about the exit status
	close(CONFIG);
	unlink $::USER_CONFIG_FILE  or warn "couldn't unlink $::USER_CONFIG_FILE";
	die $@;
    };
    # ignored race condition here.  It's possible to create the weekly
    # file after our test of existence and then to have us delete it.
    # This could happen e.g. if the program ran twice at the same time..
}

sub remove_user_config_file () {
  if (-e $::USER_CONFIG_FILE ) {
    open (CONFIG, $::USER_CONFIG_FILE);
    my $config;
    while (<CONFIG>) {
      $config .= $_;
    }
    unless ($config eq $::USER_CONFIG_SCRIPT) {
      warn "$::USER_CONFIG_FILE has been edited (or is old).  Delete by hand";
      return 0;
    }
  }

  print STDERR "removing user config script\n" if $verbose;
  unlink $::USER_CONFIG_FILE or warn "deleting user config script failed $!";
}

sub create_user () {
  my $uid = getpwnam($::LC_USER);
  if ( $uid ) {
    warn "Not creating user $::LC_USER; exists with UID $uid";
    return 0;
  }
  my ($name,$passwd,$gid,$members) = getgrnam($::LC_GROUP);
  unless ($gid) {
    print STDERR "creating $::LC_GROUP group\n" if $verbose;
    system ( 'groupadd', '-r', $::LC_GROUP)
  }

  print STDERR "creating $::LC_USER user\n" if $verbose;
  #FIXME check for existing user
  system ( 'useradd', '-c', 'LinkController service', #comment
	   '-d', $::LC_DIR_INSTALL, #homedir
	   '-M', #we don't need a homedir 'cos we should work in /var
	   #'-o', #FIXME postgress shares UIDS.  I don't understand why.
	   #'-u', '26', # they also specify a UID!!!
	   '-r', #create a system account
	   '-g', $::LC_GROUP,
	   '-s', '/bin/bash', #seems fine to me
	   $::LC_USER ) and do {
	     #FIXME.. we should probably only unlink if we just created!!??
	     warn "couldn't create the $::LC_USER user";
	     unlink $::DAILY_FILE or warn "couldn't unlink $::DAILY_FILE";
	     unlink $::WEEKLY_FILE or warn "couldn't unlink $::WEEKLY_FILE";
	     die "aborted due to errors";
	   };
}


sub delete_user () {
  print STDERR "deleting linkcont user\n" if $verbose;
  system ( 'userdel', $::LC_USER ) && do {
	     warn "couldn't delete the $::LC_USER user";
	     return 0;
	   };

  print STDERR "deleting $::LC_GROUP group\n" if $verbose;

  my ($name,$passwd,$gid,$members) = getgrnam($::LC_GROUP);
  if ($gid) {
    $members && do {
      print STDERR "Group $::LC_GROUP is not empty.  Not deleting\n"
	if $verbose;
      return ;
    };
    print STDERR "deleting $::LC_GROUP group\n" if $verbose;
    system ( 'groupdel', $::LC_GROUP)
  }
}

sub activate_users (@) {
  my @users=@_;
  my ($name,$passwd,$gid,$members) = getgrnam($::LC_USERS_GROUP);
  unless ($gid) {
    print STDERR "creating $::LC_USERS_GROUP group\n" if $verbose;
    system ( 'groupadd', $::LC_USERS_GROUP );
  }

  print STDERR "activating given users " , join( ' ', @users) ,"\n"
    if $verbose;
  foreach my $user (@users) {
    my $groups=`id -Gn $user`;
    chomp $groups;
    $groups .= " $::LC_USERS_GROUP";
    $groups =~ s/ /,/g;
    system ("usermod", '-G', $groups, $user);
  }
}

sub deactivate_users (@) {
  print STDERR "deactivating given users\n" if $verbose;
  my @users=@_;
  foreach $user(@users) {
    #list current groups
    my $groups=`id -Gn`;
    die "no groups found for user $user" unless $groups;
    my @groups=split(/ /, $groups);
    my @newgroups=();
    #delete our group
    foreach my $group(@groups) {
      push @newgroups, $group unless $group eq $::LC_USERS_GROUP;
    }
    #apply
    system ( 'usermod', '-G', join (',', @newgroups), $user ) || do {
	     warn "couldn't activate user $user";
	     unlink $::DAILY_FILE or warn "couldn't unlink $::DAILY_FILE";
	     unlink $::WEEKLY_FILE or warn "couldn't unlink $::WEEKLY_FILE";
	     die "aborted due to errors";
	   };
  }
}

sub create_workingdir () {
  if (-d $::LC_DIR ) {
    warn "LinkController Working directory $::LC_DIR already present";
  } else {
    mkpath("$::LC_DIR") or warn "working directory creation failed";
    my ($login,$pass,$uid,$gid) = getpwnam($::LC_USER)
        or die "$::LC_USER user not in passwd file.  Can't create directory.";
    chown ($uid, $gid, $::LC_DIR);
  }
}

sub delete_workingdir () {
  if (-d $::LC_DIR ) {
    #fixme: delete even in the presence of certain dotfiles:
    # .bashrc .xauth
    rmdir($::LC_DIR) or warn "working directory ($::LC_DIR) deletion failed $!";
  } else {
    warn "LinkController Working directory $::LC_DIR not present";
  }
}




