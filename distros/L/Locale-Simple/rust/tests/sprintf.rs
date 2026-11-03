//! The "rows" of t/data/sprintf.json (mo-reader.md §5), shared with every
//! runtime, through `l` without a directory, which returns the msgid
//! formatted. "perl_python_rows" are the Perl and Python extras.
#![deny(warnings)]

use locale_simple::{l, l_nolocales};
use serde_json::Value;
use std::fmt::Display;

/// A JSON argument as a Rust caller would pass it: a string without its JSON
/// quotes, an integer as `i64`, any other number as `f64`.
fn arg(v: &Value) -> Box<dyn Display> {
    match v {
        Value::String(s) => Box::new(s.clone()),
        Value::Number(n) => match n.as_i64() {
            Some(i) => Box::new(i),
            None => Box::new(n.as_f64().expect("a number")),
        },
        other => panic!("unexpected argument {}", other),
    }
}

#[test]
fn sprintf_rows() {
    let text = std::fs::read_to_string("../t/data/sprintf.json").expect("sprintf.json");
    let vectors: Value = serde_json::from_str(&text).expect("valid JSON");
    let rows = vectors["rows"].as_array().expect("rows");
    assert!(!rows.is_empty());
    l_nolocales(true);
    let mut misses = Vec::new();
    for row in rows {
        let format = row["format"].as_str().unwrap();
        let want = row["want"].as_str().unwrap();
        let boxed: Vec<Box<dyn Display>> =
            row["args"].as_array().unwrap().iter().map(arg).collect();
        let args: Vec<&dyn Display> = boxed.iter().map(|b| b.as_ref()).collect();
        let got = l(format, &args);
        if got != want {
            misses.push(format!(
                "l({:?}, {}) = {:?}, want {:?}",
                format, row["args"], got, want
            ));
        }
    }
    assert!(
        misses.is_empty(),
        "{} of {} rows miss:\n{}",
        misses.len(),
        rows.len(),
        misses.join("\n")
    );
}
