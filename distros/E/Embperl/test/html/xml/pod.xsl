<?xml version='1.0'?>


<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/TR/xhtml1/strict">


<xsl:output
   method="xml"
   indent="yes"
   encoding="iso-8859-1"
/>


    <xsl:template match="/">                         
        <html><head><title><xsl:value-of select="/pod/head/title"/></title></head><body>
        

        <xsl:apply-templates select="/pod"/> 
        </body></html>
    </xsl:template>


    <xsl:template match="sect1/title">                         
            <h1><xsl:value-of select="."/></h1>
    </xsl:template>

    <xsl:template match="sect2/title">                         
            <h2><xsl:value-of select="."/></h2>
    </xsl:template>

    <xsl:template match="sect3/title">                         
            <h2><xsl:value-of select="."/></h2>
    </xsl:template>

    <xsl:template match="sect1">                         
        <xsl:apply-templates/> 
    </xsl:template>

    <xsl:template match="sect2">                         
        <xsl:apply-templates/> 
    </xsl:template>

    <xsl:template match="para">                         
        <p><xsl:apply-templates/></p>
    </xsl:template>

    <xsl:template match="verbatim">                         
        <pre><xsl:apply-templates/>
        </pre>
    </xsl:template>

    <xsl:template match="code">                         
            <code><xsl:value-of select="."/></code>
    </xsl:template>

    <xsl:template match="underline">                         
            <u><xsl:value-of select="."/></u>
    </xsl:template>

    <xsl:template match="emphasis">                         
            <i><xsl:value-of select="."/></i>
    </xsl:template>

    <xsl:template match="strong">                         
            <b><xsl:value-of select="."/></b>
    </xsl:template>

    <xsl:template match="list">                         
            <ul>
                <xsl:apply-templates/> 
            </ul>
    </xsl:template>


    <xsl:template match="item">                         
            <li><b><xsl:apply-templates/></b></li><br/>
    </xsl:template>



    <xsl:template name="link">
        <xsl:param name="txt"/>
        <xsl:param name="uri"/>
        <a href="{$uri}"><xsl:value-of select="$txt"/></a>
    </xsl:template>



    <xsl:template match="xlink">                         
            <xsl:choose>
                <xsl:when test="@uri">
                    <xsl:call-template name="link">
                        <xsl:with-param name="uri" select="@uri"/>
                        <xsl:with-param name="txt" select="."/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="link">
                        <xsl:with-param name="uri" select="."/>
                        <xsl:with-param name="txt" select="."/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
                 
    </xsl:template>



</xsl:stylesheet> 