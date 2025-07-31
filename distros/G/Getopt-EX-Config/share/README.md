# Getopt::EX::Config Migration MCP Server

An MCP server to assist with migrating Perl scripts to use Getopt::EX::Config.

## Overview

This MCP server provides automated assistance for migrating Perl code from traditional Getopt::Long or Getopt::EX usage to the more modern Getopt::EX::Config format.

## Features

### 1. Code Analysis (`analyze_getopt_usage`)

Analyzes Perl code and extracts information necessary for migration.

**Detection Items:**
- Use statement types (Getopt::Long, Getopt::EX, Getopt::EX::Config)
- GetOptions call patterns
- Existing set/setopt functions
- %opt hash usage patterns
- Option specification details
- Migration complexity assessment

**Example Output:**
```
=== Current Analysis ===
🟡 Migration Difficulty: Medium
✓ Using Getopt::Long
✓ Detected existing set/setopt functions
✓ Found GetOptions calls in 1 location
✓ Detected options: debug, width, name

=== Migration Steps ===
1. Change use statement:
   use Getopt::EX::Config qw(config set);

2. Create configuration object:
   my $config = Getopt::EX::Config->new(
       # Define default values here
   );
```

### 2. Migration Code Generation (`suggest_config_migration`)

Automatically generates migration code examples to Getopt::EX::Config format based on current Perl code.

**Generated Content:**
- Appropriate use statements
- Config object based on detected options
- finalize function implementation examples
- Type-based default value inference

**Generation Example:**
```perl
# Getopt::EX::Config migration version
use Getopt::EX::Config qw(config set);

my $config = Getopt::EX::Config->new(
    # Default values for detected options
    debug => 0,
    width => 0,
    name => '',
);

sub finalize {
    our($mod, $argv) = @_;
    $config->deal_with($argv,
        "debug!",
        "width=i",
        "name=s",
    );
}
```

### 3. Migration Pattern Guide (`show_migration_patterns`)

Displays common migration patterns and best practices.

**Included Content:**
- Basic migration patterns
- Configuration method options
- Boolean value handling
- Success stories
- Common pitfalls

## Usage

### With Claude Code

Claude Code automatically recognizes MCP tools and calls them at appropriate times.

```
User: "I want to migrate this Perl file to use Getopt::EX::Config"
↓
Claude Code automatically calls analyze_getopt_usage
↓ 
Provides migration guidance and concrete code examples
```

### Standalone Usage

```bash
# Start as MCP server
python3 getopt_ex_migrator.py

# Communicate via JSON-RPC protocol
echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "analyze_getopt_usage", "arguments": {"file_content": "use Getopt::Long;..."}}}' | python3 getopt_ex_migrator.py
```

## Technical Specifications

### Dependencies

```python
# Required Python packages
from mcp.server import Server
from mcp.types import Tool, TextContent
```

### Analysis Engine

Uses regex-based pattern matching to detect the following Perl code elements:

- `use Getopt::Long`
- `use Getopt::EX` 
- `use Getopt::EX::Config`
- `GetOptions()` / `GetOptionsFromArray()`
- `sub set` / `sub setopt`
- `$config->deal_with()`
- `%opt` hash usage patterns

### Complexity Assessment

Evaluates migration complexity based on the following criteria:

- 🟢 **Simple** (score ≤ 2): Basic GetOptions usage
- 🟡 **Medium** (score ≤ 4): Has set functions or multiple options
- 🔴 **Complex** (score ≥ 5): Many options or complex structure

## Key Features

### Underscore-to-Dash Conversion Support

Supports Getopt::EX::Config's `$REPLACE_UNDERSCORE` feature, explaining that option names with underscores (`long_lc`) are automatically aliased to support dashes (`--long-lc`) as well.

### Backward Compatibility Explanation

Documents that existing `::set` notation remains usable after migration, supporting gradual migration approaches.

### Example-Based Guidance

Provides practical guidance using real migration success stories like App::Greple::pw.

## Practical Example

### Before Migration (Traditional Module Configuration)

```perl
package App::Greple::example;

our %opt = (
    debug => 0,
    width => 80,
    color => 'auto',
);

sub set {
    my %arg = @_;
    while (my($key, $val) = each %arg) {
        $opt{$key} = $val;
    }
}

# Configuration used throughout the module
sub process {
    print "Debug mode\n" if $opt{debug};
    format_output($opt{width});
}
```

### After Migration (Getopt::EX::Config)

```perl
package App::Greple::example;
use Getopt::EX::Config qw(config set);

my $config = Getopt::EX::Config->new(
    debug => 0,
    width => 80,
    color => 'auto',
);

sub finalize {
    our($mod, $argv) = @_;
    $config->deal_with($argv,
        "debug!",
        "width=i", 
        "color=s",
    );
}

# Configuration used throughout the module
sub process {
    print "Debug mode\n" if $config->{debug};
    format_output($config->{width});
}
```

### Module Configuration Methods

```bash
# Traditional method (::set function)
myapp -Mmodule::set=debug=1,width=120

# Config interface method  
myapp -Mmodule::config=debug=1,width=120

# Module-specific options (requires deal_with implementation)
myapp -Mmodule --debug --width=120 -- regular_args
```

**Key Point:** This migration is purely about **module internal configuration**. The module becomes more flexible in how users can configure its behavior, while maintaining backward compatibility.

## Error Handling

- Appropriate error messages for empty file content
- Error handling for unknown tool names
- Detailed exception information during analysis errors

## Development & Testing

### Running Tests

```bash
# Basic functionality test
python3 -c "
import sys; sys.path.append('.')
from getopt_ex_migrator import GetoptAnalyzer, MigrationGuide
analyzer = GetoptAnalyzer()
result = analyzer.analyze_code('use Getopt::Long;')
print('✓ Test passed' if result['use_getopt_long'] else '✗ Test failed')
"
```

### Real Migration Case Study

This MCP server was actually used to successfully migrate the `lib/Getopt/EX/i18n.pm` file in the `Getopt-EX-i18n` module.

## License

This MCP server is provided under the same license terms as Getopt::EX::Config.

## Contributing

Please report bugs or feature requests as Issues in the project repository.

---

*This MCP server significantly simplifies Getopt::EX::Config migration for Perl modules and enables consistent quality migrations.*