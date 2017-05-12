<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
  method="xml"
  omit-xml-declaration="yes"
  indent="yes"
  encoding="utf-8"/>

<!-- establish a "random" variable to force reload of target url -->
<xsl:variable name="rnd" select="translate(/testresults/@date,' :','--')"/>

<xsl:template match="/">
  <html>
    <head>
      <meta http-equiv="Refresh" content="600; url=sidebar.html"/>
      <meta http-equiv="Pragma" content="no-cache"/>
      <title>
        <xsl:text>WebTest Output</xsl:text>
      </title>
      <xsl:call-template name="style"/>
    </head>
    <body>
      <p>
        <xsl:value-of select="testresults/@date"/>
        <br/>
        <a href="content.html?{$rnd}#top" target="_content">
          <xsl:text>-&gt; test results</xsl:text>
        </a>
      </p>
      <xsl:apply-templates select="testresults/group"/>
    </body>
  </html>
</xsl:template>

<xsl:template match="group">
  <xsl:element name="div">
    <xsl:attribute name="title">
      <xsl:value-of select="@name"/>
    </xsl:attribute>
    <xsl:attribute name="class">
      <xsl:text>group</xsl:text>
      <xsl:if test="@status = 'FAIL'">
        <xsl:text> failed</xsl:text>
      </xsl:if>
    </xsl:attribute>
    <a href="content.html?{$rnd}#group{position()}"
       title="{@name}" target="_content">
      <xsl:value-of select="string(@name)"/>
    </a>
  </xsl:element>
</xsl:template>

<xsl:template name="style">
  <style type="text/css">
<xsl:text disable-output-escaping="yes"><![CDATA[
body {
  background-color: white;
  font-family: arial,helvetica,sans-serif;
  font-size: 8pt;
}
a {
  text-decoration: none;
  color: black;
}
a:hover {
  text-decoration: underline;
  color: blue;
}
div.group a:hover {
  text-decoration: underline;
  color: white;
}
div.group {
  margin: 2px 0px;
  padding-left: 3px;
  background-color: #1d1;
}
div.failed {
  background-color: #e00;
}
]]></xsl:text>
  </style>
</xsl:template>

</xsl:stylesheet>
