<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" 
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:alvis="http://alvis.info/enriched/" >

<xsl:output method="text" encoding="UTF-8"/>

<xsl:template match="alvis:canonicalDocument">

<xsl:value-of select="."/>

</xsl:template>

<xsl:template match="text()"/>

</xsl:stylesheet>

