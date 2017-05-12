#!/usr/bin/perl

######################################################################
#
#   Directory Digest -- dirgest.cgi
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: dirgest.cgi,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#    
#    It is recommended that you do not disable SECURE, otherwise it
#    allows potential attackers (should they subvert any authentication
#    you have enabled around this cgi anyway - e.g. htaccess) to 
#    specify include/exclude/quiet/configure options, and potentially
#    to extract further information about the system than they could
#    have obtained otherwise. You have been warned.
#
#    It is recommended that unless you are using https, that you 
#    enable SUMMARISE which will only print only a single master digest
#    across all output, rather than return a verbose list of file
#    and digest combinations (which could provide useful internal
#    site information to an evesdropper/attacker).
#
######################################################################

=head1 NAME

dirgest.cgi - Common Gateway Interface tool for Directory Digests

=head1 SYNOPSIS

  GET http://matthewgream.net/cgi-bin/dirgest.cgi&o=show

=head1 REQUIRES

Perl 5.004, Digest::Directory::API, CGI.

=head1 EXPORTS

Nothing.

=head1 DESCRIPTION

B<dirgest.cgi> provides a common gateway interface tool allowing 
dirgests to be fetched from a remote resource. It builds upon 
B<Digest::Directory::API>. 

=head1 USAGE

Execute the script without any arguments to see usage information.

=cut

use strict;
use warnings;

# $ENV{PATH} = '';
use lib qw(.);
use CGI;
use CGI::Carp qw(fatalsToBrowser);

use Digest::Directory::API;


######################################################################
# definitions
######################################################################

my $PROGRAM  = "Directory Digest CGI";
my $VERSION  = sprintf("%d.%02d", q$Revision: 0.90 $ =~ /(\d+)\.(\d+)/);
my $AUTHOR   = "Matthew Gream <matthew.gream\@pobox.com>";
my $RIGHTS   = "Copyright 2002 Matthew Gream. All Rights Reserved.";
my $USAGE    = <<USAGE_END;

o=OPERATION&s=SUMMARISE&c=CONFIGURE&q=QUIET&t=TRIM&i=INCLUDE&e=EXCLUDE
    [0..1] - OPERATION := "show"|"version"|"help";
    [0..1] - SUMMARISE := "0"|"1";
    [0..1] - CONFIGURE := <filename>;
    [0..1] - QUIET := "0"|"1";
    [0..1] - TRIM := "0".."n";
    [0..n] - INCLUDE := <directory|filename>;
    [0..n] - EXCLUDE := <directory|filename>;
USAGE_END
my $BANNER   = "$PROGRAM v$VERSION -- $AUTHOR\n    $RIGHTS\n";


######################################################################
# configuration
######################################################################

my $SECURE      = 1; # see above
my $SUMMARISE   = 0; # see above
my $OPERATION   = "";
my $CONFIGURE   = "dirgest.conf";
my $QUIET       = -1; 
my $TRIM        = -1;
my @INCLUDES    = ();
my @EXCLUDES    = ();


######################################################################
# parameters
######################################################################

my $cgi = new CGI;

if (defined $cgi->param('o'))
    { $OPERATION = $cgi->param('o'); }

if (!$SECURE)
{
    if (defined $cgi->param('s'))
        { $SUMMARISE = $cgi->param('s'); }
    if (defined $cgi->param('c'))
        { $CONFIGURE = $cgi->param('c'); }
    if (defined $cgi->param('q')) 
        { $QUIET = $cgi->param('q'); }
    if (defined $cgi->param('t')) 
        { $TRIM = $cgi->param('t'); }
    if (defined $cgi->param('i'))
        { @INCLUDES = $cgi->param('i'); }
    if (defined $cgi->param('e'))
        { @EXCLUDES = $cgi->param('e'); }
}


######################################################################
# operation
######################################################################

print $cgi->header('text/plain');

my ($dirgest_api) = Digest::Directory::API->new;

$dirgest_api->quiet($QUIET) if ($QUIET >= 0);
$dirgest_api->trim($TRIM) if ($TRIM >= 0);
$dirgest_api->configure($CONFIGURE, \@INCLUDES, \@EXCLUDES);

if ($OPERATION eq 'show')
{
    my($NODETAILS) = $SUMMARISE ? 1 : 0;
    my($NOSUMMARY) = 0;
    $dirgest_api->show("", "", "", $NODETAILS, $NOSUMMARY);
}
else
{
    print $BANNER . $USAGE;
}

exit 0;


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

