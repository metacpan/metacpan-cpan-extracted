<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<!--    Output HTML    -->
	<xsl:template match="/">
		<html>
			<head>
				<title>Links</title>
				<link rel="stylesheet" type="text/css" href="menu.css"/>
			</head>
			<body>
				<table border="0">
					<xsl:call-template name="results"/>
				</table>
			</body>
		</html>
	</xsl:template>
	<!--    Header service types    -->
	<xsl:template match="/result" name="header">
		<xsl:param name="header"/>
		<tr>
			<td>
				<div class="head">
					<xsl:value-of select="$header"/>
				</div>
			</td>
		</tr>
	</xsl:template>
	<!--    Output results   -->
	<xsl:template match="/results" name="results_out">
		<xsl:param name="type"/>
		<xsl:param name="header"/>
		<xsl:if test="/results/result[@type=$type]">
			<xsl:call-template name="header">
				<xsl:with-param name="header">
					<xsl:value-of select="$header"/>
				</xsl:with-param>
			</xsl:call-template>
			<xsl:for-each select="/results/result">
				<xsl:if test="@type=$type">
					<tr>
						<td>
							<xsl:element name="a">
								<xsl:attribute name="href"><xsl:value-of select="@text"/></xsl:attribute>
								<xsl:attribute name="class">lnk</xsl:attribute>
								<xsl:value-of select="@service"/>
							</xsl:element>
						</td>
					</tr>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	<!--    Select types and headers   -->
	<xsl:template match="/results" name="results">
		<xsl:call-template name="results_out">
			<xsl:with-param name="type">fulltext</xsl:with-param>
			<xsl:with-param name="header">Get fulltext</xsl:with-param>
		</xsl:call-template>
		<xsl:if test="results/data/metadata[@key='atitle'] != ''">
			<xsl:call-template name="results_out">
				<xsl:with-param name="type">websearch</xsl:with-param>
				<xsl:with-param name="header">Search for the title on the web</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<!--    Books   -->
		<xsl:call-template name="results_out">
			<xsl:with-param name="type">authorsearch</xsl:with-param>
			<xsl:with-param name="header">Other works by same author</xsl:with-param>
		</xsl:call-template>
		<xsl:call-template name="results_out">
			<xsl:with-param name="type">bookstore</xsl:with-param>
			<xsl:with-param name="header">Buy from online bookstore</xsl:with-param>
		</xsl:call-template>
		<!--    Games   -->
		<xsl:if test="results/data/metadata[@key='type'] = 'game'">
			<xsl:call-template name="results_out">
				<xsl:with-param name="type">game</xsl:with-param>
				<xsl:with-param name="header">More about the game</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="results/data/metadata[@key='type'] = 'game'">
			<xsl:call-template name="results_out">
				<xsl:with-param name="type">game_buy</xsl:with-param>
				<xsl:with-param name="header">Buy the game from online store</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<!--    Movies   -->
		<xsl:if test="results/data/metadata[@key='type'] = 'movie'">
			<xsl:call-template name="results_out">
				<xsl:with-param name="type">movie</xsl:with-param>
				<xsl:with-param name="header">More about the movie</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="results/data/metadata[@key='type'] = 'movie'">
			<xsl:if test="results/data/metadata[@key='creator'] != ''">
				<xsl:call-template name="results_out">
					<xsl:with-param name="type">movie</xsl:with-param>
					<xsl:with-param name="header">More about the director</xsl:with-param>
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
		<xsl:if test="results/data/metadata[@key='format'] = 'dvd'">
			<xsl:call-template name="results_out">
				<xsl:with-param name="type">movie</xsl:with-param>
				<xsl:with-param name="header">Buy the dvd from online store</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<!--    Music   -->
		<xsl:if test="results/data/metadata[@key='type'] = 'music'">
			<xsl:call-template name="results_out">
				<xsl:with-param name="type">music</xsl:with-param>
				<xsl:with-param name="header">More about the artist</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="results/data/metadata[@key='format'] = 'cd'">
			<xsl:call-template name="results_out">
				<xsl:with-param name="type">music</xsl:with-param>
				<xsl:with-param name="header">Buy the cd from online store</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
