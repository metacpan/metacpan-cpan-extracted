<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: debug.xsl,v 1.2 2007-02-09 17:13:25 mike Exp $ -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/1999/xhtml"
 >
 <xsl:output method="html"/>
 <xsl:template match="/">
  <html>
   <head>
    <title>Keystone Resolver</title>
    <xsl:if test="count(results/result) = 1 and
                  count(results/result[@type = 'id']) = 1">
     <xsl:element name="meta">
      <xsl:attribute name="http-equiv">refresh</xsl:attribute>
      <xsl:attribute name="content">0;url=<xsl:value-of
	select="results/result[@type = 'id']"/>
      </xsl:attribute>
     </xsl:element>
    </xsl:if>
   </head>
   <body>
    <h1>Keystone Resolver</h1>
    <p>
    <xsl:value-of disable-output-escaping="yes" select="results/result[@type = 'citation' and @tag = 'APP']"/>
    </p>
    <ul>
     <xsl:apply-templates/>
    </ul>
   </body>
  </html>
 </xsl:template>

 <xsl:template match="results/data">
   <!-- Do nothing.  This is how I prevent the content of [data]
	elements from being displayed, though I'm sure there must be a
	better way of XSLT wizards.  -->
 </xsl:template>

 <xsl:template match="results/result">
  <xsl:if test="@type != 'citation'">
  <li>
   <xsl:choose>
    <xsl:when test="@type = 'id'">
     <!-- This isn't really enough information to show the user -->
     The requested article is available via an identifier of type
     <tt><xsl:value-of select="@tag"/></tt>
     at
     <xsl:element name="a">
      <xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute>
      <xsl:value-of select="."/>
     </xsl:element>
    </xsl:when>
    <xsl:when test="@type = 'citation'">
     <!-- This needs to be XML-decoded -->
     <xsl:value-of select="."/>
    </xsl:when>
    <xsl:when test="@type = 'fulltext'">
     Get full text from
     <xsl:element name="a">
      <xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute>
      <xsl:value-of select="@service"/>
     </xsl:element>
    </xsl:when>
    <xsl:when test="@type = 'abstract'">
     Read the abstract from
     <xsl:element name="a">
      <xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute>
      <xsl:value-of select="@service"/>
     </xsl:element>
    </xsl:when>
    <xsl:when test="@type = 'websearch'">
     Search for this title at
     <xsl:element name="a">
      <xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute>
      <xsl:value-of select="@service"/>
     </xsl:element>
    </xsl:when>
    <xsl:when test="@type = 'authorsearch'">
     Find other articles by this author at
     <xsl:element name="a">
      <xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute>
      <xsl:value-of select="@service"/>
     </xsl:element>
    </xsl:when>
    <xsl:when test="@type = 'bookstore'">
     Buy on-line at
     <xsl:element name="a">
      <xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute>
      <xsl:value-of select="@service"/>
     </xsl:element>
    </xsl:when>
    <xsl:when test="@type = 'citeref'">
     Download a citation in
     <xsl:element name="a">
      <xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute>
      <xsl:value-of select="@service"/>
     </xsl:element>
     format.
    </xsl:when>
    <xsl:when test="@type = 'error'">
     <b>Error</b> -
     <xsl:value-of select="."/>
    </xsl:when>
    <xsl:otherwise>
     <b>
      Unknown service-type
      '<xsl:value-of select="@type"/>'
     </b>
     <xsl:value-of select="@service"/>
    </xsl:otherwise>
   </xsl:choose>
  </li>
  </xsl:if>
 </xsl:template>
</xsl:stylesheet>
