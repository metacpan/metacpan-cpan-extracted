<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html"
		encoding="UTF-8"/>
	<xsl:param name="start"/>
	<xsl:template match="/root/notification">
		<xsl:variable name="level" select="position()"/>
		<xsl:element name="input">
			<xsl:attribute name="type">hidden</xsl:attribute>
			<xsl:attribute name="name">reference<xsl:value-of select="$start"/>x<xsl:value-of select="$level"/></xsl:attribute>
			<xsl:attribute name="value"><xsl:value-of select="@reference"/></xsl:attribute>
		</xsl:element>
		<xsl:apply-templates/>
		<xsl:for-each select="check">
			<xsl:variable name="sublevel" select="position()"/>
			<p class="notifCheck">
				<xsl:element name="label">
					<xsl:attribute name="for">check<xsl:value-of select="$start"/>x<xsl:value-of select="$level"/>x<xsl:value-of select="$sublevel"/></xsl:attribute>
					<xsl:element name="input">
						<xsl:attribute name="type">checkbox</xsl:attribute>
						<xsl:attribute name="name">check<xsl:value-of select="$start"/>x<xsl:value-of select="$level"/>x<xsl:value-of select="$sublevel"/></xsl:attribute>
						<xsl:attribute name="id">check<xsl:value-of select="$start"/>x<xsl:value-of select="$level"/>x<xsl:value-of select="$sublevel"/></xsl:attribute>
						<xsl:attribute name="value">accepted</xsl:attribute>
					</xsl:element>
					<xsl:value-of select="."/>
				</xsl:element>
			</p>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="title">
		<h2 class="notifText"><xsl:value-of select="."/></h2> 
	</xsl:template>
	<xsl:template match="subtitle">
		<h3 class="notifText"><xsl:value-of select="."/></h3>
	</xsl:template>
	<xsl:template match="text">
		<p class="notifText"><xsl:value-of select="."/></p>
	</xsl:template>
	<xsl:template match="check">
	</xsl:template>
</xsl:stylesheet>

