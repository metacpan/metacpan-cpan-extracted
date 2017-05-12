#!/usr/bin/perl

# Skeleton for an application using Getopt::Long.

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jul  4 14:43:40 2013
# Update Count    : 84
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

################ Setup  ################

# Process command line options, config files, and such.
my $options = app_setup();

################ Presets ################

$options->{trace} = 1 if $options->{debug} || $options->{test};

################ Activate ################

main($options);

################ The Process ################

sub main {
    my ($options) = @_;
    use Data::Dumper;
    print Dumper($options);
}

################ Options and Configuration ################

use Getopt::Long 2.13;

# Package name.
my $my_package;
# Program name and version.
my ($my_name, $my_version);

sub app_setup {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Package name.
    $my_package = 'Sciurix';
    # Program name and version.
    ($my_name, $my_version) = qw( MyProg 0.01 );

    my $options =
      {
       verbose		=> 0,		# verbose processing
       ### ADD OPTIONS HERE ###

       # Development options (not shown with -help).
       debug		=> 0,		# debugging
       trace		=> 0,		# trace (show process)
       test		=> 0,		# test mode

       # Service.
       _package		=> $my_package,
       _name		=> $my_name,
       _version		=> $my_version,
       _stdin		=> \*STDIN,
       _stdout		=> \*STDOUT,
       _stderr		=> \*STDERR,
       _argv		=> [ @ARGV ],
      };

    # Return defaults if no options to process.
    return $options unless @ARGV;

    # Sorry, layout is a bit ugly...
    if ( !GetOptions
	 ($options,

	  ### ADD OPTIONS HERE ###

	  # Configuration handling.
	  'config=s'		=> sub { app_config($options, $_[0], $_[1]) },

	  # Standard options.
	  'ident'		=> \$ident,
	  'help|?'		=> \$help,
	  'verbose',
	  'trace',
	  'debug',
	 ) )
    {
	app_usage(2);
    }
    app_usage(0) if $help;
    app_ident() if $ident;

    $options;
}

sub app_ident {
    print ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage {
    my ($exit) = @_;
    select \*STDERR if $exit;
    app_ident();
    print <<EndOfUsage;
Usage: $0 [options] [file ...]
    ### ADD OPTIONS HERE ###
    --config=CFG	load options from config file
    --help		this message
    --ident		show identification
    --verbose		verbose information
EndOfUsage
    exit $exit if defined $exit;
}

sub app_config {
    my ($options, $optname, $config) = @_;
    die("$config: $!\n") unless -e $config;
    push(@{$options->{_config}}, $config);

    # Process config data, filling $options ...
}
