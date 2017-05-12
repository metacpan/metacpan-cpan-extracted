use Test::More tests => 1;
use Inline::YAML;

my @hackers =
---
name: Larry Wall
title: Fearless Leader
hacks: [patch, perl]
---
name: Damian Conway
title: Thunder from Down Under
hacks:
  - Parse::RecDescent
  - Quantum::SuperPositions
---
name: Ingy dot Net
nickname: ingy
hacks:
  - Inline
  - YAML
  - Inline::YAML
...

ok(YAML::XS::Dump(@hackers), <<END);
---
hacks:
  - patch
  - perl
name: Larry Wall
title: Fearless Leader
---
hacks:
  - Parse::RecDescent
  - Quantum::SuperPositions
name: Damian Conway
title: Thunder from Down Under
---
hacks:
  - Inline
  - YAML
  - Inline::YAML
name: Ingy dot Net
nickname: ingy
END
