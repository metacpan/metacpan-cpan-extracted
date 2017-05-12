<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:i18n="http://www.3united.com/coin/curator/i18n"
    extension-element-prefixes="i18n">

    <xsl:template match="/document">
        <xsl:value-of select="concat('test','test')"/>
        <xsl:value-of select="concat('test3',i18n:l('Tell me...'))"/>
        <xsl:value-of select="i18n:loc(&quot;Where the '[_1]'&quot;, 'hell')"/>
        <xsl:value-of select="i18n:l('do you find XSL hackers?')"/>
        <xsl:copy-of select="i18n:locfrag(&quot;...would it be &lt;a href='#' onClick='[_1]'&gt;here&lt;/a&gt;?&quot;, 'void url')"/>
        <xsl:value-of select="i18n:loc('At a place with a lot of (nested (parentheses))')"/>
        <xsl:copy-of select="i18n:lfrag(&quot;...like &lt;a href='[_1]'&gt;lispland&lt;/a&gt;?&quot;, 'void url')"/>
        <xsl:value-of select="concat(i18n:l('Mail me if you know one please!'), i18n:l('Thank you!'))"/>
        <xsl:value-of select="concat('test2','test2')"/>
    </xsl:template>

</xsl:stylesheet>