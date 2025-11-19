# PageCamel Framework - Coding Style Guide

**Version:** 4.8
**Last Updated:** 2025-10-31
**Author:** Based on analysis of PageCamel framework codebase

## Table of Contents

1. [File Organization and Naming](#file-organization-and-naming)
2. [Boilerplate and Pragmas](#boilerplate-and-pragmas)
3. [Indentation and Whitespace](#indentation-and-whitespace)
4. [Naming Conventions](#naming-conventions)
5. [Control Structures](#control-structures)
6. [Error Handling](#error-handling)
7. [Functions and Subroutines](#functions-and-subroutines)
8. [Object-Oriented Programming](#object-oriented-programming)
9. [Database Operations](#database-operations)
10. [Comments and Documentation](#comments-and-documentation)
11. [Code Layout Patterns](#code-layout-patterns)

---

## File Organization and Naming

### Module Files (.pm)

**Location:** `lib/PageCamel/`

**Naming Convention:**
- Use hierarchical namespace structure
- CamelCase for module names
- Each component in the path uses CamelCase

**Examples:**
```
lib/PageCamel/Helpers/ConfigLoader.pm       → package PageCamel::Helpers::ConfigLoader
lib/PageCamel/Web/BaseModule.pm             → package PageCamel::Web::BaseModule
lib/PageCamel/CMDLine/Worker.pm             → package PageCamel::CMDLine::Worker
lib/PageCamel/Web/Users/Login.pm            → package PageCamel::Web::Users::Login
lib/PageCamel/Helpers/PostgresDB.pm         → package PageCamel::Helpers::PostgresDB
```

**Pattern:**
- File path directly corresponds to package name
- Replace `::` with `/` in filesystem
- Add `.pm` extension

### Script Files (.pl)

**Location:** `devscripts/` or project root

**Naming Convention:**
- All lowercase
- Use descriptive names
- Separate words with no separators or use underscores in compound words

**Examples:**
```
devscripts/stylecorrect.pl
devscripts/fixcroak.pl
devscripts/tabs2spaces.pl
devscripts/setversion.pl
devscripts/compilejs.pl
```

---

## Boilerplate and Pragmas

### Standard Pragma Block (AUTOPRAGMASTART/AUTOPRAGMAEND)

Every Perl file (.pm and .pl) MUST start with this exact boilerplate:

```perl
#---AUTOPRAGMASTART---
use v5.40;
use strict;
use diagnostics;
use mro 'c3';
use English;
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 4.8;
use autodie qw( close );
use Array::Contains;
use utf8;
use Data::Dumper;
use Data::Printer;
#---AUTOPRAGMAEND---
```

**Rules:**
1. The pragma block is always enclosed between `#---AUTOPRAGMASTART---` and `#---AUTOPRAGMAEND---` markers
2. The order of pragmas is fixed and must not be changed
3. `$VERSION` is always set to the current framework version
4. Always use these exact pragmas in this exact order
5. For script files (.pl), add shebang line BEFORE the pragma block:
   ```perl
   #!/usr/bin/env perl
   #---AUTOPRAGMASTART---
   ...
   ```

### Additional Module-Specific Imports

After the AUTOPRAGMA block, add module-specific imports with ONE blank line separating them:

```perl
#---AUTOPRAGMAEND---

use base qw(Exporter);
our @EXPORT = qw(LoadConfig);
use XML::Simple;
use PageCamel::Helpers::FileSlurp qw(slurpBinFile);
```

### Output Functions

**Rule:** Always use `print` for console output. **NEVER use `say`.**

The `say` function (which adds an automatic newline) is not used in the PageCamel framework. All console output must use `print` with explicit newlines.

**Correct:**
```perl
print "Processing request\n";
print "Value: $value\n";
print STDERR "Error occurred\n";
```

**Incorrect:**
```perl
say "Processing request";          # WRONG: don't use say
say "Value: $value";                # WRONG: don't use say
say STDERR "Error occurred";        # WRONG: don't use say
```

**Rationale:** Consistent use of `print` makes the codebase more predictable and ensures explicit control over newlines.

---

## Indentation and Whitespace

### Indentation

**Rule:** Use **4 spaces** for each indentation level. **NEVER use tabs.**

The codebase includes a script (`devscripts/tabs2spaces.pl`) that enforces this:
```perl
$line =~ s/\t/    /g;  # Convert tabs to 4 spaces
```

**Example:**
```perl
sub example {
    my ($self, $arg) = @_;

    if($condition) {
        my $result = do_something();
        return $result;
    }

    return;
}
```

### Control Keywords and Parentheses

**Rule:** **NO space** between control keywords and opening parenthesis.

**Correct:**
```perl
if($condition) { ... }
while($condition) { ... }
for(my $i = 0; $i < 10; $i++) { ... }
foreach my $item (@array) { ... }
unless($condition) { ... }
until($condition) { ... }
```

**Incorrect:**
```perl
if ($condition) { ... }      # WRONG: space after 'if'
while ($condition) { ... }   # WRONG: space after 'while'
for (my $i = 0; $i < 10; $i++) { ... }  # WRONG: space after 'for'
```

### Function Calls and Parentheses

**Rule:** NO space between function name and opening parenthesis.

**Correct:**
```perl
my $result = function($arg1, $arg2);
$dbh->prepare("SELECT * FROM table");
print("Hello World\n");
```

**Incorrect:**
```perl
my $result = function ($arg1, $arg2);   # WRONG
$dbh->prepare ("SELECT * FROM table");  # WRONG
```

### Cuddled Else

**Rule:** Use "cuddled else" style - closing brace, `else`/`elsif`, and opening brace on the same line.

**Correct:**
```perl
if($condition) {
    do_something();
} else {
    do_something_else();
}

if($condition1) {
    action1();
} elsif($condition2) {
    action2();
} else {
    action3();
}
```

**Incorrect:**
```perl
if($condition) {
    do_something();
}
else {                    # WRONG: else on new line
    do_something_else();
}
```

### Spacing in Expressions

**Rules:**
- Space around most binary operators: `=`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `&&`, `||`, `.` (concatenation)
- Space after commas in lists
- NO space inside parentheses
- NO space inside square brackets
- NO space inside curly braces for hash access

**Examples:**
```perl
my $result = $a + $b;
my $check = ($x == 5 && $y > 10);
my @list = (1, 2, 3, 4);
my $hash = {key => 'value', another => 42};
$array[0] = $hash->{key};
```

### Blank Lines

**Rules:**
1. ONE blank line after the AUTOPRAGMA block
2. ONE blank line between subroutines
3. Use blank lines to separate logical sections within functions
4. NO blank lines at the start of a subroutine
5. NO multiple consecutive blank lines

**Example:**
```perl
#---AUTOPRAGMAEND---

use XML::Simple;

sub first_function {
    my ($self, $arg) = @_;

    my $step1 = process_input($arg);

    if($step1) {
        return result($step1);
    }

    return;
}

sub second_function {
    my ($self) = @_;

    return $self->{value};
}
```

---

## Naming Conventions

**General Rule:** Variable and function names use **camelCase** with the first letter lowercase. **Avoid underscores** in variable and function names.

**Exceptions where underscores ARE used:**
- Database column names (external data)
- Configuration file keys (XML, JSON, etc.)
- Hash keys from external sources
- Private/internal functions (leading underscore: `_functionName`)
- Module-level variables with special purpose
- Perl built-in variables (when not using English module)

### Variables

**Rule:** Use camelCase with the first letter lowercase.

**Scalars:**
Use camelCase for multi-word names:
```perl
my $count = 0;
my $userName = "admin";
my $dbHandle = get_database();
my $maxRetries = 5;
my $fileName = "config.xml";
my $isDebugging = 0;
my $sessionID = generate_id();
```

**Single-word names:**
```perl
my $count = 0;
my $name = "value";
my $value = 42;
my $data = fetch();
```

**Arrays:**
```perl
my @files = getFileList();
my @userList = ();
my @modlist = @{$config->{module}};
my @lines = split(/\n/, $text);
```

**Hashes:**
```perl
my %config = loadConfig();
my %settings = (
    allowKeepLoggedIn => 0,
    standardValidTime => '10 minutes',
);
```

**Note on Hash Keys:** Hash keys from configuration files or databases may retain their original format (e.g., `snake_case` from XML/database), but Perl variable names should use camelCase.

**Hash and Array References:**
```perl
my $hashref = {key => 'value'};
my $arrayref = [1, 2, 3];
my $value = $hashref->{key};
my $element = $arrayref->[0];
```

### Singular/Plural Naming in Iterations

**Rule:** Use plural names for collections (arrays/hashes) and singular names for iterator variables.

#### Array Iteration Patterns

**Standard Pattern: Plural Array → Singular Iterator**

```perl
# Correct
my @users = get_all_users();
foreach my $user (@users) {
    process_user($user);
}

my @files = get_file_list();
foreach my $file (@files) {
    if(-f $file) {
        process_file($file);
    }
}

my @lines = split(/\n/, $data);
foreach my $line (@lines) {
    print "$line\n";
}

# More examples
my @parts = split(/\ /, $text);
foreach my $part (@parts) { ... }

my @keys = keys %hash;
foreach my $key (@keys) { ... }

my @langs = ('en', 'de', 'fr');
foreach my $lang (@langs) { ... }

my @settings = list_all_settings();
foreach my $setting (@settings) { ... }
```

**Common Plural/Singular Pairs:**
- `@users` → `$user`
- `@files` → `$file`
- `@lines` → `$line`
- `@parts` → `$part`
- `@keys` → `$key`
- `@values` → `$value`
- `@items` → `$item`
- `@entries` → `$entry`
- `@results` → `$result`
- `@rows` → `$row`
- `@langs` / `@languages` → `$lang` / `$language`
- `@settings` → `$setting`
- `@permissions` → `$permission`
- `@sourceFiles` → `$sourceFile`
- `@userPermissions` → `$userPermission`
- `@fileNames` → `$fileName`

#### Hash Iteration Patterns

**Iterating Over Keys:**
```perl
my %config = load_config();
foreach my $key (keys %config) {
    my $value = $config{$key};
    print "$key = $value\n";
}

# Or with sorted keys
foreach my $keyname (sort keys %{$self->{fields}}) {
    process_field($keyname, $self->{fields}->{$keyname});
}
```

**Iterating Over Hash with Descriptive Names:**
```perl
foreach my $setting (keys %settings) {
    my $value = $settings{$setting};
    update_setting($setting, $value);
}

foreach my $module_name (keys %modules) {
    $modules{$module_name}->init();
}
```

**Database Result Sets:**
```perl
while((my $line = $sth->fetchrow_hashref)) {
    # $line is a hash reference to one row
    process_row($line);
}

while((my $row = $sth->fetchrow_hashref)) {
    print $row->{username}, "\n";
}

while((my @row = $sth->fetchrow_array)) {
    # @row is an array of column values
    process_columns(@row);
}
```

#### Loop Counter Variables

**Simple Counters:**
```perl
for(my $i = 0; $i < $count; $i++) {
    process_item($i);
}

# Nested loops
for(my $i = 0; $i < $rows; $i++) {
    for(my $j = 0; $j < $cols; $j++) {
        process_cell($i, $j);
    }
}
```

**Named Counters:**
```perl
my $count = 0;
my $cnt = 0;
my $fcount = 0;        # file count
my $retrycount = 10;   # retry count
```

#### Temporary and Status Variables

**Temporary Variables:**
```perl
my $tmp = process_data($input);
my $temp = decode_utf8($_[$j]);
my $tempnum = $pre . join('', @newparts);
```

**Status/Flag Variables:**
```perl
my $ok = 0;
my $success = 0;
my $initok = 0;
my $is_init = 0;
my $haswritten = 0;
my $needUpdate = 0;
```

**Result Variables:**
```perl
my $result = calculate();
my $retval = function_call();
my $data = fetch_data();
```

#### Handle Variable Naming

**Common Handle Abbreviations:**
```perl
my $dbh = ...;      # Database handle
my $sth = ...;      # Statement handle (prepared statement)
my $memh = ...;     # Memcache handle
my $reph = ...;     # Reporting handle
my $fh = ...;       # File handle
my $dfh = ...;      # Directory file handle
my $ofh = ...;      # Output file handle
my $ifh = ...;      # Input file handle
```

**Examples in Context:**
```perl
open(my $fh, '<', $filename) or croak("Cannot open: $ERRNO");
my @lines = <$fh>;
close $fh;

opendir(my $dfh, $directory) or croak("$ERRNO");
while((my $fname = readdir($dfh))) {
    process_file($fname);
}
closedir($dfh);

my $sth = $dbh->prepare_cached("SELECT * FROM users WHERE id = ?")
        or croak($dbh->errstr);
```

#### Building Result Collections

**Pattern: Singular → Plural**

When building a collection, use singular for the source and plural for destination:

```perl
# Collecting results
my @results;
foreach my $user (@allUsers) {
    my $result = processUser($user);
    push @results, $result;
}

# Filtering items
my @validFiles;
foreach my $file (@allFiles) {
    if(-f $file && $file =~ /\.pm$/) {
        push @validFiles, $file;
    }
}

# Transforming data
my @usernames;
foreach my $user (@users) {
    push @usernames, $user->{username};
}
```

#### Special Cases and Exceptions

**When the Singular Form is Awkward:**

Some words don't have natural singular forms, so use descriptive names:

```perl
# Instead of @datum → $datum (awkward)
my @dataPoints;
foreach my $point (@dataPoints) { ... }

# Instead of @information → $information (same)
my @infoItems;
foreach my $item (@infoItems) { ... }

# Already singular words
my @settings;
foreach my $setting (@settings) { ... }  # "setting" is already singular-ish
```

**Compound Names:**

```perl
my @sourceFiles;
foreach my $sourceFile (@sourceFiles) { ... }

my @userPermissions;
foreach my $userPermission (@userPermissions) { ... }

my @fileNames;
foreach my $fileName (@fileNames) { ... }
```

**Anonymous Iteration (when item not used):**

```perl
# When you just need to iterate N times
for(1..10) {
    do_something();
}

for(1..$count) {
    push @array, generate_item();
}

# Incrementing counters
$counter++ for(@items);
```

### Subroutines and Methods

**Rule:** Use camelCase with the first letter lowercase. **Avoid underscores** in function names.

**Examples:**
```perl
sub loadConfig { ... }
sub getSessionId { ... }
sub validateSession { ... }
sub createCookie { ... }
sub handleChildStart { ... }
sub getSettings { ... }
sub checkDBH { ... }
sub updateConfig { ... }
sub newClacksFromConfig { ... }
```

**Single-word function names:**
```perl
sub init { ... }
sub reload { ... }
sub register { ... }
sub get { ... }
sub set { ... }
sub delete { ... }
```

**Exception - Private Methods/Functions:**

Private or internal functions may use a leading underscore:
```perl
sub _getColumnType { ... }     # Private helper method
sub _logfromjs { ... }          # Internal logging function
sub _getLocalIPs { ... }        # Private utility function
```

**Note:** The leading underscore indicates the function is internal and should not be called from outside the module.

**Method Parameters:**

Modern Perl signatures are used:
```perl
sub functionName($self, $param1, $param2) {
    # function body
}
```

For methods:
```perl
sub methodName($self, $arg1, $arg2, %options) {
    # method body
}
```

First parameter is always `$self` for methods, `$class` for constructors.

**Parameter Naming:**
```perl
sub processUser($self, $userId, $userName, $isActive) {
    # Parameters use camelCase
}
```

### Constants

**Rule:** Use `Readonly` module for constants with UPPERCASE names:

```perl
use Readonly;
Readonly::Scalar my $BLOBMODE => 0x00020000;
```

**Note:** For constants with hexadecimal notation, Perl Critic may require explicit annotation:
```perl
Readonly::Scalar my $BLOBMODE => 0x00020000; ## no critic (ValuesAndExpressions::RequireNumberSeparators)
```

### Large Numbers

**Rule:** Split large numbers into groups of three digits using underscore (`_`) for readability.

**Correct:**
```perl
my $large_value = 1_000_000;
my $count = 5_000;
my $max_size = 100_000_000;
```

**Incorrect:**
```perl
my $large_value = 1000000;   # WRONG: hard to read
my $count = 5000;            # WRONG: use 5_000
```

**Exception:** Hexadecimal and octal numbers may not need separators if they represent bit patterns:
```perl
my $mask = 0x00020000;  # OK for bit patterns
```

### Magic Variables and English Module

**Rule:** Always use the `English` module and prefer long variable names over Perl magic variables.

The AUTOPRAGMA block includes `use English;` which enables these readable names.

**Correct (using English names):**
```perl
open(my $fh, '<', $file) or croak("Cannot open $file: $ERRNO");
print "Process ID: $PID\n";
print "Program name: $PROGRAM_NAME\n";
die("Error: $EVAL_ERROR");
```

**Incorrect (using magic variables):**
```perl
open(my $fh, '<', $file) or croak("Cannot open $file: $!");  # WRONG: use $ERRNO
print "Process ID: $$\n";                                     # WRONG: use $PID
print "Program name: $0\n";                                   # WRONG: use $PROGRAM_NAME
die("Error: $@");                                             # WRONG: use $EVAL_ERROR
```

**Common English Variable Names:**
- `$ERRNO` instead of `$!` (system error)
- `$EVAL_ERROR` instead of `$@` (eval error)
- `$PID` instead of `$$` (process ID)
- `$PROGRAM_NAME` instead of `$0` (program name)
- `$INPUT_LINE_NUMBER` instead of `$.` (line number)
- `$OUTPUT_AUTOFLUSH` instead of `$|` (autoflush)
- `$CHILD_ERROR` instead of `$?` (child process error)

### Package/Module Names

**Rule:** CamelCase with namespace hierarchy:
```perl
package PageCamel::Helpers::ConfigLoader;
package PageCamel::Web::BaseModule;
package PageCamel::CMDLine::Worker;
```

---

## Control Structures

### If Statements

**Format:**
```perl
if($condition) {
    statement;
}

if($condition) {
    statement1;
} else {
    statement2;
}

if($condition1) {
    statement1;
} elsif($condition2) {
    statement2;
} else {
    statement3;
}
```

**Postfix form** for simple statements:
```perl
return unless defined($value);
next if($skip_this);
last if($found);
```

### Unless

Use `unless` for negative conditions (but prefer `if(!...)` for clarity in complex cases):
```perl
unless($condition) {
    handle_error();
}

return unless defined($session);
```

### While and Until Loops

```perl
while($condition) {
    process();
}

until($done) {
    work();
}

while((my $line = $sth->fetchrow_hashref)) {
    process_line($line);
}
```

### For Loops

**C-style for:**
```perl
for(my $i = 0; $i < $count; $i++) {
    process($i);
}

for(1..25) {
    $randchars .= substr($validChars, int(rand(length($validChars))), 1);
}
```

### Foreach Loops

```perl
foreach my $item (@array) {
    process($item);
}

foreach my $key (keys %hash) {
    print "$key => $hash{$key}\n";
}
```

### Goto Labels

**Rule:** Labels should be lowercase and descriptive. Use `goto` sparingly for cleanup code.

```perl
if($error) {
    goto cleanup;
}

process_data();

cleanup:
    close_resources();
    return;
```

**Example from codebase:**
```perl
finishlogin:
    $webdata{password} = "";
    # cleanup code
```

---

## Error Handling

### Using croak()

**Import:**
```perl
use Carp qw[carp croak confess cluck longmess shortmess];
```

**Rule:** Always pass error messages to `croak()` as quoted strings.

**Correct:**
```perl
croak("Can't load config file: Not found!");
croak("Database connection failed");
$sth->execute() or croak($dbh->errstr);
```

**Pattern for checking return values:**
```perl
my $sth = $dbh->prepare_cached("SELECT ...")
    or croak($dbh->errstr);

$sth->execute($param)
    or croak($dbh->errstr);
```

### Using confess()

Use `confess()` for parameter validation in public APIs:
```perl
confess("No Webpath specified") unless defined($path);
confess("No function name specified") unless defined($funcname);
```

### Eval Blocks

**Pattern:** Use eval blocks with a success flag for exception handling.

**Standard Pattern:**
```perl
sub risky_operation($self) {
    my $success = 0;

    eval {
        # Risky code here
        my $result = do_something_dangerous();

        # More code

        $success = 1;
    };

    if(!$success) {
        handle_error('OPERATION FAILED', $EVAL_ERROR);
    }

    return;
}
```

**Real Example from CMDLine::Worker:**
```perl
sub init($self) {
    my $initok = 0;

    eval {
        my $worker = PageCamel::Worker->new();

        # ... initialization code ...

        $initok = 1;
    };

    if(!$initok) {
        suicide('INIT FAILED', $EVAL_ERROR);
    }

    return;
}
```

**For inline eval (ignoring return value):**
```perl
eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    my $temp = decode_utf8($_[$j]);
    $_[$j] = $temp;
};
```

### Die vs Croak vs Confess

- **croak()**: Standard error reporting (most common)
- **confess()**: Error with full stack trace (for debugging parameter issues)
- **die()**: Rarely used; prefer croak
- **carp()**: Warning equivalent of croak
- **cluck()**: Warning with stack trace

---

## Functions and Subroutines

### Function Signatures

**Modern Perl Signatures (v5.40):**
```perl
sub function_name($param1, $param2, $param3) {
    # Function body
}

sub method($self, $arg1, $arg2) {
    # Method body
}

sub with_defaults($self, $required, $optional = 0) {
    # Body
}
```

### Return Values

**Always explicitly return:**
```perl
sub get_value($self) {
    return $self->{value};
}

sub process($self) {
    my $result = calculate();
    return $result;
}
```

**For procedures (no return value):**
```perl
sub cleanup($self) {
    $self->close_handles();

    return;  # Explicit return with no value
}
```

### Exporting Functions

```perl
use base qw(Exporter);
our @EXPORT = qw(LoadConfig);  # Automatic export
our @EXPORT_OK = qw(arraytohashkeys hashcountfromarray);  # Optional export
```

---

## Object-Oriented Programming

### Constructor (new)

**Standard Pattern:**
```perl
sub new($proto, %config) {
    my $class = ref($proto) || $proto;

    my $self = bless \%config, $class;

    # Initialize
    $self->{somefield} = 'default';

    return $self;
}
```

**With Parent Class:**
```perl
sub new($proto, %config) {
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%config);  # Call parent NEW
    bless $self, $class;  # Re-bless with our class

    # Initialize

    return $self;
}
```

### Inheritance

```perl
use base qw(PageCamel::Web::BaseModule);
```

### Object Methods

**Always use `$self` as first parameter:**
```perl
sub method_name($self, $param) {
    my $value = $self->{field};
    $self->{another_field} = $param;

    return $value;
}
```

### Class Methods

**Use `$class` for constructors and class methods:**
```perl
sub create($class, %args) {
    return $class->new(%args);
}
```

---

## Database Operations

### Database Handle Access

**Pattern:** Wrap DBI operations with proper error checking.

**Important Rules:**

1. **`prepare()` and `prepare_cached()`**: Use `or croak()` - preparation failures are critical
   - The `or croak(...)` clause is **indented one additional level** (4 more spaces) for visual clarity

2. **`execute()`**: Use proper error handling with logging and rollback (preferred), not `or croak()`

**Preferred Pattern (with proper error handling):**
```perl
my $sth = $dbh->prepare_cached("SELECT * FROM table WHERE id = ?")
        or croak($dbh->errstr);

if(!$sth->execute($id)) {
    $reph->debuglog($dbh->errstr);
    $dbh->rollback;
    return;  # or return error status
}

while((my $line = $sth->fetchrow_hashref)) {
    process($line);
}
$sth->finish;
$dbh->commit;
```

**Visual Clarity for `or croak`:**
```perl
# The 'or croak' is indented 4 additional spaces from the statement above
my $sth = $dbh->prepare_cached("SELECT username FROM users WHERE id = ?")
        or croak($dbh->errstr);
#   ^^^^
#   Additional 4-space indentation for visual clarity
```

### Prepared Statements

**Always use placeholders:**

**Preferred pattern:**
```perl
my $sth = $dbh->prepare_cached("SELECT username, email
                                FROM users
                                WHERE username = ?")
        or croak($dbh->errstr);

if(!$sth->execute($username)) {
    $reph->debuglog($dbh->errstr);
    $dbh->rollback;
    return 0;  # or appropriate error handling
}
```

**Acceptable for simple queries where failure is not expected:**
```perl
# Only use this pattern in simple, non-critical operations
$sth->execute($username) or croak($dbh->errstr);
```

**Multi-line SQL:** Indent continued lines, with `or croak` indented one additional level:
```perl
my $sth = $dbh->prepare_cached("SELECT username, email_addr,
                               first_name, last_name, name_initials,
                               organisation, user_id
                               FROM users
                        WHERE username = ?")
        or croak($dbh->errstr);
#       ^^^^^^^^
#       Two levels of indentation (8 spaces total):
#       - 4 spaces for being inside the function
#       - 4 more spaces for the 'or croak' continuation

if(!$sth->execute($username)) {
    $reph->debuglog($dbh->errstr);
    $dbh->rollback;
    return;
}
```

### Transaction Handling

**Preferred Pattern (with logging and proper error handling):**
```perl
my $sth = $dbh->prepare_cached("UPDATE users SET last_login = now() WHERE id = ?")
        or croak($dbh->errstr);

if(!$sth->execute($user_id)) {
    $reph->debuglog($dbh->errstr);
    $dbh->rollback;
    return 0;  # Return error status
}
$dbh->commit;
```

**More complex error handling:**
```perl
my $selsth = $dbh->prepare_cached("SELECT * FROM users WHERE username = ?")
        or croak($dbh->errstr);

if(!$selsth->execute($username)) {
    $reph->debuglog($dbh->errstr);
    $dbh->rollback;
    return (status => 500);  # Return HTTP error
}

my $user = $selsth->fetchrow_hashref;
$selsth->finish;

if(!defined($user)) {
    $dbh->rollback;
    return (status => 404);  # User not found
}

$dbh->commit;
return (status => 200, user => $user);
```

**Simple pattern (only when failure is truly unexpected):**
```perl
if(!$sth->execute($param)) {
    $dbh->rollback;
    croak($dbh->errstr);
}
$dbh->commit;
```

### Summary: Database Error Handling Best Practices

**Key Rules:**

1. **`prepare()` and `prepare_cached()` → Use `or croak()`**
   - Preparation failures are always critical (syntax errors, connection issues)
   - Use `or croak()` with additional indentation (4 spaces)
   - Example: `my $sth = $dbh->prepare_cached("...") or croak($dbh->errstr);`

2. **`execute()` → Use proper error handling (preferred)**
   - Most `execute()` operations should use: `if(!$sth->execute()) { ... }`
   - Always log error: `$reph->debuglog($dbh->errstr);`
   - Always rollback: `$dbh->rollback;`
   - Return appropriate error status or value
   - Only use `or croak()` for truly unexpected failures

3. **Why not `$sth->execute() or croak()`?**
   - Doesn't log the error for debugging
   - Doesn't allow graceful error handling
   - Crashes the entire process instead of returning error status
   - Can't provide meaningful HTTP error codes or user feedback

**Anti-Pattern (avoid this):**
```perl
$sth->execute($param) or croak($dbh->errstr);  # WRONG in most cases
```

**Correct Pattern:**
```perl
if(!$sth->execute($param)) {
    $reph->debuglog($dbh->errstr);
    $dbh->rollback;
    return 0;  # or appropriate error value
}
```

---

## Comments and Documentation

### Inline Comments

**Use `#` for comments:**
```perl
# This is a single-line comment
my $value = 42;  # End-of-line comment
```

**Multi-line comments:**
```perl
# This is a longer explanation
# that spans multiple lines
# to describe something complex
my $complex = calculate();
```

### POD Documentation

**Location:** Always at the end of the file after `__END__`.

**Standard Structure:**
```perl
1;
__END__

=head1 NAME

PageCamel::Module::Name - Brief description

=head1 SYNOPSIS

  use PageCamel::Module::Name;

=head1 DESCRIPTION

Detailed description of the module's purpose and functionality.

=head2 function_name

Description of what this function does.

=head2 another_function

Description of another function.

=head1 IMPORTANT NOTE

This module is part of the PageCamel framework. Currently, only limited support
and documentation exists outside my DarkPAN repositories. This source is
currently only provided for your reference and usage in other projects (just
copy&paste what you need, see license terms below).

To see PageCamel in action and for news about the project,
visit my blog at L<https://cpan.org>.

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2020 Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
```

### Perl Critic Annotations

**Disable specific critic warnings:**
```perl
## no critic (TestingAndDebugging::ProhibitNoStrict)
no strict 'refs';
# ... code that needs symbolic references ...
use strict 'refs';

## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
eval {
    attempt_something();
};
```

---

## Code Layout Patterns

### Module Structure

**Standard module file layout:**

1. Package declaration
2. AUTOPRAGMA block
3. Additional imports
4. Constructor (`new`)
5. Public methods
6. Private methods (prefixed with `_` if needed)
7. Auto-generated functions (if using BEGIN blocks)
8. Return true value: `1;`
9. `__END__`
10. POD documentation

### Initialization Patterns

**Configuration validation:**
```perl
sub new($proto, %config) {
    my $class = ref($proto) || $proto;
    my $self = bless \%config, $class;

    my $ok = 1;
    # Required settings
    foreach my $key (qw[db memcache systemsettings]) {
        if(!defined($self->{$key})) {
            print STDERR "Module.pm: Setting $key is required but not set!\n";
            $ok = 0;
        }
    }
    if(!$ok) {
        croak("Failed to load " . $self->{modname} . " due to config errors!");
    }

    return $self;
}
```

### BEGIN Blocks for Auto-Generation

**Pattern:** Generate similar methods programmatically:
```perl
BEGIN {
    # Auto-magically generate a number of similar functions
    my @stdFuncs = qw(prefilter postfilter defaultwebdata);

    for my $f (@stdFuncs) {
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::register_$f"} =
            sub ($arg1, $arg2) {
                my $funcname = "add_$f";
                confess("No function name specified") unless defined($funcname);
                $arg1->{server}->$funcname($arg1, $arg2);
            };
    }
}
```

### Hash Reference Pattern

**Creating structured data:**
```perl
my %config = (
    key1 => 'value1',
    key2 => 42,
    nested => {
        inner_key => 'inner_value',
    },
    array_ref => [1, 2, 3],
);
```

**Multi-line hash for readability:**
```perl
return (
    status      => 200,
    type        => "text/html",
    data        => $template,
    location    => $redirect_url,
);
```

---

## Advanced Patterns and Best Practices

### Readonly Constants

**Rule:** Use `Readonly` module for module-level constants that should not change.

```perl
use Readonly;
Readonly::Scalar my $RETRY_COUNT  => 10;
Readonly::Scalar my $RETRY_WAIT   => 0.05;
Readonly::Scalar my $BLOBMODE => 0x00020000; ## no critic (ValuesAndExpressions::RequireNumberSeparators)
Readonly my $SSL_SESS_CACHE_OFF => 0x0000;
```

**Why use Readonly?**
- Prevents accidental modification of constants
- Self-documenting code
- Compiler can optimize
- Use `## no critic` annotation for hex values that don't need separators

### Boolean Coercion

**Rule:** Use `!!` (double negation) to coerce values to boolean.

```perl
my $has = !!contains($permission, $permissions);
$self->{metaonly} = !!$metaonly;
$negate = !!$negate;
```

**Why:** Makes boolean intent explicit and ensures consistent true/false values (1/0).

### Reference Type Checking

**Rule:** Use `ref()` function to check reference types before dereferencing.

```perl
if(ref $hval eq 'ARRAY') {
    $hval = 'ARRAY(' . join(', ', @{$hval}) . ')';
}

if(!ref($data)) {
    croak("Data buffer is not a reference!");
}

my $r = ref($self->{fields}->{$keyname});
if($r eq 'HASH') {
    # Handle hash reference
}
```

**Common ref() return values:**
- `'SCALAR'` - scalar reference
- `'ARRAY'` - array reference
- `'HASH'` - hash reference
- `'CODE'` - subroutine reference
- `''` (empty string) - not a reference

### Signal Handlers

**Rule:** Set up signal handlers at package/file scope level.

```perl
$SIG{PIPE} = sub {
    print "SIG PIPE\n";
    return;
};

my $childcount = 0;
$SIG{CHLD} = \&REAPER;
sub REAPER {
    my $stiff;
    while(($stiff = waitpid(-1, &WNOHANG)) > 0) {
        $childcount--;
    }
    $SIG{CHLD} = \&REAPER; # Reinstall after calling waitpid
    return;
}
```

**Pattern for temporary signal handlers:**
```perl
sub write($self, $ofh, @parts) {
    my $brokenpipe = 0;
    local $SIG{PIPE} = sub { $brokenpipe = 1;};

    # ... code that might trigger SIGPIPE ...

    return;
}
```

### Global Package Variables with BEGIN Blocks

**Rule:** Initialize package-scoped globals in BEGIN blocks.

```perl
my $globalmemh;
my $globaldbh;
my $is_init;
my $isDebugging;

BEGIN {
    $is_init = 0;
    $isDebugging = 0;
}
```

**Why:** Ensures variables are initialized at compile time before any other code runs.

### Local Scope Manipulation

**Rule:** Use `local` to temporarily modify global or package variables.

```perl
local $INPUT_RECORD_SEPARATOR = undef;  # Slurp mode
binmode($ofh, ':bytes');

local $SIG{PIPE} = sub { $brokenpipe = 1;};  # Temporary signal handler
```

**Common uses:**
- `local $INPUT_RECORD_SEPARATOR` (or `$/`) for slurp mode
- `local $OUTPUT_AUTOFLUSH` (or `$|`) for autoflush
- `local $SIG{...}` for temporary signal handlers

### Environment Variables

**Rule:** Check environment variables with `defined()` before using.

```perl
if(defined($ENV{PC_LOCALHOSTONLY}) && $ENV{PC_LOCALHOSTONLY}) {
    print "   PC_LOCALHOSTONLY mode active\n";
    # Modify behavior
}

if(defined($ENV{PC_LINUXUSER})) {
    my $fname = '/home/' . $ENV{PC_LINUXUSER} . '/versions.txt';
    # ...
}
```

**Pattern:**
- Always check `defined($ENV{VAR_NAME})` first
- Then check truthiness if needed
- Use for configuration and runtime behavior changes

### Heredoc Syntax

**Rule:** Use `<<~'MARKER'` for indented heredocs that preserve formatting.

```perl
my $basecode = <<~'ENDJSBASECODE';
    // START JavaScript.pm
    var memory = new Object;
    function __encode(obj) {
        return JSON.stringify(obj);
    }
    // END JavaScript.pm
    ENDJSBASECODE
```

**Syntax variants:**
- `<<'MARKER'` - Single-quoted (no interpolation)
- `<<"MARKER"` - Double-quoted (with interpolation)
- `<<~'MARKER'` - Indented heredoc (removes leading whitespace)

### Retry Patterns with Sleep

**Rule:** Use retry loops with exponential or fixed backoff for transient failures.

```perl
my $retrycount = $RETRY_COUNT;
my $ok = 0;
while($retrycount) {
    if($sth->execute($param)) {
        $ok = 1;
        last;
    }

    $dbh->rollback();
    $retrycount--;

    if($retrycount) {
        sleep($RETRY_WAIT);  # Or: sleep((rand(30) / 100) + 0.02);
    }
}

if(!$ok) {
    return 0;
}
```

**Use cases:**
- Database concurrency issues
- Network operations
- Resource contention

### File and Directory Operations

**File Permissions:**
```perl
if(!-d '/run/lock/pagecamel') {
    mkdir '/run/lock/pagecamel';
    chmod 0755, '/run/lock/pagecamel';
}
```

**Lock Files:**
```perl
my $weblockname = "/run/lock/pagecamel_" . $ps_appname . ".lock";

if(-f $weblockname) {
    carp("LOCKFILE $weblockname ALREADY EXISTS!");
    unlink $weblockname;
}
```

**Directory Traversal:**
```perl
opendir(my $dfh, $basedir) or croak("$ERRNO");
while((my $fname = readdir($dfh))) {
    next if($fname =~ /^\./);  # Skip hidden files
    my $nfname = $basedir . "/" . $fname;
    if(-d $nfname) {
        # Recursive call for subdirectories
        $fcount += $self->load_dir($nfname);
        next;
    }
    # Process file
}
closedir($dfh);
```

### Binmode Usage

**Rule:** Use `binmode` for binary file handles and to set encoding layers.

```perl
binmode($ofh, ':bytes');  # Binary mode, no encoding
binmode($fh, ':utf8');    # UTF-8 encoding layer
```

**Common patterns:**
- `:bytes` - Binary data, no character encoding
- `:utf8` - UTF-8 encoding (use with caution, prefer encode_utf8/decode_utf8)
- `:raw` - Unbuffered binary

### Module Exports

**Rule:** Use `@EXPORT` for automatic exports, `@EXPORT_OK` for optional exports.

```perl
use base qw(Exporter);
our @EXPORT = qw(tr_init tr_reload); ## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT_OK = qw(arraytohashkeys hashcountfromarray);
```

**Best practices:**
- Use `@EXPORT` sparingly (requires Perl Critic annotation)
- Prefer `@EXPORT_OK` for most functions
- Document exported functions in POD

### Default Parameter Values

**Rule:** Use defined checks and assignment for default values in function signatures.

```perl
sub blobWrite($self, $data, $offset = 0) {
    # $offset defaults to 0 if not provided
}

sub blobRead($self, $data, $offset = 0, $len = undef) {
    if(!defined($len)) {
        $len = $self->{datalength} - $offset;
    }
}

sub new($class, $dbh, $datablobid = undef, $metaonly = undef) {
    if(!defined($metaonly) && !defined($datablobid)) {
        $metaonly = 0;
    }
}
```

### Perl Critic Annotations

**Rule:** Use inline `## no critic` annotations to suppress specific warnings.

**On constants:**
```perl
Readonly::Scalar my $BLOBMODE => 0x00020000; ## no critic (ValuesAndExpressions::RequireNumberSeparators)
```

**On exports:**
```perl
our @EXPORT = qw(function1 function2); ## no critic (Modules::ProhibitAutomaticExportation)
```

**On code blocks:**
```perl
eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    attempt_something();
};
```

**On specific constructs:**
```perl
if($!{EWOULDBLOCK} || $!{EAGAIN}) { ## no critic (Variables::ProhibitPunctuationVars)
    # Handle would-block condition
}
```

**On symbolic references (rare):**
```perl
no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
# Code that needs symbolic references
use strict 'refs';
```

### Return Patterns

**Procedure return (no value):**
```perl
sub reload($self) {
    # Nothing to do
    return;  # Explicit return with no value
}
```

**Early return guards:**
```perl
sub get($self, $key) {
    return unless(defined($key));
    return unless(defined($self->{$key}));
    return $self->{$key};
}
```

**Multiple return values:**
```perl
sub get($self, $modulename, $settingname) {
    # ... fetch data ...
    if(defined($settingref)) {
        return (1, $settingref);  # Success with data
    } else {
        return 0;  # Failure
    }
}

# Usage:
my ($ok, $data) = $self->get($mod, $setting);
if($ok) {
    # Use $data
}
```

### Copyright and Licensing Placement

**Rule:** Copyright notices can appear before or after the package declaration, and before or after the AUTOPRAGMA block.

**Pattern 1 (Before package):**
```perl
# PAGECAMEL  (C) 2008-2020 Rene Schickbauer
# Developed under Artistic license
package PageCamel::Web::DynDNS;
#---AUTOPRAGMASTART---
...
```

**Pattern 2 (After AUTOPRAGMA):**
```perl
package PageCamel::SVC::Settings;
#---AUTOPRAGMASTART---
...
#---AUTOPRAGMAEND---
# PAGECAMEL  (C) 2008-2020 Rene Schickbauer
# Developed under Artistic license
```

**Consistency:** Be consistent within a subsystem, but variation across the codebase is acceptable.

---

## Summary Checklist

### For Every File:
- [ ] Starts with shebang (for .pl files) or package declaration (for .pm files)
- [ ] Contains complete AUTOPRAGMA block
- [ ] Uses 4 spaces for indentation (never tabs)
- [ ] No space after control keywords: `if(`, `while(`, `for(`
- [ ] Cuddled else: `} else {`
- [ ] Variable and function names use camelCase (first letter lowercase)
- [ ] No underscores in variable/function names (except private functions with leading `_`)
- [ ] Error handling uses `croak()` with quoted strings
- [ ] Functions use modern signatures with `$self` for methods
- [ ] Explicit `return` statements
- [ ] Ends with `1;` and `__END__` (for .pm files)
- [ ] Includes POD documentation after `__END__`
- [ ] Uses English module variables (`$ERRNO` not `$!`, `$EVAL_ERROR` not `$@`)
- [ ] Large numbers formatted with underscores: `1_000` not `1000`

### Code Quality:
- [ ] Database operations use `prepare_cached` with placeholders
- [ ] `prepare()` and `prepare_cached()` use `or croak()` for error handling
- [ ] `or croak()` after `prepare()` or `prepare_cached()` is indented one additional level (4 more spaces)
- [ ] `execute()` uses proper error handling: `if(!$sth->execute()) { $reph->debuglog($dbh->errstr); $dbh->rollback; ... }`
- [ ] Database errors are logged with `$reph->debuglog()` before rollback
- [ ] eval blocks use success flag pattern
- [ ] Transactions properly committed or rolled back
- [ ] No undefined variable warnings (always initialize variables)

---

## Tools and Scripts

The framework includes several helper scripts in `devscripts/`:

- **tabs2spaces.pl**: Converts tabs to 4 spaces
- **fixcroak.pl**: Ensures croak calls use proper quoting
- **stylecorrect.pl**: (Note: Has issues, marked "don't use")
- **setversion.pl**: Updates VERSION numbers
- **fixpragmas.pl**: Updates AUTOPRAGMA blocks

Use these tools to maintain consistency across the codebase.

---

## Examples from Codebase

### Example: Simple Helper Module

```perl
package PageCamel::Helpers::NeatLittleHelpers;
#---AUTOPRAGMASTART---
use v5.40;
use strict;
use diagnostics;
use mro 'c3';
use English;
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 4.8;
use autodie qw( close );
use Array::Contains;
use utf8;
use Data::Dumper;
use Data::Printer;
#---AUTOPRAGMAEND---

use base qw(Exporter);
our @EXPORT_OK = qw(arraytohashkeys hashcountfromarray);

sub arraytohashkeys(@in) {
    my %out = map {$_=>1} @in;

    return %out;
}

sub hashcountfromarray(@in) {
    my %out;
    $out{$_}++ for (@in);

    return %out;
}

1;
__END__

=head1 NAME

PageCamel::Helpers::NeatLittleHelpers - various helpers

=head1 SYNOPSIS

  use PageCamel::Helpers::NeatLittleHelpers;

=head1 DESCRIPTION

This module holds a mishmash of functions.

=head2 arraytohashkeys

Get a hash with all unique elements of an array.

=head2 hashcountfromarray

Get the counts of each unique element in an array as hash.

=cut
```

### Example: Using Large Numbers with Underscores

```perl
sub configure_limits($self) {
    # Large numbers are split into groups of three digits
    my $max_connections = 10_000;
    my $buffer_size = 1_048_576;  # 1 MB in bytes
    my $timeout_ms = 300_000;      # 5 minutes in milliseconds
    my $max_file_size = 100_000_000;  # 100 MB

    $self->{limits} = {
        connections => $max_connections,
        buffer => $buffer_size,
        timeout => $timeout_ms,
        filesize => $max_file_size,
    };

    return;
}
```

### Example: File Operations with English Variables

```perl
sub process_file($filename) {
    # Using $ERRNO instead of $!
    open(my $fh, '<', $filename) or croak("Cannot open $filename: $ERRNO");
    my @lines = <$fh>;
    close $fh;

    return @lines;
}

sub find_files($workDir) {
    my @files;

    # Using $ERRNO instead of $!
    opendir(my $dfh, $workDir) or die("Cannot open directory $workDir: $ERRNO");

    while((my $fname = readdir($dfh))) {
        next if($fname eq "." || $fname eq "..");
        $fname = $workDir . "/" . $fname;

        if(-d $fname) {
            push @files, find_files($fname);
        } elsif($fname =~ /\.pm$/i && -f $fname) {
            push @files, $fname;
        }
    }
    closedir($dfh);

    return @files;
}
```

### Example: Database Module Pattern with Proper Error Handling

```perl
sub getColumnType($self, $xtable, $xcolumn) {
    my $table = '' . $xtable;
    my $column = '' . $xcolumn;

    $self->checkDBH();

    my $schema = 'public';
    if($table =~ /\./) {
        ($schema, $table) = split/\./, $table;
    }

    # Note the additional indentation for 'or croak' after prepare_cached
    my $sth = $self->{mdbh}->prepare_cached("SELECT pg_catalog.format_type(c.atttypid, NULL) AS data_type
                                                FROM pg_attribute c
                                                  JOIN pg_class t on c.attrelid = t.oid
                                                  JOIN pg_namespace n on t.relnamespace = n.oid
                                                WHERE
                                                  n.nspname = ?
                                                  AND t.relname = ?
                                                  AND c.attname = ?
                                                  AND c.attnum >= 0")
            or croak($self->{mdbh}->errstr);

    # Proper error handling for execute()
    if(!$sth->execute($schema, $table, $column)) {
        $self->{reph}->debuglog($self->{mdbh}->errstr);
        $self->{mdbh}->rollback;
        return;
    }

    my $type;
    while((my $line = $sth->fetchrow_hashref)) {
        $type = lc $line->{data_type};
    }
    $sth->finish;

    $self->{mdbh}->commit;

    return $type;
}
```

### Example: Login/Authentication Pattern

```perl
sub verify_user($self, $username, $password) {
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $reph = $self->{server}->{modules}->{$self->{reporting}};

    my $selsth = $dbh->prepare_cached("SELECT * FROM users
                                        WHERE username = ?
                                        LIMIT 1")
            or croak($dbh->errstr);

    if(!$selsth->execute($username)) {
        $reph->debuglog($dbh->errstr);
        $dbh->rollback;
        return (status => 500);
    }

    my $user = $selsth->fetchrow_hashref;
    $selsth->finish;

    if(!defined($user)) {
        $dbh->rollback;
        return (status => 404);  # User not found
    }

    $dbh->commit;
    return (status => 200, user => $user);
}
```

---

## Version History

- **4.8**: Current version (as of analysis date)
- Framework uses Perl 5.40 features

---

**End of Style Guide**

This document is intended for both human developers and AI tools (like Claude Code, GitHub Copilot, ChatGPT, etc.) to understand and maintain consistent code style across the PageCamel framework.
