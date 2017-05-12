<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/">
<xsl:for-each select="recs/rec">
erc:
<xsl:for-each select="*">
<xsl:value-of select="local-name(.)"/>: <xsl:value-of select="."/>
<xsl:text>
</xsl:text>
</xsl:for-each>
</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
