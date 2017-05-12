# $Id: Admin.pm,v 1.8 2007-12-13 17:09:03 mike Exp $

# This is the only module that needs to be explicitly "use"d by the
# HTML::Mason components that make up the sites.  It is responsible,
# among other things, for "use"ing all the relevant sub-modules.

package Keystone::Resolver::Admin;
use strict;
use warnings;

use Keystone::Resolver;


# PRIVATE to admin(), which implements a singleton
my $_admin = undef;

# Returns an object -- always the same one -- representing the
# Keystone Resolver Admin complex-of-web-site as a whole, and through
# which global functionality and objects (such as the database handle)
# can be accessed.
#
sub admin {
    my $class = shift();

    if (!defined $_admin) {
	$_admin = bless {
	    resolver => undef,
	    sites => {},
	}, $class;
    }

    return $_admin;
}


sub resolver {
    my $this = shift();

    if (!defined $this->{resolver}) {
	### This should be a setting
	my $loglevel = (
#			Keystone::Resolver::LogLevel::CHITCHAT |
			Keystone::Resolver::LogLevel::CACHECHECK |
			Keystone::Resolver::LogLevel::PARSEXSLT |
			Keystone::Resolver::LogLevel::DUMPDESCRIPTORS |
			Keystone::Resolver::LogLevel::DUMPREFERENT |
			Keystone::Resolver::LogLevel::SHOWGENRE |
#			Keystone::Resolver::LogLevel::DBLOOKUP |
			Keystone::Resolver::LogLevel::MKRESULT |
#			Keystone::Resolver::LogLevel::SQL |
			Keystone::Resolver::LogLevel::DEREFERENCE |
			Keystone::Resolver::LogLevel::DISSECT |
			Keystone::Resolver::LogLevel::RESOLVEID |
			Keystone::Resolver::LogLevel::CONVERT01 |
			Keystone::Resolver::LogLevel::HANDLE |
			Keystone::Resolver::LogLevel::WARNING |
			0);
	$this->{resolver} = new Keystone::Resolver(logprefix => "admin",
						   _rw => 1,
						   loglevel => $loglevel);
    }

    return $this->{resolver};
}


# Delegations to the associated resolver
sub db { shift()->resolver()->db(@_) }


# This method contains the algorithm for determining, based on the
# hostname by which the web server is accessed, which if any of the
# available sites should be used.
#
sub hostname2tag {
    my $this = shift();
    my($hostname) = @_;

    $hostname =~ s/^x\.//;	# Development versions begin with "x."
    $hostname =~ s/:\d+$//;	# Discard any trailing port-number

    my $tag;
    if ($hostname eq "resolver.indexdata.com") {
	$tag = "id";
    } 
    else {
	$tag = $hostname;
	$tag =~ s/\..*//;
    }

    return $tag;
}


# Returns the site object associated in the admin-object with the
# specified tag, creating it if necessary.
#
sub site {
    my $this = shift();
    my($tag) = @_;

    if (!defined $this->{sites}->{$tag}) {
	$this->{sites}->{$tag} = $this->db()->site_by_tag($tag);
    }

    return $this->{sites}->{$tag};
}


1;
