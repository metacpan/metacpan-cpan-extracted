#############################################################################
## Name:        LZW.pm
## Purpose:     LibZip::Build::LZW
## Author:      Graciliano M. P.
## Modified by:
## Created:     2004-06-06
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
##
## This file comes from Compress::LZW.
##
## AUTHOR 
##
## Sean O'Rourke, <seano@cpan.org> - Original author, Compress::SelfExtracting
## Matt Howard <mhoward@hattmoward.org> - Compress::LZW
##
#############################################################################

package LibZip::Build::LZW ;
use 5.006 ;

use strict qw(vars) ;
use vars qw($VERSION) ;

$VERSION = '0.01' ;

use LibZip::CORE ;
use MIME::Base64 qw() ;

########
# VARS #
########

my (%SA);

my $LZ = sub { pack 'S*', @_ } ;

my $UNLZ = sub { unpack 'S*', shift; } ;

############
# COMPRESS #
############

sub compress {
    my ($str) = @_;
    my $bits = 16;
    my $p = ''; 
    my %d = map{(chr $_, $_)} 0..255;
    my @o = ();
    my $ncw = 256;
    
    for (split '', $str) {
        if (exists $d{$p.$_}) {
            $p .= $_;
        } else {
            push @o, $d{$p};
            $d{$p.$_} = $ncw++;
            $p = $_;
        }
    }
    push @o, $d{$p};
    
    if ($ncw < 1<<16) {
        return $LZ->(@o);
    } else {
        warn "Sorry, code-word overflow";
    }
}

##############
# DECOMPRESS #
##############

sub decompress {
    my ($str) = @_;
    my $bits = 16 ;
    
    my %d = (map{($_, chr $_)} 0..255);
    my $ncw = 256;
    my $ret = '';
    
    my ($p, @code) = $UNLZ->($str);
    
    $ret .= $d{$p};
    for (@code) {
        if (exists $d{$_}) {
            $ret .= $d{$_};
            $d{$ncw++} = $d{$p}.substr($d{$_}, 0, 1);
        } else {
            my $dp = $d{$p};
            unless ($_ == $ncw++) { warn "($_ == $ncw)?! Check your table size!" };
            $ret .= ($d{$_} = $dp.substr($dp, 0, 1));
        }
        $p = $_;
    }
    $ret;
}

##################
# DEC_STANDALONE #
##################

sub dec_standalone {
my($s)=@_;my%d=(map{($_,chr$_)}0..255);my$n=256;my$r='';my($p,@c)=unpack('S*',$s);
$r.=$d{$p};for(@c){if(exists $d{$_}){$r.=$d{$_};$d{$n++}=$d{$p}.substr($d{$_}, 0, 1);
}else{my$dp=$d{$p};unless($_==$n++){warn"LZW ERROR!"};$r.=($d{$_}=$dp.substr($dp,0,1));}$p=$_;}$r;
}

sub decode_base64_pure_perl {
local($^W)=0;my$s=shift;my$r="";$s=~tr|A-Za-z0-9+=/||cd;$s=~s/=+$//;$s=~tr|A-Za-z0-9+/| -_|;
while($s=~/(.{1,60})/gs){my$l=chr(32+length($1)*3/4);$r.=unpack("u",$l.$1);}$r;
}

##########
# BASE64 #
##########

sub compress_base64 { return MIME::Base64::encode_base64( compress($_[0]) ) ;}
sub uncompress_base64 { return decompress( MIME::Base64::decode_base64($_[0]) ) ;}

#######
# END #
#######

1;


