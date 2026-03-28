package Eshu;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Eshu', $VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Eshu - indentation fixer for C, Perl, XS, XML, HTML, CSS, JavaScript and POD source files

=head1 SYNOPSIS

	use Eshu;

	# Fix indentation for a specific language
	my $fixed_c    = Eshu->indent_c($source);
	my $fixed_pl   = Eshu->indent_pl($source);
	my $fixed_xs   = Eshu->indent_xs($source);
	my $fixed_xml  = Eshu->indent_xml($source);
	my $fixed_html = Eshu->indent_html($source);
	my $fixed_css  = Eshu->indent_css($source);
	my $fixed_js   = Eshu->indent_js($source);
	my $fixed_pod  = Eshu->indent_pod($source);

	# Auto-dispatch by language name
	my $fixed = Eshu->indent_string($source, lang => 'perl');

	# Use spaces instead of tabs
	my $fixed = Eshu->indent_c($source,
		indent_char  => ' ',
		indent_width => 4,
	);

	# Detect language from filename
	my $lang = Eshu->detect_lang('lib/Foo.pm');  # 'perl'

	# Fix a single file (read, detect, indent, optionally write back)
	my $result = Eshu->indent_file('lib/Foo.pm', fix => 1);

	# Fix an entire directory tree
	my $report = Eshu->indent_dir('lib/', fix => 1);

=head1 DESCRIPTION

Eshu is an XS-powered indentation fixer that rewrites leading whitespace in
C, Perl, XS, XML, HTML, CSS, JavaScript and POD source files. It tracks nesting depth and
re-emits each line with correct indentation while leaving the content of each
line untouched.

Eshu understands language-specific constructs that affect indentation:

=over 4

=item B<C> — strings, comments, preprocessor directives, block nesting

=item B<Perl> — heredocs, regex, C<qw()>/C<qq()>/C<q()>, C<s///>/C<tr///>/C<y///>, pod sections, comments

=item B<XS> — dual-mode scanning (C section above C<MODULE =>, XS section below), XSUB boundaries, label detection (C<CODE:>, C<OUTPUT:>, C<BOOT:>, etc.), C nesting within code body sections

=item B<XML> — element nesting, self-closing tags, C<< <!-- --> >> comments, C<< <![CDATA[...]]> >> sections, processing instructions, multi-line tags

=item B<HTML> — element nesting, void elements (C<br>, C<hr>, C<img>, etc.), verbatim content in C<< <script> >>, C<< <style> >>, and C<< <pre> >> blocks, comments

=item B<CSS> — rule-block brace nesting, C</* */> comments, string literals, C<url()> tokens, at-rules (C<@media>, C<@keyframes>, etc.)

=item B<JavaScript> — brace/paren/bracket nesting, double and single-quoted strings, template literals (C<`...${expr}...`>) with nested interpolation, regex literals (C</pattern/flags>), line and block comments. C<< <script> >> blocks in HTML are automatically indented as JS.

=item B<POD> — directive lines (C<=head1>, C<=over>, C<=item>, C<=back>, C<=cut>, etc.) normalised to column 0, text paragraphs at column 0, code examples (whitespace-leading lines) normalised to one indent level. POD sections embedded in Perl files are automatically processed.

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

=head2 indent_string

	my $out = Eshu->indent_string($source, lang => $lang, %opts);

Dispatch to the appropriate engine based on the C<lang> parameter:

=over 4

=item C<c> (default) — calls L</indent_c>

=item C<perl> or C<pl> — calls L</indent_pl>

=item C<xs> — calls L</indent_xs>

=item C<xml>, C<xsl>, C<xslt>, C<svg>, C<xhtml> — calls L</indent_xml> in XML mode

=item C<html>, C<htm>, C<tmpl>, C<tt>, C<ep> — calls L</indent_xml> in HTML mode

=item C<css>, C<scss>, C<less> — calls L</indent_css>

=item C<js>, C<javascript>, C<jsx>, C<ts>, C<typescript>, C<tsx>, C<mjs>, C<cjs>, C<mts> — calls L</indent_js>

=item C<pod> — calls L</indent_pod>

=back

=head2 detect_lang

	my $lang = Eshu->detect_lang($filename);

Return a language string based on the file extension, suitable for passing
to L</indent_string>. Returns C<undef> for unrecognised extensions.

	.c, .h                       → 'c'
	.xs                          → 'xs'
	.pl, .pm, .t                 → 'perl'
	.xml, .xsl, .xslt, .svg     → 'xml'
	.xhtml                       → 'xhtml'
	.html, .htm, .tmpl, .tt, .ep → 'html'
	.css, .scss, .less           → 'css'
	.js, .jsx, .mjs, .cjs       → 'js'
	.ts, .tsx, .mts              → 'js'
	.pod                         → 'pod'

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
