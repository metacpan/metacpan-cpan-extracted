<?xml version="1.0"?>
<!-- define a DOS type line ending as entity -->
<!DOCTYPE stylesheet [ <!ENTITY crlf "&#13;&#10;"> ]> 
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
  method="text"
  omit-xml-declaration="yes"
  indent="no"
  encoding="iso-8859-1"/>
<xsl:strip-space elements="*"/>

<!-- read the test definition document into variable "$testdef" -->
<xsl:param name="testdoc"/>
<xsl:variable name="testdef" select="document($testdoc)"/>

<xsl:template match="/">
  <!-- count number of failed tests -->
  <xsl:variable name="failed">
    <xsl:value-of select="count(//group[test/result/@status = 'FAIL'])"/>
  </xsl:variable>
  <!-- list failed test numbers -->
  <xsl:variable name="testnums">
    <xsl:for-each select="//group[test/result/@status = 'FAIL']">
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="$testdef/WebTest/testgroup" method="testnumber">
        <xsl:with-param name="testname" select="@name"/>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="$failed = 0">
      <!--
      <xsl:message terminate="yes">
        <xsl:text>All tests passed.</xsl:text>
      </xsl:message>
      -->
   </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="email-headers">
        <xsl:with-param name="num" select="$failed"/>
        <xsl:with-param name="list" select="$testnums"/>
      </xsl:call-template>
      <xsl:text>Output of </xsl:text>
      <xsl:value-of select="concat($testdef/WebTest/@title,' (',$failed,' failed) at ')"/>
      <xsl:value-of select="testresults/@date"/>
      <xsl:text>&crlf;&crlf;</xsl:text>
      <xsl:apply-templates select="testresults"/>
      <xsl:call-template name="email-footer"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="testresults">
  <xsl:apply-templates mode="list-tests"
       select="group[count(test/result[normalize-space(@status) = 'FAIL']) &gt; 0]"/>
  <xsl:text>&crlf;Test links:&crlf;</xsl:text>
  <xsl:apply-templates mode="list-links"
       select="group[count(test/result[normalize-space(@status) = 'FAIL']) &gt; 0]"/>

</xsl:template>

<xsl:template match="group" mode="list-tests">
  <!-- we only have nodes with failed subtests -->
  <xsl:variable name="failed">
    <xsl:value-of select="count(test/result[normalize-space(@status) = 'FAIL'])"/>
  </xsl:variable>
  <xsl:variable name="testname">
    <xsl:value-of select="@name"/>
  </xsl:variable>
  <xsl:variable name="testnumber">
    <!-- test number in original test specification -->
    <xsl:apply-templates select="$testdef/WebTest/testgroup" method="testnumber">
      <xsl:with-param name="testname" select="$testname"/>
    </xsl:apply-templates>
  </xsl:variable>
  <xsl:value-of disable-output-escaping="yes" 
                  select="concat('[',position(),'] test #',$testnumber,': ',normalize-space(@name),'&crlf;')"/>
  <xsl:value-of select="concat('Failed: ',$failed,' of ',count(test/result),' subtest')"/>
  <xsl:if test="count(test/result) &gt; 1">
    <xsl:text>s</xsl:text>
  </xsl:if>
  <xsl:if test="$testdef/WebTest/testgroup[@test_name=$testname]/@method">
    <xsl:text> (method=</xsl:text>
    <xsl:value-of select="$testdef/WebTest/testgroup[@test_name=$testname]/@method"/>
    <xsl:text>)</xsl:text>
  </xsl:if>
  <xsl:text>&crlf;</xsl:text>
  <xsl:for-each select="test/result[normalize-space(@status) = 'FAIL']">
    <xsl:value-of disable-output-escaping="yes"
                  select="concat('  ',../@name,': &quot;',normalize-space(.),'&quot;&crlf;')"/>
  </xsl:for-each>
  <xsl:text>&crlf;</xsl:text>
</xsl:template>

<xsl:template match="testgroup" method="testnumber">
  <xsl:param name="testname"/>
  <xsl:if test="@test_name=$testname">
    <xsl:value-of select="position()"/>
  </xsl:if>
</xsl:template>

<xsl:template match="group" mode="list-links">
  <xsl:variable name="num">
    <xsl:value-of select="position()"/>
  </xsl:variable>
  <xsl:variable name="testname">
    <xsl:value-of select="@name"/>
  </xsl:variable>
  <xsl:if test="$num &lt; 100">
    <xsl:text> </xsl:text>
  </xsl:if>
  <xsl:if test="$num &lt; 10">
    <xsl:text> </xsl:text>
  </xsl:if>
  <xsl:number value="$num" format="1. "/>
  <xsl:value-of select="@url"/>
  <xsl:if test="$testdef/WebTest/testgroup[@test_name=$testname]/@method">
    <xsl:text> (method=</xsl:text>
    <xsl:value-of select="$testdef/WebTest/testgroup[@test_name=$testname]/@method"/>
    <xsl:text>)</xsl:text>
  </xsl:if>
  <xsl:text>&crlf;</xsl:text>
</xsl:template>

<xsl:template name="email-headers">
  <xsl:param name="num"/>
  <xsl:param name="list"/>
  <xsl:text>From: </xsl:text>
  <xsl:value-of disable-output-escaping="yes" select="$testdef/WebTest/param/mail_from"/>
  <xsl:text>&crlf;To: </xsl:text>
  <xsl:for-each select="$testdef/WebTest/param/mail_addresses">
    <xsl:value-of disable-output-escaping="yes" select="concat(text(), ', ')"/>
  </xsl:for-each>
  <xsl:choose>
    <xsl:when test="normalize-space($testdef/WebTest/param/mail_method)='SMS'">
      <xsl:text>&crlf;Subject: Webtest:</xsl:text>
      <xsl:value-of select="$list"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>&crlf;Subject: [webtest] </xsl:text>
      <xsl:value-of select="$num"/>
      <xsl:choose>
        <xsl:when test="$num &gt; 1">
          <xsl:text> tests</xsl:text>
        </xsl:when>
        <xsl:when test="$num = 1">
          <xsl:text> test</xsl:text>
        </xsl:when>
      </xsl:choose>
      <xsl:text> failed for "</xsl:text>
      <xsl:value-of select="$testdef/WebTest/@title"/>
      <xsl:text>".</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>&crlf;&crlf;</xsl:text>
</xsl:template>


<xsl:template name="email-footer">
  <xsl:text>
-- 
NOTE: the test links will not properly work if the original
test contained POST data, cookie headers or other http-headers
which affect the application's behaviour.
</xsl:text>
</xsl:template>

</xsl:stylesheet>
