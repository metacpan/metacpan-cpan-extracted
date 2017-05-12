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
        <html><head><title>POD</title></head><body>
        

        <xsl:apply-templates select="/pod"/> 
        </body></html>
    </xsl:template>


    <xsl:template match="head1">                         
            <h1><xsl:value-of select="."/></h1>
    </xsl:template>


    <xsl:template match="head2">                         
            <h2><img src="sq.gif" width="16" height="16" alt="-" /> <xsl:value-of select="."/></h2>
            <p/>
    </xsl:template>


    <xsl:template match="CODE">                         
            <code><xsl:value-of select="."/></code>
    </xsl:template>

    <xsl:template match="PRE">                         
            <pre><xsl:value-of select="."/></pre>
    </xsl:template>

    <xsl:template match="list">                         
            <ul>
                <xsl:apply-templates/> 
            </ul>
    </xsl:template>


    <xsl:template match="item">                         
            <li><b><xsl:apply-templates/></b></li><br/>
    </xsl:template>

    <xsl:template match="BR">                         
            <br/><br/>
    </xsl:template>


</xsl:stylesheet> 