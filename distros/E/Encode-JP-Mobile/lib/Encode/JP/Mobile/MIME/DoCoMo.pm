package Encode::JP::Mobile::MIME::DoCoMo;
use strict;
Encode::Alias::define_alias('MIME-Header-JP-Mobile-DoCoMo' => 'MIME-Header-JP-Mobile-DoCoMo-SJIS');
Encode::Alias::define_alias('MIME-Header-JP-Mobile-iMode'  => 'MIME-Header-JP-Mobile-DoCoMo-SJIS');


package Encode::JP::Mobile::MIME::DoCoMo::SJIS;
use strict;
use base 'Encode::JP::Mobile::MIME';
__PACKAGE__->Define('MIME-Header-JP-Mobile-DoCoMo-SJIS');

Encode::Alias::define_alias('MIME-Header-JP-Mobile-iMode-SJIS' => 'MIME-Header-JP-Mobile-DoCoMo-SJIS');

sub subject_encoding {
    Encode::find_encoding('x-sjis-docomo');
}

sub charset_to_encoding {
    my ($self, $charset) = @_;
    
    if (!$charset || $charset =~ /shift_jis/i) {
        $charset = 'x-sjis-docomo';
    }
    
    Encode::find_encoding($charset);
}

1;
