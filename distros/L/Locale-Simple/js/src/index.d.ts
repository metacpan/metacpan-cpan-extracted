/**
 * Locale Simple - Translation system based on gettext
 * Same API in Perl, Python and JavaScript
 */

/**
 * Set the locale directory
 */
export function l_dir(dir: string): void;

/**
 * Set the current language
 */
export function l_lang(lang: string): void;

/**
 * Enable dry-run mode for string extraction
 */
export function l_dry(dry: boolean, noWrite?: boolean): void;

/**
 * Set the current text domain
 */
export function ltd(textdomain: string): void;

/**
 * Load translation data for a domain
 */
export function loadTranslations(
  domain: string,
  lang: string,
  data: Record<string, string | string[]>
): void;

/**
 * Load translation data in po2json format (Gettext.js compatible)
 */
export function loadLocaleData(
  domain: string,
  localeData: Record<string, Record<string, string | (string | null)[]>>
): void;

/**
 * Translate a string
 */
export function l(msgid: string, ...args: unknown[]): string;

/**
 * Translate with plural forms
 */
export function ln(
  msgid: string,
  msgid_plural: string,
  n: number,
  ...args: unknown[]
): string;

/**
 * Translate with context
 */
export function lp(msgctxt: string, msgid: string, ...args: unknown[]): string;

/**
 * Translate with context and plural forms
 */
export function lnp(
  msgctxt: string,
  msgid: string,
  msgid_plural: string,
  n: number,
  ...args: unknown[]
): string;

/**
 * Translate with domain
 */
export function ld(domain: string, msgid: string, ...args: unknown[]): string;

/**
 * Translate with domain and plural forms
 */
export function ldn(
  domain: string,
  msgid: string,
  msgid_plural: string,
  n: number,
  ...args: unknown[]
): string;

/**
 * Translate with domain and context
 */
export function ldp(
  domain: string,
  msgctxt: string,
  msgid: string,
  ...args: unknown[]
): string;

/**
 * Translate with domain, context and plural forms (full form)
 */
export function ldnp(
  domain: string,
  msgctxt: string | null,
  msgid: string,
  msgid_plural: string | null,
  n: number | null,
  ...args: unknown[]
): string;

declare const localeSimple: {
  l_dir: typeof l_dir;
  l_lang: typeof l_lang;
  l_dry: typeof l_dry;
  ltd: typeof ltd;
  loadTranslations: typeof loadTranslations;
  loadLocaleData: typeof loadLocaleData;
  l: typeof l;
  ln: typeof ln;
  lp: typeof lp;
  lnp: typeof lnp;
  ld: typeof ld;
  ldn: typeof ldn;
  ldp: typeof ldp;
  ldnp: typeof ldnp;
};

export default localeSimple;
