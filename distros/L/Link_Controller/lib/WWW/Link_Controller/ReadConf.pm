#Configuration - we go through %ENV, so you'd better not be running SUID
#eval to ignore if a file doesn't exist.. e.g. the system config
package WWW::Link_Controller::ReadConf;
$REVISION=q$Revision: 1.4 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );
use vars qw($VERSION);
$VERSION=0.002;

package main;

#declare variables to allow partially configured setups to work.

use vars qw($user_address $schedule $links $page_index $link_index
	    $fixlink_cgi);

#FIXME: we should check that the modes of these files are such that
#they cannot be modified by people other than the user.

BEGIN { eval { require "/etc/link-control.pl"; }; #FIXME local setup
	$DB::single = 1;
	die "System config failed: $@"
	  if $@ and not $@ =~ m/Can't locate/;
	eval { require $ENV{"HOME"} . "/.link-control.pl"; } if $ENV{"HOME"};
        die "User config failed: $@"
	  if $@ and not $@ =~ m/Can't locate/;

	if ( defined $::base_dir ) {

	  -e $::base_dir or do {
	    mkdir $::base_dir;
	    die "couldn't create base directory $::base_dir" unless -d $::base_dir;
	  };
	  die "config directory $::base_dir isn't a directory" unless -d $::base_dir;

	  $::links="$::base_dir/links.bdbm" unless defined $::links;
	  $::page_index="$::base_dir/page_has_link.cdb" unless defined $::page_index;
	  $::link_index="$::base_dir/link_on_page.cdb" unless defined $::link_index;
	  $::schedule="$::base_dir/schedule.bdbm" unless defined $::schedule;
	  $::infostrucs="$::base_dir/infostrucs"  unless defined $::infostrucs;
	}

	$::max_link_age=100; #days after which we delete link records

      };

return 1; #cocaine.  It's just like giving free cocaine to an addict.
          #that's what it is.

__END__


=head1 NAME

WWW::Link_Controller::ReadConf - Read LinkController configuration files.

=head1 SYNOPSIS

   use WWW::Link_Controller::ReadConf;
   print $::links;

=head1 DESCRIPTION

This moduleis a way of reading the config file into each of the
LinkController programs.  All it does is require a file.

    /etc/link-control.pl

followed by

    $ENV{"HOME"} . "/.link-control.pl"

but that works for now.

In order to avoid reading the home directory, unset the $ENV{"HOME"}
variable.

=head1 VARIABLES

 $user_address - email address of the user - for use when testing
    links to allow contact from web adminstrators if anything goes
    wrong.  This must be set to your email address

 $links - filname of database database containing information about the
    status of each individual link

 $schedule - filename of database of times when links should be tested.

 $page_index - filename of index in which we can look up a page and
    find out which links it has

 $link_index - filename of index in whcih we can look up a link and see
    which pages it occurs on

 $fixlink_cgi - url which leads to the active cgi script for fixing
    links.

 $max_link_age - age after which we delete links from the database

=head1 BUGS

Should allow to override the files.

=head1 SEE ALSO

WWW::Link_Controller(1)

=cut
