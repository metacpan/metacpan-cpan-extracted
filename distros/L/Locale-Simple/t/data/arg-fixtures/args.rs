// Fixture for t/52-scrape-args.t: what follows the strings is code.

fn main() {
    l!("Hello %s", name);
    let y = l!("Rust assign %s", &name);
    ln!("Rust count one", "Rust count many", n);
    ln!("%d file", "%d files", items.len());
    ln!("Rust cast %d", "Rust casts %d", n as i64, user.name.clone());
    l!("Rust paren %s", ")");
    l!("Rust comma %s %s", ",", r#"raw, ( "x""#);
    l!("Rust escape %s", "tab\t(");
    l!("Rust nested %s and %s", l!("Rust Apple"), x);
    ldp!("Rust_dom", "Rust_ctx", "Rust dp %s", vec![1, 2].len());
    l!(
        "Rust multi %s %s",
        first,
        names.join(", "),
    );
    ln!("Rust nested count one", "Rust nested count many", count(l!("Rust in count")));
    l!(not_constant, l!("Rust inside skipped"));
    // Last: no code after it could make up for a bracket read wrongly.
    l!("Rust char %c", '(');
}
