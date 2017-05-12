package Encode::JP::Mobile::MIME::AirH;
use strict;
Encode::Alias::define_alias('MIME-Header-JP-Mobile-Airedge' => 'MIME-Header-JP-Mobile-AirH-SJIS');
Encode::Alias::define_alias('MIME-Header-JP-Mobile-AirH'    => 'MIME-Header-JP-Mobile-AirH-SJIS');


package Encode::JP::Mobile::MIME::AirH::SJIS;
use strict;
use base 'Encode::JP::Mobile::MIME';
__PACKAGE__->Define('MIME-Header-JP-Mobile-AirH-SJIS');

Encode::Alias::define_alias('MIME-Header-JP-Mobile-Airedge-SJIS' => 'MIME-Header-JP-Mobile-AirH-SJIS');

sub subject_encoding {
    Encode::find_encoding('x-sjis-airh');
}

sub charset_to_encoding {
    my ($self, $charset) = @_;
    
    if (!$charset || $charset =~ /iso-2022-jp/i) {
        $charset = 'x-iso-2022-jp-airh';
    }
    elsif ($charset =~ /shift_jis/i) {
        $charset = 'x-sjis-airh';
    }
    
    Encode::find_encoding($charset);
}

1;
