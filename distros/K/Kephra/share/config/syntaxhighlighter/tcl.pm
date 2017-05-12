package syntaxhighlighter::tcl;
$VERSION = '0.01';

sub load{

use Wx qw(wxSTC_LEX_TCL wxSTC_H_TAG);

my $TclKeywords = 'after append array auto_execok auto_import auto_load \
auto_load_index auto_qualify beep binary break case catch cd clock \
close concat continue dde default echo else elseif encoding eof \
error eval exec exit expr fblocked fconfigure fcopy file \
fileevent flush for foreach format gets glob global history if \
incr info interp join lappend lindex linsert list llength load \
lrange lreplace lsearch lsort namespace open package pid \
pkg_mkIndex proc puts pwd read regexp regsub rename resource \
return scan seek set socket source split string subst switch \
tclLog tclMacPkgSearch tclPkgSetup tclPkgUnknown tell time \
trace unknown unset update uplevel upvar variable vwait while';

my $TkKeywordclass = 'bell bind bindtags button canvas checkbutton console \
destroy entry event focus font frame grab grid image label listbox menu \
menubutton message pack place radiobutton raise scale scrollbar \
text tk tkwait toplevel winfo wm';

my $ItclKeywordclass = "@scope body class code common component configbody \
constructor define destructor hull import inherit itcl itk itk_component \
itk_initialize itk_interior itk_option iwidgets keep method \
private protected public";

my $TkCommands = "tkButtonDown tkButtonEnter tkButtonInvoke \
tkButtonLeave tkButtonUp tkCancelRepeat tkCheckRadioInvoke tkDarken \
tkEntryAutoScan 	tkEntryBackspace tkEntryButton1 tkEntryClosestGap \
tkEntryInsert tkEntryKeySelect tkEntryMouseSelect tkEntryNextWord \
tkEntryPaste tkEntryPreviousWord tkEntrySeeInsert tkEntrySetCursor \
tkEntryTranspose tkEventMotifBindings tkFDGetFileTypes tkFirstMenu \
tkFocusGroup_Destroy tkFocusGroup_In tkFocusGroup_Out tkFocusOK \
tkListboxAutoScan tkListboxBeginExtend tkListboxBeginSelect \
tkListboxBeginToggle tkListboxCancel tkListboxDataExtend \
tkListboxExtendUpDown tkListboxMotion tkListboxSelectAll \
tkListboxUpDown tkMbButtonUp tkMbEnter tkMbLeave tkMbMotion \
tkMbPost tkMenuButtonDown tkMenuDownArrow tkMenuDup tkMenuEscape \
tkMenuFind tkMenuFindName tkMenuFirstEntry tkMenuInvoke tkMenuLeave \
tkMenuLeftArrow tkMenuMotion tkMenuNextEntry tkMenuNextMenu \
tkMenuRightArrow tkMenuUnpost tkMenuUpArrow tkMessageBox \
tkPostOverPoint tkRecolorTree tkRestoreOldGrab tkSaveGrabInfo \
tkScaleActivate tkScaleButton2Down tkScaleButtonDown \
tkScaleControlPress tkScaleDrag tkScaleEndDrag tkScaleIncrement \
tkScreenChanged tkScrollButton2Down tkScrollButtonDown \
tkScrollButtonUp tkScrollByPages tkScrollByUnits tkScrollDrag \
tkScrollEndDrag tkScrollSelect tkScrollStartDrag tkScrollToPos  \
tkScrollTopBottom tkTabToWindow tkTearOffMenu tkTextAutoScan \
tkTextButton1 tkTextClosestGap tkTextInsert tkTextKeyExtend \
tkTextKeySelect tkTextNextPara tkTextNextPos tkTextNextWord \
tkTextPaste tkTextPrevPara tkTextPrevPos tkTextResetAnchor \
tkTextScrollPages tkTextSelectTo tkTextSetCursor tkTextTranspose \
tkTextUpDownLine tkTraverseToMenu tkTraverseWithinMenu tk_bisque \
tk_chooseColor tk_dialog tk_focusFollowsMouse tk_focusNext \
tk_focusPrev tk_getOpenFile tk_getSaveFile tk_messageBox \
tk_optionMenu tk_popup tk_setPalette tk_textCopy tk_textCut \
tk_textPaste";

 $_[0]->SetLexer( wxSTC_LEX_TCL );			# Set Lexers to use
 $_[0]->SetKeyWords(0, $TclKeywords); #.$TkKeywordclass.$ItclKeywordclass.$TkCommands

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" );	# Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec( 0,"fore:#000000");			# whitespace (SCE_CONF_DEFAULT)
 $_[0]->StyleSetSpec( 1,"fore:#777777");			# Comment (SCE_CONF_COMMENT)
 $_[0]->StyleSetSpec( 2,"fore:#3350ff");			# Number (SCE_CONF_NUMBER)
 $_[0]->StyleSetSpec( 3,"fore:#888820");			# String
 $_[0]->StyleSetSpec( 4,"fore:#202020");			# Single quoted string
 $_[0]->StyleSetSpec( 5,"fore:#208820");			# Keyword
 $_[0]->StyleSetSpec( 6,"fore:#882020");			# Triple quotes
 $_[0]->StyleSetSpec( 7,"fore:#202020");			# Triple double quotes
 $_[0]->StyleSetSpec( 8,"fore:#209999");			# Class name definition
 $_[0]->StyleSetSpec( 9,"fore:#202020");			# Function or method name definition
 $_[0]->StyleSetSpec(10,"fore:#000000");			# Operators
 $_[0]->StyleSetSpec(11,"fore:#777777");			# Identifiers
 $_[0]->StyleSetSpec(12,"fore:#7f7f7f");			# Comment-blocks
 $_[0]->StyleSetSpec(13,"fore:#000000,back:#E0C0E0,eolfilled");  # End of line where string is not closed
 $_[0]->StyleSetSpec(34,"fore:#0000ff");			# Matched Operators
 $_[0]->StyleSetSpec(35,"fore:#ff0000");			# Matched Operators

}

1;
