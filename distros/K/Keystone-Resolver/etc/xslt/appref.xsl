<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: appref.xsl,v 1.3 2007-02-09 17:13:25 mike Exp $ -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/1999/xhtml"
 >
 <xsl:output method="html"/>
 <xsl:template match="/">
  <html>
   <head>
    <title>Keystone Resolver: APP-style Reference</title>
   </head>
   <body>
    <p>
     <xsl:value-of disable-output-escaping="yes"
	select="results/result[@type='citation' and @tag='APP']"/>
    </p>
   </body>
  </html>
 </xsl:template>
</xsl:stylesheet>
