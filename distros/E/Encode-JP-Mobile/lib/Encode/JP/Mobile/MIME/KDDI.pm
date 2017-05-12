package Encode::JP::Mobile::MIME::KDDI;
use strict;
Encode::Alias::define_alias('MIME-Header-JP-Mobile-KDDI'  => 'MIME-Header-JP-Mobile-KDDI-SJIS');
Encode::Alias::define_alias('MIME-Header-JP-Mobile-EZweb' => 'MIME-Header-JP-Mobile-KDDI-SJIS');

sub charset_to_encoding {
    my ($self, $charset) = @_;
    
    if (!$charset || $charset =~ /iso-2022-jp/i) {
        $charset = 'x-iso-2022-jp-kddi-auto';
    }
    elsif ($charset =~ /shift_jis/i) {
        $charset = 'x-sjis-kddi-auto';
    }
    
    Encode::find_encoding($charset);
}


package Encode::JP::Mobile::MIME::KDDI::SJIS;
use strict;
use base 'Encode::JP::Mobile::MIME';
__PACKAGE__->Define('MIME-Header-JP-Mobile-KDDI-SJIS');

Encode::Alias::define_alias('MIME-Header-JP-Mobile-EZweb-SJIS' => 'MIME-Header-JP-Mobile-KDDI-SJIS');

sub subject_encoding {
    Encode::find_encoding('x-sjis-kddi-auto');
}

sub charset_to_encoding {
    Encode::JP::Mobile::MIME::KDDI::charset_to_encoding(@_);
}

sub encode($$;$){
    my ($self, $str, $check) = @_;
    
    $str = $self->subject_encoding->encode($str, $check);
    return $str;
}

1;
