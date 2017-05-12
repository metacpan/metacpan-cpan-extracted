<?xml version='1.0' encoding="ISO-8859-1" ?>


<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/TR/xhtml1/strict">

    <xsl:include href="../pod.xsl"/>

    <!-- - - - - Root - - - - -->

    <xsl:template match="/">                         
        <xsl:call-template name="header1line">
            <xsl:with-param name="txt" select="/pod/head/title"/>
        </xsl:call-template>
        <xsl:apply-templates select="/pod/sect1"/> 

    </xsl:template>


</xsl:stylesheet> 