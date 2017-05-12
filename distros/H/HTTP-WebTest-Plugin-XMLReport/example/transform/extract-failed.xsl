<?xml version="1.0"?>
<!--
 Usage:
   xsltproc -param testdoc "'Input.xml'" extract-failed.xsl Output.xml
 Where:
   Input.xml  = original webtest specification
   Output.xml = output of webtest, based on Input.xml
 Returns:
   WebTest specification with only tests that failed in Output.xml
 Purpose:
   Use the resulting document to run previously failed webtest groups again
 -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
  method="xml"
  omit-xml-declaration="no"
  indent="yes"
  encoding="utf-8"/>

<xsl:param name="testdoc"/>
<xsl:variable name="testtree" select="document($testdoc)"/>
<xsl:key name="testNameKey" match="/WebTest/testgroup" use="@test_name"/>

  <xsl:template match="/testresults">
    <WebTest title="{$testtree/WebTest/@title}">
      <xsl:comment>
        <xsl:text>Failed tests from Webtest run at </xsl:text>
        <xsl:value-of select="@date"/>
      </xsl:comment>
      <!-- copy global test parameter block -->
      <xsl:apply-templates select="$testtree/WebTest/param" />
      <!-- find testgroups with failed subtests -->
      <xsl:for-each select="group">
        <xsl:variable name="name" select="@name"/>
        <xsl:if test="test/result[@status='FAIL']">
          <!-- breaks when test-text contains 'dash-dash' sequence...
          <xsl:comment>
            <xsl:text>First failed test: </xsl:text>
            <xsl:value-of select="test[result/@status='FAIL']/@name"/>
            <xsl:text> = </xsl:text>
            <xsl:value-of select="test/result[@status='FAIL']"/>
          </xsl:comment>
          -->
          <xsl:apply-templates select="$testtree/WebTest/testgroup[@test_name=$name]"/>
        </xsl:if>
      </xsl:for-each>
    </WebTest>
  </xsl:template>

  <xsl:template match="testgroup">
    <!-- first copy previous testgroup if there is no url attribute -->
    <xsl:if test="not(@url)">
      <xsl:apply-templates select="preceding-sibling::*[position()=1]"/>
    </xsl:if>
    <!-- then the current testgroup element -->
    <xsl:element name="testgroup">
      <xsl:apply-templates select="@*|node()|comment"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="@*|node()|comment">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>



</xsl:stylesheet>
