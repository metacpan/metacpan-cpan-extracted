//! The shared vectors of t/data/plural-forms.json and the .mo reader.
#![deny(warnings)]

mod support;

use locale_simple::internal::*;
use locale_simple::Translator;
use std::collections::BTreeMap;
use support::*;

fn check_plural(tag: &str, header: Option<&str>, cases: &serde_json::Value) {
    let nplurals = header
        .and_then(|h| h.split("nplurals=").nth(1))
        .and_then(|r| r.split(|c: char| !c.is_ascii_digit()).next())
        .and_then(|d| d.parse::<usize>().ok())
        .unwrap_or(2);
    let forms: Vec<String> = (0..nplurals).map(|k| format!("form{}", k)).collect();
    let mut entries = map(&[]);
    entries.insert("one".into(), forms.join("\0"));
    if let Some(h) = header {
        entries.insert("".into(), format!("{}\n", h));
    }
    let dir = temp_dir();
    write_mo(&dir, "xx", "pf", &build_mo(false, &entries, &map(&[("one", "many")])));
    let t = Translator::new();
    t.l_dir(&dir);
    t.ltd("pf");
    t.l_lang("xx");
    for c in cases.as_array().unwrap() {
        let (n, idx) = (c[0].as_i64().unwrap(), c[1].as_i64().unwrap());
        assert_eq!(t.ln("one", "many", n, &[]), format!("form{}", idx), "{}: n={}", tag, n);
    }
}

// The one-time warning is a process-wide flag, so all warning checks live in
// this one test.
#[test]
fn plural_vectors_and_warnings() {
    let v = vectors();
    for r in v["plural_forms"].as_array().unwrap() {
        reset_warning();
        let before = warning_count();
        let lang = r["lang"].as_str().unwrap();
        check_plural(lang, r["header"].as_str(), &r["cases"]);
        assert_eq!(warning_count(), before, "{} must not warn", lang);
    }
    for r in v["plural_edge_cases"].as_array().unwrap() {
        reset_warning();
        let before = warning_count();
        let name = r["name"].as_str().unwrap();
        check_plural(name, r["header"].as_str(), &r["cases"]);
        let want = usize::from(r["warns"].as_bool().unwrap());
        assert_eq!(warning_count() - before, want, "{}: warnings", name);
    }

    // warns once per process, not per file or lookup
    reset_warning();
    let before = warning_count();
    let dir = temp_dir();
    write_mo(&dir, "aa", "w", &build_mo(false, &map(&[("x", "y")]), &map(&[])));
    write_mo(
        &dir,
        "bb",
        "w",
        &build_mo(false, &map(&[("", "Plural-Forms: nplurals=2; plural=n ** 2;\n"), ("x", "z")]), &map(&[])),
    );
    let t = Translator::new();
    t.l_dir(&dir);
    t.ltd("w");
    for lang in ["aa", "bb", "aa", "nothing"] {
        t.l_lang(lang);
        t.l("x", &[]);
        t.ln("x", "xs", 3, &[]);
    }
    assert_eq!(warning_count() - before, 1);
}

#[test]
fn deeply_nested_expression_is_rejected_not_crashed() {
    let deep = format!("Plural-Forms: nplurals=2; plural={}n{};", "(".repeat(500), ")".repeat(500));
    let before_ok = rule_from_header(Some(&deep)).index(1);
    assert_eq!(before_ok, 0, "falls back to n != 1");
}

#[test]
fn locale_fallback_vectors() {
    for r in vectors()["locale_fallback"].as_array().unwrap() {
        let want: Vec<String> = r["candidates"].as_array().unwrap().iter().map(|c| c.as_str().unwrap().to_string()).collect();
        assert_eq!(candidates(r["input"].as_str().unwrap()), want, "{}", r["input"]);
    }
}

#[test]
fn env_resolution_vectors() {
    for r in vectors()["env_resolution"].as_array().unwrap() {
        let env: BTreeMap<String, String> = r["env"]
            .as_object()
            .unwrap()
            .iter()
            .map(|(k, v)| (k.clone(), v.as_str().unwrap().to_string()))
            .collect();
        let got = effective_lang(&|k| env.get(k).cloned(), None);
        assert_eq!(got, r["effective"].as_str().unwrap(), "{}", r["env"]);
    }
}

#[test]
fn l_lang_wins_over_environment() {
    assert_eq!(effective_lang(&|_| Some("de".into()), Some("fr")), "fr");
}

#[test]
fn mo_reader_fixture() {
    let data = std::fs::read(format!("{}/de_DE/LC_MESSAGES/test.mo", LOCALE_DIR)).unwrap();
    let c = parse_mo(&data).expect("fixture parses");
    assert_eq!(c.entries["alien\u{4}Hello"], vec!["Hallo Ausserirdischer"]);
    assert_eq!(
        c.entries["You have %d message"],
        vec!["Du hast %d Nachricht", "Du hast %d Nachrichten"]
    );
}

#[test]
fn mo_reader_big_endian() {
    let mo = build_mo(true, &map(&[("", STD_HEADER), ("Hello", "Hallo")]), &map(&[]));
    assert_eq!(parse_mo(&mo).expect("big endian").entries["Hello"], vec!["Hallo"]);
}

#[test]
fn mo_reader_rejects_bad_input() {
    let good = std::fs::read(format!("{}/de_DE/LC_MESSAGES/test.mo", LOCALE_DIR)).unwrap();
    let mut rev1 = good.clone();
    rev1[6] = 1;
    assert!(parse_mo(&[]).is_none());
    assert!(parse_mo(&[0; 64]).is_none());
    assert!(parse_mo(&good[..120]).is_none(), "truncated");
    assert!(parse_mo(&rev1).is_none(), "major revision 1");
}

#[test]
fn empty_msgstr_falls_through_the_chain() {
    let dir = temp_dir();
    write_mo(&dir, "de_AT", "d", &build_mo(false, &map(&[("", STD_HEADER), ("Hi", "")]), &map(&[])));
    write_mo(&dir, "de", "d", &build_mo(false, &map(&[("", STD_HEADER), ("Hi", "Hallo")]), &map(&[])));
    let t = Translator::new();
    t.l_dir(&dir);
    t.ltd("d");
    t.l_lang("de_AT");
    assert_eq!(t.l("Hi", &[]), "Hallo");
}
