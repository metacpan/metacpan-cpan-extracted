use locale_simple::{l, lp};

// Rust: whitespace before a raw string is skipped like before any literal.
fn main() {
    l!( r"RS raw after a space \n");
    l!(r#"RS raw with "quotes""#);
    lp!( "RS_ctx", r"RS raw context after a space");
}
