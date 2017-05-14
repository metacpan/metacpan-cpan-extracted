<?xml version="1.0"?>
<!-- Stylesheet for displaying XML instances of Cocoon DTD "changes.dtd" -->
<!-- (c) Laurent Bossavit, 2000 - hereby made public domain -->
<!-- $Id: changes.xsl,v 1.2 2001/04/23 19:08:39 kmacleod Exp $ -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="html"/>

	<xsl:param name="packagename" select="'Package Name'"/>
	<xsl:param name="packagelocn" select="'http://package/location/'"/>

	<xsl:template match="/changes">
		<xsl:apply-templates select="release[1]"/>
	</xsl:template>

	<xsl:template match="release">
		<FONT SIZE="4"><B><A HREF="{$packagelocn}"><xsl:value-of select="$packagename"/></A></B></FONT><BR/>
		<FONT SIZE="2"><xsl:value-of select="@date"/></FONT><BR/>
		<!-- Non fixes first -->
		<TABLE cellspacing="0" cellpadding="0">
		<xsl:apply-templates select="action[@type!='fix']"/>
                <TR><TD VALIGN="TOP">-</TD><TD>Fixes:
                    <TABLE cellspacing="0" cellpadding="0">
			<xsl:apply-templates select="action[@type='fix']"/>
                    </TABLE>
                  </TD></TR>
                </TABLE>
	</xsl:template>

	<xsl:template match="action">
		<TR><TD VALIGN="TOP">-</TD><TD><xsl:value-of select="normalize-space(.)"/></TD></TR>
	</xsl:template>

</xsl:stylesheet>
