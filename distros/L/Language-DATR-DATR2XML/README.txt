README File For Convert::DATR2XML.pm
====================================

	* INSTALLATON
	* MANIFEST
	* COPYING
	* MORE INFO
	* AUTHOR

The DATR2XML package is a colleciton of files
to provide XML support for Sussex-standard DATR.

Verison 0.81 was created by h2xs 1.20 with options
		-cfn Language::DATR::DATR2XML
and is now strict, at the expense of some limited
functionality for which I've forgotten the point.

INSTALLATION
------------
Could make a makefile, I guess, but you're better off
just sticking the PM into $perl/site/lib/convert/,
and the other files where you fancy.

MANIFEST
--------
You should recieve the following files in the package:

	*	DATR2XML.pm
		The Perl module to convert a basic set of
		Sussex-standard DATR to XML compliant with
		the DATR1.0.dtd

	*	DATR1.0.dtd
		UTF-8-encoded XML Document Type Definition
		for Sussex-standard DATR.

	*	datr.xml
		An XML Schema created on 1 July 2000,
		I think by dtd2xsd.pl, which was downloaded from
		<http://www.w3.org/2000/04/schema_hack/dtd2xsd.pl>.
		No promises on this baby.

	*	datr.xsl
		An XSLT stylesheet to convert DATR XML back to
		it's DATR source format.

	*	datrHTML.xsl
		As datr.xsl, but produces an HTML version.

	*	datrPROLOG.xsl
		An experimental XSLT stylesheet intended to render
		DATR structures in PROLOG.  Hm.

	*	test.pl
		A bunch of commands commented out, and a call
		to the Benchmark routines.

	*	COPYING
		Yes you can, but please read this first for terms.

	*	thanks.txt
		Thanks to the people named in this file for the
		contributions copied to this file.

	*	README.txt
		You know about this one already.


COPYING
-------
Please see the included file, COPYING.

MORE INFO
---------
For more info, extract the POD from the PM:
	perldoc DATR2XML.pm
or
	pod2html --title DATR2XML DATR2XML.pm

None of this wouldn't have happend without the
help of Prof Dr Gerald Gazdar of the
Research Centre for Cognitive Science at the
University of Sussex: <http://www.cogs.sussex.ac.uk>.

AUTHOR
------
Lee Goddard             mailto:mail@leegoddard.com
Sussex/London, UK       http://www.leegoddard.com/DATR
02 November 2000 - 20 April 2001
