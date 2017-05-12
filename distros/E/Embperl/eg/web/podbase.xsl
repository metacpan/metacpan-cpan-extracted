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


    <xsl:variable name="newswidth">152</xsl:variable>

    <xsl:param name="page" select="0"/>
    <xsl:param name="basename">default</xsl:param>
    <xsl:param name="extension">html???</xsl:param>
    <xsl:param name="baseuri">/eg/web/</xsl:param>
    <xsl:param name="imageuri">/eg/images/</xsl:param>


    <!-- - - - - list - - - - -->

    <xsl:template match="list">                         
        <table border="0" cellspacing="3" cellpadding="0">
               <xsl:apply-templates mode="item"/> 
        </table>
    </xsl:template>



    <xsl:template match="item" mode="item">                         
        <tr class="cItemText">
            <td valign="top">
                    <img src="{$imageuri}but.gif"/><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
            </td>
            <td>
                    <xsl:apply-templates select="itemtext"/>
            </td>
        </tr>
        <xsl:if test="*[name()!='itemtext']">
        <tr>
            <td>
                    <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>     
            </td>
            <td>
                    <xsl:apply-templates select="*[name()!='itemtext']"/>
            </td>
        </tr>
        <tr>
            <td colspan="2">
                    <img src="{$imageuri}transp.gif" height="4"/>
            </td>
        </tr>
        </xsl:if>
    </xsl:template>


    <xsl:template match="list" mode="item">                         
        <tr>
            <td>
                    <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>     
            </td>
            <td>
                <table border="0" cellspacing="3" cellpadding="0">
                       <xsl:apply-templates mode="item"/> 
                </table>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="itemtext">                         
            <p><xsl:apply-templates/></p>
    </xsl:template>


    <!-- - - - - code - - - - -->

<!--
    <xsl:template match="verbatim">                         
        <xsl:if test="not(preceding-sibling::node()[1][name()='verbatim'])">    
     	    <table width="100%" cellspacing="0"><tr>
            <td width="5%"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></td>
            <td  class="cPodVerbatim"  width="90%">
            <br/><pre>
                <xsl:apply-templates/> 
                <xsl:apply-templates select="following-sibling::node()[1][name()='verbatim']" mode="verbatim"/>
            </pre>
            </td>
            <td width="5%"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></td>
            </tr></table>
	</xsl:if>
    </xsl:template>
-->

    <xsl:template match="verbatim">                         
        <xsl:if test="not(preceding-sibling::node()[1][name()='verbatim'])">    
            <pre class="cPodVerbatim">
                <xsl:apply-templates/> 
                <xsl:apply-templates select="following-sibling::node()[1][name()='verbatim']" mode="verbatim"/>
            </pre>
	</xsl:if>
    </xsl:template>


    <xsl:template  match="verbatim" mode="verbatim">                         
		<xsl:text>

</xsl:text>
                <xsl:apply-templates/> 
                <xsl:apply-templates select="following-sibling::node()[1][name()='verbatim']" mode="verbatim"/>
    </xsl:template>

    <!-- - - - - link - - - - -->

    <xsl:template name="link">
        <xsl:param name="txt"/>
        <xsl:param name="uri"/>
        <xsl:param name="useuri"/>
        <xsl:choose>
            <xsl:when test="contains($uri, '.pod')">
                <xsl:element name="a">
                    <xsl:attribute name="href"><xsl:value-of select="$baseuri"/>pod/doc/<xsl:value-of select="substring-before($uri, '.pod')"/>.htm</xsl:attribute>
                    <xsl:value-of select="$txt"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="contains($uri, '::')">
                <xsl:element name="a">
                    <xsl:attribute name="href"><xsl:value-of select="translate($uri, ':', '/')"/></xsl:attribute>
                    <xsl:value-of select="$txt"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="starts-with($uri, 'http:')">
                <a href="{$uri}"><xsl:value-of select="$txt"/></a>
            </xsl:when>
            <xsl:when test="starts-with($uri, 'ftp:')">
                <a href="{$uri}"><xsl:value-of select="$txt"/></a>
            </xsl:when>
            <xsl:otherwise>
                
                <xsl:variable name="page">
                    <xsl:apply-templates select="//sect1[title=$uri]" mode="number"/>     
                </xsl:variable>

                <xsl:choose>
                    <xsl:when test="$page!=''">
                        <a href="{$basename}.-page-{$page}-.{$extension}"><xsl:value-of select="$txt"/></a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="page2">
                            <xsl:apply-templates select="//sect1[sect2/title=$uri]" mode="number"/>     
                        </xsl:variable>
                        <xsl:variable name="sect2">
                            <xsl:apply-templates select="//sect2[title=$uri]" mode="number"/>     
                        </xsl:variable>

                        <xsl:choose>
                            <xsl:when test="$page2!=''">
                                <a href="{$basename}.-page-{$page2}-.{$extension}#sect_{$sect2}"><xsl:value-of select="$txt"/></a>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:choose>
                                <xsl:when test="$useuri">
                                    <a href="{$useuri}"><xsl:value-of select="$txt"/></a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$txt"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>



    <xsl:template match="xlink">                         
            <xsl:choose>
                <xsl:when test="@uri">
                    <xsl:call-template name="link">
                        <xsl:with-param name="uri" select="@uri"/>
                        <xsl:with-param name="useuri" select="@uri"/>
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

    <xsl:template match="para">                         
            <p class="body"><xsl:apply-templates/></p>
    </xsl:template>

    <!-- - - - - text - - - - -->

    <xsl:template match="emphasis">                         
        <i><xsl:value-of select="."/></i>
    </xsl:template>

    <xsl:template match="strong">                         
        <b><xsl:value-of select="."/></b>
    </xsl:template>

    <xsl:template match="code">                         
        <code><xsl:value-of select="."/></code>
    </xsl:template>

    <xsl:template match="underline">                         
        <u><xsl:value-of select="."/></u>
    </xsl:template>

    <xsl:template match="pic">                         
        <p class="cPic">
        <xsl:element name="img">
            <xsl:attribute name="src"><xsl:value-of select="."/></xsl:attribute>
        </xsl:element>
        </p>
    </xsl:template>

</xsl:stylesheet> 