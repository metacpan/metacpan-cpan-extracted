<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xhtml" omit-xml-declaration='yes' media-type="text/html" encoding="utf-8"/>

<xsl:template name="mbody">
   <p>
      <!-- horrible hack -->
      <xsl:apply-templates select="child::node()[1][name() != 'member']"/>
      <xsl:apply-templates select="child::node()[2][name() = 'p']"/>
   </p>
   <table border="1" width="100%">
      <tr>
         <th width="10%">NAME</th>
         <th width="8%">TYPE</th>
         <th width="4%">VALUE</th>
         <th>DESCRIPTION</th>
         <th width="10%">GUARD</th>
      </tr>
      <xsl:apply-templates select="child::member"/>
   </table>
</xsl:template>

<xsl:template match="member">
   <tr>
       <td><xsl:value-of select="@name"/></td>
       <td><xsl:value-of select="@type"/></td>
       <td><xsl:value-of select="@value"/>&#160;</td>
       <td>
           <!-- horrible hack -->
           <xsl:if test="following-sibling::node()[1][name() != 'member']">
              <xsl:apply-templates select="following-sibling::node()[1]"/>
              <xsl:if test="following-sibling::node()[2][name() != 'member']">
                 <xsl:apply-templates select="following-sibling::node()[2]"/>
                 <xsl:if test="following-sibling::node()[3][name() != 'member']">
                    <xsl:apply-templates select="following-sibling::node()[3]"/>
                    <xsl:if test="following-sibling::node()[4][name() != 'member']">
                       <xsl:apply-templates select="following-sibling::node()[4]"/>
                       <xsl:if test="following-sibling::node()[5][name() != 'member']">
                          <xsl:apply-templates select="following-sibling::node()[5]"/>
                       </xsl:if>
                    </xsl:if>
                 </xsl:if>
              </xsl:if>
           </xsl:if>
           &#160;
       </td>
       <td>
           <b><xsl:value-of select="@guard-member"/></b>
           <xsl:text> </xsl:text><xsl:value-of select="@guard-cond"/>
           &#160;
       </td>
   </tr>
</xsl:template>

<xsl:template match="type">
   <h4>TYPE <xsl:value-of select="@name"/></h4>
   BASE TYPE <xsl:value-of select="@type"/>, LENGTH <xsl:value-of select="@length"/>, MULTIPLIER <xsl:value-of select="@multiplier"/>
   <br/>
</xsl:template>

<xsl:template match="enum|set">
   <h4><xsl:value-of select="name()"/>: <xsl:value-of select="@name"/></h4>
   <xsl:call-template name="mbody"/>
</xsl:template>

<xsl:template match="struct">
   <h4>STRUCTURE <xsl:value-of select="@name"/></h4>
   <xsl:if test="@class">
      CLASS: <xsl:value-of select="@class"/><br/>
   </xsl:if>
   <xsl:call-template name="mbody"/>
</xsl:template>

<xsl:template match="message">
   <h4>
      <xsl:if test="@src='server'"><a name="{concat('S', @type)}"/>ORIGIN: SERVER;</xsl:if>
      <xsl:if test="@src='client'"><a name="{concat('C', @type)}"/>ORIGIN: CLIENT;</xsl:if>
      MESSAGE: <xsl:value-of select="@name"/>
   </h4>
   NUMERIC TYPE (hex): <xsl:value-of select="@type"/>
   <xsl:if test="@src='server'">
      <xsl:variable name="ref" select="@name"/>
      <xsl:for-each select="//message[@src='client' and descendant::ref[@reply=$ref]]">
         (possibly in response to
         <a href="{concat('#C', @type)}"><xsl:value-of select="concat(@name, '(', @type, ')')"/></a>
         )
      </xsl:for-each>
   </xsl:if>
   <xsl:call-template name="mbody"/>
</xsl:template>

<xsl:template match="ref">
   <xsl:variable name="ref" select="concat(@ref, @reply)"/>
   <xsl:for-each select="//message[@src='server' and @name=$ref]">
      <a href="{concat('#S', @type)}"><xsl:value-of select="concat(@name, '(', @type, ')')"/></a>
   </xsl:for-each>
</xsl:template>

<xsl:template match="@*|node()">
   <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
   </xsl:copy>
</xsl:template>

</xsl:stylesheet>

