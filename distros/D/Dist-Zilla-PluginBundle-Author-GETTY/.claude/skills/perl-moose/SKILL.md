# Perl/Moose – Architecture & Implementation Patterns

## Core Principle
Use **inheritance sparingly** (stable "is-a" contracts), **roles heavily** (horizontal reuse). When in doubt: role, not subclass. Always end classes with `make_immutable`.

---

## Pattern 1 – `extends` + Attribute Override

```perl
package Vehicle;
use Moose;
use namespace::autoclean;
has color => (is => 'ro', default => 'black');
__PACKAGE__->meta->make_immutable;

package Spaceship;
use Moose;
use namespace::autoclean;
extends 'Vehicle';
has '+color' => (default => 'silver');   # override via +attr
__PACKAGE__->meta->make_immutable;
```

**Rules:**
- Multiple `extends` calls REPLACE (don't add) — always `extends 'A', 'B'` in one call.
- Override inherited attributes with `has '+name' => (...)` — don't redefine from scratch.
- Never override `isa` type in a subclass (global side effects).
- Moose uses C3 linearization for diamond inheritance — deterministic MRO.

---

## Pattern 2 – Role with `requires`

```perl
package Role::Printable;
use Moose::Role;
requires 'to_string';                    # contract: consumer must implement this
sub print_self { print $_[0]->to_string, "\n" }

package Document;
use Moose;
use namespace::autoclean;
with 'Role::Printable';
sub to_string { "Document: " . $_[0]->title }
has title => (is => 'ro', required => 1);
__PACKAGE__->meta->make_immutable;
```

**Rules:**
- `requires` fails at composition time, not runtime — loud and early.
- Always compose all roles **in one `with` call** — separate `with` calls skip conflict detection.
- `with` must come **after** all `has` declarations the role might need.
- `excludes => 'OtherRole'` prevents composing two incompatible roles — use sparingly.

---

## Pattern 3 – Role Conflict Resolution

```perl
# Both roles define foo() → conflict → class must resolve it
package MyClass;
use Moose;
use namespace::autoclean;
with 'RoleA', 'RoleB';       # dies if both define foo() without resolution
sub foo { ... }               # class defines foo → wins, resolves conflict

# Alternative: alias + exclude
with 'RoleA' => { -alias => { foo => 'foo_a' }, -excludes => 'foo' },
     'RoleB';                 # RoleB's foo wins; RoleA's available as foo_a
__PACKAGE__->meta->make_immutable;
```

**Rules:** Moose does NOT silently pick a winner — conflicts are fatal. Class-defined method always wins over roles.

---

## Pattern 4 – Roles in Roles (Bundles)

```perl
package Role::Bundle;
use Moose::Role;
with 'Role::Printable', 'Role::Serializable';   # bundle multiple roles
```

Composing `Role::Bundle` into a class pulls in both sub-roles. Good for grouping related capabilities.

---

## Pattern 5 – Dynamic Role Application

```perl
use Moose::Util 'apply_all_roles';
my $obj = MyClass->new;
apply_all_roles($obj, 'Role::Debug');    # reblesses into anon subclass
```

Use for plugin systems or per-instance decoration. Required role attributes must already be present.

---

## Pattern 6 – Parameterized Roles (MooseX::Role::Parameterized)

```perl
package Role::Counter;
use MooseX::Role::Parameterized;
parameter name => (isa => 'Str', required => 1);
role {
    my $p = shift;
    my $n = $p->name;
    has $n => (is => 'rw', isa => 'Int', default => 0);
    method "inc_$n" => sub { my $self = shift; $self->$n($self->$n + 1) };
};

package Game::Weapon;
use Moose;
use namespace::autoclean;
with 'Role::Counter' => { name => 'power' };
__PACKAGE__->meta->make_immutable;
# generates: power attribute + inc_power method
```

Use `method` (not `sub`) inside `role { }` block. Non-core — adds `MooseX::Role::Parameterized` dependency.

---

## Pattern 7 – Attribute Options Cheatsheet

```perl
has name    => (is => 'ro',   required => 1);
has tags    => (is => 'ro',   isa => 'ArrayRef[Str]', default => sub { [] });  # ALWAYS coderef for refs
has content => (is => 'lazy');                     # built on first access
sub _build_content { "generated: " . $_[0]->name }

has status  => (
    is      => 'rw',
    isa     => 'Str',
    trigger => sub {                               # fires on new() and set
        my ($self, $new, $old) = @_;              # $old is undef on construction
        die "bad status" unless $new =~ /\A(new|ok|done)\z/;
    },
);

has _secret => (is => 'ro', init_arg => 'secret'); # constructor uses 'secret', stored as _secret
has size    => (
    is     => 'ro',
    isa    => 'Int',
    coerce => 1,                                   # requires subtype with coercion defined
);
```

**Rules:**
- `default => []` → **shared state bug**. Always `default => sub { [] }`.
- Prefer `builder` over `default` for complex initialization — builders are inheritable and overridable.
- `trigger` receives `($self, $new_val, $old_val)` — unlike Moo, old value IS passed.
- `coerce` only on your own subtypes, never on built-in type names (global side effects).
- `is => 'lazy'` requires a `_build_name` method or explicit `builder`.

---

## Pattern 8 – Native Traits Delegation

```perl
package TaskList;
use Moose;
use namespace::autoclean;

has tasks => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Task]',
    default => sub { [] },
    handles => {
        add_task  => 'push',
        next_task => 'shift',
        all_tasks => 'elements',
        task_count => 'count',
        find_task  => 'first',
    },
);
__PACKAGE__->meta->make_immutable;
```

Available native traits: `Array`, `Hash`, `Bool`, `String`, `Number`, `Counter`, `Code`. Each provides a set of generated methods. See `Moose::Meta::Attribute::Native::Trait::*` on CPAN.

---

## Pattern 9 – `handles` Delegation to Objects

```perl
package Website;
use Moose;
use namespace::autoclean;
has uri => (
    is      => 'ro',
    isa     => 'URI',
    handles => [qw(host path)],            # list form
    # OR: handles => { hostname => 'host' }  # rename form
    # OR: handles => 'Role::URILike',         # delegate interface from role
);
__PACKAGE__->meta->make_immutable;
# $site->host() calls $site->uri->host() internally
```

---

## Pattern 10 – Method Modifiers

```perl
before 'save' => sub {
    my $self = shift;
    die "read-only mode" if $self->readonly;     # validate; cannot change return value
};

after 'save' => sub {
    my ($self, @args) = @_;
    $self->log("saved");                         # side effects; cannot change return value
};

around 'calculate' => sub {
    my ($orig, $self, $x) = @_;
    return 0 if $x < 0;
    return $self->$orig($x) * 2;                # CAN change return value
};
```

**Execution order:** `before` (LIFO), then `around` (LIFO, wrapping), then original, then `after` (FIFO).

**Rules:** `before`/`after` cannot alter return value; `around` can. Always capture and forward `@_` correctly in `around`. Multiple modifiers from multiple roles stack in composition order.

---

## Pattern 11 – `augment` / `inner` (Inverted Inheritance)

```perl
package Report;
use Moose;
use namespace::autoclean;
sub render {
    my $self = shift;
    "<html>" . inner() . "</html>";    # inner() calls augment from child
}
__PACKAGE__->meta->make_immutable;

package PDFReport;
use Moose;
use namespace::autoclean;
extends 'Report';
augment 'render' => sub {
    my $self = shift;
    "<pdf>" . inner() . "</pdf>";     # chain further down if needed
};
__PACKAGE__->meta->make_immutable;
```

Use when the parent defines the *frame* and children fill in the *content*. Rare — only when the parent controls the wrapper structure.

---

## Pattern 12 – Constructor Lifecycle

```perl
around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    # normalize: allow single string arg
    return $class->$orig(id => $args[0]) if @args == 1 && !ref $args[0];
    $class->$orig(@args);
};

sub BUILD {
    my ($self, $args) = @_;     # called AFTER all attributes are set
    die "SSN required for US" if $self->country eq 'USA' && !$self->ssn;
    # don't call SUPER::BUILD — Moose handles the chain (parent→child order)
}
```

**Rules:**
- Never define `sub new` — use `BUILDARGS`/`BUILD` instead.
- `BUILDARGS`: class method, runs before construction, returns hashref.
- `BUILD`: object method, runs after construction. Moose calls all `BUILD` in the hierarchy automatically.
- Never call `SUPER::BUILD` manually.
- For cleanup: use `DEMOLISH` (child→parent order), never override `DESTROY`.

---

## Pattern 13 – `make_immutable` + `namespace::autoclean`

```perl
package MyClass;
use Moose;
use namespace::autoclean;          # remove imported keywords after compile

has name => (is => 'ro', required => 1);

__PACKAGE__->meta->make_immutable; # ALWAYS — massive perf gain on object creation
```

**Rules:**
- `namespace::autoclean` goes at the top (after `use Moose`), `make_immutable` at the bottom.
- After `make_immutable`: no more dynamic `add_attribute`, `add_role` etc.
- `namespace::autoclean` removes `has`, `with`, `extends` etc. from the symbol table — they won't accidentally become methods.

---

## Pattern 14 – Type Constraints

```perl
use Moose::Util::TypeConstraints;

subtype 'PositiveInt',
    as 'Int',
    where { $_ > 0 },
    message { "$_ is not a positive integer" };

coerce 'PositiveInt',
    from 'Str',
    via { int($_) };

# Or use Type::Tiny (recommended — works with both Moo and Moose):
use Types::Standard qw(Str Int ArrayRef InstanceOf);
has name => (is => 'ro', isa => Str);
has items => (is => 'ro', isa => ArrayRef[Str], default => sub { [] });
```

Prefer `Type::Tiny` / `Types::Standard` — portable between Moo and Moose, better error messages.

---

## Decision Guide

| Situation | Use |
|---|---|
| Shared attributes/methods, stable "is-a" | `extends` |
| Optional/horizontal feature | `Moose::Role` + `with` |
| Enforce interface contract | `requires` |
| Same role, different config | `MooseX::Role::Parameterized` |
| Delegate method set to sub-object | `handles` (list/hash/role form) |
| Array/Hash/Counter operations | `traits => ['Array']` + `handles` |
| Logging/validation/caching wrapper | `before`/`around`/`after` |
| Parent defines frame, child fills content | `augment`/`inner` |
| Normalize constructor args | `around BUILDARGS` |
| Post-construction validation/setup | `BUILD` |
| Catch constructor typos | `MooseX::StrictConstructor` |
| Named types with coercion | `Type::Tiny` / `Moose::Util::TypeConstraints` |
| Multiple roles define same method | Resolve in class or `-alias`/`-excludes` |
| Metaclass extensions | `traits` on attributes or class |
| Per-instance behavior change | `Moose::Util::apply_all_roles` |

---

## Common Pitfalls

- `default => []` → **shared state bug**. Always `default => sub { [] }`.
- `extends 'A'; extends 'B'` → replaces, does NOT add. Use `extends 'A', 'B'`.
- Separate `with 'RoleA'; with 'RoleB'` → skips conflict detection. Use one `with`.
- `with` before `has` → `requires` check may fail spuriously. Define `has` first.
- `coerce` on built-in type names → global side effects across the whole program.
- Never define `sub new` — breaks Moose constructor optimization.
- Never call `SUPER::BUILD` manually — Moose handles the chain.
- Never override `DESTROY` — use `DEMOLISH`.
- Forgetting `make_immutable` → significant performance penalty on every `new`.
- `around` without forwarding `@_` correctly → subtle argument loss.

---

## MooseX Extensions (Cheatsheet)

| Module | Purpose |
|---|---|
| `MooseX::StrictConstructor` | Dies on unknown constructor args |
| `MooseX::Role::Parameterized` | Parameterized roles |
| `MooseX::ClassAttribute` | Class-level (shared) attributes |
| `MooseX::Types` | Named type libraries |
| `MooseX::Singleton` | Singleton pattern (`->instance`) |
| `MooseX::Getopt` | Auto CLI options from attributes |
| `MooseX::Storage` | Serialization/deserialization |
