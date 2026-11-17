---
name: getty-perl-moose
description: "Use when writing classes or roles in a Moose distribution — `use Moose`, `use Moose::Role`, attributes, modifiers, immutability."
---

# Perl/Moose — House Rules and Patterns

Inheritance sparingly (stable "is-a" contracts), roles heavily — when in doubt, a role.
Base rules: `getty-perl-core`.

## House conventions

```perl
package My::Document;
use Moose;
use namespace::autoclean;                  # or `no Moose;` above make_immutable
use Path::Tiny;

extends 'My::Base';
with 'My::Role::Printable', 'My::Role::Serializable';

has title => ( is => 'ro', required => 1 );

sub to_string { ... }

__PACKAGE__->meta->make_immutable;
```

- **Every class ends with `__PACKAGE__->meta->make_immutable;`** — without it every `new` is slow; after it no `add_attribute`/`add_role`.
- **`use namespace::autoclean;`** (or `no Moose;`) in every class — keeps `has`/`with`/`extends` and imports from becoming methods. A class extending DBIx::Class (`MooseX::NonMoose`) uses `use MooseX::MarkAsMethods autoclean => 1;` instead — more in skill `getty-perl-core`, `references/dbic.md`.
- **File order:** `use` lines → `extends` / `with` → `has` → methods → `make_immutable`. Exception: when a role `requires` an accessor that a `has` generates, that `has` goes above the `with` — `requires` is checked the moment `with` runs.
- **`is => 'ro'` is the default**; `rw` needs a reason.
- **`lazy_build => 1` + `sub _build_x`** for anything non-trivial (or `lazy => 1, builder => '_build_x'`); never `default => sub {...}`. `is => 'lazy'` is Moo — Moose rejects it.
- **Reference defaults are coderefs:** `default => sub { [] }` — `default => []` is shared state.
- **Types:** `Types::Standard` in new code (`use Types::Standard qw( Enum Str );`, `isa => Enum[qw( pending running done )]`) — unless the dist already uses string types (`isa => 'Str'`): then strings, never both. `MooseX::Types` is superseded — don't add it. Whether and where to type: `getty-perl-typing`.
- **Repeated attribute shapes get a generator** — env-var config (see core) as `has_conf`:

```perl
sub has_conf {
  my ( $name, $env_key, $default ) = @_;
  has $name => (
    is      => 'ro',
    lazy    => 1,
    default => sub { defined $ENV{$env_key} ? $ENV{$env_key} : ( ref $default eq 'CODE' ? $default->(@_) : $default ) },
  );
}

has_conf time_zone => MYAPP_TIME_ZONE => 'Europe/Berlin';
```

## Inheritance

```perl
extends 'Vehicle';                         # one call: extends 'A', 'B' — a second extends REPLACES
has '+color' => ( default => 'silver' );   # override an inherited attribute, never redeclare it
```

- Never narrow an inherited attribute's `isa` in a subclass. Diamonds resolve by C3 MRO.
- **`augment`/`inner`** — only when the parent owns the frame and children fill the content: the parent's `render` calls `inner()`, the child writes `augment 'render' => sub {...}`.

## Roles

- **All roles in one `with` call** — separate `with` lines skip conflict detection. `requires` fails at composition, loud and early.
- **Conflicts are fatal**, never silently resolved. A method defined in the class wins; or alias and exclude:
  `with 'RoleA' => { -alias => { foo => 'foo_a' }, -excludes => 'foo' }, 'RoleB';`
- A role may `with` other roles (a bundle). `excludes 'OtherRole';` in a role forbids composing both — sparingly.
- **Per instance:** `Moose::Util::apply_all_roles( $obj, 'Role::Debug' )` reblesses into an anon subclass — plugin systems, decoration; required attributes must already exist.
- **Parameterized:** `MooseX::Role::Parameterized` (non-core dependency); inside `role { }` use `method`, not `sub`:

```perl
package Role::Counter;
use MooseX::Role::Parameterized;
parameter name => ( isa => 'Str', required => 1 );
role {
  my $p = shift;
  my $n = $p->name;
  has $n => ( is => 'rw', isa => 'Int', default => 0 );
  method "inc_$n" => sub { my $self = shift; $self->$n( $self->$n + 1 ) };
};
# consumer: with 'Role::Counter' => { name => 'power' };   → power + inc_power
```

## Attributes and delegation

- **`trigger => sub { my ( $self, $new, $old ) = @_; ... }`** — fires on `new()` and set; `$old` is undef on construction (Moo passes no old value).
- `init_arg => 'secret'` renames the constructor key; `init_arg => undef` forbids it.
- **`coerce => 1` only on your own subtypes**, never on a built-in type name — `Moose::Util::TypeConstraints` names are global, so a coercion there changes the whole program.

```perl
has tasks => (
  traits  => ['Array'],                     # also Hash, Bool, String, Number, Counter, Code
  is      => 'ro',
  default => sub { [] },
  handles => { add_task => 'push', next_task => 'shift', all_tasks => 'elements', task_count => 'count' },
);
has uri => (
  is      => 'ro',
  handles => [qw( host path )],             # or { hostname => 'host' }, or 'Role::URILike'
);
```

## Modifiers

`before`/`after` cannot change the return value; `around` can and must forward `@_`:
`around calculate => sub { my ( $orig, $self, @args ) = @_; return $self->$orig(@args) * 2 };`
Order: `before` (LIFO), `around` (LIFO, wrapping), original, `after` (FIFO); modifiers from several roles stack in composition order.

## Lifecycle

- **Never define `sub new`.** `around BUILDARGS` (class method, returns a hashref) normalizes arguments:

```perl
around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  return $class->$orig( id => $args[0] ) if @args == 1 && !ref $args[0];
  return $class->$orig(@args);
};
```

- **`BUILD`** runs after construction, parent→child, automatically — never call `SUPER::BUILD`. Cleanup in `DEMOLISH` (child→parent); never override `DESTROY`.

## MooseX

`MooseX::StrictConstructor` (dies on unknown constructor args) · `MooseX::ClassAttribute` (class-level attributes) · `MooseX::Singleton` (`->instance`) · `MooseX::Getopt` (CLI options from attributes) · `MooseX::Storage` (serialization).
