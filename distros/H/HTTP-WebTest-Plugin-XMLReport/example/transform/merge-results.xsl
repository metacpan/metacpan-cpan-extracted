<?xml version="1.0"?>
<!--
  Stylesheet to merge results of two test-runs
  Set "status" attribute of "group" element according to one failing subtest
  Copy a few values from test definition
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
  method="xml"
  omit-xml-declaration="no"
  indent="yes"
  encoding="utf-8"/>

  <!-- read the results of the second pass into variable "$retried" -->
  <xsl:param name="merge"/>
  <xsl:variable name="retried" select="document($merge)"/>
  <!-- read the test definition document into variable "$testdef" -->
  <xsl:param name="testdoc"/>
  <xsl:variable name="testdef" select="document($testdoc)"/>

  <xsl:template match="/">
    <xsl:apply-templates select="*|@*"/>
  </xsl:template>

  <xsl:template match="testresults">
    <xsl:element name="testresults">
      <xsl:apply-templates select="@*"/>
      <!-- insert title based on test-def. attribute -->
      <title>
        <xsl:value-of select="$testdef/WebTest/@title"/>
      </title>
      <xsl:apply-templates select="*"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="group">
    <xsl:variable name="localname" select="@name"/>
    <xsl:element name="group">
      <!-- insert attribute status based on subtests -->
      <xsl:attribute name="status">
        <xsl:choose>
          <!-- check only for second testrun result -->
          <xsl:when test="$retried/testresults/group[@name=$localname]/test/result[@status='FAIL']">
            <xsl:text>FAIL</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>PASS</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:if test="$testdef/WebTest/testgroup[@test_name=$localname]/@method='POST'">
        <xsl:attribute name="method">POST</xsl:attribute>
      </xsl:if>
      <!-- copy remaining attributes -->
      <xsl:apply-templates select="@*"/>
      <!-- select results from latest testrun -->
      <xsl:choose>
        <xsl:when test="$retried/testresults/group[@name=$localname]">
          <xsl:apply-templates select="$retried/testresults/group[@name=$localname]/test"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="test"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <!-- Utilities -->

  <!-- ## default elements: just copy ## -->
  <xsl:template match="*">
    <xsl:element name="{name()}">
      <xsl:apply-templates select="@*"/>
      <!--xsl:apply-templates select="node()"/-->
      <xsl:apply-templates select="*|processing-instruction()|comment()|text()"/>
    </xsl:element>
  </xsl:template>

  <!-- ## attributes: just copy ## -->
  <xsl:template match="@*">
    <xsl:attribute name="{name()}">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <!-- ## PI: just copy ## -->
  <xsl:template match="processing-instruction()">
    <xsl:processing-instruction name="{name()}">
      <xsl:value-of select="."/>
    </xsl:processing-instruction>
  </xsl:template>
 
  <!-- ## Comment: just copy ## -->
  <xsl:template match="comment()">
    <xsl:comment>
      <xsl:value-of select="."/>
    </xsl:comment>
  </xsl:template>


</xsl:stylesheet>
