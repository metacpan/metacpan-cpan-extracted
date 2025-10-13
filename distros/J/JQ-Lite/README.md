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
- ✅ Built-in functions: `length`, `keys`, `values`, `first`, `last`, `reverse`, `sort`, `sort_desc`, `sort_by`, `min_by()`, `max_by()`, `unique`, `unique_by()`, `has`, `contains()`, `map`, `group_by`, `group_count`, `sum_by()`, `avg_by()`, `count`, `join`, `split()`, `substr()`, `slice()`, `replace()`, `empty()`, `median`, `mode`, `variance`, `stddev`, `add`, `sum`, `product`, `upper()`, `lower()`, `titlecase()`, `abs()`, `ceil()`, `floor()`, `round()`, `trim()`, `startswith()`, `endswith()`, `chunks()`, `enumerate()`, `flatten_all()`, `flatten_depth()`, `index()`, `clamp()`, `to_number()`, `pick()`, `merge_objects()`
- ✅ Pipe-style queries with `.[]` (e.g. `.[] | select(...) | .name`) 
- ✅ Command-line interface: `jq-lite`
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
| `enumerate()`  | Pair each array element with its zero-based index (v0.81) |
| `map(expr)`    | Map/filter values using a subquery                   |
| `pluck(key)`   | Extract values from an array of objects (v0.43)      |
| `pick(keys...)` | Build objects containing only the specified keys (v0.74) |
| `merge_objects()` | Shallow-merge arrays of objects into a single hash with last-write-wins semantics (v0.80) |
| `add`, `sum`, `sum_by(path)`, `avg_by(path)`, `min`, `max`, `avg`, `median`, `mode`, `variance`, `stddev`, `product` | Numeric and statistical aggregation functions |
| `abs`         | Convert numeric values to their absolute value (v0.49) |
| `ceil`        | Round numbers up to the nearest integer (v0.53)        |
| `floor`       | Round numbers down to the nearest integer (v0.53)      |
| `round`       | Round numbers to the nearest integer (v0.54)           |
| `clamp(min, max)` | Clamp numbers within an inclusive range (v0.73)        |
| `to_number`   | Convert numeric-looking strings/booleans to numbers (v0.72) |
| `trim`        | Remove leading/trailing whitespace from strings (v0.50) |
| `startswith(prefix)` | Check if a string (or array of strings) begins with `prefix` (v0.51) |
| `endswith(suffix)` | Check if a string (or array of strings) ends with `suffix` (v0.51) |
| `split(separator)` | Split a string (or array of strings) using a literal separator (v0.52) |
| `replace(old, new)` | Replace all occurrences of a literal substring with another value (arrays processed element-wise) (unreleased) |
| `substr(start, length)` | Extract a substring using zero-based indexing (arrays are processed element-wise) (v0.57) |
| `slice(start, length)` | Return a subarray using zero-based indexing with optional length (negative starts count from the end) (v0.66) |
| `has(key)` | Check if objects contain a key or arrays have an index (v0.71) |
| `contains(value)` | Check whether strings include the value or arrays contain an element (v0.56) |
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
| `type()`       | Return the type of the value ("string", "number", "boolean", "array", "object", "null") (v0.36) |
| `nth(n)`       | Get the nth element of an array (v0.37)              |
| `index(value)` | Return the zero-based index of the first match in arrays or strings (v0.65) |
| `del(key)`     | Delete a specified key from a hash object (v0.38)    |
| `compact()`    | Remove undef/null values from arrays (v0.39)         |
| `upper()`      | Convert scalars (and array elements) to uppercase (v0.47) |
| `lower()`      | Convert scalars (and array elements) to lowercase (v0.47) |
| `titlecase()`  | Convert scalars (and array elements) to title case (v0.69) |
| `path()`       | Return keys (for objects) or indices (for arrays) (v0.40) |
| `is_empty`     | True when the value is an empty array or object (v0.41)   |
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
```

For Windows:

```powershell
type user.json | jq-lite ".users[].name"
jq-lite -r ".users[].name" users.json
```

> ⚠️ `jq-lite` is named to avoid conflict with the original `jq`.

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

