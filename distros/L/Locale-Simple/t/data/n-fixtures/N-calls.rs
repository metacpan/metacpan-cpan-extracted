use locale_simple::{n_, nd_, ndn_, ndnp_, ndp_, nn_, nnp_, np_};

fn main() {
    n_!("Rust N plain");
    nn_!("Rust N one", "Rust N many");
    np_!("Rust_ctx", "Rust N ctx plain");
    nnp_!("Rust_ctx", "Rust N ctx one", "Rust N ctx many");
    nd_!("Rust_dom", "Rust N dom plain");
    ndn_!("Rust_dom", "Rust N dom one", "Rust N dom many");
    ndp_!("Rust_dom", "Rust_ctx", "Rust N dom ctx plain");
    ndnp_!("Rust_dom", "Rust_ctx", "Rust N dom ctx one", "Rust N dom ctx many");
}
