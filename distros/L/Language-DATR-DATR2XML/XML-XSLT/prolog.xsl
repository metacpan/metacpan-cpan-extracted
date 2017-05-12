<?xml version='1.0'?>
<!--	prolog.xsl version 0.3
		XSLT template to display DATR XML in HTML as dtr file format
		<code@leegoddard.com>
		Call with: <?xml-stylesheet type="text/xsl" href="dtr.xsl" ?>
		Last updated: 31 August 2000 10:41

		This is a provisional implementation of PROLOG clauses.
		The author has little idea of PROLOG implementaitons of DATR,
		and it is hope that this XSLT will be extended by one who has.

		Based on Dr Gerald Gazdar's advice that:
		    Foo:<a b c> == Baz:<d> "FooBar".
		might look something like this (details unimportant):
    		datreq('Foo',[a, b, c],[pair('Baz',[d]),quoted_node('FooBar')]).
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html"/>

<!-- The root -->

<xsl:template match="DATR">
		<xsl:apply-templates/>
		<BR/><xsl:text>&#10;</xsl:text>
		/** Produced from DATR XML by DATR prologL.xls version 0.3 **/<BR/><xsl:text>&#10;</xsl:text>

</xsl:template>

<xsl:template match="*">
	<xsl:apply-templates select="*"/>
</xsl:template>

<!-- Comment info -->
<xsl:template match="COMMENT">
	/** <xsl:value-of select="text()"></xsl:value-of>
	**/<BR/><xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- DATR definition/sentence elements -->

<xsl:template match="EQUATION">
	<!--Concatonate GROUPS of nodedefs for DATR shorthand:
		dp NOT form a union of set (cf. geraldg 06/07/00; Kay p.551),
		Only print an element's "name" attribute if the previous
		element has different "name" attribute; otherwise indent.
		Thanks to Mike and Ken; Jeni for testing. -->
   	datr_sentence('<xsl:value-of select="@node"/>',
	<!-- Path here is delimited with spaces, so replace with commas -->
	[<xsl:value-of select="translate(@path,' ',',')"/>],
	<!-- No representation of type attribute -->
	[<xsl:apply-templates select="*"/>]
	<!-- end the clause -->).
	<BR/><xsl:text>&#10;</xsl:text>
</xsl:template>


<xsl:template match="ATOM">
	<xsl:value-of select="@value"/><!--
	add a comma if there's more to come -->
	<xsl:choose>
	  <xsl:when test="following-sibling::*">, </xsl:when>
   </xsl:choose>
</xsl:template>


<xsl:template match="QUERY">
	% ?<BR/>
</xsl:template>


<xsl:template match="PATH">
	[
	<xsl:apply-templates select="*"/><!--
	add a comma if there's more to come -->
	<xsl:choose>
	  <xsl:when test="following-sibling::*">, </xsl:when>
    </xsl:choose>
	]
</xsl:template>


<xsl:template match="QUOTEDATOM">
	quoted_atom(<xsl:value-of select="@value"/>)<!--
	add a comma if there's more to come -->
	<xsl:choose>
	  <xsl:when test="following-sibling::*">, </xsl:when>
    </xsl:choose>
</xsl:template>


<xsl:template match="QUOTEDPATH">
	quoted_path(<xsl:apply-templates select="*"/>)<!--
	add a comma if there's more to come -->
	<xsl:choose>
	  <xsl:when test="following-sibling::*">, </xsl:when>
    </xsl:choose>
</xsl:template>


<xsl:template match="NODEPATH">
	pair('<xsl:value-of select="@name"/>',
	[<xsl:apply-templates select="*"/>])<!--
	Preserve whitespace and add comma if more to come -->
	<xsl:choose>
	  <xsl:when test="following-sibling::*">, </xsl:when>
   </xsl:choose>

</xsl:template>


<xsl:template match="QUOTEDNODEPATH">
	quoted_node_path('<xsl:value-of select="@name"/>',
	[<xsl:apply-templates select="*"/>]<!--
	add a comma if there's more to come -->
	<xsl:choose>
	  <xsl:when test="following-sibling::*">, </xsl:when>
    </xsl:choose>
</xsl:template>



<!-- DTR file elements -->

<xsl:template match="HEADER">

	/**********************************************<BR/><xsl:text>&#10;</xsl:text>
	<xsl:for-each select="META">
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
	<BR/><xsl:text>&#10;</xsl:text>
	</xsl:for-each>
	**********************************************/<BR/><xsl:text>&#10;</xsl:text>
	<BR/><xsl:text>&#10;</xsl:text>
</xsl:template>


<xsl:template match="OPENING">
<!-- The conditional match here is not really needed
	 but is neater and maybe needed in future -->
<!-- All directives commented out for future implimentation -->
	<xsl:for-each select="*">
		%
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
		<BR/><xsl:text>&#10;</xsl:text>
	</xsl:for-each>
	<BR/><xsl:text>&#10;</xsl:text>
</xsl:template>


<xsl:template match="CLOSING">
<!-- The conditional match here is not really needed
	 but is neater and maybe needed in future -->
<!-- All directives commented out for future implimentation -->
	<xsl:for-each select="*">
		%
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
		<BR/><xsl:text>&#10;</xsl:text>
	</xsl:for-each>
	<BR/><xsl:text>&#10;</xsl:text>
</xsl:template>

</xsl:stylesheet>
