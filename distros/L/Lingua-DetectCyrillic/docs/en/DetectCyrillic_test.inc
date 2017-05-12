%Descriptions=(
    "iso-8859-1" => "Iso-8859-1 - Western coding. Cyrillic characters not detected.",
    "windows-1251" => "Cp1251 - MS Windows coding. Also: Windows Cyrillic (Slavic), Cyrillic. Synonims: x-cp1251, windows-1251",
    "koi8-r" => "Koi8-r - Cyrillic Unix coding.  Synonims: csKOI8R, koi",
    "koi8-u" => "Koi8-u - Cyrillic Unix coding (Ukrainian).",
    "cp866" => "Cp866 - Cyrillic DOS and OS/2 coding. Also: MS-DOS Russian, MS-DOS Cyrillic CIS 1. Synonims: cp866, ibm866",
    "iso-8859-5" => "Iso-8859-5 - Cyrillic coding approved by ISO. Used on rare Unix systems. Synonims: iso-8859-5, csISOLatinCyrillic, cyrillic, iso-ir-144, ISO_8859-5, ISO_8859-5:1988",
    "utf-8" => "Utf-8 - Unicode with Cyrillica. Synonims: utf-8, unicode-1-1-utf-8, unicode-2-0-utf-8, x-unicode-2-0-utf-8",
    "x-mac-cyrillic" => "x-mac-cyrillic - Cyrillic Macintosh. Supported by Windows NT+."
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
<h4>Coding: $Charset,  Language: $Language </h4>
<table width="80%">
     <th colspan=2> Your text in different codings: </th>
     <tr class=tr1><td width=20% ><i>Current</i></td><td > $Text_area </td></tr>
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
 <b> Time used for detecting: </b> $timedf
<hr>

<table width="60%">
     <th colspan=2> Analysis results </th>
     <tr class=tr1><td width=40%>Number of characters analyzed:</td><td >$CharsProcessed</td></tr>
     <tr><td>Charset detected:</td><td>$Coding</td></tr>
     <tr class=tr1><td>Description:</td><td>$Description</td></tr>
     <tr><td>Language:</td><td>$Language</td></tr>
     <tr class=tr1><td>Algorithm:</td><td>$Algorithm</td></tr>
</table>

<hr>
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
</body></html>

POD


__END__
print "<h5>This is the report:</h5><pre>\n";
$CyrDetector -> LogWrite();
print "</pre>\n";

print "</body></html>";
