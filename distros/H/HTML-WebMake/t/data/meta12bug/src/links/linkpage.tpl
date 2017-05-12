<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html>

  <head>
    <link href="$(dokv.css)" type="text/css" rel="stylesheet"/>
    <title>Dokumentenverarbeitung ($[this.stitle])</title>
  </head>

  <body>

    <!-- page header, current location -->
    <table class="header" width="100%" height="10%" border="0pt" cellspacing="0pt"
      cellpadding="7pt">
      <tr>
	<td class="header" width="5%">&nbsp;</td>
	<td class="header" align="left" width="30%">
	    <font size="+2"><b>Universit&auml;t Bielefeld</b></font>
	</td>
	<td class="header" align="center" width="30%">
	    <font size="+2"><b>Technische Fakult&auml;t</b></font>
	</td>
	<td class="header" align="right" width="30%">
	    <font size="+2"><b>Dokumentenverarbeitung</b></font>
	</td>
	<td class="header" width="5%">&nbsp;</td>
      </tr>
    </table>

    <hr>

    <!-- page body -->
    <table border="0pt" height="80%" cellspacing="0pt" cellpadding="20pt">
      <tr valign="top">

	<!-- Navigation -->
	<td class="navigation" width="15%">

	  ${navigation.tpl}

	</td>

	<!-- Inhalt -->
	<td width="85%">
	    
	    <table width="100%">
		<tr>
		  <td align="center">
		    <a href="$(links/literatur)">$[links/literatur.txt.stitle]</a>
		  </td>
		  <td align="center">
		    <a href="$(links/latex)">$[links/latex.txt.stitle]</a>
		  </td>
		  <td align="center">
		    <a href="$(links/sgml)">$[links/sgml.txt.stitle]</a>
		  </td>
		  <td align="center">
		    <a href="$(links/xml)">$[links/xml.txt.stitle]</a>
		  </td>
		  <td align="center">
		    <a href="$(links/postscript)">$[links/postscript.txt.stitle]</a>
		  </td>
		  <td align="center">
		    <a href="$(links/wacms)">$[links/wacms.txt.stitle]</a>
		  </td>
		</tr>
		<tr>
		  <td align="center">
		    <a href="$(links/typographie)">$[links/typographie.txt.stitle]</a>
		  </td>
		  <td align="center">
		    <a href="$(links/frame)">$[links/frame.txt.stitle]</a>
		  </td>
		  <td align="center">
		    <a href="$(links/dsssl)">$[links/dsssl.txt.stitle]</a>
		  </td>
		  <td align="center">
		    <a href="$(links/xsl)">$[links/xsl.txt.stitle]</a>/<a href="$(links/xslt)">$[links/xslt.txt.stitle]</a>
		  </td>
		  <td align="center">
		    <a href="$(links/pdf)">$[links/pdf.txt.stitle]</a>
		  </td>
		  <td align="center">
		    <a href="$(links/dav)">$[links/dav.txt.stitle]</a>
		  </td>
		</tr>
	    </table>

	  <h1 align="center">$[this.ltitle]</h1>

	    ${${WebMake.OutName}.txt}

	</td>
      </tr>
    </table>

    <!-- page footer -->

    <hr>

    <table height="5%" width="100%">
	<tr>
	  <td align="left"><address>
              <a href="/~joern/">$[this.author]</a>
	    </address></td>
	<td align="right"><address>
	    erstellt: $[this.cdate] / ge&auml;ndert: $[this.mdate]</address>
	</td>
      </tr>
    </table>

  </body>

</html>
