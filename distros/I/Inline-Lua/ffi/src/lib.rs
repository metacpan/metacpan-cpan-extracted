//! src/lib.rs
//!
//! REMINDER: The `inline_lua_new` function is wrapped in a panic-catching
//! helper. If the Rust constructor panics (e.g., due to fennel.lua failing
//! to load), it wil now return a JSON error string instead of a null pointer.
//! This gives us visibility into the actual cause of the failure.

mod error;
mod runtime;

use runtime::{LuaOptions, LuaRuntime};
use serde::Deserialize;
use serde_json::json;
use std::ffi::{CStr, CString};
use libc::c_char;

/// A panic-catching helper that wraps all results in a JSON string.
fn an(f: impl FnOnce() -> Result<String, String>) -> *mut c_char {
    let result_json_string = match std::panic::catch_unwind(std::panic::AssertUnwindSafe(f)) {
        Ok(Ok(s)) => s,
        Ok(Err(e)) => {
            serde_json::to_string(&json!({ "error": e })).unwrap_or_else(|_| {
                r#"{"error":"Failed to serialize error message"}"#.to_string()
            })
        }
        Err(p) => {
            let msg = if let Some(s) = p.downcast_ref::<&str>() {
                *s
            } else if let Some(s) = p.downcast_ref::<String>() {
                s
            } else {
                "An unknown panic occurred"
            };
            serde_json::to_string(&json!({ "error": format!("Rust Panic: {}", msg) }))
                .unwrap_or_else(|_| r#"{"error":"Failed to serialize panic message"}"#.to_string())
        }
    };
    CString::new(result_json_string)
        .unwrap_or_else(|_| CString::new(r#"{"error":"Failed to create CString"}"#).unwrap())
        .into_raw()
}


#[derive(Deserialize, Debug, Default)]
struct FfiOptions {
    enable_fennel: Option<bool>,
    sandboxed: Option<bool>,
    cache_fennel: Option<bool>,
}

// REMINDER: The constructor now returns a `*mut c_char` (a JSON string)
// which will contain either the pointer address on success or an error on failure.
#[no_mangle]
pub extern "C" fn inline_lua_new(options_json: *const c_char) -> *mut c_char {
    an(|| {
        let options_str = unsafe {
            if options_json.is_null() {
                "{}"
            } else {
                CStr::from_ptr(options_json).to_str().unwrap_or("{}")
            }
        };

        let ffi_opts: FfiOptions = serde_json::from_str(options_str)
            .map_err(|e| format!("Failed to parse options JSON: {}", e))?;

        let options = LuaOptions {
            enable_fennel: ffi_opts.enable_fennel.unwrap_or(true),
            sandboxed: ffi_opts.sandboxed.unwrap_or(true),
            cache_fennel: ffi_opts.cache_fennel.unwrap_or(true),
        };

        let runtime = LuaRuntime::new(options).map_err(|e| e.to_string())?;
        let runtime_ptr = Box::into_raw(Box::new(runtime));

        // On success, return the pointer address as a JSON number
        serde_json::to_string(&json!({ "ok": runtime_ptr as usize }))
            .map_err(|e| format!("Failed to serialize runtime pointer: {}", e))
    })
}

#[no_mangle]
pub extern "C" fn inline_lua_destroy(runtime_ptr: *mut LuaRuntime) {
    if !runtime_ptr.is_null() {
        unsafe {
            let _ = Box::from_raw(runtime_ptr);
        }
    }
}

/// A helper to safely access the runtime from a pointer.
unsafe fn access_runtime<'a>(runtime_ptr: *mut LuaRuntime) -> Result<&'a LuaRuntime, String> {
    runtime_ptr.as_ref().ok_or_else(|| "Invalid Lua runtime pointer (was null)".to_string())
}

#[no_mangle]
pub extern "C" fn inline_lua_eval(runtime_ptr: *mut LuaRuntime, code: *const c_char) -> *mut c_char {
    an(|| {
        let runtime = unsafe { access_runtime(runtime_ptr)? };
        let code_str = unsafe { CStr::from_ptr(code).to_str().map_err(|e| e.to_string())? };

        let result_serde = runtime.eval(code_str).map_err(|e| e.to_string())?;

        serde_json::to_string(&json!({ "ok": result_serde }))
            .map_err(|e| format!("Failed to serialize result to JSON string: {}", e))
    })
}

#[no_mangle]
pub extern "C" fn inline_lua_eval_fennel(runtime_ptr: *mut LuaRuntime, code: *const c_char) -> *mut c_char {
     an(|| {
        let runtime = unsafe { access_runtime(runtime_ptr)? };
        let code_str = unsafe { CStr::from_ptr(code).to_str().map_err(|e| e.to_string())? };

        let result_serde = runtime.eval_fennel(code_str).map_err(|e| e.to_string())?;

        serde_json::to_string(&json!({ "ok": result_serde }))
            .map_err(|e| format!("Failed to serialize result to JSON string: {}", e))
    })
}

#[no_mangle]
pub extern "C" fn inline_lua_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}
