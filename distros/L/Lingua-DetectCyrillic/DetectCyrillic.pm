package Lingua::DetectCyrillic;
# Нужно для перекодировки. Будет заменено в следующих выпусках
use Unicode::Map8;
use Unicode::String;

use Exporter ();
@ISA = qw ( Exporter );
@EXPORT_OK = qw ( &toLowerCyr &toUpperCyr &TranslateCyr %RusCharset );


# Увеличение словаря с 300 до 3000 слов практически ничего не дало:
# при распознавании koi8/windows разница была порядка 30.
# Активизируем словари и хэши
  use Lingua::DetectCyrillic::DictRus;
  use Lingua::DetectCyrillic::DictUkr;

# Хеширование по 3 пришлось снять - оно дает в среднем в 5 раз
# лучший результат, но хэш нужен в те же 5-7 раз больше.
  use Lingua::DetectCyrillic::WordHash2Rus;
  use Lingua::DetectCyrillic::WordHash2Ukr;

$VERSION = "0.02";

# Глобальные переменные
$FullStat=0;

######## Экспортируемые переменные
$RusCharset{'Upper'} = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯҐЄІЇЎ";
$RusCharset{'Lower'} = "абвгдеёжзийклмнопрстуфхцчшщъыьэюяґєіїў";
$RusCharset{'All'}="АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюяҐґЄєІіЇїЎў«»“”–—№";
$RusCharset{'Ukrainian'}= "ҐґЄєІіЇї";
$RusCharset{'Punctuation'}="«»“”–—№";
### Конец экспортируемых переменных

### Экспортируемые функции

sub TranslateCyr {
my ($CodingIn, $CodingOut, $String) = @_;
my ($MapIn, $MapOut);

$CodingIn=lc ($CodingIn);
$CodingOut=lc ($CodingOut);
# Если входная и выходная кодировки совпадают, вернуть неизмененную строку
if ( $CodingIn eq $CodingOut ) { return $String; }

if ($CodingIn =~ /(1251|win)/) { $MapIn = Unicode::Map8 -> new("cp1251"); $CodingIn="cp1251"; } elsif
($CodingIn =~ /(koi8u|koi8-u)/) { $MapIn = Unicode::Map8 -> new("koi8-u"); $CodingIn="koi8-u"; } elsif
($CodingIn =~ /koi/) { $MapIn = Unicode::Map8 -> new("koi8-r"); $CodingIn="koi8-r"; } elsif
($CodingIn =~ /(dos|866|alt)/) { $MapIn = Unicode::Map8 -> new("cp866"); $CodingIn="cp866"; } elsif
($CodingIn =~ /(iso|8859-5)/) { $MapIn = Unicode::Map8 -> new("ISO_8859-5"); $CodingIn="ISO_8859-5"; } elsif
($CodingIn =~ /(mac|10007)/) { $MapIn = Unicode::Map8 -> new("cp10007"); $CodingIn="cp10007"; } elsif
($CodingIn =~ /(utf|uni)/) { $CodingIn="utf-8"; } else
{ return ""; } # Если не определили входную кодировку - выйти

if ($CodingOut =~ /(1251|win)/) { $MapOut = Unicode::Map8 -> new("cp1251"); $CodingOut="cp1251"; } elsif
($CodingOut =~ /(koi8u|koi8-u)/) { $MapOut = Unicode::Map8 -> new("koi8-u"); $CodingOut="koi8-u"; } elsif
($CodingOut =~ /koi/) { $MapOut = Unicode::Map8 -> new("koi8-r"); $CodingOut="koi8-r"; } elsif
($CodingOut =~ /(dos|866|alt)/) { $MapOut = Unicode::Map8 -> new("cp866"); $CodingOut="cp866";} elsif
($CodingOut =~ /(iso|8859-5)/) { $MapOut = Unicode::Map8 -> new("ISO_8859-5"); $CodingOut="ISO_8859-5";} elsif
($CodingOut =~ /(mac|10007)/) { $MapOut = Unicode::Map8 -> new("cp10007"); $CodingOut="cp10007"; } elsif
($CodingOut =~ /(utf|uni)/) { $CodingOut="utf-8"; } else
{ return ""; } # Если не определили выходную кодировку - выйти

# Из UTF-8 в 8-битовую кодировку
if ( $CodingIn eq "utf-8" ) {
$s=Unicode::String::utf8($String)->ucs2;
if ( $CodingOut eq "utf-8" ) { return $String; } else { return $MapOut->to8($s); }
}
# Из 8-битовой кодировки в UTF-8
if ( $CodingOut eq "utf-8" ) { return $MapIn->tou($String)->utf8; }
# Если это не utf-8, то перекодируем из 8-битовго набора в 8-битовый же
  return $MapIn->recode8($MapOut,$String);
}

sub toLowerCyr {
	my ($s, $SourceCoding ) = @_;
  if ( $SourceCoding ) { $s = TranslateCyr ( $SourceCoding, "win", $s ) }
	eval ("\$s =~ tr/A-Z$RusCharset{'Upper'}/a-z$RusCharset{'Lower'}/");
  if ( $SourceCoding ) { $s = TranslateCyr ( "win", $SourceCoding, $s ) }
  $s;
}
sub toUpperCyr {
	my ($s, $SourceCoding ) = @_;
  if ( $SourceCoding ) { $s = TranslateCyr ( $SourceCoding, "win", $s ) }
	eval ("\$s =~ tr/a-z$RusCharset{'Lower'}/A-Z$RusCharset{'Upper'}/");
  if ( $SourceCoding ) { $s = TranslateCyr ( "win", $SourceCoding, $s ) }
  $s;
}

######## Конец экспортируемых переменных и функций

sub new
{
# Заполнили данные по умолчанию
%Args = ( MaxTokens => 100,	DetectAllLang => 0 );
my $self = {};
shift;
# Зачитали аргументы - это глобальный хэш
  %Args = @_;

@Codings = ( "win1251", "koi8r", "cp866", "utf", "iso", "mac" );
if ( $Args{DetectAllLang} ) {push @Codings, koi8u};
@InputData="";

return bless ($self);
}


sub LogWrite {
shift;
my $Outfile=shift;

########### Формат отчета ##########
format STAT =
@<<<<<<@######@######@######@######@######@##########@##########@######@######
$key,%Stat->{$key}{GoodTokensChars},%Stat->{$key}{GoodTokensCount},%Stat->{$key}{AllTokensChars},%Stat->{$key}{AllTokensCount},%Stat->{$key}{CharsUkr},%Stat->{$key}{HashScore2Rus},%Stat->{$key}{HashScore2Ukr},%Stat->{$key}{WordsRus},%Stat->{$key}{WordsUkr}
.

# Выводим отчет. Если названия файла нет, или это stdout - выводим на экран, иначе в файл
if (!$Outfile or uc ($Outfile) eq "STDOUT") {
    $OUT=\*STDOUT;
            } else {
    open $OUT, ">$Outfile";
}

   select $OUT;   $~="STAT";
  print "Coding: $Coding    Language: $Language     Algorithm: $Algorithm \n\n";
  print  "         GdChr  GdCnt AllChr AllCnt ChrUkr    HashRus   HashUkr  WRus  WUkr\n";
  print  "*" x 78 ."\n";
   foreach $key (keys %Stat) { write ; }
  print "*" x 78 ."\n";
  print "Time: " .localtime() ."\n";
  print <<POD;
 GoodTokensChars - number of characters in pure Cyrillic tokens with correct
capitalization.
 GoodTokensCount - number of pure Cyrillic tokens with correct capitalization.
 AllTokensChars - number of characters in tokens containing Cyrillica.
 AllTokensCount - their number
 CharsUkr - number of Ukrainian letters
 HashScore2Rus (Ukr) - hits on 2-letter hash
 WordsRus (Ukr) - hits on frequency dictionary
POD

   select STDOUT;
   if ( $OUT ne \*STDOUT ) { close $OUT; }

} # LogWrite()


sub Detect {
shift;
# Перегружаем в глобальный массив @InputData, он может понадобиться еще раз
# при получении расширенной статистики.

@InputData = @_;
######## Отладочно сливаем ввод в файл
#$Outfile = "C:\\test_out3.txt";
#open OUT, ">$Outfile";
#for (@_) { print OUT; }
#close OUT;
########


_GetStat();

# Теперь выясняем кодировку
$Language = ""; $Coding="";
$Algorithm=0; # Это примененная схема определения кодировки
$MaxCharsProcessed =0;
_AnalyzeStat();
if ( $Coding eq "win1251" ) { $Coding = "windows-1251" }
elsif ( $Coding eq "koi8r" ) { $Coding = "koi8-r" }
elsif ( $Coding eq "koi8u" ) { $Coding = "koi8-u" }
elsif ( $Coding eq "iso" ) { $Coding = "iso-8859-5" }
elsif ( $Coding eq "cp866" ) { $Coding = "cp866" }
elsif ( $Coding eq "utf" ) { $Coding = "utf-8" }
elsif ( $Coding eq "mac" ) { $Coding = "x-mac-cyrillic" }
else  { $Coding = "iso-8859-1" }

return ( $Coding, $Language, $MaxCharsProcessed, $Algorithm );

}

sub _GetStat {
# Инициализируем структуру хэшей (описание см. в конце)

for (@Codings) {
if ( $FullStat ) {
  $Stat{$_}{AllTokensChars} = 0;
  $Stat{$_}{AllTokensCount} = 0;
  $Stat{$_}{CharsUkr} = 0;
  $Stat{$_}{HashScore2Rus} = 0;
  $Stat{$_}{HashScore2Ukr} = 0;
  $Stat{$_}{WordsRus} = 0;
  $Stat{$_}{WordsUkr} = 0;

    } else { # $FullStat

  $Stat{$_}{GoodTokensChars} = 0;
  $Stat{$_}{GoodTokensCount} = 0;
  $Stat{$_}{CharsUkr} = 0;

} # $FullStat
} # end for


# Получаем статистику для каждой строки
$EnoughTokens=0;
for ( @InputData ) {
my $String=$_;

for (@Codings) {
    _ParseString ($_,$String,%Stat->{$_});
  # Выходим, если хоть по одной из кодировок набрали максимальное число токенов
  if (%Stat->{$_}{GoodTokensCount} > $Args{MaxTokens} ) { $EnoughTokens=1; }
}

if ( $EnoughTokens ) { last; }
} # Конец получения статистики


}

sub _AnalyzeStat {

# Сначала анализируем соотношение букв в чисто кириллических токенах
# с правильной капитализацией


## Анализируем формальную статистику по токенам с кириллицей
# Минимальное соотношение токенов с правильной капитализацией, при котором
# разницу считаем значимой для вычисления результата. Пока не используется.
# my $TokensRatio=0.95;
# Минимальный процент токенов с украинскими символами, чтобы текст считался украинским
my $UkrTokensShare=0.01;

## Анализируем чисто кириллические токены с правильной капитализацией.
my @CyrCharRating;
for ( @Codings ) { push @CyrCharRating,[$_, %Stat->{$_}{GoodTokensChars}]; }
@CyrCharRating = sort { $b->[1] <=> $a->[1] } @CyrCharRating;

$MaxCharsProcessed = $CyrCharRating[0]->[1];

# После сортировки получаем список наиболее вероятных кодировок
# Они содержат максимальное число "правильных" кириллических слов в данной кодировке
# Выясняем, между сколькими кодировками нужно провести различие
my @BestCodings;
for $arrayref ( @CyrCharRating ) {
       if  ( $arrayref ->[1] == $CyrCharRating[0]->[1] ) {
        push @BestCodings, $arrayref ->[0] ;
       }
}

# Если первая возможная кодировка содержит больше правильных символов,
# чем любая иная, считаем, что дело сделано. Вообще здесь лучше ввести
# определение минимально необходимого преимущества, скажем, 10% или что-то вроде.

if ( scalar(@BestCodings) == 1 ) {
  $Coding = $CyrCharRating[0]->[0];

# Определяем язык. Смотрим, нет ли украинских токенов. Если они присутствуют
# в количестве не менее $UkrTokensShare, считаем язык украинским, иначе - русским.
if ( %Stat->{$Coding}{CharsUkr} / %Stat->{$Coding}{GoodTokensCount} > $UkrTokensShare )
{ $Language = "Ukr"; } else { $Language = "Rus"; }
$Algorithm = 11;
return;
} # Конец разбора одной кодировки

# Следующий вариант: одинаковое число баллов набрали ровно две кодировки.
# Не исключено, что это либо koi русский и украинский, либо win1251 и мас.
# Тогда мы их можем различить по формальным параметрам.
if ( scalar(@BestCodings) == 2 ) {

$BestCoding1 = $CyrCharRating[0]->[0];
$BestCoding2 = $CyrCharRating[1]->[0];
# Первый вариант - это кодировки koi8u и koi8r.
if ( $BestCoding1 =~ /koi/ && $BestCoding2 =~ /koi/ ) {
# Определяем язык и на этом основании - кодировку
if (%Stat->{$Coding}{GoodTokensCount} > 0 &&  %Stat->{$Coding}{CharsUkr} / %Stat->{$Coding}{GoodTokensCount} > $UkrTokensShare )
{ $Coding = "koi8u"; $Language = "Ukr"; } else { $Coding = "koi8r"; $Language = "Rus"; }
$Algorithm = 21;
return;
} # Конец 1-го варианта

# Второй вариант - это кодировки win1251 и mac. То есть весь текст записан
# строчными буквами без Ю и Э. Предпочитаем однозначно win1251
if ( $BestCoding1 =~ /(win1251|mac)/ && $BestCoding2 =~ /(win1251|mac)/ ) {
$Coding="win1251";
if (%Stat->{$Coding}{GoodTokensCount} > 0 && %Stat->{$Coding}{CharsUkr} / %Stat->{$Coding}{GoodTokensCount} > $UkrTokensShare )
{ $Language = "Ukr"; } else { $Language = "Rus"; }
$Algorithm = 22;
return;
} # Конец 2-го варианта

} # Конец разбора двух кодировок при котором когда мы еще можем обойтись только анализом
# "правильных" символов,  без привлечения расширенной статистики

# Итак, кодировку с ходу не удалось определить по статистике символов с правильной
# капитализацией. Тогда устанавливаем флаг $FullStat и еще раз получаем статистику по
# строкам - на этот раз с хэшем и словарем
$FullStat = 1;
_GetStat();

# Проверяем, а есть ли кириллица в тексте вообще.
for ( @BestCodings ) { push @CyrCharRating,[$_, %Stat->{$_}{AllTokensChars}]; }
@CyrCharRating = sort { $b->[1] <=> $a->[1] } @CyrCharRating;

$MaxCharsProcessed = $CyrCharRating[0]->[1];

# Выйти, если не было ни одного кириллического символа
if ( $MaxCharsProcessed == 0 ) { $Coding = "iso-8859-1"; $Language = "NoLang"; $Algorithm = 100; return; }


# Делаем следующие два шага. Сначала создаем массив из комбинаций языка и кодировки
# для подсчета слов из словаря, затем оставляем только комбинации с максимальным значением,
# т.е. сужаем список потенциальных комбинаций. Если этих комбинаций больше одной,
# переходим ко второму шагу - создаем аналогичный массив для хэшей и снова отбираем
# комбинации с максимальным значением. Если снова не удалось выделить единственного
# "победителя", предпочитаем русский язык украинскому, кодировку windows - макинтошу.

# Шаг 1. Ищем максимальный рейтинг слов из частотного словаря
my @WordsRating;
for ( @BestCodings ) {
  push @WordsRating, [$_,"Rus", %Stat->{$_}{WordsRus}];
  push @WordsRating, [$_,"Ukr", %Stat->{$_}{WordsUkr}];
}
@WordsRating = sort { $b->[2] <=> $a->[2] } @WordsRating;

#print "WordsRating: \n";
#for $arrayref (@WordsRating) {
#  print "  " . $arrayref ->[0] . " " .$arrayref ->[1] ." ".$arrayref ->[2] ."\n"; }


# Если обнаружили в тексте хотя бы одно слово из словаря, и нет альтернатив,
# то считаем, что определение языка/кодировки произошло
if ( $WordsRating[0]->[2] > 0 && $WordsRating[0]->[2] > $WordsRating[1]->[2] ) {
 $Coding = $WordsRating[0]->[0];
 $Language = $WordsRating[0]->[1];
 $Algorithm = 31;
 return;
}

# Либо слова из частотного словаря вообще не были обнаружены,
# либо имеем совпадение числа слов для нескольких комбинаций язык/кодировка
#  Шаг 2. Обращаемся к хэшу и еще больше сужаем ареал поиска.

my @BestWordsRating;
for $arrayref ( @WordsRating ) {
       if  ( $arrayref ->[2] == $WordsRating[0]->[2] ) {
        push @BestWordsRating, [ $arrayref ->[0],$arrayref ->[1],$arrayref ->[2] ] ;
       }
}
#print "BestWordsRating: \n";
#for $arrayref (@BestWordsRating) {
#  print "  " . $arrayref ->[0] . " " .$arrayref ->[1] ." ".$arrayref ->[2] ."\n"; }


my @HashRating;
for $arrayref ( @BestWordsRating ) {

if ( $arrayref->[1] eq "Rus" ) {
  push @HashRating, [$arrayref->[0],"Rus", %Stat->{$arrayref->[0]}{HashScore2Rus}]; }
if ( $arrayref->[1] eq "Ukr" ) {
  push @HashRating, [$arrayref->[0],"Ukr", %Stat->{$arrayref->[0]}{HashScore2Ukr}]; }

}
@HashRating = sort { $b->[2] <=> $a->[2] } @HashRating;

#for $arrayref (@HashRating) {
#  print "  " .$arrayref ->[0] . " " .$arrayref ->[1] ." ".$arrayref ->[2] ."\n"; }

# Если обнаружили в тексте хотя бы один реальный хэш, и нет альтернатив,
# то считаем, что определение языка/кодировки произошло
if ( $HashRating[0]->[2] > 0 && $HashRating[0]->[2] > $HashRating[1]->[2] ) {
 $Coding = $HashRating[0]->[0];
 $Language = $HashRating[0]->[1];
 $Algorithm = 32;
 return;
}


# Либо хэш не обнаружен, либо имеем совпадение числа слов для нескольких комбинаций
# язык/кодировка
# Шаг 3. Оставляем только те комбинации язык/кодировка, которые содержат наибольшее число
# попаданий в хэш.

my @BestHashRating;
for $arrayref ( @HashRating ) {
       if  ( $arrayref ->[2] == $HashRating[0]->[2] ) {
        push @BestHashRating, [ $arrayref ->[0],$arrayref ->[1] ] ;
       }
}
# for $arrayref (@BestHashRating) {
#  print "  " .$arrayref ->[0] . " " .$arrayref ->[1] ." ".$arrayref ->[2] ."\n"; }


# Теперь наступили тяжелые времена. ;-)) Остались только те комбинации кодировка/язык,
# для которых полностью совпадают данные и по частотному словарю, и по хэшу.
# Это может случиться ровно в двух случаях. Первый - весь текст набран строчными буквами.
# Тогда смешиваются Mac/Win. Предпочитаем Win.
# Второй - текст в koi набран без украинских букв. Тогда смешиваются koi8-r и koi8-u.
# Предпочитаем koi8-r (впрочем, разницы в данном случае никакой).


for $arrayref (@BestHashRating) {
  if ( $arrayref ->[0] =~ /win/ ) {
   $Coding = "win1251";
    if (%Stat->{$Coding}{GoodTokensCount} > 0 && %Stat->{$Coding}{CharsUkr} / %Stat->{$Coding}{GoodTokensCount} > $UkrTokensShare )
    { $Language = "Ukr"; } else { $Language = "Rus"; }
      $Algorithm = 33;
      return;
  }
}

for $arrayref (@BestHashRating) {
  if ( $arrayref ->[0] =~ /koi/ ) {
   $Coding = "koi8-r";
   $Language = "Rus";
   $Algorithm = 34;
      return;
  }
}

# Ничего не подошло. Устанавливаем первую победившую кодировку и язык.
   $Coding = $BestHashRating[0]->[0];
   $Language = $BestHashRating[0]->[1];;
   $Algorithm = 40;


return;
} #end _AnalyzeStat()




sub _ParseString {
my ($Coding, $String, $Hash) = @_;
# Перевели строку в кодировку win1251 и убрали знаки новой строки
$String = TranslateCyr($Coding,"win1251",$String);
$String =~ s/[\n\r]//go;

 ## Разбитие на слова
 ## \xAB\xBB - полиграфические кавычки, \x93\x94 - кавычки-"лапки",
 ## \xB9 - знак номера, \x96\x97 - полиграфические тире
for (split (/[\xAB\xBB\x93\x94\xB9\x96\x97\.\,\-\s\:\;\?\!\"\(\)\d<>]+/o, $String)) {
    s/^\'+(.*)\'+$/$1/; # Убрали начальные и конечные апострофы

if ( !$FullStat ) {

# Определяем, "правильный" ли это токен, т.е. содержит только кириллицу
# и либо строчные буквы, либо ПРОПИСНЫЕ, либо начинается с Прописной.
if  (/^[$RusCharset{'Lower'}]+$/ || /^[$RusCharset{'Upper'}]{1}[$RusCharset{'Lower'}]+$/ || /^[$RusCharset{'Upper'}]+$/ ) {
  $$Hash{GoodTokensChars}+=length();
  # Для UTF умножаем число кириллических символов на два.
  if ( $Coding eq "utf" ) { $$Hash{GoodTokensChars}+=length(); }
  $$Hash{GoodTokensCount}++;
  # Если токен содержит украинские символы, увеличить счетчик украинских токенов
  if ( $Args{DetectAllLang} && /[$RusCharset{'Ukrainian'}]/ ) { $$Hash{CharsUkr}++;}

}

  } else { # !$FullStat

# Определяем, можно ли вообще проводить над этим токеном какие-либо действия.
# Для этого он должен содержать хотя бы одну правильную кириллическую букву,
# английские буквы и цифры в любой смеси.
if (/[$RusCharset{'All'}]/ && /^[\w\d$RusCharset{'All'}]+$/) {
  $$Hash{AllTokensChars}+=length();
  # Для UTF умножаем число символов на два.
  if ( $Coding eq "utf" ) { $$Hash{AllTokensChars}+=length(); }
  # Если токен содержит украинские символы, увеличить счетчик украинских токенов
  if ( $Args{DetectAllLang} && /[$RusCharset{'Ukrainian'}]/ ) { $$Hash{CharsUkr}++; }

  # Теперь приступаем к обработке хэша и словарей
# Переводим токен в нижний регистр - и словарь, и хэши у нас в нижнем регистре
  $_=toLowerCyr($_);

  if ($DictRus{$_}) { $$Hash{WordsRus}++;  }
  if ($Args{DetectAllLang} && $DictUkr{$_}) { $$Hash{WordsUkr}++;  }

for $i (0..length()-1) {
  if ( $WordHash2Rus{substr($_,$i,2)} ) { $$Hash{HashScore2Rus}++; }
  if ( $Args{DetectAllLang} && $WordHash2Ukr{substr($_,$i,2)} ) { $$Hash{HashScore2Ukr}++; }
} # end for

} # end  if (/^[\w\d$RusCharset{'All'}]+$/)

} # !$FullStat

	} # end	for (split...


} # end routine



1;

__END__
=pod

=head2 ANNOTATION

B<Lingua::DetectCyrillic>. The package detects 7 Cyrillic codings as
well as the language - Russian or Ukrainian. Uses embedded frequency dictionaries;
usually one word is enough for correct detection.

=head2 SYNOPSIS

  use Lingua::DetectCyrillic;
   -or (if you need translation functions) -
  use Lingua::DetectCyrillic qw ( &TranslateCyr &toLowerCyr &toUpperCyr );

  # New class Lingua::DetectCyrillic. By default, not more than 100 Cyrillic
  # tokens (words) will be analyzed; Ukrainian is not detected.
  $CyrDetector = Lingua::DetectCyrillic ->new();

  # The same but: analyze at least 200 tokens, detect both Russian and
  # Ukrainian.
  $CyrDetector = Lingua::DetectCyrillic ->new( MaxTokens => 200, DetectAllLang => 1 );

  # Detect coding and language
  my ($Coding,$Language,$CharsProcessed,$Algorithm)= $CyrDetector -> Detect( @Data );

  # Write report
  $CyrDetector -> LogWrite(); #write to STDOUT
  $CyrDetector -> LogWrite('report.log'); #write to file

  # Translating to Lower case assuming the source coding is windows-1251
  $s=toLowerCyr($String, 'win');
  # Translating to Upper case assuming the source coding is windows-1251
  $s=toUpperCyr($String, 'win');
  # Converting from one coding to another
  # Acceptable coding definitions are win, koi, koi8u, mac, iso, dos, utf
  $s=TranslateCyr('win', 'koi',$String);

See L<Additional information on usage of this package
|Usage details>.

=head2 DESCRIPTION

This package permits to detect automatically all live Cyrillic codings -
L<windows-1251|"item_windows%2D1251">, L<koi8-r|"item_koi8%2Dr">,
L<koi8-u|"item_koi8%2Du">, L<iso-8859-5|"item_iso%2D8859%2D5">,
L<utf-8|"item_utf%2D8">, L<cp866|"item_cp866">,
L<x-mac-cyrillic|"item_x%2Dmac%2Dcyrillic">, as well
as the language - B<Russian> or B<Ukrainian>. It applies 3 algorithms for
detection:
L<formal analysis of alphabet hits|"Stage 1. Formal analysis of alphabet
hits and capitalization">,
L<frequency analysis of words and frequency analysis of 2-letter combinations|
"Stage 2. Frequency analysis of words and 2-letter combinations.">.

It also provides routines for conversion between different codings of Cyrillic
texts which can be imported if necessary.

The package permits to detect coding with one or two words only. Certainly,
in case of one word reliability will be low, especially if you wrote the words
for testing completely in lower or uppercase, as capitalization is a very
important attribute for coding detection. Nethertheless the package correctly
recognizes coding in a message containing one single word, even all lowercase -
'privet' ('hello' in Russian), 'ivan', 'vodka', 'sputnik'. ;-)))

Ukrainian language will be specified only if the text contains specific
Ukrainian letters.

Performance is good as the analysis passes two stages: on the first
only formal and fast analysis of proper capitalization and alphabet hit
is carried out and only if these data are not enough, the input is analyzed
second time - on frequency dictionaries.

=head2 DEPENDENCIES

The package requires so far B<L<Unicode::String|"item_Unicode%3A%3AString">> and
B<L<Unicode::Map8|"item_Unicode%3A%3AMap8">>
which can be downloaded from http://www.cpan.org.
See L<Additional information on packages to be installed
|Which additional packages are required?>.

I plan to implement my own support of character decoding so these
packages will be not required in future releases.

=over 4

=item 1 B<Unicode::Map8>

Basic package for conversion between different one-byte codings. Available
at http://www.cpan.org .

=over

B<Warning!> This module requires preleminary compilation with a C++ compiler;
under Unix this procedure goes smoothly and doesn't need commenting;
but under Win32 with ActiveState Perl you must

=item 2 use MS Visual C++ and

=item 2 make some manual changes to the listing after having run Makefile.PL

Open B<map8x.c> and change the line 97 from

    ch = PerlIO_getc(f);

to

    ch = getc(f);

In one word, you need to replace Perl wrapper for C function I<getc> to the
function itself. The compiler produces warnings, but as a result you'll get
a 100% working DLL.

=back

=item 3 B<Unicode::String>

Provides support for B<Unicode::Map8>. Available at http://www.cpan.org .

=back

=head2 USAGE DETAILS

=over

=item * Create a class B<Lingua::DetectCyrillic>

  $CyrDetector = Lingua::DetectCyrillic ->new();
  $CyrDetector = Lingua::DetectCyrillic ->new( MaxTokens => 100, DetectAllLang => 1 );

I<MaxTokens> - the package I<stops analyzing> the input, if the given number
of Cyrillic tokens is reached. You have not to analyze all 100 or 200 thousand
bytes from the input if after first 100 tokens the coding and the language can
be easily determined. If not specified, this argument defaults to 100.

I<DetectAllLang> - by default the package assumes Russian language only. Setting
this parameter to any non-zero value will involve analysis on two languages -
Russian and Ukrainian. This slows down perfomance by nearly 10% and can in rare
cases may result in a worse coding detection.

=item * Pass an array of strings to the class method I<Detect>:

 my ($Coding,$Language,$CharsProcessed,$Algorithm)= $CyrDetector -> Detect( @Data );

=over

=item $Coding

- L<windows-1251|"item_windows%2D1251">, L<koi8-r|"item_koi8%2Dr">,
L<iso-8859-5|"item_iso%2D8859%2D5">, L<utf-8|"item_utf%2D8">, L<cp866|"item_cp866">,
L<x-mac-cyrillic|"item_x%2Dmac%2Dcyrillic">. If the
input doesn't have a single Cyrillic character, returns B<iso-8859-1>. If
I<DetectAllLang E<gt> 0>, may return L<koi8-u|"item_koi8%2Du"> as well.

=item $Language

- B<Rus> or (if I<DetectAllLang E<gt> 0>) B<Ukr> as well. If the
input doesn't have a single Cyrillic character, returns B<NoLang> (I can't state
for sure this language to be I<English>, I<German>, I<French> or any other ;-).

=item $CharsProcessed

- number of characters processed in the most possible coding.
Useful to estimate the level of reliability. If the program found 3-4 poor Cyrillic
characters in input no need to say how correct the results are...

=item $Algorithm

- numeric code showing on which stage the program decided to
stop further analysis (satisfied with the results). Useful for debugging. If
you will report me errors, please refer to this code. For more detailed
explanation see the table
L<Algorithm codes explanation|"Algorithm codes explanation">.

=back

=item * Write a report, if you want

  $CyrDetector -> LogWrite(); #write to STDOUT
  $CyrDetector -> LogWrite('report.log'); #write to file

If the only argument is not specified or equal to I<stdout> (in upper- or
lowercase), the program writes the report to the B<STDOUT>, otherwise to
the file.

=back

=head2 HOW IT WORKS

=head3 Stage 1. Formal analysis of alphabet hits and capitalization

Started programming, I came from an obvious fact: a 'human' reader can
easily determine the coding and language from one sight, or at least to say
I<the text to be displayed in a wrong coding>. The thing is that the I<alphabets>,
i.e. I<letters> of most Cyrillic codings do I<not> coincide so if we try to
display text in a bad coding we will I<inevitably> see on screen messy characters
inside words which can not be typed with Russian or Ukrainian keyboard layout
in a standard way - valuta signs, punctuation marks, Serbian letters, sometimes
binary characters etc etc.

Indeed we have only one hard case: the two most popular Cyrillic codings -
windows-1251 and koi8-r - have their alphabets in the same range from 192 to 255,
but I<uppercase> letters of windows-1251 are placed on the codes of I<lowercase>
letters of koi8-r and vice versa, so 'Ivan Petrov' in one of these codings
will look like 'iVAN pETROV' in another, i.e. have absolutely I<wrong
capitalization> which can be also easily determined by formal analysis of
characters. And as you may guess any more or less consistent Cyrillic text
must have at least one word starting with a capital letter (I don't take in
consideration some weird Internet inhabitants WRITING ALL WITH CAPITAL LETTERS ;-).

=begin html
Also on the first stage of analysis the program consequently assumes the given
text has been written in one of 6 or 7 Cyrillic codings and calculates:
<div style='position:relative;left:30'>
1. how many tokens have inside 'bad' characters which are not
part of the Russian or Ukrainian alphabet and cannot be typed with standard
keyboard layout; <br>
2. how many tokens have improper capitalization which differs
from normal <i>UPPERCASE</i>, <i>lowercase,</i> and <i>Proper</i> words capitalization.
</div>

=end html

=begin text
Also on the first stage of analysis the program consequently assumes the given
text has been written in one of 6 or 7 Cyrillic codings and calculates:
1. how many tokens have inside 'bad' characters which are not
part of the Russian or Ukrainian alphabet and cannot be typed with standard
keyboard layout;
2. how many tokens have improper capitalization which differs
from normal I<UPPERCASE>, I<lowercase> and I<Proper> words capitalization.

=end text

This formal analysis is very I<fast> and suits for 99.9% of I<real> texts.
Wrong codings are easily filtered out and we get only one 'absolute winner'.
This method is also reliable: I can hardly imagine a normal person writing in
reverse capitalization. But what if we have only a few words and all them are
in upper- or lowerscase?

=head3 Stage 2. Frequency analysis of words and 2-letter combinations.

In this case we apply frequency analysis of words and 2-letter combinations,
called also I<hashes> (not in I<Perl> sense, certainly ;-).

The package has dictionaries for 300 most frequent Russian and Ukrainian words
and for nearly 600 most frequent Russian and Ukrainian 2-letter combinations,
built by myown (the input texts were maybe not be very typical for Internet
authors but any linguist can assure you this is not very principal:
first hundreds of the most popular words in any language are very stable,
nothing to say about letter combinations).

Also the text is analyzed second time (this shouldn't take too much time as we may
get into situation like this only in case of a very short text); all the Cyrillic
letters analized, no matter in which capitalization they are. If we found at least
one word - the coding is determined on it, otherwise - on comparison of letter
hashes.

In some very rare cases (usually in a very artificial situation when we have
only one short word written all in lower- or uppercase) the statistics on several
codings are equal. In this case we prefer windows-1251 to mac, koi8-r to koi8-u
and - if nothing helps  - windows-1251 to koi8-r.

To judge about which algorithm was applied you may wish to analyze the 4th
variable, returned by the function I<Detect> - L<$Algorithm|"item_%24Algorithm">.
More detailed explanation of it is in the table
L<Algorithm codes explanation|"Algorithm codes explanation">.



=head2 REFERENCE INFORMATION

=head3 Modern Cyrillic codings and where are they used

=over 4

The supported codings are:

=item * windows-1251

This is the most popular Cyrillic coding nowadays, used on nearly 99% PC's.
Full alphabet starts with code 192 (uppercase A), like most Microsoft character
sets for national languages, and ends with code 255 (lowercase ya). Contains
also characters for Ukrainian, Byelorussian and other languages based on
Cyrillic alphabet. Can be easily sorted etc.

=item * koi8-r

Transliterated coding; terrible remnant of the old 7-bit world.
First another coding - koi7-r was designed, where Russian characters were on
places of B<similar> English ones, for example Russian A on place of English A,
Russian R (er) on place of English R etc. Even if there were no Cyrillic
fonts at all the text still stayed readable. I<Koi8-r> is in essence the same
archeologic I<Koi7-r> with characters shifted to the extended part of ASCII
table. I<Koi8-r> is still used on Unix-based computers, therefore it is the
second popular Russian coding on the Net.

=item * koi8-u

The same as koi8-r, but with Ukrainian characters added.

=item * utf-8

A good textual representation of Unicode text. Basic characters (codes < 128)
are represented with one-byte codes, while all other languages except
Oriental ones - with two-byte sequences. See RFC 2279 'UTF-8, a transformation
format of ISO 10646' for detailed information.

=item * iso-8859-5

Though this coding is approved by ISO, it is used only on some rare Unix systems,
for example on Russian Solaris. For my whole life on the Net I have met only one
or two guys working on computers like these.

=item * cp866

Also called 'alternative' coding. Used under DOS and Russian OS/2.

=item * x-mac-cyrillic

Macintosh coding. Lowercase letters almost completely coincide with Windows-1251
(except 2 characters) so in some rare cases I<x-mac-cyrillic> can be confused with
I<windows-1251>. On the Internet this coding has almost died out; its share
is absolutely insignificant. On PC platform it is supported by default only
under Windows NT+.

=back


=head3 Algorithm codes explanation

=begin html
<table width="80%">
     <th colspan=2> Algorithm codes explanation </th>
     <tr class=tr1><td width=5%>11</td><td width=40%>Formal analysis of quantity/capitalization of Cyrillic characters;
      only one alternative found</td></tr>
     <tr><td>21</td><td>Formal analysis of quantity/capitalization of Cyrillic characters;
      two alternatives found (koi8-r and koi8-u); koi8-r chosen</td></tr>
     <tr class=tr1><td>22</td><td>Formal analysis of quantity/capitalization of Cyrillic characters;
      two alternatives found (win1251 and mac); win1251 chosen</td></tr>
     <tr><td>31</td><td>At least one word from the dictionary found and there is only one
      alternative</td></tr>
     <tr class=tr1><td>32</td><td>At least one hash from the hash dictionary found and there is only one
      alternative</td></tr>
     <tr><td>33</td><td>Formally win1251 defined (most probably on analysis of hash)</td></tr>
     <tr class=tr1><td>34</td><td>Formally koi8-r defined (most probably on analysis of hash)</td></tr>
     <tr><td>40</td><td>Most probable results were chosen, but reliability is very low</td></tr>
     <tr class=tr1><td>100</td><td>No single Cyrillic character detected</td></tr>
</table>


=begin text

=over

  11 - Formal analysis of quantity/capitalization of
  Cyrillic characters; only one alternative found
  21 - Formal analysis of quantity/capitalization of Cyrillic
  characters; two alternatives found (koi8-r and koi8-u);
  koi8-r chosen
  22 - Formal analysis of quantity/capitalization of Cyrillic
  characters; two alternatives found (win1251 and mac);
  win1251 chosen
  31 - At least one word from the dictionary found and there
  is only one alternative
  32 - At least one hash from the hash dictionary found and there
  is only one alternative
  33 - Formally win1251 defined (most probably on analysis of hash)
  34 - Formally koi8-r defined (most probably on analysis of hash)
  40 - Most probably results were chosen, but reliability is very low

=back

=end text

=head2 HISTORY

December 01, 2002 - Extensive Russian documentation added. Version changed to 0.02.

November 19, 2002 - version 0.01 released.

=head2 TODO

1. Own Unicode support.

2. Option to detect only necessary codings from a list.

What else? Need your feedback!!

=head2 CONTACTS AND COPYRIGHT


The author: B<Alexei Rudenko>, Russia, Moscow. My home phone is I<(095) 468-95-63>

Web-site: http://www.bible.ru/DetectCyrillic/

CPAN address: http://search.cpan.org/author/RUDENKO/

Email: rudenko@bible.ru

Copyright (c) 2002 Alexei Rudenko. All rights reserved.

=cut

*************** Описание хэша хэшей
 Основной хэш хэшей Stat, в котором накапливается статистика, имеет следующую структуру.

  %Stat{<имя кодировки>}{
    GoodTokensChars => 0, GoodTokensCount => 0,
    AllTokensChars => 0, AllTokensCount => 0,
    CharsUkr => 0, HashScore2Rus => 0, HashScore2Ukr => 0,
    WordsRus => 0, WordsUkr => 0
   };

 GoodTokensChars - всего символов в "правильных" токенах (с правильной капитализацией и
  набором символов),
 GoodTokensCount - всего слов с правильным набором символов и капитализацией.
 AllTokensChars - процент токенов, содержащих кириллические символы, пусть в смеси с латиницей,
 цифрами, неправильной капитализацией
 AllTokensCount - их число
 CharsUkr - число украинских букв,
 HashScore2Rus (Ukr) - вес правильных двухбуквенных сочетаний из "нарезки",
 WordsRus (Ukr) - найденные в словаре русские (украинские) слова

**************

