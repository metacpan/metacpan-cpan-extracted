use strict;
use warnings;
use Test::More;
use Eshu;

sub rs { Eshu->indent_rust($_[0]) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. simple function
{
	my $code = <<'END';
fn add(a: i32, b: i32) -> i32 {
	a + b
}
END
	is(rs($code), $code, 'Rust: simple add function');
}

# 2. if/else expression
{
	my $code = <<'END';
fn clamp(v: i32, lo: i32, hi: i32) -> i32 {
	if v < lo {
		lo
	} else if v > hi {
		hi
	} else {
		v
	}
}
END
	is(rs($code), $code, 'Rust: if/else expression');
}

# 3. struct definition
{
	my $code = <<'END';
struct Point {
	x: f64,
	y: f64,
}
END
	is(rs($code), $code, 'Rust: struct definition');
}

# 4. impl block
{
	my $code = <<'END';
impl Point {
	fn new(x: f64, y: f64) -> Self {
		Self { x, y }
	}

	fn distance(&self, other: &Point) -> f64 {
		let dx = self.x - other.x;
		let dy = self.y - other.y;
		(dx * dx + dy * dy).sqrt()
	}
}
END
	is(rs($code), $code, 'Rust: impl block');
}

# 5. trait definition
{
	my $code = <<'END';
trait Shape {
	fn area(&self) -> f64;
	fn perimeter(&self) -> f64;
	fn describe(&self) -> String {
		format!("area={:.2} perimeter={:.2}", self.area(), self.perimeter())
	}
}
END
	is(rs($code), $code, 'Rust: trait with default method');
}

# 6. trait impl
{
	my $code = <<'END';
struct Circle {
	radius: f64,
}

impl Shape for Circle {
	fn area(&self) -> f64 {
		std::f64::consts::PI * self.radius * self.radius
	}

	fn perimeter(&self) -> f64 {
		2.0 * std::f64::consts::PI * self.radius
	}
}
END
	is(rs($code), $code, 'Rust: trait impl for Circle');
}

# 7. enum with data
{
	my $code = <<'END';
enum Shape {
	Circle { radius: f64 },
	Rectangle { width: f64, height: f64 },
	Triangle { base: f64, height: f64 },
}
END
	is(rs($code), $code, 'Rust: enum with struct variants');
}

# 8. match expression
{
	my $code = <<'END';
fn area(s: &Shape) -> f64 {
	match s {
		Shape::Circle { radius } => std::f64::consts::PI * radius * radius,
		Shape::Rectangle { width, height } => width * height,
		Shape::Triangle { base, height } => 0.5 * base * height,
	}
}
END
	is(rs($code), $code, 'Rust: match on enum');
}

# 9. Option handling
{
	my $code = <<'END';
fn find_first<T: PartialEq>(slice: &[T], target: &T) -> Option<usize> {
	for (i, item) in slice.iter().enumerate() {
		if item == target {
			return Some(i);
		}
	}
	None
}
END
	is(rs($code), $code, 'Rust: Option return with generic');
}

# 10. Result and ? operator
{
	my $code = <<'END';
use std::fs;
use std::io;

fn read_config(path: &str) -> Result<String, io::Error> {
	let contents = fs::read_to_string(path)?;
	Ok(contents.trim().to_string())
}
END
	is(rs($code), $code, 'Rust: Result with ? operator');
}

# 11. closures
{
	my $code = <<'END';
fn apply_twice<F: Fn(i32) -> i32>(f: F, x: i32) -> i32 {
	f(f(x))
}

fn double(x: i32) -> i32 {
	x * 2
}
END
	is(rs($code), $code, 'Rust: higher-order function with closure');
}

# 12. iterators
{
	my $code = <<'END';
fn sum_of_squares(nums: &[i32]) -> i32 {
	nums.iter()
	.map(|&x| x * x)
	.filter(|&x| x < 100)
	.sum()
}
END
	is(rs($code), $code, 'Rust: iterator chain');
}

# 13. lifetime annotations
{
	my $code = <<'END';
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
	if a.len() >= b.len() {
		a
	} else {
		b
	}
}
END
	is(rs($code), $code, 'Rust: lifetime annotations');
}

# 14. Vec operations
{
	my $code = <<'END';
fn flatten(nested: Vec<Vec<i32>>) -> Vec<i32> {
	nested.into_iter().flatten().collect()
}
END
	is(rs($code), $code, 'Rust: Vec flatten with iterators');
}

# 15. HashMap usage
{
	my $code = <<'END';
use std::collections::HashMap;

fn word_count(text: &str) -> HashMap<&str, usize> {
	let mut counts = HashMap::new();
	for word in text.split_whitespace() {
		*counts.entry(word).or_insert(0) += 1;
	}
	counts
}
END
	is(rs($code), $code, 'Rust: word count with HashMap');
}

# 16. derive macros
{
	my $code = <<'END';
#[derive(Debug, Clone, PartialEq)]
struct Config {
	host: String,
	port: u16,
	debug: bool,
}

impl Default for Config {
	fn default() -> Self {
		Config {
			host: "localhost".to_string(),
			port: 8080,
			debug: false,
		}
	}
}
END
	is(rs($code), $code, 'Rust: derive macros and Default impl');
}

# 17. error type
{
	my $code = <<'END';
#[derive(Debug)]
enum AppError {
	Io(std::io::Error),
	Parse(std::num::ParseIntError),
	Custom(String),
}

impl std::fmt::Display for AppError {
	fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
		match self {
			AppError::Io(e) => write!(f, "IO error: {}", e),
			AppError::Parse(e) => write!(f, "parse error: {}", e),
			AppError::Custom(s) => write!(f, "error: {}", s),
		}
	}
}
END
	is(rs($code), $code, 'Rust: custom error enum');
}

# 18. async function
{
	my $code = <<'END';
async fn fetch_url(url: &str) -> Result<String, reqwest::Error> {
	let response = reqwest::get(url).await?;
	let body = response.text().await?;
	Ok(body)
}
END
	is(rs($code), $code, 'Rust: async function with await');
}

# 19. Box and trait objects
{
	my $code = <<'END';
fn make_greeter(formal: bool) -> Box<dyn Fn(&str) -> String> {
	if formal {
		Box::new(|name| format!("Good day, {}.", name))
	} else {
		Box::new(|name| format!("Hey, {}!", name))
	}
}
END
	is(rs($code), $code, 'Rust: Box<dyn Trait> trait object');
}

# 20. macro_rules!
{
	my $code = <<'END';
macro_rules! hashmap {
	( $( $key:expr => $val:expr ),* $(,)? ) => {
		{
			let mut m = std::collections::HashMap::new();
			$(
				m.insert($key, $val);
			)*
			m
		}
	};
}
END
	is(rs($code), $code, 'Rust: macro_rules! hashmap');
}

# 21. struct update syntax
{
	my $code = <<'END';
fn with_port(cfg: Config, port: u16) -> Config {
	Config { port, ..cfg }
}
END
	is(rs($code), $code, 'Rust: struct update syntax');
}

# 22. while let
{
	my $code = <<'END';
fn drain_stack(stack: &mut Vec<i32>) -> i32 {
	let mut total = 0;
	while let Some(v) = stack.pop() {
		total += v;
	}
	total
}
END
	is(rs($code), $code, 'Rust: while let pattern');
}

# 23. if let
{
	my $code = <<'END';
fn print_first(v: &[i32]) {
	if let Some(&first) = v.first() {
		println!("first: {}", first);
	} else {
		println!("empty slice");
	}
}
END
	is(rs($code), $code, 'Rust: if let pattern');
}

# 24. nested match
{
	my $code = <<'END';
fn describe(r: Result<Option<i32>, &str>) -> &str {
	match r {
		Ok(Some(n)) if n > 0 => "positive",
		Ok(Some(0)) => "zero",
		Ok(Some(_)) => "negative",
		Ok(None) => "none",
		Err(_) => "error",
	}
}
END
	is(rs($code), $code, 'Rust: nested match with guard');
}

# 25. generic struct
{
	my $code = <<'END';
struct Pair<T> {
	first: T,
	second: T,
}

impl<T: std::fmt::Display> Pair<T> {
	fn show(&self) {
		println!("({}, {})", self.first, self.second);
	}
}
END
	is(rs($code), $code, 'Rust: generic struct with impl');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
	my $in = <<'END';
fn factorial(n: u64) -> u64 {
if n == 0 {
1
} else {
n * factorial(n - 1)
}
}
END
	my $exp = <<'END';
fn factorial(n: u64) -> u64 {
	if n == 0 {
		1
	} else {
		n * factorial(n - 1)
	}
}
END
	is(rs($in), $exp, 'Rust: unindented factorial normalised');
}

# 27
{
	my $in = <<'END';
fn is_palindrome(s: &str) -> bool {
let chars: Vec<char> = s.chars().collect();
let n = chars.len();
for i in 0..n/2 {
if chars[i] != chars[n-1-i] {
return false;
}
}
true
}
END
	my $exp = <<'END';
fn is_palindrome(s: &str) -> bool {
	let chars: Vec<char> = s.chars().collect();
	let n = chars.len();
	for i in 0..n/2 {
		if chars[i] != chars[n-1-i] {
			return false;
		}
	}
	true
}
END
	is(rs($in), $exp, 'Rust: unindented palindrome check normalised');
}

# 28
{
	my $in = <<'END';
fn gcd(mut a: u64, mut b: u64) -> u64 {
while b != 0 {
let t = b;
b = a % b;
a = t;
}
a
}
END
	my $exp = <<'END';
fn gcd(mut a: u64, mut b: u64) -> u64 {
	while b != 0 {
		let t = b;
		b = a % b;
		a = t;
	}
	a
}
END
	is(rs($in), $exp, 'Rust: unindented GCD normalised');
}

# 29
{
	my $in = <<'END';
fn binary_search<T: Ord>(slice: &[T], target: &T) -> Option<usize> {
let (mut lo, mut hi) = (0, slice.len());
while lo < hi {
let mid = lo + (hi - lo) / 2;
match slice[mid].cmp(target) {
std::cmp::Ordering::Equal => return Some(mid),
std::cmp::Ordering::Less => lo = mid + 1,
std::cmp::Ordering::Greater => hi = mid,
}
}
None
}
END
	my $exp = <<'END';
fn binary_search<T: Ord>(slice: &[T], target: &T) -> Option<usize> {
	let (mut lo, mut hi) = (0, slice.len());
	while lo < hi {
		let mid = lo + (hi - lo) / 2;
		match slice[mid].cmp(target) {
			std::cmp::Ordering::Equal => return Some(mid),
			std::cmp::Ordering::Less => lo = mid + 1,
			std::cmp::Ordering::Greater => hi = mid,
		}
	}
	None
}
END
	is(rs($in), $exp, 'Rust: unindented binary search normalised');
}

# 30
{
	my $in = <<'END';
fn merge_sorted(a: &[i32], b: &[i32]) -> Vec<i32> {
let mut out = Vec::with_capacity(a.len() + b.len());
let (mut i, mut j) = (0, 0);
while i < a.len() && j < b.len() {
if a[i] <= b[j] {
out.push(a[i]); i += 1;
} else {
out.push(b[j]); j += 1;
}
}
out.extend_from_slice(&a[i..]);
out.extend_from_slice(&b[j..]);
out
}
END
	my $exp = <<'END';
fn merge_sorted(a: &[i32], b: &[i32]) -> Vec<i32> {
	let mut out = Vec::with_capacity(a.len() + b.len());
	let (mut i, mut j) = (0, 0);
	while i < a.len() && j < b.len() {
		if a[i] <= b[j] {
			out.push(a[i]); i += 1;
		} else {
			out.push(b[j]); j += 1;
		}
	}
	out.extend_from_slice(&a[i..]);
	out.extend_from_slice(&b[j..]);
	out
}
END
	is(rs($in), $exp, 'Rust: unindented merge sorted normalised');
}

# 31
{
	my $in = <<'END';
fn partition<T, F>(v: Vec<T>, f: F) -> (Vec<T>, Vec<T>)
where F: Fn(&T) -> bool {
let mut yes = Vec::new();
let mut no  = Vec::new();
for item in v {
if f(&item) { yes.push(item); } else { no.push(item); }
}
(yes, no)
}
END
	my $exp = <<'END';
fn partition<T, F>(v: Vec<T>, f: F) -> (Vec<T>, Vec<T>)
where F: Fn(&T) -> bool {
	let mut yes = Vec::new();
	let mut no  = Vec::new();
	for item in v {
		if f(&item) { yes.push(item); } else { no.push(item); }
	}
	(yes, no)
}
END
	is(rs($in), $exp, 'Rust: unindented partition normalised');
}

# 32
{
	my $in = <<'END';
fn run_length_encode(s: &str) -> Vec<(char, usize)> {
let mut out = Vec::new();
let mut chars = s.chars().peekable();
while let Some(c) = chars.next() {
let mut count = 1;
while chars.peek() == Some(&c) {
chars.next();
count += 1;
}
out.push((c, count));
}
out
}
END
	my $exp = <<'END';
fn run_length_encode(s: &str) -> Vec<(char, usize)> {
	let mut out = Vec::new();
	let mut chars = s.chars().peekable();
	while let Some(c) = chars.next() {
		let mut count = 1;
		while chars.peek() == Some(&c) {
			chars.next();
			count += 1;
		}
		out.push((c, count));
	}
	out
}
END
	is(rs($in), $exp, 'Rust: unindented run-length encode normalised');
}

# 33
{
	my $in = <<'END';
fn matrix_multiply(a: &[Vec<f64>], b: &[Vec<f64>]) -> Vec<Vec<f64>> {
let n = a.len();
let m = b[0].len();
let k = b.len();
let mut c = vec![vec![0.0; m]; n];
for i in 0..n {
for j in 0..m {
for p in 0..k {
c[i][j] += a[i][p] * b[p][j];
}
}
}
c
}
END
	my $exp = <<'END';
fn matrix_multiply(a: &[Vec<f64>], b: &[Vec<f64>]) -> Vec<Vec<f64>> {
	let n = a.len();
	let m = b[0].len();
	let k = b.len();
	let mut c = vec![vec![0.0; m]; n];
	for i in 0..n {
		for j in 0..m {
			for p in 0..k {
				c[i][j] += a[i][p] * b[p][j];
			}
		}
	}
	c
}
END
	is(rs($in), $exp, 'Rust: unindented matrix multiply normalised');
}

# 34
{
	my $in = <<'END';
fn spiral_order(matrix: Vec<Vec<i32>>) -> Vec<i32> {
let mut result = Vec::new();
if matrix.is_empty() { return result; }
let (mut top, mut bottom, mut left, mut right) = (0, matrix.len()-1, 0, matrix[0].len()-1);
while top <= bottom && left <= right {
for col in left..=right { result.push(matrix[top][col]); }
top += 1;
for row in top..=bottom { result.push(matrix[row][right]); }
if right == 0 { break; } right -= 1;
if top <= bottom { for col in (left..=right).rev() { result.push(matrix[bottom][col]); } bottom -= 1; }
if top <= bottom { for row in (top..=bottom).rev() { result.push(matrix[row][left]); } left += 1; }
}
result
}
END
	my $once = rs($in);
	is(rs($once), $once, 'Rust: spiral order idempotent');
}

# 35
{
	my $in = <<'END';
use std::collections::VecDeque;
fn bfs(graph: &Vec<Vec<usize>>, start: usize) -> Vec<usize> {
let mut visited = vec![false; graph.len()];
let mut order = Vec::new();
let mut queue = VecDeque::new();
visited[start] = true;
queue.push_back(start);
while let Some(node) = queue.pop_front() {
order.push(node);
for &neighbor in &graph[node] {
if !visited[neighbor] {
visited[neighbor] = true;
queue.push_back(neighbor);
}
}
}
order
}
END
	my $once = rs($in);
	is(rs($once), $once, 'Rust: BFS idempotent');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
	"use std::fmt;\nstruct Matrix([[f64;2];2]);\nimpl fmt::Display for Matrix {\nfn fmt(&self,f:&mut fmt::Formatter)->fmt::Result {\nwrite!(f,\"({} {})\\n({} {})\",self.0[0][0],self.0[0][1],self.0[1][0],self.0[1][1])\n}\n}\n",
	"fn quicksort(arr:&mut [i32]) {\nif arr.len()<=1{return;}\nlet pivot=arr[arr.len()-1];\nlet(mut i,mut j)=(0,0);\nwhile j<arr.len()-1{\nif arr[j]<=pivot{arr.swap(i,j);i+=1;}\nj+=1;\n}\narr.swap(i,arr.len()-1);\nquicksort(&mut arr[..i]);\nquicksort(&mut arr[i+1..]);\n}\n",
	"#[derive(Clone)]\nstruct Stack<T>{items:Vec<T>}\nimpl<T:Clone> Stack<T>{\nfn new()->Self{Stack{items:vec![]}}\nfn push(&mut self,v:T){self.items.push(v)}\nfn pop(&mut self)->Option<T>{self.items.pop()}\nfn peek(&self)->Option<&T>{self.items.last()}\n}\n",
	"fn count_set_bits(mut n:u32)->u32{\nlet mut count=0;\nwhile n!=0{\nn&=n-1;\ncount+=1;\n}\ncount\n}\n",
	"fn rotate_left(v:&mut Vec<i32>,k:usize){\nlet n=v.len();\nif n==0{return;}\nlet k=k%n;\nv[..k].reverse();\nv[k..].reverse();\nv.reverse();\n}\n",
	"fn is_balanced(s:&str)->bool{\nlet mut depth=0i32;\nfor c in s.chars(){\nmatch c{\n'('|'['|'{'=> depth+=1,\n')'|']'|'}'=> {depth-=1;if depth<0{return false;}},\n_=>{}\n}\n}\ndepth==0\n}\n",
	"fn unique_sorted(v:Vec<i32>)->Vec<i32>{\nlet mut v=v;\nv.sort_unstable();\nv.dedup();\nv\n}\n",
	"fn transpose(m:Vec<Vec<i32>>)->Vec<Vec<i32>>{\nif m.is_empty(){return vec![];}\nlet rows=m.len();let cols=m[0].len();\n(0..cols).map(|j|(0..rows).map(|i|m[i][j]).collect()).collect()\n}\n",
	"fn moving_average(nums:&[f64],window:usize)->Vec<f64>{\nif window==0||nums.len()<window{return vec![];}\nlet mut sum:f64=nums[..window].iter().sum();\nlet mut out=vec![sum/window as f64];\nfor i in window..nums.len(){\nsum+=nums[i]-nums[i-window];\nout.push(sum/window as f64);\n}\nout\n}\n",
	"fn max_subarray(nums:&[i32])->i32{\nlet(mut best,mut cur)=(nums[0],nums[0]);\nfor &n in &nums[1..]{\ncur=n.max(cur+n);\nbest=best.max(cur);\n}\nbest\n}\n",
) {
	my $once = rs($snippet);
	is(rs($once), $once, 'Rust: snippet idempotent');
}

done_testing;
