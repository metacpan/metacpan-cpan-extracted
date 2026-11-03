use locale_simple::{l, ln, lp};

// Rust: escapes in double quotes, none in raw strings.
fn main() {
    l!("RS newline\n");
    l!("RS tab\t quote \" apostrophe \' backslash \\");
    l!("RS hex \x41 unicode \u{e4} \u{1F_600}");
    l!("RS continued \
        line");
    l!(r"RS raw \n stays");
    ln!("RS one\n", "RS many\n", n);
    l!("0");
    lp!("0", "RS context zero");
    l!("RS bad \q is not read");
}
