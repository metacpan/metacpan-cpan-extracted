#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

$PACKAGE = 'Dunce::Files';
($PACKAGE_FILE = $PACKAGE) =~ s|::|/|g;
$LAST_API_CHANGE = 0;

eval "require $PACKAGE";

unless ($@) { # Make sure we did find the module.
    print <<"CHANGE_WARN" if ${$PACKAGE.'::VERSION'} < $LAST_API_CHANGE;

NOTE: There have been API changes between this version and any older
than version $LAST_API_CHANGE!  Please read the Changes file if you
are upgrading from a version older than $LAST_API_CHANGE.

CHANGE_WARN
}

WriteMakefile(
    NAME            => 'Dunce',
    VERSION_FROM    => "lib/$PACKAGE_FILE.pm",
    PREREQ_PM       => { 
                        'Function::Override'     => 0.03,
                        'Test::More'             => 0.42,
                       },
);
