package syntaxhighlighter::sh;
$VERSION = '0.01';

sub load{
use Wx qw(wxSTC_LEX_PERL wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_PERL );         # Set Lexers for perl and Bash shell
 $_[0]->SetKeyWords(0,'alias \
ar asa awk banner basename bash bc bdiff break \
bunzip2 bzip2 cal calendar case cat cc cd chmod cksum \
clear cmp col comm compress continue cp cpio crypt \
csplit ctags cut date dc dd declare deroff dev df diff diff3 \
dircmp dirname do done du echo ed egrep elif else env \
esac eval ex exec exit expand export expr false fc \
fgrep fi file find fmt fold for function functions \
getconf getopt getopts grep gres hash head help \
history iconv id if in integer jobs join kill local lc \
let line ln logname look ls m4 mail mailx make \
man mkdir more mt mv newgrp nl nm nohup ntps od \
pack paste patch pathchk pax pcat perl pg pr print \
printf ps pwd read readonly red return rev rm rmdir \
sed select set sh shift size sleep sort spell \
split start stop strings strip stty sum suspend \
sync tail tar tee test then time times touch tr \
trap true tsort tty type typeset ulimit umask unalias \
uname uncompress unexpand uniq unpack unset until \
uudecode uuencode vi vim vpax wait wc whence which \
while who wpaste wstart xargs zcat');
# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec(0,"fore:#202020");                        # White space
 $_[0]->StyleSetSpec(1,"fore:#ff0000");                        # Error
 $_[0]->StyleSetSpec(2,"fore:#aaaaaa)");                       # Comment
 $_[0]->StyleSetSpec(3,"fore:#004000,back:#E0FFE0,$(font.text),eolfilled"); # POD: = at beginning of line
 $_[0]->StyleSetSpec(4,"fore:#007f7f");                        # Number
 $_[0]->StyleSetSpec(5,"fore:#000077,bold");                   # Keywords
 $_[0]->StyleSetSpec(6,"fore:#ee7b00,back:#fff8f8");           #  Doublequoted string
 $_[0]->StyleSetSpec(7,"fore:#f36600,back:#fff8ff");           #  Single quoted string
 $_[0]->StyleSetSpec(8,"fore:#555555");                        # Symbols / Punctuation. Currently not used by LexPerl.
 $_[0]->StyleSetSpec(9,"");                                    # Preprocessor. Currently not used by LexPerl.
 $_[0]->StyleSetSpec(10,"$(colour.operator),bold");            # Operators
 $_[0]->StyleSetSpec(11,"fore:#3355bb");                       # Identifiers (functions, etc.)
 $_[0]->StyleSetSpec(12,"fore:#228822");                       # Scalars: $var
 $_[0]->StyleSetSpec(13,"fore:#339933");                       # Array: @var
 $_[0]->StyleSetSpec(14,"fore:#44aa44");                       # Hash: %var
 $_[0]->StyleSetSpec(15,"fore:#55bb55");                       # Symbol table: *var
 $_[0]->StyleSetSpec(17,"fore:#000000,back:#A0FFA0");          # Regex: /re/ or m{re}
 $_[0]->StyleSetSpec(18,"fore:#000000,back:#F0E080");          # Substitution: s/re/ore/
 $_[0]->StyleSetSpec(19,"fore:#FFFF00,back:#8080A0");          # Long Quote (qq, qr, qw, qx) -- obsolete: replaced by qq, qx, qr, qw
 $_[0]->StyleSetSpec(20,"fore:#FFFF00,back:#A08080");          # Back Ticks
 $_[0]->StyleSetSpec(21,"fore:#600000,back:#FFF0D8,eolfilled");# Data Section: __DATA__ or __END__ at beginning of line
 $_[0]->StyleSetSpec(22,"fore:#000000,back:#DDD0DD");          # Here-doc (delimiter)
 $_[0]->StyleSetSpec(23,"fore:#7F007F,back:#DDD0DD,eolfilled,notbold");# Here-doc (single quoted, q)
 $_[0]->StyleSetSpec(24,"fore:#7F007F,back:#DDD0DD,eolfilled,bold");   # Here-doc (double quoted, qq)
 $_[0]->StyleSetSpec(25,"fore:#7F007F,back:#DDD0DD,eolfilled,italics");# Here-doc (back ticks, qx)
 $_[0]->StyleSetSpec(26,"fore:#7F007F,$(font.monospace),notbold"); # Single quoted string, generic
 $_[0]->StyleSetSpec(27,"$(style.perl.6)");                    # qq = Double quoted string
 $_[0]->StyleSetSpec(28,"$(style.perl.20)");                   # qx = Back ticks
 $_[0]->StyleSetSpec(29,"$(style.perl.17)");                   # qr = Regex
 $_[0]->StyleSetSpec(30,"fore:#f36600,back:#fff8f8");          # qw = Array
}

1;
