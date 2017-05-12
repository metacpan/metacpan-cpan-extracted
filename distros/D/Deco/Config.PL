# install config files
use strict;
use ExtUtils::Install;
use ExtUtils::MakeMaker;

my $INSTALL_FILE = '.install_conf';
my $CONFDIR;

if (-e $INSTALL_FILE) {
    # on the second run (make install) we do the real install
    open (IN, $INSTALL_FILE) || die "Can't open $INSTALL_FILE for reading";
    $CONFDIR = <IN>;
    close IN;
    if (! -d $CONFDIR) {
	print "$CONFDIR does not exist. Creating directory ....\n";
	mkdir $CONFDIR, 0644;
    }
    install( { conf => $CONFDIR} );
    unlink($INSTALL_FILE);

} else {
    # prompt for conf dir
    $CONFDIR = $ENV{HOME} . '/conf/';
    my $answer = ExtUtils::MakeMaker::prompt("Where should the config files be placed? ", $CONFDIR);
    if ($answer =~ /^\s*$/) {
	# default
    } else {
	$CONFDIR = $answer;
    }
    open (OUT, ">$INSTALL_FILE") || die "Can't open $INSTALL_FILE for writing";
    print OUT $CONFDIR;
    close OUT;
}

