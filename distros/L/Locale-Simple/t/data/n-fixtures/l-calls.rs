use locale_simple::{l, ld, ldn, ldnp, ldp, ln, lnp, lp};

fn main() {
    l!("Rust N plain");
    ln!("Rust N one", "Rust N many", 4);
    lp!("Rust_ctx", "Rust N ctx plain");
    lnp!("Rust_ctx", "Rust N ctx one", "Rust N ctx many", 4);
    ld!("Rust_dom", "Rust N dom plain");
    ldn!("Rust_dom", "Rust N dom one", "Rust N dom many", 4);
    ldp!("Rust_dom", "Rust_ctx", "Rust N dom ctx plain");
    ldnp!("Rust_dom", "Rust_ctx", "Rust N dom ctx one", "Rust N dom ctx many", 4);
}
