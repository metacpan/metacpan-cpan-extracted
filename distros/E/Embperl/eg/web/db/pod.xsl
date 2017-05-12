<?xml version='1.0' encoding="ISO-8859-1" ?>


<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:pod="http://axkit.org/ns/2000/pod2xml"
                xmlns="http://www.w3.org/TR/xhtml1/strict">


    <xsl:output method="html" indent="yes" encoding="iso-8859-1"/>

    <xsl:include href="../podbase.xsl"/>

    <xsl:param name="category_id" select="2"/>
    <xsl:param name="language" select="en"/>

    <!-- - - - - Header 1 - - - - -->

    <xsl:template name="header1line">                         
     <xsl:param name="txt"></xsl:param>
      <table width="100%" border="0" cellspacing="0" cellpadding="6">
        <tr> 
          <td class="cPodH1"><xsl:value-of select="$txt"/></td>
          <td class="cPodH1Link"><a href="../add.-category_id-{$category_id}-.epl">
            <xsl:choose>
                <xsl:when test="$language='de'">[Eintrag hinzufügen]</xsl:when>
                <xsl:otherwise>[Add new entry]</xsl:otherwise>
            </xsl:choose>
              
          </a></td>
        </tr>
        <tr> 
          <td colspan="2" height="5"> </td>
        </tr>
        </table>
    </xsl:template>

    <!-- - - - - Root - - - - -->

    <xsl:template match="/">                         
        <xsl:call-template name="header1line">
            <xsl:with-param name="txt" select="/pod/head/title"/>
        </xsl:call-template>
        <xsl:apply-templates select="/pod/sect1" mode="toc1"/> 
        <hr/>
        <xsl:apply-templates select="/pod/sect1"/> 

    </xsl:template>

    <!-- - - - - table of content - - - - -->

    <xsl:template match="sect1" mode="toc1">                         
        <xsl:param name="pagehref"></xsl:param>
          <li>
            <xsl:element name="a">
                <xsl:attribute name="href"><xsl:value-of select="$pagehref"/>#sect_<xsl:number level="any"/></xsl:attribute>
                <xsl:attribute name="class">cPodH2ContentLink</xsl:attribute>
                <xsl:value-of select="title"/>
            </xsl:element>
          </li>
    </xsl:template>

    <!-- - - - - content - - - - -->

    <xsl:template match="sect1">                         
        <xsl:if test="para|verbatim|sect2">
            <br/>
            <xsl:element name="a">
                <xsl:attribute name="name">sect_<xsl:number level="any"/></xsl:attribute>
              <table width="100%" border="0" cellspacing="0" cellpadding="6">
                <tr bgcolor="#D2E9F5"> 
                  <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>
                    <font color="0"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
                        <xsl:value-of select="title"/>    
                    </font></b></font></td>
                   <td align="right"><a href="#top"><font size="1">top</font></a></td> 
                </tr>
                </table>
            </xsl:element>
        <xsl:apply-templates select="*[name()!='title']"/> 
        </xsl:if>
    </xsl:template>


</xsl:stylesheet> 