//! locale-simple for Rust: gettext-style translation helpers with sprintf
//! formatting, the same API as the Perl, Python, JavaScript, PHP and Go
//! siblings. It reads `.mo` files itself and has no dependencies.
//!
//! Rust has neither variadic functions nor runtime `%` formats, so the helpers
//! are macros ([`l!`], [`ln!`], [`lp!`], [`lnp!`], [`ld!`], [`ldn!`], [`ldp!`],
//! [`ldnp!`]) that collect their arguments as `&[&dyn Display]` and call the
//! function of the same name. The deferred markers are lower-case here
//! ([`n_!`], [`nn_!`], ...): snake_case is the convention for Rust macros.
//!
//! The setup functions ([`l_dir`], [`l_lang`], [`l_dry`], [`l_nolocales`],
//! [`ltd`]) and the helper functions work on process-wide state;
//! [`Translator`] is the same set of operations as a value, for code that
//! translates per request in several languages at once.
//!
//! ```
//! use locale_simple::{l, ln, l_dir, l_lang, ltd};
//! l_dir("../t/data/locale");
//! ltd("test");
//! l_lang("de_DE");
//! assert_eq!(l("Hello", &[]), "Hallo");
//! ```

#[macro_use]
mod macros;
mod mo;
mod plural;
mod sprintf;

use std::fmt::Display;
use std::io::Write;
use std::path::PathBuf;
use std::sync::{Mutex, RwLock};

/// Items for the test suite, not part of the API.
#[doc(hidden)]
pub mod internal {
    pub use crate::mo::{parse_mo, Catalog};
    pub use crate::plural::{reset_warning, rule_from_header, warning_count, PluralRule};
    pub use crate::sprintf::sprintf;
    pub use crate::{candidates, effective_lang};
}

const NO_DIR: &str = "please set a locale directory with l_dir() before using other translate functions";

#[derive(Default)]
struct State {
    dir: Option<PathBuf>,
    lang: Option<String>,
    domain: Option<String>,
    dry: Option<PathBuf>,
    nowrite: bool,
    nolocales: bool,
}

/// An independent set of settings (directory, language, domain, dry run) with
/// the operations of the package functions. A Rust extension to the shared
/// API: all translators and the package functions share one catalog cache, so
/// each `.mo` file is read once per process. Safe for concurrent use.
pub struct Translator {
    state: RwLock<Option<State>>,
}

static GLOBAL: Translator = Translator::new();
static DRY_FILE: Mutex<()> = Mutex::new(());

impl Default for Translator {
    fn default() -> Self {
        Self::new()
    }
}

impl Translator {
    pub const fn new() -> Translator {
        Translator {
            state: RwLock::new(None),
        }
    }

    fn with_mut<R>(&self, f: impl FnOnce(&mut State) -> R) -> R {
        let mut g = self.state.write().unwrap_or_else(|e| e.into_inner());
        f(g.get_or_insert_with(State::default))
    }

    /// Directory holding `<lang>/LC_MESSAGES/<domain>.mo`.
    pub fn l_dir(&self, dir: impl Into<PathBuf>) {
        let dir = dir.into();
        self.with_mut(|s| s.dir = Some(dir));
    }

    /// The language, e.g. `de_DE` or `de_AT:fr`. Without it the environment
    /// decides (`LC_ALL`, `LC_MESSAGES`, `LANG`, `LANGUAGE`).
    pub fn l_lang(&self, lang: &str) {
        self.with_mut(|s| s.lang = Some(lang.to_string()));
    }

    /// Dry run: append the msgids of every call to `file` instead of
    /// translating. `None` leaves dry-run mode.
    pub fn l_dry(&self, file: Option<PathBuf>, nowrite: bool) {
        self.with_mut(|s| {
            s.nolocales = file.is_some();
            s.dry = file;
            s.nowrite = nowrite;
        });
    }

    /// Turns the "set `l_dir` first" check off (`true`) or on (`false`).
    pub fn l_nolocales(&self, on: bool) {
        self.with_mut(|s| s.nolocales = on);
    }

    /// The default text domain.
    ///
    /// # Panics
    /// Without a directory, unless `l_nolocales(true)`.
    pub fn ltd(&self, domain: &str) {
        self.with_mut(|s| {
            if s.dir.is_none() && !s.nolocales {
                panic!("{}", NO_DIR);
            }
            s.domain = Some(domain.to_string());
        });
    }

    /// The full form every helper delegates to. `msgctxt` of `None` or `""`
    /// means no context; with `plural` set, `n` selects the form and is
    /// prepended to `args`, as in the other runtimes.
    ///
    /// # Panics
    /// Without a directory, unless `l_nolocales(true)`.
    pub fn ldnp(
        &self,
        domain: &str,
        msgctxt: Option<&str>,
        msgid: &str,
        plural: Option<&str>,
        n: i64,
        args: &[&dyn Display],
    ) -> String {
        if msgid.is_empty() {
            return String::new();
        }
        let (dir, lang, cur_domain, dry, nowrite) = {
            let g = self.state.read().unwrap_or_else(|e| e.into_inner());
            let default = State::default();
            let s = g.as_ref().unwrap_or(&default);
            if s.dir.is_none() && !s.nolocales {
                drop(g);
                panic!("{}", NO_DIR);
            }
            (
                s.dir.clone(),
                s.lang.clone(),
                s.domain.clone(),
                s.dry.clone(),
                s.nowrite,
            )
        };
        let ctxt = msgctxt.filter(|c| !c.is_empty());
        let mut all: Vec<&dyn Display> = Vec::with_capacity(args.len() + 1);
        if plural.is_some() {
            all.push(&n);
        }
        all.extend_from_slice(args);

        if let Some(file) = dry {
            if !nowrite {
                write_dry(&file, domain, ctxt, msgid, plural);
            }
            let text = match plural {
                Some(p) if n != 1 => p,
                _ => msgid,
            };
            return sprintf::sprintf(text, &all);
        }
        let text = match dir {
            None => fallback(msgid, plural, n).to_string(),
            Some(dir) => {
                let domain = if domain.is_empty() {
                    cur_domain.as_deref().unwrap_or("messages")
                } else {
                    domain
                };
                let env = |k: &str| std::env::var(k).ok();
                let effective = effective_lang(&env, lang.as_deref());
                lookup(&dir, &effective, domain, ctxt, msgid, plural, n)
            }
        };
        sprintf::sprintf(&text, &all)
    }

    pub fn l(&self, msgid: &str, args: &[&dyn Display]) -> String {
        self.ldnp("", None, msgid, None, 0, args)
    }

    pub fn ln(&self, msgid: &str, plural: &str, n: i64, args: &[&dyn Display]) -> String {
        self.ldnp("", None, msgid, Some(plural), n, args)
    }

    pub fn lp(&self, msgctxt: &str, msgid: &str, args: &[&dyn Display]) -> String {
        self.ldnp("", Some(msgctxt), msgid, None, 0, args)
    }

    pub fn lnp(&self, msgctxt: &str, msgid: &str, plural: &str, n: i64, args: &[&dyn Display]) -> String {
        self.ldnp("", Some(msgctxt), msgid, Some(plural), n, args)
    }

    pub fn ld(&self, domain: &str, msgid: &str, args: &[&dyn Display]) -> String {
        self.ldnp(domain, None, msgid, None, 0, args)
    }

    pub fn ldn(&self, domain: &str, msgid: &str, plural: &str, n: i64, args: &[&dyn Display]) -> String {
        self.ldnp(domain, None, msgid, Some(plural), n, args)
    }

    pub fn ldp(&self, domain: &str, msgctxt: &str, msgid: &str, args: &[&dyn Display]) -> String {
        self.ldnp(domain, Some(msgctxt), msgid, None, 0, args)
    }
}

// ----------------------------------------------------------------------
// Package functions on the process-wide state
// ----------------------------------------------------------------------

/// Directory holding `<lang>/LC_MESSAGES/<domain>.mo`.
pub fn l_dir(dir: impl Into<PathBuf>) {
    GLOBAL.l_dir(dir)
}

/// The language, e.g. `de_DE` or `de_AT:fr`.
pub fn l_lang(lang: &str) {
    GLOBAL.l_lang(lang)
}

/// Dry run: append the msgids of every call to `file`; `None` leaves it.
pub fn l_dry(file: Option<PathBuf>, nowrite: bool) {
    GLOBAL.l_dry(file, nowrite)
}

/// Turns the "set `l_dir` first" check off (`true`) or on (`false`).
pub fn l_nolocales(on: bool) {
    GLOBAL.l_nolocales(on)
}

/// The default text domain.
pub fn ltd(domain: &str) {
    GLOBAL.ltd(domain)
}

pub fn ldnp(
    domain: &str,
    msgctxt: Option<&str>,
    msgid: &str,
    plural: Option<&str>,
    n: i64,
    args: &[&dyn Display],
) -> String {
    GLOBAL.ldnp(domain, msgctxt, msgid, plural, n, args)
}

pub fn l(msgid: &str, args: &[&dyn Display]) -> String {
    GLOBAL.l(msgid, args)
}

pub fn ln(msgid: &str, plural: &str, n: i64, args: &[&dyn Display]) -> String {
    GLOBAL.ln(msgid, plural, n, args)
}

pub fn lp(msgctxt: &str, msgid: &str, args: &[&dyn Display]) -> String {
    GLOBAL.lp(msgctxt, msgid, args)
}

pub fn lnp(msgctxt: &str, msgid: &str, plural: &str, n: i64, args: &[&dyn Display]) -> String {
    GLOBAL.lnp(msgctxt, msgid, plural, n, args)
}

pub fn ld(domain: &str, msgid: &str, args: &[&dyn Display]) -> String {
    GLOBAL.ld(domain, msgid, args)
}

pub fn ldn(domain: &str, msgid: &str, plural: &str, n: i64, args: &[&dyn Display]) -> String {
    GLOBAL.ldn(domain, msgid, plural, n, args)
}

pub fn ldp(domain: &str, msgctxt: &str, msgid: &str, args: &[&dyn Display]) -> String {
    GLOBAL.ldp(domain, msgctxt, msgid, args)
}

// ----------------------------------------------------------------------
// Locale resolution and lookup (spec §2)
// ----------------------------------------------------------------------

fn fallback<'a>(msgid: &'a str, plural: Option<&'a str>, n: i64) -> &'a str {
    match plural {
        Some(p) if n != 1 => p,
        _ => msgid,
    }
}

/// The language string: `lang` (from `l_lang`) wins, else the environment.
#[doc(hidden)]
pub fn effective_lang(env: &dyn Fn(&str) -> Option<String>, lang: Option<&str>) -> String {
    if let Some(l) = lang {
        return l.to_string();
    }
    let locale = ["LC_ALL", "LC_MESSAGES", "LANG"]
        .iter()
        .filter_map(|v| env(v))
        .find(|s| !s.is_empty())
        .unwrap_or_default();
    if locale.is_empty() || locale == "C" || locale == "POSIX" {
        return String::new();
    }
    env("LANGUAGE")
        .filter(|s| !s.is_empty())
        .unwrap_or(locale)
}

/// The ordered lookup chain of a language string.
#[doc(hidden)]
pub fn candidates(effective: &str) -> Vec<String> {
    let mut out: Vec<String> = Vec::new();
    let mut add = |s: &str| {
        if !out.iter().any(|o| o == s) {
            out.push(s.to_string());
        }
    };
    for entry in effective.split(':') {
        let mut e = entry.replace('-', "_");
        if let Some(at) = e.find('@') {
            e.truncate(at);
        }
        if let Some(dot) = e.find('.') {
            e.truncate(dot);
        }
        if e.is_empty() || e == "C" || e == "POSIX" {
            continue;
        }
        add(&e);
        if let Some(us) = e.find('_') {
            add(&e[..us]);
        }
    }
    out
}

fn lookup(
    dir: &std::path::Path,
    effective: &str,
    domain: &str,
    msgctxt: Option<&str>,
    msgid: &str,
    plural: Option<&str>,
    n: i64,
) -> String {
    let key = match msgctxt {
        Some(c) => format!("{}\x04{}", c, msgid),
        None => msgid.to_string(),
    };
    for cand in candidates(effective) {
        let path = dir.join(cand).join("LC_MESSAGES").join(format!("{}.mo", domain));
        let cat = match mo::load_catalog(&path) {
            Some(c) => c,
            None => continue,
        };
        if let Some(forms) = cat.entries.get(&key) {
            let idx = if plural.is_some() { cat.rule.index(n) } else { 0 };
            if let Some(f) = forms.get(idx) {
                if !f.is_empty() {
                    return f.clone();
                }
            }
        }
    }
    fallback(msgid, plural, n).to_string()
}

/// Escapes backslash, newline, tab, carriage return and double quote for a
/// dry-run line, in that order, as `gettext_escape` in Perl and Python does.
fn escape(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('\n', "\\n")
        .replace('\t', "\\t")
        .replace('\r', "\\r")
        .replace('"', "\\\"")
}

/// Appends one block to `file`. The bytes go out as built here, with `\n` line
/// ends on every platform, in UTF-8.
fn write_dry(file: &std::path::Path, domain: &str, ctxt: Option<&str>, msgid: &str, plural: Option<&str>) {
    let mut b = String::new();
    if !domain.is_empty() {
        b.push_str(&format!("# domain: {}\n", domain));
    }
    if let Some(c) = ctxt {
        b.push_str(&format!("msgctxt \"{}\"\n", escape(c)));
    }
    b.push_str(&format!("msgid \"{}\"\n", escape(msgid)));
    if let Some(p) = plural.filter(|p| !p.is_empty()) {
        b.push_str(&format!("msgid_plural \"{}\"\n", escape(p)));
    }
    b.push('\n');
    let _lock = DRY_FILE.lock().unwrap_or_else(|e| e.into_inner());
    if let Ok(mut f) = std::fs::OpenOptions::new().create(true).append(true).open(file) {
        let _ = f.write_all(b.as_bytes());
    }
}
