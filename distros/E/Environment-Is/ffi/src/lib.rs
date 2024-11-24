use is_docker::is_docker;
use is_wsl::is_wsl;
use is_interactive::is_interactive;

#[no_mangle]
pub extern "C" fn iz_is_docker() -> bool {
    is_docker()
}

#[no_mangle]
pub extern "C" fn iz_is_wsl() -> bool {
    is_wsl()
}

#[no_mangle]
pub extern "C" fn iz_is_interactive() -> bool {
    is_interactive()
}
