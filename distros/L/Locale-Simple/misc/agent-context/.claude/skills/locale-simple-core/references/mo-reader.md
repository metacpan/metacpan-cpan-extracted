# .mo Reader Specification

Single specification for the runtimes that bring their own gettext reader: PHP, Go,
Rust and — for the plural evaluator and the locale chain — JavaScript. Perl and Python
get all of this from libc. The shared test vectors are `t/data/plural-forms.json`;
every implementation must run them. If an implementation disagrees with this document,
the implementation is wrong; if the document is wrong, fix it here first.

## 1. MO binary format

GNU gettext "MO Files". All integers are unsigned 32-bit.

- **Magic** at offset 0: `0x950412de` read little endian means the file is little
  endian; `0xde120495` means big endian. Read both; anything else is an error.
- **Header** (7 words, byte order from the magic):

  | offset | field |
  |---|---|
  | 0 | magic |
  | 4 | revision (only major revision 0 is supported; `revision >> 16 != 0` is an error) |
  | 8 | N, number of strings |
  | 12 | O, offset of the original-strings table |
  | 16 | T, offset of the translation table |
  | 20 | hash table size (ignored) |
  | 24 | hash table offset (ignored) |

- **Tables.** Table entry `i` is `(length, offset)`, 8 bytes, at `O + 8*i` (originals)
  and `T + 8*i` (translations). The string is `length` bytes at `offset`, followed by
  a NUL that is not counted in `length`.
- **The hash table is not used.** Read all N pairs linearly into a map.
- **Bounds.** Every table and string range must lie inside the file; otherwise the
  file is rejected as a whole (no partial read, no panic, no exception leaking).
- **Context.** Key is `msgctxt \x04 msgid` (EOT, byte 0x04).
- **Plural.** Original is `msgid \x00 msgid_plural`; translation is
  `form0 \x00 form1 \x00 …`. A plural entry is looked up by its singular `msgid` (the
  part before the first `\x00`); with context, `msgctxt \x04 msgid`.
- **Header entry.** The entry with empty msgid holds RFC-822-style metadata
  (`Key: value\n`). Needed keys: `Plural-Forms`, `Content-Type` (`charset=`).
  Strings are decoded as UTF-8; other charsets are not supported (read as UTF-8,
  invalid bytes replaced).
- **Duplicates.** Later entry wins.

Worked example, `t/data/locale/de_DE/LC_MESSAGES/test.mo` (1207 bytes): magic bytes
`de 12 04 95`... read as little endian `0x950412de`; revision 0; N=9; O=28; T=100;
entry 0 is the header (original length 0), entry 4 is `Hello` → `Hallo`, entry 8 is
`alien\x04Hello` → `Hallo Ausserirdischer`, entry 6 is
`You have %d message\x00You have %d messages` →
`Du hast %d Nachricht\x00Du hast %d Nachrichten`.

## 2. Directory and locale resolution

File: `<l_dir>/<lang>/LC_MESSAGES/<domain>.mo`, with `ltd(domain)` selecting the domain.

**Effective language string.** `l_lang(x)` wins when it has been called. Otherwise, in
runtimes with an environment: `LC_ALL`, `LC_MESSAGES`, `LANG` give the locale (first
non-empty). If that locale is empty, `C` or `POSIX`, the result is empty (no
translation, even when `LANGUAGE` is set — as in GNU gettext). Otherwise the effective
string is `LANGUAGE` when non-empty, else the locale. Browser-style runtimes without
environment use only `l_lang`.

**Candidate chain.** Split the effective string on `:` (GNU `LANGUAGE` list; `l_lang`
accepts the same syntax). For each entry, in order:

1. Replace `-` with `_` (`pt-BR` → `pt_BR`). No case folding.
2. Strip `@modifier`, then strip `.codeset` (`de_DE.UTF-8@euro` → `de_DE`).
3. Empty, `C` and `POSIX` entries (and anything starting `C.`) contribute nothing.
4. Otherwise the entry contributes itself, then — if it contains `_` — the part before
   the first `_` (`de_AT` → `de_AT`, `de`).

Concatenate the contributions, drop later duplicates. `de_AT:fr` → `de_AT, de, fr`.
An empty chain means "no translation": msgids are returned as is.

**Lookup across the chain.** For every message, the chain is walked in order: the
first candidate whose `.mo` exists, contains the key, and has a **non-empty** msgstr
(for plurals: a non-empty selected form) wins. Missing files are skipped silently. An
empty msgstr is "untranslated" and falls through to the next candidate, and finally to
the msgid (`msgid` for `n == 1`, `msgid_plural` otherwise). Each candidate uses **its
own** `Plural-Forms` header to select the form.

Perl and Python obtain the same behavior from libc; where libc differs in a corner case
(e.g. `C:de`), the fixture rows in `locale_fallback` are authoritative for the four
own-reader runtimes.

## 3. Plural-Forms evaluator

The header is evaluated, never guessed from the language name.

### 3.1 Extraction

In the header entry, find the line starting `Plural-Forms:`. Within it find
`nplurals=<digits>` and `plural=<expr>`; `<expr>` runs to the next `;` or end of line.
Whitespace is insignificant. `nplurals` must be ≥ 1 and the expression must parse
completely, otherwise the header counts as unparsable.

### 3.2 Grammar

```
expr    := or ( '?' expr ':' expr )?
or      := and ( '||' and )*
and     := eq ( '&&' eq )*
eq      := rel ( ('==' | '!=') rel )*
rel     := add ( ('<' | '>' | '<=' | '>=') add )*
add     := mul ( ('+' | '-') mul )*
mul     := unary ( ('*' | '/' | '%') unary )*
unary   := '!' unary | primary
primary := 'n' | integer | '(' expr ')'
```

Precedence from lowest to highest: `?:` (right associative), `||`, `&&`,
`== !=`, `< > <= >=`, `+ -`, `* / %`, `!`. Binary operators are left associative.
`integer` is decimal digits. Anything else (bitwise operators, `**`, unknown
identifiers, trailing tokens) makes the expression unparsable.

### 3.3 Semantics

- All values are integers (at least 64-bit signed; JS: safe-integer range).
- `n` is the count, a non-negative integer. A fractional `n` is truncated toward zero,
  a negative `n` is replaced by its absolute value.
- Comparison and logical operators yield `1` or `0`; `&&` and `||` evaluate to
  `1`/`0` and short-circuit; any non-zero is true.
- `/` truncates toward zero. **Division and modulo by zero yield `0`** — no panic, no
  exception, no NaN.
- Arithmetic overflow must not panic (wrapping or saturating are both fine).
- The result `r` is the form index. If `r < 0` or `r >= nplurals`, the index is `0`.

### 3.4 Security

The expression is data from a file.

- **No `eval`, no `new Function`, no `create_function`, no template engines** — in any
  language, PHP included. Write a tokenizer and a recursive-descent (or Pratt) parser
  into an AST or closure tree, once per header, cached per loaded file.
- **Depth limit.** Nesting counts `(` groups, `!` prefixes and both branches of
  `?:`. More than **100** levels makes the expression unparsable (the fixture covers
  100 = ok, 101 = fallback). The input expression is also limited to 1000 characters.
- No recursion beyond that bound, no unbounded allocation from the expression.

### 3.5 Fallback

A missing header, a missing `Plural-Forms:`, a missing `nplurals`, or an unparsable
expression selects the rule `nplurals=2; plural=n != 1;` and emits **one** warning per
process (not per lookup, not per file) through the runtime's normal warning channel
(`E_USER_WARNING`, `log`/`eprintln`, `console.warn`). Entries without a catalog at all
(msgid fallback, §2) never warn.

## 4. Shared test vectors

`t/data/plural-forms.json`:

- `plural_forms[]` — `{lang, header, cases: [[n, index], …]}`: en, de, fr (`n > 1`),
  pl and ru (3 forms), ar (6 forms), ja (1 form).
- `plural_edge_cases[]` — `{name, header|null, warns, cases}`: missing header,
  unparsable expression, missing nplurals, division/modulo by zero, index out of
  range, nesting depth 100/101. `warns` says whether the one-time warning is
  expected.
- `locale_fallback[]` — `{input, candidates}`: the §2 chain from a language string.
- `env_resolution[]` — `{env, effective}`: the §2 effective string from environment
  variables (runtimes with an environment only).

Each runtime suite iterates over **all** rows; a new row needs no code change. Plural
rows feed the header into the real header-parsing entry point, not into a private
helper, so §3.1 is covered as well.

## 5. sprintf semantics

`.po` files contain `%s`, `%d` and positional `%1$s`. Supported are the conversions
`b c d e u f F o s x X` (the set of `Locale::Simple::sprintf_compare`), the flags `+`,
`-`, `0`, space and `'<char>` (custom pad), width, `.precision`, the `N$` position and
`%%`.

Every runtime brings its own formatter that parses the format once and formats each
placeholder on its own: Perl and PHP hand one placeholder at a time to the native
`sprintf`, Python, JavaScript, Go and Rust format it themselves (`fmt.Sprintf` has no
`%1$s`, `format!` is compile-time). Width and precision count characters, not bytes.
- **Missing argument:** the placeholder is left unchanged in the output. No panic, no
  error, no warning.
- **Extra arguments** are ignored.
- **Arguments** are read as Perl reads them: a numeric conversion takes the leading
  number of a string (0 without one), an integer conversion drops the fraction, and
  `b o u x X` show a negative number as unsigned 64-bit.
- **Flags and precision** work as in C: `+` and space apply to `d` and the floating
  conversions, the precision of an integer conversion is its minimum digit count
  (`%.0d` of 0 is empty) and turns `0` off, `0` also pads `s` and `c`, and a floating
  conversion rounds a tie to the even digit.

Shared vectors: `t/data/sprintf.json`.

- `rows[]` — `{format, args, want}`, `args` as JSON strings and numbers. Every
  runtime suite iterates over all rows.
- `perl_python_rows[]` — the same shape, for what Perl and Python take beyond this
  section: a `*` width or precision, the `#` flag and the conversions `i E g G`.
