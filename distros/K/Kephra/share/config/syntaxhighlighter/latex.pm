package syntaxhighlighter::latex;
$VERSION = '0.01';

sub load{    use Wx qw(wxSTC_LEX_TEX wxSTC_H_TAG);

    my $tex_primitives = 'above abovedisplayshortskip abovedisplayskip
    abovewithdelims accent adjdemerits advance afterassignment
    aftergroup atop atopwithdelims
    badness baselineskip batchmode begingroup
    belowdisplayshortskip belowdisplayskip binoppenalty botmark
    box boxmaxdepth brokenpenalty
    catcode char chardef cleaders closein closeout clubpenalty
    copy count countdef cr crcr csname
    day deadcycles def defaulthyphenchar defaultskewchar
    delcode delimiter delimiterfactor delimeters
    delimitershortfall delimeters dimen dimendef discretionary
    displayindent displaylimits displaystyle
    displaywidowpenalty displaywidth divide
    doublehyphendemerits dp dump
    edef else emergencystretch end endcsname endgroup endinput
    endlinechar eqno errhelp errmessage errorcontextlines
    errorstopmode escapechar everycr everydisplay everyhbox
    everyjob everymath everypar everyvbox exhyphenpenalty
    expandafter
    fam fi finalhyphendemerits firstmark floatingpenalty font
    fontdimen fontname futurelet
    gdef global group globaldefs
    halign hangafter hangindent hbadness hbox hfil horizontal
    hfill horizontal hfilneg hfuzz hoffset holdinginserts hrule
    hsize hskip hss horizontal ht hyphenation hyphenchar
    hyphenpenalty hyphen
    if ifcase ifcat ifdim ifeof iffalse ifhbox ifhmode ifinner
    ifmmode ifnum ifodd iftrue ifvbox ifvmode ifvoid ifx
    ignorespaces immediate indent input inputlineno input
    insert insertpenalties interlinepenalty
    jobname
    kern
    language lastbox lastkern lastpenalty lastskip lccode 
    leaders left lefthyphenmin leftskip leqno let limits 
    linepenalty line lineskip lineskiplimit long looseness 
    lower lowercase 
    mag mark mathaccent mathbin mathchar mathchardef mathchoice 
    mathclose mathcode mathinner mathop mathopen mathord 
    mathpunct mathrel mathsurround maxdeadcycles maxdepth 
    meaning medmuskip message mkern month moveleft moveright 
    mskip multiply muskip muskipdef 
    newlinechar noalign noboundary noexpand noindent nolimits 
    nonscript scriptscript nonstopmode nulldelimiterspace 
    nullfont number 
    omit openin openout or outer output outputpenalty over 
    overfullrule overline overwithdelims 
    pagedepth pagefilllstretch pagefillstretch pagefilstretch 
    pagegoal pageshrink pagestretch pagetotal par parfillskip 
    parindent parshape parskip patterns pausing penalty 
    postdisplaypenalty predisplaypenalty predisplaysize 
    pretolerance prevdepth prevgraf 
    radical raise read relax relpenalty right righthyphenmin 
    rightskip romannumeral 
    scriptfont scriptscriptfont scriptscriptstyle scriptspace 
    scriptstyle scrollmode setbox setlanguage sfcode shipout 
    show showbox showboxbreadth showboxdepth showlists showthe 
    skewchar skip skipdef spacefactor spaceskip span special 
    splitbotmark splitfirstmark splitmaxdepth splittopskip 
    string 
    tabskip textfont textstyle the thickmuskip thinmuskip time 
    toks toksdef tolerance topmark topskip tracingcommands 
    tracinglostchars tracingmacros tracingonline tracingoutput 
    tracingpages tracingparagraphs tracingrestores tracingstats 
    uccode uchyph underline unhbox unhcopy unkern unpenalty 
    unskip unvbox unvcopy uppercase 
    vadjust valign vbadness vbox vcenter vfil vfill vfilneg 
    vfuzz voffset vrule vsize vskip vsplit vss vtop 
    wd widowpenalty write
    xdef xleaders xspaceskip
    year';

    my $etex_primitives = 'beginL beginR botmarks
    clubpenalties currentgrouplevel currentgrouptype
    currentifbranch currentiflevel currentiftype
    detokenize dimexpr displaywidowpenalties
    endL endR eTeXrevision eTeXversion everyeof
    firstmarks fontchardp fontcharht fontcharic fontcharwd
    glueexpr glueshrink glueshrinkorder gluestretch
    gluestretchorder gluetomu
    ifcsname ifdefined iffontchar interactionmode
    interactionmode interlinepenalties
    lastlinefit lastnodetype
    marks topmarks middle muexpr mutoglue
    numexpr
    pagediscards parshapedimen parshapeindent parshapelength
    predisplaydirection
    savinghyphcodes savingvdiscards scantokens showgroups
    showifs showtokens splitdiscards splitfirstmarks
    TeXXeTstate tracingassigns tracinggroups tracingifs
    tracingnesting tracingscantokens
    unexpanded unless
    widowpenalties';

    my $pdftex_primitives = 'pdfadjustspacing pdfannot pdfavoidoverfull
    pdfcatalog pdfcompresslevel
    pdfdecimaldigits pdfdest pdfdestmargin
    pdfendlink pdfendthread
    pdffontattr pdffontexpand pdffontname pdffontobjnum pdffontsize
    pdfhorigin
    pdfimageresolution pdfincludechars pdfinfo
    pdflastannot pdflastdemerits pdflastobj
    pdflastvbreakpenalty pdflastxform pdflastximage
    pdflastximagepages pdflastxpos pdflastypos
    pdflinesnapx pdflinesnapy pdflinkmargin pdfliteral
    pdfmapfile pdfmaxpenalty pdfminpenalty pdfmovechars
    pdfnames
    pdfobj pdfoptionpdfminorversion pdfoutline pdfoutput
    pdfpageattr pdfpageheight pdfpageresources pdfpagesattr
    pdfpagewidth pdfpkresolution pdfprotrudechars
    pdfrefobj pdfrefxform pdfrefximage
    pdfsavepos pdfsnaprefpoint pdfsnapx pdfsnapy pdfstartlink
    pdfstartthread
    pdftexrevision pdftexversion pdfthread pdfthreadmargin
    pdfuniqueresname
    pdfvorigin
    pdfxform pdfximage';

    my $omega_primitives = 'odelimiter omathaccent omathchar oradical omathchardef omathcode odelcode
    leftghost rightghost
    charwd charht chardp charit
    localleftbox localrightbox
    localinterlinepenalty localbrokenpenalty
    pagedir bodydir pardir textdir mathdir
    boxdir nextfakemath
    pagewidth pageheight pagerightoffset pagebottomoffset
    nullocp nullocplist ocp externalocp ocplist pushocplist popocplist clearocplists ocptracelevel
    addbeforeocplist addafterocplist removebeforeocplist removeafterocplist
    OmegaVersion
    InputTranslation OutputTranslation DefaultInputTranslation DefaultOutputTranslation
    noInputTranslation noOutputTranslation
    InputMode OutputMode DefaultInputMode DefaultOutputMode
    noInputMode noOutputMode noDefaultInputMode noDefaultOutputMode';


# only the macros that make sense:
    my $partial_tex_macros = 'TeX
    bgroup egroup endgraf space empty null
    newcount newdimen newskip newmuskip newbox newtoks newhelp newread newwrite newfam newlanguage newinsert newif
    maxdimen magstephalf magstep
    frenchspacing nonfrenchspacing normalbaselines obeylines obeyspaces raggedright ttraggedright
    thinspace negthinspace enspace enskip quad qquad
    smallskip medskip bigskip removelastskip topglue vglue hglue
    break nobreak allowbreak filbreak goodbreak smallbreak medbreak bigbreak
    line leftline rightline centerline rlap llap underbar strutbox strut
    cases matrix pmatrix bordermatrix eqalign displaylines eqalignno leqalignno
    pageno folio tracingall showhyphens fmtname fmtversion
    hphantom vphantom phantom smash';

    my $partial_etex_macros = 'eTeX
    newmarks grouptype interactionmode nodetype iftype
    tracingall loggingall tracingnone';


    $_[0]->SetLexer(wxSTC_LEX_TEX);            # Set Lexers to use
    $_[0]->SetKeyWords(0,$tex_primitives.$partial_tex_macros);
# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" );

    $_[0]->StyleSetSpec(0,"fore:#202020");					# Default
    $_[0]->StyleSetSpec(1,"fore:#007f7f");					# Special
    $_[0]->StyleSetSpec(2,"fore:#7f0000)");					# Group
    $_[0]->StyleSetSpec(3,"fore:#7f7f00");					# Symbol
    $_[0]->StyleSetSpec(4,"fore:#007f00");					# Command
    $_[0]->StyleSetSpec(5,"fore:#000000");					# Text

    $_[0]->StyleSetSpec(34,"fore:#00007f");					# Identifiers
    $_[0]->StyleSetSpec(35,"fore:#7f007f");					# Identifiers
}

1;