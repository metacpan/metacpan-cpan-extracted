#![allow(dead_code)]

use std::collections::BTreeMap;
use std::path::PathBuf;
use std::sync::atomic::{AtomicUsize, Ordering};

pub const LOCALE_DIR: &str = "../t/data/locale";

pub fn vectors() -> serde_json::Value {
    let text = std::fs::read_to_string("../t/data/plural-forms.json").expect("plural-forms.json");
    serde_json::from_str(&text).expect("valid JSON")
}

pub fn temp_dir() -> PathBuf {
    static N: AtomicUsize = AtomicUsize::new(0);
    let dir = std::env::temp_dir().join(format!(
        "locale-simple-{}-{}",
        std::process::id(),
        N.fetch_add(1, Ordering::SeqCst)
    ));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

/// Builds a `.mo` file. `entries` maps msgid to msgstr (plural forms joined by
/// NUL); `plurals` maps a msgid to its msgid_plural.
pub fn build_mo(
    big: bool,
    entries: &BTreeMap<String, String>,
    plurals: &BTreeMap<String, String>,
) -> Vec<u8> {
    let put = |v: &mut Vec<u8>, x: usize| {
        let x = x as u32;
        v.extend_from_slice(&if big { x.to_be_bytes() } else { x.to_le_bytes() });
    };
    let mut pairs: Vec<(String, &String)> = entries
        .iter()
        .map(|(id, s)| match plurals.get(id) {
            Some(p) => (format!("{}\0{}", id, p), s),
            None => (id.clone(), s),
        })
        .collect();
    pairs.sort();
    let n = pairs.len();
    let (o, t) = (28, 28 + 8 * n);
    let pos = t + 8 * n;
    let (mut otab, mut ttab, mut blob) = (Vec::new(), Vec::new(), Vec::new());
    for (id, s) in &pairs {
        put(&mut otab, id.len());
        put(&mut otab, pos + blob.len());
        blob.extend_from_slice(id.as_bytes());
        blob.push(0);
        put(&mut ttab, s.len());
        put(&mut ttab, pos + blob.len());
        blob.extend_from_slice(s.as_bytes());
        blob.push(0);
    }
    let mut out = Vec::new();
    // a big-endian file starts with the bytes 95 04 12 de
    for v in [0x950412de_usize, 0, n, o, t, 0, 0] {
        put(&mut out, v);
    }
    out.extend(otab);
    out.extend(ttab);
    out.extend(blob);
    out
}

pub fn write_mo(dir: &std::path::Path, lang: &str, domain: &str, data: &[u8]) {
    let p = dir.join(lang).join("LC_MESSAGES");
    std::fs::create_dir_all(&p).unwrap();
    std::fs::write(p.join(format!("{}.mo", domain)), data).unwrap();
}

pub fn map(pairs: &[(&str, &str)]) -> BTreeMap<String, String> {
    pairs.iter().map(|(a, b)| (a.to_string(), b.to_string())).collect()
}

pub const STD_HEADER: &str = "Plural-Forms: nplurals=2; plural=n != 1;\n";
