<!-- promote-title-ids.xsl -->
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:db="http://docbook.org/ns/docbook">
  <xsl:output method="xml" indent="yes"/>

  <!-- copy everything -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- move xml:id from title to its section -->
  <xsl:template match="db:section[db:info/db:title/@xml:id]">
    <xsl:copy>
      <xsl:attribute name="xml:id">
        <xsl:value-of select="db:info/db:title/@xml:id"/>
      </xsl:attribute>
      <xsl:apply-templates select="@*[name()!='xml:id']|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
