package MARC::Lint::CodeData;

use strict;
use warnings; 

#declare the necessary variables
use vars qw($VERSION @EXPORT_OK %GeogAreaCodes %ObsoleteGeogAreaCodes %LanguageCodes %ObsoleteLanguageCodes %CountryCodes %ObsoleteCountryCodes %Sources600_651 %ObsoleteSources600_651 %Sources655 %ObsoleteSources655);

$VERSION = '1.38';

use base qw(Exporter AutoLoader);

@EXPORT_OK = qw(%GeogAreaCodes %ObsoleteGeogAreaCodes %LanguageCodes %ObsoleteLanguageCodes %CountryCodes %ObsoleteCountryCodes %Sources600_651 %ObsoleteSources600_651 %Sources655 %ObsoleteSources655);

=head1 NAME

MARC::Lint::CodeData -- Contains codes from the MARC code lists for Geographic Areas, Languages, and Countries.

=head1 DESCRIPTION

Code data is used for validating fields 008, 040, 041, and 043.

Also, sources for subfield 2 in 600-651 and 655.

Stores codes in hashes, %MARC::Lint::CodeData::[name].

Note: According to the official MARC documentation, Sears is not a valid 655
term. The code data below treats it as valid, in anticipation of a change in
the official documentation.

=head1 SYNOPSIS

use MARC::Lint::CodeData;

#Should provide access to the following:
#%MARC::Lint::CodeData::GeogAreaCodes;
#%MARC::Lint::CodeData::ObsoleteGeogAreaCodes;
#%MARC::Lint::CodeData::LanguageCodes;
#%MARC::Lint::CodeData::ObsoleteLanguageCodes;
#%MARC::Lint::CodeData::CountryCodes;
#%MARC::Lint::CodeData::ObsoleteCountryCodes;
#%MARC::Lint::CodeData::Sources600_651;
#%MARC::Lint::CodeData::ObsoleteSources600_651;
#%MARC::Lint::CodeData::Sources655;
#%MARC::Lint::CodeData::ObsoleteSources655;


#or, import specific code list data
use MARC::Lint::CodeData qw(%GeogAreaCodes);

my $gac = "n-us---";
my $validgac = 1 if ($GeogAreaCodes{$gac});
print "Geographic Area Code $gac is valid\n" if $validgac;


=head1 EXPORT

None by default. 
@EXPORT_OK: %GeogAreaCodes, %ObsoleteGeogAreaCodes, %LanguageCodes, %ObsoleteLanguageCodes, %CountryCodes, %ObsoleteCountryCodes, %Sources600_651, %ObsoleteSources600_651, %Sources655, %ObsoleteSources655.

=head1 TO DO

Update codes as needed (see L<http://www.loc.gov/marc/>).

Add other codes for MARC Code Lists for Relators, Sources, Description Conventions.

Determine what to do about 600-655 codes with indicators (cash, lcsh, lcshac,
mesh, nal, and rvm). Currently, these are duplicated in valid and obsolete
hashes. Validation routines should probably treat these differently due to large
numbers of records using these codes, created before the indicators were
allowed.

Determine whether three blank spaces should be in the LanguageCodes (for 008 validation) or not. 
If it is here, then 041 would be allowed to have three blank spaces as a valid code 
(though other checks would report the error--spaces at the beginning and ending of a subfield
and multiple spaces in a field where such a thing is not allowed).

Update Subject source codes with codes from additional Source lists (see L<https://www.loc.gov/standards/sourcelist/subject.html>):
    Genre/Form Term and Code Source Codes
    Occupation Term Source Codes
    Function Term Source Codes
    Temporal Term Source Codes
    Name and Title Source Codes 
    Classification Scheme Source Codes
    Subject Category Code Source Codes
	
=head2 SEE ALSO

L<MARC::Lint>

L<MARC::Lintadditions> (for check_040, check_041, check_043 using these codes)

L<MARC::Errorchecks> (for 008 validation using these codes)

L<http://www.loc.gov/marc/> for the official code lists.

The following (should be included in the distribution package for this package):
countrycodelistclean.pl
gaccleanupscript.pl
languagecodelistclean.pl
The scripts above take the MARC code list ASCII version as input.
They output tab-separated codes for updating the data below.

=head1 VERSION HISTORY

Version 1.38: Updated September 5, 2020.
 -Added new sources codes from Technical Notice of September 15, 2017
 -Added new sources codes from Technical Notice of October 20, 2017
 -Added new sources codes from Technical Notice of December 01, 2017
 -Added new sources codes from Technical Notice of January 26, 2018
 -Added new sources codes from Technical Notice of March 09, 2018
 -Added new sources codes from Technical Notice of May 25, 2018
 -Added new sources codes from Technical Notice of July 27, 2018
 -Added new sources codes from Technical Notice of August 31, 2018
 -Added new sources codes from Technical Notice of October 12, 2018
 -Added new sources codes from Technical Notice of October 26, 2018
 -Added new sources codes from Technical Notice of March 27, 2019
 -Added new sources codes from Technical Notice of April 19, 2019
 -Added new sources codes from Technical Notice of May 31, 2019
 -Added new sources codes from Technical Notice of August 09, 2019
 -Added new sources codes from Technical Notice of September 13, 2019
 -Added new sources codes from Technical Notice of October 04, 2019
 -Added new sources codes from Technical Notice of October 11, 2019
 -Added new sources codes from Technical Notice of November 1, 2019
 -Added new sources codes from Technical Notice of November 26, 2019
 -Added new sources codes from Technical Notice of December 12, 2019
 -Added new sources codes from Technical Notice of February 21, 2020
 -Added new sources codes from Technical Notice of March 13, 2020
 -Added new sources codes from Technical Notice of May 1, 2020
 -Added new sources codes from Technical Notice of June 26, 2020
 -Added new sources codes from Technical Notice of July 28, 2020

Version 1.37: Updated August 2, 2017.

 -Added new sources codes from Technical Notice of February 19, 2016
 -Added new sources codes from Technical Notice of February 26, 2016
 -Added new sources codes from Technical Notice of April 8, 2016
 -Added new sources codes from Technical Notice of July 29, 2016
 -Added new sources codes from Technical Notice of September 16, 2016
 -Added new sources codes from Technical Notice of November 2, 2016
 -Added new sources codes from Technical Notice of December 2, 2016
 -Added new sources codes from Technical Notice of February 17, 2017
 -Added new sources codes from Technical Notice of February 28, 2017
 -Added new sources codes from Technical Notice of March 10, 2017
 -Added new sources codes from Technical Notice of March 24, 2017
 -Added new sources codes from Technical Notice of May 19, 2017
 -Added new sources codes from Technical Notice of June 21, 2017
 -Added new sources codes from Technical Notice of July 13, 2017


Version 1.36: Updated January 17, 2016.

 -Added new sources codes from Technical Notice of November 12, 2015
 -Added bidex to %Sources655

Version 1.35: Updated July 1, 2015.

 -Added new sources codes from Technical Notice of July 3, 2014
 -Added new sources codes from Technical Notice of July 18, 2014
 -Added new sources codes from Technical Notice of September 18, 2014
 -Added new sources codes from Technical Notice of October 22, 2014
 -Added new sources codes from Technical Notice of November 14, 2014
 -Added new sources codes from Technical Notice of January 23, 2015
 -Added new sources codes from Technical Notice of March 13, 2015
 -Added new sources codes from Technical Notice of June 23, 2015

Version 1.34: Updated June 8, 2014.

 -Added new sources600_651 codes from http://www.loc.gov/standards/sourcelist/subject.html, viewed June 9, 2014.
 -Removed sources600-650 source codes based on http://www.loc.gov/standards/sourcelist/subject.html, viewed June 9, 2014.
 -Added new sources655 codes from http://www.loc.gov/standards/sourcelist/genre-form.html, viewed June 9, 2014.
 -Added new sources codes from Technical Notice of Sept. 26, 2013
 -Added new sources codes from Technical Notice of Nov. 13, 2013
 -Added new sources codes from Technical Notice of Mar. 14, 2014
 -Added new sources codes from Technical Notice of June 6, 2014

Not yet deleted from sources600_651 pending confirmation:
dacs
iaat
ilot
itoamc
lcmpt
ndllsh
onet
raam
tbit
toit

Version 1.33: Updated Sept. 1, 2013.

 -Added new country and GAC codes from Technical Notice of Feb. 22, 2013
 -Added new country and GAC codes from Technical Notice of Mar. 22, 2013
 -Added new country and GAC codes from Technical Notice of Apr. 25, 2013 (with correction of May 15, 2013)
 -Added new country and GAC codes from Technical Notice of May 29, 2013
 -Added new country and GAC codes from Technical Notice of June 26, 2013
 -Added new country and GAC codes from Technical Notice of July 26, 2013
 
 
Version 1.32: Updated Sept. 2, 2012.

 -Separated "NAME and DESCRIPTION" pod section into "NAME" and "DESCRIPTION"
 -Sorted tab-separated lists for country codes and GAC alphabetically
 -Added new country and GAC codes from Technical Notice of Aug. 15, 2011
 -Added new country and GAC codes from Technical Notice of Dec. 6, 2011
 -Added new sources codes from Technical Notice of Dec. 14, 2011
 -Added new sources codes from Technical Notice of Dec. 23, 2011
 -Added new sources codes from Technical Notice of Jan. 26, 2012
 -Added new sources codes from Technical Notice of Mar. 28, 2012
 -Added new sources codes from Technical Notice of Apr. 27, 2012
 -Added new sources codes from Technical Notice of July 11, 2012
 -Added new sources codes from Technical Notice of Aug. 29, 2012


Version 1.31: Updated Aug. 15, 2011.

 -Added new sources codes from Technical Notice of Apr. 28, 2010.
 -Added new sources codes from Technical Notice of May 26, 2010.
 -Added new sources codes from Technical Notice of June 18, 2010.
 -Added new sources codes from Technical Notice of Jan. 5, 2011.
 -Added new sources codes from Technical Notice of Apr. 13, 2011.
 -Added new sources codes from Technical Notice of Apr. 22, 2011.
 -Added new sources codes from Technical Notice of May 20, 2011.
 -Added new sources codes from Technical Notice of June 14, 2011.
 -Added new sources codes from Technical Notice of July 15, 2011.

Version 1.30: Updated Jan. 27, 2010.

 -Added new sources codes from Technical Notice of Jan. 26, 2010.

Version 1.29: Updated Nov. 18, 2009.

 -Added new sources codes from Technical Notice of Sept. 30, 2009.
 -Added new sources codes from Technical Notice of Oct. 26, 2009.

Version 1.28: Updated May 2, 2009.

 -Added new sources codes from Technical Notice of Oct. 10, 2008.
 -Added new sources codes from Technical Notice of Dec. 16, 2008.
 -Added new language codes from Technical Notice of Jan. 6, 2009 (mol moved to ObsoleteLanguageCodes).
 -Added new sources codes from Technical Notice of Jan. 23, 2009.
 -Added new sources codes from Technical Notice of Feb. 19, 2009.
 -Added new sources codes from Technical Notice of Apr. 22, 2009.


Version 1.27: Updated Aug. 14, 2008.

 -Added new sources codes from Technical Notice of July 25, 2008.

Version 1.26: Updated July 6, 2008.

 -Added new language codes from Technical Notice of July 1, 2008.
 -Moved obsolete language codes 'scc' and 'scr' to the obsolete language hash.

Version 1.25: Updated Apr. 28, 2008.

 -Added new sources codes from Technical Notice of Apr. 25, 2008.

Version 1.24: Updated Mar. 30, 2008.

 -Added new sources codes from Technical Notice of Mar. 28, 2008.

Version 1.23: Updated Mar. 26, 2008.

 -Added new country and GAC codes from Technical Notice of Mar. 25, 2008.

Version 1.22: Updated Jan. 21, 2008.

 -Added new sources codes from Technical Notice of Jan. 18, 2008.

Version 1.21: Updated Nov. 30, 2007.

 -Added new sources codes from Technical Notice of Nov. 30, 2007.

Version 1.20: Updated Nov. 19, 2007.

 -Added new language codes from Technical Notice of Nov. 16, 2007.

Version 1.19: Updated Oct. 22, 2007.

 -Added new language codes from Technical Notice of Oct. 22, 2007.

Version 1.18: Updated Aug. 14, 2007.

 -Added new source codes from Technical Notice of Aug. 13, 2007.

Version 1.17: Updated July 16, 2007.

 -Added new source codes from Technical Notice of July 13, 2007.

Version 1.16: Updated Apr. 18, 2007.

 -Added new source codes from Technical Notice of Apr. 5, 2007.

Version 1.15: Updated Feb. 28, 2007.

 -Added new country and geographic codes from Technical Notice of Feb. 28, 2007.
 -Added 'yu ' to list of obsolete codes.

Version 1.14: Updated Jan. 8, 2007.

 -Added new source codes from Technical Notice of Jan. 5, 2007.

Version 1.13: Updated Nov. 19, 2006.

 -Added new source codes from Technical Notice of Nov. 14, 2006.

Version 1.12: Updated Oct. 20, 2006.

 -Added new source code from Technical Notice of Oct. 19, 2006.

Version 1.11: Updated Oct. 18, 2006.

 -Added new source codes from Technical Notice of Oct. 17, 2006.

Version 1.10: Updated Aug. 30, 2006.

 -Added new source codes from Technical Notice of Aug. 29, 2006.

Version 1.09: Updated June 26, 2006.

 -Added new source codes from Technical Notice of June 23, 2006.

Version 1.08: Updated May 30, 2006.

 -Added new source codes from Technical Notice of May 26, 2006.

Version 1.07: Updated Mar. 13, 2006.

 -Added new source codes from Technical Notice of Mar. 10, 2006.

Version 1.06: Updated Feb. 23, 2006.

 -Added new language codes from Technical Notice of Feb 23, 2006.
 -Alphabetized language codes.

Version 1.05: Updated Jan. 11, 2006.

 -Added new sources codes from Technical Notice of Jan. 10, 2006.

Version 1.04: Updated Oct. 13, 2005.

 -Added new sources codes from Technical Notice of Oct. 12, 2005.

Version 1.03: Updated Aug. 31, 2005.

 -Added new language codes for Ainu and Southern Altai (August 30, 2005 technical notice)

Version 1.02: Updated June 21-July 12, 2005. Released (to CPAN) with new version of MARC::Errorchecks.

 -Added GAC and Country code changes for Australia (July 12, 2005 update)
 -Added 6xx subfield 2 source code data for June 17, 2005 update.
 -Updated valid Language codes to June 2, 2005 changes.

Version 1.01: Updated Jan. 5-Feb. 10, 2005. Released (to CPAN) Feb. 13, 2005 (with new version of MARC::Errorchecks).

 -Added code list data for 600-651 subfield 2 and for 655 subfield 2 sources.
 -Updated codes based on changes made Jan. 19 (languages), Feb. 2 (sources), Feb. 9 (sources). 
 
Version 1.00 (original version): First release, Dec. 5, 2004. Uploaded to SourceForge CVS, Jan. 3, 2005.
 -Included in MARC::Errorchecks distribution on CPAN.
 -Used by MARC::Lintadditions.

=cut

#fill the valid Geographic Area Codes hash

%GeogAreaCodes = map {($_, 1)} (split "\t", ("a------	a-af---	a-ai---	a-aj---	a-ba---	a-bg---	a-bn---	a-br---	a-bt---	a-bx---	a-cb---	a-cc---	a-cc-an	a-cc-ch	a-cc-cq	a-cc-fu	a-cc-ha	a-cc-he	a-cc-hh	a-cc-hk	a-cc-ho	a-cc-hp	a-cc-hu	a-cc-im	a-cc-ka	a-cc-kc	a-cc-ki	a-cc-kn	a-cc-kr	a-cc-ku	a-cc-kw	a-cc-lp	a-cc-mh	a-cc-nn	a-cc-pe	a-cc-sh	a-cc-sm	a-cc-sp	a-cc-ss	a-cc-su	a-cc-sz	a-cc-ti	a-cc-tn	a-cc-ts	a-cc-yu	a-ccg--	a-cck--	a-ccp--	a-ccs--	a-ccy--	a-ce---	a-ch---	a-cy---	a-em---	a-gs---	a-ii---	a-io---	a-iq---	a-ir---	a-is---	a-ja---	a-jo---	a-kg---	a-kn---	a-ko---	a-kr---	a-ku---	a-kz---	a-le---	a-ls---	a-mk---	a-mp---	a-my---	a-np---	a-nw---	a-ph---	a-pk---	a-pp---	a-qa---	a-si---	a-su---	a-sy---	a-ta---	a-th---	a-tk---	a-ts---	a-tu---	a-uz---	a-vt---	a-ye---	aa-----	ab-----	ac-----	ae-----	af-----	ag-----	ah-----	ai-----	ak-----	am-----	an-----	ao-----	aopf---	aoxp---	ap-----	ar-----	as-----	at-----	au-----	aw-----	awba---	awgz---	ay-----	az-----	b------	c------	cc-----	cl-----	d------	dd-----	e------	e-aa---	e-an---	e-au---	e-be---	e-bn---	e-bu---	e-bw---	e-ci---	e-cs---	e-dk---	e-er---	e-fi---	e-fr---	e-ge---	e-gi---	e-gr---	e-gw---	e-gx---	e-hu---	e-ic---	e-ie---	e-it---	e-kv---	e-lh---	e-li---	e-lu---	e-lv---	e-mc---	e-mm---	e-mo---	e-mv---	e-ne---	e-no---	e-pl---	e-po---	e-rb---	e-rm---	e-ru---	e-sm---	e-sp---	e-sw---	e-sz---	e-uk---	e-uk-en	e-uk-ni	e-uk-st	e-uk-ui	e-uk-wl	e-un---	e-ur---	e-urc--	e-ure--	e-urf--	e-urk--	e-urn--	e-urp--	e-urr--	e-urs--	e-uru--	e-urw--	e-vc---	e-xn---	e-xo---	e-xr---	e-xv---	e-yu---	ea-----	eb-----	ec-----	ed-----	ee-----	el-----	en-----	eo-----	ep-----	er-----	es-----	ev-----	ew-----	f------	f-ae---	f-ao---	f-bd---	f-bs---	f-cd---	f-cf---	f-cg---	f-cm---	f-cx---	f-dm---	f-ea---	f-eg---	f-et---	f-ft---	f-gh---	f-gm---	f-go---	f-gv---	f-iv---	f-ke---	f-lb---	f-lo---	f-ly---	f-mg---	f-ml---	f-mr---	f-mu---	f-mw---	f-mz---	f-ng---	f-nr---	f-pg---	f-rh---	f-rw---	f-sa---	f-sd---	f-sf---	f-sg---	f-sh---	f-sj---	f-sl---	f-so---	f-sq---	f-ss---	f-sx---	f-tg---	f-ti---	f-tz---	f-ua---	f-ug---	f-uv---	f-za---	fa-----	fb-----	fc-----	fd-----	fe-----	ff-----	fg-----	fh-----	fi-----	fl-----	fn-----	fq-----	fr-----	fs-----	fu-----	fv-----	fw-----	fz-----	h------	i------	i-bi---	i-cq---	i-fs---	i-hm---	i-mf---	i-my---	i-re---	i-se---	i-xa---	i-xb---	i-xc---	i-xo---	l------	ln-----	lnaz---	lnbm---	lnca---	lncv---	lnfa---	lnjn---	lnma---	lnsb---	ls-----	lsai---	lsbv---	lsfk---	lstd---	lsxj---	lsxs---	m------	ma-----	mb-----	me-----	mm-----	mr-----	n------	n-cn---	n-cn-ab	n-cn-bc	n-cn-mb	n-cn-nf	n-cn-nk	n-cn-ns	n-cn-nt	n-cn-nu	n-cn-on	n-cn-pi	n-cn-qu	n-cn-sn	n-cn-yk	n-cnh--	n-cnm--	n-cnp--	n-gl---	n-mx---	n-us---	n-us-ak	n-us-al	n-us-ar	n-us-az	n-us-ca	n-us-co	n-us-ct	n-us-dc	n-us-de	n-us-fl	n-us-ga	n-us-hi	n-us-ia	n-us-id	n-us-il	n-us-in	n-us-ks	n-us-ky	n-us-la	n-us-ma	n-us-md	n-us-me	n-us-mi	n-us-mn	n-us-mo	n-us-ms	n-us-mt	n-us-nb	n-us-nc	n-us-nd	n-us-nh	n-us-nj	n-us-nm	n-us-nv	n-us-ny	n-us-oh	n-us-ok	n-us-or	n-us-pa	n-us-ri	n-us-sc	n-us-sd	n-us-tn	n-us-tx	n-us-ut	n-us-va	n-us-vt	n-us-wa	n-us-wi	n-us-wv	n-us-wy	n-usa--	n-usc--	n-use--	n-usl--	n-usm--	n-usn--	n-uso--	n-usp--	n-usr--	n-uss--	n-ust--	n-usu--	n-xl---	nc-----	ncbh---	nccr---	nccz---	nces---	ncgt---	ncho---	ncnq---	ncpn---	nl-----	nm-----	np-----	nr-----	nw-----	nwaq---	nwaw---	nwbb---	nwbf---	nwbn---	nwcj---	nwco---	nwcu---	nwdq---	nwdr---	nweu---	nwgd---	nwgp---	nwhi---	nwht---	nwjm---	nwla---	nwli---	nwmj---	nwmq---	nwna---	nwpr---	nwsc---	nwsd---	nwsn---	nwst---	nwsv---	nwtc---	nwtr---	nwuc---	nwvb---	nwvi---	nwwi---	nwxa---	nwxi---	nwxk---	nwxm---	p------	pn-----	po-----	poas---	pobp---	poci---	pocw---	poea---	pofj---	pofp---	pogg---	pogu---	poji---	pokb---	poki---	poln---	pome---	pomi---	ponl---	ponn---	ponu---	popc---	popl---	pops---	posh---	potl---	poto---	pott---	potv---	poup---	powf---	powk---	pows---	poxd---	poxe---	poxf---	poxh---	ps-----	q------	r------	s------	s-ag---	s-bl---	s-bo---	s-ck---	s-cl---	s-ec---	s-fg---	s-gy---	s-pe---	s-py---	s-sr---	s-uy---	s-ve---	sa-----	sn-----	sp-----	t------	u------	u-ac---	u-at---	u-at-ac	u-at-ne	u-at-no	u-at-qn	u-at-sa	u-at-tm	u-at-vi	u-at-we	u-atc--	u-ate--	u-atn--	u-cs---	u-nz---	w------	x------	xa-----	xb-----	xc-----	xd-----	zd-----	zju----	zma----	zme----	zmo----	zne----	zo-----	zpl----	zs-----	zsa----	zsu----	zur----	zve----"));

#fill the obsolete Geographic Area Codes hash

%ObsoleteGeogAreaCodes = map {($_, 1)} (split "\t", ("t-ay---	e-ur-ai	e-ur-aj	nwbc---	e-ur-bw	f-by---	pocp---	e-url--	cr-----	v------	e-ur-er	et-----	e-ur-gs	pogn---	nwga---	nwgs---	a-hk---	ei-----	f-if---	awiy---	awiw---	awiu---	e-ur-kz	e-ur-kg	e-ur-lv	e-ur-li	a-mh---	cm-----	e-ur-mv	n-usw--	a-ok---	a-pt---	e-ur-ru	pory---	nwsb---	posc---	a-sk---	posn---	e-uro--	e-ur-ta	e-ur-tk	e-ur-un	e-ur-uz	a-vn---	a-vs---	nwvr---	e-urv--	a-ys---"));

#fill the valid Language Codes hash

%LanguageCodes = map {($_, 1)} (split "\t", ("   	aar	abk	ace	ach	ada	ady	afa	afh	afr	ain	aka	akk	alb	ale	alg	alt	amh	ang	anp	apa	ara	arc	arg	arm	arn	arp	art	arw	asm	ast	ath	aus	ava	ave	awa	aym	aze	bad	bai	bak	bal	bam	ban	baq	bas	bat	bej	bel	bem	ben	ber	bho	bih	bik	bin	bis	bla	bnt	bos	bra	bre	btk	bua	bug	bul	bur	byn	cad	cai	car	cat	cau	ceb	cel	cha	chb	che	chg	chi	chk	chm	chn	cho	chp	chr	chu	chv	chy	cmc	cop	cor	cos	cpe	cpf	cpp	cre	crh	crp	csb	cus	cze	dak	dan	dar	day	del	den	dgr	din	div	doi	dra	dsb	dua	dum	dut	dyu	dzo	efi	egy	eka	elx	eng	enm	epo	est	ewe	ewo	fan	fao	fat	fij	fil	fin	fiu	fon	fre	frm	fro	frr	frs	fry	ful	fur	gaa	gay	gba	gem	geo	ger	gez	gil	gla	gle	glg	glv	gmh	goh	gon	gor	got	grb	grc	gre	grn	gsw	guj	gwi	hai	hat	hau	haw	heb	her	hil	him	hin	hit	hmn	hmo	hrv	hsb	hun	hup	iba	ibo	ice	ido	iii	ijo	iku	ile	ilo	ina	inc	ind	ine	inh	ipk	ira	iro	ita	jav	jbo	jpn	jpr	jrb	kaa	kab	kac	kal	kam	kan	kar	kas	kau	kaw	kaz	kbd	kha	khi	khm	kho	kik	kin	kir	kmb	kok	kom	kon	kor	kos	kpe	krc	krl	kro	kru	kua	kum	kur	kut	lad	lah	lam	lao	lat	lav	lez	lim	lin	lit	lol	loz	ltz	lua	lub	lug	lui	lun	luo	lus	mac	mad	mag	mah	mai	mak	mal	man	mao	map	mar	mas	may	mdf	mdr	men	mga	mic	min	mis	mkh	mlg	mlt	mnc	mni	mno	moh	mon	mos	mul	mun	mus	mwl	mwr	myn	myv	nah	nai	nap	nau	nav	nbl	nde	ndo	nds	nep	new	nia	nic	niu	nno	nob	nog	non	nor	nqo	nso	nub	nwc	nya	nym	nyn	nyo	nzi	oci	oji	ori	orm	osa	oss	ota	oto	paa	pag	pal	pam	pan	pap	pau	peo	per	phi	phn	pli	pol	pon	por	pra	pro	pus	que	raj	rap	rar	roa	roh	rom	rum	run	rup	rus	sad	sag	sah	sai	sal	sam	san	sas	sat	scn	sco	sel	sem	sga	sgn	shn	sid	sin	sio	sit	sla	slo	slv	sma	sme	smi	smj	smn	smo	sms	sna	snd	snk	sog	som	son	sot	spa	srd	srn	srp	srr	ssa	ssw	suk	sun	sus	sux	swa	swe	syc	syr	tah	tai	tam	tat	tel	tem	ter	tet	tgk	tgl	tha	tib	tig	tir	tiv	tkl	tlh	tli	tmh	tog	ton	tpi	tsi	tsn	tso	tuk	tum	tup	tur	tut	tvl	twi	tyv	udm	uga	uig	ukr	umb	und	urd	uzb	vai	ven	vie	vol	vot	wak	wal	war	was	wel	wen	wln	wol	xal	xho	yao	yap	yid	yor	ypk	zap	zbl	zen	zha	znd	zul	zun	zxx	zza"));

#fill the obsolete Language Codes hash

%ObsoleteLanguageCodes = map {($_, 1)} (split "\t", ("ajm	esk	esp	eth	far	fri	gag	gua	int	iri	cam	kus	mla	max	mol	lan	gal	lap	sao	gae	scc	scr	sho	snh	sso	swz	tag	taj	tar	tru	tsw"));

#fill the valid Country Codes hash

%CountryCodes = map {($_, 1)} (split "\t", ("aa 	abc	aca	ae 	af 	ag 	ai 	aj 	aku	alu	am 	an 	ao 	aq 	aru	as 	at 	au 	aw 	ay 	azu	ba 	bb 	bcc	bd 	be 	bf 	bg 	bh 	bi 	bl 	bm 	bn 	bo 	bp 	br 	bs 	bt 	bu 	bv 	bw 	bx 	ca 	cau	cb 	cc 	cd 	ce 	cf 	cg 	ch 	ci 	cj 	ck 	cl 	cm 	co 	cou	cq 	cr 	ctu	cu 	cv 	cw 	cx 	cy 	dcu	deu	dk 	dm 	dq 	dr 	ea 	ec 	eg 	em 	enk	er 	es 	et 	fa 	fg 	fi 	fj 	fk 	flu	fm 	fp 	fr 	fs 	ft 	gau	gb 	gd 	gh 	gi 	gl 	gm 	go 	gp 	gr 	gs 	gt 	gu 	gv 	gw 	gy 	gz 	hiu	hm 	ho 	ht 	hu 	iau	ic 	idu	ie 	ii 	ilu	inu	io 	iq 	ir 	is 	it 	iv 	iy 	ja 	ji 	jm 	jo 	ke 	kg 	kn 	ko 	ksu	ku 	kv 	kyu	kz 	lau	lb 	le 	lh 	li 	lo 	ls 	lu 	lv 	ly 	mau	mbc	mc 	mdu	meu	mf 	mg 	miu	mj 	mk 	ml 	mm 	mnu	mo 	mou	mp 	mq 	mr 	msu	mtu	mu 	mv 	mw 	mx 	my 	mz 	na 	nbu	ncu	ndu	ne 	nfc	ng 	nhu	nik	nju	nkc	nl 	nmu	nn 	no 	np 	nq 	nr 	nsc	ntc	nu 	nuc	nvu	nw 	nx 	nyu	nz 	ohu	oku	onc	oru	ot 	pau	pc 	pe 	pf 	pg 	ph 	pic	pk 	pl 	pn 	po 	pp 	pr 	pw 	py 	qa 	qea	quc	rb 	re 	rh 	riu	rm 	ru 	rw 	sa 	sc 	scu	sd 	sdu	se 	sf 	sg 	sh 	si 	sj 	sl 	sm 	sn 	snc	so 	sp 	sq 	sr 	ss 	st 	stk	su 	sw 	sx 	sy 	sz 	ta 	tc 	tg 	th 	ti 	tk 	tl 	tma	tnu	to 	tr 	ts 	tu 	tv 	txu	tz 	ua 	uc 	ug 	uik	un 	up 	utu	uv 	uy 	uz 	vau	vb 	vc 	ve 	vi 	vm 	vp 	vra	vtu	wau	wea	wf 	wiu	wj 	wk 	wlk	ws 	wvu	wyu	xa 	xb 	xc 	xd 	xe 	xf 	xga	xh 	xj 	xk 	xl 	xm 	xn 	xna	xo 	xoa	xp 	xr 	xra	xs 	xv 	xx 	xxc	xxk	xxu	ye 	ykc	za "));

#fill the obsolete Country Codes hash

%ObsoleteCountryCodes = map {($_, 1)} (split "\t", ("ai 	air	ac 	ajr	bwr	cn 	cz 	cp 	ln 	cs 	err	gsr	ge 	gn 	hk 	iw 	iu 	jn 	kzr	kgr	lvr	lir	mh 	mvr	nm 	pt 	rur	ry 	xi 	sk 	xxr	sb 	sv 	tar	tt 	tkr	unr	uk 	ui 	us 	uzr	vn 	vs 	wb 	ys 	yu "));

%Sources600_651 = map {($_, 1)} (split "\t", ("aass	aat	abne	aedoml	afo	afset	agrifors	agrovoc	agrovocf	agrovocs	aiatsisl	aiatsisp	aiatsiss	aktp	albt	allars	apaist	armac	ascl	asft	ashlnl	asrcrfcd	asrcseo	asrctoa	asth	ated	atg	atla	aucsh	ausext	bare	barn	bhb	bella	bet	bhammf	bhashe	bib1814	bibalex	bibbi	biccbmc	bicssc	bidex	bisacsh	bisacmt	bisacrt	bjornson	blcpss	blmlsh	blnpn	bokbas	bt	btr	cabt	cash	cbk	cck	cckthema	ccsa	cct	ccte	cctf	ccucaut	cdcng	ceeus	cerlt	chirosh	cht	ciesiniv	cilla	ckhw	collett	conorsi	csahssa	csalsct	csapa	csh	csht	cstud	czenas	czmesh	dacs	dbcsh	dbn	dcs	ddcri	ddcrit	ddcut	dicgenam	dicgenes	dicgentop	dissao	dit	dltlt	dltt	drama	dtict	dugfr	ebfem	eclas	eet	eflch	eks	embiaecid	embne	embucm	emnmus	ept	erfemn	ericd	est	eum	eurovocen	eurovoces	eurovocfr	eurovocsl	fast	fautor	fes	finaf	finmesh	fire	fmesh	fnhl	francis	fssh	galestne	gbd	gccst	gcipmedia	gcipplatform	gem	gemet	georeft	gnd	gnis	gst	gtt	habibe	habich	habifr	habiit	hamsun	hapi	hkcan	helecon	henn	hlasstg	hoidokki	homoit	hrvmesh	hrvmr	huc	humord	iaat	ibsen	ica	iconauth	icpsr	idas	idsbb	idszbz	idszbzes	idszbzna	idszbzzg	idszbzzh	idszbzzk	iescs	iest	ilot	ilpt	inist	inspect	ipat	ipsp	iptcnc	isis	itglit	itoamc	itrt	jhpb	jhpk	jlabsh	juho	jupo	jurivoc	kaa	kaba	kao	kassu	kauno	kaunokki	kdm	khib	kito	kitu	kkts	koko	kssbar	kta	kto	ktpt	ktta	kubikat	kula	kulo	kupu	labloc	lacnaf	lapponica	larpcal	lcac	lcdgt	lcmpt	lcsh	lcshac	lcstt	lctgm	lemac	lemb	liito	liv	lnmmbr	local	ltcsh	lua	maaq	maotao	mar	masa	mech	mero	mesh	mipfesd	mmm	mpirdes	msc	msh	mtirdes	mts	musa	muso	muzeukc	muzeukn	muzvukci	naf	nal	nalnaf	nasat	nbdbt	nbiemnfag	ncjt	ndlsh	netc	ndllsh	nicem	nimacsc	nlgaf	nlgkk	nlgsh	nlksh	nlmnaf	nmaict	no-ubo-mr	noraf	noram	norbok	normesh	noubomn	noubojur	nsbncf	nskps	nta	ntcpsc	ntcsd	ntids	ntissc	nzggn	nznb	odlt	ogst	onet	opms	ordnok	pascal	pepp	peri	periodo	pha	pkk	pleiades	pmbok	pmcsg	pmont	pmt	poliscit	popinte	pplt	ppluk	precis	prnpdi	prvt	psychit	puho	quiding	qlsp	qrma	qrmak	qtglit	raam	ram	rasuqam	renib	reo	rero	rerovoc	rma	root	rpe	rswk	rswkaf	rugeo	rurkp	rvm	rvmfast	rvmgd	samisk	sanb	sao	sbiao	sbt	scbi	scgdst	scisshl	scot	sears	sfit	sgc	sgce	shbe	she	shsples	sigle	sipri	sk	skbb	skon	slem	smda	snt	socio	solstad	sosa	spines	ssg	stcv	sthus	stw	sucnsaf	swd	swemesh	taika	tasmas	taxhs	tbit	tbjvp	tekord	tept	tero	tesa	tesbhaecid	test	tgn	tha	thema	thesoz	thia	tho	thub	tips	tisa	tlka	tlsh	toit	trfarn	trfbmb	trfdh	trfgr	trfoba	trfzb	trt	trtsa	tshd	tsht	tsr	ttka	ttll	tucua	udc	ukslc	ulan	umitrist	unbisn	unbist	unescot	unicefirc	usaidt	valo	vcaadu	vffyl	vmj	waqaf	watrest	wgst	wot	wpicsh	ysa	yso"));

#The codes cash, lcsh, lcshac, mesh, nal, and rvm are covered by 2nd indicators in 600-655
#they are only used when indicators are not available
%ObsoleteSources600_651 = map {($_, 1)} (split "\t", ("bibsent	cash	lcsh	lcshac	mesh	nal	nobomn	noubojor	reroa	rvm"));

%Sources655 = map {($_, 1)} (split "\t", ("aat	aatnor	afset	aiatsisl	aiatsisp	aiatsiss	aktp	alett	amg	asrcrfcd	asrcseo	asrctoa	asth	aucsh	barn	barngf	bib1814	bibalex	biccbmc	bidex	bgtchm	bisacsh	bisacmt	bisacrt	bjornson	bt	cash	cgndb	chirosh	cck	cct	cdcng	cjh	collett	conorsi	csht	czenas	dacs	dcs	dct	ddcut	eet	eflch	embne	emnmus	ept	erfemn	ericd	estc	eurovocen	eurovocsl	fast	fbg	fgtpcm	finmesh	fire	ftamc	galestne	gatbeg	gem	gmd	gmgpc	gnd	gpn	gtmm	gsafd	gst	gtlm	gttg	hamsun	hapi	hkcan	hoidokki	ica	ilot	isbdcontent	isbdmedia	itglit	itrt	jhpb	jhpk	kkts	lacnaf	lcgft	lcmpt	lcsh	lcshac	lcstt	lctgm	lemac	lobt	local	maaq	mar	marccategory	marcform	marcgt	marcsmd	mech	mesh	migfg	mim	msh	muzeukc	muzeukn	muzeukv	muzvukci	nal	nalnaf	nbdbgf	nbiemnfag	ncrbs	ncrcarrier	ncrcontent	ncrcpc	ncrfs	ncrft	ncrmat	ncrmedia	ncrpm	ncrpo	ncrrm	ncrtr	ncrvf	ndlgft	ndlsh	netc	ngl	nimafc	nlgaf	nlgkk	nlgsh	nlmnaf	nmc	no-ubo-mr	noraf	noram	nsbncf	ntids	nzcoh	nzggn	nznb	olacvggt	onet	opms	ordnok	peakbag	pkk	pmcsg	pmt	proysen	quiding	qlsp	qrmak	qtglit	raam	radfg	rasuqam	rbbin	rbgenr	rbmscv	rbpap	rbpri	rbprov	rbpub	rbtyp	rdabf	rdabs	rdacarrier	rdacc	rdaco	rdacontent	rdacpc	rdact	rdafnm	rdafs	rdaft	rdagen	rdagrp	rdagw	rdalay	rdamat	rdamedia	rdamt	rdapf	rdapm	rdapo	rdarm	rdarr	rdaspc	rdatc	rdatr	rdavf	reo	rerovoc	reveal	rma	rswk	rswkaf	rugeo	rvm	rvmgf	sao	saogf	scbi	sears	sgc	sgce	sgp	sipri	skon	snt	socio	spines	ssg	stw	swd	swemesh	tbit	thema	tesa	tgfbne	thesoz	tho	thub	toit	tsht	tsaij	tucua	ukslc	ulan	vgmsgg	vgmsng	vmj	waqaf"));

#The codes cash, lcsh, lcshac, mesh, nal, and rvm are covered by 2nd indicators in 600-655
#they are only used when indicators are not available
%ObsoleteSources655 = map {($_, 1)} (split "\t", ("cash	ftamc	lcsh	lcshac	marccarrier	marccontent	marcmedia	mesh	nal	reroa	rvm"));

1;

=head1 LICENSE

This code may be distributed under the same terms as Perl itself. 

Please note that this module is not a product of or supported by the 
employers of the various contributors to the code.

=head1 AUTHOR

Bryan Baldus
eijabb@cpan.org

Copyright (c) 2004-2020.

=cut

__END__