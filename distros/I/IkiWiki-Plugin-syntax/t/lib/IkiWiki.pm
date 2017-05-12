#!/usr/bin/perl

#   This module is for debugging only
#

package IkiWiki;
use warnings;
use strict;
use Encode;
use HTML::Entities;
use URI::Escape q{uri_escape_utf8};
use POSIX;
use IO::File;

use HTML::Template;

use vars qw{%config %links %oldlinks %pagemtime %pagectime %pagecase
            %pagestate %renderedfiles %oldrenderedfiles %pagesources
            %destsources %depends %hooks %forcerebuild $gettext_obj};

use Exporter q{import};
our @EXPORT = qw(hook debug error template htmlpage add_depends pagespec_match
                 bestlink htmllink readfile writefile pagetype srcfile pagename
                 displaytime will_render gettext urlto targetpage
                 add_underlay
                 %config %links %pagestate %renderedfiles
                 %pagesources %destsources);
our $VERSION = 2.00; # plugin interface version, next is ikiwiki version
our $version='unknown'; # VERSION_AUTOREPLACE done by Makefile, DNE

### Global configuration
#   Setting a minimal ikiwiki setup
our %config = (
    wikiname => "MyWiki",
	#adminuser => ["yourname", ],
	adminemail => 'me@example.org',

	# Be sure to customise these..
	srcdir => "/path/to/source",
	destdir => "/var/www/wiki",

	url => "http://example.org/wiki",
	cgiurl => "http://example.org/ikiwiki.cgi",
	#templatedir => "/usr/share/ikiwiki/templates",
	underlaydir => ".",
    
    userdir => 'users',

	wrappers => [
	],

	# Generate rss feeds for blogs?
	rss => 1,
	# Generate atom feeds for blogs?
	atom => 1,
	# Include discussion links on all pages?
	discussion => 1,
	# Logging settings:
	verbose => 0,
	syslog => 0,
);

### dummy subroutines
sub hook {

}

sub debug {
    if ($IkiWiki::debug) {
        print STDERR shift,"\n";
    }
}

sub error {
    die @_;
}

sub readfile {
    my  $file       =   shift;
    my  $content    =   undef;

    if (my $fh = IO::File->new( $file )) {
        local $/;
        $content = <$fh>;
        $fh->close;
    }

    return $content;
}

sub srcfile {
    my  $page   =   shift;

    return $page;
}

my %tmpl = ();
my %tmpl_options = (
    die_on_bad_params => 0,
);

sub template {
    my  $name   =   shift;

    if (not defined $tmpl{$name}) {
        my $filename = sprintf 'extras/%s', $name;

        $tmpl{$name} = HTML::Template->new( filename => $filename, 
                           %tmpl_options );
    }

    return $tmpl{$name};
}

sub add_depends {
    return;
}

sub gettext {
    return shift;
}

sub urlto {
    my ($to, $from) = @_;

    return sprintf( "URL from %s to %s", $from || '', $to || '' );
}


1;


