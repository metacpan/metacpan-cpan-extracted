/**
 * Locale Simple - Translation system based on gettext
 * Same API in Perl, Python and JavaScript
 *
 * @module locale-simple
 */

// Internal state
let currentDomain = null;
let currentLang = null;
let localeDir = null;
let dryMode = false;
let noWrite = false;

// Translation data storage: { domain: { lang: { msgid: msgstr, ... } } }
const translations = {};

// Registered domains
const domains = new Set();

/**
 * sprintf implementation supporting positional and sequential placeholders
 * @param {string} format - Format string with %s, %d, %1$s style placeholders
 * @param {...any} args - Arguments to substitute
 * @returns {string} Formatted string
 */
function sprintf(format, ...args) {
  if (!format) return '';

  let argIndex = 0;

  return format.replace(
    /%%|%(?:(\d+)\$)?([+-]?)([ 0])?(\d+)?(?:\.(\d+))?([sdifoxXeEgGcb%])/g,
    (match, position, sign, pad, width, precision, type) => {
      if (match === '%%') return '%';

      const idx = position ? parseInt(position, 10) - 1 : argIndex++;
      let value = args[idx];

      if (value === undefined) return match;

      switch (type) {
        case 's':
          value = String(value);
          break;
        case 'd':
        case 'i':
          value = parseInt(value, 10).toString();
          break;
        case 'f':
          value = precision !== undefined
            ? parseFloat(value).toFixed(parseInt(precision, 10))
            : parseFloat(value).toString();
          break;
        case 'o':
          value = parseInt(value, 10).toString(8);
          break;
        case 'x':
          value = parseInt(value, 10).toString(16);
          break;
        case 'X':
          value = parseInt(value, 10).toString(16).toUpperCase();
          break;
        case 'e':
          value = parseFloat(value).toExponential(precision ? parseInt(precision, 10) : undefined);
          break;
        case 'E':
          value = parseFloat(value).toExponential(precision ? parseInt(precision, 10) : undefined).toUpperCase();
          break;
        case 'g':
        case 'G':
          value = parseFloat(value).toPrecision(precision ? parseInt(precision, 10) : undefined);
          if (type === 'G') value = value.toUpperCase();
          break;
        case 'c':
          value = String.fromCharCode(parseInt(value, 10));
          break;
        case 'b':
          value = parseInt(value, 10).toString(2);
          break;
      }

      // Handle width padding
      if (width) {
        const padChar = pad === '0' ? '0' : ' ';
        const padWidth = parseInt(width, 10);
        if (value.length < padWidth) {
          if (sign === '-') {
            value = value.padEnd(padWidth, padChar);
          } else {
            value = value.padStart(padWidth, padChar);
          }
        }
      }

      return value;
    }
  );
}

/**
 * Get plural form index for a language
 * Default: Germanic plural rules (n != 1)
 * @param {number} n - Count
 * @param {string} [lang] - Language code
 * @returns {number} Plural form index
 */
function getPluralIndex(n, lang) {
  // Germanic languages (en, de, nl, etc.): nplurals=2; plural=(n != 1)
  // This is the most common case
  return n !== 1 ? 1 : 0;
}

/**
 * Write dry-run output (for extracting translatable strings)
 * @param {string|null} domain
 * @param {string|null} msgctxt
 * @param {string} msgid
 * @param {string|null} msgid_plural
 */
function writeDry(domain, msgctxt, msgid, msgid_plural) {
  if (noWrite) return;
  if (typeof console !== 'object' || typeof console.debug !== 'function') return;

  if (domain) console.debug('# domain: ' + domain);
  if (msgctxt) console.debug('msgctxt "' + msgctxt + '"');
  if (msgid) console.debug('msgid "' + msgid + '"');
  if (msgid_plural) console.debug('msgid_plural "' + msgid_plural + '"');
  console.debug('');
}

/**
 * Look up a translation
 * @param {string} domain
 * @param {string|null} msgctxt
 * @param {string} msgid
 * @param {string|null} msgid_plural
 * @param {number|null} n
 * @returns {string}
 */
function lookup(domain, msgctxt, msgid, msgid_plural, n) {
  const domainData = translations[domain];
  if (!domainData) return msgid_plural && n !== 1 ? msgid_plural : msgid;

  const langData = domainData[currentLang] || domainData[''];
  if (!langData) return msgid_plural && n !== 1 ? msgid_plural : msgid;

  // Build lookup key (with context if present)
  const key = msgctxt ? msgctxt + '\u0004' + msgid : msgid;
  const entry = langData[key];

  if (!entry) return msgid_plural && n !== 1 ? msgid_plural : msgid;

  // Handle plural forms
  if (msgid_plural && n !== null) {
    if (Array.isArray(entry)) {
      const idx = getPluralIndex(n, currentLang);
      return entry[idx] || entry[0] || msgid;
    }
    // Single string, use for both forms
    return n !== 1 ? msgid_plural : entry;
  }

  return Array.isArray(entry) ? entry[0] : entry;
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
 * Set the current language
 * @param {string} lang - Language code (e.g., 'de_DE', 'en_US')
 */
export function l_lang(lang) {
  currentLang = lang;
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
 * @param {string} lang - Language code
 * @param {Object} data - Translation data object
 */
export function loadTranslations(domain, lang, data) {
  if (!translations[domain]) {
    translations[domain] = {};
  }
  translations[domain][lang] = data;
}

/**
 * Load translation data in po2json format (Gettext.js compatible)
 * @param {string} domain - Domain name
 * @param {Object} localeData - locale_data object from po2json
 */
export function loadLocaleData(domain, localeData) {
  const domainData = localeData[domain];
  if (!domainData) return;

  // Extract language from header
  const header = domainData[''] || {};
  const lang = header.lang || '';

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
      } else if (value.length > 2) {
        data[key] = value.slice(1);
      }
    } else {
      data[key] = value;
    }
  }

  translations[domain][lang] = data;
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
// Default export with all functions
// ============================================================================

export default {
  l_dir,
  l_lang,
  l_dry,
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
};
