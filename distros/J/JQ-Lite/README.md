![JQ::Lite](./images/JQ_Lite_logo_small.png)

# JQ::Lite

[![MetaCPAN](https://img.shields.io/cpan/v/JQ::Lite?color=blue)](https://metacpan.org/pod/JQ::Lite)
[![GitHub](https://img.shields.io/github/stars/kawamurashingo/JQ-Lite?style=social)](https://github.com/kawamurashingo/JQ-Lite)

**JQ::Lite** is a lightweight, pure-Perl JSON query engine inspired by the [`jq`](https://stedolan.github.io/jq/) command-line tool.  
It allows you to extract, traverse, and filter JSON data using a simplified jq-like syntax — entirely within Perl.

---

## 🔧 Features

- ✅ **Pure Perl** (no XS, no external binaries)
- ✅ Dot notation (`.users[].name`)
- ✅ Optional key access (`.nickname?`)
- ✅ Array indexing and expansion (`.users[0]`, `.users[]`)
- ✅ `select(...)` filters with `==`, `!=`, `<`, `>`, `and`, `or`
- ✅ Built-in functions: `length`, `keys`, `values`, `first`, `last`, `reverse`, `sort`, `sort_desc`, `sort_by`, `min_by()`, `max_by()`, `unique`, `unique_by()`, `has`, `contains()`, `test()`, `any()`, `all()`, `not`, `map`, `map_values()`, `walk()`, `recurse()`, `group_by`, `group_count`, `sum_by()`, `avg_by()`, `median_by()`, `count`, `join`, `split()`, `explode()`, `implode()`, `substr()`, `slice()`, `replace()`, `empty()`, `median`, `mode`, `percentile()`, `variance`, `stddev`, `add`, `sum`, `product`, `upper()`, `lower()`, `titlecase()`, `abs()`, `ceil()`, `floor()`, `round()`, `trim()`, `ltrimstr()`, `rtrimstr()`, `startswith()`, `endswith()`, `chunks()`, `enumerate()`, `transpose()`, `flatten_all()`, `flatten_depth()`, `range()`, `index()`, `rindex()`, `indices()`, `clamp()`, `tostring()`, `tojson()`, `fromjson()`, `to_number()`, `pick()`, `merge_objects()`, `to_entries()`, `from_entries()`, `with_entries()`, `paths()`, `leaf_paths()`, `getpath()`, `setpath()`, `delpaths()`, `arrays`, `objects`, `scalars`
- ✅ `reduce expr as $var (init; update)` for jq-style accumulation with lexical variable bindings
- ✅ `foreach expr as $var (init; update [; extract])` for jq-compatible streaming accumulation with optional emitters
- ✅ jq-style alternative operator (`lhs // rhs`) for concise default values
- ✅ Conditional branching with jq-style `if ... then ... elif ... else ... end`
  ```jq
  if .score >= 90 then "A" elif .score >= 80 then "B" else "C" end
  ```
- ✅ Pipe-style queries with `.[]` (e.g. `.[] | select(...) | .name`)
- ✅ Command-line interface: `jq-lite`
- ✅ jq-compatible `--null-input` (`-n`) flag to start from `null` without providing JSON input
- ✅ jq-compatible `--slurp` (`-s`) flag to collect every JSON document from the input stream into a single array
- ✅ jq-compatible `--from-file` (`-f`) option to load filters from reusable script files
- ✅ Reads from STDIN or file
- ✅ **Interactive mode** for exploring JSON line-by-line
- ✅ `--use` option to select decoder (JSON::PP, JSON::XS, etc.)
- ✅ `--debug` option to show active JSON module
- ✅ `--help-functions` to list all built-in functions

---

## 🤔 Why JQ::Lite (vs `jq` or `JSON::PP`)?

| Use Case              | Tool            |
|-----------------------|-----------------|
| Simple JSON decode    | ✅ `JSON::PP`    |
| Shell processing      | ✅ `jq`          |
| jq-style queries in Perl | ✅ **JQ::Lite** |
| Lightweight & portable | ✅ **JQ::Lite** |

---

## 📆 Supported Functions

| Function       | Description                                           |
|----------------|-------------------------------------------------------|
| `length`       | Get number of elements in an array, keys in a hash, or characters in scalars |
| `keys`         | Extract sorted keys from a hash                      |
| `keys_unsorted` | Extract object keys without sorting (jq-compatible) |
| `values`       | Extract values from a hash (v0.34)                   |
| `sort`         | Sort array items                                     |
| `sort_desc`    | Sort array items in descending order (v0.61)         |
| `sort_by(key)` | Sort array of objects by field (v0.32)               |
| `min_by(path)` | Return the element with the smallest projected value (v0.75) |
| `max_by(path)` | Return the element with the largest projected value (v0.75) |
| `unique`       | Remove duplicate values                              |
| `unique_by(path)` | Remove duplicates by projecting each entry to a key path (v0.60) |
| `first`        | Get the first element of an array                    |
| `last`         | Get the last element of an array                     |
| `reverse`      | Reverse an array                                     |
| `limit(n)`     | Limit array to first `n` elements                    |
| `drop(n)`      | Skip the first `n` elements in an array              |
| `tail(n)`      | Return the final `n` elements in an array (v0.79)    |
| `chunks(n)`    | Split an array into subarrays with `n` items each (v0.64) |
| `range(start; end[, step])` | Emit a numeric sequence from `start` (default `0`) up to but excluding `end`, advancing by `step` (default `1`) (v0.86) |
| `enumerate()`  | Pair each array element with its zero-based index (v0.81) |
| `transpose()`  | Convert arrays-of-arrays from rows into columns, truncating to the shortest length (v0.82) |
| `map(expr)`    | Map/filter values using a subquery                   |
| `map_values(filter)` | Apply a filter to every value in an object, dropping keys when the filter yields no result (v0.92) |
| `walk(filter)` | Recursively apply a filter to every value within arrays and objects (v0.95) |
| `recurse([filter])` | Depth-first traversal of nested structures using an optional child filter (v0.103) |
| `pluck(key)`   | Extract values from an array of objects (v0.43)      |
| `pick(keys...)` | Build objects containing only the specified keys (v0.74) |
| `merge_objects()` | Shallow-merge arrays of objects into a single hash with last-write-wins semantics (v0.80) |
| `to_entries()` | Convert objects/arrays into an array of `{key, value}` pairs (v0.84) |
| `from_entries()` | Convert entry arrays back into an object (v0.84) |
| `with_entries(filter)` | Apply a filter to each entry before rebuilding the object (v0.84) |
| `add`, `sum`, `sum_by(path)`, `avg_by(path)`, `median_by(path)`, `min`, `max`, `avg`, `median`, `mode`, `percentile(p)`, `variance`, `stddev`, `product` | Numeric and statistical aggregation functions |
| `abs`         | Convert numeric values to their absolute value (v0.49) |
| `ceil`        | Round numbers up to the nearest integer (v0.53)        |
| `floor`       | Round numbers down to the nearest integer (v0.53)      |
| `round`       | Round numbers to the nearest integer (v0.54)           |
| `clamp(min, max)` | Clamp numbers within an inclusive range (v0.73)        |
| `tostring`    | Convert values to their JSON string representation (v0.85) |
| `tojson`      | Encode any value as JSON text (unreleased)                |
| `fromjson`    | Decode JSON text into native values (arrays handled element-wise) (unreleased) |
| `to_number`   | Convert numeric-looking strings/booleans to numbers (v0.72) |
| `trim`        | Remove leading/trailing whitespace from strings (v0.50) |
| `ltrimstr(prefix)` | Remove `prefix` from the start of strings when present (v0.87) |
| `rtrimstr(suffix)` | Remove `suffix` from the end of strings when present (v0.87) |
| `startswith(prefix)` | Check if a string (or array of strings) begins with `prefix` (v0.51) |
| `endswith(suffix)` | Check if a string (or array of strings) ends with `suffix` (v0.51) |
| `split(separator)` | Split a string (or array of strings) using a literal separator (v0.52) |
| `explode()` | Convert strings into arrays of Unicode code points (v0.88) |
| `implode()` | Turn arrays of code points back into strings (v0.88) |
| `replace(old, new)` | Replace all occurrences of a literal substring with another value (arrays processed element-wise) (unreleased) |
| `substr(start, length)` | Extract a substring using zero-based indexing (arrays are processed element-wise) (v0.57) |
| `slice(start, length)` | Return a subarray using zero-based indexing with optional length (negative starts count from the end) (v0.66) |
| `has(key)` | Check if objects contain a key or arrays have an index (v0.71) |
| `contains(value)` | Check whether strings include the value or arrays contain an element (v0.56) |
| `test(pattern[, flags])` | Match strings against Perl-compatible regular expressions with optional `imxs` flags (unreleased) |
| `all([filter])` | Return true when every input (optionally filtered) is truthy (v0.94) |
| `any([filter])` | Return true when any input (optionally filtered) is truthy (v0.90) |
| `not` | Logical negation following jq truthiness semantics (v0.102) |
| `group_by(key)`| Group array items by field                           |
| `group_count(key)` | Count how many items fall under each key (v0.46)   |
| `sum_by(path)` | Sum numeric values projected from each array item (v0.68) |
| `avg_by(path)` | Average numeric values projected from each array item (v0.78) |
| `count`        | Count total number of matching items                 |
| `join(sep)`    | Join array elements with custom separator (v0.31+)   |
| `empty()`      | Discard all results (compatible with jq) (v0.33+)    |
| `flatten()`    | Flatten array one level deep (like `.[]`) (v0.35)    |
| `flatten_all()`| Recursively flatten nested arrays into a single array (v0.67) |
| `flatten_depth(n)` | Flatten nested arrays up to `n` levels deep (v0.70) |
| `arrays`       | Emit input values only when they are arrays (v0.99) |
| `objects`      | Emit input values only when they are objects (v0.100) |
| `scalars`      | Emit input values only when they are scalars (strings, numbers, booleans, null) (unreleased) |
| `type()`       | Return the type of the value ("string", "number", "boolean", "array", "object", "null") (v0.36) |
| `nth(n)`       | Get the nth element of an array (v0.37)              |
| `index(value)` | Return the zero-based index of the first match in arrays or strings (v0.65) |
| `rindex(value)` | Return the zero-based index of the last match in arrays or strings (v0.98) |
| `indices(value)` | Return every index where the value appears in arrays or strings (v0.91) |
| `del(key)`     | Delete a specified key from a hash object (v0.38)    |
| `delpaths(paths)` | Remove multiple keys or indices using path arrays (v0.93) |
| `compact()`    | Remove undef/null values from arrays (v0.39)         |
| `upper()`      | Convert scalars (and array elements) to uppercase (v0.47) |
| `lower()`      | Convert scalars (and array elements) to lowercase (v0.47) |
| `titlecase()`  | Convert scalars (and array elements) to title case (v0.69) |
| `path()`       | Return keys (for objects) or indices (for arrays) (v0.40) |
| `paths()`      | Emit every path to nested values as arrays of keys/indices (v0.89) |
| `leaf_paths()` | Emit only the paths that terminate in non-container values (v0.96) |
| `getpath(path)` | Retrieve the value(s) at the supplied path array or expression (unreleased) |
| `setpath(path; value)` | Set or create a value at the specified path using literal or filter input (unreleased) |
| `is_empty`     | True when the value is an empty array or object (v0.41)   |
| `expr // fallback` | Use jq's alternative operator to supply defaults when the left side is null or missing (v1.02) |
| `default(value)` | Substitute a fallback value when the result is undef/null (v0.42) |

---

## 📦 Installation

### 🛠️ From Source (Manual Build)

```sh
perl Makefile.PL
make
make test
make install
```

### 🍺 Using Homebrew (macOS)

```sh
brew tap kawamurashingo/jq-lite
brew install --HEAD jq-lite
```

> ℹ️ Requires Xcode Command Line Tools.  
> If installation fails due to outdated tools, run:
>
> ```sh
> sudo rm -rf /Library/Developer/CommandLineTools
> sudo xcode-select --install
> ```

### 🐙 Portable Install Script (Linux/macOS)

```sh
curl -fsSL https://raw.githubusercontent.com/kawamurashingo/JQ-Lite/main/install.sh | bash
```

> Installs to `$HOME/.local/bin` by default.  
> Add the following to your shell config if not already in PATH:
>
> ```sh
> export PATH="$HOME/.local/bin:$PATH"
> ```

---

## 🌍 Environment Compatibility

`JQ::Lite` (Perl-based jq alternative) runs in almost **any Linux environment** where Perl is available — even when installing `jq` itself is difficult or impossible.

### 🧱 1. Legacy Distributions (CentOS 6 / RHEL 6 / Ubuntu 12.04, etc.)

| Distribution | jq-lite Support | Notes |
|---------------|----------------|-------|
| **CentOS 6 / RHEL 6** | ⚠️ Requires upgrade | Default Perl 5.10.1 is too old; upgrade Perl to ≥ 5.14 (e.g. via perlbrew) before installing. |
| **Ubuntu 12.04 / 14.04** | ✅ Works | Perl 5.14–5.18; installable via `cpan install JQ::Lite`. |
| **Debian 7 (Wheezy)** | ✅ Works | Perl 5.14.2 standard; `apt-get install cpanminus` → `cpanm JQ::Lite` runs cleanly. |
| **SLES 11 and earlier** | ❌ Not supported | System Perl 5.10–5.12 is below the minimum requirement; upgrade Perl to ≥ 5.14 to use JQ::Lite. |

✅ **Conclusion:**  
Even on legacy environments without jq, `JQ::Lite` runs as long as Perl ≥ 5.14 is available.

---

### 🐧 2. Minimalist Distributions (Alpine / BusyBox / TinyCore)

| Distribution | jq-lite Support | Notes |
|---------------|----------------|-------|
| **Alpine Linux (3.x+)** | ✅ Works | Install with `apk add perl perl-utils build-base`. Excellent compatibility. |
| **BusyBox-based (Buildroot, OpenWRT)** | ⚠️ Difficult | Usually no Perl or CPAN; requires prebuilt Perl or cross-compilation. |
| **TinyCore Linux** | ⚠️ Conditional | Install `tce-load -wi perl5.tcz` first. Limited storage may be a constraint. |

✅ **Conclusion:**  
Except BusyBox-only systems, lightweight distros like Alpine can run `jq-lite` smoothly.

---

### ☁️ 3. Restricted / Enterprise Networks

| Environment | jq-lite Support | Notes |
|--------------|----------------|-------|
| **No internet (CPAN disabled)** | ✅ Works (offline) | Copy tarball (`cpanm --look JQ::Lite`) and install manually via `perl Makefile.PL && make install`. |
| **Proxy environment** | ✅ Supported | Example: `cpanm -v --proxy http://sysworks101z.prod.jp.local:3128 JQ::Lite`. |
| **No root privilege** | ✅ Supported | Use `cpanm --local-lib ~/perl5 JQ::Lite` for user-space installation. |

✅ **Conclusion:**  
`jq-lite` can be installed and used in **closed, proxy, and non-root environments** where jq cannot.

---

### 🔧 Summary

| Environment Type     | jq | jq-lite |
|----------------------|----|---------|
| Legacy CentOS / RHEL | ❌  | ✅       |
| Older Ubuntu / Debian| ⚠️  | ✅       |
| Alpine Linux         | ⚠️  | ✅       |
| BusyBox / OpenWRT    | ❌  | ⚠️ (Perl required) |
| Air-gapped Servers   | ❌  | ✅       |
| No Root Privilege    | ⚠️  | ✅       |

---

### ✅ Overall Conclusion

> **`jq-lite` works in almost every Linux environment** — including legacy, lightweight, or isolated systems where installing jq is impractical.

---

## 🚀 Usage

### As a Perl module

```perl
use JQ::Lite;

my $json = '{"users":[{"name":"Alice"},{"name":"Bob"}]}';
my $jq = JQ::Lite->new;
my @names = $jq->run_query($json, '.users[].name');

print join("\n", @names), "\n";
```

### As a command-line tool

```bash
cat users.json | jq-lite '.users[].name'
jq-lite '.users[] | select(.age > 25)' users.json
jq-lite -r '.users[].name' users.json
jq-lite -c '.users[0]' users.json
```

For Windows:

```powershell
type user.json | jq-lite ".users[].name"
jq-lite -r ".users[].name" users.json
```

> ⚠️ `jq-lite` is named to avoid conflict with the original `jq`.

Use `-c` / `--compact-output` when you need jq-style single-line JSON that is
easier to pipe into other tools or compare in scripts.

---

### 🔄 Interactive Mode

If you omit the query, `jq-lite` enters **interactive mode**, allowing you to type queries line-by-line against a fixed JSON input.

```bash
jq-lite users.json
```
![JQ::Lite demo](images/jq_lite.gif)

```
jq-lite interactive mode. Enter query (empty line to quit):
> .users[0].name
"Alice"
> .users[] | select(.age > 25)
{
  "name" : "Alice",
  "age" : 30,
  ...
}
```

- Results will be **re-rendered each time**, clearing the previous output (like a terminal UI).
- Works with `--raw-output` (`-r`) as well.

---

### 🔍 Decoder selection and debug output

If installed, the following JSON modules are checked and used in order of priority: `JSON::MaybeXS`, `Cpanel::JSON::XS`, `JSON::XS`, and `JSON::PP`. You can see which module is being used with the `--debug` option.

```bash
$ jq-lite --debug .users[0].age users.json
[DEBUG] Using Cpanel::JSON::XS
30

$ jq-lite --use JSON::PP .users[0].age users.json
30

$ jq-lite --use JSON::PP --debug .users[0].age users.json
[DEBUG] Using JSON::PP
30
```

---

### 📘 Example Input

```json
{
  "users": [
    {
      "name": "Alice",
      "age": 30,
      "profile": {
        "active": true,
        "country": "US"
      }
    },
    {
      "name": "Bob",
      "age": 25,
      "profile": {
        "active": false,
        "country": "JP"
      }
    },
    {
      "name": "Carol",
      "age": 35
    }
  ]
}
```

### Example Queries

```bash
jq-lite '.users[].name' users.json
jq-lite '.users | length' users.json
jq-lite '.users[0] | keys' users.json
jq-lite '.users[].nickname?' users.json
jq-lite '.users[] | select(.age > 25)' users.json
jq-lite '.users[] | select(.profile.active == true) | .name' users.json
jq-lite '.users | sort_by(.age)' users.json
jq-lite '.users | map(.name) | join(", ")' users.json
jq-lite '.users[] | (.nickname // .name)' users.json
jq-lite '.users | drop(1)' users.json
jq-lite '.users[] | select(.age > 25) | empty' users.json
jq-lite '.users[0] | values' users.json
jq-lite '.users[0].name | type' users.json
```

---

## 🤮 Testing

```bash
prove -l t/
```

---

## 📦 CPAN

👉 [JQ::Lite on MetaCPAN](https://metacpan.org/pod/JQ::Lite)

---

## 📝 License

This module is released under the same terms as Perl itself.

---

## 👤 Author

**Kawamura Shingo**  
📧 pannakoota1@gmail.com  
🔗 [GitHub @kawamurashingo](https://github.com/kawamurashingo/JQ-Lite)


