%Descriptions=(
    "iso-8859-1" => "Iso-8859-1 - ������������������ ���������. ��������� �� ����������.",
    "windows-1251" => "Cp1251 - ��������� MS Windows. �����: Windows Cyrillic (Slavic), Cyrillic. ��������: x-cp1251, windows-1251",
    "koi8-r" => "Koi8-r - ��������� Unix.  ��������: csKOI8R, koi",
    "koi8-u" => "Koi8-u - ��������� Unix (����������).",
    "cp866" => "Cp866 - ��������� DOS � OS/2. �����: MS-DOS Russian, MS-DOS Cyrillic CIS 1. ��������: cp866, ibm866",
    "iso-8859-5" => "Iso-8859-5 - ��������� ���������, ���������� ISO. ������������ �� ��������� �������� Unix. ��������: iso-8859-5, csISOLatinCyrillic, cyrillic, iso-ir-144, ISO_8859-5, ISO_8859-5:1988",
    "utf-8" => "Utf-8 - Unicode � ��������� ���������. ��������: utf-8, unicode-1-1-utf-8, unicode-2-0-utf-8, x-unicode-2-0-utf-8",
    "x-mac-cyrillic" => "x-mac-cyrillic - ��������� �� Macintosh. �������������� ��� Windows NT+."
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
<h4>���������: $Charset,  ����: $Language </h4>
<table width="80%">
     <th colspan=2> ��� ����� � ��������� ����������: </th>
     <tr class=tr1><td width=20% ><i>�������� �����</i></td><td > $Text_area </td></tr>
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
 <b> �����, �������������� ��� �����������: </b> $timedf
<hr>

<table width="60%">
     <th colspan=2> ���������� ������� </th>
     <tr class=tr1><td width=40%>������������������ ��������:</td><td >$CharsProcessed</td></tr>
     <tr><td>���������:</td><td>$Coding</td></tr>
     <tr class=tr1><td>��������:</td><td>$Description</td></tr>
     <tr><td>����:</td><td>$Language</td></tr>
     <tr class=tr1><td>��������:</td><td>$Algorithm</td></tr>
</table>

<hr>
<table width="80%">
     <th colspan=2> ���������� ����� ��������� </th>
     <tr class=tr1><td width=5%>11</td><td width=40%>����������
        ������ ����������/������������� ������������� ��������; ������� ������
        ���� ������������</td></tr>
     <tr><td>21</td><td>���������� ������ ����������/�������������
        ������������� ��������; ������� ���
        ������������ (koi8-r � koi8-u); ������� koi8-r</td></tr>
     <tr class=tr1><td>22</td><td>���������� ������
        ����������/�������������
        ������������� ��������; ������� ���
        ������������ (win1251 � mac); ������� win1251</td></tr>
     <tr><td>31</td><td>������� �� ������� ���� ����
        ����� �� ������� � ���� ������ ����
        ������������</td></tr>
     <tr class=tr1><td>32</td><td>������� �� ������� ����
        ���� ����� �� ���� � ���� ������ ����
        ������������</td></tr>
     <tr><td>33</td><td>��������� ���������� win1251 (������
        ����� �� ���� ������� ����)</td></tr>
     <tr class=tr1><td>34</td><td>��������� ���������� koi8-r
        (������ ����� �� ���� ������� ����)</td></tr>
     <tr><td>40</td><td>��� ������ �������� ���������
        ���������, �� ���������� �����
        ��������</td></tr>
     <tr class=tr1><td>100</td><td>�� ������� �� ������
        �������������� �������</td></tr>
</table>
</body></html>

POD


__END__
print "<h5>This is the report:</h5><pre>\n";
$CyrDetector -> LogWrite();
print "</pre>\n";

print "</body></html>";
