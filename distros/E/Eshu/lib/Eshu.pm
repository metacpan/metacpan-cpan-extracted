package Eshu;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.09';

require XSLoader;
XSLoader::load('Eshu', $VERSION);

sub include_dir {
    my $dir = $INC{'Eshu.pm'};
    $dir =~ s{Eshu\.pm$}{Eshu/include};
    return $dir;
}

1;

__END__

=encoding utf8

=head1 NAME

Eshu - indentation fixer and syntax highlighter for C, Perl, XS, XML, HTML,
CSS, JavaScript, TypeScript, Python, Go, Rust, Java, PHP, Ruby, Lua, Bash,
SQL, YAML, JSON, POD and more

=head1 SYNOPSIS

	use Eshu;

	# Fix indentation — one method per language
	my $fixed_c      = Eshu->indent_c($source);
	my $fixed_pl     = Eshu->indent_pl($source);
	my $fixed_xs     = Eshu->indent_xs($source);
	my $fixed_xml    = Eshu->indent_xml($source);
	my $fixed_html   = Eshu->indent_html($source);
	my $fixed_css    = Eshu->indent_css($source);
	my $fixed_js     = Eshu->indent_js($source);
	my $fixed_ts     = Eshu->indent_ts($source);
	my $fixed_pod    = Eshu->indent_pod($source);
	my $fixed_bash   = Eshu->indent_bash($source);
	my $fixed_go     = Eshu->indent_go($source);
	my $fixed_lua    = Eshu->indent_lua($source);
	my $fixed_rust   = Eshu->indent_rust($source);
	my $fixed_py     = Eshu->indent_python($source);
	my $fixed_java   = Eshu->indent_java($source);
	my $fixed_php    = Eshu->indent_php($source);
	my $fixed_ruby   = Eshu->indent_ruby($source);
	my $fixed_json   = Eshu->indent_json($source);
	my $fixed_sql    = Eshu->indent_sql($source);
	my $fixed_yaml   = Eshu->indent_yaml($source);

	# Auto-dispatch by language name
	my $fixed = Eshu->indent_string($source, lang => 'perl');

	# Use spaces instead of tabs
	my $fixed = Eshu->indent_c($source,
		indent_char  => ' ',
		indent_width => 4,
	);

	# Syntax highlight — returns HTML with <span class="esh-X"> tokens
	my $html = Eshu->highlight_string($source, lang => 'perl');
	my $html = Eshu->highlight_ts($source);
	my $html = Eshu->highlight_java($source);
	my $html = Eshu->highlight_php($source);
	my $html = Eshu->highlight_ruby($source);
	my $html = Eshu->highlight_json($source);
	my $html = Eshu->highlight_sql($source);
	my $html = Eshu->highlight_go($source);
	my $html = Eshu->highlight_lua($source);
	my $html = Eshu->highlight_rust($source);
	my $html = Eshu->highlight_bash($source);
	my $html = Eshu->highlight_yaml($source);

	# Detect language from filename
	my $lang = Eshu->detect_lang('lib/Foo.pm');  # 'perl'

	# Fix a single file (read, detect, indent, optionally write back)
	my $result = Eshu->indent_file('lib/Foo.pm', fix => 1);

	# Fix an entire directory tree
	my $report = Eshu->indent_dir('lib/', fix => 1);

=head1 DESCRIPTION

Eshu is an XS-powered indentation fixer and syntax highlighter. The
indentation engine rewrites leading whitespace, tracking nesting depth and
re-emitting each line with correct indentation while leaving content
untouched. The highlighting engine wraps recognised tokens in HTML
C<< <span class="esh-X"> >> elements.

Supported languages: C, Perl, XS, XML, HTML, CSS, JavaScript, TypeScript,
Python, Go, Rust, Java, PHP, Ruby, Lua, Bash, SQL, YAML, JSON, POD.

Eshu understands language-specific constructs that affect indentation:

=over 4

=item B<C> — strings, comments, preprocessor directives, block nesting

=item B<Perl> — heredocs, regex, C<qw()>/C<qq()>/C<q()>, C<s///>/C<tr///>/C<y///>, pod sections, comments

=item B<XS> — dual-mode scanning (C section above C<MODULE =>, XS section below), XSUB boundaries, label detection (C<CODE:>, C<OUTPUT:>, C<BOOT:>, etc.), C nesting within code body sections

=item B<XML> — element nesting, self-closing tags, C<< <!-- --> >> comments, C<< <![CDATA[...]]> >> sections, processing instructions, multi-line tags

=item B<HTML> — element nesting, void elements (C<br>, C<hr>, C<img>, etc.), verbatim content in C<< <script> >>, C<< <style> >>, and C<< <pre> >> blocks, comments

=item B<CSS> — rule-block brace nesting, C</* */> comments, string literals, C<url()> tokens, at-rules (C<@media>, C<@keyframes>, etc.)

=item B<JavaScript> — brace/paren/bracket nesting, double and single-quoted strings, template literals (C<`...${expr}...`>) with nested interpolation, regex literals (C</pattern/flags>), line and block comments. C<< <script> >> blocks in HTML are automatically indented as JS.

=item B<TypeScript> — same engine as JavaScript; C<.ts>/C<.tsx>/C<.mts> files are detected automatically.

=item B<Python> — indentation-significant; reads logical depth from existing whitespace (depth stack), re-emits with configured style. Continuation lines (backslash or open bracket) are tracked. Strings (C<"...">, C<'...'>, triple-quoted), C<#> comments, and decorator lines (C<@name>) are recognised.

=item B<Go> — C<{}>, C<()>, C<[]> brace/paren/bracket nesting, interpreted strings C<"...">, raw string literals (backtick, can span multiple lines), rune literals C<'.'>, C<//> line comments, C</* */> block comments, C<case>/C<default> labels placed at switch-brace level, and all Go numeric literals (decimal, hex C<0x>, binary C<0b>, octal C<0o>, C<_> separators, imaginary C<i> suffix).

=item B<Rust> — brace-based model identical to Go; nested C</* */> block comments, raw strings C<r"...">/C<r#"..."#>, byte strings C<b"...">, byte chars C<b'.'>, and lifetime annotations C<'a> (distinguished from char literals).

=item B<Java> — brace/paren/bracket nesting, strings (double-quoted, text blocks C<"""...""">), char literals, C<//> and C</* */> comments, C<@Annotation> handling, and C<switch> case-label de-indentation.

=item B<PHP> — brace-based nesting, C<$variable> tracking, C<//>/C<#>/C</* */> comments, heredoc/nowdoc (C<<<EOT>/C<<<'EOT'>), single and double-quoted strings, C<#[Attribute]> blocks.

=item B<Ruby> — brace/paren/bracket nesting plus keyword blocks (C<def>/C<end>, C<do>/C<end>, C<class>/C<end>, etc.), heredocs (C<<<~HEREDOC>), single and double-quoted strings, regex literals, C<#> comments.

=item B<Lua> — keyword-based block nesting (C<do>/C<end>, C<if>/C<then>/C<end>, C<function>/C<end>, C<repeat>/C<until>, C<else>/C<elseif> transitions), table constructor C<{}> brace tracking, long strings C<[[...]]>/C<[=[...]=]> and long comments C<--[[...]]> spanning multiple lines, C<"...">/C<'...'> strings, and C<--> line comments.

=item B<Bash> — keyword-pair blocks (C<if>/C<fi>, C<for>/C<done>, C<while>/C<done>, C<until>/C<done>, C<case>/C<esac>, C<select>/C<done>), brace grouping C<{ }>, C<function> keyword, heredocs (C<<<EOF>>, C<<<-EOF>>), C<$( )> subshell and C<$(( ))> arithmetic depth tracking, single and double-quoted strings, C<$'...'> ANSI-C strings, and C<#> comments.

=item B<SQL> — keyword-based clause indentation (C<SELECT>/C<FROM>/C<WHERE>/C<JOIN>/C<GROUP BY>/C<ORDER BY>/C<HAVING>/C<UNION> etc.), C<CASE>/C<WHEN>/C<THEN>/C<ELSE>/C<END> expression tracking, PL/pgSQL C<BEGIN>/C<END> blocks, C<-->/C</* */> comments, single-quoted strings. Case-insensitive.

=item B<YAML> — reads logical depth from existing leading whitespace (depth stack identical to Python engine), re-emits with configured style (default: 2-space). Block scalar bodies (C<|> and C<E<gt>>) are re-normalised. Document markers (C<--->/C<...>) reset the depth stack.

=item B<JSON> — structural formatting of C<{}>/ C<[]> nesting; no language-specific constructs beyond brace tracking and string recognition.

=item B<POD> — directive lines (C<=head1>, C<=over>, C<=item>, C<=back>, C<=cut>, etc.) normalised to column 0, text paragraphs at column 0, verbatim blocks (whitespace-leading lines) normalised to one indent level. POD sections embedded in Perl files are automatically processed.

=back

The engine is written in C for speed and operates as a single-pass
line-by-line scanner.

The Eshu distribution also includes a command-line tool (C<eshu>) that can fix
files in-place, preview changes as a diff, or run in CI check mode. It supports
recursive directory processing with file inclusion/exclusion patterns and automatic
language detection by extension. There is also a vim plugin (C<eshu.vim>) that can
fix the open file or a selected 'visual' range.

=head1 METHODS

=head2 indent_c

	my $out = Eshu->indent_c($source, %opts);

Fix indentation of C source code. Tracks C<{}>, C<()>, C<[]> nesting,
handles C strings, character literals, line and block comments, and
preprocessor directives.

=head2 indent_pl

	my $out = Eshu->indent_pl($source, %opts);

Fix indentation of Perl source code. In addition to brace nesting, handles
heredocs (C<< <<EOF >>, C<< <<~EOF >>, C<< <<'EOF' >>, C<< <<"EOF" >>),
regex literals, C<qw()>/C<qq()>/C<q()> constructs with paired and non-paired
delimiters, multi-section operators (C<s///>, C<tr///>, C<y///>), pod
sections (C<=head1> through C<=cut>), and line comments.

=head2 indent_xs

	my $out = Eshu->indent_xs($source, %opts);

Fix indentation of XS source files. Operates in dual mode: lines above the
first C<MODULE = ...> line are processed as C; lines below are processed as
XS with XSUB boundary detection, label recognition, and C nesting tracking
within code body sections. C<BOOT:> sections use a shallower indentation
depth than other labels.

=head2 indent_xml

	my $out = Eshu->indent_xml($source, %opts);

Fix indentation of XML source. Tracks element nesting via opening and
closing tags, handles self-closing tags (C<< <br/> >>), comments
(C<< <!-- --> >>), CDATA sections, and processing instructions
(C<< <?...?> >>). Multi-line tags are indented one level beyond the
opening tag.

Also used for HTML when called via C<indent_string> with C<lang =E<gt> 'html'>.
In HTML mode, void elements (C<br>, C<hr>, C<img>, C<input>, C<meta>,
C<link>, etc.) are treated as self-closing, and content inside
C<< <script> >>, C<< <style> >>, and C<< <pre> >> blocks is passed through verbatim.
C<< <script> >> blocks are indented with the JavaScript engine.

=head2 indent_html

	my $out = Eshu->indent_html($source, %opts);

Fix indentation of HTML source. This is a convenience method equivalent to
calling C<< Eshu->indent_xml($source, lang => 'html', %opts) >>. Void
elements (C<br>, C<hr>, C<img>, C<input>, C<meta>, C<link>, etc.) are
treated as self-closing. C<< <script> >> blocks are indented with the
JavaScript engine, while C<< <style> >> and C<< <pre> >> content is
passed through verbatim.

=head2 indent_css

	my $out = Eshu->indent_css($source, %opts);

Fix indentation of CSS, SCSS, and LESS source. Tracks brace nesting for
rule blocks and at-rules (C<@media>, C<@keyframes>, C<@supports>, etc.),
handles C</* */> block comments, string literals (single and double-quoted),
and C<url()> tokens with unquoted paths.

=head2 indent_js

	my $out = Eshu->indent_js($source, %opts);

Fix indentation of JavaScript (and TypeScript) source. Tracks C<{}>, C<()>,
C<[]> nesting, handles double-quoted strings, single-quoted strings,
template literals (backtick strings with C<${expr}> interpolation), regex
literals (C</pattern/flags>) with character class support, line comments
(C<//>) and block comments (C</* */>). Multi-line template literal content
is preserved verbatim (whitespace is significant).

=head2 indent_pod

	my $out = Eshu->indent_pod($source, %opts);

Fix indentation of POD (Plain Old Documentation). Directive lines
(C<=head1>, C<=head2>, C<=over>, C<=item>, C<=back>, C<=cut>, C<=pod>,
C<=begin>, C<=end>, C<=for>, C<=encoding>) are normalised to column 0.
Text paragraphs stay at column 0. Code examples (lines with leading
whitespace) are normalised to one indent level. POD sections embedded
in Perl source files are automatically processed by the Perl engine.

=head2 indent_bash

	my $out = Eshu->indent_bash($source, %opts);

Fix indentation of Bash/shell scripts. Tracks keyword-pair block depth
(C<if>/C<fi>, C<for>/C<done>, C<while>/C<done>, C<until>/C<done>,
C<case>/C<esac>, C<select>/C<done>) and brace grouping C<{ }>.

Handles C<then>/C<do> as deferred openers (depth increases for the next
line). Handles C<else>/C<elif> as combined -1/+1 transitions. C<case>
patterns (the C<PATTERN)> lines) are at one indent level inside the
C<case/in> block; their bodies are indented one further level; C<;;>
closes each arm.

Strings (single-quoted C<'...'>, double-quoted C<"...">, C<$'...'> ANSI-C),
heredoc bodies, C<$( )> subshells, C<$(( ))> arithmetic, and C<# ...>
comments are all recognised and their contents are not scanned for
keywords.

=head2 highlight_bash

	my $html = Eshu->highlight_bash($source);

Syntax-highlight Bash/shell source.

=head2 indent_go

	my $out = Eshu->indent_go($source, %opts);

Fix indentation of Go source code. Tracks C<{}>, C<()>, C<[]> nesting
and handles C<case>/C<default> labels (placed one level shallower than
their body, matching C<gofmt> output), interpreted strings C<"...">,
raw string literals (backtick, spanning any number of lines), rune
literals C<'.'>, C<//> line comments, and C</* */> block comments.

=head2 highlight_go

	my $html = Eshu->highlight_go($source);

Syntax-highlight Go source. Returns an HTML string with token spans.
Recognises keywords (C<esh-k>), predeclared functions and types
(C<esh-b>), strings (C<esh-s>, covers interpreted, raw, and rune
literals), comments (C<esh-c>), and numbers (C<esh-n>, covers decimal,
hex C<0x>, binary C<0b>, octal C<0o>, underscored separators, and
imaginary C<i> suffix).

=head2 indent_lua

	my $out = Eshu->indent_lua($source, %opts);

Fix indentation of Lua source code. Uses keyword-based block nesting:
C<do>/C<then>/C<function> open a new indent level on the next line,
C<end>/C<until> close the level on their own line, and C<else>/C<elseif>
transition (-1 then +1). Table constructors C<{}> are also tracked.
Long strings C<[[...]]>/C<[=[...]=]> and long comments C<--[[...]]> that
span multiple lines are emitted verbatim.

=head2 highlight_lua

	my $html = Eshu->highlight_lua($source);

Syntax-highlight Lua source. Returns an HTML string with token spans.
Recognises keywords (C<esh-k>), standard library functions and tables
(C<esh-b>), strings including long strings (C<esh-s>), comments
including long comments (C<esh-c>), and numbers (C<esh-n>, covers
decimal, float, and hex C<0x> literals).

=head2 indent_rust

	my $out = Eshu->indent_rust($source, %opts);

Fix indentation of Rust source code. Uses a brace-based model identical to
Go: C<{> opens a new indent level (deferred to the next line), C<}> closes on
its own line, and C<()/[]> are also tracked for depth balance. Additional
Rust constructs handled: nested C</* */> block comments, raw strings
C<r"...">/C<r#"..."#>, byte strings C<b"...">, byte chars C<b'.'>, and
lifetime annotations C<'a> (distinguished from char literals to avoid
misinterpreting them as string openers).

=head2 highlight_rust

	my $html = Eshu->highlight_rust($source);

Syntax-highlight Rust source. Returns an HTML string with token spans.
Recognises keywords (C<esh-k> — C<fn>, C<let>, C<match>, C<impl>, etc.),
builtin types and traits (C<esh-b> — C<i32>, C<String>, C<Vec>, C<Option>,
etc.), strings and char literals (C<esh-s>), comments including nested block
comments (C<esh-c>), numbers (C<esh-n>), attributes C<#[...]> (C<esh-p>),
and lifetime annotations (C<esh-b>). Common macros such as C<println!> and
C<vec!> are highlighted as builtins.

=head2 indent_yaml

	my $out = Eshu->indent_yaml($source, %opts);

Normalise YAML indentation. YAML uses indentation-significant structure, so
this pass reads the logical depth from existing leading whitespace (using a
depth stack identical to the Python engine) and re-emits each line with the
configured style. Defaults: C<indent_char=' '>, C<indent_width=2>.

Block scalar bodies (C<|> and C<E<gt>>) are re-normalised at the correct
depth (key_depth+1) while preserving any relative indentation within the
block. Flow collections (C<{ }> and C<[ ]>) that span lines are emitted
verbatim. Document markers (C<--->/C<...>) are emitted at depth 0 and reset
the depth stack for the next document.

=head2 highlight_yaml

	my $html = Eshu->highlight_yaml($source);

Syntax-highlight YAML source. Returns an HTML string with token spans.
Token classes: C<esh-a> (mapping keys), C<esh-v> (anchors C<&name> and
aliases C<*name>), C<esh-p> (tags C<!!/!tag> and directives C<%YAML/%TAG>),
C<esh-k> (document markers C<--->/C<...>, booleans, null, sequence C<->),
C<esh-s> (quoted strings), C<esh-n> (numbers), C<esh-h> (block scalar body
lines), C<esh-c> (comments).

=head2 indent_ts

	my $out = Eshu->indent_ts($source, %opts);

Fix indentation of TypeScript source. Uses the same engine as
L</indent_js>: C<{}>, C<()>, C<[]> nesting, string literals, template
literals, regex literals, and line/block comments. TypeScript-specific
syntax (type annotations, decorators, generics) is transparent to the
indentation pass.

=head2 indent_python

	my $out = Eshu->indent_python($source, %opts);

Fix indentation of Python source. Reads the logical depth from existing
leading whitespace (using a depth stack), and re-emits each line with
the configured indent style. Defaults: C<indent_char=' '>,
C<indent_width=4>. Continuation lines (trailing backslash or unclosed
bracket/paren) are tracked. Strings (C<"...">, C<'...'>, triple-quoted
C<"""...""">/C<'''...'''>), C<#> comments, and C<@decorator> lines are
recognised and their content is not scanned for indentation signals.

=head2 indent_java

	my $out = Eshu->indent_java($source, %opts);

Fix indentation of Java source. Tracks C<{}>, C<()>, C<[]> nesting,
handles double-quoted strings, text blocks (C<"""...""">), char literals,
C<//> line comments, C</* */> block comments, and C<@Annotation>
lines. C<switch> case labels are placed one level shallower than their
body.

=head2 indent_php

	my $out = Eshu->indent_php($source, %opts);

Fix indentation of PHP source. Tracks brace/paren/bracket nesting,
handles C<$variable> sigils (so C<{> inside strings is not counted),
single and double-quoted strings, heredoc/nowdoc bodies, C<//>/C<#> line
comments, and C</* */> block comments.

=head2 indent_ruby

	my $out = Eshu->indent_ruby($source, %opts);

Fix indentation of Ruby source. Tracks both brace/paren/bracket nesting
and keyword-pair blocks (C<def>/C<end>, C<do>/C<end>, C<class>/C<end>,
C<module>/C<end>, C<if>/C<end>, etc.). Handles single and double-quoted
strings, heredocs (C<<<~HEREDOC>), regex literals, and C<#> comments.

=head2 indent_json

	my $out = Eshu->indent_json($source, %opts);

Fix indentation of JSON source. Tracks C<{}> and C<[]> nesting and
re-emits each value on its own line with the configured indent style.
Defaults: C<indent_char=' '>, C<indent_width=2>. String values and
keys are passed through verbatim without scanning for structural
characters.

=head2 indent_sql

	my $out = Eshu->indent_sql($source, %opts);

Fix indentation of SQL source. Uses a keyword-based clause model:
primary clause keywords (C<SELECT>, C<FROM>, C<WHERE>, C<JOIN>, C<GROUP
BY>, C<ORDER BY>, C<HAVING>, C<UNION>, C<INSERT INTO>, C<UPDATE>,
C<DELETE FROM>) each start at the base indent level. C<CASE>/C<WHEN>/C<THEN>/C<ELSE>/C<END>
expressions are tracked separately with their own nesting depth.
PL/pgSQL C<BEGIN>/C<END> blocks add an outer level. C<--> line and
C</* */> block comments, single-quoted strings (with C<''> escape), and
quoted identifiers (C<"...">, C<[...]>, backtick) are recognised.
Matching is case-insensitive.

=head2 highlight_ts

	my $html = Eshu->highlight_ts($source);

Syntax-highlight TypeScript source. Recognises all JavaScript tokens
plus TypeScript-specific keywords (C<interface>, C<type>, C<enum>,
C<namespace>, C<declare>, C<abstract>, C<readonly>, C<override>,
C<keyof>, C<typeof>, C<infer>, C<satisfies>, C<as>, C<is>, C<from>,
C<implements>, type primitives and modifiers), utility type builtins
(C<Partial>, C<Required>, C<Record>, C<Pick>, C<Omit>, C<Awaited>,
etc.), and decorator expressions (C<@Name>) (C<esh-p>).

=head2 highlight_java

	my $html = Eshu->highlight_java($source);

Syntax-highlight Java source. Recognises keywords (C<esh-k>), standard
library types (C<esh-b> — C<String>, C<Integer>, C<System>, C<Math>,
C<StringBuilder>, etc.), annotation names C<@Override>/C<@Deprecated>/etc.
(C<esh-p>), strings and char literals (C<esh-s>), comments (C<esh-c>),
and numbers (C<esh-n>).

=head2 highlight_php

	my $html = Eshu->highlight_php($source);

Syntax-highlight PHP source. Recognises keywords (C<esh-k>), builtin
functions and classes (C<esh-b> — C<strlen>, C<array_map>,
C<json_encode>, C<Exception>, C<DateTime>, C<PDO>, etc.), PHP 8
attribute blocks C<#[...]> (C<esh-p>), variables C<$name> (C<esh-p>),
strings (C<esh-s>), C<//>/C<#>/C</* */> comments (C<esh-c>), and
numbers (C<esh-n>).

=head2 highlight_ruby

	my $html = Eshu->highlight_ruby($source);

Syntax-highlight Ruby source. Recognises keywords (C<esh-k>), builtin
methods and module functions (C<esh-b> — C<puts>, C<require>,
C<attr_accessor>, C<private>, C<lambda>, etc.), symbols C<:name> and
C<:"...">) (C<esh-r>), global/instance/class variables (C<esh-v>),
strings (C<esh-s>), C<#> comments (C<esh-c>), and numbers (C<esh-n>).

=head2 highlight_json

	my $html = Eshu->highlight_json($source);

Syntax-highlight JSON source. Object keys are tagged C<esh-a>, string
values C<esh-s>, C<null>/C<true>/C<false> keywords C<esh-k>, and
numbers C<esh-n>. When called via C<highlight_string> with
C<lang =E<gt> 'jsonc'>, C<//> and C</* */> comments (C<esh-c>) are
also recognised.

=head2 highlight_sql

	my $html = Eshu->highlight_sql($source);

Syntax-highlight SQL source. Recognises keywords (C<esh-k>), aggregate
and window functions (C<esh-b> — C<COUNT>, C<SUM>, C<AVG>, C<ROW_NUMBER>,
C<RANK>, etc.), single-quoted strings (C<esh-s>), quoted identifiers
(C<esh-a>), C<-->/C</* */> comments (C<esh-c>), and numbers (C<esh-n>).
Matching is case-insensitive.

=head2 indent_string

	my $out = Eshu->indent_string($source, lang => $lang, %opts);

Dispatch to the appropriate engine based on the C<lang> parameter:

=over 4

=item C<c>, C<h> (default) — calls L</indent_c>

=item C<perl>, C<pl>, C<pm>, C<t> — calls L</indent_pl>

=item C<xs> — calls L</indent_xs>

=item C<xml>, C<xsl>, C<xslt>, C<svg>, C<xhtml> — calls L</indent_xml> in XML mode

=item C<html>, C<htm>, C<tmpl>, C<tt>, C<ep> — calls L</indent_xml> in HTML mode

=item C<css>, C<scss>, C<less> — calls L</indent_css>

=item C<js>, C<javascript>, C<jsx>, C<mjs>, C<cjs> — calls L</indent_js>

=item C<ts>, C<typescript>, C<tsx>, C<mts> — calls L</indent_ts>

=item C<python>, C<py> — calls L</indent_python>

=item C<java> — calls L</indent_java>

=item C<php>, C<phtml> — calls L</indent_php>

=item C<ruby>, C<rb>, C<rake> — calls L</indent_ruby>

=item C<json>, C<jsonc> — calls L</indent_json>

=item C<pod> — calls L</indent_pod>

=item C<bash>, C<sh>, C<shell>, C<zsh>, C<ksh> — calls L</indent_bash>

=item C<go> — calls L</indent_go>

=item C<rust>, C<rs> — calls L</indent_rust>

=item C<lua> — calls L</indent_lua>

=item C<sql>, C<psql>, C<ddl> — calls L</indent_sql>

=item C<yaml>, C<yml> — calls L</indent_yaml>

=back

=head2 include_dir

	my $dir = Eshu->include_dir();

Returns the path to the Eshu C header directory. Useful for sibling modules
that need to compile against C<eshu_hl.h> or other Eshu headers without
copying them — add the returned path to C<INC> in your C<Makefile.PL>:

	eval { require Eshu; $eshu_inc = Eshu->include_dir() };
	$eshu_inc //= '../Eshu-0.09/include';  # development fallback

=head2 highlight_string

	my $html = Eshu->highlight_string($source, lang => $lang);

Syntax-highlight C<$source> for the given language and return an HTML string
where recognised tokens are wrapped in C<< <span class="esh-X"> >> elements.
The returned string is HTML-safe (C<< < >> C<< > >> C<< & >> C<< " >> are
escaped throughout). Unknown C<lang> values fall back to HTML-escaping only
(no spans).

C<lang> accepts:

=over 4

=item C<c> or C<h> — C/C++ (default)

=item C<perl>, C<pl>, C<pm>, C<t> — Perl

=item C<js>, C<javascript>, C<jsx>, C<mjs>, C<cjs> — JavaScript

=item C<ts>, C<typescript>, C<tsx>, C<mts> — TypeScript (calls L</highlight_ts>)

=item C<css>, C<scss>, C<less> — CSS / Sass / Less

=item C<xml>, C<html>, C<htm>, C<svg>, C<xhtml> — XML / HTML

=item C<pod> — POD (verbatim blocks sub-highlighted as Perl)

=item C<python>, C<py> — Python

=item C<json>, C<jsonc> — JSON (C<jsonc> also highlights comments)

=item C<bash>, C<sh>, C<shell>, C<zsh>, C<ksh> — Bash / shell

=item C<go> — Go

=item C<rust>, C<rs> — Rust

=item C<java> — Java

=item C<lua> — Lua

=item C<php>, C<phtml> — PHP

=item C<ruby>, C<rb>, C<rake> — Ruby

=item C<sql>, C<psql>, C<ddl> — SQL

=item C<yaml>, C<yml> — YAML

=back

Token CSS classes:

=over 4

=item C<esh-k> — keyword

=item C<esh-s> — string / quoted literal

=item C<esh-c> — comment

=item C<esh-n> — number literal

=item C<esh-p> — preprocessor directive (C/XS) or at-rule (CSS)

=item C<esh-r> — regex or quoted-like construct (Perl)

=item C<esh-h> — heredoc body (Perl)

=item C<esh-v> — variable sigil and name (Perl: C<$foo>, C<@bar>, C<%baz>)

=item C<esh-d> — documentation (POD command line)

=item C<esh-g> — tag name (XML/HTML)

=item C<esh-a> — attribute name (XML/HTML)

=back

=head2 detect_lang

	my $lang = Eshu->detect_lang($filename);

Return a language string based on the file extension, suitable for passing
to L</indent_string>. Returns C<undef> for unrecognised extensions.

	.c, .h                                → 'c'
	.xs                                   → 'xs'
	.pl, .pm, .t                          → 'perl'
	.xml, .xsl, .xslt, .svg              → 'xml'
	.xhtml                                → 'xhtml'
	.html, .htm, .tmpl, .tt, .ep         → 'html'
	.css, .scss, .less                    → 'css'
	.js, .jsx, .mjs, .cjs                → 'js'
	.ts, .tsx, .mts                       → 'ts'
	.json, .jsonc                         → 'json'
	.java                                 → 'java'
	.php, .phtml, .php3, .php4, .php5    → 'php'
	.rb, .rake                            → 'ruby'
	.pod                                  → 'pod'
	.sh, .bash, .zsh, .ksh               → 'bash'
	.go                                   → 'go'
	.rs                                   → 'rust'
	.lua                                  → 'lua'
	.sql, .psql, .ddl                     → 'sql'
	.yaml, .yml                           → 'yaml'

=head2 indent_file

	my $result = Eshu->indent_file($path, %opts);

Read a single file, detect its language, run the indentation fixer, and
optionally write the result back. Returns a hashref:

	{
		file   => $path,
		status => 'changed',      # or 'unchanged', 'needs_fixing',
					   #    'skipped', 'error'
		lang   => 'perl',
		diff   => '...',           # only if diff => 1
		reason => '...',           # only if status is 'skipped'
		error  => '...',           # only if status is 'error'
	}

Files are skipped if they are over 1 MB, contain NUL bytes in the first
8 KB (binary detection), or have an unrecognised extension.

Options: all L</OPTIONS> keys plus C<fix>, C<diff>, and C<lang>.

=head2 indent_dir

	my $report = Eshu->indent_dir($path, %opts);

Recursively walk a directory, detect languages by extension, and fix
indentation for all recognised files. Returns a report hashref:

	{
		files_checked => 42,
		files_changed => 7,
		files_skipped => 3,
		files_errored => 0,
		changes       => [ ... ],   # array of indent_file results
	}

Options: all L</OPTIONS> keys plus:

=over 4

=item B<fix> — write changes back to disk (default: dry-run)

=item B<diff> — include diff output in each result

=item B<recursive> — recurse into subdirectories (default: 1)

=item B<exclude> — regexp or arrayref of regexps; skip files matching any

=item B<include> — regexp or arrayref of regexps; only process files matching at least one

=item B<lang> — force a language for all files instead of auto-detecting

=back

Symlinks to files are followed; symlinks to directories are not (to avoid
cycles).

=head1 OPTIONS

All indentation methods accept the following options as key-value pairs:

=over 4

=item B<indent_char>

Character to use for indentation. Either C<"\t"> (tab, the default) or
C<" "> (space).

=item B<indent_width>

Number of characters per indentation level. Defaults to C<1> for tabs.
Typically set to C<2> or C<4> when using spaces.

=item B<indent_pp>

Boolean. When true, indent C preprocessor directives according to their
C<#if>/C<#endif> nesting depth. Defaults to C<0> (preprocessor directives
stay at column 0). Only meaningful for C and XS engines.

=back

=head1 CLI

Eshu ships with a command-line tool:

	# Fix a file in-place
	eshu --fix lib/Foo.pm

	# Preview changes as a diff
	eshu --diff lib/Foo.pm

	# CI check — exit 1 if file would change
	eshu --check lib/Foo.pm

	# Read stdin, write stdout
	cat messy.c | eshu --lang c

	# Use 4-space indentation
	eshu --spaces 4 --fix src/bar.c

	# Fix all recognised files in a directory tree
	eshu --fix lib/

	# Fix only Perl files, excluding backups
	eshu --fix --include '\.pm$' --exclude '\.bak$' lib/

	# Verbose output showing every file processed
	eshu --fix --verbose lib/

Run C<eshu --help> for the full list of options.

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
