<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:local="http://mycompany.com/me"
    xmlns=""
    exclude-result-prefixes="msxsl local">

<!--
    MJPH    0.1.1    7-NOV-2002     Always output char in chart
-->

<xsl:output method="html"/>

<xsl:variable name="char_font">
    <xsl:choose>
        <xsl:when test="/characterMapping/@byte-font">
            <xsl:value-of select="/characterMapping/@byte-font"/>
        </xsl:when>
        <xsl:otherwise>Times</xsl:otherwise>
    </xsl:choose>
</xsl:variable>


<xsl:variable name="hex_str">0123456789ABCDEF</xsl:variable>
<xsl:variable  name="hex_lc">0123456789abcdef</xsl:variable>
<xsl:variable name="cp1252">
    <xsl:text>&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;</xsl:text>
    <xsl:text>&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;&#x00A0;</xsl:text>
    <xsl:text>&#x00A0;&#x0021;&#x0022;&#x0023;&#x0024;&#x0025;&#x0026;&#x0027;&#x0028;&#x0029;&#x002A;&#x002B;&#x002C;&#x002D;&#x002E;&#x002F;</xsl:text>
    <xsl:text>&#x0030;&#x0031;&#x0032;&#x0033;&#x0034;&#x0035;&#x0036;&#x0037;&#x0038;&#x0039;&#x003A;&#x003B;&#x003C;&#x003D;&#x003E;&#x003F;</xsl:text>
    <xsl:text>&#x0040;&#x0041;&#x0042;&#x0043;&#x0044;&#x0045;&#x0046;&#x0047;&#x0048;&#x0049;&#x004A;&#x004B;&#x004C;&#x004D;&#x004E;&#x004F;</xsl:text>
    <xsl:text>&#x0050;&#x0051;&#x0052;&#x0053;&#x0054;&#x0055;&#x0056;&#x0057;&#x0058;&#x0059;&#x005A;&#x005B;&#x005C;&#x005D;&#x005E;&#x005F;</xsl:text>
    <xsl:text>&#x0060;&#x0061;&#x0062;&#x0063;&#x0064;&#x0065;&#x0066;&#x0067;&#x0068;&#x0069;&#x006A;&#x006B;&#x006C;&#x006D;&#x006E;&#x006F;</xsl:text>
    <xsl:text>&#x0070;&#x0071;&#x0072;&#x0073;&#x0074;&#x0075;&#x0076;&#x0077;&#x0078;&#x0079;&#x007A;&#x007B;&#x007C;&#x007D;&#x007E;&#x007F;</xsl:text>
    <xsl:text>&#x20AC;&#x0081;&#x201A;&#x0192;&#x201E;&#x2026;&#x2020;&#x2021;&#x02C6;&#x2030;&#x0160;&#x2039;&#x0152;&#x008D;&#x017D;&#x008F;</xsl:text>
    <xsl:text>&#x0090;&#x2018;&#x2019;&#x201C;&#x201D;&#x2022;&#x2013;&#x2014;&#x02DC;&#x2122;&#x0161;&#x203A;&#x0153;&#x009D;&#x017E;&#x0178;</xsl:text>
    <xsl:text>&#x00A0;&#x00A1;&#x00A2;&#x00A3;&#x00A4;&#x00A5;&#x00A6;&#x00A7;&#x00A8;&#x00A9;&#x00AA;&#x00AB;&#x00AC;&#x00AD;&#x00AE;&#x00AF;</xsl:text>
    <xsl:text>&#x00B0;&#x00B1;&#x00B2;&#x00B3;&#x00B4;&#x00B5;&#x00B6;&#x00B7;&#x00B8;&#x00B9;&#x00BA;&#x00BB;&#x00BC;&#x00BD;&#x00BE;&#x00BF;</xsl:text>
    <xsl:text>&#x00C0;&#x00C1;&#x00C2;&#x00C3;&#x00C4;&#x00C5;&#x00C6;&#x00C7;&#x00C8;&#x00C9;&#x00CA;&#x00CB;&#x00CC;&#x00CD;&#x00CE;&#x00CF;</xsl:text>
    <xsl:text>&#x00D0;&#x00D1;&#x00D2;&#x00D3;&#x00D4;&#x00D5;&#x00D6;&#x00D7;&#x00D8;&#x00D9;&#x00DA;&#x00DB;&#x00DC;&#x00DD;&#x00DE;&#x00DF;</xsl:text>
    <xsl:text>&#x00E0;&#x00E1;&#x00E2;&#x00E3;&#x00E4;&#x00E5;&#x00E6;&#x00E7;&#x00E8;&#x00E9;&#x00EA;&#x00EB;&#x00EC;&#x00ED;&#x00EE;&#x00EF;</xsl:text>
    <xsl:text>&#x00F0;&#x00F1;&#x00F2;&#x00F3;&#x00F4;&#x00F5;&#x00F6;&#x00F7;&#x00F8;&#x00F9;&#x00FA;&#x00FB;&#x00FC;&#x00FD;&#x00FE;&#x00FF;</xsl:text>
</xsl:variable>

<xsl:variable name="ranges">
    <xsl:for-each select="//range">
        <xsl:call-template name="ranges"/>
    </xsl:for-each>
<!--    <xsl:apply-templates select="//range" mode="ranges"/> -->
</xsl:variable>

<msxsl:script language="Jscript" implements-prefix="local">
<![CDATA[
    function nodeset(nodes)
    {
        return nodes.item(0);
    }
]]>
</msxsl:script>


<xsl:key name="byte-key" match="//a[not(@bactxt) and not(@bbctxt)]" use="@b"/>
<xsl:key name="byte-key" match="//fbu[not(@bactxt) and not(@bbctxt)]" use="@b"/>
<!-- <xsl:key name="byte-key" match="local:nodeset($ranges)/a[not(@bactxt) and not(@bbctxt) and not(contains(@u, ' '))]" use="@b"/> -->

<xsl:key name="uni-key" match="//a[not(@uactxt) and not(@ubctxt)]" use="@u"/>
<xsl:key name="uni-key" match="//fub[not(@uactxt) and not(@ubctxt)]" use="@u"/>
<!-- <xsl:key name="uni-key" match="local:nodeset($ranges)/a[not(@uactxt) and not(@ubctxt) and not(contains(@b, ' '))]" use="@u"/> -->



<xsl:template match="/characterMapping">
    <html><head>
    <title>Mapping Description for <xsl:value-of select="@id"/></title>
    <style type="text/css">
        .head {font-size: 200%; font-style: bold; text-align:center; background-color: #F0F0F0}
        .id {font-size: 70%; margin: 0; padding: 0;}
        .char {font: 200%, '<xsl:value-of select="$char_font"/>'; margin: 0; padding: 0; text-align: center}
        .normalhead {font-size: 125%; font-style: bold}
    </style>
<!--        <META http-equiv="Content-Type" content="text/html; charset=UTF-8"/> -->
    </head><body>
<!--    <xsl:comment>
        <xsl:for-each select="//result">
            <xsl:call-template name="ranges"/>
        </xsl:for-each>
    </xsl:comment>
-->
    <h1>Mapping Description for <xsl:value-of select="@description"/></h1>
    <xsl:for-each select="history/modified">
        <xsl:sort select="@version" data-type="number" order="descending"/>
        <xsl:if test="position() = 1">
            <p>Version <xsl:value-of select="@version"/>, <xsl:value-of select="@date"/>.</p>
        </xsl:if>
    </xsl:for-each>
<!--    <p>There are <xsl:value-of select="count(local:nodeset($ranges)//a)"/> range elements.</p> -->
    <h2>Chart</h2>
        <xsl:call-template name="chart"/>
    <h3>Ligatures</h3>
    <div style="margin-left: 3em">
        <table border="1" style="border-style: solid; border-collapse: collapse">
            <thead><tr><td class="normalhead">Bytes</td><td class="normalhead">Unicodes</td></tr></thead>
            <tbody>
                <xsl:apply-templates select="//a[contains(@b, ' ') or contains(@u, ' ')]|//fbu[contains(@b, ' ') or contains(@u, ' ')]|//fub[contains(@b, ' ') or contains(@u, ' ')]"
                        mode="ligatures"/>
            </tbody>
        </table>
    </div>
    <h2>Warnings</h2>
        <xsl:apply-templates select="//a|//fbu|//fub" mode="errors">
            <xsl:sort select="@u"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="//range" mode="errors"/>
    <h2>History</h2>
        <xsl:apply-templates select="//modified"/>
    </body></html>
</xsl:template>

<xsl:template match="modified" mode="Intro">
    <p>Version <xsl:value-of select="@version"/></p>
</xsl:template>

<xsl:template name="chart">
<div style="text-align: center">
<table cellspacing="0" border="1" style="border-style: solid; border-collapse: collapse">
    <thead>
        <tr class="head">
            <td>&#x00A0;</td><td>0</td><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td>
            <td>8</td><td>9</td><td>A</td><td>B</td><td>C</td><td>D</td><td>E</td><td>F</td><td>&#x00A0;</td>
        </tr>
    </thead>
    <tbody>
        <xsl:call-template name="chart_row"/>
    </tbody>
    <tfoot>
        <tr class="head">
            <td>&#x00A0;</td><td>0</td><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td>
            <td>8</td><td>9</td><td>A</td><td>B</td><td>C</td><td>D</td><td>E</td><td>F</td><td>&#x00A0;</td>
        </tr>
    </tfoot>
</table>
</div>
</xsl:template>

<xsl:template name="chart_row">
    <xsl:param name="row" select="0"/>
    <tr>
        <td class="head">
            <xsl:value-of select="substring($hex_str, $row + 1, 1)"/>
        </td>
        <xsl:call-template name="chart_cell">
            <xsl:with-param name="row" select="$row"/>
        </xsl:call-template>
        <td class="head">
            <xsl:value-of select="substring($hex_str, $row + 1, 1)"/>
        </td>
    </tr>
    <xsl:if test="$row &lt; 15">
        <xsl:call-template name="chart_row">
            <xsl:with-param name="row" select="$row + 1"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template name="chart_cell">
    <xsl:param name="row" select="0"/>
    <xsl:param name="column" select="0"/>
    <xsl:variable name="cell_num" select="$column * 16 + $row"/>
    <xsl:variable name="cell_hex" select="concat(substring($hex_str, $column + 1, 1), substring($hex_str, $row + 1, 1))"/>
    <xsl:call-template name="cell">
        <xsl:with-param name="number" select="$cell_num"/>
        <xsl:with-param name="cell_hex" select="$cell_hex"/>
    </xsl:call-template>
    <xsl:if test="$column &lt; 15">
        <xsl:call-template name="chart_cell">
            <xsl:with-param name="row" select="$row"/>
            <xsl:with-param name="column" select="$column + 1"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template name="cell">
    <xsl:param name="number" select="0"/>
    <xsl:param name="cell_hex" select="'00'"/>
    <xsl:variable name="match" select="local:nodeset($ranges)/a[@b=$cell_hex]|key('byte-key', $cell_hex)"/>
    <xsl:variable name="char" select="substring($cp1252, $number + 1, 1)"/>
    <xsl:choose>
        <xsl:when test="not($match)">
            <td style="background-color: #E8E8FF">
                <p class="id"><xsl:value-of select="$number"/>&#x00A0;&#x00A0;<xsl:value-of select="$char"/></p>
                <p class="char"><xsl:value-of select="$char"/></p>
                <p class="id">&#x00A0;</p>
            </td>
        </xsl:when>
        <xsl:when test="contains($match/@u, ' ')">
            <td style="background-color: #E8FFE8">
                <p class="id"><xsl:value-of select="$number"/>&#x00A0;&#x00A0;<xsl:value-of select="$char"/></p>
                <p class="char"><xsl:value-of select="$char"/></p>
                <p class="id">&#x00A0;</p>
            </td>
        </xsl:when>
        <xsl:when test="count($match) > 1">
            <td style="background-color: #FFE8E8">
                <p class="id"><xsl:value-of select="$number"/>&#x00A0;&#x00A0;<xsl:value-of select="$char"/></p>
                <p class="char"><xsl:value-of select="$char"/></p>
                <p class="id">&#x00A0;</p>
            </td>
        </xsl:when>
        <xsl:when test="(not(key('uni-key', $match/@u)) and not(local:nodeset($ranges)/a[@u=$match/@u]))
                or count(key('uni-key', $match/@u)) > 1">
            <td style="background-color: #FFE8E8">
                <p class="id"><xsl:value-of select="$number"/>&#x00A0;&#x00A0;<xsl:value-of select="$char"/></p>
                <p class="char"><xsl:value-of select="$char"/></p>
                <p class="id">U+<xsl:value-of select="$match/@u"/></p>
            </td>
        </xsl:when>
        <xsl:otherwise>
            <td>
                <p class="id"><xsl:value-of select="$number"/>&#x00A0;&#x00A0;<xsl:value-of select="$char"/></p>
                <p class="char"><xsl:value-of select="$char"/></p>
                <p class="id">U+<xsl:value-of select="$match/@u"/></p>
            </td>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="a|fbu|fub" mode="ligatures">
    <tr><td><xsl:value-of select="@b"/></td><td><xsl:value-of select="@u"/></td></tr>
</xsl:template>

<xsl:template match="a" mode="errors">
    <xsl:if test="not(@bactxt) and not(@bbctxt) and not(contains(@u, ' '))">
        <xsl:if test="not(key('uni-key', @u)|local:nodeset($ranges)/a[@u=current()/@u])">
            <p>No reverse mapping for U+<xsl:value-of select="@u"/> mapped from 0x<xsl:value-of select="@b"/></p>
        </xsl:if>
        <xsl:if test="count(key('uni-key', @u)|local:nodeset($ranges)/a[@u=current()/@u]) > 1">
            <p>Multiple mapping from U+<xsl:value-of select="@u"/> to at least 0x<xsl:value-of select="@b"/></p>
        </xsl:if>
    </xsl:if>
    <xsl:if test="not(@uactxt) and not(@ubctxt) and not(contains(@b, ' '))">
        <xsl:if test="not(key('byte-key', @b)|local:nodeset($ranges)/a[@b=current()/@b])">
            <p>No reverse mapping for 0x<xsl:value-of select="@b"/> mapped from U+<xsl:value-of select="@u"/></p>
        </xsl:if>
        <xsl:if test="count(key('byte-key', @b)|local:nodeset($ranges)/a[@b=current()/@b]) > 1">
            <p>Multiple mapping from 0x<xsl:value-of select="@b"/> to at least U+<xsl:value-of select="@u"/></p>
        </xsl:if>
    </xsl:if>
</xsl:template>

<xsl:template match="fbu" mode="errors">
    <xsl:if test="not(@bactxt) and not(@bbctxt) and not(contains(@u, ' '))">
        <xsl:if test="not(key('uni-key', @u)|local:nodeset($ranges)/a[@u=current()/@u])">
            <p>No reverse mapping for U+<xsl:value-of select="@u"/> mapped from 0x<xsl:value-of select="@b"/></p>
        </xsl:if>
        <xsl:if test="count(key('uni-key', @u)|local:nodeset($ranges)/a[@u=current()/@u]) > 1">
            <p>Multiple mapping from U+<xsl:value-of select="@u"/> to at least 0x<xsl:value-of select="@b"/></p>
        </xsl:if>
    </xsl:if>
</xsl:template>

<xsl:template match="fub" mode="errors">
    <xsl:if test="not(@uactxt) and not(@ubctxt) and not(contains(@b, ' '))">
        <xsl:if test="not(key('byte-key', @b)|local:nodeset($ranges)/a[@b=current()/@b])">
            <p>No reverse mapping for 0x<xsl:value-of select="@b"/> mapped from U+<xsl:value-of select="@u"/></p>
        </xsl:if>
        <xsl:if test="count(key('byte-key', @b|local:nodeset($ranges)/a[@b=current()/@b])) > 1">
            <p>Multiple mapping from 0x<xsl:value-of select="@b"/> to at least U+<xsl:value-of select="@u"/></p>
        </xsl:if>
    </xsl:if>
</xsl:template>

<xsl:template match="range" mode="errors">
    <xsl:call-template name="range-errors">
        <xsl:with-param name="bfirst">
            <xsl:call-template name="hex2dec">
                <xsl:with-param name="hex" select="@bFirst"/>
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="blast">
            <xsl:call-template name="hex2dec">
                <xsl:with-param name="hex" select="@bLast"/>
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="ufirst">
            <xsl:call-template name="hex2dec">
                <xsl:with-param name="hex" select="@uFirst"/>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template name="range-errors">
    <xsl:param name="bfirst"/>
    <xsl:param name="blast"/>
    <xsl:param name="ufirst"/>
    <xsl:variable name="hb">
        <xsl:call-template name="dec2hex">
            <xsl:with-param name="dec" select="$bfirst"/>
            <xsl:with-param name="len" select="'00'"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="hu">
        <xsl:call-template name="dec2hex">
            <xsl:with-param name="dec" select="$ufirst"/>
            <xsl:with-param name="len" select="'0000'"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:if test="not(@bactxt) and not(@bbctxt) and not(contains(@u, ' '))">
        <xsl:if test="not(key('uni-key', @u)|local:nodeset($ranges)/a[@u=$hu])">
            <p>No reverse mapping for U+<xsl:value-of select="@u"/> mapped from 0x<xsl:value-of select="@b"/></p>
        </xsl:if>
        <xsl:if test="count(key('uni-key', @u)|local:nodeset($ranges)/a[@u=$hu]) > 1">
            <p>Multiple mapping from U+<xsl:value-of select="@u"/> to at least 0x<xsl:value-of select="@b"/></p>
        </xsl:if>
    </xsl:if>
    <xsl:if test="not(@uactxt) and not(@ubctxt) and not(contains(@b, ' '))">
        <xsl:if test="not(key('byte-key', @b)|local:nodeset($ranges)/a[@b=$hb])">
            <p>No reverse mapping for 0x<xsl:value-of select="@b"/> mapped from U+<xsl:value-of select="@u"/></p>
        </xsl:if>
        <xsl:if test="count(key('byte-key', @b)|local:nodeset($ranges)/a[@b=$hb]) > 1">
            <p>Multiple mapping from 0x<xsl:value-of select="@b"/> to at least U+<xsl:value-of select="@u"/></p>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$bfirst &lt; $blast">
        <xsl:call-template name="range-errors">
            <xsl:with-param name="bfirst" select="$bfirst + 1"/>
            <xsl:with-param name="blast" select="$blast"/>
            <xsl:with-param name="ufirst" select="$ufirst + 1"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template match="modified">
    <p style="margin-bottom: 0; padding-bottom: 0">Version <xsl:value-of select="@version"/>, <xsl:value-of select="@date"/></p>
    <p style="padding-left: 3em; margin-top: 0; padding-top: 0"><xsl:value-of select="."/></p>
</xsl:template>

<xsl:template name="ranges">
    <xsl:call-template name="range-unpack">
        <xsl:with-param name="bfirst">
            <xsl:call-template name="hex2dec">
                <xsl:with-param name="hex" select="@bFirst"/>
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="blast">
            <xsl:call-template name="hex2dec">
                <xsl:with-param name="hex" select="@bLast"/>
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="ufirst">
            <xsl:call-template name="hex2dec">
                <xsl:with-param name="hex" select="@uFirst"/>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template name="range-unpack">
    <xsl:param name="bfirst"/>
    <xsl:param name="blast"/>
    <xsl:param name="ufirst"/>
    <xsl:element name="a">
        <xsl:attribute name="b">
            <xsl:call-template name="dec2hex">
                <xsl:with-param name="dec" select="$bfirst"/>
                <xsl:with-param name="len" select="'00'"/>
            </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="u">
            <xsl:call-template name="dec2hex">
                <xsl:with-param name="dec" select="$ufirst"/>
                <xsl:with-param name="len" select="'0000'"/>
            </xsl:call-template>
        </xsl:attribute>
    </xsl:element>
    <xsl:if test="$bfirst &lt; $blast">
        <xsl:call-template name="range-unpack">
            <xsl:with-param name="bfirst" select="$bfirst + 1"/>
            <xsl:with-param name="blast" select="$blast"/>
            <xsl:with-param name="ufirst" select="$ufirst + 1"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template name="hex2dec">
    <xsl:param name="hex"/>
    <xsl:param name="dec" select="0"/>
    <xsl:variable name="res" select="$dec * 16 + string-length(substring-before($hex_str, substring($hex, 1, 1)))"/>
    <xsl:choose>
        <xsl:when test="string-length($hex) > 1">
            <xsl:call-template name="hex2dec">
                <xsl:with-param name="hex" select="substring($hex, 2)"/>
                <xsl:with-param name="dec" select="$res"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$res"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="dec2hex">
    <xsl:param name="dec" select="0"/>
    <xsl:param name="len" select="'0'"/>
    <xsl:param name="hex"/>
    <xsl:variable name="res" select="concat(substring($hex_str, ($dec mod 16) + 1, 1), $hex)"/>
    <xsl:choose>
        <xsl:when test="$dec > 15">
            <xsl:call-template name="dec2hex">
                <xsl:with-param name="dec" select="floor($dec div 16)"/>
                <xsl:with-param name="len" select="$len"/>
                <xsl:with-param name="hex" select="$res"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="concat(substring($len, string-length($res) + 1), $res)"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
