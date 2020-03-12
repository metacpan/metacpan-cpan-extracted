## Contributing

Thanks for your interest in this project. We welcome all community
contributions! To install locally, follow the instructions in the
[README.md](./README.mkdn) file.

## Releasing

This project uses [Dist::Zilla](https://github.com/rjbs/Dist-Zilla) to manage
its build and release processes. For ease and consistency there is also a
_"release"_ bash script in the project root folder which executes the most
common steps in releasing this software. The script must be executed with the
release's version explicitly specified, and the following is an example of
that:

```
  $ ./release 1.00
```

## Directory Structure

```
  lib
  ├── Class.pm
  ├── Class
  │   └── Widget.pm
  t
  ├── can.t
  ├── can
  │   ├── Class_method.t
  │   └── Class_Widget_method.t
  ├── use.t
  └── use
      ├── Class.t
      └── Class_Widget.t
```

Important! Before you checkout the code and start making contributions you need
to understand the project structure and reasoning. This will help ensure you
put code changes in the right place so they won't get overwritten.

The `lib` directory is where the packages (modules, classes, etc) are. Feel
free to create, delete and/or update as you see fit. All POD (documentation)
changes are made in their respective test files under the `t` directory. This
is necessary because the documentation is auto-generated during release.

The `t/can.t` and `t/use.t` are used to parse and inspect the code changes and
ensure that all classes, methods, functions, etc, are well documented and have
corresponding tests.

Thank you so much!

## Questions, Suggestions, Issues/Bugs

Please post any questions, suggestions, issues or bugs to the [issue
tracker](../../issues) on GitHub.
