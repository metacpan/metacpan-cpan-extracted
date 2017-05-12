package Encode::JavaScript::Cyrillic;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.01';

use base 'Encode::Encoding';
use Encode;

__PACKAGE__->Define('JavaScript-Cyrillic');

# russian text escape code, for unescape: (bug : %u0410 -%u044f)

my %codeMap = (
    '%u0410' => 'А', '%u0411' => 'Б', '%u0412' => 'В', '%u0413' => 'Г',
    '%u0414' => 'Д', '%u0415' => 'Е', '%u0401' => 'Ё', '%u0416' => 'Ж',
    '%u0417' => 'З', '%u0418' => 'И', '%u0419' => 'Й', '%u041A' => 'К',
    '%u041B' => 'Л', '%u041C' => 'М', '%u041D' => 'Н', '%u041E' => 'О',
    '%u041F' => 'П', '%u0420' => 'Р', '%u0421' => 'С', '%u0422' => 'Т',
    '%u0423' => 'У', '%u0424' => 'Ф', '%u0425' => 'Х', '%u0426' => 'Ц',
    '%u0427' => 'Ч', '%u0428' => 'Ш', '%u0429' => 'Щ', '%u042A' => 'Ъ',
    '%u042B' => 'Ы', '%u042C' => 'Ь', '%u042D' => 'Э', '%u042E' => 'Ю',
    '%u042F' => 'Я',
    '%u0430' => 'а', '%u0431' => 'б', '%u0432' => 'в', '%u0433' => 'г',
    '%u0434' => 'д', '%u0435' => 'е', '%u0451' => 'ё', '%u0436' => 'ж',
    '%u0437' => 'з', '%u0438' => 'и', '%u0439' => 'й', '%u043A' => 'к',
    '%u043B' => 'л', '%u043C' => 'м', '%u043D' => 'н', '%u043E' => 'о',
    '%u043F' => 'п', '%u0440' => 'р', '%u0441' => 'с', '%u0442' => 'т',
    '%u0443' => 'у', '%u0444' => 'ф', '%u0445' => 'х', '%u0446' => 'ц',
    '%u0447' => 'ч', '%u0448' => 'ш', '%u0449' => 'щ', '%u044A' => 'ъ',
    '%u044B' => 'ы', '%u044C' => 'ь', '%u044D' => 'э', '%u044E' => 'ю',
    '%u044F' => 'я'
);

my %revMap = reverse %codeMap;

sub decode($$;$){
    my($obj,$buf,$chk) = @_;
    $_[1] = '' if $chk;
    my ($arr,$res);
    if ( $buf =~/%u04/ ){
       $arr = [split '%',$buf];
    
        shift @$arr;
        map{$_ ='%'.$_} @$arr;
        $arr = _replace($arr,\%codeMap);
        $res = join '',@$arr;
    }
    else {
        $res = $buf;
    }
    
    return $res;
}

sub encode($$;$){
    my($obj,$buf,$chk) = @_;
    $_[1] = '' if $chk;
    my $values = join '|',values %codeMap;
    
    my $regexp = qr/$values/;
    
    $buf =~ s/($regexp)/_translateSymbols($1)/ge;
        
    return $buf;
}

sub _replace($$) {
    my($arrRef,$hashRef) = @_;
    foreach (@$arrRef){
        if( exists $hashRef->{$_}){
            $_=$hashRef->{$_};
        }
    }
    return $arrRef;
}

sub _translateSymbols {
    my $sym = shift;
    
    if( exists $revMap{$sym}){
        $sym = $revMap{$sym};        
    }
    return $sym;
}

1;
__END__

=head1 NAME

Encode::JavaScript::Cyrillic - Javascript bug fix for cyrillic((bug : %u0410 -%u044f))

=head1 SYNOPSIS
  
  use Encode;  
  use Encode::JavaScript::Cyrillic;
  my $decString = '%u0401%u0410%u0411%u0412';
  my $encString = 'ЁАБВ';
  my $res = decode('JavaScript-Cyrillic',$decString);
  $res = encode('JavaScript-Cyrillic',$encString);

=head1 DESCRIPTION
   
  Encode::JavaScript::Cyrillic - is Encoding to represent javascript characters from escape function  

=head1 SEE ALSO

L<Encode>

=head1 AUTHOR

harper, E<lt>plcgi1@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by harper

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
