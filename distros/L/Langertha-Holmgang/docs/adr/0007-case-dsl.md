# ADR 0007 — The case DSL: keywords, generators, discovery

- Status: accepted
- Date: 2026-11-04
- Source: k18; ADR 0004 (one structure, two front ends), ADR 0005 (the structure); suite
  format 2 as specified in cai-platform `docs/entwurf-evals.md` §3.1–3.6
- Tags: dsl, naming, generators, loader

## Context

ADR 0004 adds a Perl DSL next to suite format 2; ADR 0005 fixes the structure both build and
puts the DSL into the main module `Langertha::Holmgang`. What is left is the public syntax:
the keywords, how they nest, which Perl names they must avoid, how generators get a seed,
how plugin device types appear, and where DSL suites live. The implementation is a later
slice on top of the loader (k2); the YAML export is k19.

## Decision

### Shape

- **`use Langertha::Holmgang;` exports the keywords** through `Moose::Exporter` (`as_is`;
  `no Langertha::Holmgang;` removes them). No class is built, so there is no `with_meta`:
  the owner of a keyword is the innermost open `suite` or `case` block, not the caller's
  package. A keyword outside its block, or a single-valued keyword given twice, croaks at
  the line that wrote it.
- **Two kinds of names.** *Declarations* (`suite`, `case`, `title`, `rule`, `device`, …)
  record into the open block and return nothing useful. *Constructors* (`at`, `run`,
  `call`, `file`, `haystack`, `handler`, …) are pure: they return a piece of format 2 data
  and record nothing. A constructor checks its own keys at once, so a typo croaks at its
  line.
- **Every keyword is a format 2 key, or sugar with a format 2 image** (table below). The DSL
  builds the same raw hashes the YAML loader reads and hands them to `Structure` (ADR 0005)
  when the `suite` block closes; then lint runs. There is no second validator and no field
  the loader cannot express — a keyword for a new field arrives in the same slice that
  teaches `Structure` the field.
- **Fixed-arity constructors carry prototypes** — `file($)`, `run($$)`, `put($$$)`,
  `call($$)` — so `system_prompt file 'system.md';` does not swallow what follows, and a
  comma list of unparenthesised calls is a compile error instead of a silent misparse.
  Several calls in one list are written with parentheses: `run( a => 'x' ), run( b => 'y' )`.
- **Rule kinds: first argument is the kind's value, then pairs.** `KIND VALUE, %rest` is
  the format 2 rule `{ KIND => VALUE, %rest }`; `rule TITLE => …` adds the title. The pairs
  are format 2's own: expectations and `required => 0`. Expectations are pair keys
  (`equals`, `in`, `exists`, `length`, `any`, `before` …), which `=>` quotes, so none of
  them is exported. A `regex` may be a `qr//`; it is stored as its string form, which Perl
  reads back as the same pattern.

### The keywords

| Keyword | In | Format 2 |
|---|---|---|
| `suite ID => sub {…}` | file | the suite; `id` (must equal the directory name when loaded from a search directory) |
| `title`, `description`, `version`, `topic`, `license`, `repeat` | suite | the key of the same name |
| `threshold pass_rate => …, pass_k => …` | suite | `threshold` |
| `source title => …, license => …, url => …` | suite, case | `source` |
| `system_prompt TEXT` | suite / case | `defaults.system` / `system` |
| `settings temperature => …, max_tokens => …, max_turns => …` | suite / case | `defaults.*` / the case keys |
| `tool NAME => description => …, parameters => {…}, simulator => … \| handlers => […]` | suite | one entry of `tools` |
| `handler match => …, when => …, apply => […], output => …, error => 1` | constructor | one handler; `apply` operations stay data hashes |
| `case ID => sub {…}` | suite, `generate` | one case; `id` |
| `generate seed => N, sub { my ( $rng ) = @_; … }` | suite | plain cases (below) |
| `title`, `difficulty`, `weight` | case | the key of the same name (`weight`: ADR 0005) |
| `tags LIST` | case | `tags`; repeated calls append |
| `tier '48k'` | case | the tag `stufe-48k` (ADR 0005); one per case |
| `ask CONTENT, %opt` | case | a message with `role: user` |
| `message ROLE => CONTENT, %opt` | case | a message; `%opt` is `untrusted => 1` (later `images`, below) |
| `device NAME => TYPE => {…}` | case | `state.NAME` with `type: TYPE` |
| `world NAME => VALUE` | case | `state.NAME` without a type (handler worlds) |
| `observe match => {…}, when => […], output => …, error => 1` | case | one entry of `observe` |
| `rule TITLE => KIND` | case | one entry of `rules` |
| `at PATH, %exp` | constructor | rule kind `state` |
| `unchanged_except [PATHS]`, `calls [CALLS]`, `not_called CALL`, `only_tools [NAMES]` | constructor | the rule kind of the same name |
| `check {host, command}, expect => {…}`, `packet {…}, verdict => …`, `login {…}, result => …` | constructor | the rule kind of the same name |
| `solution CALLS` | case | `solution`; `solution()` is `[]`, the "no tool" family |
| `alternative TITLE => CALLS` | case | one entry of `alternatives` |
| `wrong TITLE => CALLS` | case | one entry of `wrong_solutions` |
| `call TOOL => {ARGS}` | constructor | `{ tool, args }` |
| `run HOST => COMMAND` | constructor | a call of the suite's tool with `simulator: run_command` |
| `put HOST => PATH => CONTENT` | constructor | a call of the suite's tool with `simulator: write_file` |
| `file 'NAME'` | constructor | the file's text, read relative to the suite file's directory |
| `haystack kind => …, tokens => …, seed => …, insert => […], exclude => […]` | constructor | `{ generate: {…} }` long content |

The same constructors build solution calls and the call patterns of `calls`/`not_called`;
as in format 2, the rule reads the arguments as patterns. `run` and `put` resolve their
tool name when the suite closes: exactly one tool with that `simulator` must exist, or the
suite does not load. Paths are dotted text or an array of segments, as in format 2.

### Collisions — decided

- `state` is a feature keyword (`use v5.10` and later): the rule kind is `at`, a world
  entry is `device`/`world`.
- `system` is a builtin: `system_prompt`. `write` is a builtin: `put`.
- `push`, `delete` (handler operations) are builtins: operations stay data hashes, no
  keywords for them.
- `version` shadows the core package in the suite file (`version->parse` there becomes a
  call of the keyword); kept, because format 2 names it so and a suite file has no use for
  the package. Write `version::->parse` if needed.
- `case`, `rule`, `run`, `file`, `tool`, `check`, `call`: no builtin, no `Test::More`
  export — kept. `Test2::V0` exports `call` and `check`, `Path::Class` exports `file`,
  `IPC::Run` exports `run` on request: a file that needs both renames on import
  (`use Langertha::Holmgang call => { -as => 'tool_call' };`, Sub::Exporter under
  `Moose::Exporter`). The house test framework is `Test::More`; nothing to rename there.

### Devices and simulator plugins

There are **no constructors per device type** (no `linux {…}`, `routeros {…}`): the type is
data, `device web1 => linux => {…}`. Keywords exported per registered type would depend on
which plugins were loaded before `use`, and a type name is free to be `link`, `time` or
`dns` — any builtin or user sub. The type is checked against the simulator registry
(`Simulators`, ADR 0005) when the suite closes, as the loader checks it; a plugin from
outside core only has to be registered by then. A plugin may ship its own helper module of
constructors for its state (they return plain hashes its simulator reads); those names are
the plugin's, outside this keyword set.

### Generators

- `generate seed => N, sub {…}` runs its block once, while the suite is built, and passes a
  **private random source** (`Langertha::Holmgang::Random`): a seeded object with a fixed,
  pure-Perl algorithm, so the same seed gives the same cases on every perl and platform.
  Never `srand`/`rand` — the global generator is shared with every other module. Changing
  the algorithm changes every generated suite and needs its `version` raised.
- A generator emits ordinary `case` declarations; nothing about the seed reaches the
  structure. Determinism is tested by generating in two processes with different
  `PERL_HASH_SEED` and comparing the YAML export byte for byte — the test that sees a
  `keys %h` loop in a generator.
- The seed in the file is the default. The loader takes an override per suite id, so a
  private measurement seed never has to be written into a public file (ADR 0003); the
  option's name belongs to the loader/CLI slice.

### Order, errors, digest

- Cases are ordered by id, as format 2 orders them by file name, so a DSL suite and its
  export run in the same order. A duplicate id refuses the suite.
- Refusals from `Structure` and lint name the suite file, the case id and the field path
  (`suite.pl: case 01-nginx-stopped: rules[1].equals`), like the loader's.
- A DSL suite's digest is the digest of its YAML export (k19 makes the bytes
  canonical): a suite and its export are the same suite.

### Where DSL suites live

- A search directory holds suite directories. A suite directory has **either**
  `suite.yaml` with `cases/` **or** `suite.pl`; both is an error, as is a suite id found in
  two search directories. `suite.pl` declares exactly one `suite`, whose id is the
  directory name; fixtures and texts for `file` sit beside it.
- Loading `suite.pl` runs Perl: it is code with the trust of an installed module. The
  loader reads it only from configured search directories, each file compiled in a package
  of its own. Model output never reaches it — the model only talks to simulators.
- `suite` also works outside the loader, in a test or script: it returns the `Suite`
  object, and `file` then reads relative to the calling file.

### Later fields

- **Images** (k27): an `images => [ … ]` option on `ask`/`message`, matching format 2's
  `images: [ { file, untrusted? } ]`, with an `image` constructor if a per-image option
  needs one. Both land with k27's loader change, not before.
- Anything else ADR 0005 or a later ADR adds to the structure gets its keyword in the slice
  that adds it, named in that slice's ADR.

### Example (invented)

```perl
use Langertha::Holmgang;

suite 'example-sums' => sub {
  title   'Example: add numbers, hand in the sum';
  version 1;
  topic   'reasoning';
  system_prompt 'Use the tool to hand in your answer. Then reply briefly without a tool.';

  tool submit_answer => (
    description => 'Hand in the final answer. A later call replaces an earlier one.',
    parameters  => { type => 'object', required => ['value'],
                     properties => { value => { type => 'integer' } } },
    handlers    => [ handler apply => [ { set => 'answer', value => '{value|int}' } ], output => 'ok' ],
  );

  generate seed => 4711, sub {
    my ( $rng ) = @_;
    for my $n ( 1 .. 3 ) {
      my @terms = map { $rng->int( 10, 99 ) } 1 .. 4;
      my $sum = 0;
      $sum += $_ for @terms;
      case sprintf( 'sum-%02d', $n ) => sub {
        title      'Sum of four numbers, variant '.$n;
        difficulty 'leicht';
        world answer => undef;
        ask 'Add '.join( ', ', @terms ).' and hand in the sum.';
        rule 'sum handed in'      => at 'answer', equals => $sum;
        rule 'nothing else moved' => unchanged_except ['answer'];
        solution    call submit_answer => { value => $sum };
        alternative 'corrected answer' =>
          call( submit_answer => { value => $sum - 1 } ), call( submit_answer => { value => $sum } );
        wrong 'off by one' => call submit_answer => { value => $sum + 1 };
      };
    }
  };
};
```

## Consequences

- The DSL slice depends on k2 (`Structure`, loader) and the registry of k3; its tests port
  nothing from cai-platform (there is no DSL there) and pin: every keyword against the
  format 2 hash it must produce, every collision above, croak locations, and generator
  determinism across processes.
- Acceptance 3 (k20) writes one suite in both forms; the export (k19) is the bridge and
  must round-trip DSL → YAML → loader to the same structure.
- New keywords need an ADR; a keyword without a format 2 image is a defect.

**Amendment 2026-11-11 (k18, implementation).** Chosen by the worker in the overnight run, not by the maintainer. The keywords, collisions and table above are implemented as written; what the ADR left open:

- **Owner of a keyword.** The open block lives in the package variables `$Langertha::Holmgang::OPEN` and `$LOADING`, only ever set with `local` (one block, one file) — the same deviation from "no package state" as `::Template`'s `$SIMULATORS` (ADR 0005 amendment k34): an `as_is` keyword has no other way to reach its block. As every `Moose::Exporter` module, `use Langertha::Holmgang` also turns on `strict` and `warnings` in the caller.
- **Once or many.** Once per block: `title`, `description`, `version`, `topic`, `license`, `repeat`, `threshold`, `source`, `system_prompt`, each key of `settings`, `difficulty`, `weight`, `tier`, `solution`. Appending: `tool`, `case`, `tags`, `ask`, `message`, `observe`, `rule`, `alternative`, `wrong`; `device`/`world` once per state name. `device` refuses a `type` key in its hash (the type is the second argument). `tier` takes what `Case::tier` reads (`\d+k`) and is refused beside a `stufe-` tag either way round.
- **Checked at once.** The pairs of `tool`, `handler`, `observe`, `settings`, `threshold`, `source`, `image`, `ask`/`message` (`untrusted`, `images`) and of every rule kind (its format 2 keys plus `required`; for `at` the expectations and `tolerance`, k49) — an unknown key dies at its line. **Exception: `haystack`** checks its keys when the suite closes, through `Structure` and `::Haystack` with the field path, because `::Haystack`'s key list is not public and a second copy would drift. `rule TITLE => KIND` refuses pairs after the kind: they belong to the kind (`at 'p', equals => 1, required => 0`).
- **Images (k27).** `images => [ … ]` on `ask`/`message` takes `image FILE, untrusted => 1` entries or a plain file name, which is `{ file => NAME }`; files are relative to the suite directory, which the DSL hands `Structure::case` as `dir`.
- **Closing a suite.** What the blocks recorded is deep-copied (a hash used in two cases is not shared); every `qr//` in it becomes its string form, not only under `regex`; `run`/`put` become calls of the suite's one tool with that simulator, else loading dies naming the line of the `run`/`put`. Then `Loader::assemble` (ADR 0005 amendment k18): `Structure::suite_head`, each case ordered by id through `Structure::case` and `Lint` with both mock runs — the code path of `Loader::load` — so the DSL has no checks of its own beyond keyword misuse. A suite without cases is refused, as in format 2.
- **Errors.** Keyword misuse dies with a text at the line that wrote it (`title: given twice in suite x at …/suite.pl line 14.`); under the loader that text becomes the refusal `suite.pl: …`. Refusals of `Structure` and lint name `suite.pl: case ID: FIELD` and `suite.pl: FIELD` for the head; outside the loader the calling file's basename stands in for `suite.pl`.
- **Digest — a temporary rule; the final bytes are k19's.** `assemble` takes the digest exactly as `load` does, over the parts of the suite's YAML export: `suite.yaml` (the head with `format: 2`), each case as `cases/<id>.yaml`, the generated texts and the images under those names. Until k19 defines the export's bytes, a part's bytes are `YAML::XS::Dump` of its data (keys sorted, `Loader::_export_bytes`); k19 replaces that one function with the export, so a DSL suite's digest changes once, then. Stable across processes and hash seeds (tested).
- **Seed override.** `Loader->new( seeds => { ID => N } )` replaces the seed of every `generate` block of the DSL suite `ID` (all of them get `N`). The command line has no option for it yet; its name is left to a CLI card.
- **`::Random`.** xoshiro128** (Blackman, Vigna) over four 32-bit words, seeded by splitmix32; `seed` 0 .. 2**32-1; methods `next_u32`, `int( LO, HI )` (inclusive, unbiased by rejection), `float`, `pick( LIST )`, `shuffle( LIST )`. Pure Perl, needs 64-bit integers like `::Haystack`. The first values are pinned in `t/random.t`.
- **Loading `suite.pl`.** Compiled as a string in a package of its own (`Langertha::Holmgang::_SuiteFile<N>`) with none of the loader's pragmas, like `do FILE`; `#line` keeps the file's path and lines in messages. The command line's `lint` and `run` take a directory with `suite.pl` like one with `suite.yaml`.
- **No shipped DSL example in this slice.** ADR 0010 allows one; it is left out because another slice was changing `share/suites`, `t/share_suites.t` and ADR 0010 in the same tree at the same time. A follow-up card.

**Amendment 2026-11-11 (k19, the YAML export).** Chosen by the worker in the overnight run, not by the maintainer. The temporary `Loader::_export_bytes` is gone; `assemble` writes the export's files and hashes exactly those bytes, so a DSL suite's digest is the digest `load` takes of its export (tested: export, load, same digest). The DSL digests of k18 change once, here; format 2 suites are hashed over their files as before and keep their digests (acceptance baseline).

- **Where.** `Loader->export( DIR, ROOT )` (ADR 0005 puts the export into `::Loader`): loads the DSL suite (lint included, with the loader's `seeds`), writes `ROOT/<id>/suite.yaml`, `cases/<id>.yaml` and every image a case shows (copied byte for byte under its relative path), into a temporary directory under `ROOT` that is renamed into place, then loads the result back; anything but the same digest removes it and refuses (field `export`). An existing `ROOT/<id>` is refused, nothing is overwritten. A directory with `suite.yaml` is refused (field `suite`): format 2 is YAML already. The written files are kept on the `Suite` in a private attribute (`_export`), set only by `assemble`.
- **Contents.** The format 2 data the keywords built, nothing else: `suite.yaml` is the head with `format: 2`; texts read by `file` are inline (no text file is copied); `haystack` specs stay `generate` specs (ADR 0005: the export writes the spec, not the text); generated cases are plain cases; `qr//` is its string form; `tier` is its `stufe-` tag. No comment header: the `source`/`license` keys carry the origin.
- **Canonical bytes — an own small YAML writer, not `YAML::XS::Dump`.** `YAML::XS` writes every text with a line break as one double-quoted line, which defeats "readable without Perl" for system prompts and file contents, and its bytes would follow its bundled libyaml. The writer: block style, two spaces, a list under its key indented; keys sorted, but `format id name title tool role version description` first; a text with line breaks as a literal block (`|`, `|-` without, `|+` with more than one final line break) when it holds no character YAML must escape and its first line is not indented; other texts plain when they start with a letter or `/`, hold only letters, digits, space and `_./+,?'()=:-`, have no `: ` and no trailing space or colon, and are no number or YAML word (`y n yes no on off true false null`, any case), else double-quoted with `\n \t \" \\ \xHH \uHHHH` escapes; a value Perl holds only as a number (IV/NV flags without POK, as JSON encoders decide) plain, so a numeric *text* stays quoted and a tool's `enum: ["0","1"]` stays strings; `undef` as `~`; a Perl boolean (`builtin::is_bool`) or `JSON::PP::Boolean` as `true`/`false` — which `YAML::XS` reads back as `1`/`''`, the same to every check. UTF-8. Every literal block is read back alone before it is used, and every file is read back with `YAML::XS` and compared with the data (texts by `eq`, booleans by truth); a value that does not survive (a code reference) refuses with the case's field. Two exports, and an export under another hash seed in another process, are byte-identical (tested). A number's flags can differ between perls when the generator also used it as text; `0 + $n` or `"$n"` pins it.
- **Order.** Cases are sorted by their export file name `<id>.yaml`, not by id: format 2 loads files in name order, and the two differ when one id is another plus `-…` (`a-b.yaml` sorts before `a.yaml`, `a` before `a-b`). k18 sorted by id; the DSL now runs in exactly the export's order (tested with `a` and `a-b`).
- **Command line:** `holmgang export-yaml` (ADR 0009 amendment k19/k51).
- **Seen while testing, not changed (noted on k19):** a code reference in a case's state passes `Structure` and dies in the world's copy without a field path; the export's own refusal is tested directly.

**Amendment 2026-11-11 (k52, excerpts).** Chosen by the worker in the overnight run, not by the maintainer. New constructor **`excerpt FILE, from => LABEL, to => LABEL`**: the format 2 part `{ auszug: { datei: FILE, von: FROM, bis: TO } }` (ADR 0005 amendment k52), used as a message content alone or among the parts of a list (`ask [ "…", excerpt( 'quellen/lfg.txt', from => '§ 2', to => '§ 3' ), "…" ]`). English keyword and pair names, as `haystack` stands for `generate` and `tier` for the `stufe-` tag; pairs rather than `FILE => FROM => TO` so that the two labels cannot be swapped unseen. Checked at once: a file name, the pairs `from`/`to` only, both texts — misuse dies at its line. The file and the range are checked when the suite closes, by `Structure` through `::Excerpt`, with the field path (`suite.pl: case c1: messages[0].content[1].auszug.bis`); the file is relative to the suite directory, like images. The export writes the part unchanged and copies the fixture (ADR 0005 amendment k52); the export loads back with the same digest (tested).

**Amendment 2026-11-11 (k59).** The k19 note "a code reference in a case's state passes `Structure`" is resolved: `Structure` refuses it with the field path (ADR 0005 amendment k59), regression test `t/dsl/state_plain.t`. A `qr//` in the state is still stored as its string form (closing a suite, above), not refused.

**Amendment 2026-11-11 (k60, suite.pl is UTF-8 source).** Chosen by the worker in the overnight run, not by the maintainer. A `suite.pl` is compiled with `use utf8` in effect, whether the file says so or not: the loader adds the pragma in front of the file's first line (`#line 1` keeps line numbers as written). Before, the file was read as bytes and compiled without pragmas, so a file without `use utf8` turned every non-ASCII text into Latin-1 mojibake that loaded, linted and passed both mock runs while the model was sent garbled text. The other reading — refuse non-ASCII without `use utf8` — was rejected: a DSL suite is text, no author means Latin-1, and a refusal would only make every author write the same line. A file that says `use utf8;` itself loads the same suite (same digest); a file that is not valid UTF-8 is refused with the field `suite.pl` ("not UTF-8"), checked before compiling. Texts read by `file` were already decoded as UTF-8 and are unchanged. The export writes the characters as UTF-8 and loads back with the same digest. Digests of DSL suites with non-ASCII text and no `use utf8` change once, here — they were the digests of the mojibake; suites that said `use utf8` and format 2 suites keep theirs. Regression test `t/dsl/utf8.t` checks the outgoing request against `Langertha::Engine::Virtual`.
