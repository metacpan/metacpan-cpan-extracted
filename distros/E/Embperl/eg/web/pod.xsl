<?xml version='1.0' encoding="ISO-8859-1" ?>


<!-- the following seems not to work with libxml -->

<!DOCTYPE stylesheet [
<!ENTITY nbsp "<xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text>">  
<!ENTITY space "<xsl:text> </xsl:text>">
<!ENTITY cr "<xsl:text>
</xsl:text>">
]>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/TR/xhtml1/strict">

    <xsl:output method="html" indent="yes" encoding="ISO-8859-1"/>

    <xsl:include href="podbase.xsl"/> 


    <!-- - - - - Header 1 - - - - -->

    <xsl:template name="header1line">                         
     <xsl:param name="txt"></xsl:param>
      <table width="100%" border="0" cellspacing="0" cellpadding="6">
        <tr> 
          <td class="cPodH1"><xsl:value-of select="$txt"/></td>
        </tr>
        </table>
    </xsl:template>


    <!-- - - - - Get number - - - - -->
    
    <xsl:template match="sect1" mode="number"><xsl:number/></xsl:template>                         
    <xsl:template match="sect2" mode="number"><xsl:number level="any"/></xsl:template>                         

 
    <!-- - - - - Header Navigation - - - - -->

    <xsl:template name="headernav">                         
            <a name="top">
            <xsl:choose>

                <!-- - - - - Header Navigation - normal page - - - -->


                <xsl:when test="not(pod/sect1)">
                    <xsl:variable name="nextpage">
                        <xsl:apply-templates select="following-sibling::sect1[para|verbatim|sect2][position()=1]" mode="number"/>
                    </xsl:variable>

                    <xsl:variable name="prevpage">
                        <xsl:apply-templates select="preceding-sibling::sect1[para|verbatim|sect2][position()=1]" mode="number"/>
                    </xsl:variable>
            
                    <table width="100%">
                      <tr>
                        <td align="left" valign="top" width="45%">
                          <xsl:if test="$prevpage &gt; 0">
                            <a href="{$basename}.-page-{$prevpage}-.{$extension}" class="cPodHeaderNavLink">
                                [ &lt;&lt; Prev: <xsl:value-of select="preceding-sibling::sect1[para|verbatim|sect2][position()=1]/title"/> ]
                            </a>
                          </xsl:if>
                        </td>
                        <td align="center"  valign="top" width="10%">
                        <a href="{$basename}.{$extension}" class="cPodHeaderNavLink">[ Content ]</a>
                        </td>
                        <td align="right" valign="top" width="45%">
                        <xsl:if test="following-sibling::sect1">
                            <a href="{$basename}.-page-{$nextpage}-.{$extension}" class="cPodHeaderNavLink">
                                [ Next: <xsl:value-of select="following-sibling::sect1[para|verbatim|sect2]/title"/> &gt;&gt; ]
                            </a>

                        </xsl:if>
                        </td>
                      </tr>
                    </table>
                </xsl:when>

                <!-- - - - - Header Navigation - content page - - - -->

                <xsl:otherwise>
                    <xsl:variable name="nextpage">
                        <xsl:apply-templates select="/pod/sect1[para|verbatim|sect2][position()=1]" mode="number"/>
                    </xsl:variable>
                    <table width="100%">
                      <tr>
                        <td align="right">
                          <a href="{$basename}.-page-{$nextpage}-.{$extension}" class="cPodHeaderNavLink">
                            [ Next: <xsl:value-of select="/pod/sect1[para|verbatim|sect2]/title"/> &gt;&gt; ]
                          </a>
                        </td>
                    </tr>
                  </table>
                </xsl:otherwise>
            </xsl:choose>
            </a>
    </xsl:template>

    <!-- - - - - Root - - - - -->

    <xsl:template match="/">                         
                <xsl:choose>
                    <xsl:when test="count(/pod/sect1) = 1">
                        <xsl:apply-templates select="/pod/sect1"> 
                            <xsl:with-param name="shownav">0</xsl:with-param>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$page = 0">
                        <xsl:call-template name="header1line">
                            <xsl:with-param name="txt">Content - <xsl:value-of select="/pod/head/title|/pod/sect1/title"/></xsl:with-param>
                        </xsl:call-template>
                        <xsl:call-template name="headernav"/>
                        
                        <ul>              
                            <xsl:apply-templates select="/pod/sect1" mode="toc_short"/> 
                        </ul>              
                        <hr/>
                        <ul>              
                            <xsl:apply-templates select="/pod/sect1" mode="toc"/> 
                        </ul>              
                        <hr/>
                        <xsl:call-template name="headernav"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="/pod/sect1[position()=$page]"/> 
                    </xsl:otherwise>
                </xsl:choose>
    </xsl:template>

    <!-- - - - - table of content - short - - - - -->

    <xsl:template match="sect1" mode="toc_short">                         
        <xsl:if test="para|verbatim|sect2|list">
              <li>
                <xsl:element name="a">
                  <xsl:attribute name="href"><xsl:value-of select="$basename"/>.-page-<xsl:number/>-.<xsl:value-of select="$extension"/></xsl:attribute>
                  <xsl:attribute name="class">cPodH1ContentLink</xsl:attribute>
                <xsl:value-of select="title"/>
              </xsl:element>
              </li>
        </xsl:if>
    </xsl:template>

    <!-- - - - - table of content - long - - - - -->

    <xsl:template match="sect1" mode="toc">                         
        <xsl:if test="para|verbatim|sect2|list">
            <xsl:variable name="pagehref">
                <xsl:value-of select="$basename"/>.-page-<xsl:number/>-.<xsl:value-of select="$extension"/>
            </xsl:variable>

            <li><a href="{$pagehref}" class="cPodH1ContentLink"><xsl:value-of select="title"/></a></li>
            <xsl:if test="sect2">
                <ul>
                    <xsl:apply-templates select="sect2" mode="toc1">
                        <xsl:with-param name="pagehref" select="$pagehref"/>
                    </xsl:apply-templates>
                </ul>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:template match="sect2" mode="toc1">                         
        <xsl:param name="pagehref"></xsl:param>
          <li>
            <xsl:element name="a">
                <xsl:attribute name="href"><xsl:value-of select="$pagehref"/>#sect_<xsl:number level="any"/></xsl:attribute>
                <xsl:attribute name="class">cPodH2ContentLink</xsl:attribute>
                <xsl:value-of select="title"/>
            </xsl:element>
          </li>
    </xsl:template>

    <!-- ********** content - sect1 ********** -->

    <xsl:template match="sect1">                         
        <xsl:param name="shownav">1</xsl:param>
          
        <xsl:call-template name="header1line">
            <xsl:with-param name="txt" select="title"/>
        </xsl:call-template>

        <xsl:if test="$shownav = 1">
            <xsl:call-template name="headernav"/>
        </xsl:if>

        <xsl:if test="para|verbatim|sect2|list">
            <xsl:if test="sect2">
                <ul>
                    <xsl:apply-templates select="sect2" mode="toc1"/> 
                </ul><hr/>
            </xsl:if>
            <xsl:apply-templates select="*[name()!='title']"/> 
        </xsl:if>

        <xsl:if test="$shownav = 1">
            <hr/>
            <xsl:call-template name="headernav"/>
        </xsl:if>

    </xsl:template>


    <!-- ********** content - sect2 ********** -->

    <xsl:template match="sect2">                         
        <br/>
        <xsl:element name="a">
            <xsl:attribute name="name">sect_<xsl:number level="any"/></xsl:attribute>
          <table width="100%" border="0" cellspacing="0" cellpadding="6">
            <tr class="cPodH2"> 
              <td><xsl:value-of select="title"/></td>
              <td align="right"><a href="#top" class="cTopLink">top</a></td> 
            </tr>
            </table>
        </xsl:element>
        <xsl:apply-templates select="*[name()!='title']"/> 
    </xsl:template>



</xsl:stylesheet> 