//! The GNU `.mo` reader (spec: `.claude/skills/locale-simple-core/references/mo-reader.md` §1) and the
//! process-wide catalog cache shared by the package functions and every
//! `Translator`.

use crate::plural::{rule_from_header, PluralRule};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};

/// One parsed `.mo` file: msgid (with `ctxt\x04` prefix when present) to the
/// translation forms, plus the plural rule of its header.
pub struct Catalog {
    pub entries: HashMap<String, Vec<String>>,
    pub rule: PluralRule,
}

static CATALOGS: Mutex<Option<HashMap<PathBuf, Option<Arc<Catalog>>>>> = Mutex::new(None);

/// Returns the catalog at `path`, reading it once per process. `None`: the file
/// is missing or unusable.
pub fn load_catalog(path: &Path) -> Option<Arc<Catalog>> {
    let mut guard = CATALOGS.lock().unwrap_or_else(|e| e.into_inner());
    let map = guard.get_or_insert_with(HashMap::new);
    if let Some(c) = map.get(path) {
        return c.clone();
    }
    let c = std::fs::read(path)
        .ok()
        .and_then(|d| parse_mo(&d))
        .map(Arc::new);
    map.insert(path.to_path_buf(), c.clone());
    c
}

fn u32_at(d: &[u8], at: usize, big: bool) -> Option<u32> {
    let b: [u8; 4] = d.get(at..at.checked_add(4)?)?.try_into().ok()?;
    Some(if big {
        u32::from_be_bytes(b)
    } else {
        u32::from_le_bytes(b)
    })
}

/// Parses a `.mo` file; any structural problem rejects the whole file.
pub fn parse_mo(d: &[u8]) -> Option<Catalog> {
    let big = match u32_at(d, 0, false)? {
        0x950412de => false,
        0xde120495 => true,
        _ => return None,
    };
    if u32_at(d, 4, big)? >> 16 != 0 {
        return None;
    }
    let n = u32_at(d, 8, big)? as usize;
    let o = u32_at(d, 12, big)? as usize;
    let t = u32_at(d, 16, big)? as usize;
    let size = d.len();
    if o.checked_add(n.checked_mul(8)?)? > size || t.checked_add(n.checked_mul(8)?)? > size {
        return None;
    }
    let string = |table: usize, i: usize| -> Option<&[u8]> {
        let len = u32_at(d, table + 8 * i, big)? as usize;
        let off = u32_at(d, table + 8 * i + 4, big)? as usize;
        d.get(off..off.checked_add(len)?)
    };
    let mut entries: HashMap<String, Vec<String>> = HashMap::new();
    for i in 0..n {
        let orig = string(o, i)?;
        let trans = string(t, i)?;
        let key = orig.split(|b| *b == 0).next().unwrap_or(orig);
        let forms = trans
            .split(|b| *b == 0)
            .map(|f| String::from_utf8_lossy(f).into_owned())
            .collect();
        entries.insert(String::from_utf8_lossy(key).into_owned(), forms);
    }
    let header = entries.remove("").map(|f| f.join("\0"));
    Some(Catalog {
        entries,
        rule: rule_from_header(header.as_deref()),
    })
}
