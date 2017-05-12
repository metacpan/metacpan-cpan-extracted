<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
	<xsl:output method="html" encoding="UTF-8" indent="yes"/>
	<xsl:template match="UXF">
		<html>
			<head>
				<title/>
				<style type="text/css"><![CDATA[
.hdPackages {  font-family: Arial, Helvetica, sans-serif; font-size: 24px; font-class: normal; font-weight: bold; color: #FFFFFF; background-color: #00FF00; text-align: left}
.hdModules {  font-family: Arial, Helvetica, sans-serif; font-size: 18px; font-class: normal; font-weight: bold; background-color: #00FFCC; text-align: left}
.hdClasses {  font-family: Arial, Helvetica, sans-serif; font-size: 16px; font-class: normal; font-weight: bold; text-align: left; background-color: #99FF99}
.hdOperations {  font-family: Arial, Helvetica, sans-serif; font-size: 14px; font-class: normal; font-weight: bold; background-color: #FFFF00; text-align: left}
.tdOperation {  font-family: Arial, Helvetica, sans-serif; font-size: 12px; font-class: normal; font-weight: normal; background-color: #FFFF99; text-align: left; vertical-align: top;}
.hdAttributes {  font-family: Arial, Helvetica, sans-serif; font-size: 16px; font-class: normal; font-weight: bold; background-color: #FF9900; text-align: left}
.tdAttribute {  font-family: Arial, Helvetica, sans-serif; font-size: 12px; font-class: normal; font-weight: normal; background-color: #FFCC99; text-align: left; vertical-align: top;}
]]></style>
			</head>
			<body bgcolor="#33CCFF">
				<table bgcolor="#33CCFF" width="'80%'" align="center">
					<tr>
						<td class="hdPackages">Packages</td>
					</tr>
					<xsl:apply-templates select="Package"/>
				</table>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="Package">
		<tr>
			<td>
				<table border="1" width="100%" cellpadding="10" cellspacing="3">
					<tbody>
						<tr>
							<td class="hdModules">Module <a href="file://{Note/text()}">
									<xsl:if test="Name = ''"><![CDATA[<unknown>]]></xsl:if>
									<xsl:value-of select="Name"/>
									<xsl:attribute name="href">file://<xsl:value-of select="Note"/></xsl:attribute>
								</a>
							</td>
						</tr>
						<tr>
							<td>
								<xsl:apply-templates select="Class">
									<xsl:sort select="Name"/>
								</xsl:apply-templates>
							</td>
						</tr>
					</tbody>
				</table>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="Class">
		<table border="1" width="100%" cellpadding="5">
			<tbody>
				<tr>
					<td class="hdClasses" colspan="2">Class <xsl:if test="Name = ''"><![CDATA[<unknown>]]></xsl:if>
						<xsl:value-of select="Name"/>
					</td>
				</tr>
				<tr>
					<td class="hdOperations">
						<xsl:choose>
							<xsl:when test="Operation">Operations</xsl:when>
							<xsl:otherwise>Operations: none</xsl:otherwise>
						</xsl:choose>
					</td>
					<td class="hdAttributes">
						<xsl:choose>
							<xsl:when test="Attribute">Attributes</xsl:when>
							<xsl:otherwise>Attributes: none</xsl:otherwise>
						</xsl:choose>
					</td>
				</tr>
				<tr>
					<td class="tdOperation">
						<xsl:choose>
							<xsl:when test="Operation">
								<xsl:apply-templates select="Operation">
									<xsl:sort select="Name"/>
								</xsl:apply-templates>
							</xsl:when>
							<xsl:otherwise/>
						</xsl:choose>
					</td>
					<td class="tdAttribute">
						<xsl:choose>
							<xsl:when test="Attribute">
								<xsl:apply-templates select="Attribute">
									<xsl:sort select="Name"/>
								</xsl:apply-templates>
							</xsl:when>
							<xsl:otherwise/>
						</xsl:choose>
					</td>
				</tr>
			</tbody>
		</table>
	</xsl:template>
	<xsl:template match="Attribute">
		<table border="0" width="100%" cellpadding="5" class="tdAttribute">
			<tbody>
				<tr>
					<td class="tdAttribute">
						<xsl:if test="Name = ''"><![CDATA[<unknown>]]></xsl:if>
						<xsl:value-of select="Name"/>
					</td>
				</tr>
			</tbody>
		</table>
	</xsl:template>
	<xsl:template match="Operation">
		<table border="0" width="100%" cellpadding="5">
			<tbody>
				<tr>
					<td class="tdOperation">
						<xsl:if test="Name = ''"><![CDATA[<unknown>]]></xsl:if>
						<xsl:value-of select="Name"/>
					</td>
				</tr>
			</tbody>
		</table>
	</xsl:template>
</xsl:stylesheet>
