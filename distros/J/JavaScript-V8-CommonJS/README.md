# NAME

JavaScript::V8::CommonJS - Modules/1.0 for JavaScript::V8

# SYNOPSIS

    use JavaScript::V8::CommonJS;

    my $js = JavaScript::V8::CommonJS->new(paths => ["./modules"]);

    print $js->eval('require("foo").add(4, 2)');  # prints 6

    # modules/foo.js
    # exports.add = function(a, b) { return a + b }

# DESCRIPTION

CommonJS implementation for JavaScript::V8. Currently only Module/1.0 spec is implemented. (Passing all unit tests at [https://github.com/commonjs/commonjs/tree/master/tests/modules/1.0](https://github.com/commonjs/commonjs/tree/master/tests/modules/1.0))

# CONSTRUCTOR

## new

All arguments are optional.

- paths

    Arrayref of paths to search for modules. Default: \[getcwd()\].

- modules

    Hashref of native modules. Default: {}.

# METHODS

## add\_module(name => module)

Register native modules. Attempting to register a module twice is a fatal error.

    $js->add_module( http => {
        get => sub { ... },
        post => sub { ... },
        ...
    });

## eval(js\_code, source)

Evaluates javascript source code on the global context. JS exceptions are rethrown as [JavaScript::V8::CommonJS::Exception](https://metacpan.org/pod/JavaScript::V8::CommonJS::Exception) instances.

    $js->eval('require("program").doSomething()', "main")

The second argument is a source or filename to be reported on error messages.

## eval\_file(path)

    $js->eval_file("main.js")

## c

Returns the JavaScript::V8::Context instance.

    # run v8 garbage collector
    $js->c->idle_notification

# LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Carlos Fernando Avila Gratz <cafe@kreato.com.br>
