#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Block/RCS/RowDir.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Block::RowDir;  # assumes Some/Module.pm
use Genezzo::Util;
use Genezzo::Block::Std;

use strict;
use warnings;

use Carp;
use warnings::register;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
#    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 7.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&GetRDEntry &SetRDEntry );
    %EXPORT_TAGS = ();     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw(
                      $RowDirTemplate $LenRowDirTemplate
                      );
}

our @EXPORT_OK;

# non-exported package globals go here

# initialize package globals, first exported ones

#                      status posn len
our $RowDirTemplate    = 'n N N';
our $LenRowDirTemplate = length(pack($RowDirTemplate, 1, 1, 1));
our $RowDirHdrOffset   = $Genezzo::Block::Std::LenHdrTemplate;

# my ($status, $posn, $len) = GetRDEntry($entrynum, $bigbuf)
sub GetRDEntry
{
#    greet @_;
    return undef
        unless (scalar(@_) > 1);

    if ($_[1] !~ /\d+/)
    {
        carp "Non-numeric offset: $_[1] "
            if warnings::enabled();
        return (undef); # protect us from non-numeric array offsets
    }

    my $entrynum  = $_[1];
    my $href      = $_[0];
    my $refbufstr = $href->{bigbuf};

    return unpack($RowDirTemplate, 
                  substr($$refbufstr,
                         $RowDirHdrOffset + ($entrynum * $LenRowDirTemplate),
                         $LenRowDirTemplate));
}

sub SetRDEntry
{
#    whoami @_;

    return undef
        unless (scalar(@_) > 4);

    if ($_[1] !~ /\d+/)
    {
        carp "Non-numeric offset: $_[1] "
            if warnings::enabled();
        return (undef); # protect us from non-numeric array offsets
    }

    my $entrynum  = $_[1];
    my $href      = $_[0];
    my $refbufstr = $href->{bigbuf};

    substr($$refbufstr,
           $RowDirHdrOffset + ($entrynum * $LenRowDirTemplate),
           $LenRowDirTemplate)
        = pack($RowDirTemplate, $_[2], $_[3], $_[4]);
#    return $_[0];
}

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Block::RowDir - row directory

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ARGUMENTS

=head1 FUNCTIONS

=head2 EXPORT

=head1 LIMITATIONS

various

=head1 #TODO

=over 4

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2003, 2004 Jeffrey I Cohen.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to: jcohen@genezzo.com

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut
