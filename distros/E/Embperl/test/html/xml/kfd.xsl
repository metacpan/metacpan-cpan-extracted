<?xml version='1.0'?>
<xsl:stylesheet  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:template match="Operation">
<xsl:for-each select="Funds/Fund">

<table border="0" cellpadding="0" cellspacing="0" width="100%">
<tr>
	<td class="bar01"><img src="[ImageDir]/1pixel.gif/$FILE/1pixel.gif" width="9" height="1" /></td>
</tr>
<tr>
	<td class="bar01" height="26">
		<img src="[ImageDir]/1pixel.gif/$FILE/1pixel.gif" width="8" height="1" />
		<font class="lighttextbold">
			<xsl:value-of select="FundName" />
		</font>
	</td>
</tr>
<tr>
	<td class="bar01"><img src="[ImageDir]/1pixel.gif/$FILE/1pixel.gif" width="9" height="1" /></td>
</tr>
<tr height="10">
</tr>

<tr height="25">

	<td class="blank"><font class="textblueboldsmaller">Manager / Authorised Corporate Director:
</font><br /><font class="text"> 
<xsl:value-of select="MgrACDName" /><br />
<xsl:if test="FundManager/Address1!=''">
<xsl:value-of select="FundManager/Address1" /><br />
</xsl:if>
<xsl:if test="FundManager/Address2!=''">
<xsl:value-of select="FundManager/Address2" /><br />
</xsl:if>
<xsl:if test="FundManager/Address3!=''">
<xsl:value-of select="FundManager/Address3" /><br />
</xsl:if>
<xsl:if test="FundManager/Address4!=''">
<xsl:value-of select="FundManager/Address4" /><br />
</xsl:if>
<xsl:if test="FundManager/Postcode!=''">
<xsl:value-of select="FundManager/Postcode" /><br />
</xsl:if>
<xsl:if test="FundManager/Country!=''">
<xsl:value-of select="FundManager/Country" /><br />
</xsl:if>
</font>
<br />

</td>
</tr>

<tr height="25">
	<td class="blank"><font class="textblueboldsmaller">Name of Trustee/Depositary:</font><br /><font class="text"><xsl:value-of select="TrusteeName" /><br /><br /></font></td>
</tr>

<tr height="25">
	<td class="blank"><font class="textblueboldsmaller">Fund Investment Objective:</font><br /><font class="text"><xsl:value-of select="Objectives" /><br /><br /></font></td>
</tr>

<tr height="25">
	<td class="blank"><font class="textblueboldsmaller">Initial Charge:</font><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text><font class="text"> <xsl:value-of select="format-number(InitialCharge,'###,##0.00')" />%</font></td>
</tr>

<tr height="25">
	<td class="blank"><font class="textblueboldsmaller">Annual Charge:</font><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text><font class="text"> <xsl:value-of select="format-number(AnnualCharge,'###,##0.00')" />%</font></td>
</tr>

<tr height="25">
	<td class="blank"><font class="textblueboldsmaller">Other Charges:</font><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text><font class="text"> <xsl:value-of select="format-number(OtherCharges,'###,##0.00')" />%</font></td>
</tr>
<xsl:if test="SpecialRiskFactors!=''">
<tr height="25">
	<td class="blank"><font class="textblueboldsmaller">Special Risk Factors:</font><br /><font class="text"> <xsl:value-of select="SpecialRiskFactors" /><br /><br /></font></td>
</tr>
</xsl:if>

<xsl:if test="ImportantChangesPending!=''">
<tr height="25">
	<td class="blank"><font class="textblueboldsmaller">Fund Manager's comments on important changes pending:</font><br /><font class="text"> <xsl:value-of select="ImportantChangesPending" /><br /><br /></font></td>
</tr>
</xsl:if>
<!--
<tr height="20" valign="bottom">
	<td class="blank"><font class="textbold">Shares purchased within an ISA : </font></td>
</tr>
-->
</table>
<br/>


<table border="0" cellpadding="0" cellspacing="0" width="100%"><tr><td class="tablebar"><img src="[ImageDir]/1pixel.gif/$FILE/1pixel.gif" width="9" height="1" /><font class="lighttextbold">Units or shares purchased within an ISA :</font>
<table width="100%" cellpadding="2" cellspacing="1" border="0">
<tr>
	<td class="tablebar" colspan="9"><img src="[ImageDir]/1pixel.gif/$FILE/1pixel.gif" width="1" height="7" /></td>
</tr>
<tr align="center">
	<td class="blank"><font class="textbold">At end of year</font></td>
	<td class="blank"><font class="textbold">Investment to date</font></td>
	<td class="blank"><font class="textbold">Income to date</font></td>
	<td class="blank"><font class="textbold">Effect of deductions to date</font></td>
	<td class="blank"><font class="textbold">What you might get back at 7%</font></td>
</tr>
<tr align="center">

	<td class="blank"><font class="text">1</font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text>1,000.00</font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(IncomeToDateyr1,'###,##0.00')" /></font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(DeductionsToDateyr1,'###,##0.00')" /></font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(GetBackyr1,'###,##0.00')" /></font></td>
</tr>


<tr align="center">

	<td class="blank"><font class="text">3</font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text>1,000.00</font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(IncomeToDateyr3,'###,##0.00')" /></font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(DeductionsToDateyr3,'###,##0.00')" /></font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(GetBackyr3,'###,##0.00')" /></font></td>
</tr>


<tr align="center">

	<td class="blank"><font class="text">5</font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text>1,000.00</font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(IncomeToDateyr5,'###,##0.00')" /></font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(DeductionsToDateyr5,'###,##0.00')" /></font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(GetBackyr5,'###,##0.00')" /></font></td>
</tr>


<tr align="center">

	<td class="blank"><font class="text">10</font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text>1,000.00</font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(IncomeToDateyr10,'###,##0.00')" /></font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(DeductionsToDateyr10,'###,##0.00')" /></font></td>
	<td class="blank" align="right"><font class="text"><xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(GetBackyr10,'###,##0.00')" /></font></td>
</tr>

</table>
</td></tr>


<tr>

	<td class="blank"><font class="text"><br />The last line in the table shows that over ten years the effect of the total charges and expenses could amount to <xsl:text disable-output-escaping="yes">&amp;pound;</xsl:text><xsl:value-of select="format-number(DeductionsToDateyr10,'###,##0.00')" />.  Putting it another way, this would have the same effect as bringing the illustrated investment growth from 7% a year down to <xsl:value-of select="format-number(ReductionInYield,'###,##0.00')" />%.</font></td>
</tr>


</table>
<br/>
</xsl:for-each>
</xsl:template>

<xsl:template match="Status"></xsl:template>

</xsl:stylesheet>

