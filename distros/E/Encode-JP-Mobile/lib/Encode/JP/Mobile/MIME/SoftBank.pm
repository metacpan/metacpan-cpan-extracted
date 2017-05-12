package Encode::JP::Mobile::MIME::SoftBank;
use strict;
Encode::Alias::define_alias('MIME-Header-JP-Mobile-SoftBank' => 'MIME-Header-JP-Mobile-SoftBank-UTF8');
Encode::Alias::define_alias('MIME-Header-JP-Mobile-Vodafone' => 'MIME-Header-JP-Mobile-SoftBank-UTF8');

sub charset_to_encoding {
    my ($self, $charset) = @_;
    
    if (!$charset || $charset =~ /utf-8/i) {
        $charset = 'x-utf8-softbank';
    }
    elsif ($charset =~ /shift_jis/i) {
        $charset = 'x-sjis-softbank';
    }
    
    Encode::find_encoding($charset);
}


package Encode::JP::Mobile::MIME::SoftBank::UTF8;
use strict;
use base 'Encode::JP::Mobile::MIME';
__PACKAGE__->Define('MIME-Header-JP-Mobile-SoftBank-UTF8');

Encode::Alias::define_alias('MIME-Header-JP-Mobile-Vodafone-UTF8' => 'MIME-Header-JP-Mobile-SoftBank-UTF8');

sub subject_encoding {
    Encode::find_encoding('x-utf8-softbank');
}

sub charset_to_encoding {
    Encode::JP::Mobile::MIME::SoftBank::charset_to_encoding(@_);
}


package Encode::JP::Mobile::MIME::SoftBank::SJIS;
use strict;
use base 'Encode::JP::Mobile::MIME';
__PACKAGE__->Define('MIME-Header-JP-Mobile-SoftBank-SJIS');

Encode::Alias::define_alias('MIME-Header-JP-Mobile-Vodafone-SJIS' => 'MIME-Header-JP-Mobile-SoftBank-SJIS');

sub subject_encoding {
    Encode::find_encoding('x-sjis-softbank');
}

sub charset_to_encoding {
    Encode::JP::Mobile::MIME::SoftBank::charset_to_encoding(@_);
}

1;
