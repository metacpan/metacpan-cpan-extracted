package syntaxhighlighter::lua;
$VERSION = '0.01';

sub load {    use Wx qw(wxSTC_LEX_LUA wxSTC_H_TAG);

    my $lua_keywords = 'and break do else elseif end false for function if \
in local nil not or repeat return then true until while';

# Basic Functions
    my $lua_keywords2 = '_VERSION assert collectgarbage dofile error gcinfo loadfile loadstring \
print tonumber tostring type unpack';

#### Lua 4.0 Basic Functions
    my $lua4_keywords2 = '_ALERT _ERRORMESSAGE _INPUT _PROMPT _OUTPUT \
_STDERR _STDIN _STDOUT call dostring foreach foreachi getn globals newtype \
rawget rawset require sort tinsert tremove';

# String Manipulation & Mathematical Functions
    my $lua4_keywords3 = 'abs acos asin atan atan2 ceil cos deg exp \
floor format frexp gsub ldexp log log10 max min mod rad random randomseed \
sin sqrt strbyte strchar strfind strlen strlower strrep strsub strupper tan';

# Input and Output Facilities & System Facilities
    my $lua4_keywords4 = 'openfile closefile readfrom writeto appendto \
remove rename flush seek tmpfile tmpname read write \
clock date difftime execute exit getenv setlocale time';

#### Lua 5.0 Basic Functions
    my $lua5_keywords2 = '_G getfenv getmetatable ipairs loadlib next pairs pcall \
rawegal rawget rawset require setfenv setmetatable xpcall \
string table math coroutine io os debug';
# I put the library names here, so when highlighted standalone, they are probably variable name from Lua 4.0 times.

# String Manipulation, Table Manipulation, Mathematical Functions (string & table & math)
    my $lua5_keywords3 = 'string.byte string.char string.dump string.find string.len \
string.lower string.rep string.sub string.upper string.format string.gfind string.gsub \
table.concat table.foreach table.foreachi table.getn table.sort table.insert table.remove table.setn \
math.abs math.acos math.asin math.atan math.atan2 math.ceil math.cos math.deg math.exp \
math.floor math.frexp math.ldexp math.log math.log10 math.max math.min math.mod \
math.pi math.rad math.random math.randomseed math.sin math.sqrt math.tan';

# Coroutine Manipulation, Input and Output Facilities, System Facilities (coroutine & io & os)
    my $lua5_keywords4 = 'coroutine.create coroutine.resume coroutine.status \
coroutine.wrap coroutine.yield \
io.close io.flush io.input io.lines io.open io.output io.read io.tmpfile io.type io.write \
io.stdin io.stdout io.stderr \
os.clock os.date os.difftime os.execute os.exit os.getenv os.remove os.rename \
os.setlocale os.time os.tmpname';
# I keep keywords5, 6, 7 & 8 for other libraries

    $_[0]->SetLexer(wxSTC_LEX_LUA);				# Set Lexers to use
    $_[0]->SetKeyWords(0,$lua_keywords);
    $_[0]->SetKeyWords(1,$lua_keywords2.$lua4_keywords2.$lua5_keywords2);
    $_[0]->SetKeyWords(2,$lua4_keywords3.$lua5_keywords3);
    $_[0]->SetKeyWords(3,$lua4_keywords4.$lua5_keywords4);
# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" );

    $_[0]->StyleSetSpec(0,"fore:#202020");					# White space
    $_[0]->StyleSetSpec(1,"fore:#bbbbbb");					# Block comment (Lua 5.0)
    $_[0]->StyleSetSpec(2,"fore:#cccccc)");					# Line Comment
    $_[0]->StyleSetSpec(3,"fore:#ddffdd");					# Doc comment
    $_[0]->StyleSetSpec(4,"fore:#007f7f");					# Number
    $_[0]->StyleSetSpec(5,"fore:#7788bb,bold");					# Keywords
    $_[0]->StyleSetSpec(6,"fore:#555555,back:#ddeecc");			# String
    $_[0]->StyleSetSpec(7,"fore:#555555,back:#eeeebb");			# Character
    $_[0]->StyleSetSpec(8,"fore:#55ffff");					# Literal string
    $_[0]->StyleSetSpec(9,"fore:#228833");					# Preprocessor
    $_[0]->StyleSetSpec(10,"fore:#bb7799,bold");				# Operators
    $_[0]->StyleSetSpec(11,"fore:#778899");					# Identifiers (everything else...)
    $_[0]->StyleSetSpec(12,"fore:#228822");					# End of line where string is not closed
    $_[0]->StyleSetSpec(13,"fore:#339933");					# Other keywords (bozo test colors :-)
    $_[0]->StyleSetSpec(14,"fore:#44aa44");					# keywords3
    $_[0]->StyleSetSpec(15,"fore:#55bb55");					# keywords4
    $_[0]->StyleSetSpec(16,"fore:#66cc66");					# keywords5
    $_[0]->StyleSetSpec(17,"fore:#66cc66");					# keywords6
    $_[0]->StyleSetSpec(18,"fore:#77dd77");					# keywords7
    $_[0]->StyleSetSpec(19,"fore:#88ee88");					# keywords8

    $_[0]->StyleSetSpec(32,"fore:#000000");					# Default
}

1;