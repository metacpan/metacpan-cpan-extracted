package syntaxhighlighter::php;
$VERSION = '0.01';

sub load{
use Wx qw(wxSTC_LEX_PHPSCRIPT wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_PHPSCRIPT );         # Set Lexers to use
 $_[0]->SetKeyWords(0,'
and argv as argc break case cfunction class continue declare default do \
die echo else elseif empty enddeclare endfor endforeach endif endswitch \
endwhile e_all e_parse e_error e_warning eval exit extends false for \
foreach function global http_cookie_vars http_get_vars http_post_vars \
http_post_files http_env_vars http_server_vars if include include_once \
list new not null old_function or parent php_os php_self php_version \
print require require_once return static switch stdclass this true var \
xor virtual while __file__ __line__ __sleep __wakeup');                     # Add new keyword.
 $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec(0,"fore:#202020");           # White space
 $_[0]->StyleSetSpec(1,"fore:#ff0000");           # Error
 $_[0]->StyleSetSpec(2,"fore:#9999dd)");          # Comment
 $_[0]->StyleSetSpec(3,"fore:#004000");           # POD: = at beginning of line
 $_[0]->StyleSetSpec(4,"fore:#007f7f");           # Number
 $_[0]->StyleSetSpec(5,"fore:#000077,bold");      # Keywords
 $_[0]->StyleSetSpec(6,"fore:#ee7b00");           #  Doublequoted string
 $_[0]->StyleSetSpec(7,"fore:#f36600");           #  Single quoted string
 $_[0]->StyleSetSpec(8,"fore:#555555");           # Symbols / Punctuation. Currently not used by LexPerl.
 $_[0]->StyleSetSpec(9,"fore:#555555");           # Preprocessor. Currently not used by LexPerl.
 $_[0]->StyleSetSpec(10,"fore:#800080");          # Operators
 $_[0]->StyleSetSpec(11,"fore:#3355bb");          # Identifiers (functions, etc.)
 $_[0]->StyleSetSpec(12,"fore:#228822");          # Scalars: $var
 $_[0]->StyleSetSpec(13,"fore:#339933");          # Array: @var
 $_[0]->StyleSetSpec(14,"fore:#44aa44");          # Hash: %var
 $_[0]->StyleSetSpec(15,"fore:#55bb55");          # Symbol table: *var
 $_[0]->StyleSetSpec(17,"fore:#000000");          # Regex: /re/ or m{re}
 $_[0]->StyleSetSpec(18,"fore:#0000FF");          # PHP
 $_[0]->StyleSetSpec(19,"fore:#FFFF00");          # Long Quote (qq, qr, qw, qx) -- obsolete: replaced by qq, qx, qr, qw
 $_[0]->StyleSetSpec(20,"fore:#FFFF00");          # Back Ticks
 $_[0]->StyleSetSpec(21,"fore:#600000");          # Data Section: __DATA__ or __END__ at beginning of line
 $_[0]->StyleSetSpec(22,"fore:#000000");          # Here-doc (delimiter)
 $_[0]->StyleSetSpec(23,"fore:#7F007F");# Here-doc (single quoted, q)
 $_[0]->StyleSetSpec(24,"fore:#7F007F");   # Here-doc (double quoted, qq)
 $_[0]->StyleSetSpec(25,"fore:#7F007F");          # Here-doc (back ticks, qx)
 $_[0]->StyleSetSpec(26,"fore:#7F007F");          # Single quoted string, generic
 $_[0]->StyleSetSpec(27,"fore:#f36600");          # qq = Double quoted string
 $_[0]->StyleSetSpec(28,"fore:#228822");          # qx = Back ticks
 $_[0]->StyleSetSpec(29,"fore:#f36600");          # qr = Regex
 $_[0]->StyleSetSpec(30,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(31,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(32,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(33,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(34,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(35,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(36,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(37,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(38,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(39,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(40,"fore:#228822");          # qw = Array
 $_[0]->StyleSetSpec(41,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(42,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(43,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(44,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(45,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(46,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(47,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(48,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(49,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(50,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(51,"fore:#228822");                   # qw = Array
 $_[0]->StyleSetSpec(52,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(53,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(54,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(55,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(56,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(57,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(58,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(59,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(60,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(61,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(62,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(63,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(64,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(65,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(66,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(67,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(68,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(69,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(70,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(71,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(72,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(73,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(74,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(75,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(76,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(77,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(78,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(79,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(80,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(81,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(82,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(83,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(84,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(85,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(86,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(87,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(88,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(89,"fore:#228822");                   # qw = Array 
 #$_[0]->StyleSetSpec(90,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(91,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(92,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(93,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(94,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(95,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(96,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(97,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(98,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(99,"fore:#228822");                   # qw = Array 
 #$_[0]->StyleSetSpec(100,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(101,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(102,"fore:#228822");                   # qw = Array
 #$_[0]->StyleSetSpec(103,"fore:#228822");                   # qw = Array

# $_[0]->StyleSetSpec(104,"fore:#00007F,italics,back:#FFF8F8");  # PHP complex variable
 
 $_[0]->StyleSetSpec(105,"fore:#999999,back:#F8F8ff,italics");		# One line comment
 $_[0]->StyleSetSpec(106,"fore:#00007F,back:#F8F8ff,italics");		# PHP variable in double quoted string
 $_[0]->StyleSetSpec(107,"fore:#002200,back:#F8F8ff");				# PHP operator
 $_[0]->StyleSetSpec(108,"fore:#000033,back:#F8F8ff,eolfilled");	# PHP Default
 $_[0]->StyleSetSpec(109,"fore:#007F00,back:#F8F8ff");				# Double quoted String
 $_[0]->StyleSetSpec(110,"fore:#009F00,back:#F8F8ff");				# Single quoted string
 $_[0]->StyleSetSpec(111,"fore:#000077,bold,back:#F8ffff");         # Keyword
 $_[0]->StyleSetSpec(112,"fore:#007f7f,back:#F8F8ff");				# Number
 $_[0]->StyleSetSpec(113,"fore:#228822,back:#F8F8ff,italics");		# Variable
 $_[0]->StyleSetSpec(114,"fore:#999999,back:#F8F8ff");				# Comment
 $_[0]->StyleSetSpec(115,"fore:#666666,back:#F8F8ff,italics");		# One line comment
 $_[0]->StyleSetSpec(116,"fore:#00007F,back:#F8F8ff,italics");		# PHP variable in double quoted string
 $_[0]->StyleSetSpec(117,"fore:#000000,back:#F8F8ff");				# PHP operator
#
 $_[0]->StyleSetSpec(118,"fore:#000033,back:#F8F8ff,eolfilled");	# PHP   Default
 $_[0]->StyleSetSpec(119,"fore:#007F00,back:#F8F8ff");				# Double quoted String
 $_[0]->StyleSetSpec(120,"fore:#009F00,back:#F8F8ff");				# Single quoted string
 $_[0]->StyleSetSpec(121,"fore:#7F007F,back:#F8F8ff,italics");		# Keyword
 $_[0]->StyleSetSpec(122,"fore:#CC9900,back:#F8F8ff");				# Number
 $_[0]->StyleSetSpec(123,"fore:#00007F,back:#F8F8ff,italics");		# Variable
 $_[0]->StyleSetSpec(124,"fore:#777777,back:#F8F8ff");				# Comment
 $_[0]->StyleSetSpec(125,"fore:#aaaaaa,back:#F8F8Ff,italics");		# One line comment
 $_[0]->StyleSetSpec(126,"fore:#00007F,back:#F8F8Ff,italics");		# PHP variable in double quoted string
 $_[0]->StyleSetSpec(127,"fore:#000000,back:#F8F8Ff");				# PHP operator
}

1;
