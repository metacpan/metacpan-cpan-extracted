//! src/runtime.rs

use crate::error::InlineLuaError;
use mlua::{Error as LuaError, Function, Lua, LuaSerdeExt, StdLib, Value};
use serde::Deserialize;
use serde_json::Value as JsonValue;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

pub type Result<T> = std::result::Result<T, InlineLuaError>;

impl From<LuaError> for InlineLuaError {
    fn from(err: LuaError) -> Self {
        InlineLuaError::EvalError(err.to_string())
    }
}

#[derive(Debug, Clone, Deserialize)]
pub struct LuaOptions {
    pub enable_fennel: bool,
    pub sandboxed: bool,
    pub cache_fennel: bool,
}

impl Default for LuaOptions {
    fn default() -> Self {
        Self {
            enable_fennel: true,
            sandboxed: true,
            cache_fennel: true,
        }
    }
}

pub struct LuaRuntime {
    lua: Lua,
    pub options: LuaOptions,
    fennel_cache: Arc<Mutex<HashMap<String, String>>>,
}

fn load_environment(lua: &Lua, options: &LuaOptions) -> mlua::Result<()> {
    if options.enable_fennel && !options.sandboxed {
        const FENNEL_SOURCE: &'static str = include_str!("../fennel.lua");
        let fennel_mod: Value = lua.load(FENNEL_SOURCE).set_name("fennel.lua").eval()?;
        lua.globals().set("fennel", fennel_mod)?;

        // This helper uses xpcall with a traceback handler.
        const LUA_HELPERS: &str = r#"
            function fennel_compile(source)
                if not fennel or not fennel.compileString then
                    return nil, "Fennel is not enabled or compiler not found"
                end
                local ok, res = pcall(fennel.compileString, source)
                if ok then return res, nil else return nil, tostring(res) end
            end
            function protected_eval_with_traceback(code)
                local func, err = load(code, "inline-code", "t")
                if not func then
                    -- Syntax error: return message directly.
                    return { ok = false, message = err }
                end

                -- This handler is called by xpcall on runtime errors.
                local function traceback_handler(err)
                    return debug.traceback(tostring(err), 2)
                end

                local ok, result = xpcall(func, traceback_handler)

                if ok then
                    return { ok = true, value = result }
                else
                    -- On error, 'result' is the string from our traceback_handler.
                    -- The message already contains the full traceback.
                    return { ok = false, message = result }
                end
            end
        "#;
        lua.load(LUA_HELPERS).set_name("inline-lua-helpers").exec()?;
    }
    Ok(())
}

impl LuaRuntime {
    pub fn new(options: LuaOptions) -> Result<Self> {
        let lua = if options.sandboxed {
            Lua::new()
        } else {
            unsafe { Lua::unsafe_new() }
        };

        let libs_to_load = if options.sandboxed {
            StdLib::ALL_SAFE
        } else {
            StdLib::ALL
        };

        lua.load_std_libs(libs_to_load)
            .map_err(|e| InlineLuaError::InitError(e.to_string()))?;

        load_environment(&lua, &options)
            .map_err(|e| InlineLuaError::SetupError(e.to_string()))?;

        Ok(Self {
            lua,
            options,
            fennel_cache: Arc::new(Mutex::new(HashMap::new())),
        })
    }

    pub fn eval(&self, code: &str) -> Result<JsonValue> {
        if self.options.sandboxed {
            let val: Value = self.lua.load(code).eval()?;
            return Ok(self.lua.from_value(val)?);
        }

        let protected_eval: Function = self.lua.globals().get("protected_eval_with_traceback")?;
        let result_table: mlua::Table = protected_eval.call(code)?;

        if result_table.get("ok")? {
            let val: Value = result_table.get("value")?;
            Ok(self.lua.from_value(val)?)
        } else {
            // REMINDER: The message from the new helper must contain the full error
            // string, including the traceback for runtime errors.
            let message: String = result_table.get("message")?;
            Err(InlineLuaError::EvalError(message))
        }
    }

    pub fn eval_fennel(&self, code: &str) -> Result<JsonValue> {
        if self.options.sandboxed {
            return Err(InlineLuaError::FennelNotEnabled);
        }
        
        let lua_code = if self.options.cache_fennel {
            self.compile_fennel_cached(code)?
        } else {
            self.compile_fennel(code)?
        };
        self.eval(&lua_code)
    }

    fn compile_fennel(&self, code: &str) -> Result<String> {
        let fennel_compile: Function = self.lua.globals().get("fennel_compile")?;
        let (compiled_code, err_msg): (Option<String>, Option<String>) = fennel_compile.call(code)?;
        match (compiled_code, err_msg) {
            (Some(lua_code), None) => Ok(lua_code),
            (None, Some(err)) => Err(InlineLuaError::FennelError(format!("Fennel compilation error: {}", err))),
            _ => Err(InlineLuaError::FennelError("Unknown error during Fennel compilation".to_string())),
        }
    }
    
    fn compile_fennel_cached(&self, code: &str) -> Result<String> {
        let mut cache = self.fennel_cache.lock().unwrap();
        if let Some(cached) = cache.get(code) {
            return Ok(cached.clone());
        }
        let compiled = self.compile_fennel(code)?;
        cache.insert(code.to_string(), compiled.clone());
        Ok(compiled)
    }
}
