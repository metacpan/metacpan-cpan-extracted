package JS::JJ;

use strict;
use warnings;
use Encode qw/
    encode_utf8
    decode_utf8
/;

use base qw/Exporter/;

our @EXPORT_OK = qw/
   jj_encode
   jj_decode
/;

our $VERSION = '0.01';

our $jj_array = ['___', '__$', '_$_', '_$$', '$__', '$_$', '$$_', '$$$', '$___', '$__$', '$_$_', '$_$$', '$$__', '$$_$', '$$$_', '$$$$'];

sub jj_encode {
    my ($value, $key) = @_;
    
    $key ||= '$';
    
    my $encode = '';
    my $temp = '';
    
    my @chars = split //, decode_utf8($value);
    
    for (my $i=0; $i<scalar(@chars); $i++) {
        my $hex = ord $chars[$i];
        
        if ($hex == 0x22 || $hex == 0x5c) {          
            $temp .= '\\\\\\' . $chars[$i];            
        } elsif ((0x21 <= $hex && $hex <= 0x2f) || (0x3a <= $hex && $hex <= 0x40) || (0x5b <= $hex && $hex <= 0x60) || (0x7b <= $hex && $hex <= 0x7f)) {
            $temp .= $chars[$i];
        } elsif ((0x30 <= $hex && $hex <= 0x39) || (0x61 <= $hex && $hex <= 0x66)) {
            $encode .= '"' . $temp . '"+' if $temp;
            $encode .= $key . '.' . $jj_array->[$hex < 0x40 ? $hex - 0x30 : $hex - 0x57] . '+';
            
            $temp = '';            
        } elsif ($hex == 0x6c || $hex == 0x6f || $hex == 0x74 || $hex == 0x75) {
            $encode .= '"' . $temp . '"+' if $temp;
            $encode .= '(![]+"")[' . $key . '._$_]+' if $hex == 0x6c;
            $encode .=               $key . '._$+'   if $hex == 0x6f;
            $encode .=               $key . '.__+'   if $hex == 0x74;
            $encode .=               $key . '._+'    if $hex == 0x75;
            
            $temp = '';          
        } else {
            $encode .= '"';
            $encode .= $temp if $temp;
            
            if ($hex < 128) {
                my @oct = split //, sprintf "%o", $hex;
                
                for (keys @oct) {
                    $oct[$_] = $key . '.' . $jj_array->[$oct[$_]] . '+' if $oct[$_] =~ /[0-7]/;
                }
                
                $encode .= '\\\\' . '"+' . join '', @oct;                
            } else {
                my @hex = map { chr } unpack 'U*', sprintf "%04x", $hex;
                
                for (keys @hex) {
                    $hex[$_] = $key . '.' . $jj_array->[hex($hex[$_])] . '+' if $hex[$_] =~ /[0-9a-f]/;
                }
                
                $encode .= '\\\\' . '"+' . $key . '._+' . join '', @hex;
                
            }
            
            $temp = '';            
        }
    }
    
    return &_join_encode($encode, $key, $temp);
}

sub jj_decode {
    my $value = shift;
    
    my ($key) = $value =~ /(.*)=~\[\];/;
    $key =~ s/^\s+|\s+$//;
    $key =~ s/(\$)/\\\$/g;
    
    if ($key) {
        my $jj = &_clean($value);
                  
        my $regex = $key . '.';
        $regex   .= join '|' . $key . '.', @$jj_array;        

        # hex        
        my $hex_n = 4 * length($key) + 24;
        
        my (@hex) = $jj =~ /(\"?\\\"\+${key}\._\+[${regex}\+]{${hex_n}})/g;
                                     
        for (@hex) {
            my (@n) = $_ =~ /(\+)/g;
            $_ =~ s/\+[^\+]+$/\+/ if scalar(@n) > 4;
            
            my $l = &_replace_hex($key, $_);
            $l =~ s/^.+\+//g;
            $l = encode_utf8(chr(hex($l)));
            
            $jj =~ s/\Q${_}\E\"?/${l}/;
        }
        
        $jj = &_replace_hex($key, $jj);
        
        # oct
        my (@oct) = $jj =~ /(\\\"\+\d{2,3})/g;
        
        for (@oct) {
            my ($oct) = $_ =~ /(\d+)$/;
            $oct =~ s/\d{1}$// if $oct > 177;
            
            my $l = chr(oct($oct));
            $jj =~ s/\\\"\+${oct}\"?/${l}/;
        }
        
        # lotu
        $jj =~ s/\(!\[\]\+""\)\[${key}\._\$_\]\+\"?/l/gs;
        $jj =~ s/${key}\._\$\+\"?/o/gs;
        $jj =~ s/${key}\.__\+\"?/t/gs;
        $jj =~ s/${key}\._\+\"?/u/gs;
        
        # remove \\
        $jj =~ s/(\"\"\+)/\"/g;
        $jj =~ s/\Q\\\E//g;        
        
        return $jj;
    }
}

sub _clean {
    my $jj = shift;
    
    my ($new) = $jj =~ /.\$\$\+"\\""\+(.*?)\"\+"\\"/;
    $new =~ s/^\s+|\s+$//;
    
    return $new;
}

sub _replace_hex {
    my ($key, $value) = @_;
    
    $value =~ s/${key}\.\$\$\$\$\+\"?/f/g;
    $value =~ s/${key}\.\$\$\$_\+\"?/e/g;
    $value =~ s/${key}\.\$\$_\$\+\"?/d/g;
    $value =~ s/${key}\.\$\$__\+\"?/c/g;
    $value =~ s/${key}\.\$_\$\$\+\"?/b/g;
    $value =~ s/${key}\.\$_\$_\+\"?/a/g;
    $value =~ s/${key}\.\$__\$\+\"?/9/g;
    $value =~ s/${key}\.\$___\+\"?/8/g;
    $value =~ s/${key}\.\$\$\$\+\"?/7/g;
    $value =~ s/${key}\.\$\$_\+\"?/6/g;
    $value =~ s/${key}\.\$_\$\+\"?/5/g;
    $value =~ s/${key}\.\$__\+\"?/4/g;
    $value =~ s/${key}\._\$\$\+\"?/3/g;
    $value =~ s/${key}\._\$_\+\"?/2/g;
    $value =~ s/${key}\.__\$\+\"?/1/g;
    $value =~ s/${key}\.___\+\"?/0/g;

    return $value;
}

sub _join_encode {
    my ($encode, $key, $temp) = @_;
    
    $encode .= '"' . $temp . '"+' if $temp;    
    $encode  = $key . '=~[];' .
               $key . '={___:++' .
               $key . ',$$$$:(![]+"")[' .
               $key . '],__$:++' .
               $key . ',$_$_:(![]+"")[' .
               $key . '],_$_:++' .
               $key . ',$_$$:({}+"")[' .
               $key . '],$$_$:(' .
               $key . '[' .
               $key . ']+"")[' .
               $key . '],_$$:++' .
               $key . ',$$$_:(!""+"")[' .
               $key . '],$__:++' .
               $key . ',$_$:++' .
               $key . ',$$__:({}+"")[' .
               $key . '],$$_:++' .
               $key . ',$$$:++' .
               $key . ',$___:++' .
               $key . ',$__$:++' .
               $key . '};' .
               $key . '.$_=' . '(' .
               $key . '.$_=' .
               $key . '+"")[' .
               $key . '.$_$]+' . '(' .
               $key . '._$=' .
               $key . '.$_[' .
               $key . '.__$])+' . '(' .
               $key . '.$$=(' .
               $key . '.$+"")[' .
               $key . '.__$])+' . '((!' .
               $key . ')+"")[' .
               $key . '._$$]+' . '(' .
               $key . '.__=' .
               $key . '.$_[' .
               $key . '.$$_])+' . '(' .
               $key . '.$=(!""+"")[' .
               $key . '.__$])+' . '(' .
               $key . '._=(!""+"")[' .
               $key . '._$_])+' .
               $key . '.$_[' .
               $key . '.$_$]+' .
               $key . '.__+' .
               $key . '._$+' .
               $key . '.$;' .
               $key . '.$$=' .
               $key . '.$+' . '(!""+"")[' .
               $key . '._$$]+' .
               $key . '.__+' .
               $key . '._+' .
               $key . '.$+' .
               $key . '.$$;' .
               $key . '.$=(' .
               $key . '.___)[' .
               $key . '.$_][' .
               $key . '.$_];' .
               $key . '.$(' .
               $key . '.$(' .
               $key . '.$$+"\\""+' . $encode . '"\\"")())();';
    
    return $encode;    
}

1;

=encoding utf8

=head1 NAME

JS::JJ - Encode and Decode JJ

=head1 SYNOPSIS

    use JS::JJ qw/
        jj_encode
        jj_decode
    /;
    
    my $jj = jj_encode($js);
    
    my $js = jj_decode($jj);
    
=head1 DESCRIPTION
    
This module provides methods for encode and decode JJ.

=head1 METHODS

=head2 jj_encode

    my $jj = jj_encode($js);
    
Returns the jj.

=head2 jj_decode

    my $js = jj_decode($jj);
    
Returns the javascript.

=head1 SEE ALSO

L<Original encoder jjencode|http://utf-8.jp/public/jjencode.html>

=head1 AUTHOR
 
Lucas Tiago de Moraes C<lucastiagodemoraes@gmail.com>
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2020 by Lucas Tiago de Moraes.
 
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
 
=cut