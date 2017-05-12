<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format">
  <xsl:output method="text" omit-xml-declaration="yes" />

  <!-- =================================== -->

  <xsl:template match="translationUnit">
/*
 * C binding pseudo code of <xsl:value-of select="$module"/>, generated <xsl:value-of select="$current-date"/>
 */
[%~ PROCESS module_start('module', '<xsl:value-of select="$module"/>') ~%]
    <xsl:apply-templates/>
[%~ PROCESS module_end('module', '<xsl:value-of select="$module"/>') ~%]
  </xsl:template>

  <!-- =================================== -->

  <xsl:template match="translationUnit/externalDeclaration/declaration">
[%~ PROCESS decl_start('file', '<xsl:value-of select="@file"/>', 'text', '<xsl:value-of select="@text"/>') ~%]
    <xsl:apply-templates/>
[%~ PROCESS decl_end('file', '<xsl:value-of select="@file"/>', 'text', '<xsl:value-of select="@text"/>') ~%]
  </xsl:template>

</xsl:stylesheet>
