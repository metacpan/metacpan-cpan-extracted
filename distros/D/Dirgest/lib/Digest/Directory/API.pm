
######################################################################
#
#   Directory Digest -- Digest::Directory::API.pm 
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: API.pm,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#    
######################################################################

=head1 NAME

Digest::Directory::API - api class for Directory Digests

=head1 SYNOPSIS

  use Digest::Directory::API;
 
  my($d) = Digest::Directory::API->new();
  $d->quiet(0);
  $d->configure("/etc/dirgests.conf");
  my($r) = $d->compare("", "", "", "/etc/dirgests.text", 0, 0);
  ( $r > 0 ) && print "Warning: dirgests changed - inspect!\n";
  
=head1 REQUIRES

Perl 5.004, Digest::Directory::BASE.

=head1 EXPORTS

Nothing.

=head1 DESCRIPTION

B<Digest::Directory::API> provides a more general API over 
B<Digest::Directory::BASE> that allows clients to configure, 
create, show, compare and update directory digests. 

=cut

######################################################################

package Digest::Directory::API;

require 5.004;

use strict;
use warnings;
use vars qw( @ISA $PROGRAM $VERSION $AUTHOR $RIGHTS $USAGE );
@ISA = qw(Exporter);

$PROGRAM = "Digest::Directory::API";
$VERSION = sprintf("%d.%02d", q$Revision: 0.90 $ =~ /(\d+)\.(\d+)/);
$AUTHOR = "Matthew Gream <matthew.gream\@pobox.com>";
$RIGHTS = "Copyright 2002 Matthew Gream. All Rights Reserved.";
$USAGE = "see pod documentation";

######################################################################

use Digest::Directory::BASE;

######################################################################

=head1 METHODS

The following methods are provided:

=over 4

=cut


######################################################################

=item B<$dirgest = Digest::Directory::API-E<gt>new( )>

Create a dirgest instance; default configuration is set up, with 
quiet = 0.

=cut

######################################################################

sub new
 {
    my($class) = @_;

    my $self = {
        quiet => 0,
        dirgest => Digest::Directory::BASE->new()
    };

    return bless $self, $class;
 }

sub dirgest
 {
    my($self) = @_;

    return $self->{'dirgest'};
 }


######################################################################

=item B<$dirgest-E<gt>quiet( $enabled )>

Enable quiet operating mode for a dirgest; ensures that no debug
trace output is provided during operation.

$enabled => '0' or '1' for whether operation to be quiet or not;

=cut

######################################################################

sub quiet
{
    my($self, $q) = @_;

    $self->{'quiet'} = $q if (defined $q);
    $self->{'dirgest'}->quiet($self->{'quiet'});
    return 1;
}


######################################################################

=item B<$dirgest-E<gt>trim( $count )>

Enable trim level, at specified count; all file/directory sets will
have their prefix trimmed.

$count => 'n' where 'n' >= 0 && specifies the number of leading
components of a name to remove.

=cut

######################################################################

sub trim
{
    my($self, $t) = @_;

    $self->{'dirgest'}->trim($t);
    return 1;
}



######################################################################

=item B<$result = $dirgest-E<gt>configure( $file, \@incl, \@excl )>

Specify configuration for a dirgest; 

$file => filename to read configuration from in the format 
as specified in Digest::Directory::BASE.pm;

\@incl => array of file/directory sets to include (in addition 
to those read from configuration file);

\@excl => array of file/directory sets to exclude (in addition 
to those read from configuration file);

return => '1' on success, or '0' on failure;

=cut

######################################################################

sub configure
{
    my($self, $conf, $incl, $excl) = @_;

    $self->{'dirgest'}->configure($conf)
        if($conf);
    foreach (@$incl) 
        { $self->{'dirgest'}->include($_); }
    foreach (@$excl) 
        { $self->{'dirgest'}->exclude($_); }

    return 1;
}


######################################################################

=item B<$result = $dirgest-E<gt>create( $link, $user, $pass, $file, $nodetails, $nosummary )>

Create a dirgest and save to specified file;

$link => the link to fetch dirgests from;

$user => the http username to use with $link;

$pass => the http password to use with $link;

$file => the file to save dirgests to;

$nodetails => don't show detail dirgests during activity;

$nosummary => don't show summary dirgest during activity;

return => '1' on success, or '0' on failure;

=cut

######################################################################

sub create
{
    my($self, $link, $user, $pass, $file, $nodetails, $nosummary) = @_;

    print "CREATING\n"
        if (!$self->{'quiet'});

    if ($link)
    {
        $self->{'dirgest'}->fetch($link, $user, $pass) 
            || return 0;
    }
    else
    {
        $self->{'dirgest'}->compute()
            || return 0;
    }

    $self->{'dirgest'}->print($nodetails, $nosummary)
        unless ($nodetails && $nosummary);
    
    $file && $self->{'dirgest'}->save($file) 
        || return 0;

    return 1;
}


######################################################################

=item B<$result = $dirgest-E<gt>show( $link, $user, $pass, $nodetails, $nosummary )>

Show a dirgest from a resource with options;

$link => the link to fetch dirgests from;

$user => the http username to use with $link;

$pass => the http password to use with $link;

$file => the file to save dirgests to;

$nodetails => don't show detail dirgests during activity;

$nosummary => don't show summary dirgest during activity;

return => '1' on success, or '0' on failure;

=cut

######################################################################

sub show
{
    my($self, $link, $user, $pass, $nodetails, $nosummary) = @_;

    print "SHOWING\n"
        if (!$self->{'quiet'});

    if ($link)
    {
        $self->{'dirgest'}->fetch($link, $user, $pass)
            || return 0;
    }
    else
    {
        $self->{'dirgest'}->compute()
            || return 0;
    }

    $self->{'dirgest'}->print($nodetails, $nosummary)
        unless ($nodetails && $nosummary);

    return 1;
}


######################################################################

=item B<$result = $dirgest-E<gt>compare( $link, $user, $pass, $file, $nodetails, $nosummary, $showequal )>

Compare dirgests as obtained from resources or locally;

$link => the link to fetch dirgests from;

$user => the http username to use with $link;

$pass => the http password to use with $link;

$file => the file to save dirgests to;

$nodetails => don't show detail dirgests during activity;

$nosummary => don't show summary dirgest during activity;

$showequal => show equal dirgests during activity;

return => '1' on success, or '0' on failure;

=cut

######################################################################

sub compare
{
    my($self, $link, $user, $pass, $file, $nodetails, $nosummary, $showequal) = @_;

    print "COMPARING\n"
        if (!$self->{'quiet'});

    if ($link)
    {
        $self->{'dirgest'}->fetch($link, $user, $pass)
            || return 0;
    }
    else
    {
        $self->{'dirgest'}->compute()
            || return 0;
    }

    my $dirgest = Digest::Directory::BASE->new();
    $dirgest->quiet($self->{'quiet'});
    $dirgest->load($file)
        || return 0;

    my ($result) = $self->{'dirgest'}->compare($dirgest,
        $nodetails, $nosummary, $showequal);

    return $result;
}


######################################################################

=item B<$result = $dirgest-E<gt>update( $link, $user, $pass, $file, $nodetails, $nosummary, $showequal )>

Update a dirgest from a resource back to resource;

$link => the link to fetch dirgests from;

$user => the http username to use with $link;

$pass => the http password to use with $link;

$file => the file to save dirgests to;

$nodetails => don't show detail dirgests during activity;

$nosummary => don't show summary dirgest during activity;

$showequal => show equal dirgests during activity;

return => '1' on success, or '0' on failure;

=cut

######################################################################

sub update
{
    my($self, $link, $user, $pass, $file, $nodetails, $nosummary, $showequal) = @_;

    print "UPDATING\n"
        if (!$self->{'quiet'});

    if ($link)
    {
        $self->{'dirgest'}->fetch($link, $user, $pass)
            || return 0;
    }
    else
    {
        $self->{'dirgest'}->compute()
            || return 0;
    }

    my $dirgest = Digest::Directory::BASE->new;
    $dirgest->quiet($self->{'quiet'});
    $file && $dirgest->load($file)
        || return 0;

    my ($result) = $self->{'dirgest'}->compare($dirgest,
        $nodetails, $nosummary, $showequal);

    $file && $self->{'dirgest'}->save($file)
        || return 0;

    return 1;
}


######################################################################

=back

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

