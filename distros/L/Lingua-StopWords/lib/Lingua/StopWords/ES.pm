package Lingua::StopWords::ES;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( getStopWords ) ] ); 
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = 0.08;

sub getStopWords {
    if ( @_ and $_[0] eq 'UTF-8' ) {
        # adding U0 causes the result to be flagged as UTF-8
        my %stoplist = map { ( pack("U0a*", $_), 1 ) } qw( 
            de la que el en y a los del se las por un para con no una su al
            lo como mÃ¡s pero sus le ya o este sÃ­ porque esta entre cuando
            muy sin sobre tambiÃ©n me hasta hay donde quien desde todo nos
            durante todos uno les ni contra otros ese eso ante ellos e esto
            mÃ­ antes algunos quÃ© unos yo otro otras otra Ã©l tanto esa
            estos mucho quienes nada muchos cual poco ella estar estas
            algunas algo nosotros mi mis tÃº te ti tu tus ellas nosotras
            vosotros vosotras os mÃ­o mÃ­a mÃ­os mÃ­as tuyo tuya tuyos
            tuyas suyo suya suyos suyas nuestro nuestra nuestros nuestras
            vuestro vuestra vuestros vuestras esos esas estoy estÃ¡s estÃ¡
            estamos estÃ¡is estÃ¡n estÃ© estÃ©s estemos estÃ©is estÃ©n
            estarÃ© estarÃ¡s estarÃ¡ estaremos estarÃ©is estarÃ¡n estarÃ­a
            estarÃ­as estarÃ­amos estarÃ­ais estarÃ­an estaba estabas
            estÃ¡bamos estabais estaban estuve estuviste estuvo estuvimos
            estuvisteis estuvieron estuviera estuvieras estuviÃ©ramos
            estuvierais estuvieran estuviese estuvieses estuviÃ©semos
            estuvieseis estuviesen estando estado estada estados estadas
            estad he has ha hemos habÃ©is han haya hayas hayamos hayÃ¡is
            hayan habrÃ© habrÃ¡s habrÃ¡ habremos habrÃ©is habrÃ¡n habrÃ­a
            habrÃ­as habrÃ­amos habrÃ­ais habrÃ­an habÃ­a habÃ­as habÃ­amos
            habÃ­ais habÃ­an hube hubiste hubo hubimos hubisteis hubieron
            hubiera hubieras hubiÃ©ramos hubierais hubieran hubiese
            hubieses hubiÃ©semos hubieseis hubiesen habiendo habido habida
            habidos habidas soy eres es somos sois son sea seas seamos
            seÃ¡is sean serÃ© serÃ¡s serÃ¡ seremos serÃ©is serÃ¡n serÃ­a
            serÃ­as serÃ­amos serÃ­ais serÃ­an era eras Ã©ramos erais eran
            fui fuiste fue fuimos fuisteis fueron fuera fueras fuÃ©ramos
            fuerais fueran fuese fueses fuÃ©semos fueseis fuesen siendo
            sido tengo tienes tiene tenemos tenÃ©is tienen tenga tengas
            tengamos tengÃ¡is tengan tendrÃ© tendrÃ¡s tendrÃ¡ tendremos
            tendrÃ©is tendrÃ¡n tendrÃ­a tendrÃ­as tendrÃ­amos tendrÃ­ais
            tendrÃ­an tenÃ­a tenÃ­as tenÃ­amos tenÃ­ais tenÃ­an tuve
            tuviste tuvo tuvimos tuvisteis tuvieron tuviera tuvieras
            tuviÃ©ramos tuvierais tuvieran tuviese tuvieses tuviÃ©semos
            tuvieseis tuviesen teniendo tenido tenida tenidos tenidas tened 
        );
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( $_, 1 ) } qw( 
            de la que el en y a los del se las por un para con no una su al
            lo como más pero sus le ya o este sí porque esta entre cuando
            muy sin sobre también me hasta hay donde quien desde todo nos
            durante todos uno les ni contra otros ese eso ante ellos e esto
            mí antes algunos qué unos yo otro otras otra él tanto esa estos
            mucho quienes nada muchos cual poco ella estar estas algunas
            algo nosotros mi mis tú te ti tu tus ellas nosotras vosotros
            vosotras os mío mía míos mías tuyo tuya tuyos tuyas suyo suya
            suyos suyas nuestro nuestra nuestros nuestras vuestro vuestra
            vuestros vuestras esos esas estoy estás está estamos estáis
            están esté estés estemos estéis estén estaré estarás estará
            estaremos estaréis estarán estaría estarías estaríamos
            estaríais estarían estaba estabas estábamos estabais estaban
            estuve estuviste estuvo estuvimos estuvisteis estuvieron
            estuviera estuvieras estuviéramos estuvierais estuvieran
            estuviese estuvieses estuviésemos estuvieseis estuviesen
            estando estado estada estados estadas estad he has ha hemos
            habéis han haya hayas hayamos hayáis hayan habré habrás habrá
            habremos habréis habrán habría habrías habríamos habríais
            habrían había habías habíamos habíais habían hube hubiste hubo
            hubimos hubisteis hubieron hubiera hubieras hubiéramos
            hubierais hubieran hubiese hubieses hubiésemos hubieseis
            hubiesen habiendo habido habida habidos habidas soy eres es
            somos sois son sea seas seamos seáis sean seré serás será
            seremos seréis serán sería serías seríamos seríais serían era
            eras éramos erais eran fui fuiste fue fuimos fuisteis fueron
            fuera fueras fuéramos fuerais fueran fuese fueses fuésemos
            fueseis fuesen siendo sido tengo tienes tiene tenemos tenéis
            tienen tenga tengas tengamos tengáis tengan tendré tendrás
            tendrá tendremos tendréis tendrán tendría tendrías tendríamos
            tendríais tendrían tenía tenías teníamos teníais tenían tuve
            tuviste tuvo tuvimos tuvisteis tuvieron tuviera tuvieras
            tuviéramos tuvierais tuvieran tuviese tuvieses tuviésemos
            tuvieseis tuviesen teniendo tenido tenida tenidos tenidas tened 
        );
        return \%stoplist;
    }
}

1;
