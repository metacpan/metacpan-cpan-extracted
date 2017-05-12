<?xml version='1.0'?>

<!--
<!DOCTYPE xxx [
<!ENTITY % nbsp "&lt;![CDATA[&nbsp;]]&gt;" >
]>
-->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:pod="http://axkit.org/ns/2000/pod2xml"
                xmlns="http://www.w3.org/TR/xhtml1/strict">


<xsl:output
   method="html"
   indent="no"
   encoding="iso-8859-1"
/>

<xsl:variable name="imagepath">/eg/images</xsl:variable>
<xsl:variable name="newswidth">152</xsl:variable>
<xsl:param name="numnews">10</xsl:param>

    <xsl:template match="/">                         
        <html>
            <head>
                <title><xsl:value-of select="pod/head/title"/></title>
            </head>
            <body>
                    <xsl:apply-templates select="/pod/sect1"/> 
            
            <xsl:if test="$numnews &lt; 9999">
                <a href="news/NEWS.xml?numnews=9999">more...</a>
            </xsl:if>
            </body>
        </html>
    </xsl:template>


    <xsl:template match="sect1">                         
        <table width="{$newswidth}" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td><img src="{$imagepath}/h_news.gif" width="{$newswidth}" height="19"/></td>
          </tr>
          <tr>
            <td><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></td>
          </tr>
          <tr>
            <td>
               <xsl:apply-templates select="item[position() &lt; $numnews]"/> 
            </td>
          </tr>
        </table>
    </xsl:template>



    <xsl:template match="item">                         
              <table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr> 
                  <td bgcolor="#327EA7"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><b>
                    <font color="#FFFFFF"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
                        <xsl:value-of select="itemtext"/>    
                    </font></b></font></td>
                </tr>
                <tr> 
                  <td bgcolor="#C2D9E5"><img src="{$imagepath}/linie-news.gif" width="{$newswidth}" height="4"/></td>
                </tr>
                <tr> 
                  <td bgcolor="#D2E9F5">
                    <table width="100%" border="0" cellspacing="0" cellpadding="3">
                      <tr>
                        <td><font size="1" face="Verdana, Arial, Helvetica, sans-serif">
                            <xsl:apply-templates/>
                        </font></td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
    </xsl:template>

    <xsl:template match="para">                         
            <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="xlink">                         
            <xsl:element name="a">
                <xsl:attribute name="href">
                    <xsl:value-of select="@uri"/>
                </xsl:attribute>
                <xsl:value-of select="."/>
            </xsl:element>
    </xsl:template>

</xsl:stylesheet> 