package syntaxhighlighter::sql;
$VERSION = '0.01';

sub load{    use Wx qw(wxSTC_LEX_SQL wxSTC_H_TAG);
    my $sql_keywords = 'absolute action add admin after aggregate \
alias all allocate alter and any are array as asc \
assertion at authorization \
before begin binary bit blob boolean both breadth by \
call cascade cascaded case cast catalog char character \
check class clob close collate collation column commit \
completion connect connection constraint constraints \
constructor continue corresponding create cross cube current \
current_date current_path current_role current_time current_timestamp \
current_user cursor cycle \
data date day deallocate dec decimal declare default \
deferrable deferred delete depth deref desc describe descriptor \
destroy destructor deterministic dictionary diagnostics disconnect \
distinct domain double drop dynamic \
each else end end-exec equals escape every except \
exception exec execute external \
false fetch first float for foreign found from free full \
function \
general get global go goto grant group grouping \
having host hour \
identity if ignore immediate in indicator initialize initially \
inner inout input insert int integer intersect interval \
into is isolation iterate \
join \
key \
language large last lateral leading left less level like \
limit local localtime localtimestamp locator \
map match minute modifies modify module month \
names national natural nchar nclob new next no none \
not null numeric \
object of off old on only open operation option \
or order ordinality out outer output \
pad parameter parameters partial path postfix precision prefix \
preorder prepare preserve primary \
prior privileges procedure public \
read reads real recursive ref references referencing relative \
restrict result return returns revoke right \
role rollback rollup routine row rows \
savepoint schema scroll scope search second section select \
sequence session session_user set sets size smallint some| space \
specific specifictype sql sqlexception sqlstate sqlwarning start \
state statement static structure system_user \
table temporary terminate than then time timestamp \
timezone_hour timezone_minute to trailing transaction translation \
treat trigger true \
under union unique unknown \
unnest update usage user using \
value values varchar variable varying view \
when whenever where with without work write \
year \
zone';

    $_[0]->SetLexer(wxSTC_LEX_SQL);            # Set Lexers to use
    $_[0]->SetKeyWords(0,$sql_keywords);
# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" );

    $_[0]->StyleSetSpec(0,"fore:#202020");					# White space
    $_[0]->StyleSetSpec(1,"fore:#bbbbbb");					# Comment
    $_[0]->StyleSetSpec(2,"fore:#cccccc)");					# Line Comment
    $_[0]->StyleSetSpec(3,"fore:#004000");					# Doc comment
    $_[0]->StyleSetSpec(4,"fore:#007f7f");					# Number
    $_[0]->StyleSetSpec(5,"fore:#7788bb,bold");					# Keyword
    $_[0]->StyleSetSpec(6,"fore:#555555,back:#ddeecc");			#  Doublequoted string
    $_[0]->StyleSetSpec(7,"fore:#555555,back:#eeeebb");			#  Single quoted string
    $_[0]->StyleSetSpec(8,"fore:#55ffff");					# Symbols
    $_[0]->StyleSetSpec(9,"fore:#228833");					# Preprocessor
    $_[0]->StyleSetSpec(10,"fore:#bb7799,bold");				# Operators
    $_[0]->StyleSetSpec(11,"fore:#778899");					# Identifiers
    $_[0]->StyleSetSpec(12,"fore:#000000,$(font.monospace),back:#E0C0E0,eolfilled");# End of line where string is not closed
}

1;