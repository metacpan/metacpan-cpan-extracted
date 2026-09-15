# 📘 JQ::Lite — Function Reference

This document lists all jq-compatible and extended functions supported by **JQ::Lite**.
Functions are grouped by purpose for easier lookup.

---

## 🔍 Core Functions

| Function                | Description                                          |
| ----------------------- | ---------------------------------------------------- |
| `length`                | Number of elements / keys / characters               |
| `keys`, `keys_unsorted` | Object keys (sorted / unsorted)                      |
| `values`                | Object values                                        |
| `type()`                | Type string: `"string"`, `"number"`, `"array"`, etc. |
| `is_empty`              | True if array/object has no elements                 |
| `default(value)`        | Replace null/undef with fallback                     |
| `expr // fallback`      | Alternative operator (like jq)                       |
| `try expr [catch handler]` | Catch and recover from runtime errors              |

---

## 🧮 Math & Aggregation

| Function                                          | Description                      |
| ------------------------------------------------- | -------------------------------- |
| `add`, `sum`, `product`                           | Aggregation over arrays          |
| `sum_by(path)`, `avg_by(path)`, `median_by(path)` | Aggregate by field               |
| `avg`, `median`, `mode`, `percentile(p)`          | Statistical metrics              |
| `variance`, `stddev`                              | Statistical dispersion           |
| `abs`, `ceil`, `floor`, `round`                   | Rounding helpers                 |
| `clamp(min, max)`                                 | Restrict number to range         |
| `tonumber()`, `to_number()`                       | Strict / safe numeric conversion |

---

## 🧰 String Utilities

| Function                             | Description                          |
| ------------------------------------ | ------------------------------------ |
| `upper()`, `lower()`, `titlecase()`  | Case conversion                      |
| `ascii_upcase()`, `ascii_downcase()` | ASCII-only case conversion           |
| `trim()`, `ltrimstr()`, `rtrimstr()` | Trim whitespace or prefixes/suffixes |
| `startswith()`, `endswith()`         | Prefix/suffix test                   |
| `contains(value)`                    | Substring or array inclusion (legacy array semantics) |
| `contains_subset(value)`             | Recursive, order-insensitive multiset inclusion for arrays |
| `inside(container)`                  | Whether input is inside container    |
| `split(sep)`, `join(sep)`            | Split and join                       |
| `substr(start, len)`                 | Substring extraction                 |
| `replace(old, new)`                  | Replace substring (literal)          |
| `@json`, `@csv`, `@tsv`, `@base64`, `@base64d`, `@uri` | Format value as JSON, CSV/TSV row, Base64 string, decode Base64 text, or percent-encoded URI |
| `explode()`, `implode()`             | String ↔ Unicode code points         |
| `tostring`, `tojson`, `fromjson`     | Serialization utilities              |

**Array containment semantics**

- `contains(value)`: keeps the legacy behavior for arrays—it searches for an
  element equal to the provided value. Nested arrays must match exactly (order
  and length) to satisfy equality. Objects still use subset semantics and
  strings still use substring matching.
- `contains_subset(value)`: recursive subset matching for arrays. The
  right-hand array is satisfied when every element can be matched anywhere in
  the left-hand array (order-insensitive) with multiset counting. Nested arrays
  and objects are compared recursively using the same subset rules. This is not
  a drop-in replacement for jq's `contains`: duplicate needles require duplicate
  matching elements (`[1] | contains_subset([1,1])` is false), and scalar values
  are compared after string coercion (`["1"] | contains_subset([1])` is true).

---

## 📊 Array Operations

| Function                                         | Description              |
| ------------------------------------------------ | ------------------------ |
| `sort`, `sort_desc`, `sort_by(key)`              | Sort array               |
| `reverse`, `first`, `last`                       | Basic reordering         |
| `unique`, `unique_by(path)`                      | Deduplicate              |
| `limit(n)`, `drop(n)`, `rest`, `tail(n)`         | Array slicing            |
| `range(start; end[, step])`                      | Numeric sequence         |
| `chunks(n)`                                      | Split into subarrays     |
| `flatten()`, `flatten_all()`, `flatten_depth(n)` | Flatten nested arrays    |
| `enumerate()`                                    | Pair elements with index |
| `transpose()`                                    | Convert rows ↔ columns   |
| `nth(n)`                                         | Nth element              |
| `compact()`                                      | Remove null/undef        |
| `index(v)`, `rindex(v)`, `indices(v)`            | Locate positions         |

---

## 🧩 Object Operations

| Function                                | Description                                     |
| --------------------------------------- | ----------------------------------------------- |
| `has(key)`                              | Key existence                                   |
| `pick(keys...)`                         | Keep specified keys                             |
| `pluck(key)`                            | Extract values from objects                     |
| `merge_objects()`                       | Merge array of objects                          |
| `del(key)`, `delpaths(paths)`           | Remove keys                                     |
| `to_entries()`, `from_entries()`        | Convert between object ↔ array of `{key,value}` |
| `with_entries(filter)`                  | Transform entries                               |
| `group_by(key)`, `group_count(key)`     | Group and count                                 |
| `paths()`, `leaf_paths()`               | Enumerate all or leaf paths                     |
| `getpath(path)`, `setpath(path; value)` | Read/write by path                              |

---

## 🔄 Functional / Recursive

| Function                                        | Description                |
| ----------------------------------------------- | -------------------------- |
| `map(expr)`, `map_values(expr)`                 | Map/filter array or object |
| `walk(filter)`                                  | Recursive apply            |
| `recurse([filter])`                             | Depth-first traversal      |
| `reduce expr as $x (init; update)`              | Fold accumulator           |
| `foreach expr as $x (init; update [; extract])` | Streaming reduce           |
| `any([filter])`, `all([filter])`                | Boolean aggregation        |
| `not`                                           | Logical negation           |

---

## 🧱 Type Filters

| Function  | Description                                 |
| --------- | ------------------------------------------- |
| `arrays`  | Pass only arrays                            |
| `objects` | Pass only objects                           |
| `scalars` | Pass only scalars (string/number/bool/null) |

---

## ⚙️ Utility Helpers

| Function                    | Description            |
| --------------------------- | ---------------------- |
| `empty()`                   | Discard results        |
| `count`                     | Count elements         |
| `path()`                    | Return keys or indices |
| `range(start; end[, step])` | Numeric range          |
| `expr // value`             | Default operator       |

---

### 🔄 Interactive Mode

If you omit the query, `jq-lite` enters **interactive mode**, allowing you to type queries line-by-line against a fixed JSON input.

```bash
jq-lite users.json
```

---

## 🧾 Notes

* jq-style **pipe syntax** and **expressions** are fully supported:
  `.[] | select(.age > 20) | .name`
* Mathematical expressions follow normal precedence and parentheses.
* Errors are descriptive (e.g. divide-by-zero).

---

📚 For usage examples and environment compatibility, see [README.md](README.md).
👉 Also available on [MetaCPAN — JQ::Lite](https://metacpan.org/pod/JQ::Lite)
