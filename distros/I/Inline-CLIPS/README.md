# Inline-CLIPS

A Perl module distribution that provides:

- `Inline::CLIPS`: a Perl interface for running CLIPS programs.
- `Alien::CLIPS`: an Alien module that uses `Alien::Build` to find a system
  CLIPS installation or build one from
  <https://github.com/jtrujil43/FuzzyCLIPS>.

## Install

```bash
perl Makefile.PL
make
make test
```

## Usage

```perl
use Inline::CLIPS;

my $clips = Inline::CLIPS->new;
my $result = $clips->run_program(q{
  (deftemplate animal (slot name) (slot class))
  (deffacts seed (animal (name "penguin") (class bird)))
  (defrule describe
    (animal (name ?n) (class ?c))
    =>
    (printout t ?n " is a " ?c crlf))
}, '(run)');
```

## Examples

- `examples/process-flow-check.pl`: process-flow-check inspired rule flow.
- `examples/airbp-animals.pl`: a simpler AIRBP-style animal classification
  example.
