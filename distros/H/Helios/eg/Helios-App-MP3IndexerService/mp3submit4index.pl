#!/usr/bin/env perl

use 5.008;
use strict;
use warnings;
use Getopt::Long;
use Helios::Config;
use Helios::Job;

our $VERSION = '2.00';

# get the command line options
our $VERBOSE = 0;
GetOptions('verbose' => \$VERBOSE );

# get the global config
my $config = Helios::Config->parseConfig();

while (<>) {
	chomp;
	my $jobxml = '<job><params><filename>'.$_.'</filename></params></job>';
	my $job = Helios::Job->new();
	$job->setConfig($config);
	$job->setJobType('Helios::App::MP3IndexerService');
	$job->setArgString($jobxml);
	my $jobid = $job->submit();
	print "Submitted job ",$jobid," for file ",$_,"\n" if $VERBOSE;
}

=head1 NAME

mp3submit4index.pl - submit jobs to Helios::App::MP3IndexerService for indexing

=head1 SYNOPSIS

 # start the service daemon
 helios.pl MP3IndexerService
 
 # find all the .mp3 files in your file system
 # and submit jobs to Helios to index them
 find / -name "*\.mp3" -print | mp3submit4index.pl

=head1 DESCRIPTION

This is a sample application to demonstrate some of the features of the 
Helios distributed job processing system and how to write services for it.

The mp3submit4index.pl command reads a list of filenames from STDIN and 
submits jobs to Helios for Helios::App::MP3IndexerService to process.

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut
