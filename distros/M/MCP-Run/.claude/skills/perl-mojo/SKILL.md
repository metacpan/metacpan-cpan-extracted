---
name: Perl Mojo
description: Mojo::Base object system and the Mojolicious toolkit - attributes, defaults, roles, and the core Mojo::* helpers
trigger: when working with Mojo::Base, Mojolicious, Mojo::UserAgent, Mojo::IOLoop, or perl-mojo
category: language
---

# Perl/Mojo – Object System & Toolkit

## Core Principle
`Mojo::Base` is a **complete object system in one import**: strict/warnings/utf8, the
current feature bundle, attributes, and inheritance. Reach for it whenever the
surrounding code already lives in Mojo-land — mixing object systems inside one
distribution costs more than it buys.

All behaviour below is verified against the installed Mojolicious, not quoted from memory.

---

## Pattern 1 – Class, subclass, role

```perl
package App::Base;
use Mojo::Base -base, -signatures;        # standalone class

package App::Child;
use Mojo::Base 'App::Base', -signatures;  # subclass: parent name replaces -base

package App::Role::Loud;
use Mojo::Base -role, -signatures;        # role (Role::Tiny under the hood)
requires 'name';
sub shout ($self) { uc $self->name }

package main;
use Mojo::Base -strict;                   # scripts: strict/warnings/utf8/features, no OO
```

**Rules:** The first argument picks the mode — `-base`, a parent class name, `-role`,
or `-strict`. Add `-signatures` for subroutine signatures, `-async_await` for
`async`/`await`.

---

## Pattern 2 – Attributes

```perl
package App::Server;
use Mojo::Base -base, -signatures;

has name    => 'PerlServer';        # static default, shared value
has port    => 8080;
has debug   => 0;                   # falsy defaults are kept as-is
has clients => sub { [] };          # coderef: fresh per instance
has ua      => sub { Mojo::UserAgent->new };
```

**Rules:** A **coderef default is evaluated lazily** — on first read of the accessor,
once per instance, then cached in the object. Anything mutable (arrayref, hashref,
object) must be a coderef, otherwise every instance shares one value. Attribute names
must match `/^[a-zA-Z_]\w*$/`.

`App::Server->attr(added => 'later')` adds an attribute at runtime, which is how
plugins extend a class they do not own.

---

## Pattern 3 – Overriding an inherited default

```perl
package MCP::Server;
use Mojo::Base -base, -signatures;
has name    => 'PerlServer';
has version => '1.0.0';

package MCP::Run::Bash;
use Mojo::Base 'MCP::Server', -signatures;
our $VERSION = '0.106';
has name    => 'mcp-run-bash';      # re-declare: overrides the parent default
has version => $VERSION;
```

**Rules:** Redeclaring `has` in the subclass is the override — it installs a fresh
accessor in the child package. Explicit constructor arguments still win over any
default, so `MCP::Run::Bash->new(name => 'other')` reports `other`. Put identity
defaults on the **class**, not in the `bin/` script that happens to launch it, so
library users inherit them too.

---

## Pattern 4 – Chainable accessors

```perl
my $server = App::Server->new;
$server->name('api')->port(9090)->debug(1);   # setters return the invocant
my $name = $server->name;                      # getter returns the value

App::Server->new(name => 'a');                 # hash
App::Server->new({name => 'a'});               # hashref — both accepted
```

**Rules:** Every setter returns `$self`, so calls chain. `->tap(sub { ... })` runs a
side effect mid-chain and returns the invocant: `$obj->tap(sub { $_[0]->name('x') })`.

---

## Pattern 5 – Composing roles

```perl
package App::Quiet;
use Mojo::Base -base, -signatures;
has name => 'quiet';

package main;
my $loud = App::Quiet->with_roles('App::Role::Loud')->new;
say $loud->shout;                              # QUIET
```

**Rules:** `with_roles` builds (and caches) a new class with the roles applied and
returns its name — compose first, construct second. A leading `+` in the role name
expands to the invocant's namespace: `App::Quiet->with_roles('+Loud')` means
`App::Quiet::Role::Loud`. Roles can also be applied to a single object with
`$obj->with_roles(...)`. `requires 'name'` in the role is checked at composition time.

---

## Pattern 6 – Lazy construction of expensive members

```perl
package App::Pipeline;
use Mojo::Base -base, -signatures;
has filters => sub { shift->_build_filters };  # built on first use, then cached
```

**Rules:** Lazy defaults defer **construction**, not **loading** — the class you
construct still has to be `use`d at compile time. Load the module with a plain `use`
at the top and keep the coderef for the expensive part; that way a missing or broken
dependency stops the process at startup rather than on a user's first request.

---

## Toolkit – the parts worth knowing

```perl
use Mojo::JSON qw(encode_json decode_json true false);
encode_json {ok => true, no => false};         # {"no":false,"ok":true}
decode_json('{"n":1}')->{n};                   # 1

use Mojo::File qw(path);
path('/tmp/a/b.txt')->basename;                # b.txt
path('/tmp/x')->spurt($data);                  # write
path('/tmp/x')->slurp;                         # read
path('/tmp')->list_tree->each(sub { ... });    # walk

use Mojo::Collection qw(c);
c(1,2,3,4)->grep(sub { $_ % 2 })->map(sub { $_ * 10 })->join('|');   # 10|30
c(3,1,2)->sort->first;                          # 1

use Mojo::Util qw(trim dumper b64_encode encode decode);
trim("  x  ");                                  # x
print dumper $ref;                              # debugging dump
```

**Rules:** `Mojo::JSON`'s `true`/`false` survive a decode/encode roundtrip as real JSON
booleans — plain `1`/`0` do not. `Mojo::Collection` methods return collections, so they
chain; `->each`/`->join`/`->first` leave the chain.

---

## Async

```perl
use Mojo::Base -strict, -signatures, -async_await;   # -signatures is its own flag
use Mojo::Promise;

async sub fetch ($url) {
  my $tx = await $ua->get_p($url);
  return $tx->result->json;
}

Mojo::Promise->all(map { fetch($_) } @urls)->then(sub (@results) { ... })->wait;
```

**Rules:** `-async_await` enables `async`/`await` only — a signatured `async sub` also
needs `-signatures` in the same import. `->wait` drives the event loop until settled and
belongs at the top level, never inside a running loop. `all` hands its callback **one
arrayref per input promise** (`[$first], [$second], ...`), preserving input order.
`Mojo::IOLoop->timer`/`->recurring` schedule work; `Mojo::IOLoop->start` runs the loop
unless one is already running.

---

## Conventions

- **POD attributes** documented as `=attr`, methods as `=method` — matching whatever the
  distribution's release bundle expects.
- **`$VERSION` before `has`.** `our $VERSION` is assigned at compile time near the top of
  the file, so `has version => $VERSION;` further down sees the value in both a checkout
  and a built distribution.
- **One object system per distribution.** If the base class is `Mojo::Base`, subclasses
  stay `Mojo::Base`.
