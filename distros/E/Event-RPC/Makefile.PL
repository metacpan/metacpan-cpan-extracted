# $Id: Makefile.PL,v 1.2 2005/04/15 21:11:49 joern Exp $

use strict;
use ExtUtils::MakeMaker;

my $loop_modules = 0;
my $has_event    = 0;
my $has_glib     = 0;
my $has_anyevent = 0;

my $format_modules = 0;
my $has_sereal     = 0;
my $has_cbor_xs    = 0;
my $has_json_xs    = 0;
my $has_storable   = 0;

eval { require Event;    $has_event    = 1 } && ++$loop_modules;
eval { require Glib;     $has_glib     = 1 } && ++$loop_modules;
eval { require AnyEvent; $has_anyevent = 1 } && ++$loop_modules;

eval { require Sereal;   $has_sereal   = 1 } && ++$format_modules;
eval { require CBOR::XS; $has_cbor_xs  = 1 } && ++$format_modules;
eval { require JSON::XS; $has_json_xs  = 1 } && ++$format_modules;
eval { require Storable; $has_storable = 1 } && ++$format_modules;

if ( !$loop_modules ) {
    print "\n";
    print "*****************************************************************\n";
    print "WARNING: You need Event, Glib or AnyEvent for Event::RPC to work!\n";
    print "*****************************************************************\n";
    print "\n";
}

if ( !$format_modules ) {
    print "\n";
    print "*****************************************************************\n";
    print "WARNING: You need Sereal, CBOR::XS, JSON::XS or Storable module\n";
    print "*****************************************************************\n";
    print "\n";
}

my $has_ssl;
eval { require IO::Socket::SSL; $has_ssl = 1 } || do {
    print "\n";
    print "NOTE: Event::RPC is capable of SSL encrypted connections,\n";
    print "      but your Perl is missing the IO::Socket::SSL module.\n";
    print "      Event::RPC works perfectly without the module, but you\n";
    print "      can't use SSL connections until IO::Socket::SSL is\n";
    print "      installed.\n";
    print "\n";
};

#-- Add found modules to PREREQ_PM, so CPAN Testers add
#-- version numbers of these modules to the reports, which
#-- are very important in case of failing tests.
my @add_prereq;
push @add_prereq, 'AnyEvent', 0        if not $loop_modules;
push @add_prereq, 'Event', 0           if $has_event;
push @add_prereq, 'Glib', 0            if $has_glib;

push @add_prereq, "Sereal", 3.0        if $has_sereal or not $format_modules;
push @add_prereq, "CBOR::XS", 0        if $has_cbor_xs;
push @add_prereq, "JSON::XS", 3.0      if $has_json_xs;
push @add_prereq, "Storable", 0        if $has_storable;

push @add_prereq, 'IO::Socket::SSL', 0 if $has_ssl;
push @add_prereq, 'Net::SSLeay', 0     if $has_ssl;

WriteMakefile(
    'NAME'	   => 'Event::RPC',
    'VERSION_FROM' => 'lib/Event/RPC.pm',
    'PREREQ_PM'    => {
    	'Test::More'       => 0,
        'Storable'         => 0,
        'IO::Socket::INET' => 0,
        @add_prereq,
    },
    'dist' => {
        COMPRESS => "gzip",
        SUFFIX   => "gz",
	PREOP    => q[pod2text lib/Event/RPC.pm > README],
	POSTOP	 => q[mkdir -p dist && mv Event-RPC-*tar.gz dist/],
    },
);
