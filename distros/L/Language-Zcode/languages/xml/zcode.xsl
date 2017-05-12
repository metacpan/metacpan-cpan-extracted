<?xml version="1.0" encoding="ISO-8859-1"?>
<!-- IE 5 -->
<xsl:stylesheet
xmlns:xsl="http://www.w3.org/TR/WD-xsl">
<!-- IE 6.0
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
-->

<!--
<xsl:template match="/">
<html>
<body>
<h2>Plotz XML</h2> 
<xsl:apply-templates/> 
</body>
</html>
</xsl:template>
-->

<xsl:template match="/">
    <html><body>
    <h1>Plotz Translation of Z-file</h1>

    <h2>Constants</h2>
    <table border="1">
    <tr bgcolor="#9acd32">
      <th align="left">Name</th>
      <th align="left">value</th>
    </tr>
    <xsl:for-each select="zfile/constants/anon">
    <!--xsl:sort select="constant_key"/-->
    <tr>
      <td><xsl:value-of select="constant_key"/></td>
      <td><xsl:value-of select="value"/></td>
    </tr>
    </xsl:for-each>
    </table>

    <h2>Subroutines</h2>
    <xsl:for-each select="zfile/subroutine">
	<h3><xsl:value-of select="name"/></h3>
	<strong>Locals: </strong>
	<xsl:for-each select="locv">
	    <xsl:value-of select="."/>
	</xsl:for-each>

	<xsl:for-each select="command">
	    <ul>
	    <strong><xsl:value-of select="opcode_address"/></strong>

	    <xsl:choose> <!-- Big choose over opcode name -->

	    <xsl:when test="opcode[.='print' or .='print_ret']">
		<xsl:value-of select="opcode"/>
	        &quot;<xsl:value-of select="print_string"/>&quot;
	    </xsl:when>
	    <xsl:when test="opcode[.='print_obj']">
		print_obj Obj<xsl:value-of select="object"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='print_num']">
		print_num <xsl:value-of select="value"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='print_char']">
		<!-- Print actual character instead? In parens? -->
		print_char <xsl:value-of select="output_character_code"/>
	    </xsl:when>

	    <xsl:when test="opcode[.='add']">
	        <xsl:value-of select="result"/> =
	        <xsl:value-of select="a"/> + <xsl:value-of select="b"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='sub']">
	        <xsl:value-of select="result"/> =
	        <xsl:value-of select="a"/> - <xsl:value-of select="b"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='mul']">
	        <xsl:value-of select="result"/> =
	        <xsl:value-of select="a"/> * <xsl:value-of select="b"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='div']">
	        <xsl:value-of select="result"/> =
	        <xsl:value-of select="a"/> / <xsl:value-of select="b"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='mod']">
	        <xsl:value-of select="result"/> =
	        <xsl:value-of select="a"/> % <xsl:value-of select="b"/>
	    </xsl:when>

	    <xsl:when test="opcode[.='not']">
	        <xsl:value-of select="result"/> = ! <xsl:value-of select="a"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='or']">
	        <xsl:value-of select="result"/> =
	        <xsl:value-of select="a"/> || <xsl:value-of select="b"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='and']">
	        <xsl:value-of select="result"/> =
	        <xsl:value-of select="a"/> &amp;&amp; <xsl:value-of select="b"/>
	    </xsl:when>

	    <xsl:when test="opcode[.='pull']">
	        <xsl:value-of select="variable"/> = pull
	    </xsl:when>
	    <xsl:when test="opcode[.='push']">
	        push <xsl:value-of select="value"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='inc']">
	        <xsl:value-of select="variable"/>++
	    </xsl:when>
	    <xsl:when test="opcode[.='dec']">
	        <xsl:value-of select="variable"/>--
	    </xsl:when>
	    <xsl:when test="opcode[.='load']">
	        <xsl:value-of select="result"/> = <xsl:value-of select="variable"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='store']">
	        <xsl:value-of select="variable"/> = <xsl:value-of select="value"/>
	    </xsl:when>

	    <xsl:when test="opcode[.='loadw']">
	        <xsl:value-of select="result"/> =
	        <xsl:value-of select="array"/> -> <xsl:value-of select="word_index"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='loadb']">
	        <xsl:value-of select="result"/> =
	        <xsl:value-of select="array"/> -> <xsl:value-of select="byte_index"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='storew']">
	        <xsl:value-of select="array"/> -> <xsl:value-of select="word_index"/>
	        = <xsl:value-of select="value"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='storeb']">
	        <xsl:value-of select="array"/> -> <xsl:value-of select="byte_index"/>
	        = <xsl:value-of select="value"/>
	    </xsl:when>

	    <xsl:when test="opcode[.='jump']">
	        jump <xsl:value-of select="label"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='jz']">
		<xsl:choose>
		    <xsl:when test="negate_jump[.=1]">unless </xsl:when>
		    <xsl:otherwise>if </xsl:otherwise>
		</xsl:choose>
	        <xsl:value-of select="a"/> == 0 goto
	        <xsl:value-of select="label"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='jl']">
		<xsl:choose>
		    <xsl:when test="negate_jump[.=1]">unless </xsl:when>
		    <xsl:otherwise>if </xsl:otherwise>
		</xsl:choose>
	        <xsl:value-of select="a"/> &lt; <xsl:value-of select="b"/> goto
	        <xsl:value-of select="label"/>
	    </xsl:when>
	    <xsl:when test="opcode[.='jg']">
		<xsl:choose>
		    <xsl:when test="negate_jump[.=1]">unless </xsl:when>
		    <xsl:otherwise>if </xsl:otherwise>
		</xsl:choose>
	        <xsl:value-of select="a"/> &gt; <xsl:value-of select="b"/> goto
	        <xsl:value-of select="label"/>
	    </xsl:when>

	    <!--xsl:when test="substring(opcode, 1, 4) = 'call']"-->
	    <xsl:when test="opcode[.='call_1n' or .='call_2n' or .='call_vn' or .='call_vn2' or .='call']">
	        rtn<xsl:value-of select="routine"/>(<xsl:value-of select="args"/>)
	    </xsl:when>
	    <xsl:when test="opcode[.='call_1s' or .='call_2s' or .='call_vs' or .='call_vs2']">
	        <xsl:value-of select="result"/> = 
		    rtn<xsl:value-of select="routine"/>(<xsl:value-of select="args"/>)
	    </xsl:when>
	    <xsl:when test="opcode[.='ret']">
	        ret <xsl:value-of select="value"/>
	    </xsl:when>

	    <xsl:otherwise> <!-- Just print the opcode name -->
		<xsl:value-of select="opcode"/>
	    </xsl:otherwise>
	    </xsl:choose>
	    </ul>
	</xsl:for-each>
    </xsl:for-each>

    </body></html>
</xsl:template>

</xsl:stylesheet>
