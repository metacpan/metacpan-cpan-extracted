<?xml version="1.0"?>
<!--
  Stylesheet to list names of testgroups
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
  method="text"
  omit-xml-declaration="no"
  indent="yes"
  encoding="utf-8"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//testgroup"/>
  </xsl:template>

  <xsl:template match="testgroup">
    <xsl:value-of select="position()"/>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="/WebTest/@title"/>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="@test_name"/>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="comment"/>
    <xsl:text>&#13;&#10;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
