<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:csl="urn:csl">
  <xsl:output method="text" omit-xml-declaration="yes" />

  <!-- =================================================================== -->
  <!--                            MAIN                                     -->
  <!-- =================================================================== -->

  <xsl:template match="/">

/* Description of a variable */
typedef struct _<xsl:value-of select="csl:prefix()" />variable {
  char *name;
  
} <xsl:value-of select="csl:prefix()" />variable_t;
typedef struct _<xsl:value-of select="csl:prefix()" />identifiers {
    union {
      <xsl:for-each select="./csl/identifiers/identifier" >
        const char *name;
        short isTypedef;
        
      </xsl:for-each>
    } identifier;
} <xsl:value-of select="csl:prefix()" />identifiers_t;
  </xsl:template>
</xsl:stylesheet>

