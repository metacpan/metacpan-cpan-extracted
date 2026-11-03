/**
 * Locale Simple - Translation system based on gettext
 * Same API in Perl, Python and JavaScript
 *
 * @module locale-simple
 */

import { candidates, normalizeLang } from './locale-chain.js';

// Internal state
let currentDomain = null;
// Languages tried in order: the chain of l_lang(), then "" (bundles filed
// without a language)
let lookupChain = [''];
let localeDir = null;
let dryMode = false;
let noWrite = false;

// Translation data storage: { domain: { lang: { msgid: msgstr, ... } } }
const translations = {};

// Registered domains
const domains = new Set();

// One placeholder of mo-reader.md §5: %%, or the N$ position, the flags (with
// '<char> as pad character), width, .precision and the conversion.
const PLACEHOLDER = /%%|%(?:(\d+)\$)?((?:[-+ 0]|'.)*)(\d+)?(?:\.(\d*))?([bcdeEfFgGiosuxX])/gsu;

// The leading number of a string, read the way Perl reads it.
const LEADING_NUMBER = /^\s*[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/;

const RADIX = { b: 2, o: 8, x: 16, X: 16 };

/**
 * The number an argument stands for: a string gives its leading number, as
 * in Perl, and 0 without one.
 * @param {any} value
 * @returns {number}
 */
function toNumber(value) {
  if (typeof value === 'number') return value;
  if (typeof value === 'boolean') return value ? 1 : 0;
  const m = LEADING_NUMBER.exec(String(value));
  return m ? parseFloat(m[0]) : 0;
}

/**
 * Sign and digits of b d i o u x X, as C and Perl write them: the fraction is
 * dropped, b o u x X show a negative number as unsigned 64-bit, and the
 * precision is the minimum number of digits.
 * @returns {[string, string]}
 */
function integerParts(flags, conversion, digits, value) {
  const number = Math.trunc(toNumber(value));
  let big = BigInt(Number.isFinite(number) ? number : 0);
  let sign = '';
  if (conversion === 'd' || conversion === 'i') {
    if (big < 0) {
      sign = '-';
      big = -big;
    } else if (flags.includes('+')) {
      sign = '+';
    } else if (flags.includes(' ')) {
      sign = ' ';
    }
  } else {
    big = BigInt.asUintN(64, big);
  }
  let text = big.toString(RADIX[conversion] || 10);
  if (conversion === 'X') text = text.toUpperCase();
  if (digits !== undefined) {
    text = digits === 0 && big === BigInt(0) ? '' : text.padStart(digits, '0');
  }
  return [sign, text];
}

const TEN = BigInt(10);

/**
 * The exact decimal value of a finite number >= 0 as [digits, scale], so that
 * number = digits / 10^scale.
 * @param {number} number
 * @returns {[bigint, number]}
 */
function exactDecimal(number) {
  if (number === 0) return [BigInt(0), 0];
  const view = new DataView(new ArrayBuffer(8));
  view.setFloat64(0, number);
  const bits = view.getBigUint64(0);
  const biased = Number((bits >> BigInt(52)) & BigInt(0x7ff));
  let mantissa = bits & ((BigInt(1) << BigInt(52)) - BigInt(1));
  let exponent = -1074;
  if (biased !== 0) {
    mantissa += BigInt(1) << BigInt(52);
    exponent = biased - 1075;
  }
  if (exponent >= 0) return [mantissa << BigInt(exponent), 0];
  return [mantissa * BigInt(5) ** BigInt(-exponent), -exponent];
}

/**
 * digits / 10^scale rounded to `keep` decimal places (keep may be negative),
 * a tie to the even neighbour as in C; the result counts in units of 10^-keep.
 * @returns {bigint}
 */
function roundTo(digits, scale, keep) {
  if (keep >= scale) return digits * TEN ** BigInt(keep - scale);
  const divisor = TEN ** BigInt(scale - keep);
  const quotient = digits / divisor;
  const twice = (digits % divisor) * BigInt(2);
  const up = twice > divisor || (twice === divisor && quotient % BigInt(2) === BigInt(1));
  return up ? quotient + BigInt(1) : quotient;
}

function fixed(number, precision) {
  const [digits, scale] = exactDecimal(number);
  const text = roundTo(digits, scale, precision).toString().padStart(precision + 1, '0');
  return precision ? text.slice(0, -precision) + '.' + text.slice(-precision) : text;
}

/**
 * Mantissa digits (precision + 1 of them) and decimal exponent of number.
 * @returns {[string, number]}
 */
function exponentParts(number, precision) {
  if (number === 0) return ['0'.repeat(precision + 1), 0];
  const [digits, scale] = exactDecimal(number);
  let exponent = digits.toString().length - 1 - scale;
  let rounded = roundTo(digits, scale, precision - exponent);
  if (rounded.toString().length > precision + 1) {
    rounded /= TEN;
    exponent += 1;
  }
  return [rounded.toString(), exponent];
}

function exponential(mantissa, exponent) {
  const digits = mantissa.length > 1 ? mantissa[0] + '.' + mantissa.slice(1) : mantissa;
  return digits + 'e' + (exponent < 0 ? '-' : '+') + String(Math.abs(exponent)).padStart(2, '0');
}

function withoutTrailingZeros(text) {
  return text.includes('.') ? text.replace(/\.?0+$/, '') : text;
}

/**
 * Sign and digits of e E f F g G, as C and Perl write them.
 * @returns {[string, string]}
 */
function floatParts(flags, conversion, digits, value) {
  let number = toNumber(value);
  let sign = '';
  if (number < 0 || Object.is(number, -0)) {
    sign = '-';
    number = -number;
  } else if (flags.includes('+')) {
    sign = '+';
  } else if (flags.includes(' ')) {
    sign = ' ';
  }
  if (!Number.isFinite(number)) return [sign, Number.isNaN(number) ? 'NaN' : 'Inf'];
  const precision = digits === undefined ? 6 : digits;
  let text;
  if (conversion === 'f' || conversion === 'F') {
    text = fixed(number, precision);
  } else if (conversion === 'e' || conversion === 'E') {
    text = exponential(...exponentParts(number, precision));
  } else {
    // %g: %e or %f by the exponent, with the trailing zeros dropped
    const significant = precision === 0 ? 1 : precision;
    const [mantissa, exponent] = exponentParts(number, significant - 1);
    if (exponent < -4 || exponent >= significant) {
      const [head, tail] = exponential(mantissa, exponent).split('e');
      text = withoutTrailingZeros(head) + 'e' + tail;
    } else {
      text = withoutTrailingZeros(fixed(number, significant - 1 - exponent));
    }
  }
  if (conversion === 'E' || conversion === 'G') text = text.toUpperCase();
  return [sign, text];
}

/**
 * Fill sign and text up to the width: with the '<char> pad character, with
 * spaces on the right for -, with zeros after the sign for 0 where it applies,
 * else with spaces on the left. The width counts characters.
 */
function justify(sign, text, flags, width, pad, zero) {
  const body = sign + text;
  const fill = width - Array.from(body).length;
  if (fill <= 0) return body;
  const left = flags.includes('-');
  if (pad !== undefined) return left ? body + pad.repeat(fill) : pad.repeat(fill) + body;
  if (left) return body + ' '.repeat(fill);
  if (zero && flags.includes('0')) return sign + '0'.repeat(fill) + text;
  return ' '.repeat(fill) + body;
}

/**
 * sprintf with the conversions, flags, width, precision and N$ position of
 * mo-reader.md §5 (t/data/sprintf.json holds the shared rows). One pass over
 * the format: each placeholder is formatted on its own with its own argument,
 * so an argument value is never read as a format. %2$s picks its argument, a
 * placeholder without N$ takes the next one in order. A placeholder without
 * an argument stays as it is; extra arguments are ignored.
 * @param {string} format - Format string with %s, %d, %1$s style placeholders
 * @param {...any} args - Arguments to substitute
 * @returns {string} Formatted string
 */
function sprintf(format, ...args) {
  if (!format) return '';

  let next = 0;

  return format.replace(PLACEHOLDER, (match, position, flagText, width, precision, conversion) => {
    if (match === '%%') return '%';

    const index = position ? parseInt(position, 10) - 1 : next++;
    if (index < 0 || index >= args.length || args[index] === undefined) return match;
    const value = args[index];

    let pad;
    const flags = flagText.replace(/'(.)/gsu, (all, char) => {
      pad = char;
      return '';
    });
    const digits = precision === undefined ? undefined : parseInt(precision || '0', 10);

    let sign = '';
    let text;
    let zero = true;
    if (conversion === 's' || conversion === 'c') {
      if (conversion === 's') {
        text = String(value);
      } else {
        const code = Math.trunc(toNumber(value));
        text = code >= 0 && code <= 0x10ffff ? String.fromCodePoint(code) : '�';
      }
      if (digits !== undefined) text = Array.from(text).slice(0, digits).join('');
    } else if ('eEfFgG'.includes(conversion)) {
      [sign, text] = floatParts(flags, conversion, digits, value);
    } else {
      [sign, text] = integerParts(flags, conversion, digits, value);
      zero = digits === undefined;
    }

    return justify(sign, text, flags, width ? parseInt(width, 10) : 0, pad, zero);
  });
}

// Plural rules per loaded bundle: { domain: { lang: { nplurals, evaluate } } }
const pluralRules = {};

const DEFAULT_PLURAL_RULE = { nplurals: 2, evaluate: (n) => (n !== 1 ? 1 : 0) };

const MAX_PLURAL_DEPTH = 100;
const MAX_PLURAL_LENGTH = 1000;

let pluralWarned = false;

function warnPluralOnce(reason) {
  if (pluralWarned) return;
  pluralWarned = true;
  if (typeof console === 'object' && typeof console.warn === 'function') {
    console.warn('locale-simple: ' + reason + ', falling back to "n != 1"');
  }
}

const PLURAL_BINARY_LEVELS = [['||'], ['&&'], ['==', '!='], ['<', '>', '<=', '>='], ['+', '-'], ['*', '/', '%']];
const PLURAL_BINARY_OPS = {
  '||': (x, y) => (x || y ? 1 : 0),
  '&&': (x, y) => (x && y ? 1 : 0),
  '==': (x, y) => (x === y ? 1 : 0),
  '!=': (x, y) => (x !== y ? 1 : 0),
  '<': (x, y) => (x < y ? 1 : 0),
  '>': (x, y) => (x > y ? 1 : 0),
  '<=': (x, y) => (x <= y ? 1 : 0),
  '>=': (x, y) => (x >= y ? 1 : 0),
  '+': (x, y) => x + y,
  '-': (x, y) => x - y,
  '*': (x, y) => x * y,
  '/': (x, y) => (y === 0 ? 0 : Math.trunc(x / y)),
  '%': (x, y) => (y === 0 ? 0 : x % y),
};

/**
 * Compile the expression of a Plural-Forms header into a function of n.
 * Recursive-descent parser over the C subset gettext uses; the expression is
 * data from a .po/.mo file, so it is never eval'ed. Nesting of parentheses,
 * "!" and the branches of "?:" is capped at MAX_PLURAL_DEPTH.
 * @param {string} src
 * @returns {(n: number) => number}
 */
function compilePluralExpr(src) {
  if (src.length > MAX_PLURAL_LENGTH) throw new Error('plural expression too long');
  const toks = [];
  const re = /\s*(\d+|n|\|\||&&|==|!=|<=|>=|[-+*/%<>!?:()])/y;
  let at = 0;
  while (at < src.length && src.slice(at).trim() !== '') {
    re.lastIndex = at;
    const m = re.exec(src);
    if (!m) throw new Error('unexpected input in plural expression');
    toks.push(m[1]);
    at = re.lastIndex;
  }
  let pos = 0;
  let depth = 0;

  const peek = () => toks[pos];
  const take = (t) => {
    if (toks[pos] !== t) throw new Error('expected ' + t);
    pos++;
  };
  const nested = (fn) => {
    if (++depth > MAX_PLURAL_DEPTH) throw new Error('plural expression nested too deeply');
    const r = fn();
    depth--;
    return r;
  };

  function expr() {
    const cond = binary(0);
    if (peek() !== '?') return cond;
    pos++;
    const a = nested(expr);
    take(':');
    const b = nested(expr);
    return (n) => (cond(n) ? a(n) : b(n));
  }

  function binary(level) {
    if (level === PLURAL_BINARY_LEVELS.length) return unary();
    let left = binary(level + 1);
    while (PLURAL_BINARY_LEVELS[level].includes(peek())) {
      const op = PLURAL_BINARY_OPS[toks[pos++]];
      const l = left;
      const r = binary(level + 1);
      left = (n) => op(l(n), r(n));
    }
    return left;
  }

  function unary() {
    if (peek() === '!') {
      pos++;
      const inner = nested(unary);
      return (n) => (inner(n) ? 0 : 1);
    }
    return primary();
  }

  function primary() {
    const t = toks[pos++];
    if (t === 'n') return (n) => n;
    if (t !== undefined && /^\d+$/.test(t)) {
      const v = parseInt(t, 10);
      return () => v;
    }
    if (t === '(') {
      const inner = nested(expr);
      take(')');
      return inner;
    }
    throw new Error('unexpected token ' + t);
  }

  const fn = expr();
  if (pos !== toks.length) throw new Error('trailing tokens in plural expression');
  return fn;
}

const compiledRules = new Map();

/**
 * Parse a Plural-Forms header value ("nplurals=2; plural=n != 1;", with or
 * without the leading "Plural-Forms:") into a rule. Returns null if unusable.
 * @param {string} header
 * @returns {{nplurals: number, evaluate: (n: number) => number}|null}
 */
function parsePluralForms(header) {
  if (typeof header !== 'string') return null;
  if (compiledRules.has(header)) return compiledRules.get(header);
  let rule = null;
  const np = /\bnplurals\s*=\s*(\d+)/.exec(header);
  const ex = /\bplural\s*=\s*([^;\n]*)/.exec(header);
  if (np && ex && parseInt(np[1], 10) >= 1) {
    try {
      const fn = compilePluralExpr(ex[1]);
      const nplurals = parseInt(np[1], 10);
      rule = {
        nplurals,
        evaluate(n) {
          const idx = fn(Math.abs(Math.trunc(n)));
          return idx < 0 || idx >= nplurals ? 0 : idx;
        },
      };
    } catch (e) {
      rule = null;
    }
  }
  compiledRules.set(header, rule);
  return rule;
}

/**
 * Turn the optional pluralForms argument into a rule.
 * @param {string|{evaluate: Function}|null|undefined} spec
 * @param {boolean} warnIfAbsent - warn when nothing was given (header-based loading)
 */
function resolvePluralRule(spec, warnIfAbsent) {
  if (spec && typeof spec === 'object' && typeof spec.evaluate === 'function') return spec;
  if (spec === undefined || spec === null) {
    if (warnIfAbsent) warnPluralOnce('no Plural-Forms header');
    return DEFAULT_PLURAL_RULE;
  }
  const rule = parsePluralForms(spec);
  if (rule) return rule;
  warnPluralOnce('unusable Plural-Forms header');
  return DEFAULT_PLURAL_RULE;
}

function storePluralRule(domain, lang, rule) {
  if (!pluralRules[domain]) pluralRules[domain] = {};
  pluralRules[domain][lang] = rule;
}

/**
 * Get plural form index from the rule of a loaded bundle
 * @param {number} n - Count
 * @param {{evaluate: (n: number) => number}} rule
 * @returns {number} Plural form index
 */
function getPluralIndex(n, rule) {
  return rule.evaluate(n);
}

/**
 * Escape a string for a quoted .po line: backslash, newline, tab, carriage
 * return and double quote, as the other runtimes write them.
 * @param {string} text
 * @returns {string}
 */
function poEscape(text) {
  return String(text)
    .replace(/\\/g, '\\\\')
    .replace(/\n/g, '\\n')
    .replace(/\t/g, '\\t')
    .replace(/\r/g, '\\r')
    .replace(/"/g, '\\"');
}

/**
 * Write dry-run output (for extracting translatable strings): the block of
 * the other runtimes, `# domain:`, `msgctxt`, `msgid` and `msgid_plural` as
 * they apply, in one console.debug call. The lines are joined with \n and end
 * with \n, so the console shows the block followed by a blank line, the bytes
 * the other runtimes write to their dry-run file.
 * @param {string|null} domain
 * @param {string|null} msgctxt
 * @param {string} msgid
 * @param {string|null} msgid_plural
 */
function writeDry(domain, msgctxt, msgid, msgid_plural) {
  if (noWrite) return;
  if (typeof console !== 'object' || typeof console.debug !== 'function') return;

  const lines = [];
  if (domain) lines.push('# domain: ' + domain);
  if (msgctxt) lines.push('msgctxt "' + poEscape(msgctxt) + '"');
  lines.push('msgid "' + poEscape(msgid) + '"');
  if (msgid_plural) lines.push('msgid_plural "' + poEscape(msgid_plural) + '"');
  console.debug(lines.join('\n') + '\n');
}

const hasOwn = Object.prototype.hasOwnProperty;

/**
 * Own property only: msgids and languages are data, never prototype members
 * @param {Object|undefined} obj
 * @param {string} key
 */
function own(obj, key) {
  return obj != null && hasOwn.call(obj, key) ? obj[key] : undefined;
}

/**
 * Look up a translation across the locale chain (mo-reader.md §2): the first
 * language whose bundle has the key with a non-empty msgstr wins (for plurals:
 * a non-empty form, selected by that bundle's own rule); an empty or missing
 * one falls through to the next language, after the chain to the bundle filed
 * without a language, and finally to the msgid.
 * @param {string} domain
 * @param {string|null} msgctxt
 * @param {string} msgid
 * @param {string|null} msgid_plural
 * @param {number|null} n
 * @returns {string}
 */
function lookup(domain, msgctxt, msgid, msgid_plural, n) {
  const domainData = own(translations, domain);
  if (domainData) {
    const key = msgctxt ? msgctxt + '\u0004' + msgid : msgid;
    for (const lang of lookupChain) {
      const entry = own(own(domainData, lang), key);
      if (entry === undefined) continue;
      const forms = Array.isArray(entry) ? entry : [entry];
      const rule = own(own(pluralRules, domain), lang) || DEFAULT_PLURAL_RULE;
      const text = forms[msgid_plural && n !== null ? getPluralIndex(n, rule) : 0];
      if (typeof text === 'string' && text !== '') return text;
    }
  }
  return msgid_plural && n !== 1 ? msgid_plural : msgid;
}

// ============================================================================
// Public API - Setup functions
// ============================================================================

/**
 * Set the locale directory
 * @param {string} dir - Path to locale directory
 */
export function l_dir(dir) {
  localeDir = dir;
}

/**
 * Set the current language. A colon-separated list is tried in order, and
 * every entry also tries its language part: 'de_AT:fr' looks in de_AT, de,
 * fr, then in a bundle loaded without a language.
 * @param {string} lang - Language code (e.g., 'de_DE', 'pt-BR', 'de_AT:fr')
 */
export function l_lang(lang) {
  lookupChain = [...candidates(lang), ''];
}

/**
 * Enable dry-run mode for string extraction
 * @param {boolean} dry - Enable dry mode
 * @param {boolean} [nw=false] - Suppress output
 */
export function l_dry(dry, nw = false) {
  dryMode = dry;
  noWrite = nw;
}

/**
 * Accepted for API symmetry with the siblings, where it lifts the
 * "set l_dir first" check. JavaScript has no locale directory, so this
 * is a no-op.
 * @param {boolean} x - Ignored
 */
export function l_nolocales(x) {}

/**
 * Set the current text domain
 * @param {string} textdomain - Domain name
 */
export function ltd(textdomain) {
  if (!domains.has(textdomain)) {
    domains.add(textdomain);
  }
  currentDomain = textdomain;
}

/**
 * Load translation data for a domain
 * This should be called with the JSON data from po2json
 *
 * @example
 * // Load from JSON file or inline
 * loadTranslations('myapp', 'de_DE', {
 *   "Hello": "Hallo",
 *   "You have %d message": ["Du hast %d Nachricht", "Du hast %d Nachrichten"]
 * });
 *
 * @param {string} domain - Domain name
 * @param {string} lang - Language code, filed normalised ('pt-BR' → 'pt_BR');
 *   '' for a bundle that answers every language
 * @param {Object} data - Translation data object
 * @param {string|{evaluate: Function}} [pluralForms] - Plural-Forms header value,
 *   e.g. "nplurals=3; plural=...;". Omitted: "n != 1".
 */
export function loadTranslations(domain, lang, data, pluralForms) {
  lang = normalizeLang(lang);
  if (!translations[domain]) {
    translations[domain] = {};
  }
  translations[domain][lang] = data;
  storePluralRule(domain, lang, resolvePluralRule(pluralForms, false));
}

/**
 * Load translation data in po2json format (Gettext.js compatible)
 * @param {string} domain - Domain name
 * @param {Object} localeData - locale_data object from po2json
 */
export function loadLocaleData(domain, localeData) {
  const domainData = localeData[domain];
  if (!domainData) return;

  // Language from the header: "lang", else the gettext field "Language"
  // that bin/po2json writes (with a leading space); "" when neither is set
  const header = domainData[''] || {};
  const lang = normalizeLang(String(header.lang || header.Language || '').trim());

  if (!translations[domain]) {
    translations[domain] = {};
  }

  // Convert po2json format to our internal format
  const data = {};
  for (const [key, value] of Object.entries(domainData)) {
    if (key === '') continue; // Skip header
    // po2json format: msgid: [null, msgstr] or msgid: [null, msgstr[0], msgstr[1], ...]
    if (Array.isArray(value)) {
      if (value.length === 2 && value[0] === null) {
        data[key] = value[1];
      } else if (value.length > 2 || (value.length === 2 && value[0] !== null)) {
        // msgid_plural first, then one entry per plural form (a single one for nplurals=1)
        data[key] = value.slice(1);
      }
    } else {
      data[key] = value;
    }
  }

  translations[domain][lang] = data;
  storePluralRule(domain, lang, resolvePluralRule(header['Plural-Forms'], true));
}

// ============================================================================
// Public API - Translation functions
// ============================================================================

/**
 * Translate a string
 * @param {string} msgid - Message ID
 * @param {...any} args - sprintf arguments
 * @returns {string} Translated string
 */
export function l(msgid, ...args) {
  return ldnp('', null, msgid, null, null, ...args);
}

/**
 * Translate with plural forms
 * @param {string} msgid - Singular message ID
 * @param {string} msgid_plural - Plural message ID
 * @param {number} n - Count for plural selection
 * @param {...any} args - sprintf arguments
 * @returns {string} Translated string
 */
export function ln(msgid, msgid_plural, n, ...args) {
  return ldnp('', null, msgid, msgid_plural, n, ...args);
}

/**
 * Translate with context
 * @param {string} msgctxt - Message context
 * @param {string} msgid - Message ID
 * @param {...any} args - sprintf arguments
 * @returns {string} Translated string
 */
export function lp(msgctxt, msgid, ...args) {
  return ldnp('', msgctxt, msgid, null, null, ...args);
}

/**
 * Translate with context and plural forms
 * @param {string} msgctxt - Message context
 * @param {string} msgid - Singular message ID
 * @param {string} msgid_plural - Plural message ID
 * @param {number} n - Count for plural selection
 * @param {...any} args - sprintf arguments
 * @returns {string} Translated string
 */
export function lnp(msgctxt, msgid, msgid_plural, n, ...args) {
  return ldnp('', msgctxt, msgid, msgid_plural, n, ...args);
}

/**
 * Translate with domain
 * @param {string} domain - Text domain
 * @param {string} msgid - Message ID
 * @param {...any} args - sprintf arguments
 * @returns {string} Translated string
 */
export function ld(domain, msgid, ...args) {
  return ldnp(domain, null, msgid, null, null, ...args);
}

/**
 * Translate with domain and plural forms
 * @param {string} domain - Text domain
 * @param {string} msgid - Singular message ID
 * @param {string} msgid_plural - Plural message ID
 * @param {number} n - Count for plural selection
 * @param {...any} args - sprintf arguments
 * @returns {string} Translated string
 */
export function ldn(domain, msgid, msgid_plural, n, ...args) {
  return ldnp(domain, null, msgid, msgid_plural, n, ...args);
}

/**
 * Translate with domain and context
 * @param {string} domain - Text domain
 * @param {string} msgctxt - Message context
 * @param {string} msgid - Message ID
 * @param {...any} args - sprintf arguments
 * @returns {string} Translated string
 */
export function ldp(domain, msgctxt, msgid, ...args) {
  return ldnp(domain, msgctxt, msgid, null, null, ...args);
}

/**
 * Translate with domain, context and plural forms (full form)
 * @param {string} domain - Text domain (empty string for current domain)
 * @param {string|null} msgctxt - Message context
 * @param {string} msgid - Singular message ID
 * @param {string|null} msgid_plural - Plural message ID
 * @param {number|null} n - Count for plural selection
 * @param {...any} args - sprintf arguments
 * @returns {string} Translated string
 */
export function ldnp(domain, msgctxt, msgid, msgid_plural, n, ...args) {
  // An empty msgid is the .po header: it comes back empty, with no lookup
  // and no dry-run block.
  if (msgid === '') return '';
  const td = domain || currentDomain || '';

  // Add n to args if plural
  const allArgs = msgid_plural ? [n, ...args] : args;

  if (dryMode) {
    writeDry(domain || null, msgctxt, msgid, msgid_plural);
    const text = msgid_plural && n !== 1 ? msgid_plural : msgid;
    return sprintf(text, ...allArgs);
  }

  const translated = lookup(td, msgctxt, msgid, msgid_plural, n);
  return sprintf(translated, ...allArgs);
}

// ============================================================================
// Deferred-translation markers
// ============================================================================
//
// Runtime no-ops that exist so the scraper can treat them as msgid sources
// while render-time code stays in charge of the actual lookup. Use these
// where the locale is not yet known (module top-level, DSLs, class fields)
// and hand the stored msgid(s) to the matching l*() later. Plural variants
// return [sg, pl] so the caller can spread them into ln(...plur, n).

export function N_(msgid)                      { return msgid; }
export function Nn_(sg, pl)                    { return [sg, pl]; }
export function Np_(ctxt, msgid)               { return msgid; }
export function Nnp_(ctxt, sg, pl)             { return [sg, pl]; }
export function Nd_(domain, msgid)             { return msgid; }
export function Ndn_(domain, sg, pl)           { return [sg, pl]; }
export function Ndp_(domain, ctxt, msgid)      { return msgid; }
export function Ndnp_(domain, ctxt, sg, pl)    { return [sg, pl]; }

// ============================================================================
// Default export with all functions
// ============================================================================

export default {
  l_dir,
  l_lang,
  l_dry,
  l_nolocales,
  ltd,
  loadTranslations,
  loadLocaleData,
  l,
  ln,
  lp,
  lnp,
  ld,
  ldn,
  ldp,
  ldnp,
  N_,
  Nn_,
  Np_,
  Nnp_,
  Nd_,
  Ndn_,
  Ndp_,
  Ndnp_,
};
