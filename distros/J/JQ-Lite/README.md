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
- ✅ Built-in functions: `length`, `keys`, `values`, `first`, `last`, `reverse`, `sort`, `sort_by`, `unique`, `has`, `map`, `group_by`, `count`, `join`, `empty()` 
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
| `length`       | Get number of elements in an array or keys in a hash |
| `keys`         | Extract sorted keys from a hash                      |
| `values`       | Extract values from a hash (v0.34)                   |
| `sort`         | Sort array items                                     |
| `sort_by(key)` | Sort array of objects by field (v0.32)               |
| `unique`       | Remove duplicate values                              |
| `first`        | Get the first element of an array                    |
| `last`         | Get the last element of an array                     |
| `reverse`      | Reverse an array                                     |
| `limit(n)`     | Limit array to first `n` elements                    |
| `map(expr)`    | Map/filter values using a subquery                   |
| `add`, `min`, `max`, `avg` | Numeric aggregation functions            |
| `group_by(key)`| Group array items by field                           |
| `count`        | Count total number of matching items                 |
| `join(sep)`    | Join array elements with custom separator (v0.31+)   |
| `empty()`      | Discard all results (compatible with jq) (v0.33+)    |
| `flatten()`    | Flatten array one level deep (like `.[]`) (v0.35)    |
| `type()`       | Return the type of the value ("string", "number", "boolean", "array", "object", "null") (v0.36) |
| `nth(n)`       | Get the nth element of an array (v0.37)              |
| `del(key)`     | Delete a specified key from a hash object (v0.38)    |
| `compact()`    | Remove undef/null values from arrays (v0.39)         |

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

