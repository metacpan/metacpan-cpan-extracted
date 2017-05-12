package syntaxhighlighter::forth;
$VERSION = '0.01';

sub load{

    use Wx qw(wxSTC_LEX_FORTH wxSTC_H_TAG);

# control keywords Forth
    my $forth_keywords = 'AGAIN BEGIN CASE DO ELSE ENDCASE ENDOF IF LOOP OF 
REPEAT THEN UNTIL  WHILE 
[IF] [ELSE] [THEN] ?DO';

# keywords 
    my $forth_keywords2 = 'DUP DROP ROT SWAP OVER @ ! 2@ 2! 2DUP 2DROP 2SWAP 2OVER NIP R@ >R R> 2R@ 2>R 2R> 
0= 0< SP@ SP! W@ W! C@ C! < > = <> 0<>
SPACE SPACES KEY? KEY THROW CATCH ABORT */ 2* /MOD CELL+ CELLS CHAR+
CHARS MOVE ERASE DABS TITLE HEX DECIMAL HOLD <# # #S #> SIGN
D. . U. DUMP (.") >NUMBER IMMEDIATE EXIT RECURSE UNLOOP LEAVE HERE ALLOT ,
C, W, COMPILE, BRANCH, RET, LIT, DLIT, ?BRANCH, ", >MARK >RESOLVE1 <MARK >RESOLVE
ALIGN ALIGNED USER-ALLOT USER-HERE HEADER DOES> SMUDGE HIDE :NONAME LAST-WORD
?ERROR ERROR2 FIND1 SFIND SET-CURRENT GET-CURRENT DEFINITIONS GET-ORDER FORTH
ONLY SET-ORDER ALSO PREVIOUS VOC-NAME. ORDER LATEST LITERAL 2LITERAL SLITERAL
CLITERAL ?LITERAL1 ?SLITERAL1 HEX-LITERAL HEX-SLITERAL ?LITERAL2 ?SLITERAL2 SOURCE
EndOfChunk CharAddr PeekChar IsDelimiter GetChar OnDelimiter SkipDelimiters OnNotDelimiter
SkipWord SkipUpTo ParseWord NextWord PARSE SKIP CONSOLE-HANDLES REFILL DEPTH ?STACK
?COMP WORD INTERPRET BYE QUIT MAIN1 EVALUATE INCLUDE-FILE INCLUDED >BODY +WORD
WORDLIST CLASS! CLASS@ PAR! PAR@ ID. ?IMMEDIATE ?VOC IMMEDIATE VOC WordByAddrWl
WordByAddr NLIST WORDS SAVE OPTIONS /notransl ANSI>OEM ACCEPT EMIT CR TYPE EKEY?
EKEY EKEY>CHAR EXTERNTASK ERASE-IMPORTS ModuleName ModuleDirName ENVIRONMENT?
DROP-EXC-HANDLER SET-EXC-HANDLER HALT ERR CLOSE-FILE CREATE-FILE CREATE-FILE-SHARED
OPEN-FILE-SHARED DELETE-FILE FILE-POSITION FILE-SIZE OPEN-FILE READ-FILE REPOSITION-FILE
DOS-LINES UNIX-LINES READ-LINE WRITE-FILE RESIZE-FILE WRITE-LINE ALLOCATE FREE RESIZE
START SUSPEND RESUME STOP PAUSE MIN MAX TRUE FALSE ASCIIZ>
R/O W/O ;CLASS ENDWITH OR AND /STRING SEARCH COMPARE EXPORT ;MODULE SPACE /'';

# defwords
    my $forth_keywords3 = 'VARIABLE CREATE : VALUE CONSTANT VM: M: var dvar chars OBJ
CONSTR: DESTR: CLASS: OBJECT: POINTER
USER USER-CREATE USER-VALUE VECT
WNDPROC: VOCABULARY -- TASK: CEZ: MODULE:';

# prewords1
    my $forth_keywords4 = 'CHAR [CHAR] POSTPONE WITH ['] TO [COMPILE] CHAR ASCII ';

# prewords2
    my $forth_keywords5 = 'REQUIRE WINAPI:';

# string words
    my $forth_keywords6 = 'S" ABORT" Z" " ." C"';

    $_[0]->SetLexer( wxSTC_LEX_FORTH );					# Set Lexers to use
    $_[0]->SetKeyWords(0,$forth_keywords);
    $_[0]->SetKeyWords(1,$forth_keywords2);
    $_[0]->SetKeyWords(2,$forth_keywords3);
    $_[0]->SetKeyWords(3,$forth_keywords4);
    $_[0]->SetKeyWords(4,$forth_keywords5);
    $_[0]->SetKeyWords(5,$forth_keywords6);

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)

 $_[0]->StyleSetSpec( 0,"fore:#000000");				# whitespace (SCE_FORTH_DEFAULT)
 $_[0]->StyleSetSpec( 1,"fore:#009933");				# Comment (SCE_FORTH_COMMENT)
 $_[0]->StyleSetSpec( 2,"fore:#007f00");				# ML comment (SCE_FORTH_COMMENT_ML)
 $_[0]->StyleSetSpec( 3,"fore:#000000,bold");			# ML comment (SCE_FORTH_IDENTIFIER)
 $_[0]->StyleSetSpec( 4,"fore:#00007f,bold");			# control (SCE_FORTH_CONTROL)
 $_[0]->StyleSetSpec( 5,"fore:#000000,bold");			# Keywords
 $_[0]->StyleSetSpec( 6,"fore:#ff0000");				# defwords (SCE_FORTH_DEFWORD)
 $_[0]->StyleSetSpec( 7,"fore:#cc3300");				# preword1 (SCE_FORTH_PREWORD1)
 $_[0]->StyleSetSpec( 8,"fore:#996633");				# preword2 (SCE_FORTH_PREWORD2)
 $_[0]->StyleSetSpec( 9,"fore:#007f7f");				# number (SCE_FORTH_NUMBER)
 $_[0]->StyleSetSpec(10,"fore:#cc3300");				# Double quoted string (SCE_FORTH_STRING)
 $_[0]->StyleSetSpec(11,"fore:#0000cc");				# locale
}

1;