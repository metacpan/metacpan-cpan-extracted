use Test::More;

use_ok('JS::JJ');

my $code = q{aaaa=~[];aaaa={___:++aaaa,$$$$:(![]+"")[aaaa],__$:++aaaa,$_$_:(![]+"")[aaaa],_$_:++aaaa,$_$$:({}+"")[aaaa],$$_$:(aaaa[aaaa]+"")[aaaa],_$$:++aaaa,$$$_:(!""+"")[aaaa],$__:++aaaa,$_$:++aaaa,$$__:({}+"")[aaaa],$$_:++aaaa,$$$:++aaaa,$___:++aaaa,$__$:++aaaa};aaaa.$_=(aaaa.$_=aaaa+"")[aaaa.$_$]+(aaaa._$=aaaa.$_[aaaa.__$])+(aaaa.$$=(aaaa.$+"")[aaaa.__$])+((!aaaa)+"")[aaaa._$$]+(aaaa.__=aaaa.$_[aaaa.$$_])+(aaaa.$=(!""+"")[aaaa.__$])+(aaaa._=(!""+"")[aaaa._$_])+aaaa.$_[aaaa.$_$]+aaaa.__+aaaa._$+aaaa.$;aaaa.$$=aaaa.$+(!""+"")[aaaa._$$]+aaaa.__+aaaa._+aaaa.$+aaaa.$$;aaaa.$=(aaaa.___)[aaaa.$_][aaaa.$_];aaaa.$(aaaa.$(aaaa.$$+"\""+aaaa.$_$_+(![]+"")[aaaa._$_]+aaaa.$$$_+"\\"+aaaa.__$+aaaa.$$_+aaaa._$_+aaaa.__+"(\\\"\\"+aaaa.__$+aaaa._$_+aaaa.___+aaaa._$+"\\"+aaaa._+aaaa.___+aaaa.___+aaaa.$$$_+aaaa.$$$+aaaa._$+"\\"+aaaa.__$+aaaa.$$_+aaaa._$$+"\\"+aaaa.$__+aaaa.___+aaaa.$$_$+aaaa.$$$_+"\\"+aaaa.$__+aaaa.___+"\\"+aaaa.__$+aaaa.___+aaaa._$$+aaaa.$_$_+(![]+"")[aaaa._$_]+aaaa.$$_$+aaaa.$_$_+"\\"+aaaa.__$+aaaa.$$_+aaaa._$$+"\\\");"+"\"")())();};
is(JS::JJ::jj_decode($code), 'alert("Poços de Caldas");', 'Decode');
$code =~ s/\\/\\\\/g;
$code =~ s/\\\\\\\\/\\\\\\/g;
$code =~ s/\\\\\"\"/\\\"\"/g;
is(JS::JJ::jj_encode('alert("Poços de Caldas");', "aaaa"), $code, 'Encode');

done_testing;