package syntaxhighlighter::nsis;
$VERSION = '0.01';

sub load{

    use Wx qw(wxSTC_LEX_NSIS wxSTC_H_TAG);

# Functions:
    my $nsis_keywords = 'What Abort AddSize AllowRootDirInstall AutoCloseWindow
BGGradient BrandingText BringToFront CRCCheck Call CallInstDLL Caption ClearErrors
CompletedText ComponentText CopyFiles CreateDirectory CreateShortCut Delete
DeleteINISec DeleteINIStr DeleteRegKey DeleteRegValue DetailPrint DetailsButtonText
DirShow DirText DisabledBitmap EnabledBitmap EnumRegKey EnumRegValue Exch Exec
ExecShell ExecWait ExpandEnvStrings File FileClose FileErrorText FileOpen FileRead
FileReadByte FileSeek FileWrite FileWriteByte FindClose FindFirst FindNext FindWindow
Function FunctionEnd GetCurrentAddress GetDLLVersionLocal GetDllVersion GetFileTime
GetFileTimeLocal GetFullPathName GetFunctionAddress GetLabelAddress GetTempFileName
Goto HideWindow Icon IfErrors IfFileExists IfRebootFlag InstProgressFlags InstType
InstallButtonText InstallColors InstallDir InstallDirRegKey IntCmp IntCmpU IntFmt IntOp
IsWindow LicenseData LicenseText MessageBox MiscButtonText Name OutFile Pop Push
Quit RMDir ReadEnvStr ReadINIStr ReadRegDword ReadRegStr Reboot RegDLL Rename
Return SearchPath Section SectionDivider SectionEnd SectionIn SendMessage SetAutoClose
SetCompress SetDatablockOptimize SetDateSave SetDetailsPrint SetDetailsView SetErrors
SetFileAttributes SetOutPath SetOverwrite SetRebootFlag ShowInstDetails ShowUninstDetails
SilentInstall SilentUnInstall Sleep SpaceTexts StrCmp StrCpy StrLen SubCaption UnRegDLL
UninstallButtonText UninstallCaption UninstallEXEName UninstallIcon UninstallSubCaption
UninstallText WindowIcon WriteINIStr WriteRegBin WriteRegDword WriteRegExpandStr
WriteRegStr WriteUninstaller SectionGetFlags SectionSetFlags SectionSetText SectionGetText
LogText LogSet CreateFont SetShellVarContext SetStaticBkColor SetBrandingImage PluginDir
SubSectionEnd SubSection CheckBitmap ChangeUI SetFont AddBrandingImage XPStyle Var
LangString !define !undef !ifdef !ifndef !endif !else !macro !echo !warning !error !verbose
!macroend !insertmacro !system !include !cd !packhdr';

# Variables:
    my $nsis_keywords2 = '$0 $1 $2 $3 $4 $5 $6 $7 $8 $9 
$R0 $R1 $R2 $R3 $R4 $R5 $R6 $R7 $R8 $R9 $CMDLINE $DESKTOP 
$EXEDIR $HWNDPARENT $INSTDIR $OUTDIR $PROGRAMFILES ${NSISDIR} $\n $\r 
$QUICKLAUNCH $SMPROGRAMS $SMSTARTUP $STARTMENU $SYSDIR $TEMP $WINDIR';

# Lables:
    my $nsis_keywords3 = 'ARCHIVE FILE_ATTRIBUTE_ARCHIVE FILE_ATTRIBUTE_HIDDEN
FILE_ATTRIBUTE_NORMAL FILE_ATTRIBUTE_OFFLINE FILE_ATTRIBUTE_READONLY
FILE_ATTRIBUTE_SYSTEM FILE_ATTRIBUTE_TEMPORARY HIDDEN HKCC HKCR HKCU
HKDD HKEY_CLASSES_ROOT HKEY_CURRENT_CONFIG HKEY_CURRENT_USER HKEY_DYN_DATA
HKEY_LOCAL_MACHINE HKEY_PERFORMANCE_DATA HKEY_USERS HKLM HKPD HKU IDABORT
IDCANCEL IDIGNORE IDNO IDOK IDRETRY IDYES MB_ABORTRETRYIGNORE MB_DEFBUTTON1
MB_DEFBUTTON2 MB_DEFBUTTON3 MB_DEFBUTTON4 MB_ICONEXCLAMATION
MB_ICONINFORMATION MB_ICONQUESTION MB_ICONSTOP MB_OK MB_OKCANCEL
MB_RETRYCANCEL MB_RIGHT MB_SETFOREGROUND MB_TOPMOST MB_YESNO MB_YESNOCANCEL
NORMAL OFFLINE READONLY SW_SHOWMAXIMIZED SW_SHOWMINIMIZED SW_SHOWNORMAL
SYSTEM TEMPORARY auto colored false force hide ifnewer nevershow normal
off on show silent silentlog smooth true try';

#User defined:
    my $nsis_keywords4 = 'MyFunction MySomethingElse';

    $_[0]->SetLexer(wxSTC_LEX_NSIS);					# Set Lexers to use
    $_[0]->SetKeyWords(0,$nsis_keywords1);
    $_[0]->SetKeyWords(1,$nsis_keywords2);
    $_[0]->SetKeyWords(2,$nsis_keywords3);
    $_[0]->SetKeyWords(3,$nsis_keywords4);

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)

 $_[0]->StyleSetSpec( 0,"fore:#000000");				# Whitespace (SCE_NSIS_DEFAULT)
 $_[0]->StyleSetSpec( 1,"fore:#bbbbbb");				# Comment (SCE_NSIS_COMMENT)
 $_[0]->StyleSetSpec( 2,"fore:#999999,back:#EEEEEE");		# String double quote (SCE_NSIS_STRINGDQ)
 $_[0]->StyleSetSpec( 3,"fore:#999999,back:#EEEEEE");		# String left quote (SCE_NSIS_STRINGLQ)
 $_[0]->StyleSetSpec( 4,"fore:#999999,back:#EEEEEE");		# String right quote (SCE_NSIS_STRINGRQ)
 $_[0]->StyleSetSpec( 5,"fore:#00007f,bold");			# Function (SCE_NSIS_FUNCTION)
 $_[0]->StyleSetSpec( 6,"fore:#CC3300");				# Variable (SCE_NSIS_VARIABLE)
 $_[0]->StyleSetSpec( 7,"fore:#ff9900");				# Label (SCE_NSIS_LABEL)
 $_[0]->StyleSetSpec( 8,"fore:#000000");				# User Defined (SCE_NSIS_USERDEFINED)
 $_[0]->StyleSetSpec( 9,"fore:#7f007f");				# Section (SCE_NSIS_SECTIONDEF)
 $_[0]->StyleSetSpec(10,"fore:#9fcc9f");				# Sub section (SCE_NSIS_SUBSECTIONDEF)
 $_[0]->StyleSetSpec(11,"fore:#007f00,bold");			# If def (SCE_NSIS_IFDEFINEDEF)
 $_[0]->StyleSetSpec(12,"fore:#009f00,bold");			# Macro def (SCE_NSIS_MACRODEF)
 $_[0]->StyleSetSpec(13,"fore:#CC3300,back:#EEEEEE");		# Variable within string (SCE_NSIS_STRINGVAR)
 $_[0]->StyleSetSpec(14,"fore:#007f7f");				# Numbers (SCE_NSIS_NUMBER)
}

1;
