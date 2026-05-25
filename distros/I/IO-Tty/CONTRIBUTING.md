# Contributing to IO::Tty

## Bug Reports

Open an issue at https://github.com/cpan-authors/IO-Tty/issues with:

- Your OS and version
- Perl version (`perl -v`)
- Full output of `perl Makefile.PL && make && make test`

## Pull Requests

1. Fork the repository
2. Create a feature branch
3. Ensure `make test` passes
4. Submit a pull request against `main`

### Build & Test

```bash
perl Makefile.PL
make
make test
```

### Guidelines

- IO::Tty is POSIX-only. Windows is not supported (Cygwin works).
- The XS code supports multiple pty allocation strategies across many
  Unix variants. Test on as many platforms as you can.
- `Makefile.PL` compiles C test programs at configure time — changes
  there need careful testing.
- Don't edit generated files (`xssubs.c`, `Tty/Constant.pm`, `Tty.c`).

## Releases

Releases to CPAN are done by the maintainer only.
