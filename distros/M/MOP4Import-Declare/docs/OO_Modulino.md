# The OO Modulino Pattern

## Overview

OO Modulino (Object-Oriented Modulino) is an extension of Modulino that adds an initialization and method dispatch mechanism, allowing any method to be invoked as a CLI subcommand.

## What is a Modulino?

A Modulino is a design pattern where a module can also function as an executable file ([reference](https://www.masteringperl.org/category/chapters/modulinos/)).

In general, what features a Modulino provides to the CLI is left to the individual programmer's discretion. Therefore, to use arbitrary functions different from those exposed by the CLI, you still need to write scripts.

## OO Modulino Characteristics

OO Modulino introduces a consistent set of conventions to the Modulino's CLI, inspired by CLI tools with subcommands like git:

```
program [GLOBAL_OPTIONS] COMMAND [COMMAND_ARGS]
```

- `GLOBAL_OPTIONS`: Passed to constructor (`--key=value` format)
- `COMMAND`: Method name to invoke
- `COMMAND_ARGS`: Arguments to the method

By introducing this calling convention to the Modulino's CLI, it becomes possible to easily test any method of a module from the command line. This is an extremely valuable characteristic for both module developers and those who test the module later.

### Similarity to Git Commands

This design is inspired by git commands:

- `git --git-dir=/path commit -m "message"`
  - `--git-dir=/path`: Global option (git object configuration)
  - `commit`: Subcommand (method)
  - `-m "message"`: Command argument

Based on the same concept, OO Modulino allows passing module methods and constructor options from the command line:

- `./MyScript.pm --config=prod query "SELECT * FROM users"`
  - `--config=prod`: Constructor option
  - `query`: Method name
  - `"SELECT * FROM users"`: Method argument

## Basic Implementation Examples

As an example, let's look at how to make a Mouse-based module into an OO Modulino.

### Original Module (Mouse-based)

```perl
package Greetings;
use Mouse;

has name => (is => 'rw', default => 'world');

sub hello {
  my ($self, @msg) = @_; +{ result => ["Hello", $self->name, @msg] }
}

sub goodnight {
  my ($self, @msg) = @_; +{ result => ["Good night", $self->name, @msg] }
}
#========================================
1;
```

To test this module from the CLI, you need to write a one-liner like:

```sh
% perl -I. -MGreetings -MJSON -le 'print encode_json(Greetings->new(name => "universe")->hello)'
{"result":["Hello","universe"]}
```

### OO Modulino Implementation (with JSON support)

Let's create `Greetings_oo_modulino_json.pm`, an OO Modulino version of the previous `Greetings.pm`:

```perl
#!/usr/bin/env perl
package Greetings_oo_modulino_json;

# ...omitted...

use JSON;

# Implementation of _parse_long_opts, _decode_json_maybe shown separately

sub cmd_help {
  die "Usage: $0 [OPTIONS] COMMAND ARGS...\n";
}

unless (caller) {
  my $self = __PACKAGE__->new(__PACKAGE__->_parse_long_opts(\@ARGV));

  my $cmd = shift || "help";

  if (my $sub = $self->can("cmd_$cmd")) {
    $sub->($self, map {_decode_json_maybe($_)} @ARGV);
  }
  elsif ($sub = $self->can($cmd)) {
    print encode_json($sub->($self, map {_decode_json_maybe($_)} @ARGV)), "\n";
  }
  else {
    die "Unknown command: $cmd\n";
  }
}
1;
```

With OO Modulino, you can easily test methods. (If your shell is Zsh and you have [App::oo_modulino_zsh_completion_helper](https://metacpan.org/pod/App::oo_modulino_zsh_completion_helper) installed, you can even tab-complete method names):

```sh
% ./Greetings_oo_modulino_json.pm hello '{"foo":"bar"}'
{"result":["Hello","world",{"foo":"bar"}]}

% ./Greetings_oo_modulino_json.pm --name='["foo","bar"]' goodnight
{"result":["Good night",["foo","bar"]]}
```

### Appendix

```perl
sub _parse_long_opts {
  my ($class, $list) = @_;
  my @opts;
  while (@$list and $list->[0] =~ /^--(?:(\w+)(?:=(.*))?)?\z/s) {
    shift @$list;
    last unless defined $1;
    push @opts, $1, _decode_json_maybe($2) // 1;
  }
  @opts;
}

sub _decode_json_maybe {
  my ($str) = @_;
  if (not defined $str) {
    return undef;
  }
  elsif ($str =~ /^(?:\[.*?\]|\{.*?\})\z/s) {
    decode_json($str)
  }
  else {
    $str
  }
}
```

## Summary

The OO Modulino pattern provides these benefits for Perl module development:

- **Immediate feedback**: Test methods as soon as you write them
- **Unified interface**: Consistent CLI conventions
- **Improved testability**: Easy testing in small units
- **Debugging ease**: Standard tools work out of the box

This enables consistent module handling from early development through production deployment.

## References

- [Modulino: both script and module](https://perlmaven.com/modulino-both-script-and-module)
- [Mastering Perl: Modulinos](https://www.masteringperl.org/category/chapters/modulinos/)
- [MOP4Import::Base::CLI_JSON](../Base/CLI_JSON.pod)
- [App::oo_modulino_zsh_completion_helper](https://metacpan.org/pod/App::oo_modulino_zsh_completion_helper)