//! Port of python/test.py against the package functions and macros. They work
//! on process-wide state, so every test takes the lock and sets it up fresh.
#![deny(warnings)]

mod support;

use locale_simple::*;
use std::sync::{Mutex, MutexGuard};
use support::LOCALE_DIR;

static LOCK: Mutex<()> = Mutex::new(());

fn setup() -> MutexGuard<'static, ()> {
    let g = LOCK.lock().unwrap_or_else(|e| e.into_inner());
    l_dry(None, false);
    l_nolocales(false);
    l_dir(LOCALE_DIR);
    ltd("test");
    l_lang("de_DE");
    g
}

#[test]
fn translate() {
    let _g = setup();
    assert_eq!(l!("Hello"), "Hallo");
    assert_eq!(ln!("You have %d message", "You have %d messages", 4), "Du hast 4 Nachrichten");
    assert_eq!(ln!("You have %d message", "You have %d messages", 1), "Du hast 1 Nachricht");
    assert_eq!(ln!("You have %d message", "You have %d messages", 0), "Du hast 0 Nachrichten");
    assert_eq!(
        ln!("You have %d message of %s", "You have %d messages of %s", 1, "harry"),
        "Du hast 1 Nachricht von harry"
    );
    assert_eq!(
        ln!("You have %d message of %s", "You have %d messages of %s", 4, "harry"),
        "Du hast 4 Nachrichten von harry"
    );
    assert_eq!(
        ln!("%2$s brought %1$d message", "%2$s brought %1$d messages", 1, "harry"),
        "1 Nachricht gebracht von harry"
    );
    assert_eq!(
        ln!("%2$s has %1$d message", "%2$s has %1$d messages", 4, "harry"),
        "harry hat 4 Nachrichten"
    );
    assert_eq!(l!("Change order test %s %s", "one", "two"), "Andere Reihenfolge hier two one");
    assert_eq!(
        l!("Other change order test %s %s %s", 1, 2, 3),
        "Verhalten aus http://perldoc.perl.org/functions/sprintf.html 3 1 1"
    );
    assert_eq!(lp!("alien", "Hello"), "Hallo Ausserirdischer");
    assert_eq!(l!(""), "");
}

#[test]
fn context_plural() {
    let _g = setup();
    assert_eq!(lnp!("some_ctxt", "You have %d message", "You have %d messages", 1), "You have 1 message");
    assert_eq!(lnp!("some_ctxt", "You have %d message", "You have %d messages", 4), "You have 4 messages");
}

#[test]
fn domain_switching() {
    let _g = setup();
    ltd("othertest");
    ltd("test");
    assert_eq!(ld!("othertest", "Hello"), "Anderes Hallo");
    assert_eq!(
        ldn!("othertest", "You have %d message", "You have %d messages", 4),
        "Du hast 4 AndereNachrichten"
    );
    assert_eq!(
        ldn!("othertest", "You have %d message", "You have %d messages", 1),
        "Du hast 1 AndereNachricht"
    );
    assert_eq!(ld!("nonexistent", "Hello"), "Hello");
    assert_eq!(ldp!("othertest", "no_such_ctxt", "Hello"), "Hello");
    assert_eq!(l!("Hello"), "Hallo");
    assert_eq!(ldnp!("othertest", "no_such_ctxt", "Hello", "Hellos", 2), "Hellos");
}

#[test]
fn dry_run() {
    let _g = setup();
    let file = support::temp_dir().join("dry.po");
    l_dry(Some(file.clone()), false);
    assert_eq!(l!("Hello %s", "World"), "Hello World");
    assert_eq!(ln!("One %d", "Many %d", 1), "One 1");
    assert_eq!(ln!("One %d", "Many %d", 5), "Many 5");
    assert_eq!(ldp!("dom", "ctx", "Hello"), "Hello");
    let content = std::fs::read_to_string(&file).unwrap();
    for want in [
        "msgid \"Hello %s\"",
        "msgid \"One %d\"",
        "msgid_plural \"Many %d\"",
        "# domain: dom\nmsgctxt \"ctx\"\nmsgid \"Hello\"\n\n",
    ] {
        assert!(content.contains(want), "dry file lacks {:?}:\n{}", want, content);
    }
    l_dry(None, false);
}

/// What t/21-dryrun.t and python/test.py expect from the same calls, byte for byte.
const DRY_SHARED: &str = concat!(
    "msgid \"Hello\"\n",
    "\n",
    "# domain: othertest\n",
    "msgid \"Hello\"\n",
    "\n",
    "msgctxt \"alien\"\n",
    "msgid \"Hello\"\n",
    "\n",
    "msgid \"%2$s has %1$d message\"\n",
    "msgid_plural \"%2$s has %1$d messages\"\n",
    "\n",
    "# domain: othertest\n",
    "msgctxt \"inbox\"\n",
    "msgid \"You have %d message\"\n",
    "msgid_plural \"You have %d messages\"\n",
    "\n",
    r#"msgid "Say \"%s\"\\n\nGrüße""#,
    "\n",
    "\n",
    r#"msgid "Tab\there\rand CR""#,
    "\n",
    "\n",
);

#[test]
fn dry_run_shared_format() {
    let _g = setup();
    let file = support::temp_dir().join("shared.po");
    l_dry(Some(file.clone()), false);
    assert_eq!(l!("Hello"), "Hello");
    assert_eq!(l!(""), "");
    assert_eq!(ld!("othertest", "Hello"), "Hello");
    assert_eq!(lp!("alien", "Hello"), "Hello");
    assert_eq!(
        ln!("%2$s has %1$d message", "%2$s has %1$d messages", 2, "harry"),
        "harry has 2 messages"
    );
    assert_eq!(
        ldnp!("othertest", "inbox", "You have %d message", "You have %d messages", 1),
        "You have 1 message"
    );
    assert_eq!(l!("Say \"%s\"\\n\nGrüße", "hi"), "Say \"hi\"\\n\nGrüße");
    assert_eq!(l!("Tab\there\rand CR"), "Tab\there\rand CR");
    let bytes = std::fs::read(&file).unwrap();
    assert_eq!(std::str::from_utf8(&bytes).expect("UTF-8"), DRY_SHARED);
    l_dry(None, false);
}

#[test]
fn dry_run_nowrite() {
    let _g = setup();
    let file = support::temp_dir().join("dry.po");
    l_dry(Some(file.clone()), true);
    assert_eq!(l!("Hello"), "Hello");
    assert!(!file.exists());
    l_dry(None, false);
}

#[test]
#[should_panic(expected = "please set a locale directory with l_dir() before using other translate functions")]
fn error_without_locale_dir() {
    // a fresh translator is the only way to have "no directory" in a process
    // whose global state other tests configure
    Translator::new().l("Hello", &[]);
}

#[test]
fn nolocales_only_lifts_the_check() {
    let t = Translator::new();
    t.l_nolocales(true);
    assert_eq!(t.l("Hello %d", &[&1]), "Hello 1");
    t.l_dir(LOCALE_DIR);
    t.ltd("test");
    t.l_lang("de_DE");
    assert_eq!(t.l("Hello", &[]), "Hallo");
}

#[test]
fn language_switching_lifecycle() {
    let _g = setup();
    assert_eq!(l!("Hello"), "Hallo");
    l_lang("xx_YY");
    assert_eq!(l!("Hello"), "Hello");
    l_lang("de_DE");
    assert_eq!(l!("Hello"), "Hallo");
}

#[test]
#[allow(clippy::eq_op)]
fn deferred_markers() {
    let _g = setup();
    assert_eq!(n_!("Hello"), "Hello");
    assert_eq!(np_!("menu", "Open"), "Open");
    assert_eq!(nd_!("app", "Hi"), "Hi");
    assert_eq!(ndp_!("app", "menu", "Open"), "Open");
    assert_eq!(nn_!("1 file", "%d files"), ("1 file", "%d files"));
    assert_eq!(nnp_!("ctx", "1 file", "%d files"), ("1 file", "%d files"));
    assert_eq!(ndn_!("dom", "1 file", "%d files"), ("1 file", "%d files"));
    assert_eq!(ndnp_!("dom", "ctx", "1 file", "%d files"), ("1 file", "%d files"));

    assert_eq!(l!(n_!("Hello")), "Hallo");
    let (sg, pl) = nn_!("You have %d message", "You have %d messages");
    assert_eq!(ln!(sg, pl, 1), "Du hast 1 Nachricht");
    assert_eq!(ln!(sg, pl, 4), "Du hast 4 Nachrichten");
}
