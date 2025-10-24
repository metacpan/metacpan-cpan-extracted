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
| `trim()`, `ltrimstr()`, `rtrimstr()` | Trim whitespace or prefixes/suffixes |
| `startswith()`, `endswith()`         | Prefix/suffix test                   |
| `contains(value)`                    | Substring or array inclusion         |
| `split(sep)`, `join(sep)`            | Split and join                       |
| `substr(start, len)`                 | Substring extraction                 |
| `replace(old, new)`                  | Replace substring (literal)          |
| `explode()`, `implode()`             | String ↔ Unicode code points         |
| `tostring`, `tojson`, `fromjson`     | Serialization utilities              |

---

## 📊 Array Operations

| Function                                         | Description              |
| ------------------------------------------------ | ------------------------ |
| `sort`, `sort_desc`, `sort_by(key)`              | Sort array               |
| `reverse`, `first`, `last`                       | Basic reordering         |
| `unique`, `unique_by(path)`                      | Deduplicate              |
| `limit(n)`, `drop(n)`, `tail(n)`                 | Array slicing            |
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

## 🧾 Notes

* jq-style **pipe syntax** and **expressions** are fully supported:
  `.[] | select(.age > 20) | .name`
* Mathematical expressions follow normal precedence and parentheses.
* Errors are descriptive (e.g. divide-by-zero).

---

📚 For usage examples and environment compatibility, see [README.md](README.md).
👉 Also available on [MetaCPAN — JQ::Lite](https://metacpan.org/pod/JQ::Lite)

