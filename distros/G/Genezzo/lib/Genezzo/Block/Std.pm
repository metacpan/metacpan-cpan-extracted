#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Block/RCS/Std.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Block::Std;  # assumes Some/Module.pm
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
    $VERSION = do { my @r = (q$Revision: 7.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&GetStdHdr &SetStdHdr &ClearStdBlock &SetHdr);
    %EXPORT_TAGS = ();     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw(
                      %BlockType $DEFBLOCKSIZE 
                      $HdrTemplate $LenHdrTemplate
                      );
    
}

our @EXPORT_OK;

# non-exported package globals go here

# initialize package globals, first exported ones
our %BlockType = 
qw(
   EmptyBlock 0
   AppendBlock 1
   RandomBlock 2
   );

our $DEFBLOCKSIZE = $Genezzo::Util::DEFBLOCKSIZE;   # 4K blocksize

# calculate space for type, fileno/blockno, 
# LSN/SCN/sequence number 
our $fileblockTmpl = "N N";
our $fbtLen = length(pack($fileblockTmpl, 1, 1));

our $xtraHdr = "x$fbtLen";  # can only be a spacer like x32

#               [fixed head]  blocktype, #rows[i.e., size of rowdir], freespace
our $HdrTemplate    = "$xtraHdr n n N";
our $LenHdrTemplate = length(pack($HdrTemplate, 1, 1, 1));

our $FtrTemplate    = "N N N"; # something like LSN, type, checksum
our $LenFtrTemplate = length(pack($FtrTemplate, 1, 1, 1));

# XXX: a checksum might be a nice thing in the std header...

# my ($blocktype, $numelts, $freespace) = GetHdr($bigbuf)
sub GetStdHdr
{
    return undef
        unless (scalar(@_));

    my $href = $_[0];
    my $refbufstr = $href->{bigbuf};

    return unpack($HdrTemplate, $$refbufstr);
}
sub SetStdHdr
{
#    greet @_;

    return undef
        unless (scalar(@_) > 3);

    my $href = $_[0];
    my $refbufstr = $href->{bigbuf};

    substr($$refbufstr, 0, $LenHdrTemplate) 
        = pack($HdrTemplate, $_[1], $_[2], $_[3]);
#    return $_[0];
}
sub ClearStdBlock
{
#    whoami;
    return undef
        unless (scalar(@_));
    SetStdHdr($_[0], 0, 0, 0);
}
sub SetHdr
{
    my %optional = (
                    HeaderTemplate => $HdrTemplate
                    );
    my %required = (
                    href => "no buffer supplied !"
                    );
    my %args = (%optional,
		@_);

    return 0
        unless (Validate(\%args, \%required));

    my $href = $args{href};
    my $refbufstr = $href->{bigbuf};

    my %needtoget;

    unless (    exists($args{BlockType})
             && exists($args{NumElts})
             && exists($args{FreeSpace})
             )
    {
        my ($blocktype, $numelts, $freespace) 
            = GetStdHdr($href);
    
        $args{BlockType} = $blocktype
            unless (exists($args{BlockType}));
        $args{NumElts} = $numelts
            unless (exists($args{NumElts}));
        $args{FreeSpace} = $freespace
            unless (exists($args{FreeSpace}));
     }

    substr($$refbufstr, 0, length($args{HeaderTemplate}))
        = pack($args{HeaderTemplate},
               $args{BlockType},
               $args{NumElts},
               $args{FreeSpace});

    return 1;
}

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Block::Std - Standard Block 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item  GetStdHdr 

=item  SetStdHdr 

=item  ClearStdBlock 

=item  SetHdr

=back

=head2 EXPORT

=over 4

=item  %BlockType 
List of legal block types

=item  $DEFBLOCKSIZE
Default block size

=item  $HdrTemplate 

=item  $LenHdrTemplate

=back


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
