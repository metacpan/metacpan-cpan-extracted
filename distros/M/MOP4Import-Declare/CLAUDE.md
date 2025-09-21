# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

### Prerequisites
```bash
# Install dependencies (requires cpm)
cpm install -g

# Or install cpm first if needed
curl -fsSL --compressed https://git.io/cpm > cpm
chmod +x cpm
PATH=.:$PATH cpm install -g
```

### Build
```bash
# Generate Build script from Build.PL
perl Build.PL

# Build the distribution
./Build build
```

### Testing
```bash
# Run all tests
./Build test

# Run a specific test file
perl -Mblib t/02_declare.t

# Run tests with verbose output
./Build test verbose=1
```

### Clean
```bash
./Build clean
./Build realclean
```

## Project Architecture

MOP4Import::Declare is a Meta-Object Protocol library for building extensible exporters in Perl. It provides a thin layer to map import arguments to pragma methods.

### Core Components

- **MOP4Import::Declare** (Declare.pm): Main module that provides the `-as_base` pragma for creating exporters. Handles the meta-protocol for mapping import arguments to `declare_*` methods.

- **MOP4Import::Types** (Types.pm): Type system built on `fields.pm` providing compile-time field checking. Central to the architecture for creating typed classes with checked fields.

- **MOP4Import::Base::CLI** (Base/CLI.pm): Framework for building command-line interfaces with automatic help generation, option parsing, and subcommand support.

- **MOP4Import::Base::CLI_JSON** (Base/CLI_JSON.pm): Base class for rapidly building testable CLI modules. Enables immediate command-line testing of any module method with automatic JSON serialization of inputs/outputs. Designed to accelerate module development through exploratory testing.

### Key Patterns

1. **Pragma Methods**: Methods prefixed with `declare_` implement import pragmas. When a module uses `-foo`, it calls `declare_foo()`.

2. **Field Declaration**: Uses Perl's `fields` pragma and `%FIELDS` for compile-time checking of object fields via `my TYPE $var` syntax.

3. **Type System**: The `use MOP4Import::Types` pattern creates typed classes with checked fields, providing compile-time safety for typos in field names.

4. **CLI Framework**: Subcommands are methods prefixed with `cmd_`. Options are fields declared in the class.

5. **OO Modulino Pattern**: Single Perl file acts as both class module and CLI executable. CLI_JSON implements this pattern allowing any method to be called directly from command line for rapid testing and development.

## Testing Considerations

- Tests require multiple Perl modules: Test::Kantan, Test::Differences, Test::Output, Test::Exit, Test2::Tools::Command
- CI runs against Perl versions 5.16 through 5.40 plus threaded builds
- Some tests may skip on older Perl versions (< 5.018)

## Dependencies

Core runtime dependencies:
- JSON::MaybeXS
- Sub::Util >= 1.40
- Module::Runtime

Test dependencies include Test::Kantan, Test::Differences, Capture::Tiny, and others listed in cpanfile.

## Documentation Structure

- **Base/CLI_JSON.pod**: Reference manual for CLI_JSON users (how to use CLI_JSON to write OO Modulino)
- **docs/CLI_JSON_rationale.md**: Explains the rationale and value proposition of CLI_JSON
- **docs/OO_Modulino.md**: Conceptual explanation of the OO Modulino pattern
- **docs/CLI_JSON_rationale.ja.md**: Japanese version of rationale document
- **docs/OO_Modulino.ja.md**: Japanese version of OO Modulino pattern explanation

## CLI_JSON Development Workflow

When developing modules with CLI_JSON:

1. Create minimal module with `use MOP4Import::Base::CLI_JSON -as_base`
2. Add `MY->cli_run(\@ARGV) unless caller;` for CLI capability
3. Check syntax with `perl -wc` or `perlminlint`
4. Set executable bit with `chmod +x`
5. Test methods immediately from command line
6. Use `perl -d` for debugging, `perl -d:NYTProf` for profiling

This workflow enables rapid exploratory development with immediate feedback.