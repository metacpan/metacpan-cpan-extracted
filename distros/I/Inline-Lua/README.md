# Inline::Lua - A Modern Bridge Between Perl and Lua/Fennel

A modern, safe, and fast way to embed Lua and Fennel code directly inside your Perl scripts, powered by a Rust backend.

## Table of Contents

- [Why Use Inline::Lua?](https://www.google.com/search?q=%23why-use-inlinelua "null")
  
- [Installation](https://www.google.com/search?q=%23installation "null")
  
- [Quick Start](https://www.google.com/search?q=%23quick-start "null")
  
- [Advanced Example](https://www.google.com/search?q=%23advanced-example-processing-perl-data-in-lua "null")
  
- [Error Handling](https://www.google.com/search?q=%23error-handling "null")
  
- [API Reference](https://www.google.com/search?q=%23api-reference "null")
  
- [Limitations & Caveats](https://www.google.com/search?q=%23limitations--caveats "null")
  
- [Performance](https://www.google.com/search?q=%23performance "null")
  
- [Contributing](https://www.google.com/search?q=%23contributing "null")
  
- [Author](https://www.google.com/search?q=%23author "null")
  
- [License](https://www.google.com/search?q=%23license "null")
  

## Why Use Inline::Lua?

This module is for Perl developers who want to leverage the Lua ecosystem for tasks like configuration, scripting, or as a safe, embedded logic engine.

- **Performance:** By compiling the entire Lua runtime into a native Rust library, this module offers a significant performance advantage over pure-Perl interpreters. Logic executed in Lua runs at near-native speed.
  
- **Safety:** The default sandboxed environment prevents Lua scripts from accessing the filesystem, network, or other system resources. Rust's memory safety guarantees eliminate an entire class of bugs and vulnerabilities at the FFI boundary.
  
- **Modern Features:** Get out-of-the-box support for [Fennel](https://fennel-lang.org/ "null"), a Lisp that compiles to Lua, without any extra configuration.
  
- **Ease of Use:** A simple, clean API for evaluating code and automatically marshalling complex data structures (hashes and arrays) between Perl and Lua via JSON.
  

## Installation

### Requirements

- **Perl:** v5.16 or newer.
  
- **Rust Toolchain:** v1.65 or newer. You can install it easily via [rustup](https://rustup.rs/ "null").
  
- **Platform:** Tested on Linux. Should be compatible with macOS and Windows (x86_64), but these are not yet officially tested.
  
- **Perl Dependencies:**
  
  - `FFI::Platypus`
    
  - `JSON::MaybeXS`
    
  - `Cpanel::JSON::XS`
    

### From CPAN

Once the module is on CPAN, you can install it with:

```shell
cpanm Inline::Lua
```
or
```shell
cpan Inline:Lua
```
### From Source

To install from source:

```shell
# Clone the repository
git clone https://github.com/ItsMeForLua/Inline-Lua.git
cd Inline-Lua

# Build and install
perl Makefile.PL
make
make test
make install
```

The `Makefile.PL` script will automatically invoke `cargo` to build the Rust backend and package it with the Perl module.

## Quick Start

Here is the absolute minimum to get started:

```perl
use Inline::Lua;

# 1. Create a new Lua runtime
my $lua = Inline::Lua->new;

# 2. Evaluate a string of Lua code
my $result = $lua->eval('return 2 + 2');

# 3. Get the result back in Perl
print $result; # Output: 4
```

## Advanced Example: Processing Perl Data in Lua

The recommended way to pass complex data *into* the Lua environment is to serialize it as JSON in Perl and decode it within the Lua script. This pattern is simple, robust, and avoids complex FFI data marshalling.

```perl
use Inline::Lua;
use JSON::MaybeXS; # To encode the Perl data into the script
use Data::Dumper;

my $users = [
    { id => 1, name => 'alice', role => 'admin' },
    { id => 2, name => 'bob',   role => 'user'  },
];

# Create a non-sandboxed instance to get detailed error tracebacks
my $lua = Inline::Lua->new(sandboxed => 0);

# Inject the Perl data structure into the Lua script as a JSON string
my $json_users = JSON::MaybeXS->new->encode($users);

my $report = $lua->eval(qq{
    -- This script assumes a JSON library is available in the Lua environment.
    -- We are using the 'dkjson' library in this example.
    local json = require("json")
    local users = json.decode($json_users)

    function process_users(user_list)
        local report = {}
        for _, user in ipairs(user_list) do
            report[user.name] = string.upper(user.role)
        end
        return report
    end

    return process_users(users)
});

# $report is now a Perl hash: { alice => "ADMIN", bob => "USER" }
print Dumper($report);
```

***Note on Lua Dependencies:*** *The* example above requires a Lua JSON *library. A popular choice is `dkjson.lua`. You would need to ensure this file is available in Lua's `package.path` for the `require("json")` call to succeed.*

## Error Handling

The `eval` and `eval_fennel` methods will `die` on an error. You should wrap them in an `eval` block or use a module like `Try::Tiny` to catch potential errors gracefully.

```perl
use Try::Tiny;

my $lua = Inline::Lua->new(sandboxed => 0);

# --- Example 1: Lua Runtime Error ---
try {
    # This code will fail because 'x' is nil
    $lua->eval('local x = nil; x()');
}
catch {
    # The error in $_ will contain a full stack traceback
    warn "Caught a Lua error: $_";
};

# --- Example 2: Fennel Compile-Time Error ---
try {
    # This Fennel code is invalid
    $lua->eval_fennel('(let [x 1] (y))');
}
catch {
    warn "Caught a Fennel error: $_";
};
```

## API Reference

### `new(%options)`

Creates and returns a new `Inline::Lua` object, which represents an isolated Lua runtime environment.

It accepts the following options:

- sandboxed (default: 1)
  
  If true, the Lua environment will be sandboxed by loading only safe libraries. In this mode, Fennel is disabled as it requires the unsafe debug library. If false, all standard Lua libraries (including io, os, and debug) will be loaded. This is required to use eval_fennel.
  
- enable_fennel (default: 1)
  
  This option is respected only when sandboxed is false. If true, the Fennel compiler will be loaded into the Lua environment.
  
- cache_fennel (default: 1)
  
  If true, the results of Fennel compilation will be cached. This can provide a significant speedup if you are evaluating the same Fennel code strings multiple times.
  

### `eval($lua_code)`

Evaluates a string of Lua code. The value of the last expression (e.g., from a `return` statement) is converted to a Perl data structure and returned.

If the Lua code throws an error, this method will `die` with the error message from Lua, including a full stack traceback for runtime errors (in non-sandboxed mode).

### `eval_fennel($fennel_code)`

Evaluates a string of Fennel code. This method will only work if the object was created with `sandboxed => 0`.

The code is first compiled to Lua, and then the result is evaluated and returned just like the `eval` method. If the Fennel code has a compilation or runtime error, this method will `die` with a descriptive error message.

## Limitations & Caveats

- **Rust Toolchain:** This module requires a Rust compiler (`rustc`) and `cargo` to be installed on the system during installation. It is not a pure-Perl module.
  
- **JSON Serialization:** All data passed between Perl and Lua is serialized through JSON. This is robust but introduces a small performance overhead. It is not suitable for passing file handles, code references, or other non-serializable data types.
  
- **Sandboxing:** Fennel support requires disabling the sandbox (`sandboxed => 0`), which gives the Lua code access to potentially unsafe libraries like `io` and `os`. Use this option with caution if you are running untrusted code.
  

## Performance

The backend is written in Rust and compiles to a native shared library. The execution of Lua and Fennel code is therefore very fast.

The main performance consideration is the serialization of data between Perl and Lua. For calls that pass large, complex data structures but perform very little work in Lua, the JSON serialization overhead may be noticeable. For use cases involving significant computation within the Lua script, this overhead is typically negligible.

Users with performance-critical applications are encouraged to benchmark their specific use cases.

## Contributing

Issues, feature requests, and pull requests are welcome! Please feel free to open an issue on the [GitHub repository](https://www.google.com/search?q=https://github.com/ItsMeForLua/Inline-Lua "null").

## Author

Andrew D. France [andrewforlua@gmail.com](mailto:andrewforlua@gmail.com "null")

## License

This software is copyright (c) 2025 by Andrew D. France.

This is free software; you can redistribute it and/or modify it under the terms of the **GNU** Lesser General Public **License v3.0**, a copy of which is included in the `LICENSE` file.