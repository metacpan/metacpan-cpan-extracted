<?xml version='1.0'?>
<!--	dtrHTML.xsl		Last updated: 24/08/00 16:16
		XSLT template to display DATR XML in HTML as dtr file format
		Copyright (C) Lee Goddard, 2/7/2000. All rights reserved.
		<code@leegoddard.com>
		Call with: <?xml-stylesheet type="text/xsl" href="dtr.xsl" ?>
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html"/>

<!-- The root -->

<xsl:template match="DATR">
		<TT>
		<xsl:apply-templates/>
		</TT>
		<BR/>
		<HR size="1" color="teal"/>
		<FONT size="1" face="Lucinda, Verdana, Helvectia, Arial, Sans-serif" color="teal">
		Produced from DATR XML by DATR datrHTML.xls version 0.13<BR/>
		</FONT>
</xsl:template>

<xsl:template match="*">
	<xsl:apply-templates select="*"></xsl:apply-templates>
</xsl:template>

<!-- Comment info -->
<xsl:template match="COMMENT">
	<FONT color="green">%
	<xsl:value-of select="text()"></xsl:value-of>
	</FONT>
	<BR/>
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
			<B>
			<xsl:value-of select="@node"/>:
			</B>
		</xsl:when>
		<xsl:otherwise>
			&#160;&#160;&#160;&#160;&#160;&#160;
		</xsl:otherwise>
	</xsl:choose>
	<FONT color="#0000AA">
	&lt;<xsl:value-of select="@path"/>&gt;
	</FONT>
	<xsl:if test="@type[.='EXTEND']">=</xsl:if>
	<xsl:if test="@type[.!='EXTEND']">==</xsl:if> <!-- the default -->
	&#160;
	<xsl:apply-templates select="*"/>
   	<xsl:if test="not(@node = following-sibling::*[@node][1]/@node)">
		<!-- end the clause --><B>.</B>
		<BR/>
	</xsl:if>
	<BR/>
</xsl:template>


<xsl:template match="QUERY">
	<FONT color="black">?</FONT>
</xsl:template>


<xsl:template match="ATOM">
	<FONT color="navy">
	<xsl:value-of select="@value"/>
	</FONT>
</xsl:template>

<xsl:template match="PATH">
	<FONT color="navy">
	&lt;<xsl:apply-templates select="*"/>&gt;
	</FONT>
</xsl:template>

<xsl:template match="QUOTEDATOM">
	<FONT color="blue">
	&quot;<xsl:value-of select="@value"/>&quot;
	</FONT>
</xsl:template>

<xsl:template match="QUOTEDPATH">
	<FONT color="blue">
	&quot;&lt;<xsl:apply-templates select="*"/>&gt;&quot;
	</FONT>
</xsl:template>

<xsl:template match="NODEPATH">
	<FONT color="navy">
	<xsl:value-of select="@name"/>
	:
	&lt;<xsl:apply-templates select="*"/>&gt;
	</FONT>
</xsl:template>

<xsl:template match="QUOTEDNODEPATH">
	<FONT color="blue">
	&quot;
	<xsl:value-of select="@name"/>:
	&lt;<xsl:apply-templates select="*"/>&gt;
	&quot;
	</FONT>
</xsl:template>


<!-- DTR file elements -->

<xsl:template match="HEADER">
	<FONT color="gray" size="1">
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%<BR/>
	%<BR/>
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
	 :&#160; <!-- nbsp -->
	 <FONT face="Georgia, Times, Serif">
	 <xsl:value-of select="@content"/>
	 </FONT>
	<BR/>
	</xsl:for-each>
	%<BR/>
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%<BR/>
	<BR/>
	</FONT>
</xsl:template>

<xsl:template match="OPENING">
<!-- The conditional match here is not really needed
	 but is neater and maybe needed in future -->
	<xsl:for-each select="*">
		<FONT color="red">
		# <xsl:value-of select="name()"/> <xsl:text>&#32;</xsl:text>
		</FONT>
		<FONT color="darkred">
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
		</FONT>
		<!-- end clause -->
		<FONT color="red">
			<B>.</B><BR/>
		</FONT>
	</xsl:for-each>
	<BR/>
</xsl:template>



<xsl:template match="CLOSING">
<!-- The conditional match here is not really needed
	 but is neater and maybe needed in future -->
	<xsl:for-each select="*">
		<FONT color="red">
		# <xsl:value-of select="name()"/> <xsl:text>&#32;</xsl:text>
		</FONT>
		<FONT color="darkred">
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
		</FONT>
		<!-- end clause -->
		<FONT color="red">
			<B>.</B><BR/>
		</FONT>
	</xsl:for-each>
	<BR/>
</xsl:template>


</xsl:stylesheet>






