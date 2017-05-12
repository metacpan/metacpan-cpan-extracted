<?xml version="1.0" encoding="UTF-8"?>

<!-- $Id: designed.xsl,v 1.2 2007-02-09 17:13:25 mike Exp $ -->
<xsl:stylesheet
	xmlns='http://www.w3.org/1999/xhtml'
	xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
	version='1.0'>
 <xsl:output method='html'/>
 <xsl:template match='/'>
  <html xmlns='http://www.w3.org/1999/xhtml'>
   <head>
    <meta http-equiv='Cache-Control' content='no-cache'/>
    <meta http-equiv='Pragma' content='no-cache'/>
    <title>Keystone Resolver</title>
    <link rel='stylesheet' href='/styles.css' media='screen, all' type='text/css'/>
    <link rel='author' href='http://www.indexdata.dk'/>
    <xsl:if test="count(results/result) = 1 and
                  count(results/result[@type='id']) = 1">
     <xsl:element name='meta'>
      <xsl:attribute name='http-equiv'>refresh</xsl:attribute>
      <xsl:attribute name='content'>0;url=
       <xsl:value-of select="results/result[@type = 'id']"/>
      </xsl:attribute>
     </xsl:element>
    </xsl:if>
   </head>
   <body>
    <div class='top'>
     <img width='399' alt='Index Data' src='/logo.gif' height='77'/>
    </div>
    <div class='main'>
     <div>
      <span class='label'>Author</span>
      <div class='description'>
       <xsl:value-of select="results/result[@type = 'citation' and @tag = 'author']"/>
      </div>
      <span class='label'>Description</span>
      <div class='description'>
       <xsl:value-of select="results/data[@entity = 'rft']/metadata[@key='atitle']"/>
      </div>
      <span class='label'>Source</span>
      <div class='description'>
       <xsl:value-of select="results/data[@entity = 'rft']/metadata[@key='jtitle']"/>
      </div>
      <br/>
      <form id='data' method='post'>
       <!-- ### We need to explicitly list all parameters here -->
       <label>Year</label>
       <xsl:element name='input'>
        <xsl:attribute name='onchange'>document.getElementById('warning').style.display='block';</xsl:attribute>
        <xsl:attribute name='type'>text</xsl:attribute>
        <xsl:attribute name='name'>rft.date</xsl:attribute>
        <xsl:attribute name='value'>
         <xsl:value-of select="results/data[@entity = 'rft']/metadata[@key='date']"/>
        </xsl:attribute>
       </xsl:element>
       <label>Volume</label>
       <xsl:element name='input'>
        <xsl:attribute name='onchange'>document.getElementById('warning').style.display='block';</xsl:attribute>
        <xsl:attribute name='type'>text</xsl:attribute>
        <xsl:attribute name='name'>rft.volume</xsl:attribute>
        <xsl:attribute name='value'>
         <xsl:value-of select="results/data[@entity = 'rft']/metadata[@key='volume']"/>
        </xsl:attribute>
       </xsl:element>
       <label>Issue</label>
       <xsl:element name='input'>
        <xsl:attribute name='onchange'>document.getElementById('warning').style.display='block';</xsl:attribute>
        <xsl:attribute name='type'>text</xsl:attribute>
        <xsl:attribute name='name'>rft.issue</xsl:attribute>
        <xsl:attribute name='value'>
         <xsl:value-of select="results/data[@entity = 'rft']/metadata[@key='issue']"/>
        </xsl:attribute>
       </xsl:element>
       <label>Start Page</label>
       <xsl:element name='input'>
        <xsl:attribute name='onchange'>document.getElementById('warning').style.display='block';</xsl:attribute>
        <xsl:attribute name='type'>text</xsl:attribute>
        <xsl:attribute name='name'>rft.spage</xsl:attribute>
        <xsl:attribute name='value'>
         <xsl:value-of select="results/data[@entity = 'rft']/metadata[@key='spage']"/>
        </xsl:attribute>
       </xsl:element>
       <input value='Update' name='Update' type='submit' class='button'/>
      </form>
      <div id='warning'>
       After you have edited the data in the input fields, click on the Update button for the changes to take effect.
      </div>
      <hr/>

      <div class='linkblock'>
       <div class='links'>
	<!-- ### Yuck!  Nasty presentation! -->
        <b>The requested article is available via an identifier</b>
        <xsl:apply-templates select="results/result[@type='id']"/>
       </div>
      </div>

      <div class='linkblock'>
       <div class='links'>
        <b>Full Text:</b>
        <br/>
        <xsl:apply-templates select="results/result[@type='fulltext']"/>
       </div>
       <div class='links'>
        <b>Abstract:</b>
        <br/>
        <xsl:apply-templates select="results/result[@type='abstract']"/>
       </div>
      </div>

      <div class='linkblock'>
       <div class='links'>
        <b>Search on the web:</b>
        <br/>
        <xsl:apply-templates select="results/result[@type='websearch']"/>
       </div>
       <div class='links'>
        <b>Other Works by Same Author:</b>
        <br/>
        <xsl:apply-templates select="results/result[@type='authorsearch']"/>
       </div>
      </div>

      <div class='linkblock'>
       <div class='links'>
        <b>Buy from on-line bookstore:</b>
        <br/>
        <xsl:apply-templates select="results/result[@type='bookstore']"/>
       </div>
       <div class='links'>
        <b>Download citation:</b>
        <br/>
        <xsl:apply-templates select="results/result[@type='citeref']"/>
       </div>
      </div>

      <div class='linkblock'>
       <div class='links'>
        <b>Works That Cite This Article:</b>
        <br/>
        [not yet implemented]
       </div>
       <div class='links'>
        <b>Additional options:</b>
        <br/>
        <a href='index.html' class='link'>Ask a Librarian a Question</a>
        <a href='index.html' class='link'>Give Us Your Feedback</a>
	<br/>
       </div>
      </div>
     </div>

     <xsl:if test="results/result[@type='error']">
      <div class="errorlist">
       <xsl:apply-templates select="results/result[@type='error']"/>
      </div>
     </xsl:if>

     <div class='tag'>
      Powered by
      <a href='http://www.indexdata.dk' class='tag'>Keystone Resolver</a>
     </div>
    </div>
   </body>
  </html>
 </xsl:template>

 <xsl:template match='results/data'><!-- nothing --></xsl:template>

 <xsl:template match="results/result[@type='id']">
  <div class="link">
   <tt><xsl:value-of select="@tag"/></tt>
   at
   <xsl:element name='a'>
    <xsl:attribute name='href'>
     <xsl:value-of select='.'/>
    </xsl:attribute>
    <xsl:value-of select='.'/>
   </xsl:element>
  </div>
 </xsl:template>

 <xsl:template match="results/result[@type='fulltext' or
				     @type='abstract' or
				     @type='websearch' or
				     @type='authorsearch' or
				     @type='bookstore' or
				     @type='citeref']">
  <xsl:element name='a'>
   <xsl:attribute name='class'>link</xsl:attribute>
   <xsl:attribute name='href'>
    <xsl:value-of select='.'/>
   </xsl:attribute>
   <xsl:value-of select='@service'/>
  </xsl:element>
 </xsl:template>

 <xsl:template match="results/result[@type='error']">
  <div class="error">
   Warning:
   <xsl:value-of select='.'/>
  </div>
 </xsl:template>

</xsl:stylesheet>
