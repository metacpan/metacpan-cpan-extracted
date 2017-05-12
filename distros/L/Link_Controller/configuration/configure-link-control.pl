#!/usr/bin/perl -w

=head1 NAME

configure-link-control - setup configuration files for LinkController

=head1 DESCRIPTION

The aim of this program is to get the default settings for
LinkContoller set up in the file C<.link-control> in the users home
directory.  It does this by asking various questions and then putting
the results into that file.

=head1 BUGS

Interaction with the $::base_dir directory is not handled here.

=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont/ - the
LinkController homepage.

=cut

use WWW::Link_Controller::ReadConf::utils;

use Getopt::Function; #don't need yet qw(maketrue makevalue);

$::opthandler = new Getopt::Function
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
  ],  {};

$::opthandler->std_opts;

$::opthandler->check_opts;

sub usage() {
  print <<EOF;
configure-link-control [options]

EOF
  $::opthandler->list_opts;
  print <<EOF;

Attempt to setup LinkController for basic usage.
EOF
}

sub version() {
  print <<'EOF';
configure-link-control version 
$Id: configure-link-control.pl,v 1.14 2002/01/18 20:32:35 mikedlr Exp $
EOF
}

print <<EOINTRO;
              LinkController Configuration

Welcome to LinkController Configuration.  This program is designed to
set you up ready to use LinkController by setting up the configuration
file .infostruc.pl in your home directory.  The file will just be a
simple perl program so you can either edit it by hand or use this
program again to change it.

EOINTRO

eval { require "/etc/link-control.pl"; }; #FIXME local setup
warn "System config failed: $@"
  if $@ and not $@ =~ m/Can't locate/;

my %sysconfig=();

$sysconfig{"user_address"}=$::user_address if defined $::user_address;
undef $::user_address;
$sysconfig{"links"}=$::links if defined $::links;
undef $::links;
$sysconfig{"schedule"}=$::schedule if defined $::schedule;
undef $::schedule;
$sysconfig{"page_index"}=$::page_index if defined $::page_index;
undef $::page_index;
$sysconfig{"link_index"}=$::link_index if defined $::link_index;
undef $::link_index;

my $homeconfig_file=$ENV{"HOME"} . "/.link-control.pl";
my %homeconfig=();

if (-e $homeconfig_file) {
  yesno (<<'EOQ') and eval "require '$homeconfig_file'";
Do you want to try to load in the configuration in your home directory
to use for defaults?
EOQ
  warn "load failed: $@ - ignoring file.. abort if that's wrong" if $@;
}

$homeconfig{"user_address"}=$::user_address if defined $::user_address;
undef $::user_address;
$homeconfig{"links"}=$::links if defined $::links;
undef $::links;
$homeconfig{"schedule"}=$::schedule if defined $::schedule;
undef $::schedule;
$homeconfig{"page_index"}=$::page_index if defined $::page_index;
undef $::page_index;
$homeconfig{"link_index"}=$::link_index if defined $::link_index;
undef $::link_index;

my %config=();

if ($homeconfig{"user_address"}) {
  $config{"user_address"} = getstring( <<EOQ, $homeconfig{"user_address"});
What is your email address?  Press return to use the same as before.
EOQ
} else {
  $config{"user_address"} = 
    getstring( <<EOQ ) while not defined $config{"user_address"};
What is your email address?  You must give this if you want to do link
testing because test-link will not work without it.
EOQ
}


print "\n";

CASE: {
  $homeconfig{"links"} && do  {
    $config{"links"} = getstring( <<EOQ, $homeconfig{"links"});
Where do you store your links database?  Please give the full path to
the file.  You can use '~/' to indicate your home directory.
Press return to use the same as before:
  $homeconfig{"links"}
Type a single r and this will be reset to use the system configuration.
EOQ
    last CASE;
  };
  $sysconfig{"links"} && do  {
    $config{"links"} = getstring( <<EOQ );
Where do you store your links database?  The system defines
   $sysconfig{"links"}
press return and we will just use the system configuration.
EOQ
    last CASE;
  };
  $config{"links"} = getstring( <<EOQ )  while not defined $config{"links"};
Where do you store your links database?  You must give a file location
as there isn't any information on this.
EOQ
}

print "\n";

CASE: {
  $homeconfig{"page_index"} && do  {
    $config{"page_index"} = getstring( <<EOQ, $homeconfig{"page_index"});
Where do you store your page_index database?  Please give the full path to
the file.  You can use '~/' to indicate your home directory.
Press return to use the same as before:
  $homeconfig{"page_index"}
Type a single r and this will be reset to use the system configuration.
EOQ
    last CASE;
  };
  $sysconfig{"page_index"} && do  {
    $config{"page_index"} = getstring( <<EOQ );
Where do you store your page_index database?  The system defines
   $sysconfig{"page_index"}
press return and we will just use the system configuration.
EOQ
    last CASE;
  };
  $config{"page_index"} = getstring( <<EOQ );
Where do you store your page_index database?  If you don't give this
then you won't be able to report which pages contain a given link.
EOQ
}

print "\n";

CASE: {
  $homeconfig{"link_index"} && do  {
    $config{"link_index"} = getstring( <<EOQ, $homeconfig{"link_index"});
Where do you store your link_index database?  Please give the full path to
the file.  You can use '~/' to indicate your home directory.
Press return to use the same as before:
  $homeconfig{"link_index"}
Type a single r and this will be reset to use the system configuration.
EOQ
    last CASE;
  };
  $sysconfig{"link_index"} && do  {
    $config{"link_index"} = getstring( <<EOQ );
Where do you store your link_index database?  The system defines
   $sysconfig{"link_index"}
press return and we will just use the system configuration.  If your
system administrator runs link checking for you then don't change
this.
EOQ
    last CASE;
  };
  $config{"link_index"} = getstring( <<EOQ );
Where do you store your link_index database?  If you don't give this
then you won't be able to report which links are on a given page.
EOQ
}

print "\n";

CASE: {
  $homeconfig{"schedule"} && do  {
    $config{"schedule"} = getstring( <<EOQ, $homeconfig{"schedule"});
Where do you store your link checking schedule?  Please give the 
full path to the file.  You can use '~/' to indicate your home directory.
Press return to use the same as before:
  $homeconfig{"schedule"}
Type a single r and this will be reset to use the system configuration.
EOQ
    last CASE;
  };
  $sysconfig{"schedule"} && do  {
    $config{"schedule"} = getstring( <<EOQ );
Where do you store your link checking schedule?  The system defines
   $sysconfig{"schedule"}
press return and we will just use the system configuration.  You need
to set this if you want to run your own link checking separately from
the system administrator.  Otherwise it's better to stick with the 
administrator doing this and there's no need to worry.
EOQ
    last CASE;
  };
  $config{"schedule"} = getstring( <<EOQ );
Where do you store your link checking schedule?  You need this in order to
be able to run link checking yourself.  
EOQ
}

CASE: {
  $homeconfig{"infostrucs"} && do  {
    $config{"infostrucs"} = getstring( <<EOQ, $homeconfig{"infostrucs"});

Where do you keep your infostrucs file.  This defines where your web
pages to be checked are and which files create them.  Give the
full path to the file.  You can use '~/' to indicate your home directory.
Press return to use the same as before:
  $homeconfig{"infostrucs"}
Type a single r and this will be reset to use the system configuration.
EOQ
    last CASE;
  };
  $sysconfig{"infostrucs"} && do  {
    $config{"infostrucs"} = getstring( <<EOQ );
Where do you keep your infostrucs file.  This defines where your web
pages to be checked are and which files create them.  Give the
full path to the file.  You can use '~/' to indicate your home directory.

The system defines
   $sysconfig{"infostrucs"}
press return and we will just use the system configuration.  You need
to set this to a file which points to your web pages.
EOQ
    last CASE;
  };
  $config{"infostrucs"} = getstring( <<EOQ );
Where do you keep your infostrucs file.  This defines where your web
pages to be checked are and which files create them.  Give the
full path to the file.  You can use '~/' to indicate your home directory.
EOQ
}


foreach my $var ( qw(link_index page_index links infostrucs) ) {
  defined $config{$var} or next;
  $config{"$var"} =~ m,^r$, and delete $config{"$var"};
  defined $config{$var} or next;
  $config{"$var"} =~ s,^~/,$ENV{"HOME"}/,;
}


rename $homeconfig_file . '.bak', $homeconfig_file . '.bak.bak'
  if -e $homeconfig_file . ".bak" and -e $homeconfig_file;
rename $homeconfig_file, $homeconfig_file . '.bak'
  or die "couldn't make backup of old configuration file,"
  if -e $homeconfig_file;
open CONFIG, ">$homeconfig_file"
  or die "unable to write to " . $homeconfig_file . ": ". $!;
print CONFIG <<'EOF';
#Automatically generated config file for LinkController.  Maybe you
#want to use the configuration utility configure-link-control?
use vars qw($schedule $links $page_index $link_index $fixlink_cgi
	    $user_address $infostrucs);
EOF

print CONFIG <<"EOF";
\$::user_address = '$config{"user_address"}';
EOF

%comments=
  ( '$::links' => '$::links - filename of database of link information',
    '$::page_index' => '$::page_index - filename of links on page index',
    '$::link_index' => '$::link_index - filename of page with links index',
    '$::schedule' => '$::schedule - link testing schedule filename',
    '$::fixlink_cgi' => '$::fixlink_cgi - URL of linkfixing CGI',
    '$::infostrucs' => '$::infostrucs - File defining where we keep our web pages',
  );

foreach my $varname ( qw($::links $::page_index $::link_index $::schedule
                         $::fixlink_cgi $::infostrucs) ) {
  my $configname = $varname;
  $configname =~ s/^\$:://;
  print CONFIG '#' . $comments{$varname} . "\n";
  if ( $config{$configname} ) {

    print CONFIG <<"EOF" ;
$varname="$config{$configname}" ;
EOF

  } else {

    print CONFIG <<"EOF" ;
#$varname="xxxx" ;
1; #allows file to be required
EOF

  }
}
close CONFIG or die "closing config file failed" . $!;

print << "EOF";
Your configuration has been written.  You can edit it in $homeconfig_file.
EOF

if ( $config{infostrucs} ) {
  -e $config{infostrucs} && do {
    print <<EOF;
The infostrucs file already exists.  We will stop configuration here.
Delete it if you would like to recreate it.
EOF
      exit;
  }; 

    my $directory=getstring( <<EOQ );
In which directory do you keep your web pages?  Leave empty if there
is no directory
EOQ
  my $baseurl=getstring( <<EOQ );
What is the baseurl of your web pages (e.g. http://www.example.com/)?
EOQ

  if ($baseurl) {
    open INFOS, ">" . $config{infostrucs}
      or die "couldn't open infostrucs file " . $config{infostrucs};
    if ( $directory ) {
      print INFOS "directory $baseurl $directory\n";
    } else {
      print INFOS "www $baseurl\n";
    }

  } else { 
    warn <<EOF;
We can not generate an infostruc file without a baseurl.  Please look
in the LinkController manual for details about how this file should be
built.
EOF
  }
}
1;


