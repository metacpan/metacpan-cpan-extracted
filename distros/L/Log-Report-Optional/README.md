# distribution Log-Report-Optional

  * My extended documentation: <http://perl.overmeer.net/CPAN/>
  * Development via GitHub: <https://github.com/markov2/perl5-Log-Report-Optional>
  * Download from CPAN: <ftp://ftp.cpan.org/pub/CPAN/authors/id/M/MA/MARKOV/>
  * Indexed from CPAN: <https://metacpan.org/release/Log-Report-Optional>

This module will allow libraries (helper modules) to have a dependency
to a small module instead of the full Log-Report distribution.  The full
power of "Log::Report" is only released when the main program uses that
module.  In that case, the module using the 'Optional' will also use the
full "Log::Report", otherwise the dressed-down "Log::Report::Minimal"
version.

## Development &rarr; Release

Important to know, is that I use an extension on POD to write the manuals.
The "raw" unprocessed version is visible on GitHub.  It will run without
problems, but does not contain manual-pages.

Releases to CPAN are different: "raw" documentation gets removed from
the code and translated into real POD and clean HTML.  This reformatting
is implemented with the OODoc distribution (A name I chose before OpenOffice
existed, sorry for the confusion)

Clone from github for the "raw" version.  For instance, when you want
to contribute a new feature.

On github, you can find the processed version for each release.  But the
better source is CPAN; to get it installed simply run:

```sh
   cpan -i Log::Report::Optional
```

## Contributing

When you want to contribute to this module, you do not need to provide
a perfect patch... actually: it is nearly impossible to create a patch
which I will merge without modification.  Usually, I need to adapt the
style of code and documentation to my own strict rules.

When you submit an extension, please contribute a set with

1. code

2. code documentation

3. regression tests in t/

**Please note:**
When you contribute in any way, you agree to transfer the copyrights to
Mark Overmeer (you will get the honors in the code and/or ChangeLog).
You also automatically agree that your contribution is released under
the same license as this project: licensed as perl itself.

## Copyright and License

This project is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See <http://dev.perl.org/licenses/>
