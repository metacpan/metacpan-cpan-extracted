#! perl --			-*- coding: utf-8 -*-

use utf8;

# Author          : Johan Vromans
# Created On      : Thu Jul  7 15:53:48 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sat Aug 11 21:13:47 2012
# Update Count    : 1009
# Status          : Unknown, Use with caution!

################ Common stuff ################

package main;

our $cfg;
our $dbh;

package EB::Main;

use strict;
use warnings;

use EekBoek;
use EB;
use EB::DB;
use Getopt::Long 2.13;

################ The Process ################

sub run {
    my ( $pkg, $opts ) = @_;
    $opts = {} unless defined $opts;
    binmode(STDOUT, ":encoding(utf8)");
    binmode(STDERR, ":encoding(utf8)");

    # Preliminary initialize config.
    EB->app_init( { app => $EekBoek::PACKAGE } );

    # Command line options.
    $opts =
      { interactive   => -t,		# runs interactively
	#command,			# command to process
	#echo,				# echo input
	confirm	      => 0,		# NYI
	#journal,			# show journal
	#inexport,			# in/export
	#file,				# file voor in/export
	#dir,				# directory voor in/export
	#title,				# title for export
	#errexit			# disallow errors in batch
	verbose	      => 0,		# verbose processing
	#boekjaar,			# boekjaar

	# Development options (not shown with -help).
	debug	     => 0,		# debugging
	trace	     => 0,		# trace (show process)
	test	     => 0,		# test mode.

	# Let supplied options override.
	%$opts,
      };

    # Process command line options.
    app_options($opts);

    # Post-processing.
    $opts->{trace} |= ($opts->{debug} || $opts->{test});

    # Initialize config.
    EB->app_init( { app => $EekBoek::PACKAGE, %$opts } );
    if ( $opts->{printconfig} ) {
	$cfg->printconf( \@ARGV );
	exit;
    }

    my $userdir = $cfg->user_dir;
    mkdir($userdir) unless -d $userdir;

    unless ( defined($opts->{wizard}) && !$opts->{wizard} ) {
      if ( $opts->{wizard}
	 or
	 !$opts->{config}
	 && ( ( -e $cfg->std_config || -e $cfg->std_config_alt ) ? $cfg->val( qw(general wizard), 0 ) : 1 )
       ) {
	require EB::IniWiz;
	EB::IniWiz->run($opts); # sets $opts->{runeb}
	die("?"._T("Geen administratie geselecteerd")."\n") unless $opts->{runeb};
	EB->app_init( { app => $EekBoek::PACKAGE, %$opts } );
      }
    }

    $opts->{echo} = "eb> " if $opts->{echo};

    my $dataset = $cfg->val(qw(database name), undef);

    unless ( $dataset ) {
	die("?"._T("Geen EekBoek database opgegeven.".
		   " Specificeer een database in de configuratiefile,".
		   " of selecteer een andere configuratiefile".
		   " op de command line met \"--config=...\".").
	    "\n");
    }

    $cfg->newval(qw(database name), $dataset);
    $cfg->newval(qw(preferences journal), $opts->{journal})
      if defined $opts->{journal};

    $dbh = EB::DB->new(trace => $opts->{trace});

    my $createdb;
    if ( defined $opts->{inexport} ) {
	if ( $opts->{inexport} ) {
	    $opts->{command} = 1;
	    $createdb = 1;
	    @ARGV = qw(import --noclean);
	    push(@ARGV, "--file", $opts->{file})
	      if defined $opts->{file};
	    push(@ARGV, "--dir", $opts->{dir})
	      if defined $opts->{dir};
	}
	else {
	    $opts->{command} = 1;
	    @ARGV = qw(export);
	    push(@ARGV, "--file", $opts->{file})
	      if defined $opts->{file};
	    push(@ARGV, "--dir", $opts->{dir})
	      if defined $opts->{dir};
	    push(@ARGV, "--titel", $opts->{title})
	      if defined $opts->{title};
	}
    }

    if ( $createdb ) {
	$dbh->createdb($dataset);
	warn("%".__x("Lege database {db} is aangemaakt", db => $dataset)."\n");
    }

    return 0 if $opts->{command} && !@ARGV;

    require EB::Shell;
    my $shell = EB::Shell->new
      ({ HISTFILE	   => $userdir."/history",
	 command	   => $opts->{command},
	 interactive	   => $opts->{interactive},
	 errexit	   => defined($opts->{errexit})?$opts->{errexit}:$cfg->val(qw(shell errexit),0),
	 verbose	   => $opts->{verbose},
	 trace		   => $opts->{trace},
	 journal	   => $cfg->val(qw(preferences journal), 0),
	 echo		   => $opts->{echo},
	 prompt		   => lc($cfg->app),
	 boekjaar	   => $opts->{boekjaar},
       });

    $| = 1;

    $shell->run;

}

################ Subroutines ################

################ Subroutines ################

sub app_options {
    my ( $opts ) = @_;

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    Getopt::Long::Configure(qw(no_ignore_case));

    if ( !GetOptions( $opts,
		      'command|c'    => sub {
			  $opts->{command} = 1;
			  die("!FINISH\n");
		      },
		      'import'       => sub {
			  $opts->{inexport} = 1;
		      },
		      'export'       => sub {
			  $opts->{inexport} = 0;
		      },
		      'init'         => sub {
			  $opts->{inexport} = 1;
			  $opts->{dir} = ".";
		      },
		      'define|D=s%',
		      'printconfig|P',
		      'nostdconf|X',
		      'config|f=s',
		      'title|titel=s',
		      'echo|e!',
		      'ident',
		      'journaal',
		      'boekjaar=s',
		      'verbose',
		      'dir=s',
		      'file=s',
		      'interactive!',
		      'wizard!',
		      'errexit!',
		      'trace',
		      'help|?',
		      'debug',
		    ) or $opts->{help} )
    {
	app_usage(2);
    }
    app_usage(2) if @ARGV && !($opts->{command} || $opts->{printconfig});
    app_ident() if $opts->{ident};
}

sub app_ident {
    return;
    print STDERR (__x("Dit is {pkg} [{name} {version}]",
		      pkg     => $EekBoek::PACKAGE,
		      name    => "Shell",
		      version => $EekBoek::VERSION) . "\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR __x(<<EndOfUsage, prog => $0);
Gebruik: {prog} [options] [file ...]

    --command  -c	voer de rest van de opdrachtregel uit als command
    --echo  -e		toon ingelezen opdrachten
    --boekjaar=XXX	specificeer boekjaar
    --import		importeer een nieuwe administratie
    --export		exporteer een administratie
    --dir=XXX		directory voor im/export
    --file=XXX		bestand voor im/export
    --titel=XXX		omschrijving voor export
    --init		(re)creëer administratie
    --help		deze hulpboodschap
    --ident		toon identificatie
    --verbose		geef meer uitgebreide information

Voor experts:

    --config=XXX -f	specificeer configuratiebestand
    --nostdconf -X	gebruik uitsluitend dit configuratiebestand
    --define=XXX -D	definieer configuratiesetting
    --printconfig -P	print config waarden
    --[no]interactive	forceer [non]interactieve modus
    --[no]errexit	stop direct na een fout in de invoer
EndOfUsage
    CORE::exit $exit if defined $exit && $exit != 0;
}

1;
