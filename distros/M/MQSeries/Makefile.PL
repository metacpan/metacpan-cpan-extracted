#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Makefile.PL,v 38.2 2012/09/26 16:15:20 jettisu Exp $
#
use English;
use ExtUtils::MakeMaker;
use File::Copy;

#
# Create the MQServer directory and files on the fly.
#
# This used to be a bunch of symlinks, but Win32 makes this
# impractical.  This is already gross enough, so I'm just going to
# copy everything over, and keep it uptodate.  If any of the MQClient
# files changes, then you'll need to re-run the Makefile.PL.
#
# Hmm...  Maybe I can make a bunch of special makefile targets to
# force the update.  Hmm....
#
my %files =
  (
   "MQServer/"				=> 1,
   "MQServer/MQSeries.xs.in/"		=> 1,
   "MQServer/Makefile.PL"		=> "MQClient/Makefile.PL",
   "MQServer/constants.c.PL"		=> "MQClient/constants.c.PL",
   "MQServer/typemap.PL"		=> "MQClient/typemap.PL",
   "MQServer/MQSeries.pm.in"		=> "MQClient/MQSeries.pm.in",
  );

opendir(MQCLIENT,"MQClient/MQSeries.xs.in") ||
  die "Unable to opendir MQClient/MQSeries.xs.in: $ERRNO\n";

foreach ( readdir(MQCLIENT) ) {
    next if /^\.\.?$/;
    next if $_ eq 'RCS';
    next if $_ =~ /~$/;
    $files{"MQServer/MQSeries.xs.in/$_"} = "MQClient/MQSeries.xs.in/$_";
}

closedir(MQCLIENT);

foreach my $dest ( sort keys %files ) {

    if ( $dest =~ m:/$: ) {

	next if -d $dest;
	warn "Creating directory $dest\n";
	mkdir($dest,0755) || die "Unable to mkdir $dest:\n";

    } else {

	my $src = $files{$dest};

	if ( -f $dest ) {
	    my (@src)  = stat($src)  or die "Unable to stat $src: $ERRNO\n";
	    my (@dest) = stat($dest) or die "Unable to stat $dest: $ERRNO\n";
	    next if $dest[9] >= $src[9];
	}

	warn "Copying $src -> $dest\n";

	copy($src,$dest) || die "Unable to copy $src to $dest: $ERRNO\n";

    }

}

WriteMakefile(
	      NAME	   => 'MQSeries',
	      VERSION_FROM => 'MQSeries.pm', # finds $VERSION
              AUTHOR      => 'MQ Engineering Group <mqseries@cpan.org>',
              ABSTRACT	  => "Interface to IBM's MQSeries Product",
	      PREREQ_PM   => { 'Convert::EBCDIC'  => '0.06',
			       'Params::Validate' => '1.00',
			       'Test::Simple'     => '0.62',
			       'Test::Pod'        => '1.20',
			     },
	     );


