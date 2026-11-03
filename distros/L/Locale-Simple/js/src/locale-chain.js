/**
 * The locale chain of .claude/skills/locale-simple-core/references/mo-reader.md §2, shared with the PHP, Go
 * and Rust readers. Internal module, bundled into dist/; not part of the
 * package's public API.
 */

/**
 * Normalise one language tag: "-" becomes "_", then "@modifier" and
 * ".codeset" are stripped. No case folding.
 * ("pt-BR" → "pt_BR", "de_DE.UTF-8@euro" → "de_DE")
 * @param {string} tag
 * @returns {string}
 */
export function normalizeLang(tag) {
  let t = String(tag).replace(/-/g, '_');
  const at = t.indexOf('@');
  if (at >= 0) t = t.slice(0, at);
  const dot = t.indexOf('.');
  if (dot >= 0) t = t.slice(0, dot);
  return t;
}

/**
 * Turn a language string into the ordered lookup chain. The string is a
 * colon-separated list (GNU LANGUAGE syntax, "de_AT:fr"); each entry
 * contributes itself and then its part before the first "_". Empty, "C"
 * and "POSIX" entries contribute nothing; later duplicates are dropped.
 * ("de_AT:fr" → ["de_AT", "de", "fr"])
 * @param {string|null|undefined} effective
 * @returns {string[]}
 */
export function candidates(effective) {
  const out = [];
  const add = (c) => {
    if (!out.includes(c)) out.push(c);
  };
  for (const entry of String(effective ?? '').split(':')) {
    const e = normalizeLang(entry);
    if (e === '' || e === 'C' || e === 'POSIX') continue;
    add(e);
    const us = e.indexOf('_');
    if (us > 0) add(e.slice(0, us));
  }
  return out;
}
