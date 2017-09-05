#! perl --			-*- coding: utf-8 -*-

use utf8;

# EB.pm -- EekBoek Base module.
# Author          : Johan Vromans
# Created On      : Fri Sep 16 18:38:45 2005
# Last Modified By: Johan Vromans
# Last Modified On: Thu Aug 31 09:57:36 2017
# Update Count    : 331
# Status          : Unknown, Use with caution!

package main;

our $app;
our $cfg;

package EB;

use strict;
use base qw(Exporter);

use EekBoek;

our @EXPORT;
our @EXPORT_OK;

# Establish location of our run-time resources.
my $lib;
sub libfile {
    my ($f) = @_;

    unless ( $lib ) {
	# Packaged.
	if ( $App::Packager::PACKAGED ) {
	    return App::Packager::GetResourcePath()."/$f";
	}
	else {
	    $lib = $INC{"EB.pm"};
	    $lib =~ s/EB\.pm$//;
	}
    }
    $lib."EB/res/$f";
}

sub findlib {
    my ( $file, $section ) = @_;

    # The two-argument form supports locale-dependent paths, but
    # we hard-wire this to 'nl'.
    if ( $section ) {
	my $lang = 'nl';
	my $found = findlib( "$section/$lang/$file" );
	return $found if $found;
	$found = findlib( "$section/$file" );
	return $found if $found;
	return undef;
    }

    # Packaged.
    if ( $App::Packager::PACKAGED ) {
	my $found = App::Packager::GetUserFile($file);
	return $found if -e $found;
	$found = App::Packager::GetResource($file);
	return $found if -e $found;
    }

    foreach ( @INC ) {
	return "$_/EB/user/$file" if -e "$_/EB/user/$file";
	return "$_/EB/res/$file"  if -e "$_/EB/res/$file";
	return "$_/EB/$file"      if -e "$_/EB/$file";
    }
    undef;
}

use lib ( grep { defined } findlib("CPAN") );

# Some standard modules (locale-free).
use EB::Globals;
use Carp;
use Data::Dumper;
use EB::Utils;

# We need a glob() that deals with spaces.
use File::Glob ( $] >= 5.016 ? ":bsd_glob" : ":glob" );

# Even though we do not use translations, most of the code is in place.
sub _T { $_[0] }

# Export our and the imported globals.
@EXPORT = ( @EB::Globals::EXPORT,
	    @EB::Utils::EXPORT,
	    "_T",
	    qw(carp croak confess),	# Carp
	    qw(glob),			# File::Glob
	    qw(Dumper),			# Data::Dumper
	    qw(findlib libfile),	# <self>
	  );

our $ident;
our $imsg;
my $imsg_saved;
our $url = "http://www.eekboek.nl";

sub __init__ {
    $imsg_saved = $imsg || "";

    my $year = 2005;
    my $thisyear = (localtime(time))[5] + 1900;
    $year .= "-$thisyear" unless $year == $thisyear;
    $ident = __x("{name} {version}",
		 name    => $EekBoek::PACKAGE,
		 version => $EekBoek::VERSION);
    $imsg = __x("{ident}{extra} -- Copyright {year} Squirrel Consultancy",
		ident   => $ident,
		extra   => ($app ? " Wx" : ""),
		year    => $year);
    if ( $imsg ne $imsg_saved
	 && !( @ARGV && $ARGV[0] =~ /-(P|-?printconfig)$/ )
       ) {
	warn($imsg, "\n");
    }

    eval {
	require Win32;
	my @a = Win32::GetOSVersion();
	my ($id, $major) = @a[4,1];
	die unless defined $id;
	warn(_T("EekBoek is VRIJE software, ontwikkeld om vrij over uw eigen gegevens te kunnen beschikken.")."\n");
	warn(_T("Met uw keuze voor het Microsoft Windows besturingssysteem geeft u echter alle vrijheden weer uit handen. Dat is erg triest.")."\n");
    } unless $imsg_saved eq $imsg || $ENV{AUTOMATED_TESTING};

}

sub app_init {
    shift;			# 'EB'

    # Load a config file.
    require EB::Config;
    undef $::cfg;
    EB::Config->init_config( @_ );

    # Main initialisation.
    __init__();

    # Initialise locale-dependent formats.
    require EB::Format;
    EB::Format->init_formats();

    return $::cfg;		# until we've got something better
}

sub EB::Config::Handler::connect_db {
    # Connect to the data base.
    require EB::DB;
    EB::DB::->connect;
}

1;

__END__

=head1 NAME

EB - EekBoek * Bookkeeping software for small and medium-size businesses

=head1 SYNOPSIS

EekBoek is a bookkeeping package for small and medium-size businesses.
Unlike other accounting software, EekBoek has both a command-line
interface (CLI) and a graphical user-interface (GUI). Furthermore, it
has a complete Perl API to create your own custom applications.

=head1 DESCRIPTION

For a description how to use the program, see L<http://www.eekboek.nl/docs/index.html>.

=head1 BUGS AND PROBLEMS

Please use the eekboek-users mailing list at SourceForge.

=head1 AUTHOR AND CREDITS

Johan Vromans (jvromans@squirrel.nl) wrote this module.

Web site: L<http://www.eekboek.nl>.

=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 2005-2011 by Squirrel Consultancy. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.
