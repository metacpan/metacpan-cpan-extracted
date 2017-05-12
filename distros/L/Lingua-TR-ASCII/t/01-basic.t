use strict;
use warnings;
use utf8;
use Test::More qw( no_plan );

use Lingua::TR::ASCII;
use Lingua::TR::ASCII::Data;

my @ascii = (
    q{Acimasizca acelya gorunen bir sacmaliktansa acilip sacilmak...},
    q{Acisindan bagirip cagirarak sacma sozler soylemek.},
    q{Bogurtuler opucukler.},
    q{BUYUKCE BIR TOPAC TOPARLAGI VE DE YUMAGI yumagi.},
    q{Bilgisayarlarda uc adet bellek turu bulunur. Islemci icerisinde yer alan yazmaclar, son derece hizli ancak cok sinirli hafizaya sahiptirler. Islemcinin cok daha yavas olan ana bellege olan erisim gereksinimini gidermek icin kullanilirlar. Ana bellek ise Rastgele erisimli bellek (REB veya RAM, Random Access Memory) ve Salt okunur bellek (SOB veya ROM, Read Only Memory) olmak uzere ikiye ayrilir. RAM'a istenildigi zaman yazilabilir ve icerigi ancak guc surdugu surece korunur. ROM'sa sadece okunabilen ve onceden yerlestirilmis bilgiler icerir. Bu icerigi gucten bagimsiz olarak korur. Ornegin herhangi bir veri veya komut RAM'da bulunurken, bilgisayar donanimini duzenleyen BIOS ROM'da yer alir.},
    q{1969 yilinda 15 yasindayken 1000 lira transfer parasi alarak Camialti Spor Kulubu'nde amator futbolcu oldu. Daha sonra IETT Spor Kulubu'nun amator futbolcusu oldu. 1976 yilinda, IETT sampiyon oldugunda, Erdogan da bu takimda oynamaktaydi. Erokspor Kulubunde de futbola devam etti ve 16 yillik futbol yasamini 12 Eylul 1980 Askeri Darbesi sonrasinda birakti ve daha fazla siyasi faaliyet...},
    q{Opusmegi cagristiran catirtilar.},
    q{Hadi bir masal uyduralim, icinde mutlu, doygun, telassiz durdugumuz.},
    q{Yukarida belirtilmis olan faturalandirma tarihinden itibaren odeme suresi 20 gundur. Odeme yapilirken gonderen aciklamasi olarak, tarafiniza verilen telefon numarasi ve ilgili fatura numarasinin mutlaka belirtilmesi gerekmektedir.},
);

my @turkish = (
    q{Acımasızca açelya görünen bir saçmalıktansa açılıp saçılmak...},
    q{Acısından bağırıp çağırarak saçma sözler söylemek.},
    q{Böğürtüler öpücükler.},
    q{BÜYÜKÇE BİR TOPAÇ TOPARLAĞI VE DE YUMAĞI yumağı.},
    q{Bilgisayarlarda üç adet bellek turu bulunur. İşlemci içerisinde yer alan yazmaçlar, son derece hızlı ancak çok sınırlı hafızaya sahiptirler. İşlemcinin çok daha yavaş olan ana bellege olan erişim gereksinimini gidermek için kullanılırlar. Ana bellek ise Rastgele erişimli bellek (REB veya RAM, Random Access Memory) ve Salt okunur bellek (SOB veya ROM, Read Only Memory) olmak üzere ikiye ayrılır. RAM'a istenildiği zaman yazılabilir ve içeriği ancak güç sürdüğü sürece korunur. ROM'sa sadece okunabilen ve önceden yerleştirilmiş bilgiler içerir. Bu içeriği güçten bağımsız olarak korur. Örneğin herhangi bir veri veya komut RAM'da bulunurken, bilgisayar donanımını düzenleyen BİOS ROM'da yer alır.},
    q{1969 yılında 15 yaşındayken 1000 lira transfer parası alarak Camialtı Spor Kulübü'nde amatör futbolcu oldu. Daha sonra İETT Spor Kulübü'nün amatör futbolcusu oldu. 1976 yılında, İETT şampiyon olduğunda, Erdoğan da bu takımda oynamaktaydı. Erokspor Kulübünde de futbola devam etti ve 16 yıllık futbol yaşamını 12 Eylül 1980 Askeri Darbesi sonrasında bıraktı ve daha fazla siyasi faaliyet...},
    q{Öpüşmeği çağrıştıran çatırtılar.},
    q{Hadi bir masal uyduralım, içinde mutlu, doygun, telaşsız durduğumuz.},
    q{Yukarıda belirtilmiş olan faturalandırma tarihinden itibaren ödeme süresi 20 gündür. Ödeme yapılırken gönderen açıklaması olarak, tarafınıza verilen telefon numarası ve ilgili fatura numarasının mutlaka belirtilmesi gerekmektedir.},
);

for my $i ( 0..$#ascii ) {
    my $ascii_verbatim     = $ascii[$i];
    my $turkish_verbatim   = $turkish[$i];
    my $turkish_converted  = ascii_to_turkish( $ascii_verbatim  );
    my $ascii_converted    = turkish_to_ascii( $turkish_verbatim   );

    is(     $turkish_converted, $turkish_verbatim, 'EQ(turkish) ' . ($i + 1) );
    _chars( $turkish_converted, $turkish_verbatim, 'EQ(turkish) ' . ($i + 1) );

    is(     $ascii_converted,   $ascii_verbatim  , 'EQ(ascii)   ' . ($i + 1) );
    _chars( $ascii_converted,   $ascii_verbatim  , 'EQ(ascii)   ' . ($i + 1) );
}

TEST_WARN: {
    my @warnings;
    local $SIG{__WARN__} = sub {
        my $msg = shift || return;
        chomp $msg;
        diag "WARNING: $msg\n";
        push @warnings, $msg;
        return;
    };
    is( ascii_to_turkish( undef ), undef, 'undef is undef' );
    is( ascii_to_turkish( q{}   ), q{},   'Empty string is empty string' );
    is( ascii_to_turkish( 0     ), 0,     'Zero is zero' );
    ok( ! @warnings, 'No warnings' );
}

for my $i ( 1..CONTEXT_SIZE ) {
    my $test1 = q(a) x $i;
    my $test2 = qq(\n) x $i;
    my $test3 = qq(a\n) x $i;
    is( $test1, $test1, "SIZE EQ($i) $test1" );
    is( $test2, $test2, "SIZE EQ($i) \\n" );
    is( $test3, $test3, "SIZE EQ(${i}a) \\n" );
}

sub _chars {
    my($got, $expected, $id) = @_;
    my @got      = split m{}xms, $got;
    my @expected = split m{}xms, $expected;
    if ( @got == @expected ) {
        my @buf;
        while ( @got ) {
            my $char_got = shift @got;
            my $char_exp = shift @expected;
            next if $char_got eq $char_exp;
            push @buf, [ $char_got, $char_exp ];
        }
        if ( @buf ) {
            require Data::Dumper;
            diag sprintf '[%s] Mismatching chars: %s', $id, Data::Dumper::Dumper( \@buf );
        }
    }
    else {
        diag sprintf '[%s] Char count mismatch %d != %d',
                        $id,
                        scalar @got,
                        scalar @expected;
    }
    return $got, $expected;
}

1;

__END__
