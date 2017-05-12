#!/usr/bin/perl

######################################################################
#
#   Directory Digest -- dirgest.pl
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: dirgest.pl,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#    
#    The API module provides standard command line interface with
#    multiple commands/options to create, show, compare, update
#    and otherwise process dirgests. With the correct arguments,
#    the dirgests can be obtained remotely.
#    
######################################################################

=head1 NAME

dirgest.pl - Command Line Interface tool for Directory Digests

=head1 SYNOPSIS

  $ dirgest.pl --quiet --filename=/etc/dirgests.text \
        --configure=/etc/dirgests.conf \
        compare

=head1 REQUIRES

Perl 5.004, Digest::Directory::API, Getopt::Long.

=head1 EXPORTS

Nothing.

=head1 DESCRIPTION

B<dirgest.pl> provides a command line tool allowing dirgests to be
manipulated conveniently manually or from scripts. It builds upon
B<Digest::Directory::API>. 

=head1 USAGE

Execute the script without any arguments to see usage information.

=cut

######################################################################

use strict;
use warnings;

use Digest::Directory::API;


######################################################################
# definitions
######################################################################

my $PROGRAM  = "Directory Digest CLI";
my $VERSION  = sprintf("%d.%02d", q$Revision: 0.90 $ =~ /(\d+)\.(\d+)/);
my $AUTHOR   = "Matthew Gream <matthew.gream\@pobox.com>";
my $RIGHTS   = "Copyright 2002 Matthew Gream. All Rights Reserved.";
my $USAGE    = <<USAGE_END;

dirgest [options] show|create|compare|update [+/-name] ...

Commands:
  show              compute|fetch D; display D
  create            compute|fetch D; display D; save D
  compare           compute|fetch D; load D'; compare D D'
  update            compute|fetch D; load D'; compare D D'; save D'

Configuration:
  +name             include file/directory (command line, or configure file)
  -name             exclude file/directory (command line, or configure file)

Options:
  --version         show version and exit
  --help            display this help information
  --quiet           operate in quiet mode, no progress output
  --configure=name  the configuration file (default: CONFIGURE)
  --filename=name   the dirgests file (default: DIRGESTS)
  --fetch=url       rather than compute, try to fetch from remote url
  --login=user:pass user/pass for http fetch authentication
  --nodetails       no details in compare|update|show
  --nosummary       no summary in compare|update|show
  --show            show results of compute|fetch 
  --show_equal      show equal results when comparing (rather than just diffs)
  --trim=n          strip 'n' levels from the output path
USAGE_END
my $BANNER   = "$PROGRAM v$VERSION -- $AUTHOR\n    $RIGHTS\n";


######################################################################
# configuration
######################################################################

my $FILENAME     = "DIRGESTS";
my $CONFIGURE    = "";
my $RESOURCE     = "";
my $LOGIN        = "";
my $USERNAME     = "";
my $PASSWORD     = "";
my $VERSION_SHOW = 0;
my $HELP_SHOW    = 0;
my $SHOW         = 0;
my $SHOWEQUAL    = 0;
my $NODETAILS    = 0;
my $NOSUMMARY    = 0;
my $NOOP         = 0;
my $OPERATION    = "";
my @INCLUDES     = ();
my @EXCLUDES     = ();
my $QUIET        = -1;
my $TRIM         = -1;

use Getopt::Long;
Getopt::Long::Configure("prefix_pattern=(--)");
GetOptions(    
    'version'         => \$VERSION_SHOW,
    'help'            => \$HELP_SHOW,
    'quiet'           => \$QUIET,
    'configure=s'     => \$CONFIGURE,
    'filename=s'      => \$FILENAME,
    'show'            => \$SHOW,
    'show_equal'      => \$SHOWEQUAL,
    'nodetails'       => \$NODETAILS,
    'nosummary'       => \$NOSUMMARY,
    'fetch=s'         => \$RESOURCE,
    'login=s'         => \$LOGIN,
    'trim=i'          => \$TRIM,
    'noop'            => \$NOOP,
);

if ($VERSION_SHOW) 
    { print $BANNER; exit 0; }
if (scalar @ARGV < 1 || $HELP_SHOW) 
    { die($BANNER . $USAGE); }
$OPERATION = lc($ARGV[0]); 
    shift @ARGV;
if (!($OPERATION=~m/(create|compare|update|show)/)) 
    { die($BANNER . $USAGE); }

foreach (@ARGV)
{
    if (/^\-(.*)$/)
    { push @EXCLUDES, $1; }
    elsif (/^\+(.*)$/)
    { push @INCLUDES, $1; }
    else
    { push @INCLUDES, $_; }
}

$USERNAME = $LOGIN || '';
$PASSWORD = ($USERNAME and $USERNAME =~ s/:(.*)$//) ? $1 : '';


######################################################################
# operation
######################################################################

print $BANNER
    if ($QUIET <= 0);

my($dirgest_api) = Digest::Directory::API->new();

$dirgest_api->quiet($QUIET) if ($QUIET >= 0);
$dirgest_api->trim($TRIM) if ($TRIM >= 0);
$dirgest_api->configure($CONFIGURE, \@INCLUDES, \@EXCLUDES);

my($result) = 0;

if ($NOOP)
{
}
elsif ($OPERATION eq 'create') 
{
    if (!$SHOW) { $NODETAILS = 1; $NOSUMMARY = 1; }
    $result = $dirgest_api->create(
        $RESOURCE, $USERNAME, $PASSWORD, 
        $FILENAME,
        $NODETAILS, $NOSUMMARY);
}
elsif ($OPERATION eq 'show') 
{
    $result = $dirgest_api->show(
        $RESOURCE, $USERNAME, $PASSWORD, 
        $NODETAILS, $NOSUMMARY);
}
elsif ($OPERATION eq 'compare') 
{
    $result = $dirgest_api->compare(
        $RESOURCE, $USERNAME, $PASSWORD, 
        $FILENAME, 
        $NODETAILS, $NOSUMMARY, $SHOWEQUAL);
}
elsif ($OPERATION eq 'update') 
{
    $result = $dirgest_api->update(
        $RESOURCE, $USERNAME, $PASSWORD, 
        $FILENAME,
        $NODETAILS, $NOSUMMARY, $SHOWEQUAL);
}

exit $result;


######################################################################

=head1 AUTHOR

Matthew Gream (MGREAM) <matthew.gream@pobox.com>

=head1 VERSION

Version 0.90.

=head1 RIGHTS

Copyright 2002 Matthew Gream. All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

######################################################################

1;

