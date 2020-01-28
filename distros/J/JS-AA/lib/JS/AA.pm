package JS::AA;

use strict;
use warnings;
use Encode qw/
    encode_utf8
    decode_utf8
/;

use base qw/Exporter/;

our @EXPORT_OK = qw/
   aa_encode
   aa_decode
/;

our $VERSION = 0.03;

our $aa_array = [        
    "(c^_^o)",
    "(ﾟΘﾟ)",
    "((o^_^o) - (ﾟΘﾟ))",
    "(o^_^o)",
    "(ﾟｰﾟ)",
    "((ﾟｰﾟ) + (ﾟΘﾟ))",
    "((o^_^o) +(o^_^o))",
    "((ﾟｰﾟ) + (o^_^o))",
    "((ﾟｰﾟ) + (ﾟｰﾟ))",
    "((ﾟｰﾟ) + (ﾟｰﾟ) + (ﾟΘﾟ))",
    "(ﾟДﾟ) .ﾟωﾟﾉ",
    "(ﾟДﾟ) .ﾟΘﾟﾉ",
    "(ﾟДﾟ) ['c']",
    "(ﾟДﾟ) .ﾟｰﾟﾉ",
    "(ﾟДﾟ) .ﾟДﾟﾉ",
    "(ﾟДﾟ) [ﾟΘﾟ]"        
];

our $aa_hash = {        
    "(c^_^o)" => 0,
    "(ﾟΘﾟ)" => 1,
    "((o^_^o) - (ﾟΘﾟ))" => 2,
    "(o^_^o)" => 3,
    "(ﾟｰﾟ)" => 4,
    "((ﾟｰﾟ) + (ﾟΘﾟ))" => 5,
    "((o^_^o) +(o^_^o))" => 6,
    "((ﾟｰﾟ) + (o^_^o))" => 7,
    "((ﾟｰﾟ) + (ﾟｰﾟ))" => 8,
    "((ﾟｰﾟ) + (ﾟｰﾟ) + (ﾟΘﾟ))" => 9,
    "(ﾟДﾟ) .ﾟωﾟﾉ" => 10,
    "(ﾟДﾟ) .ﾟΘﾟﾉ" => 11,
    "(ﾟДﾟ) ['c']" => 12,
    "(ﾟДﾟ) .ﾟｰﾟﾉ" => 13,
    "(ﾟДﾟ) .ﾟДﾟﾉ" => 14,
    "(ﾟДﾟ) [ﾟΘﾟ]" => 15        
};

sub aa_encode {
    my $value = shift;
    
    my $encode = &_begin;
    
    my @chars = unpack "U*", decode_utf8($value);
    
    for my $char (@chars) {
        $encode .= "(ﾟДﾟ)[ﾟεﾟ]+";
        
        if ($char <= 127) {
            for (map { $_ - 48 } unpack 'U*', sprintf("%o", $char)) {
                $encode .= $aa_array->[$_] . "+ ";
            }
        } else {
            $encode .= "(oﾟｰﾟo)+ ";
            
            for (map { chr } unpack 'U*', sprintf( "%04x", $char) ) {
                $encode .= $aa_array->[hex($_)] . "+ ";
            }            
        }
    }
    
    $encode .= &_end;

    return $encode;        
}

sub aa_decode {
    my $value = shift;
    
    my @data = &_split($value);
    
    my $decode = '';
    
    for my $data (@data) {
        my $number;
        if ($data =~ /\Q(oﾟｰﾟo)+\E/) {
            $data =~ s/\Q(oﾟｰﾟo)+ \E//;
            
            $number .= sprintf("%x", $aa_hash->{$_}) for &_list($data);
            
            $decode .= encode_utf8(chr(hex($number))) if $number;            
        } else {
            $number .= $aa_hash->{$_} for &_list($data);
            
            $decode .= chr(oct(int($number))) if $number;
        }
    }
    
    return $decode;
}

sub _begin {
    return "ﾟωﾟﾉ= /｀ｍ´）ﾉ ~┻━┻   //*´∇｀*/ ['_']; o=(ﾟｰﾟ)  =_=3; c=(ﾟΘﾟ) =(ﾟｰﾟ)-(ﾟｰﾟ); "
         . "(ﾟДﾟ) =(ﾟΘﾟ)= (o^_^o)/ (o^_^o);"
         . "(ﾟДﾟ)={ﾟΘﾟ: '_' ,ﾟωﾟﾉ : ((ﾟωﾟﾉ==3) +'_') [ﾟΘﾟ] "
         . ",ﾟｰﾟﾉ :(ﾟωﾟﾉ+ '_')[o^_^o -(ﾟΘﾟ)] "
         . ",ﾟДﾟﾉ:((ﾟｰﾟ==3) +'_')[ﾟｰﾟ] }; (ﾟДﾟ) [ﾟΘﾟ] =((ﾟωﾟﾉ==3) +'_') [c^_^o];"
         . "(ﾟДﾟ) ['c'] = ((ﾟДﾟ)+'_') [ (ﾟｰﾟ)+(ﾟｰﾟ)-(ﾟΘﾟ) ];"
         . "(ﾟДﾟ) ['o'] = ((ﾟДﾟ)+'_') [ﾟΘﾟ];"
         . "(ﾟoﾟ)=(ﾟДﾟ) ['c']+(ﾟДﾟ) ['o']+(ﾟωﾟﾉ +'_')[ﾟΘﾟ]+ ((ﾟωﾟﾉ==3) +'_') [ﾟｰﾟ] + "
         . "((ﾟДﾟ) +'_') [(ﾟｰﾟ)+(ﾟｰﾟ)]+ ((ﾟｰﾟ==3) +'_') [ﾟΘﾟ]+"
         . "((ﾟｰﾟ==3) +'_') [(ﾟｰﾟ) - (ﾟΘﾟ)]+(ﾟДﾟ) ['c']+"
         . "((ﾟДﾟ)+'_') [(ﾟｰﾟ)+(ﾟｰﾟ)]+ (ﾟДﾟ) ['o']+"
         . "((ﾟｰﾟ==3) +'_') [ﾟΘﾟ];(ﾟДﾟ) ['_'] =(o^_^o) [ﾟoﾟ] [ﾟoﾟ];"
         . "(ﾟεﾟ)=((ﾟｰﾟ==3) +'_') [ﾟΘﾟ]+ (ﾟДﾟ) .ﾟДﾟﾉ+"
         . "((ﾟДﾟ)+'_') [(ﾟｰﾟ) + (ﾟｰﾟ)]+((ﾟｰﾟ==3) +'_') [o^_^o -ﾟΘﾟ]+"
         . "((ﾟｰﾟ==3) +'_') [ﾟΘﾟ]+ (ﾟωﾟﾉ +'_') [ﾟΘﾟ]; "
         . "(ﾟｰﾟ)+=(ﾟΘﾟ); (ﾟДﾟ)[ﾟεﾟ]='\\\\'; "
         . "(ﾟДﾟ).ﾟΘﾟﾉ=(ﾟДﾟ+ ﾟｰﾟ)[o^_^o -(ﾟΘﾟ)];"
         . "(oﾟｰﾟo)=(ﾟωﾟﾉ +'_')[c^_^o];"    
         . "(ﾟДﾟ) [ﾟoﾟ]='\\\"';"
         . "(ﾟДﾟ) ['_'] ( (ﾟДﾟ) ['_'] (ﾟεﾟ+"
         . "(ﾟДﾟ)[ﾟoﾟ]+ ";
}

sub _end {
    return "(ﾟДﾟ)[ﾟoﾟ]) (ﾟΘﾟ)) ('_');";
}

sub _split {
    my $aa = shift;
    
    my ($new) = $aa =~ /\Q[ﾟoﾟ]+ \E(.*?)\Q(ﾟДﾟ)[ﾟoﾟ]) (ﾟΘﾟ)) ('_');\E/;
    
    my @array = split(/\Q(ﾟДﾟ)[ﾟεﾟ]+\E/, $new);
    
    return @array;
}

sub _list {
    my $data = shift;
    
    my (@array) = $data =~ /(\Q(c^_^o)\E|\Q(ﾟΘﾟ)\E|\Q((o^_^o) - (ﾟΘﾟ))\E|\Q(o^_^o)\E|\Q(ﾟｰﾟ)\E|\Q((ﾟｰﾟ) + (ﾟΘﾟ))\E|\Q((o^_^o) +(o^_^o))\E|\Q((ﾟｰﾟ) + (o^_^o))\E|\Q((ﾟｰﾟ) + (ﾟｰﾟ))\E|\Q((ﾟｰﾟ) + (ﾟｰﾟ) + (ﾟΘﾟ))\E|\Q(ﾟДﾟ) .ﾟωﾟﾉ\E|\Q(ﾟДﾟ) .ﾟΘﾟﾉ\E|\Q(ﾟДﾟ) ['c']\E|\Q(ﾟДﾟ) .ﾟｰﾟﾉ\E|\Q(ﾟДﾟ) .ﾟДﾟﾉ\E|\Q(ﾟДﾟ) [ﾟΘﾟ]\E)/g;
    
    return @array;
}

1;

=encoding utf8

=head1 NAME

JS::AA - Encode and Decode AA

=head1 SYNOPSIS

    use JS::AA qw/
        aa_encode
        aa_decode
    /;
    
    my $aa = aa_encode($js);
    
    my $js = aa_decode($aa);
    
=head1 DESCRIPTION
    
This module provides methods for encode and decode AA.

=head1 METHODS

=head2 aa_encode

    my $aa = aa_encode($js);
    
Returns the aa.

=head2 aa_decode

    my $js = aa_decode($aa);
    
Returns the javascript.

=head1 SEE ALSO

L<Original encoder aaencode|http://utf-8.jp/public/aaencode.html>

L<Original decoder aadecode|https://cat-in-136.github.io/2010/12/aadecode-decode-encoded-as-aaencode.html>

=head1 AUTHOR
 
Lucas Tiago de Moraes C<lucastiagodemoraes@gmail.com>
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2020 by Lucas Tiago de Moraes.
 
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
 
=cut