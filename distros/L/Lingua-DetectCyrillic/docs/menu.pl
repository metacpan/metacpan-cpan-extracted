#!/usr/bin/perl -w

require "Languages.inc"; # получили @AvailableLangs
print "content-type: text/plain\n\n";
( $ScriptPath )=( $ENV{SCRIPT_NAME} =~ m|(/.*/)(.*)$| );
if ( $ScriptPath eq "") { $ScriptPath = "/"; }
# Предполагается, что второй элемент маршрута - указание на язык, типа /en/, /ru/ и т.п.
( $DocLanguage, $DocPathAfterLang)= ( $ENV{DOCUMENT_URI} =~ m|$ScriptPath(.*)/(.*)| );

# Здесь - глобальное меню, не зависящее от каталога. Это языки и кодировка
my %DocVersions;
# Перебираем каталоги-языки
for ( @{$AvailableLangs} ) {
    #Смотрим, есть ли в этом каталоге файл с точно таким же названием
    $OtherVersion="$_/$DocPathAfterLang";
    if (-e $OtherVersion) {  $DocVersions{$_}=$ScriptPath.$OtherVersion;  }
}

#Это - локальное меню
( $DocPath )= ( $ENV{DOCUMENT_URI} =~ m|(.*/)$ENV{DOCUMENT_NAME}|i );
$MenuInc=$ENV{DOCUMENT_ROOT}.$DocPath."Menu.inc";
# Если локальное меню присутствует, печатаем его начало, иначе - сами
if ( -e $MenuInc ) {  require $MenuInc;  print $LocalMenuStart; }
if ( !$LocalMenuStart ) {  print "<td width=100><td>Language:</td>"; }

#Теперь формируем меню.
foreach $key (keys (%DocVersions)){
  if ( $DocVersions{$key} eq $ENV{DOCUMENT_URI} )
  { print  "<td class=SelectedLanguage>$key</td>" ;} else
  { print "<td><a href=$DocVersions{$key}>$key</a></td>";}
}

my %Codings;
my $DecodingScript="http://www.bible.ru/cgi-bin/code.pl";
my $DocUri="http://$ENV{HTTP_HOST}$ENV{DOCUMENT_URI}";
print <<EOD;
<td nowrap>
Coding:
<a href="$DecodingScript/vol/$DocUri">trans</a>
<a href="$DecodingScript/win/$DocUri">win</a>
<a href="$DecodingScript/koi/$DocUri">koi</a>
<a href="$DecodingScript/utf8/$DocUri">utf</a>
</td>

EOD

if ($LocalMenuEnd) { print $LocalMenuEnd; }
if (!$LocalMenuEnd) { print "</tr></table>"; }

# Блокировать формирование меню JavaScript
print "<script language=javascript>var MenuBuiltOnServer=1;</script>";

__END__
#
print join ("<br>\n", @INC);
print "<table border=1> " ;
for $key (sort  keys (%ENV) ) {
	print "<tr><td>$key </td><td> " .$ENV{$key} ."</td></tr>\n";
}
print "</table> " ;

