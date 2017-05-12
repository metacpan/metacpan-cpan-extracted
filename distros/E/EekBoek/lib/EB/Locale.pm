#! perl

# Locale.pm -- EB Locale setup (core version)
# Author          : Johan Vromans
# Created On      : Fri Sep 16 20:27:25 2005
# Last Modified By: Johan Vromans
# Last Modified On: Tue Aug 14 12:28:39 2012
# Update Count    : 165
# Status          : Unknown, Use with caution!

package EB::Locale;

# IMPORTANT:
#
# This module is used (require-d) by module EB only.
# No other modules should try to play localisation tricks.
#
# Note: Only _T must be defined. The rest is defined in EB::Utils.

use strict;

use constant COREPACKAGE => "ebcore";

use base qw(Exporter);

our @EXPORT_OK = qw(_T);
our @EXPORT = @EXPORT_OK;

# This module supports three different gettext implementations.

use POSIX qw(setlocale);

my $core_localiser;
our $LOCALISER;			# for outside checking

sub LC_MESSAGES {
    eval { POSIX::LC_MESSAGES() } || 5;
}

sub __init__ {
    return if $core_localiser;

    # Since EB is use-ing Locale, we cannot use the EB exported libfile yet.
    my $dir = EB::libfile("locale");

    # Use outer settings.
    setlocale(LC_MESSAGES);

    # Try Locale::gettext
    eval {
	require Locale::gettext;
	$core_localiser = Locale::gettext->domain(COREPACKAGE);
	$core_localiser->dir($dir);
	eval 'sub _T { $core_localiser->get($_[0]) }';
	$LOCALISER = "Locale::gettext";
    } and return;

    # Try Locale::Messages (part of libintl-perl).
    eval {
	require Locale::Messages;
	Locale::Messages::bindtextdomain( COREPACKAGE, $dir );
	Locale::Messages::textdomain(COREPACKAGE);
	eval 'sub _T { package Locale::Messages; turn_utf_8_on(gettext($_[0])) }';
	$LOCALISER = "Locale::Messages";
    } and return;
    return if $core_localiser;

    # Try Locale::gettext_xs (part of libintl-perl).
    eval {
	require Locale::gettext_xs;
	Locale::gettext_xs::bindtextdomain( COREPACKAGE, $dir );
	Locale::gettext_xs::textdomain(COREPACKAGE);
	eval 'sub _T { Locale::gettext_xs::gettext($_[0]) }';
	$LOCALISER = "Locale::gettext_xs";
    } and return;
    return if $core_localiser;

    # Try Locale::gettext_pp (part of libintl-perl).
    eval {
	require Locale::gettext_pp;
	Locale::gettext_pp::bindtextdomain( COREPACKAGE, $dir );
	Locale::gettext_pp::textdomain(COREPACKAGE);
	eval 'sub _T { Locale::gettext_pp::gettext($_[0]) }';
	$LOCALISER = "Locale::gettext_pp";
    } and return;
    return if $core_localiser;

    # Fallback to none.
    unless ( $core_localiser ) {
	$core_localiser = "<dummy>";
	eval 'sub _T { $_[0] };';
	$LOCALISER = "";
    }
}

sub get_language {
    $ENV{LANG};
}

sub set_language {
    # Set/change language.
    setlocale( LC_MESSAGES, $ENV{LANG} = $_[1] );
}

__init__();

1;
