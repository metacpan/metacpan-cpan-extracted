# MailTools

  * My extended documentation: <http://perl.overmeer.net/CPAN/>
  * Development via GitHub: <https://github.com/markov2/perl5-MailTools>
  * Download from CPAN: <ftp://ftp.cpan.org/pub/CPAN/authors/id/M/MA/MARKOV/>
  * Indexed from CPAN: <http://search.cpan.org/~markov/MailTools/>
    and <https://metacpan.org/release/MailTools>

MailTools is one of the oldest modules on CPAN.  It started off in 1995,
the year Perl 5.0 got released!  That's just in the beginning of the
MIME standards.

Email has become more complex over the years.  The components of
MailTools only understand very basic emails and fairly simple mime
headers.  Fixing some things will break existing applications.

The only reason for still maintaining it, is because it is used as example
in many books and therefore applications still use it.  Not because it
is good.  Sometimes it is good enough, though.

Later, this module got extended by the MIME::Entity modules to support
multiparts and more smartness.  But even those modules are quite limited,
considering modern emails.

**Please note:** When you start all over, please consider Mail::Box!
For a feature overview, take a look at the
[MailBox overview](http://perl.overmeer.net/mailbox/html/Mail_Box-Overview/)
and
[MailBox features](http://perl.overmeer.net/mailbox/html/Mail_Box-Index/)
pages.

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
   cpan -i MailTools
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

Graham Barr wrote most of these components, since 2001 maintained by
Mark Overmeer. Copyright is with these authors.

This project is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See <http://dev.perl.org/licenses/>

