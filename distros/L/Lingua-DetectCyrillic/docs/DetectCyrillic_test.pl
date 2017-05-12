#!/usr/bin/perl -w
use lib "/home/christ/MyPerlLib";
use Lingua::DetectCyrillic qw ( &toLowerCyr &toUpperCyr &TranslateCyr %RusCharset );
use Benchmark;

# Анализируем переменные окружения. Ну очень не хочется использовать CGI.pm на 240 Кб!
for ( split("&",$ENV{QUERY_STRING} ) ) {
  my ($key,$value) = split("=",$_);  $QStringData{$key} = $value; }

$Text_area = $QStringData{Text_area};
$Text_area =~ s/%([A-Fa-f\d]{2})/chr hex $1/eg; # unescape the string
$Text_area =~ s/\+/ /g; # remove plus signs

$MaxTokens = $QStringData{MaxTokens};
$DetectAllLang = $QStringData{DetectAllLang};

$CyrDetector = Lingua::DetectCyrillic ->new( MaxTokens => $MaxTokens, DetectAllLang => $DetectAllLang );
$timestart=new Benchmark;
( $Coding,$Language,$CharsProcessed, $Algorithm )= $CyrDetector -> Detect($Text_area);
#$CyrDetector -> LogWrite("test_log.log");
$timedf=timestr(timediff(new Benchmark,$timestart));

$Charset = $Coding;

#Формируем абсолютный маршрут к тому каталогу, из которого пришел запрос
$ENV{HTTP_REFERER} =~ m|(.*$ENV{HTTP_HOST})(.*/)(.*)$| ;
$Inc .=$ENV{DOCUMENT_ROOT} .$2. "DetectCyrillic_test.inc";

if ( $Language eq "NoLang" ) {
  $DocTitle = "Detection of Language and Coding";
  # Пробуем сменить язык на en
  ($IncAlt=$Inc) =~ s#(/ru/|/uk/)#/en/#;

  if ( -e $IncAlt ) {
  # Если английский отчет есть, показываем его, иначе - устанавливаем
  # принудительно windows-1251
   $Inc = $IncAlt;
   print  "Content-Type: text/html; charset=iso-8859-1\n\n";
    } else {
   print  "Content-Type: text/html; charset=windows-1251\n\n";
  }


} else {
  $DocTitle = TranslateCyr(win,$Charset,"Определение кодировки и языка");
  $Text_area_win = TranslateCyr($Charset,"windows-1251",$Text_area);
  $Text_area_koi8r = TranslateCyr($Charset,"koi8-r",$Text_area);
  $Text_area_koi8u = TranslateCyr($Charset,"koi8-u",$Text_area);
  $Text_area_utf = TranslateCyr($Charset,"utf-8",$Text_area);
  $Text_area_cp866 = TranslateCyr($Charset,"cp866",$Text_area);
  $Text_area_iso = TranslateCyr($Charset,"iso-8859-5",$Text_area);
  $Text_area_mac = TranslateCyr($Charset,"x-mac-cyrillic",$Text_area);
  print  "Content-Type: text/html; charset=$Charset\n\n";

}

require $Inc;

