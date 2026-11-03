#![deny(warnings)]

mod support;

use locale_simple::{l_dir, l_lang, ltd, Translator};
use std::sync::Arc;
use support::*;

fn german() -> Translator {
    let t = Translator::new();
    t.l_dir(LOCALE_DIR);
    t.ltd("test");
    t.l_lang("de_DE");
    t
}

#[test]
fn translators_are_independent() {
    let a = german();
    let b = german();
    b.l_lang("xx_YY");
    assert_eq!(a.l("Hello", &[]), "Hallo");
    assert_eq!(b.l("Hello", &[]), "Hello");
    assert_eq!(a.ln("You have %d message", "You have %d messages", 4, &[]), "Du hast 4 Nachrichten");
    assert_eq!(a.lp("alien", "Hello", &[]), "Hallo Ausserirdischer");
    assert_eq!(a.ld("othertest", "Hello", &[]), "Anderes Hallo");
}

#[test]
fn translator_and_package_functions_share_the_catalog_cache() {
    // The file is deleted after the translator read it: the package functions
    // can only still translate if they get the catalog from the shared cache.
    let dir = temp_dir();
    let mo = build_mo(false, &map(&[("", STD_HEADER), ("Hi", "Hallo")]), &map(&[]));
    write_mo(&dir, "de", "shared", &mo);
    let t = Translator::new();
    t.l_dir(&dir);
    t.ltd("shared");
    t.l_lang("de");
    assert_eq!(t.l("Hi", &[]), "Hallo");
    std::fs::remove_dir_all(dir.join("de")).unwrap();

    ld_state(&dir);
    assert_eq!(locale_simple::l("Hi", &[]), "Hallo", "served from the cache");
    assert_eq!(t.l("Hi", &[]), "Hallo");
}

// the package functions are process-wide: this is the only test here touching them
fn ld_state(dir: &std::path::Path) {
    l_dir(dir);
    ltd("shared");
    l_lang("de");
}

#[test]
#[should_panic(expected = "please set a locale directory")]
fn translator_requires_a_directory() {
    Translator::new().l("Hello", &[]);
}

#[test]
fn concurrent_use() {
    let t = Arc::new(german());
    let handles: Vec<_> = (0..8)
        .map(|i| {
            let t = Arc::clone(&t);
            std::thread::spawn(move || {
                for _ in 0..100 {
                    assert_eq!(t.l("Hello", &[]), "Hallo");
                    if i % 2 == 0 {
                        t.l_lang("de_DE");
                    }
                }
            })
        })
        .collect();
    for h in handles {
        h.join().unwrap();
    }
}
