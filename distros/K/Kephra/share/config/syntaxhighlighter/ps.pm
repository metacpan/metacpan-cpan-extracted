package syntaxhighlighter::ps;
$VERSION = '0.01';

sub load{

    use Wx qw(wxSTC_LEX_PS wxSTC_H_TAG);

# Postscript level 1 operators
    my $ps_keywords = 'FontDirectory StandardEncoding UserObjects abs add aload
anchorsearch and arc arcn arcto array ashow astore atan awidthshow begin bind
bitshift bytesavailable cachestatus ceiling charpath clear cleardictstack
cleartomark clip clippath closefile closepath concat concatmatrix copy copypage
cos count countdictstack countexecstack counttomark currentcmykcolor
currentcolorspace currentdash currentdict currentfile currentflat currentfont
currentgray currenthsbcolor currentlinecap currentlinejoin currentlinewidth
currentmatrix currentmiterlimit currentpagedevice currentpoint currentrgbcolor
currentscreen currenttransfer cvi cvlit cvn cvr cvrs cvs cvx def defaultmatrix
definefont dict dictstack div dtransform dup echo end eoclip eofill eq
erasepage errordict exch exec execstack executeonly executive exit exp false
file fill findfont flattenpath floor flush flushfile for forall ge get
getinterval grestore grestoreall gsave gt idetmatrix idiv idtransform if ifelse
image imagemask index initclip initgraphics initmatrix inustroke invertmatrix
itransform known kshow le length lineto ln load log loop lt makefont mark
matrix maxlength mod moveto mul ne neg newpath noaccess nor not null nulldevice
or pathbbox pathforall pop print prompt pstack put putinterval quit rand rcheck
rcurveto read readhexstring readline readonly readstring rectstroke repeat
resetfile restore reversepath rlineto rmoveto roll rotate round rrand run save
scale scalefont search setblackgeneration setcachedevice setcachelimit
setcharwidth setcolorscreen setcolortransfer setdash setflat setfont setgray
sethsbcolor setlinecap setlinejoin setlinewidth setmatrix setmiterlimit
setpagedevice setrgbcolor setscreen settransfer setvmthreshold show showpage
sin sqrt srand stack start status statusdict stop stopped store string
stringwidth stroke strokepath sub systemdict token token transform translate
true truncate type ueofill undefineresource userdict usertime version vmstatus
wcheck where widthshow write writehexstring writestring xcheck xor';

# Postscript level 2 operators
    my $ps_keywords2 = 'GlobalFontDirectory ISOLatin1Encoding SharedFontDirectory
UserObject arct
colorimage cshow currentblackgeneration currentcacheparams currentcmykcolor
currentcolor currentcolorrendering currentcolorscreen currentcolorspace
currentcolortransfer currentdevparams currentglobal currentgstate
currenthalftone currentobjectformat currentoverprint currentpacking
currentpagedevice currentshared currentstrokeadjust currentsystemparams
currentundercolorremoval currentuserparams defineresource defineuserobject
deletefile execform execuserobject filenameforall fileposition filter
findencoding findresource gcheck globaldict glyphshow gstate ineofill infill
instroke inueofill inufill inustroke languagelevel makepattern packedarray
printobject product realtime rectclip rectfill rectstroke renamefile
resourceforall resourcestatus revision rootfont scheck selectfont serialnumber
setbbox setblackgeneration setcachedevice2 setcacheparams setcmykcolor setcolor
setcolorrendering setcolorscreen setcolorspace setcolortranfer setdevparams
setfileposition setglobal setgstate sethalftone setobjectformat setoverprint
setpacking setpagedevice setpattern setshared setstrokeadjust setsystemparams
setucacheparams setundercolorremoval setuserparams setvmthreshold shareddict
startjob uappend ucache ucachestatus ueofill ufill undef undefinefont
undefineresource undefineuserobject upath ustroke ustrokepath vmreclaim
writeobject xshow xyshow yshow';

# Postscript level 3 operators
    my $ps_keywords3 = 'cliprestore clipsave composefont currentsmoothness 
findcolorrendering setsmoothness shfill';

# RIP-specific operators (Ghostscript)
    my $ps_keywords4 = '.begintransparencygroup .begintransparencymask .bytestring .charboxpath
.currentaccuratecurves .currentblendmode .currentcurvejoin .currentdashadapt
.currentdotlength .currentfilladjust2 .currentlimitclamp .currentopacityalpha
.currentoverprintmode .currentrasterop .currentshapealpha
.currentsourcetransparent .currenttextknockout .currenttexturetransparent
.dashpath .dicttomark .discardtransparencygroup .discardtransparencymask
.endtransparencygroup .endtransparencymask .execn .filename .filename
.fileposition .forceput .forceundef .forgetsave .getbitsrect .getdevice
.inittransparencymask .knownget .locksafe .makeoperator .namestring .oserrno
.oserrorstring .peekstring .rectappend .runandhide .setaccuratecurves
.setblendmode .setcurvejoin .setdashadapt .setdebug .setdefaultmatrix
.setdotlength .setfilladjust2 .setlimitclamp .setmaxlength .setopacityalpha
.setoverprintmode .setrasterop .setsafe .setshapealpha .setsourcetransparent
.settextknockout .settexturetransparent .stringbreak .stringmatch .tempfile
.type1decrypt .type1encrypt .type1execchar .unread arccos arcsin copydevice
copyscanlines currentdevice finddevice findlibfile findprotodevice flushpage
getdeviceprops getenv makeimagedevice makewordimagedevice max min
putdeviceprops setdevice';

    $_[0]->SetLexer(wxSTC_LEX_PS);					# Set Lexers to use
    $_[0]->SetKeyWords(0,$ps_keywords1);
    $_[0]->SetKeyWords(1,$ps_keywords2);
    $_[0]->SetKeyWords(2,$ps_keywords3);
    $_[0]->SetKeyWords(3,$ps_keywords4);

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)

 $_[0]->StyleSetSpec( 0,"fore:#000000");				# Default
 $_[0]->StyleSetSpec( 1,"fore:#bbbbbb");				# Comment
 $_[0]->StyleSetSpec( 2,"fore:#aaaaaa,back:#EEffEE");		# DSC comment
 $_[0]->StyleSetSpec( 3,"fore:#999999,back:#EEffEE");		# DSC comment value
 $_[0]->StyleSetSpec( 4,"fore:#007f7f");				# Number
 $_[0]->StyleSetSpec( 5,"fore:#00007f");				# Name
 $_[0]->StyleSetSpec( 6,"fore:#CC3300,bold");			# Keyword
 $_[0]->StyleSetSpec( 7,"fore:#ff9900");				# Literal
 $_[0]->StyleSetSpec( 8,"fore:#ffbb00");				# Immediately evaluated literal
 $_[0]->StyleSetSpec( 9,"fore:#7f007f");				# Array parenthesis
 $_[0]->StyleSetSpec(10,"fore:#9fcc9f");				# Dictionary parenthesis
 $_[0]->StyleSetSpec(11,"fore:#007f00");				# Procedure parenthesis
 $_[0]->StyleSetSpec(12,"fore:#000000");				# Text
 $_[0]->StyleSetSpec(13,"fore:#000000,back:#EEEEEE");		# Hex string
 $_[0]->StyleSetSpec(14,"fore:#000000,back:#dddddd");		# Base85 string
 $_[0]->StyleSetSpec(15,"fore:#ff0000");				# Bad string character
}

1;
