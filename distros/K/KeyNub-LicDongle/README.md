# KeyNub License Dongle — Perl binding

```perl
use KeyNub::LicDongle qw(%STATUS $SCOPE_DEVELOPER);

my $dongle = KeyNub::LicDongle->open;      # first dongle, or ->open($serial)
$dongle->verify_genuine;                   # dies unless genuine
$dongle->session_open;
my $data = $dongle->app_decrypt($blob);    # <- build the licence check on this
$dongle->session_close;
$dongle->close;
```

Perl 5.20+ and **[FFI::Platypus](https://metacpan.org/pod/FFI::Platypus)**, the one
dependency:

```
cpanm FFI::Platypus
```

## It uses the flat API, not the core ABI

Unlike the other scripting bindings, this one calls
[`keynub_licdongle_flat`](https://github.com/AB-KeyNub/KeyNub-SDK/blob/master/bindings/flat/README.md) — the same surface COBOL and Fortran
use. Perl has no way to describe a C struct layout that computes its own padding,
so a core-ABI binding would have to hand-write `unpack` templates with explicit
offsets, and a wrong offset there reads a neighbouring field: a plausible wrong
value rather than a crash, and the hardest kind of bug to notice. The flat API has
no structs at all, so the problem does not arise.

What that costs: **no progress reporting**, because the flat API has no callbacks.
Records are read in one call.

Set `KEYNUB_LICDONGLE_FLAT_LIBRARY` to point at a specific library.

## Notes

- Failures die with a `KeyNub::LicDongle::Error` object that stringifies for a
  plain `die` handler and carries `status`, `operation` and `detail` for code that
  wants to branch — compare `$err->status` against `$STATUS{NO_DEVICE}`.
- `$dongle->is_genuine` is the non-dying form for a gate and **fails closed**: a
  missing dongle, an I/O error and an invalid certificate all return false.
- Records and app-crypto use the flat API's two-call size protocol internally, so
  callers never size a buffer themselves.
- `erase_all_records` is deliberately separate from `erase_record`: in the C API a
  null name means "erase every record", and an accidentally empty Perl variable
  must not do that.
- `close` is called from `DESTROY` as well, and the destructor cannot die. The
  library holds 32 handles at once, so a loop that forgets will notice.

> Read [`../../docs/integration-security.md`](https://github.com/AB-KeyNub/KeyNub-SDK/blob/master/docs/integration-security.md)
> before writing the check. `exit unless $dongle->is_genuine` is one line to
> delete, and Perl ships as source — obfuscation and `pp` only raise the effort.
> What cannot be deleted is data the program needs and only the dongle can
> decrypt.

## Status

Shipping this one is still an open decision. It works and it is tested like
everything else, but on an *engineering*-dongle language list Perl reads as padding
to a technical evaluator. It is here because
it was cheap once the toolchain was in place; see
the binding list.

## Links

- [KeyNub License Dongle for Perl](https://www.keynub.com/developers/perl/): the product, and how to
  order one
- [Source, samples and issue tracker](https://github.com/AB-KeyNub/KeyNub-SDK) on GitHub
- [Native library for your platform](https://github.com/AB-KeyNub/KeyNub-SDK/blob/master/NATIVES.md)
