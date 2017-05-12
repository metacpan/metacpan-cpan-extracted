# A template for Makefile.PL used by Arena Networks.
# - Set the $PACKAGE variable to the name of your module.
# - Set $LAST_API_CHANGE to reflect the last version you changed the API 
#   of your module.
# - Fill in your dependencies in PREREQ_PM
# Alternatively, you can say the hell with this and use h2xs.
use ExtUtils::MakeMaker;
use strict;

my $PACKAGE = 'IP::Country::DNSBL';
(my $PACKAGE_FILE = $PACKAGE) =~ s|::|/|g;
my $LAST_API_CHANGE = 1.00;
my $CURR_VERSION;
eval "require $PACKAGE;\n\$CURR_VERSION = \$$PACKAGE"."::VERSION;";

unless ($@) { # Make sure we did find the module.
    if( $CURR_VERSION < $LAST_API_CHANGE ) {
        print "-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-\n".
	    "NOTE: There have been API changes between this version and any older\n".
	    "      than version $LAST_API_CHANGE! It seems that you have a copy\n".
	    "      of this software installed with a version number of $CURR_VERSION.\n".
	    "      Please read the CHANGES file if you have been building software\n".
	    "      that relies on a previous version of this software.\n".
	    "-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-\n";
        sleep 5;
    }
}

WriteMakefile(
	      NAME          => $PACKAGE,
	      VERSION_FROM  => "lib/$PACKAGE_FILE.pm", # finds $VERSION
	      PREREQ_PM     => { 'Net::DNS' => 0 },
	      AUTHOR        => 'Nigel Wetters Gourlay <nwetters@cpan.org>',
	      ABSTRACT_FROM => "lib/$PACKAGE_FILE.pm"
	      );

