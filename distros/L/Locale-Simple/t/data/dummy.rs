// Fixture for the Rust scraper: lifetimes, chars, raw strings, attributes.

#[derive(Debug)]
struct Holder<'a> {
    text: &'a str,
}

fn first<'a>(s: &'a str) -> &'a str {
    let c = 'x';
    let q = '"';
    let _ = (c, q);
    locale_simple::l!("Rust path qualified");
    s
}

fn raw() {
    l!(r#"Rust raw with "quote" inside"#);
    l!(r##"Rust raw "# near terminator"##);
    l!(r"Rust raw no hashes");
    ln!("Rust one", "Rust many", 3);
}

fn derived() {
    #[allow(unused_must_use)]
    ld!("rust_dom", "Rust after attribute");
}

// l!("Rust commented out");
