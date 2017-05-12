<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
  method="xml"
  omit-xml-declaration="yes"
  indent="yes"
  encoding="utf-8"/>

<xsl:template match="/">
  <html>
    <head>
      <meta http-equiv="Refresh" content="600; url=content.html"/>
      <meta http-equiv="Pragma" content="no-cache"/>
      <title>
        <xsl:value-of select="testresults/title"/>
        <xsl:text> - </xsl:text>
        <xsl:value-of select="testresults/@date"/>
      </title>
      <xsl:call-template name="style"/>
      <xsl:call-template name="script"/>
    </head>
    <body>
      <a name="top"><xsl:comment>top</xsl:comment></a>
      <h2>
        <xsl:value-of select="testresults/title"/>
        <xsl:text> - </xsl:text>
        <xsl:value-of select="testresults/@date"/>
      </h2>
      <h3>WebTest results</h3>
      <ul>
        <xsl:apply-templates select="testresults/group" mode="toc"/>
      </ul>
      <p>
        <a href="javascript:addNetscapePanel('{testresults/title}'); void(0);">Add this to Mozilla Sidepanel</a>
      </p> 
      <xsl:apply-templates select="testresults/group" mode="body"/>
    </body>
  </html>
</xsl:template>

<xsl:template match="group" mode="toc">
  <li>
    <span class="{@status}">
      <xsl:value-of select="@status"/>
    </span>
    <xsl:text>: </xsl:text>
    <a href="#group{position()}">
      <xsl:value-of select="string(@name)"/>
    </a>
  </li>
</xsl:template>

<xsl:template match="group" mode="body">
  <a name="group{position()}">
    <xsl:comment> This space for rent </xsl:comment>
  </a>
  <div class="group">
    <div style="float: right; padding-right: 5px;">
      <a href="#top">TOP</a>
    </div>
    <a href="{@url}" onclick="return warn(this, '{@method}');" title="Link: request url for {@name}">
      <xsl:value-of select="@name"/>
    </a>
    <xsl:if test="@method">
      <xsl:text> (method = </xsl:text>
      <xsl:value-of select="@method"/>
      <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="test"/>
  </div>
</xsl:template>

<xsl:template match="test">
  <div class="test">
    <span title="{@name}">
      <xsl:value-of select="string(@name)"/>
    </span>
    <xsl:apply-templates select="result"/>
  </div>
</xsl:template>

<xsl:template match="result">
  <xsl:element name="div">
    <xsl:attribute name="class">
      <xsl:text>result </xsl:text>
      <xsl:value-of select="@status"/>
    </xsl:attribute>
    <xsl:attribute name="title">
      <xsl:value-of select="."/>
    </xsl:attribute>
    <div class="status">
      <xsl:value-of select="string(@status)"/>
    </div>
    <xsl:value-of select="string(.)"/>
  </xsl:element>
</xsl:template>

<!-- Utilities -->

<xsl:template name="script">
  <script language="JavaScript">
<xsl:text disable-output-escaping="yes"><![CDATA[ //<![CDATA[
function warn(oLink, strMethod) {
  var strWarn = oLink.href;
  if (strWarn.length > 53) {
    strWarn = strWarn.substring(0,50) + "...";
  }
  strWarn += '\n \n';
  if (strMethod == 'POST') {
    strWarn += 'This link does not match the test condition\n';
    strWarn += 'because POST data is missing.\n \n';
  } else {
    strWarn += 'This link may not fully match the test conditions.\n';
    strWarn += 'Cookies or adapted http-headers may exist.\n \n'
  }
  strWarn += 'Continue?';
  return window.confirm(strWarn);
}
function addNetscapePanel(strTitle) {
  if ((typeof window.sidebar == "object") && (typeof window.sidebar.addPanel == "function"))
  {
    if (!strTitle) strTitle = "WebTest";
    var url = document.location.protocol + '//' + document.location.host + document.location.pathname;
    url = url.substring(0,url.indexOf('content.html')) + 'sidebar.html';
    window.sidebar.addPanel (strTitle, url, "");
  } else {
    var rv = window.confirm ("This page is enhanced for use with Netscape 6. "
        + "Would you like to upgrade now?");
    if (rv)
      document.location.href = "http://home.netscape.com/download/index.html";
    }
}
]]>// ]]&gt;</xsl:text>
  </script>
</xsl:template>

<xsl:template name="style">
  <style type="text/css">
<xsl:text disable-output-escaping="yes"><![CDATA[
body {
  background-color: white;
  font-family: arial,helvetica,sans-serif;
  font-size: 10pt;
}
a {
  text-decoration: none;
  color: darkblue;
}
a:hover {
  text-decoration: underline;
  color: blue;
}
div.group {
  margin: 16px 0px;
  padding: 0px 3px;
  background-color: white;
  border: 1px solid black;
  font-weight: bold;
}
div.test {
  margin: 4px 0px;
  padding: 1px 4px;
  background-color: white;
  border: 1px solid #999;
  font-weight: normal;
}
div.result {
  margin: 1px 0px;
  padding: 1px 8px;
  font-family: courier,monospace;
}
.PASS {
  background-color: #1d1;
}
.FAIL {
  background-color: #e00;
}
div.status {
  font-family: arial,helvetica,sans-serif;
  font-weight: bold;
  font-size: 9pt;
  width: 50px;
  float: left;
  color: white;
}
]]></xsl:text>
  </style>
</xsl:template>

</xsl:stylesheet>
