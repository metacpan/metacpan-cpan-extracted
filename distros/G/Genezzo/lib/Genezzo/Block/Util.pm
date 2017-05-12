#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Block/RCS/Util.pm,v 1.2 2005/12/31 09:31:57 claude Exp claude $
#
# copyright (c) 2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Block::Util;  # assumes Some/Module.pm
use Genezzo::Util;

use strict;
use warnings;

use Carp;


BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
#    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
    @EXPORT      = ();
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
#    @EXPORT_OK   = qw($Var1 %Hashit &func3 &func5);
    @EXPORT_OK   = ();

}

our @EXPORT_OK;

sub GetChecksums
{
    my ($refbuf, $blocksize) = @_;
    
    # XXX XXX: compute a basic 32 bit checksum
#   my $basicftr = pack($Genezzo::Block::Std::FtrTemplate, 0, 0, 0);
    my $packlen  = $Genezzo::Block::Std::LenFtrTemplate;

    my $skippy = $blocksize-$packlen; # skip to end of buffer
    # get the checksum
    my @outarr = unpack("x$skippy $Genezzo::Block::Std::FtrTemplate", 
			$$refbuf);

    # return calculated checksum and stored value
    my $ckTempl  = '%32C' . ($blocksize - $packlen); # skip the footer
    my $cksum = unpack($ckTempl, $$refbuf) % 65535;
    my $ck1 = pop @outarr;

    my @cksums;

    push @cksums, $cksum, $ck1;

    return @cksums;
}

sub UpdateBlockHeaderandFooter
{
    my ($fnum, $bnum, $refbuf, $blocksize) = @_;
    UpdateBlockHeader($fnum, $bnum, $refbuf, $blocksize);
    UpdateBlockFooter($refbuf, $blocksize);
}

sub UpdateBlockHeader
{
    my ($fnum, $bnum, $refbuf, $blocksize) = @_;

    # XXX: build a basic header with the file number, block number,
    # etc 
    # XXX XXX fileblockTmpl
    my $basichdr = pack($Genezzo::Block::Std::fileblockTmpl, $fnum, $bnum); 
    my $packlen  = $Genezzo::Block::Std::fbtLen;

    substr($$refbuf, 0, $packlen) = $basichdr;

}

sub UpdateBlockFooter
{
    my ($refbuf, $blocksize) = @_;

    # XXX XXX: compute a basic 32 bit checksum 
    # -- see perldoc unpack
    my $packlen     = $Genezzo::Block::Std::LenFtrTemplate;

    my $ckTempl  = '%32C' . ($blocksize - $packlen); # skip the footer
    my $cksum    = unpack($ckTempl, $$refbuf) % 65535;
    my $basicftr = pack($Genezzo::Block::Std::FtrTemplate, 0, 0, $cksum);
    # add the checksum to the end of the block
    substr($$refbuf, $blocksize-$packlen, $packlen) = $basicftr;
}

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Block::Util - Block Utility functions

=head1 SYNOPSIS

use Genezzo::Block::Util;



=head1 DESCRIPTION

The block utility functions are used to update block headers and
footers and to calculate checksum information.

=head1 FUNCTIONS

=over 4

=item  GetChecksums

=item  UpdateBlockHeader

=item  UpdateBlockFooter

=item  UpdateBlockHeaderandFooter


=back

=head2 EXPORT


=head1 LIMITATIONS

Only supports fixed block header and fixed size 

=head1 TODO

=over 4

=item  Support for completely variable block headers

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2006 Jeffrey I Cohen.  All rights reserved.

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
