package syntaxhighlighter::vb;
$VERSION = '0.02';

sub load{

    use Wx qw(wxSTC_LEX_VB wxSTC_H_TAG);
    my $vb_keywords = 'and begin case call continue do each else elseif end erase
error event exit false for function get gosub goto if implement in load loop lset
me mid new next not nothing on or property raiseevent rem resume return rset
select set stop sub then to true unload until wend while with withevents
attribute alias as boolean byref byte byval const compare currency date declare dim double
enum explicit friend global integer let lib long module object option optional
preserve private property public redim single static string type variant';

    my $vbnet_keywords = 'addhandler addressof andalso alias and ansi as assembly auto boolean
byref byte byval call case catch cbool cbyte cchar cdate cdec cdbl char cint class
clng cobj const cshort csng cstr ctype date decimal declare default delegate dim do double
each else elseif end enum erase error event exit false finally for friend function get
gettype goto  handles if implements imports in inherits integer interface is let lib like long
loop me mod module mustinherit mustoverride mybase myclass namespace new
next not nothing notinheritable notoverridable object on option optional or
orelse overloads overridable overrides paramarray preserve private property protected public
raiseevent readonly redim rem removehandler resume return select set shadows
shared short single static step stop string structure sub synclock then throw to true try
typeof unicode until variant when while with withevents writeonly xor';

# Not used here, mostly system statements (files, registry, I/O...),
# I am not sure I should include them in the regular statements.
    my $vb_otherstatements = 'appactivate beep chdir chdrive close
deletesetting filecopy get input kill line lock unlock lset mid mkdir name
open print put randomize reset rmdir rset savepicture savesetting seek
sendkeys setattr time unload width write';

 $_[0]->SetLexer( wxSTC_LEX_VB );         # Set Lexers to use
 $_[0]->SetKeyWords(0,$vbnet_keywords);

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec( 0,"fore:#000000");					# whitespace
 $_[0]->StyleSetSpec( 1,"fore:#555555");					# Comment
 $_[0]->StyleSetSpec( 2,"fore:#007f7f");					# Number
 $_[0]->StyleSetSpec( 3,"fore:#3333aa,bold");				# Keyword
 $_[0]->StyleSetSpec( 4,"fore:#ff2020");					# String
 $_[0]->StyleSetSpec( 5,"fore:#208820");					# Preprocessor
 $_[0]->StyleSetSpec( 6,"fore:#882020");					# Operator
 $_[0]->StyleSetSpec( 7,"fore:#5577ff");					# Identifier
 $_[0]->StyleSetSpec( 8,"fore:#209999");					# Date

}

1;
