//! The Plural-Forms evaluator (spec: `.claude/skills/locale-simple-core/references/mo-reader.md` §3). The
//! expression is data from a file: a tokenizer and a recursive-descent parser
//! build a closure tree, nothing is executed any other way.

use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};

type Node = Box<dyn Fn(i64) -> i64 + Send + Sync>;

const MAX_DEPTH: usize = 100;
const MAX_LENGTH: usize = 1000;

/// Selects the translation form for a count.
pub struct PluralRule {
    nplurals: i64,
    eval: Node,
}

impl PluralRule {
    pub fn index(&self, n: i64) -> usize {
        let v = n.checked_abs().unwrap_or(i64::MAX);
        let i = (self.eval)(v);
        if i < 0 || i >= self.nplurals {
            0
        } else {
            i as usize
        }
    }
}

static WARNED: AtomicBool = AtomicBool::new(false);
static WARNINGS: AtomicUsize = AtomicUsize::new(0);

/// Allow the one-time warning again (tests).
pub fn reset_warning() {
    WARNED.store(false, Ordering::SeqCst);
}

/// How many fallback warnings were emitted so far (tests).
pub fn warning_count() -> usize {
    WARNINGS.load(Ordering::SeqCst)
}

fn warn_once() {
    if !WARNED.swap(true, Ordering::SeqCst) {
        WARNINGS.fetch_add(1, Ordering::SeqCst);
        eprintln!(
            "locale-simple: missing or unusable Plural-Forms header, falling back to \"n != 1\""
        );
    }
}

fn default_rule() -> PluralRule {
    PluralRule {
        nplurals: 2,
        eval: Box::new(|n| if n != 1 { 1 } else { 0 }),
    }
}

/// Takes the header entry of a `.mo` file (`None`: there is none). A missing
/// or unusable `Plural-Forms:` selects `n != 1` and warns once per process.
pub fn rule_from_header(header: Option<&str>) -> PluralRule {
    if let Some(h) = header {
        if let Some(line) = h
            .split('\n')
            .map(|l| l.trim_end_matches('\r'))
            .find(|l| l.starts_with("Plural-Forms:"))
        {
            if let Some(rule) = parse_plural_forms(line) {
                return rule;
            }
        }
    }
    warn_once();
    default_rule()
}

fn parse_plural_forms(line: &str) -> Option<PluralRule> {
    let nplurals: i64 = digits_after(line, "nplurals")?.parse().ok()?;
    if nplurals < 1 {
        return None;
    }
    let at = keyword_end(line, "plural")?;
    let expr = line[at..].split(&[';', '\n'][..]).next()?;
    Some(PluralRule {
        nplurals,
        eval: compile(expr)?,
    })
}

/// Position right after `key`, optional spaces, `=` and optional spaces, where
/// `key` stands on a word boundary (so "plural" does not match "nplurals").
fn keyword_end(line: &str, key: &str) -> Option<usize> {
    let mut from = 0;
    while let Some(p) = line[from..].find(key) {
        let start = from + p;
        let before_ok = start == 0
            || !line.as_bytes()[start - 1].is_ascii_alphanumeric() && line.as_bytes()[start - 1] != b'_';
        let rest = line[start + key.len()..].trim_start();
        if before_ok && rest.starts_with('=') {
            let after_eq = &rest[1..];
            return Some(line.len() - after_eq.trim_start().len());
        }
        from = start + key.len();
    }
    None
}

fn digits_after<'a>(line: &'a str, key: &str) -> Option<&'a str> {
    let at = keyword_end(line, key)?;
    let rest = &line[at..];
    let end = rest.find(|c: char| !c.is_ascii_digit()).unwrap_or(rest.len());
    if end == 0 {
        None
    } else {
        Some(&rest[..end])
    }
}

fn tokenize(src: &str) -> Option<Vec<String>> {
    if src.len() > MAX_LENGTH {
        return None;
    }
    let b = src.as_bytes();
    let mut toks = Vec::new();
    let mut i = 0;
    while i < b.len() {
        let c = b[i];
        if c.is_ascii_whitespace() {
            i += 1;
        } else if c.is_ascii_digit() {
            let j = b[i..]
                .iter()
                .position(|x| !x.is_ascii_digit())
                .map_or(b.len(), |p| i + p);
            toks.push(src[i..j].to_string());
            i = j;
        } else if i + 1 < b.len() && matches!(&src[i..i + 2], "||" | "&&" | "==" | "!=" | "<=" | ">=") {
            toks.push(src[i..i + 2].to_string());
            i += 2;
        } else if b"n+-*/%<>!?:()".contains(&c) {
            toks.push((c as char).to_string());
            i += 1;
        } else {
            return None;
        }
    }
    Some(toks)
}

const LEVELS: [&[&str]; 6] = [
    &["||"],
    &["&&"],
    &["==", "!="],
    &["<", ">", "<=", ">="],
    &["+", "-"],
    &["*", "/", "%"],
];

fn op(tok: &str) -> fn(i64, i64) -> i64 {
    match tok {
        "||" => |x, y| (x != 0 || y != 0) as i64,
        "&&" => |x, y| (x != 0 && y != 0) as i64,
        "==" => |x, y| (x == y) as i64,
        "!=" => |x, y| (x != y) as i64,
        "<" => |x, y| (x < y) as i64,
        ">" => |x, y| (x > y) as i64,
        "<=" => |x, y| (x <= y) as i64,
        ">=" => |x, y| (x >= y) as i64,
        "+" => |x, y| x.wrapping_add(y),
        "-" => |x, y| x.wrapping_sub(y),
        "*" => |x, y| x.wrapping_mul(y),
        "/" => |x, y| if y == 0 { 0 } else { x.wrapping_div(y) },
        _ => |x, y| if y == 0 { 0 } else { x.wrapping_rem(y) },
    }
}

struct Parser {
    toks: Vec<String>,
    pos: usize,
    depth: usize,
}

impl Parser {
    fn peek(&self) -> &str {
        self.toks.get(self.pos).map_or("", |s| s.as_str())
    }

    fn nested(&mut self, f: fn(&mut Parser) -> Option<Node>) -> Option<Node> {
        self.depth += 1;
        if self.depth > MAX_DEPTH {
            return None;
        }
        let r = f(self);
        self.depth -= 1;
        r
    }

    fn expr(&mut self) -> Option<Node> {
        let cond = self.binary(0)?;
        if self.peek() != "?" {
            return Some(cond);
        }
        self.pos += 1;
        let a = self.nested(Parser::expr)?;
        if self.peek() != ":" {
            return None;
        }
        self.pos += 1;
        let b = self.nested(Parser::expr)?;
        Some(Box::new(move |n| if cond(n) != 0 { a(n) } else { b(n) }))
    }

    fn binary(&mut self, level: usize) -> Option<Node> {
        if level == LEVELS.len() {
            return self.unary();
        }
        let mut left = self.binary(level + 1)?;
        while LEVELS[level].contains(&self.peek()) {
            let f = op(self.peek());
            self.pos += 1;
            let right = self.binary(level + 1)?;
            let l = left;
            left = Box::new(move |n| f(l(n), right(n)));
        }
        Some(left)
    }

    fn unary(&mut self) -> Option<Node> {
        if self.peek() == "!" {
            self.pos += 1;
            let inner = self.nested(Parser::unary)?;
            return Some(Box::new(move |n| (inner(n) == 0) as i64));
        }
        self.primary()
    }

    fn primary(&mut self) -> Option<Node> {
        let t = self.peek().to_string();
        self.pos += 1;
        if t == "n" {
            return Some(Box::new(|n| n));
        }
        if t == "(" {
            let inner = self.nested(Parser::expr)?;
            if self.peek() != ")" {
                return None;
            }
            self.pos += 1;
            return Some(inner);
        }
        if t.as_bytes().first().map_or(false, |c| c.is_ascii_digit()) {
            let v = t.parse::<i64>().unwrap_or(i64::MAX);
            return Some(Box::new(move |_| v));
        }
        None
    }
}

fn compile(src: &str) -> Option<Node> {
    let mut p = Parser {
        toks: tokenize(src)?,
        pos: 0,
        depth: 0,
    };
    let f = p.expr()?;
    if p.pos == p.toks.len() {
        Some(f)
    } else {
        None
    }
}
