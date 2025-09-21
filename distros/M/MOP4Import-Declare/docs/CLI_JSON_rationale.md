# Rationale for MOP4Import::Base::CLI_JSON

## Overview

MOP4Import::Base::CLI_JSON (CLI_JSON for short) is a base class designed to accelerate Perl module development. Its primary value lies in **making any method of a module under development immediately testable from the command line**.

## Problems It Solves

### Traditional Module Development Challenges

When developing Perl modules, the typical workflow involves:

1. Write module code
2. Write test scripts
3. Run tests to verify behavior
4. Fix issues and re-test

In this development cycle, you can't verify method behavior without writing test scripts first. This overhead significantly slows down development, especially during the exploratory phase.

### The CLI_JSON Solution

Modules inheriting from CLI_JSON enable the following development flow:

```perl
#!/usr/bin/env perl
package MyScript;
use MOP4Import::Base::CLI_JSON -as_base;
MY->cli_run(\@ARGV) unless caller;

sub query {
  my ($self, $sql) = @_;
  # SQL query implementation
}
1;
```

This module can be executed immediately from the command line:

```bash
# Syntax check
$ perl -wc MyScript.pm

# Run immediately
$ ./MyScript.pm query "SELECT * FROM users"

# Run with debugger
$ perl -d ./MyScript.pm query "SELECT * FROM users"

# Run with profiler
$ perl -d:NYTProf ./MyScript.pm query "SELECT * FROM users"
```

## Core Design Principles

### 1. Unified Data Exchange via JSON

By restricting arguments and return values to JSON-serializable data, we achieve:

- **Complex data structure handling**: Arrays and hashes work naturally
- **Language-neutral interface**: Easy integration with other languages and tools
- **Debugging ease**: Human-readable input/output format

### 2. Flexible Output Formats

Multiple output formats including the default NDJSON (Newline Delimited JSON):

- **ndjson**: Readable for large arrays, works well with line-oriented tools like grep
- **json**: Standard JSON format
- **yaml**: More human-readable format
- **tsv**: Convenient for spreadsheet processing
- **dump**: Perl's Data::Dumper for debugging

### 3. OO Modulino Pattern Implementation

The same file serves three roles:

1. **Regular Perl module**: Used via `use MyScript;`
2. **CLI tool**: Executed as `./MyScript.pm`
3. **Test target**: Individual methods can be tested independently

## Development Efficiency Improvements

### Support for Exploratory Development

Since methods can be tested immediately after writing:

- Verify behavior before writing test scripts
- Rapid iteration and experimentation
- Refine interface design through actual use

### Enhanced Testability

Naturally encourages breaking methods into CLI-callable units, resulting in:

- Easier unit test writing
- Clear separation of responsibilities
- More reusable code

### Easy Debugging and Profiling

Standard Perl tools work seamlessly:

- `perl -d` for debugger
- `perl -d:NYTProf` for profiling
- `perl -MDevel::Trace` for tracing

## Summary

The rationale for CLI_JSON is to **dramatically shorten the feedback loop in module development**. It's not just a CLI tool creation framework, but a development productivity tool for Perl module authors.

## Related Documentation

- [About OO Modulino Pattern](./OO_Modulino.md)
- [CLI_JSON Reference Manual](../Base/CLI_JSON.pod)