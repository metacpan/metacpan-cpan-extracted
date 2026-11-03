<?php

declare(strict_types=1);

/**
 * Locale Simple — gettext-style translation helpers with sprintf formatting.
 * Same API as the Perl, Python and JavaScript siblings.
 *
 * Reads GNU .mo files itself (spec: .claude/skills/locale-simple-core/references/mo-reader.md), so
 * ext-gettext is not needed. All 21 names are plain functions in the
 * namespace Locale\Simple.
 */

namespace Locale\Simple;

/**
 * Process-wide state and the .mo / plural / locale machinery behind the
 * functions below. Not part of the public API; the test suite reaches in.
 *
 * @internal
 */
final class Internal
{
    public static ?string $dir = null;
    public static ?string $lang = null;
    public static ?string $domain = null;
    public static ?string $dry = null;
    public static bool $nowrite = false;
    public static bool $nolocales = false;

    /** @var array<string, ?array{entries: array<string, list<string>>, rule: array{nplurals: int, eval: \Closure}}> */
    private static array $catalogs = [];
    private static bool $pluralWarned = false;

    private const MAX_DEPTH = 100;
    private const MAX_LENGTH = 1000;

    public static function reset(): void
    {
        self::$dir = self::$lang = self::$domain = self::$dry = null;
        self::$nowrite = self::$nolocales = false;
        self::$catalogs = [];
        self::$pluralWarned = false;
    }

    public static function resetPluralWarning(): void
    {
        self::$pluralWarned = false;
    }

    // ------------------------------------------------------------------
    // locale resolution (spec §2)
    // ------------------------------------------------------------------

    /**
     * @param array<string, string> $env
     */
    public static function effectiveLang(array $env, ?string $lang): string
    {
        if ($lang !== null) {
            return $lang;
        }
        $locale = '';
        foreach (['LC_ALL', 'LC_MESSAGES', 'LANG'] as $var) {
            if (($env[$var] ?? '') !== '') {
                $locale = $env[$var];
                break;
            }
        }
        if ($locale === '' || $locale === 'C' || $locale === 'POSIX') {
            return '';
        }
        $language = $env['LANGUAGE'] ?? '';
        return $language !== '' ? $language : $locale;
    }

    /**
     * @return list<string>
     */
    public static function candidates(string $effective): array
    {
        $out = [];
        foreach (explode(':', $effective) as $entry) {
            $entry = str_replace('-', '_', $entry);
            $entry = preg_replace('/@.*$/s', '', $entry);
            $entry = preg_replace('/\..*$/s', '', $entry);
            if ($entry === '' || $entry === 'C' || $entry === 'POSIX') {
                continue;
            }
            $out[] = $entry;
            $us = strpos($entry, '_');
            if ($us !== false) {
                $out[] = substr($entry, 0, $us);
            }
        }
        return array_values(array_unique($out));
    }

    // ------------------------------------------------------------------
    // lookup
    // ------------------------------------------------------------------

    public static function lookup(string $td, ?string $ctxt, string $id, ?string $idp, ?int $n): string
    {
        $fallback = ($idp !== null && $n !== 1) ? $idp : $id;
        if (self::$dir === null) {
            return $fallback;
        }
        $domain = $td !== '' ? $td : (self::$domain ?? 'messages');
        $effective = self::effectiveLang(self::environment(), self::$lang);
        $key = ($ctxt !== null && $ctxt !== '') ? $ctxt . "\x04" . $id : $id;

        foreach (self::candidates($effective) as $cand) {
            $cat = self::catalog(self::$dir . '/' . $cand . '/LC_MESSAGES/' . $domain . '.mo');
            if ($cat === null || !isset($cat['entries'][$key])) {
                continue;
            }
            $forms = $cat['entries'][$key];
            $idx = $idp !== null ? ($cat['rule']['eval'])($n ?? 0) : 0;
            $hit = $forms[$idx] ?? '';
            if ($hit !== '') {
                return $hit;
            }
        }
        return $fallback;
    }

    /**
     * @return array<string, string>
     */
    private static function environment(): array
    {
        $env = [];
        foreach (['LC_ALL', 'LC_MESSAGES', 'LANG', 'LANGUAGE'] as $var) {
            $v = getenv($var);
            if ($v !== false) {
                $env[$var] = $v;
            }
        }
        return $env;
    }

    /**
     * @return ?array{entries: array<string, list<string>>, rule: array{nplurals: int, eval: \Closure}}
     */
    private static function catalog(string $path): ?array
    {
        if (array_key_exists($path, self::$catalogs)) {
            return self::$catalogs[$path];
        }
        $data = is_file($path) ? @file_get_contents($path) : false;
        return self::$catalogs[$path] = ($data === false ? null : self::parseMo($data));
    }

    // ------------------------------------------------------------------
    // .mo reader (spec §1)
    // ------------------------------------------------------------------

    /**
     * @return ?array{entries: array<string, list<string>>, rule: array{nplurals: int, eval: \Closure}}
     */
    public static function parseMo(string $d): ?array
    {
        $len = strlen($d);
        if ($len < 28) {
            return null;
        }
        $magic = unpack('V', $d)[1];
        if ($magic === 0x950412de) {
            $f = 'V';
        } elseif ($magic === 0xde120495) {
            $f = 'N';
        } else {
            return null;
        }
        $h = unpack("{$f}rev/{$f}n/{$f}o/{$f}t", $d, 4);
        if (($h['rev'] >> 16) !== 0) {
            return null;
        }
        $n = $h['n'];
        $o = $h['o'];
        $t = $h['t'];
        if ($o + 8 * $n > $len || $t + 8 * $n > $len) {
            return null;
        }
        $entries = [];
        for ($i = 0; $i < $n; $i++) {
            $a = unpack("{$f}len/{$f}off", $d, $o + 8 * $i);
            $b = unpack("{$f}len/{$f}off", $d, $t + 8 * $i);
            if ($a['off'] + $a['len'] > $len || $b['off'] + $b['len'] > $len) {
                return null;
            }
            $orig = substr($d, $a['off'], $a['len']);
            $trans = substr($d, $b['off'], $b['len']);
            $z = strpos($orig, "\0");
            $key = $z === false ? $orig : substr($orig, 0, $z);
            $entries[$key] = explode("\0", $trans);
        }
        $header = isset($entries['']) ? implode("\0", $entries['']) : null;
        unset($entries['']);
        return ['entries' => $entries, 'rule' => self::ruleFromHeader($header)];
    }

    // ------------------------------------------------------------------
    // Plural-Forms (spec §3)
    // ------------------------------------------------------------------

    /**
     * @return array{nplurals: int, eval: \Closure}
     */
    public static function ruleFromHeader(?string $header): array
    {
        $rule = null;
        if ($header !== null) {
            foreach (preg_split('/\r?\n/', $header) as $line) {
                if (strncmp($line, 'Plural-Forms:', 13) === 0) {
                    $rule = self::parsePluralForms($line);
                    break;
                }
            }
        }
        if ($rule === null) {
            self::warnPluralOnce();
            return ['nplurals' => 2, 'eval' => static fn (int $n): int => $n !== 1 ? 1 : 0];
        }
        return $rule;
    }

    /**
     * @return ?array{nplurals: int, eval: \Closure}
     */
    public static function parsePluralForms(string $line): ?array
    {
        if (!preg_match('/\bnplurals\s*=\s*(\d+)/', $line, $np)
            || !preg_match('/\bplural\s*=\s*([^;\n]*)/', $line, $ex)) {
            return null;
        }
        $nplurals = (int) $np[1];
        if ($nplurals < 1) {
            return null;
        }
        $fn = self::compilePlural($ex[1]);
        if ($fn === null) {
            return null;
        }
        return [
            'nplurals' => $nplurals,
            'eval' => static function (int $n) use ($fn, $nplurals): int {
                $n = $n === PHP_INT_MIN ? PHP_INT_MAX : abs($n);
                $r = $fn($n);
                return ($r < 0 || $r >= $nplurals) ? 0 : $r;
            },
        ];
    }

    private static function warnPluralOnce(): void
    {
        if (self::$pluralWarned) {
            return;
        }
        self::$pluralWarned = true;
        trigger_error('locale-simple: missing or unusable Plural-Forms header, falling back to "n != 1"', E_USER_WARNING);
    }

    private static function sat(int|float $v): int
    {
        if (is_float($v)) {
            return $v > 0 ? PHP_INT_MAX : PHP_INT_MIN;
        }
        return $v;
    }

    /**
     * Tokenizer + recursive-descent parser into a closure tree. The expression
     * is data from a file and is never evaluated by the PHP engine.
     */
    private static function compilePlural(string $src): ?\Closure
    {
        if (strlen($src) > self::MAX_LENGTH) {
            return null;
        }
        $toks = [];
        $at = 0;
        $len = strlen($src);
        while ($at < $len) {
            if (ctype_space($src[$at])) {
                $at++;
                continue;
            }
            if (!preg_match('/\G(\d+|n|\|\||&&|==|!=|<=|>=|[-+*\/%<>!?:()])/', $src, $m, 0, $at)) {
                return null;
            }
            $toks[] = $m[1];
            $at += strlen($m[1]);
        }

        $pos = 0;
        $depth = 0;
        $count = count($toks);
        $levels = [['||'], ['&&'], ['==', '!='], ['<', '>', '<=', '>='], ['+', '-'], ['*', '/', '%']];
        $sat = static fn (int|float $v): int => self::sat($v);
        $ops = [
            '||' => static fn (int $x, int $y): int => ($x !== 0 || $y !== 0) ? 1 : 0,
            '&&' => static fn (int $x, int $y): int => ($x !== 0 && $y !== 0) ? 1 : 0,
            '==' => static fn (int $x, int $y): int => $x === $y ? 1 : 0,
            '!=' => static fn (int $x, int $y): int => $x !== $y ? 1 : 0,
            '<' => static fn (int $x, int $y): int => $x < $y ? 1 : 0,
            '>' => static fn (int $x, int $y): int => $x > $y ? 1 : 0,
            '<=' => static fn (int $x, int $y): int => $x <= $y ? 1 : 0,
            '>=' => static fn (int $x, int $y): int => $x >= $y ? 1 : 0,
            '+' => static fn (int $x, int $y): int => $sat($x + $y),
            '-' => static fn (int $x, int $y): int => $sat($x - $y),
            '*' => static fn (int $x, int $y): int => $sat($x * $y),
            '/' => static fn (int $x, int $y): int => $y === 0 ? 0 : ($y === -1 ? $sat(-$x) : intdiv($x, $y)),
            '%' => static fn (int $x, int $y): int => ($y === 0 || $y === -1) ? 0 : $x % $y,
        ];

        // Parse failures are signalled by exception and caught once at the end.
        $fail = static function () {
            throw new \UnexpectedValueException('plural');
        };

        $expr = null;
        $unary = null;
        $nested = function (callable $fn) use (&$depth, $fail) {
            if (++$depth > self::MAX_DEPTH) {
                $fail();
            }
            $r = $fn();
            $depth--;
            return $r;
        };
        $binary = null;
        $binary = function (int $level) use (&$binary, &$unary, &$pos, $toks, $levels, $ops): \Closure {
            if ($level === count($levels)) {
                return $unary();
            }
            $left = $binary($level + 1);
            while (isset($toks[$pos]) && in_array($toks[$pos], $levels[$level], true)) {
                $op = $ops[$toks[$pos++]];
                $l = $left;
                $r = $binary($level + 1);
                $left = static fn (int $n): int => $op($l($n), $r($n));
            }
            return $left;
        };
        $primary = function () use (&$pos, $toks, &$expr, $nested, $fail): \Closure {
            $t = $toks[$pos++] ?? null;
            if ($t === 'n') {
                return static fn (int $n): int => $n;
            }
            if ($t !== null && ctype_digit($t)) {
                $v = (int) $t;
                return static fn (int $n): int => $v;
            }
            if ($t === '(') {
                $inner = $nested($expr);
                if (($toks[$pos++] ?? null) !== ')') {
                    $fail();
                }
                return $inner;
            }
            $fail();
        };
        $unary = function () use (&$pos, $toks, &$unary, $nested, $primary): \Closure {
            if (($toks[$pos] ?? null) === '!') {
                $pos++;
                $inner = $nested($unary);
                return static fn (int $n): int => $inner($n) !== 0 ? 0 : 1;
            }
            return $primary();
        };
        $expr = function () use (&$pos, $toks, &$expr, $binary, $nested, $fail): \Closure {
            $cond = $binary(0);
            if (($toks[$pos] ?? null) !== '?') {
                return $cond;
            }
            $pos++;
            $a = $nested($expr);
            if (($toks[$pos++] ?? null) !== ':') {
                $fail();
            }
            $b = $nested($expr);
            return static fn (int $n): int => $cond($n) !== 0 ? $a($n) : $b($n);
        };

        try {
            $fn = $expr();
        } catch (\UnexpectedValueException) {
            return null;
        }
        return $pos === $count ? $fn : null;
    }

    // ------------------------------------------------------------------
    // sprintf (spec §5, rows in t/data/sprintf.json)
    // ------------------------------------------------------------------

    /** One placeholder: %%, or the N$ position, flags, width, .precision, conversion. */
    private const PLACEHOLDER = '/%%|%(?:(\d+)\$)?((?:[-+ 0]|\'.)*)(\d+)?(?:\.(\d*))?([bcdeufFosxX])/s';

    /** The number at the start of a string, the way Perl reads a string as a number. */
    private const LEADING_NUMBER = '/^\s*[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/';

    /**
     * Formats with the conversions b c d e u f F o s x X, the flags + - 0
     * space '<char>, width, .precision, the N$ position and %%. Each
     * placeholder is formatted on its own: a placeholder without an argument
     * stays unchanged, extra arguments are ignored.
     *
     * @param list<mixed> $args
     */
    public static function format(string $fmt, array $args): string
    {
        if (!str_contains($fmt, '%')) {
            return $fmt;
        }
        // A UTF-8 format reads a '<char> pad as one character, any other
        // format byte by byte.
        $mode = preg_match('//u', $fmt) === 1 ? 'u' : '';
        $next = 0;
        $out = preg_replace_callback(
            self::PLACEHOLDER . $mode,
            static function (array $m) use ($args, &$next, $mode): string {
                if ($m[0] === '%%') {
                    return '%';
                }
                $index = $m[1] !== null ? (int) $m[1] - 1 : $next++;
                if ($index < 0 || !array_key_exists($index, $args)) {
                    return $m[0];
                }
                return self::conversion($m, $args[$index], $mode);
            },
            $fmt,
            flags: PREG_UNMATCHED_AS_NULL
        );
        return $out ?? $fmt;
    }

    /**
     * One placeholder with its argument. The 0 flag pads s, c and the
     * floating conversions, and the integer conversions without a precision;
     * a precision on an integer conversion is its minimum digit count.
     *
     * @param array<int, ?string> $m
     */
    private static function conversion(array $m, mixed $arg, string $mode): string
    {
        $left = $plus = $space = $zero = false;
        $pad = null;
        preg_match_all('/\'(.)|[-+ 0]/s' . $mode, (string) $m[2], $flags, PREG_SET_ORDER);
        foreach ($flags as $flag) {
            if (isset($flag[1])) {
                $pad = $flag[1];
            } elseif ($flag[0] === '-') {
                $left = true;
            } elseif ($flag[0] === '+') {
                $plus = true;
            } elseif ($flag[0] === ' ') {
                $space = true;
            } else {
                $zero = true;
            }
        }
        $width = (int) $m[3];
        $precision = $m[4] !== null ? (int) $m[4] : null;
        $conv = (string) $m[5];
        $sign = '';
        $zeroPads = true;

        switch ($conv) {
            case 's':
                $text = is_array($arg) ? 'Array' : (string) $arg;
                if ($precision !== null) {
                    $text = implode('', array_slice(self::chars($text), 0, $precision));
                }
                break;
            case 'c':
                $text = self::character(self::integer($arg));
                break;
            case 'e':
            case 'f':
            case 'F':
                $v = (float) self::number($arg);
                $negative = $v < 0 || ($v == 0 && fdiv(1, $v) < 0);
                $sign = $negative ? '-' : ($plus ? '+' : ($space ? ' ' : ''));
                $text = sprintf('%.' . ($precision ?? 6) . ($conv === 'e' ? 'e' : 'F'), abs($v));
                if ($conv === 'e') {
                    // C writes at least two exponent digits
                    $text = (string) preg_replace('/e([+-])(\d)$/', 'e${1}0$2', $text);
                }
                break;
            default: // b d o u x X
                $n = self::integer($arg);
                if ($conv === 'd') {
                    $sign = $n < 0 ? '-' : ($plus ? '+' : ($space ? ' ' : ''));
                    $text = ltrim(sprintf('%d', $n), '-');
                } else {
                    // PHP writes a negative number as unsigned 64-bit here
                    $text = sprintf('%' . $conv, $n);
                }
                if ($precision !== null) {
                    $text = ($precision === 0 && $n === 0) ? '' : str_pad($text, $precision, '0', STR_PAD_LEFT);
                    $zeroPads = false;
                }
        }

        $fill = $width - count(self::chars($sign . $text));
        if ($fill <= 0) {
            return $sign . $text;
        }
        if ($left) {
            return $sign . $text . str_repeat($pad ?? ' ', $fill);
        }
        if ($zero && $zeroPads && $pad === null) {
            return $sign . str_repeat('0', $fill) . $text;
        }
        return str_repeat($pad ?? ' ', $fill) . $sign . $text;
    }

    /**
     * An argument as a number: ints and floats as they are, anything else the
     * leading number of its text (0 without one).
     */
    private static function number(mixed $arg): int|float
    {
        if (is_int($arg) || is_float($arg)) {
            return $arg;
        }
        if (is_bool($arg) || $arg === null) {
            return (int) $arg;
        }
        if (is_array($arg) || !preg_match(self::LEADING_NUMBER, (string) $arg, $m)) {
            return 0;
        }
        return strpbrk($m[0], '.eE') === false ? (int) $m[0] : (float) $m[0];
    }

    /** An argument for an integer conversion: the fraction dropped. */
    private static function integer(mixed $arg): int
    {
        $n = self::number($arg);
        return is_float($n) ? (is_finite($n) ? (int) $n : 0) : $n;
    }

    /** The UTF-8 character of a code point, U+FFFD for none. */
    private static function character(int $cp): string
    {
        if ($cp < 0 || $cp > 0x10FFFF || ($cp >= 0xD800 && $cp <= 0xDFFF)) {
            $cp = 0xFFFD;
        }
        if ($cp < 0x80) {
            return \chr($cp);
        }
        if ($cp < 0x800) {
            return \chr(0xC0 | ($cp >> 6)) . \chr(0x80 | ($cp & 0x3F));
        }
        if ($cp < 0x10000) {
            return \chr(0xE0 | ($cp >> 12)) . \chr(0x80 | (($cp >> 6) & 0x3F)) . \chr(0x80 | ($cp & 0x3F));
        }
        return \chr(0xF0 | ($cp >> 18)) . \chr(0x80 | (($cp >> 12) & 0x3F))
            . \chr(0x80 | (($cp >> 6) & 0x3F)) . \chr(0x80 | ($cp & 0x3F));
    }

    /**
     * The characters of a UTF-8 string, its bytes when it is not UTF-8.
     *
     * @return list<string>
     */
    private static function chars(string $s): array
    {
        if ($s === '') {
            return [];
        }
        $chars = preg_split('//u', $s, -1, PREG_SPLIT_NO_EMPTY);
        return $chars === false ? str_split($s) : $chars;
    }

    /**
     * Escapes backslash, newline, tab, carriage return and double quote for a
     * dry-run line, in that order, as gettext_escape in Perl and Python does.
     */
    public static function escape(string $s): string
    {
        return str_replace(['\\', "\n", "\t", "\r", '"'], ['\\\\', '\\n', '\\t', '\\r', '\\"'], $s);
    }
}

// ----------------------------------------------------------------------
// Setup
// ----------------------------------------------------------------------

function l_dir(string $dir): void
{
    Internal::$dir = $dir;
}

function l_lang(string $lang): void
{
    Internal::$lang = $lang;
}

/**
 * Dry run: append the msgids of every call to $file instead of translating.
 * Passing null leaves dry mode.
 */
function l_dry(?string $file, bool $nowrite = false): void
{
    Internal::$dry = ($file === null || $file === '') ? null : $file;
    Internal::$nowrite = $nowrite;
    Internal::$nolocales = Internal::$dry !== null;
}

function l_nolocales(bool $on): void
{
    Internal::$nolocales = $on;
}

function ltd(string $domain): void
{
    check_dir();
    Internal::$domain = $domain;
}

/** @internal */
function check_dir(): void
{
    if (Internal::$dir === null && !Internal::$nolocales) {
        throw new \RuntimeException('please set a locale directory with l_dir() before using other translate functions');
    }
}

// ----------------------------------------------------------------------
// Translation
// ----------------------------------------------------------------------

function ldnp(string $td, ?string $ctxt, string $id, ?string $idp, ?int $n, mixed ...$args): string
{
    if ($id === '') {
        return $id;
    }
    check_dir();
    if ($idp !== null) {
        array_unshift($args, $n);
    }
    if (Internal::$dry !== null) {
        if (!Internal::$nowrite) {
            $save = [];
            if ($td !== '') {
                $save[] = '# domain: ' . $td;
            }
            if ($ctxt !== null && $ctxt !== '') {
                $save[] = 'msgctxt "' . Internal::escape($ctxt) . '"';
            }
            $save[] = 'msgid "' . Internal::escape($id) . '"';
            if ($idp !== null && $idp !== '') {
                $save[] = 'msgid_plural "' . Internal::escape($idp) . '"';
            }
            // file_put_contents appends in binary mode ("ab"): the bytes go out
            // unchanged, LF line ends on every platform.
            file_put_contents(Internal::$dry, implode("\n", $save) . "\n\n", FILE_APPEND);
        }
        return Internal::format($idp !== null && $n !== 1 ? $idp : $id, $args);
    }
    return Internal::format(Internal::lookup($td, $ctxt, $id, $idp, $n), $args);
}

function l(string $id, mixed ...$args): string
{
    return ldnp('', null, $id, null, null, ...$args);
}

function ln(string $id, string $idp, int $n, mixed ...$args): string
{
    return ldnp('', null, $id, $idp, $n, ...$args);
}

function lp(string $ctxt, string $id, mixed ...$args): string
{
    return ldnp('', $ctxt, $id, null, null, ...$args);
}

function lnp(string $ctxt, string $id, string $idp, int $n, mixed ...$args): string
{
    return ldnp('', $ctxt, $id, $idp, $n, ...$args);
}

function ld(string $td, string $id, mixed ...$args): string
{
    return ldnp($td, null, $id, null, null, ...$args);
}

function ldn(string $td, string $id, string $idp, int $n, mixed ...$args): string
{
    return ldnp($td, null, $id, $idp, $n, ...$args);
}

function ldp(string $td, string $ctxt, string $id, mixed ...$args): string
{
    return ldnp($td, $ctxt, $id, null, null, ...$args);
}

// ----------------------------------------------------------------------
// Deferred-translation markers: identity, the scraper sees the msgid.
// The plural variants return [singular, plural] so the call site can
// spread them with the count: ln(...Nn_('1 file', '%d files'), ...[$n]).
// ----------------------------------------------------------------------

function N_(string $id): string
{
    return $id;
}

/** @return array{string, string} */
function Nn_(string $sg, string $pl): array
{
    return [$sg, $pl];
}

function Np_(string $ctxt, string $id): string
{
    return $id;
}

/** @return array{string, string} */
function Nnp_(string $ctxt, string $sg, string $pl): array
{
    return [$sg, $pl];
}

function Nd_(string $td, string $id): string
{
    return $id;
}

/** @return array{string, string} */
function Ndn_(string $td, string $sg, string $pl): array
{
    return [$sg, $pl];
}

function Ndp_(string $td, string $ctxt, string $id): string
{
    return $id;
}

/** @return array{string, string} */
function Ndnp_(string $td, string $ctxt, string $sg, string $pl): array
{
    return [$sg, $pl];
}
