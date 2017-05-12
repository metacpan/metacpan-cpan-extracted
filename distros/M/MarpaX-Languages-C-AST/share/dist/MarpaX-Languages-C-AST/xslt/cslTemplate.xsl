<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:csl="urn:csl">
  <xsl:output method="text" omit-xml-declaration="yes" />

  <!-- =================================================================== -->
  <!--                            MAIN                                     -->
  <!-- =================================================================== -->

  <xsl:template match="/csl">
/* List of all identifiers enums */
  <!-- enum mode -->
typedef enum <xsl:value-of select="csl:prefix()"/>_enum_ = {
    <xsl:for-each select="./identifiers">
      <xsl:call-template name="identifiers">
        <xsl:with-param name="base" select="''"/>
        <xsl:with-param name="mode" select="'enum'"/>
      </xsl:call-template>
    </xsl:for-each>
  <xsl:value-of select="csl:prefix()"/>_NULL
} <xsl:value-of select="csl:prefix()"/>_enum;

/* Identifiers full name */
  <!-- fullIdentifier mode -->
const char **<xsl:value-of select="csl:prefix()"/>_identifiers[] = {
    <xsl:for-each select="./identifiers">
      <xsl:call-template name="identifiers">
        <xsl:with-param name="base" select="''"/>
        <xsl:with-param name="mode" select="'fullIdentifier'"/>
      </xsl:call-template>
    </xsl:for-each>
  NULL
}
  </xsl:template>

  <!-- =================================================================== -->
  <!--                         IDENTIFIERS                                 -->
  <!-- =================================================================== -->
  <xsl:template name="identifiers">
    <xsl:param name="base"/>
    <xsl:param name="mode"/>
    <xsl:for-each select="./identifier">
      <xsl:call-template name="identifier">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="mode" select="$mode"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- =================================================================== -->
  <!--                         IDENTIFIER                                  -->
  <!-- =================================================================== -->
  <xsl:template name="identifier">
    <xsl:param name="base"/>
    <xsl:param name="mode"/>
    <xsl:variable name="fullIdentifier">
      <xsl:choose>
        <xsl:when test="$base!=''">
          <xsl:value-of select="concat($base, '_', ./@text)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="./@text" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$mode='fullIdentifier'">
       "<xsl:value-of select="$fullIdentifier" />",
      </xsl:when>
      <xsl:when test="$mode='enum'">
        <xsl:value-of select="csl:prefix()"/>_<xsl:value-of select="$fullIdentifier" />,
      </xsl:when>
    </xsl:choose>
    <!--
        inner identifiers. This can happen only when we recurse, and the
        possible cases are:
        function/parameters
        members/member
    -->
    <xsl:for-each select="./function/parameters/identifiers">
      <xsl:call-template name="identifiers">
        <xsl:with-param name="base" select="$fullIdentifier"/>
        <xsl:with-param name="mode" select="$mode"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:for-each select="./members/member/identifiers">
      <xsl:call-template name="identifiers">
        <xsl:with-param name="base" select="$fullIdentifier"/>
        <xsl:with-param name="mode" select="$mode"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
