<?xml version="1.0"?>
<!--
  Stylesheet to list names of testgroups
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
  method="html"
  omit-xml-declaration="no"
  indent="yes"
  encoding="utf-8"/>

  <xsl:template match="/">
   <html>
    <head>
     <title>WebTest: <xsl:value-of select="/WebTest/@title"/></title>
    </head>
    <body>
     <h2>WebTest: <xsl:value-of select="/WebTest/@title"/></h2>
     <table border="1">
      <tr>
       <th>#</th>
       <th>Test</th>
       <th>Comment</th>
      </tr>
      <xsl:apply-templates select="//testgroup"/>
     </table>
    </body>
   </html>
  </xsl:template>

  <xsl:template match="testgroup">
   <tr>
    <td><xsl:value-of select="position()"/></td>
    <td><xsl:value-of select="@test_name"/></td>
    <td><xsl:value-of select="comment"/></td>
   </tr>
  </xsl:template>

</xsl:stylesheet>
