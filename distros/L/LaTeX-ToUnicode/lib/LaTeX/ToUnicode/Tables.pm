package LaTeX::ToUnicode::Tables;
BEGIN {
  $LaTeX::ToUnicode::Tables::VERSION = '0.54';
}
use strict;
use warnings;
#ABSTRACT: Character tables for LaTeX::ToUnicode

use utf8; # just for the german support

# Technically not all of these are ligatures, but close enough.
# Order is important, so has to be a list, not a hash.
# 
our @LIGATURES = (
    "---" => '\x{2014}', # em dash
    "--"  => '\x{2013}', # en dash
    "!`"  => '\x{00A1}', # inverted exclam
    "?`"  => '\x{00A1}', # inverted question
    "``"  => '\x{201c}', # left double
    "''"  => '\x{201d}', # right double
    "`"   => '\x{2018}', # left single
    "'"   => '\x{2019}', # right single
);
# test text: em---dash, en--dash, exc!`am, quest?`ion, ``ld, rd'', `ls, rs'.
#
# Some additional ligatures supported in T1 encoding, but we won't (from
# tex-text.map):
# U+002C U+002C <> U+201E  ; ,, -> DOUBLE LOW-9 QUOTATION MARK
# U+003C U+003C <> U+00AB  ; << -> LEFT POINTING GUILLEMET
# U+003E U+003E <> U+00BB  ; >> -> RIGHT POINTING GUILLEMET

#  for {\MARKUP(shape) ...} and \textMARKUP{...}; although not all
# command names are defined in LaTeX for all markups, we translate them
# anyway. Also, LaTeX has more font axes not included here: md, ulc, sw,
# ssc, etc. See ltfntcmd.dtx and ltfssaxes.dtx if we ever want to try
# for completeness.
# 
our %MARKUPS = (
    'bf'  => 'b',
    'cal' => '',
    'em'  => 'em',
    'it'  => 'i',
    'rm'  => '',
    'sc'  => '', # qqq should uppercasify
    'sf'  => '',
    'sl'  => 'i',
    'small' => '',
    'subscript'    => 'sub',
    'superscript'  => 'sup',
    'tt'  => 'tt',
);

# More commands taking arguments that we want to handle.
# 
our %ARGUMENT_COMMANDS = (
    'emph'      => ['\textem{', '}'], # \textem doesn't exist, but we handle it
    'enquote'   => ["`",        "'"],
    'path'      => ['\texttt{', '}'], # ugh, might not be a braced argument
);

#  Non-alphabetic \COMMANDs, other than accents and special cases.
# 
our %CONTROL_SYMBOLS = (
    ' '  => ' ', # control space
    "\t" => ' ', # control space
    "\n" => '\x{0020}', # control space; use entity to avoid being trimmed
    '!'  => '',  # negative thin space
   # " umlaut
    '#'  => '#', # sharp sign
    '$'  => '$', # dollar sign
    '%'  => '%', # percent sign
    '&'  => '\x{0026}', # ampersand, entity to avoid html conflict
   # ' acute accent
    '('  => '',  # start inline math
    ')'  => '',  # end inline math
    '*'  => '',  # discretionary multiplication
    '+'  => '',  # tabbing: tab stop to right
    ','  => '',  # thin space
    '-'  => '',  # discretionary hyphenation
   # . overdot accent
    '/'  => '',  # italic correction
   # 0..9 undefined
    ':'  => '',  # medium space
    ';'  => ' ', # thick space
    '<'  => '',  # tabbing: text to left of margin
   # = macron accent
    '>'  => '',  # tabbing: next tab stop
   # ? undefined
    '@'  => '#', # end of sentence
   # A..Z control words, not symbols
    '['  => '',  # start display math
    '\\' => ' ', # line break
    ']'  => '',  # end display math
   # ^ circumflex accent
    '_'  => '_', # underscore
   # ` grave accent
   # a..z control words, not symbols
    '{'  => '\x{007b}', # lbrace
    '|'  => '\x{2225}', # parallel
    '}'  => '\x{007d}', # rbrace
   # ~ tilde accent
);

#  Alphabetic \COMMANDs that map to nothing. This is simply
# interpolated into %CONTROL_WORDS (next), not used directly, so we
# redundantly specify the '' on every line.
# 
our %CONTROL_WORDS_EMPTY = (
    'begingroup'    => '',
    'bgroup'        => '',
    'checkcomma'    => '',
    #'cite'          => '', # keep \cite undefined since it needs manual work
    'clearpage'     => '',
    'doi'           => '',
    'egroup'        => '',
    'endgroup'      => '',
    'ensuremath'    => '',
    'hbox'          => '',
    'ignorespaces'  => '',
    'mbox'          => '',
    'medspace'      => '',
    'negmedspace'   => '',
    'negthickspace' => '',
    'negthinspace'  => '',
    'newblock'      => '',
    'newpage'       => '',
    'noindent'      => '',
    'nolinkurl'     => '',
    'oldstylenums'  => '',
    'pagebreak'     => '',
    'protect'       => '',
    'raggedright'   => '',
    'relax'         => '',
    'thinspace'     => '',
    'unskip'        => '',
    'urlprefix'     => '',
);

#  Alphabetic commands, that expand to nothing (above) and to
# something (below).
#
our %CONTROL_WORDS = (
    %CONTROL_WORDS_EMPTY,
    'BibLaTeX'       => 'BibLaTeX',
    'BibTeX'         => 'BibTeX',
    'LaTeX'          => 'LaTeX',
    'LuaLaTeX'       => 'LuaLaTeX',
    'LuaTeX'         => 'LuaTeX',
    'MF'             => 'Metafont',
    'MP'             => 'MetaPost',
    'Omega'          => '\x{03A9}',
    'TeX'            => 'TeX',
    'XeLaTeX'        => 'XeLaTeX',
    'XeTeX'          => 'XeTeX',
    'bullet'         => '\x{2022}',
    'dag'            => '\x{2020}',
    'ddag'           => '\x{2021}',
    'dots'           => '\x{2026}',
    'epsilon'        => '\x{03F5}',
    'hookrightarrow' => '\x{2194}',
    'ldots'          => '\x{2026}',
    'log'            => 'log',
    'omega'          => '\x{03C9}',
    'par'            => "\n\n",
    'qquad'          => ' ', # 2em space
    'quad'           => ' ', # em space
    'textbackslash'  => '\x{005C}', # entities so \ in output indicates
                                    # untranslated TeX source
    'textbraceleft'  => '\x{007B}', # entities so our bare-brace removal
    'textbraceright' => '\x{007D}', # skips them
    'textgreater'    => '\x{003E}',
    'textless'       => '\x{003C}',
    'textquotedbl'   => '"',
    'thickspace'     => ' ',
    'varepsilon'     => '\x{03B5}',
);

#  Control words (not symbols) that generate various non-English
# letters and symbols. Lots more could be added.
# 
our %SYMBOLS = ( # Table 3.2 in Lamport, plus more
    'AA' => '\x{00C5}', # A with ring
    'aa' => '\x{00E5}',
    'AE' => '\x{00C6}', # AE
    'ae' => '\x{00E6}',
    'DH' => '\x{00D0}', # ETH
    'dh' => '\x{00F0}',
    'DJ' => '\x{0110}', # D with stroke
    'dj' => '\x{0111}',
    'i'  => '\x{0131}', # small dotless i
    'L'  => '\x{0141}', # L with stroke
    'l'  => '\x{0142}',
    'NG' => '\x{014A}', # ENG
    'ng' => '\x{014B}',
    'OE' => '\x{0152}', # OE
    'oe' => '\x{0153}',
    'O'  => '\x{00D8}', # O with stroke
    'o'  => '\x{00F8}',
    'SS' => 'SS',       # lately also U+1E9E, but SS seems good enough
    'ss' => '\x{00DF}',
    'TH' => '\x{00DE}', # THORN
    'textordfeminine'  => '\x{00AA}',
    'textordmasculine' => '\x{00BA}',
    'textregistered'   => '\x{00AE}',
    'th' => '\x{00FE}',
    'TM' => '\x{2122}', # trade mark sign
);

#  Accent commands that are not alphabetic.
# 
our %ACCENT_SYMBOLS = (
  "\"" => {             # with diaresis
    A => '\x{00C4}',
    E => '\x{00CB}',
    H => '\x{1E26}',
    I => '\x{00CF}',
    O => '\x{00D6}',
    U => '\x{00DC}',
    W => '\x{1E84}',
    X => '\x{1E8c}',
    Y => '\x{0178}',
    "\\I" => '\x{00CF}',
    "\\i" => '\x{00EF}',
    a => '\x{00E4}',
    e => '\x{00EB}',
    h => '\x{1E27}',
    i => '\x{00EF}',
    o => '\x{00F6}',
    t => '\x{1E97}',
    u => '\x{00FC}',
    w => '\x{1E85}',
    x => '\x{1E8d}',
    y => '\x{00FF}',
  },
  "'" => {              # with acute
    A => '\x{00C1}',
   AE => '\x{01FC}',
    C => '\x{0106}',
    E => '\x{00C9}',
    G => '\x{01F4}',
    I => '\x{00CD}',
    K => '\x{1E30}',
    L => '\x{0139}',
    M => '\x{1E3E}',
    N => '\x{0143}',
    O => '\x{00D3}',
    P => '\x{1E54}',
    R => '\x{0154}',
    S => '\x{015A}',
    U => '\x{00DA}',
    W => '\x{1E82}',
    Y => '\x{00DD}',
    Z => '\x{0179}',
    "\\I" => '\x{00CD}',
    "\\i" => '\x{00ED}',
    a => '\x{00E1}',
   ae => '\x{01FD}',
    c => '\x{0107}',
    e => '\x{00E9}',
    g => '\x{01F5}',
    i => '\x{00ED}',
    k => '\x{1E31}',
    l => '\x{013A}',
    m => '\x{1E3f}',
    n => '\x{0144}',
    o => '\x{00F3}',
    p => '\x{1E55}',
    r => '\x{0155}',
    s => '\x{015B}',
    u => '\x{00FA}',
    w => '\x{1E83}',
    y => '\x{00FD}',
    z => '\x{017A}',
  },
  "^" => {              # with circumflex
    A => '\x{00C2}',
    C => '\x{0108}',
    E => '\x{00CA}',
    G => '\x{011C}',
    H => '\x{0124}',
    I => '\x{00CE}',
    J => '\x{0134}',
    O => '\x{00D4}',
    R => 'R\x{0302}',
    S => '\x{015C}',
    U => '\x{00DB}',
    W => '\x{0174}',
    Y => '\x{0176}',
    Z => '\x{1E90}',
    "\\I" => '\x{00CE}',
    "\\J" => '\x{0134}',
    "\\i" => '\x{00EE}',
    "\\j" => '\x{0135}',
    a => '\x{00E2}',
    c => '\x{0109}',
    e => '\x{00EA}',
    g => '\x{011D}',
    h => '\x{0125}',
    i => '\x{00EE}',
    j => '\x{0135}',
    o => '\x{00F4}',
    s => '\x{015D}',
    u => '\x{00FB}',
    w => '\x{0175}',
    y => '\x{0177}',
    z => '\x{1E91}',
  },
  "`" => {              # with grave
    A => '\x{00C0}',
    E => '\x{00C8}',
    I => '\x{00CC}',
    N => '\x{01F8}',
    O => '\x{00D2}',
    U => '\x{00D9}',
    W => '\x{1E80}',
    Y => '\x{1Ef2}',
    "\\I" => '\x{00CC}',
    "\\i" => '\x{00EC}',
    a => '\x{00E0}',
    e => '\x{00E8}',
    i => '\x{00EC}',
    n => '\x{01F9}',
    o => '\x{00F2}',
    u => '\x{00F9}',
    w => '\x{1E81}',
    y => '\x{1EF3}',
  },
  "." => {              # with dot above
    A => '\x{0226}',
    B => '\x{1E02}',
    C => '\x{010A}',
    D => '\x{1E0A}',
    E => '\x{0116}',
    F => '\x{1E1E}',
    G => '\x{0120}',
    H => '\x{1E22}',
    I => '\x{0130}',
    M => '\x{1E40}',
    N => '\x{1E44}',
    O => '\x{022E}',
    P => '\x{1E56}',
    R => '\x{1E58}',
    S => '\x{1E60}',
    T => '\x{1E6a}',
    W => '\x{1E86}',
    X => '\x{1E8A}',
    Y => '\x{1E8E}',
    Z => '\x{017B}',
    "\\I" => '\x{0130}',
    a => '\x{0227}',
    b => '\x{1E03}',
    c => '\x{010B}',
    d => '\x{1E0B}',
    e => '\x{0117}',
    f => '\x{1e1f}',
    g => '\x{0121}',
    h => '\x{1E23}',
    m => '\x{1E41}',
    n => '\x{1E45}',
    o => '\x{022F}',
    p => '\x{1E57}',
    r => '\x{1E59}',
    s => '\x{1E61}',
    t => '\x{1E6b}',
    w => '\x{1E87}',
    x => '\x{1E8b}',
    y => '\x{1E8f}',
    z => '\x{017C}',
  },
  '=' => {              # with macron
    A => '\x{0100}',
   AE => '\x{01E2}',
    E => '\x{0112}',
    G => '\x{1E20}',
    I => '\x{012A}',
    O => '\x{014C}',
    U => '\x{016A}',
    Y => '\x{0232}',
    "\\I" => '\x{012A}',
    "\\i" => '\x{012B}',
    a => '\x{0101}',
   ae => '\x{01E3}',
    e => '\x{0113}',
    g => '\x{1E21}',
    i => '\x{012B}',
    o => '\x{014D}',
    u => '\x{016B}',
    y => '\x{0233}',
  },
  "~" => {              # with tilde
    A => '\x{00C3}',
    E => '\x{1EBC}',
    I => '\x{0128}',
    N => '\x{00D1}',
    O => '\x{00D5}',
    U => '\x{0168}',
    V => '\x{1E7C}',
    Y => '\x{1EF8}',
    "\\I" => '\x{0128}',
    "\\i" => '\x{0129}',
    a => '\x{00E3}',
    e => '\x{1EBD}',
    i => '\x{0129}',
    n => '\x{00F1}',
    o => '\x{00F5}',
    u => '\x{0169}',
    v => '\x{1E7D}',
    y => '\x{1EF9}',
  },
);

#  Accent commands that are alphabetic.
# 
our %ACCENT_LETTERS = (
  "H" => {              # with double acute
    O => '\x{0150}',
    U => '\x{0170}',
    o => '\x{0151}',
    u => '\x{0171}',
  },
  "c" => {              # with cedilla
    C => '\x{00C7}',
    D => '\x{1E10}',
    E => '\x{0228}',
    G => '\x{0122}',
    H => '\x{1E28}',
    K => '\x{0136}',
    L => '\x{013B}',
    N => '\x{0145}',
    R => '\x{0156}',
    S => '\x{015E}',
    T => '\x{0162}',
    c => '\x{00E7}',
    d => '\x{1E11}',
    e => '\x{0229}',
    g => '\x{0123}',
    h => '\x{1E29}',
    k => '\x{0137}',
    l => '\x{013C}',
    n => '\x{0146}',
    r => '\x{0157}',
    s => '\x{015F}',
    t => '\x{0163}',
  },
  "d" => {              # with dot below
    A => '\x{1EA0}',
    B => '\x{1E04}',
    D => '\x{1E0C}',
    E => '\x{1EB8}',
    H => '\x{1E24}',
    I => '\x{1ECA}',
    K => '\x{1E32}',
    L => '\x{1E36}',
    M => '\x{1E42}',
    N => '\x{1E46}',
    O => '\x{1ECC}',
    R => '\x{1E5A}',
    S => '\x{1E62}',
    T => '\x{1E6C}',
    U => '\x{1EE4}',
    V => '\x{1E7E}',
    W => '\x{1E88}',
    Y => '\x{1Ef4}',
    Z => '\x{1E92}',
    "\\I" => '\x{1ECA}',
    "\\i" => '\x{1ECB}',
    a => '\x{1EA1}',
    b => '\x{1E05}',
    d => '\x{1E0D}',
    e => '\x{1EB9}',
    h => '\x{1E25}',
    i => '\x{1ECB}',
    k => '\x{1E33}',
    l => '\x{1E37}',
    m => '\x{1E43}',
    n => '\x{1E47}',
    o => '\x{1ECD}',
    r => '\x{1E5b}',
    s => '\x{1E63}',
    t => '\x{1E6D}',
    u => '\x{1EE5}',
    v => '\x{1E7F}',
    w => '\x{1E89}',
    y => '\x{1EF5}',
    z => '\x{1E93}',
  },
  "h" => {              # with hook above
    A => '\x{1EA2}',
    E => '\x{1EBA}',
    I => '\x{1EC8}',
    O => '\x{1ECe}',
    U => '\x{1EE6}',
    Y => '\x{1EF6}',
    "\\I" => '\x{1EC8}',
    "\\i" => '\x{1EC9}',
    a => '\x{1EA3}',
    e => '\x{1EBB}',
    i => '\x{1EC9}',
    o => '\x{1ECF}',
    u => '\x{1EE7}',
    y => '\x{1EF7}',
  },
  "k" => {              # with ogonek
    A => '\x{0104}',
    E => '\x{0118}',
    I => '\x{012E}',
    O => '\x{01EA}',
    U => '\x{0172}',
    "\\I" => '\x{012E}',
    "\\i" => '\x{012F}',
    a => '\x{0105}',
    e => '\x{0119}',
    i => '\x{012F}',
    o => '\x{01EB}',
    u => '\x{0173}',
  },
  "r" => {              # with ring above
    A => '\x{00C5}',
    U => '\x{016E}',
    a => '\x{00E5}',
    u => '\x{016F}',
    w => '\x{1E98}',
    y => '\x{1E99}',
  },
  "u" => {              # with breve
    A => '\x{0102}',
    E => '\x{0114}',
    G => '\x{011E}',
    I => '\x{012C}',
    O => '\x{014E}',
    U => '\x{016C}',
    "\\I" => '\x{012C}',
    "\\i" => '\x{012D}',
    a => '\x{0103}',
    e => '\x{0115}',
    g => '\x{011F}',
    i => '\x{012D}',
    o => '\x{014F}',
    u => '\x{016D}',
  },
  "v" => {              # with caron
    A => '\x{01CD}',
    C => '\x{010C}',
    D => '\x{010E}',
   DZ => '\x{01C4}',
    E => '\x{011A}',
    G => '\x{01E6}',
    H => '\x{021E}',
    I => '\x{01CF}',
    K => '\x{01E8}',
    L => '\x{013D}',
    N => '\x{0147}',
    O => '\x{01D1}',
    R => '\x{0158}',
    S => '\x{0160}',
    T => '\x{0164}',
    U => '\x{01D3}',
    Z => '\x{017D}',
    "\\I" => '\x{01CF}',
    "\\i" => '\x{01D0}',
    "\\j" => '\x{01F0}',
    a => '\x{01CE}',
    c => '\x{010D}',
    d => '\x{010F}',
   dz => '\x{01C6}',
    e => '\x{011B}',
    g => '\x{01E7}',
    h => '\x{021F}',
    i => '\x{01D0}',
    j => '\x{01F0}',
    k => '\x{01E9}',
    l => '\x{013E}',
    n => '\x{0148}',
    o => '\x{01D2}',
    r => '\x{0159}',
    s => '\x{0161}',
    t => '\x{0165}',
    u => '\x{01D4}',
    z => '\x{017E}',
  },
);

# 
our %GERMAN = ( # for package `german'/`ngerman'
    '"a'    => 'ä',
    '"A'    => 'Ä',
    '"e'    => 'ë',
    '"E'    => 'Ë',
    '"i'    => 'ï',
    '"I'    => 'Ï',
    '"o'    => 'ö',
    '"O'    => 'Ö',
    '"u'    => 'ü',
    '"U'    => 'Ü',
    '"s'    => 'ß',
    '"S'    => 'SS',
    '"z'    => 'ß',
    '"Z'    => 'SZ',
    '"ck'   => 'ck', # old spelling: ck -> k-k
    '"ff'   => 'ff', # old spelling: ff -> ff-f
    '"`'    => '„',
    "\"'"   => '“',
    '"<'    => '«',
    '">'    => '»',
    '"-'    => '\x{00AD}',    # soft hyphen
    '""'    => '\x{200B}',  # zero width space
    '"~'    => '\x{2011}',  # non-breaking hyphen
    '"='    => '-',
    '\glq'  => '‚', # left german single quote
    '\grq'  => '‘', # right german single quote
    '\flqq' => '«',
    '\frqq' => '»',
    '\dq'   => '"',
);

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

LaTeX::ToUnicode::Tables - Character tables for LaTeX::ToUnicode

=head1 VERSION

version 0.54

=head1 CONSTANTS

=head2 @LIGATURES

Standard TeX character sequences (not \commands) which need to be
replaced: C<---> with U+2014 (em dash), etc.  Includes: em dash, en
dash, inverted exclamation, inverted question, left double quote, right
double quote, left single quote, right single quote. They are replaced
in that order.

=head2 %MARKUPS

Hash where keys are the names of formatting commands like C<\tt>,
without the backslash, namely: C<bf cal em it rm sc sf sl small tt>. Values
are the obvious HTML equivalent where one exists, given as the tag name
without the angle brackets: C<b em i tt>. Otherwise the value is the empty
string.

=head2 %ARGUMENT_COMMANDS

Hash where keys are the names of TeX commands taking arguments that we
handle, without the backslash, such as C<enquote>. Each value is a
reference to a list of two strings, the first being the text to insert
before the argument, the second being the text to insert after. For
example, for C<enquote> the value is C<["`", "'"]>. The inserted text is
subject to further replacements.

Only three such commands are currently handled: C<\emph>, C<\enquote>,
and C<\path>.

=head2 %CONTROL_SYMBOLS

A hash where the keys are non-alphabetic C<\command>s (without the
backslash), other than accents and special cases. These don't take
arguments. Although some of these have Unicode equivalents, such as the
C<\,> thin space, it seems better to keep the output as simple as
possible; small spacing tweaks in TeX aren't usually desirable in plain
text or HTML.

The values are single-quoted strings C<'\x{...}'>, not double-quoted
literal characters <"\x{...}">, to ease future parsing of the
TeX/text/HTML.

This hash is necessary because TeX's parsing rules for control symbols
are different from control words: no space or other token is needed to
terminate control symbols.

=head2 %CONTROL_WORDS

Keys are names of argument-less commands, such as C<\LaTeX> (without the
backslash). Values are the replacements, often the empty string.

=head2 %SYMBOLS

Keys are the commands for extended characters, such as C<\AA> (without
the backslash.)

=head2 %ACCENT_SYMBOLS

Two-level hash of accented characters like C<\'{a}>. The keys of this
hash are the accent symbols (without the backslash), such as C<`> and
C<'>. The corresponding values are hash references where the keys are
the base letters and the values are single-quoted C<'\x{....}'> strings.

=head2 %ACCENT_LETTERS

Same as %ACCENT_SYMBOLS, except the keys are accents that are
alphabetic, such as C<\c> (without the backslash as always).

As with control sequences, it's necessary to distinguish symbols and
alphabetic commands because of the different parsing rules.

=head2 %GERMAN

Character sequences (not necessarily commands) as defined by the package
`german'/`ngerman', e.g. C<"a> (a with umlaut), C<"s> (german sharp s)
or C<"`"> (german left quote). Note the missing backslash.

The keys of this hash are the literal character sequences.

=head1 AUTHOR

Gerhard Gossen <gerhard.gossen@googlemail.com>,
Boris Veytsman <boris@varphi.com>,
Karl Berry <karl@freefriends.org>

L<https://github.com/borisveytsman/bibtexperllibs>

=head1 COPYRIGHT AND LICENSE

Copyright 2010-2023 Gerhard Gossen, Boris Veytsman, Karl Berry

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl5 programming language system itself.

=cut
