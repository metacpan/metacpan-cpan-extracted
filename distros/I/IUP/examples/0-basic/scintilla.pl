#  IUP::Scintilla example

use strict;
use warnings;

use IUP ':all';

my $sampleCode = <<'END';
  /* Block comment */
  #include<stdio.h>
  #include<iup.h>
  
  void SampleTest() {
    printf("Printing float: %f\n", 12.5);
  }
  
  void SampleTest2() {
    printf("Printing char: %c\n", 'c');
  }
  
  int main(int argc, char **argv) {
    // Start up IUP
    IupOpen(&argc, &argv);
    IupSetGlobal("SINGLEINSTANCE", "Iup Sample");
    
    if(!IupGetGlobal("SINGLEINSTANCE")) {
      IupClose(); 
      return EXIT_SUCCESS; 
    }
      
    SampleTest();
    SampleTest2();
    printf("Printing an integer: %d\n", 37);
    
    IupMainLoop();
    IupClose();
    return EXIT_SUCCESS;
  }
END

my $sci = IUP::Scintilla->new( EXPAND=>"YES");
my $dlg = IUP::Dialog->new( child=>$sci, TITLE=>"IupScintilla", SIZE=>"HALFxHALF" );
$dlg->Show();

$sci->SetCallback(CARET_CB => sub { warn "carret:$_[1]:$_[2]:$_[3]\n" });
$sci->SetAttribute(
  KEYWORDS0 => "void struct union enum char short int long double float signed unsigned const static extern auto register volatile bool class private protected public friend inline template virtual asm explicit typename mutable"
              ."if else switch case default break goto return for while do continue typedef sizeof NULL new delete throw try catch namespace operator this const_cast static_cast dynamic_cast reinterpret_cast true false using"
              ."typeid and and_eq bitand bitor compl not not_eq or or_eq xor xor_eq",
  CLEARALL => "",
  LEXERLANGUAGE => "cpp",
  STYLEFONT32 => "Consolas",
  STYLEFONTSIZE32 => "11",
  STYLECLEARALL => "Yes",
  STYLEFGCOLOR1 => "0 128 0",    # 1-C comment 
  STYLEFGCOLOR2 => "0 128 0",    # 2-C++ comment line 
  STYLEFGCOLOR4 => "128 0 0",    # 4-Number 
  STYLEFGCOLOR5 => "0 0 255",    # 5-Keyword 
  STYLEFGCOLOR6 => "160 20 20",  # 6-String 
  STYLEFGCOLOR7 => "128 0 0",    # 7-Character 
  STYLEFGCOLOR9 => "0 0 255",    # 9-Preprocessor block 
  STYLEFGCOLOR10 => "255 0 255", # 10-Operator 
  STYLEBOLD10 => "YES",          # 11-Identifier  
  STYLEHOTSPOT6 => "YES", 
  INSERT0 => $sampleCode,
  MARGINWIDTH0 => "50",
  PROPERTY => "fold=1",
  PROPERTY => "fold.compact=0",
  PROPERTY => "fold.comment=1",
  PROPERTY => "fold.preprocessor=1",
  MARGINWIDTH1 => "20",
  MARGINTYPE1 => "SYMBOL",
  MARGINMASKFOLDERS1 => "Yes",
  MARKERDEFINE => "FOLDER=PLUS",
  MARKERDEFINE => "FOLDEROPEN=MINUS",
  MARKERDEFINE => "FOLDEREND=EMPTY",
  MARKERDEFINE => "FOLDERMIDTAIL=EMPTY",
  MARKERDEFINE => "FOLDEROPENMID=EMPTY",
  MARKERDEFINE => "FOLDERSUB=EMPTY",
  MARKERDEFINE => "FOLDERTAIL=EMPTY",
  FOLDFLAGS => "LINEAFTER_CONTRACTED",
  MARGINSENSITIVE1 => "YES",
);

IUP->MainLoop;
