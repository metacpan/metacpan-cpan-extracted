use anyhow::bail;
use anyhow::Result;
use memcache::Client;
use memcache::CommandError::KeyExists;
use memcache::MemcacheError::CommandError;
use memcache::Url;
use std::cell::Cell;
use std::cell::RefCell;
use std::collections::HashMap;
use std::ffi::CStr;
use std::ffi::CString;
use std::os::raw::c_char;
use std::str;
use std::time::Duration;
use std::time::SystemTime;

struct Rl {
    url: Url,
    client: Option<Client>,
    error: CString,
    read_timeout: Option<Duration>,
    write_timeout: Option<Duration>,
}

impl Rl {
    fn new(url: &CStr) -> Result<Rl> {
        let url = Url::parse(url.to_str()?)?;
        Ok(Rl {
            url: url,
            client: None,
            error: CString::new("")?,
            read_timeout: None,
            write_timeout: None,
        })
    }

    fn rate_limit(
        &mut self,
        prefix: &CStr,
        size: u32,
        rate_max: u32,
        rate_seconds: u32,
    ) -> Result<bool> {
        let prefix = prefix.to_str()?;

        /* re-connect if necessary */
        if let None = self.client {
            let client = Client::connect(String::from(self.url.clone()))?;
            client.set_read_timeout(self.read_timeout)?;
            client.set_write_timeout(self.write_timeout)?;
            self.client = Some(client);
        }

        if let Some(client) = &self.client {
            let now = SystemTime::now()
                .duration_since(SystemTime::UNIX_EPOCH)?
                .as_secs();

            let key = format!("{}-{}", prefix, now);
            match client.add(&key, 0, rate_seconds + 1) {
                Ok(()) => (),
                Err(CommandError(e)) if e == KeyExists => (),
                Err(e) => bail!(e),
            };

            let keys: Vec<String> = (1..u64::from(rate_seconds))
                .map(|n| format!("{}-{}", prefix, now - n))
                .collect();
            let keys: Vec<&str> = keys.iter().map(|s| &**s).collect();
            let tokens: HashMap<String, u32> = client.gets(&keys)?;
            let (value, cas_id) = match client.get(&key)? {
                Some((value, _, cas)) => (
                    match str::from_utf8(&value) {
                        Ok(value) => match value.parse::<u32>() {
                            Ok(value) => value,
                            Err(_) => 0,
                        },
                        Err(_) => 0,
                    },
                    cas,
                ),
                None => (0, None),
            };

            let mut sum = value + size;
            for (_, v) in tokens {
                sum += v;
            }

            if sum > rate_max {
                return Ok(true);
            }

            if let Some(cas_id) = cas_id {
                client.cas(&key, value + size, rate_seconds + 1, cas_id)?;
            }

            Ok(false)
        } else {
            // TODO
            // shouldn't get in here?
            // but should probably error?
            Ok(false)
        }
    }
}

thread_local!(
  static COUNTER: Cell<u64> = Cell::new(1);
  static STORE: RefCell<HashMap<u64, Rl>> = RefCell::new(HashMap::new())
);

#[no_mangle]
pub extern "C" fn rl_new(url: *const c_char) -> u64 {
    if url.is_null() {
        return 0;
    }

    let url = unsafe { CStr::from_ptr(url) };
    let rl = match Rl::new(url) {
        Ok(rl) => rl,
        Err(_) => return 0,
    };

    let index = COUNTER.with(|it| {
        let index = it.get();
        it.set(index + 1);
        index
    });

    STORE.with(|it| {
        let mut it = it.borrow_mut();
        it.insert(index, rl);
    });

    index
}

#[no_mangle]
pub extern "C" fn rl__rate_limit(
    index: u64,
    prefix: *const c_char,
    size: u32,
    rate_max: u32,
    rate_seconds: u32,
) -> i32 {
    let prefix = if prefix.is_null() {
        unsafe { CStr::from_ptr(b"\0".as_ptr() as *const c_char) }
    } else {
        unsafe { CStr::from_ptr(prefix) }
    };

    STORE.with(|it| {
        return match it.borrow_mut().get_mut(&index) {
            Some(rl) => match rl.rate_limit(prefix, size, rate_max, rate_seconds) {
                Ok(true) => 1,
                Ok(false) => 0,
                Err(e) => {
                    if let Ok(error) = CString::new(e.to_string()) {
                        rl.error = error;
                    }
                    rl.client = None;
                    -1
                }
            },
            None => -1,
        };
    })
}

#[no_mangle]
pub extern "C" fn rl__error(index: u64) -> *const c_char {
    STORE.with(|it| {
        let error = match it.borrow().get(&index) {
            Some(rl) => rl.error.as_ptr(),
            None => b"Invalid object index\0".as_ptr() as *const c_char,
        };

        error
    })
}

#[no_mangle]
pub extern "C" fn rl_set_write_timeout(index: u64, timeout: f64) {
    STORE.with(|it| {
        if let Some(rl) = it.borrow_mut().get_mut(&index) {
            rl.write_timeout = Some(Duration::from_secs_f64(timeout));
            if let Some(client) = &rl.client {
                let _ = client.set_write_timeout(rl.write_timeout);
            }
        }
    });
}

#[no_mangle]
pub extern "C" fn rl_set_read_timeout(index: u64, timeout: f64) {
    STORE.with(|it| {
        if let Some(rl) = it.borrow_mut().get_mut(&index) {
            rl.read_timeout = Some(Duration::from_secs_f64(timeout));
            if let Some(client) = &rl.client {
                let _ = client.set_read_timeout(rl.read_timeout);
            }
        }
    });
}

#[no_mangle]
pub extern "C" fn rl_DESTROY(index: u64) {
    STORE.with(|it| {
        it.borrow_mut().remove(&index);
    })
}
