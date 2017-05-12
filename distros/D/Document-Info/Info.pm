#$Id$
#
# Document::Info - determine the document type of office files
#
# To use it you need perl >=5.004 and additionally the three modules:
#
#     OLE::Storage
#     Unicode::Map 
#     Startup
#
# to be found at my directory at your favorite CPAN location or at:
#
#    http://wwwwbs.cs.tu-berlin.de/~schwartz/perl/
#
# Copyright (C) 1999 Martin Schwartz
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, you should find it at:
#
#    http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/COPYING
#
# You can contact me via schwartz@cs.tu-berlin.de
#

package Document::Info;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;
require AutoLoader;
@ISA = qw(Exporter AutoLoader);
$VERSION = '0.01';

use Startup;
use OLE::PropertySet;
use OLE::Storage;
use FileHandle;

##
## PUBLIC
##

sub new {
    my ( $proto, $fileName ) = @_;
    my $class = ref ($proto) || $proto;
    my $S = bless ( {}, $class );
    return 0 unless $S -> _Startup ( new Startup() );
    return 0 unless $S -> _Var     ( OLE::Storage->NewVar() );
    $S -> _fileName ( $fileName );
    $S -> _Doc ( "" );
    return 0 unless $S -> _go ( );
$S}

sub getLocale   { $_[0]->_DocLoc() };
sub getOS       { $_[0]->_DocOS() };
sub getRevision { $_[0]->_DocRev() };
sub getType     { $_[0]->_DocType() }

#
# Document type.
#
sub cAstound     { "Astound" }
sub cMSExcel     { "MS Excel" }
sub cMSPP        { "MS PowerPoint" }
sub cMSWord      { "MS Word" }
sub cMSWorks     { "MS Works" }
sub cPDF         { "PDF" }
sub cStarWriter  { "StarWriter" }
sub cWordPerfect { "WordPerfect" }

#
# OS type
#
sub cDOS         { "DOS" }
sub cMacOS       { "MacOS" }
sub cWindows     { "Windows" }


##
## REST IS PRIVATE
##

# Runtime 
sub _Doc      { my $S=shift; $S->{DOC}      = shift if @_; $S->{DOC} }
sub _Startup  { my $S=shift; $S->{STARTUP}  = shift if @_; $S->{STARTUP} }
sub _Var      { my $S=shift; $S->{VAR}      = shift if @_; $S->{VAR} }

sub _fileName { my $S=shift; $S->{FILENAME} = shift if @_; $S->{FILENAME} }
sub _fh       { my $S=shift; $S->{FH}       = shift if @_; $S->{FH} }
sub _pps      { my $S=shift; $S->{PPS}      = shift if @_; $S->{PPS} }

# Properties
sub _DocLoc   { my $S=shift; $S->{DOCLOC}  = shift if @_; $S->{DOCLOC} }
sub _DocOS    { my $S=shift; $S->{DOCOS}   = shift if @_; $S->{DOCOS} }
sub _DocRev   { my $S=shift; $S->{DOCREV}  = shift if @_; $S->{DOCREV} }
sub _DocType  { my $S=shift; $S->{DOCTYPE} = shift if @_; $S->{DOCTYPE} }

sub _go {
    my ( $S ) = @_;
    my $status = 0;

    if ( 
        $S->_Doc (
            OLE::Storage -> open ( 
                $S->_Startup(), $S->_Var(), $S->_fileName() 
            )
        ) 
    ) {
        $status = $S -> _checkOleFiles ( );
        $S->_Doc() -> close ( );
    } else {
        return 0 unless $S->_fh (
            new FileHandle $S->_fileName(), "r"
        );
        $status = $S -> _checkFiles ( );
        $S->_fh ( undef );
    }
    $status;
}

sub _checkFiles {
    my ( $S ) = @_;
    my $id00 = $S -> _fSubstr (0,4);
    return 0 unless length ( $id00 );

    if ( 0 ) {
    } elsif ( unpack("V",$id00)==0xBadDeed ) {
        return 1 if $S->_tryMSPowerPoint30(0);
    } elsif ( unpack("N",$id00)==0xBadDeed ) {
        return 1 if $S->_tryMSPowerPoint30(1);
    } elsif ( unpack("V",$id00)==0x002da5db ) {
        return 1 if $S->_tryMSWord20Win(0);
    } elsif ( unpack("V",$id00)==0x0021a59b ) {
        return 1 if $S->_tryMSWord10Win(0);
    } elsif ( unpack("V",$id00)==0x230037fe ) {
        return 1 if $S->_tryMSWord51Mac(0);
    } elsif ( unpack("V",$id00)==0x1c0037fe ) {
        return 1 if $S->_tryMSWord40Mac(0);
    } elsif ( unpack("N",$id00)==0xff575043 ) {
        return 1 if $S->_tryWordPerfect(1);
    } elsif ( (unpack("V",$id00)&0xffff)==0xbe31 ) {
        return 1 if $S->_tryMSWriteAndMSWordDOS(1);
    } elsif ( (unpack("V",$id00)&0xffff)==0xbe32 ) {
        return 1 if $S->_tryMSWrite(1);
    } elsif ( $id00 eq "%PDF" ) {
        return 1 if $S->_tryPDF();
    } else {
        return 1 if $S->_tryMSExcel ( );
    }
}

sub _checkOleFiles {
     my ( $S ) = @_;
     my %dir = ( );
     return 0 unless $S->_Doc()->directory ( 0, \%dir, "string" );
     if ( $S->_pps($dir{StarWriterDocument}) ) {
         return 1 if $S -> _tryOleStarWriter ( \%dir );
     }
     if ( $S->_pps($dir{'Astound Data'}) ) {
         return 1 if $S -> _tryOleAstound ( \%dir );
     }
     if ( $S->_pps($dir{WordDocument}) ) {
         return 1 if $S -> _tryOleMSWord ( \%dir );
     }
     if ( $S->_pps($dir{PP40}) ) {
         return 1 if $S -> _tryOleMSPowerPoint40 ( );
     }
     if ( $S->_pps($dir{'PowerPoint Document'}) ) {
         return 1 if $S -> _tryOleMSPowerPoint95 ( \%dir );
     }
     if ( $S->_pps($dir{MatOST}) ) {
         return 1 if $S -> _tryOleMSWorks40 ( );
     }
     if ( $dir{Workbook}||$dir{Book} ) {
         return 1 if $S -> _tryOleMSExcel ( \%dir );
     }
     return 0;
}

##
## --  File types  -------------------------------------------------
##

#
# Astound
#

sub _tryOleAstound {
    my ( $S ) = @_;
    $S -> _DocType ( cAstound() );
}

#
# MS Excel
#

sub _tryOleMSExcel {
    my ( $S, $dir ) = @_;
    $S -> _DocType ( cMSExcel() );
    if ($dir->{Workbook} && $dir->{Book}) {
        $S -> _DocRev ( "5.0,95,97,2000" );
    } elsif ( $S->_pps($dir->{Workbook}) ) {
        $S -> _tryMSExcel ( );
        if ( !$S->_DocRev() ) {
            $S -> _DocRev ( "97,2000" );
        }
    } else {
        $S -> _DocRev ( "5.0,95" );
    }
    $S -> _setMacOrWin ( );
1}

sub _tryMSExcel {
    my ( $S ) = @_;

    my ($type, $len);
    my $o = 0;
    my $max = $S -> _fLen() - 1;
    while ( $o<=$max ) {
        return 0 if ( ($o+4)>$max ); # corrupt => not an excel file
        $type = unpack("v",$S->_fSubstr($o,2)); $o+=2;
        $len  = unpack("v",$S->_fSubstr($o,2)); $o+=2;
        return 0 if ( ($o+$len)>$max ); # corrupt => not an excel file
        if ($type==0x0009) {
            $S -> _DocType ( cMSExcel() );
            $S -> _DocRev ( "2.0" );
            return 1;
        } elsif ($type==0x0209) {
            $S -> _DocType ( cMSExcel() );
            $S -> _DocRev ( "3.0" );
            return 1;
        } elsif ($type==0x0409) {
            $S -> _DocType ( cMSExcel() );
            $S -> _DocRev ( "4.0" );
            return 1;
        } elsif ($type==0x0809) {
            my $biffType = unpack("v",$S->_fSubstr($o,2));
            $S -> _DocType ( cMSExcel() );
            if ($biffType==0x500) {
                $S -> _DocRev ( "5.0,95" );
            } elsif ($biffType=0x600) {
                $S -> _DocRev ( "97,2000" );
            } else {
                $S -> _DocRev ( ">2000" );
            }
            return 1;
        }
        $o += $len;
    }
0}

#
# MS PowerPoint
#

sub _tryOleMSPowerPoint95 {
    my ( $S, $dir ) = @_;
    $S -> _DocType ( cMSPP() );
    if ( $dir->{PP97_DUALSTORAGE} ) {
        $S -> _DocRev ( "95,97,2000" );
    } else {
        if ( $dir->{Header} ) {
            $S -> _DocRev ( "95" );
        } else {
            $S -> _DocRev ( "97,2000" );
        }
    }
    $S -> _setMacOrWin ( );
1}

sub _tryOleMSPowerPoint40 {
    my ( $S ) = @_;
    $S -> _DocType ( cMSPP() );
    $S -> _DocRev ( "4.0" );
    $S -> _setMacOrWin ( );
1}

sub _tryMSPowerPoint30 {
     my ( $S, $byteOrder ) = @_;
     $S -> _DocType ( cMSPP() );
     $S -> _DocRev ( "3.0" );
     $S -> _DocOS ( $byteOrder ? cMacOS() : cWindows() );
1}

#
# MS Word
#

sub _tryMSWriteAndMSWordDOS {
    my ( $S ) = @_;
    my $type = unpack("v",$S->_fSubstr(2,2));
    if ( ($type==1) || ($type==2) || ($type==3) ) {
        return $S -> _tryMSWordDOS ( );
    } else {
        if ( unpack("v",$S->_fSubstr(0x60,2)) ) {
            return $S -> _tryMSWrite ( );
        } else {
            return $S -> _tryMSWordDOS ( );
        }
    }
1}

sub _tryMSWordDOS {
    my ( $S ) = @_;
    $S -> _DocType ( cMSWord() );
    $S -> _DocRev ( "5.0" );
    $S -> _DocOS ( cDOS() );
1}

sub _tryMSWord40Mac {
    my ( $S, $byteOrder ) = @_;
    $S -> _DocType ( cMSWord() );
    $S -> _DocRev ( "4.0" );
    $S -> _DocOS ( cMacOS() );
1}

sub _tryMSWord51Mac {
     my ( $S, $byteOrder ) = @_;
     $S -> _DocType ( cMSWord() );
     $S -> _DocRev ( "5.1" );
     $S -> _DocOS ( cMacOS() );
1}

sub _tryMSWord10Win {
     my ( $S, $byteOrder ) = @_;
     $S -> _DocType ( cMSWord() );
     $S -> _DocRev ( "1.0" );
     $S -> _DocOS ( cWindows() );
     $S -> _DocLoc ( $S->_getLocaleForMS_C_L(unpack("v",$S->_fSubstr(6,2))) );
1}

sub _tryMSWord20Win {
     my ( $S, $byteOrder ) = @_;
     $S -> _DocType ( cMSWord() );
     $S -> _DocRev ( "2.0" );
     $S -> _DocOS ( cWindows() );
     $S -> _DocLoc ( $S->_getLocaleForMS_C_L(unpack("v",$S->_fSubstr(6,2))) );
1}

sub _tryOleMSWord {
     my ( $S, $dir ) = @_;
     $S -> _DocType ( cMSWord() );
     my $buf = $S->_fSubstr ( 5, 1 );
     if ( length($buf) ) {
         my $id = unpack ( "C", $buf );
         if ( $id==0xc0 ) {
             $S -> _DocRev ( "6.0" );
         } elsif ( $id==0xe0 ) {
             $S -> _DocRev ( "95" );
         } elsif ( $id==0x00 ) {
             $S -> _DocRev ( "97" );
         } elsif ( $id==0x20 ) {
             $S -> _DocRev ( "2000" );
         } else {
             # Nanu?
         }
     }
     if ( !$S->_DocRev() ) { # Hoops?
         if ( $dir->{'1Table'} || $dir->{'2Table'} ) {
             $S -> _DocRev ( "97,2000" );
         } else {
             $S -> _DocRev ( "6.0,95" );
         }
     }
     $S -> _DocLoc ( $S->_getLocaleForMS_C_L(unpack("v",$S->_fSubstr(6,2))) );
     $S -> _setMacOrWin ( );
1}

#
# MS Works
#

sub _tryOleMSWorks40 {
    my ( $S ) = @_;
    $S -> _DocType ( cMSWorks() );
    $S -> _DocRev ( "4.0" );
    $S -> _DocOS ( cWindows() );
1}

#
# MS Write
#

sub _tryMSWrite {
    my ( $S ) = @_;
    $S -> _DocType ( cMSWrite() );
    $S -> _DocOS ( cWindows() );
1}

#
# PDF
#

sub _tryPDF {
    my ( $S ) = @_;
    if ( $S->_fSubstr(4,10) =~ /-(\d+\.\d+)\b/ ) {
        $S -> _DocRev ( $1 );
        $S -> _DocType ( cPDF() );
    } else {
        return 0;
    }
1}

#
# StarWriter
#

sub _tryOleStarWriter {
    my ( $S, $dir ) = @_;
    $S -> _DocType ( cStarWriter() );

    if ( my $pps=$dir->{"\01CompObj"} ) {
        if (
            tie my %P, 'OLE::PropertySet', 
                $S->_Startup(), $S->_Var(), $S->_pps(), $S->_Doc(), "string"
        ) {
            $S -> _DocRev ( (split/\s+/,$P{0})[1] );
        }
    }
}

#
# WordPerfect
#

sub _tryWordPerfect {
    my ( $S, $byteOrder ) = @_;
    $S -> _DocType ( cWordPerfect() );
1}

##
## --  Tools  ------------------------------------------------------
##

sub _getLocaleForMS_C_L {
    my ( $S, $id ) = @_;
    # 2do!
    return $id ? "($id)" : "";
}

#
# When other tests fail this might give a clue about the origin OS.
# The root entry of MacOS-Ole-Files has no name.
#
sub _setMacOrWin {
    my ( $S ) = @_;
    if ( !$S->_DocOS() ) {
        if ( $S->_Doc()->name(0)->string() eq 'Root Entry' ) {
            $S -> _DocOS ( cWindows() );
        } else {
            $S -> _DocOS ( cMacOS() );
        }
    }
1}

sub _fSubstr {
    my ( $S, $o, $lmax, $lmin ) = @_;
    $lmax = $lmin if $lmax < $lmin;
    my $buf = "";
    my $read;
    if ( !$S->_pps() ) {
        my $fh = $S -> _fh ( );
        $fh -> seek ( $o, 0 );
        $read = $fh -> read ($buf, $lmax);
        if ( $read < $lmin ) {
            $buf = "";
        }
    } else {
        $S->_Doc()->read($S->_pps(),\$buf,$o,$lmax);
        if ( length($buf)<$lmin ) {
            $buf = "";
        }
    }
    return $buf;
}

sub _fLen {
    my ( $S ) = @_;
    if ( !$S->_pps() ) {
        return -s $S->_fileName();
    } else {
        return $S->_Doc() -> size ( $S->_pps() );
    }
}

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

Document::Info v0.01 - determine file type for Office documents

=head1 SYNOPSIS

    use Document::Info;

    if ( $Info=Document::Info->new($fileName) ) {;
        # $Info constructed, that means something has been determined.

        # Fetch the currently supported properties.
        $type = $Info -> getType ( );
        $rev  = $Info -> getRevision ( );
        $os   = $Info -> getOS ( );

        if ( $type eq $Info->cMSExcel() ) {
           # Do something. Note: when checking a type or an operating System
           # always use the string constants like cMSExcel().
        }
        if ( !$revision ) {
            # revision not determined.
        }
    } else {
        # Document type could not be determined.
    }

=head1 DESCRIPTION

The module tries to figure out the document type of Office files. It utilizes
OLE::Storage to determine the file type of Windows-documents. The module is 
in a very early state.

=head1 AUTHOR

Martin Schwartz, schwartz@cs.tu-berlin.de

=head1 SEE ALSO

file(1), lfile(1), OLE::Storage.

=cut
