# Problem 49: Parent Runtime Environment Loads After Project `.env.pl`

Ticket: DKT-009

## Problem

A project `.env.pl` may use a variable defined in the user's
`~/.developer-dashboard/.env`, but the variable is undefined when that script
runs. For example, a project script that calls `opendir` using
`$ENV{DIR_D2D_SRC}` fails even though the home runtime `.env` defines it.

## Expected Behaviour

Environment files load in parent-to-child order. At each directory, plain
`.env` and `.env.pl` files load before runtime files beneath that directory;
then the loader proceeds to deeper directories. Later child values override
parent values. Explicitly inherited shell variables remain protected.

## Root Cause

`EnvLoader::load_runtime_layers` previously queued every plain-directory file
before every `.developer-dashboard` and `.d2` runtime file. This caused the
project-root `.env.pl` to execute before the home runtime `.env`, contrary to
the DD-OOP-LAYERS parent-to-child contract.

## Reproduction

1. Set `DIR_D2D_SRC=/some/source` in `~/.developer-dashboard/.env`.
2. Put `opendir(my $dir, $ENV{DIR_D2D_SRC})` in the project-root `.env.pl`.
3. Run any `d2` command from that project.
4. Before the fix, `.env.pl` sees an undefined `DIR_D2D_SRC`; after the fix,
   it sees `/some/source` and opens that directory.

The hermetic regression tests reproduce this with temporary home, runtime, and
project directories, without reading or modifying a user's real configuration.

## Fix and Verification

Runtime env files are now interleaved with plain directory files by ancestry:
unmatched inherited runtime roots first, then each plain directory followed by
its runtime roots, preserving sibling and alias order. Tests cover loader file
order and a public CLI run where project `.env.pl` reads a home runtime value.
