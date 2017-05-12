<?xml version='1.0'?>
<!--	dtr.xsl version 0.14 Last updated: 24/08/00 16:16
		XSLT template to display DATR XML in HTML as dtr file format
		Copyright (C) Lee Goddard, 2/7/2000. All rights reserved.
		<code@leegoddard.com>
		Call with: <?xml-stylesheet type="text/xsl" href="dtr.xsl" ?>
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text"/>

<!-- The root -->
<xsl:template match="DATR">
		<xsl:apply-templates/>
		<xsl:text>&#10;</xsl:text>
		% ------------------------------------------------------------<xsl:text>&#10;</xsl:text>
		% Produced from DATR XML by DATR datrHTML.xls version 0.14<xsl:text>&#10;</xsl:text>

</xsl:template>

<xsl:template match="*">
	<xsl:apply-templates select="*"></xsl:apply-templates>
</xsl:template>

<!-- Comment info -->
<xsl:template match="COMMENT">
	% <xsl:value-of select="text()"></xsl:value-of>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- DATR definition/sentence elements -->

<xsl:template match="EQUATION">
	<!--Concatonate GROUPS of nodedefs for DATR shorthand:
		dp NOT form a union of set (cf. geraldg 06/07/00; Kay p.551),
		Only print an element's "name" attribute if the previous
		element has different "name" attribute; otherwise indent.
		Thanks to Mike and Ken; Jeni for testing. -->
   	<xsl:choose>
		<xsl:when test="not(@node = preceding-sibling::*[@node][1]/@node )">
			<xsl:value-of select="@node"/>:
		</xsl:when>
		<xsl:otherwise>
			&#160;&#160;&#160;&#160;&#160;&#160;
		</xsl:otherwise>
	</xsl:choose>
	&lt;<xsl:value-of select="@path"/>&gt;
	<xsl:if test="@type[.='EXTEND']">=</xsl:if>
	<xsl:if test="@type[.!='EXTEND']">==</xsl:if>	<!-- the default -->
	&#160;
	<xsl:apply-templates select="*"/>
   	<xsl:if test="not(@node = following-sibling::*[@node][1]/@node)">
		<!-- end the clause -->.
	</xsl:if>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="QUERY">?</xsl:template>

<xsl:template match="ATOM">
	<xsl:value-of select="@value"/>
</xsl:template>

<xsl:template match="PATH">
	&lt;<xsl:apply-templates select="*"/>&gt;
</xsl:template>

<xsl:template match="QUOTEDATOM">
	"<xsl:value-of select="@value"/>"
</xsl:template>

<xsl:template match="QUOTEDPATH">
	"&lt;<xsl:apply-templates select="*"/>&gt;"
</xsl:template>

<xsl:template match="NODEPATH">
	<xsl:value-of select="@name"/>:
	&lt;<xsl:apply-templates select="*"/>&gt;
</xsl:template>

<xsl:template match="QUOTEDNODEPATH">
	"<xsl:value-of select="@name"/>:
	&lt;<xsl:apply-templates select="*"/>&gt;"
</xsl:template>

<!-- DTR file elements -->
<xsl:template match="HEADER">
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%<xsl:text>&#10;</xsl:text>
	%<xsl:text>&#10;</xsl:text>
	<xsl:for-each select="META">
	%
		<xsl:choose>
		  <xsl:when test="META">
			 <xsl:value-of select="@name"/>
		  </xsl:when>
		  <xsl:otherwise>
			 <xsl:value-of select="@name"/>
		  </xsl:otherwise>
	   </xsl:choose>
	 :&#160;
	 <xsl:value-of select="@content"/>
	<xsl:text>&#10;</xsl:text>
	</xsl:for-each>
	%<xsl:text>&#10;</xsl:text>
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%<xsl:text>&#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>
</xsl:template>


<xsl:template match="OPENING">
<!-- The conditional match here is not really needed
	 but is neater and maybe needed in future -->
	<xsl:for-each select="*">
		# <xsl:value-of select="name()"/> <xsl:text>&#32;</xsl:text>
		<xsl:if test="@value">
			<xsl:value-of select="@value"/>
		</xsl:if>
		<xsl:if test="@filename">
			<xsl:value-of select="@filename"/>
		</xsl:if>
		<xsl:if test="@range">
		<xsl:value-of select="@range"/>
		</xsl:if>
		<xsl:apply-templates select="*"/>
		<!-- end clause -->.
		<xsl:text>&#10;</xsl:text>
	</xsl:for-each>
	<xsl:text>&#10;</xsl:text>
</xsl:template>


<xsl:template match="CLOSING">
<!-- The conditional match here is not really needed
	 but is neater and maybe needed in future -->
	<xsl:for-each select="*">
		# <xsl:value-of select="name()"/> <xsl:text>&#32;</xsl:text>
		<xsl:if test="@value">
			<xsl:value-of select="@value"/>
		</xsl:if>
		<xsl:if test="@filename">
			<xsl:value-of select="@filename"/>
		</xsl:if>
		<xsl:if test="@range">
			<xsl:value-of select="@range"/>
		</xsl:if>
		<xsl:apply-templates select="*"/>
		<!-- end clause -->.
		<xsl:text>&#10;</xsl:text>
	</xsl:for-each>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

</xsl:stylesheet>
