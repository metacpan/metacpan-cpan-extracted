/**
 * Locale Simple - Translation system based on gettext
 * Same API in Perl, Python and JavaScript
 */

/**
 * Set the locale directory
 */
export function l_dir(dir: string): void;

/**
 * Set the current language. A colon-separated list is tried in order, and
 * every entry also tries its language part: "de_AT:fr" looks in de_AT, de,
 * fr, then in a bundle loaded without a language.
 */
export function l_lang(lang: string): void;

/**
 * Enable dry-run mode for string extraction: every translation returns its
 * msgid (or the plural for n != 1), formatted with its arguments, and writes
 * its block (`# domain:`, `msgctxt`, `msgid`, `msgid_plural`, escaped as in a
 * .po file) in one console.debug call. A true noWrite keeps dry-run mode
 * without the output.
 */
export function l_dry(dry: boolean, noWrite?: boolean): void;

/**
 * Accepted for API symmetry with the siblings; a no-op in JavaScript,
 * which has no locale directory
 */
export function l_nolocales(nolocales: boolean): void;

/**
 * Set the current text domain
 */
export function ltd(textdomain: string): void;

/**
 * A compiled plural rule: index of the plural form for n.
 */
export interface PluralRule {
  nplurals: number;
  evaluate(n: number): number;
}

/**
 * Load translation data for a domain. `lang` is filed normalised
 * ("pt-BR" → "pt_BR"); "" files a bundle that answers every language.
 * `pluralForms` is the value of the Plural-Forms header
 * (e.g. "nplurals=2; plural=n != 1;"); omitted means "n != 1".
 */
export function loadTranslations(
  domain: string,
  lang: string,
  data: Record<string, string | string[]>,
  pluralForms?: string | PluralRule | null
): void;

/**
 * The header of a po2json bundle (key ""): the gettext header fields
 * (`Language`, `Plural-Forms`, ...), optionally a `lang` field.
 */
export type Po2JsonHeader = Record<string, string>;

/**
 * A po2json entry: `[msgid_plural | null, msgstr, ...]`, or a plain msgstr.
 */
export type Po2JsonEntry = string | (string | null)[];

/**
 * One domain of po2json output: "" holds the header, every other key a msgid.
 */
export type Po2JsonDomain = Record<string, Po2JsonEntry | Po2JsonHeader>;

/**
 * Load translation data in po2json format (Gettext.js compatible). The bundle
 * is filed under the header's `lang`, else its `Language`; "" when neither is set.
 */
export function loadLocaleData(
  domain: string,
  localeData: Record<string, Po2JsonDomain>
): void;

/**
 * Translate a string. An empty msgid returns an empty string without a lookup.
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

/**
 * Deferred-translation markers — runtime no-ops that the scraper treats
 * as msgid sources. Use where strings must be declared before a user
 * locale is known; pass the stored msgid(s) to the matching l*() at
 * render time. Plural variants return [sg, pl].
 */
export function N_(msgid: string): string;
export function Nn_(msgid: string, msgid_plural: string): [string, string];
export function Np_(msgctxt: string, msgid: string): string;
export function Nnp_(
  msgctxt: string,
  msgid: string,
  msgid_plural: string
): [string, string];
export function Nd_(domain: string, msgid: string): string;
export function Ndn_(
  domain: string,
  msgid: string,
  msgid_plural: string
): [string, string];
export function Ndp_(domain: string, msgctxt: string, msgid: string): string;
export function Ndnp_(
  domain: string,
  msgctxt: string,
  msgid: string,
  msgid_plural: string
): [string, string];

declare const localeSimple: {
  l_dir: typeof l_dir;
  l_lang: typeof l_lang;
  l_dry: typeof l_dry;
  l_nolocales: typeof l_nolocales;
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
  N_: typeof N_;
  Nn_: typeof Nn_;
  Np_: typeof Np_;
  Nnp_: typeof Nnp_;
  Nd_: typeof Nd_;
  Ndn_: typeof Ndn_;
  Ndp_: typeof Ndp_;
  Ndnp_: typeof Ndnp_;
};

export default localeSimple;
