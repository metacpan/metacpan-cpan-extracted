%Descriptions=(
    "iso-8859-1" => "Iso-8859-1 - Западноевропейская кодировка. Кириллица не обнаружена.",
    "windows-1251" => "Cp1251 - Кодировка MS Windows. Также: Windows Cyrillic (Slavic), Cyrillic. Синонимы: x-cp1251, windows-1251",
    "koi8-r" => "Koi8-r - Кодировка Unix.  Синонимы: csKOI8R, koi",
    "koi8-u" => "Koi8-u - Кодировка Unix (украинская).",
    "cp866" => "Cp866 - Кодировка DOS и OS/2. Также: MS-DOS Russian, MS-DOS Cyrillic CIS 1. Синонимы: cp866, ibm866",
    "iso-8859-5" => "Iso-8859-5 - кодировка кириллицы, одобренная ISO. Используется на некоторых системах Unix. Синонимы: iso-8859-5, csISOLatinCyrillic, cyrillic, iso-ir-144, ISO_8859-5, ISO_8859-5:1988",
    "utf-8" => "Utf-8 - Unicode с символами кириллицы. Синонимы: utf-8, unicode-1-1-utf-8, unicode-2-0-utf-8, x-unicode-2-0-utf-8",
    "x-mac-cyrillic" => "x-mac-cyrillic - Кириллица на Macintosh. Поддерживается под Windows NT+."
);
$Description = $Descriptions{$Charset};
print <<POD;
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=$Charset">
  <title>$DocTitle</title>
  <style>
  TABLE {background-color:#eeeeee; border-color:#cccccc; border-style:solid; cell-padding:2; border-width:2; font-size:90% }
  TH {text-align:left; padding-left:80pt}
  .tr1 {background-color:#dddddd; }
  BODY {font-family: Arial, Helvetica,sans-serif; font-size:70%}
</style>
</head><body>
<h4>Кодировка: $Charset,  язык: $Language </h4>
<table width="80%">
     <th colspan=2> Ваш текст в различных кодировках: </th>
     <tr class=tr1><td width=20% ><i>Исходный текст</i></td><td > $Text_area </td></tr>
     <tr><td>windows-1251</td><td> $Text_area_win </td></tr>
     <tr class=tr1><td>x-mac-cyrillic</td><td> $Text_area_mac</td></tr>
     <tr><td>koi8-r</td><td> $Text_area_koi8r </td></tr>
     <tr class=tr1><td>koi8-u</td><td> $Text_area_koi8u </td></tr>
     <tr><td>utf-8</td><td> $Text_area_utf </td></tr>
     <tr class=tr1><td>cp866</td><td> $Text_area_cp866 </td></tr>
     <tr><td>iso-8859-5</td><td> $Text_area_iso </td></tr>
</table>

 <b> MaxTokens: </b> $MaxTokens <br>
 <b> DetectAllLang: </b> $DetectAllLang <br>
 <b> Время, использованное для определения: </b> $timedf
<hr>

<table width="60%">
     <th colspan=2> Результаты анализа </th>
     <tr class=tr1><td width=40%>Проанализированных символов:</td><td >$CharsProcessed</td></tr>
     <tr><td>Кодировка:</td><td>$Coding</td></tr>
     <tr class=tr1><td>Описание:</td><td>$Description</td></tr>
     <tr><td>Язык:</td><td>$Language</td></tr>
     <tr class=tr1><td>Алгоритм:</td><td>$Algorithm</td></tr>
</table>

<hr>
<table width="80%">
     <th colspan=2> Объяснение кодов алгоритма </th>
     <tr class=tr1><td width=5%>11</td><td width=40%>Формальный
        анализ количества/капитализации кириллических символов; найдена только
        одна альтернатива</td></tr>
     <tr><td>21</td><td>Формальный анализ количества/капитализации
        кириллических символов; найдены две
        альтернативы (koi8-r и koi8-u); выбрана koi8-r</td></tr>
     <tr class=tr1><td>22</td><td>Формальный анализ
        количества/капитализации
        кириллических символов; найдены две
        альтернативы (win1251 и mac); выбрана win1251</td></tr>
     <tr><td>31</td><td>Найдено по меньшей мере одно
        слово из словаря и есть только одна
        альтернатива</td></tr>
     <tr class=tr1><td>32</td><td>Найдено по меньшей мере
        одно слово из хэша и есть только одна
        альтернатива</td></tr>
     <tr><td>33</td><td>Формально определена win1251 (скорее
        всего на базе анализа хэша)</td></tr>
     <tr class=tr1><td>34</td><td>Формально определена koi8-r
        (скорее всего на базе анализа хэша)</td></tr>
     <tr><td>40</td><td>Был выбран наиболее вероятный
        результат, но надежность очень
        невелика</td></tr>
     <tr class=tr1><td>100</td><td>Не найдено ни одного
        кириллического символа</td></tr>
</table>
</body></html>

POD


__END__
print "<h5>This is the report:</h5><pre>\n";
$CyrDetector -> LogWrite();
print "</pre>\n";

print "</body></html>";
