# Devel::Deanonymize

A small tool to make anonymous subs visible to Devel::Coverage (and possibly similar Modules).
Code is based on https://github.com/pjcj/Devel--Cover/issues/51#issuecomment-17222928

## Synopsys 

```bash
# delete old coverage data (optional)
cover -delete

# Perl scripts
perl -MDevel::Cover=-ignore,^t/,Deanonymize -MDevel::Deanonymize=<inculde_pattern> your_script.pl

# Perl tests
HARNESS_PERL_SWITCHES="-MDevel::Cover=-ignore,^t/,Deanonymize -MDevel::Deanonymize=<include_pattern"  prove t/

# generate report
cover -report html
```

## Debugging

If your tests suddenly fail for some weird reason, you can set `DEANONYMIZE_DEBUG`. If this environment variable is set,
we print out the filename for every modified file and write its contents to `<filpath/filename>_mod.pl`

## Coverage Reports

Per default, `Devel::Cover` creates a folder named `cover_db` inside the project root. To visualize the result, we have to
generate a report:

```bash
cover -report html
```

The html report (or any other report type) is then stored under `cover_db` as well.


## Examples

See separate subdirectory [examples/runit.sh](examples/runit.sh)

## Important notes

- Make sure your script (the one under test) always ends with `__END__`, `__DATA__` or `1;`, otherwise the regex to modify it fails silently
- To debug if your script is "deanonymized" use `warn()` instead of `print()` print is somewhat unreliable in this early stage
- [Devel::Cover](https://metacpan.org/pod/Devel::Cover) on cpan