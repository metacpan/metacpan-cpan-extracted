# Platform compatibility test dependencies

The `platform-compatibility.yml` full-suite matrix installs project modules
under `local/lib/perl5`. Before running the suite, it must also install
`Devel::Cover` into that same local library and export the library through
`PERL5LIB` in `GITHUB_ENV`.

This setup is required by the coverage-gate regression tests. Those tests start
child Perl processes which load `Devel::Cover::DB::IO`; a parent test process
passing its assertions does not prove that those children can locate the
serializer. If the workflow omits the coverage tool or the `PERL5LIB` export,
the gate exits before reaching its intended assertions, making tests such as
`t/149`, `t/150`, `t/169`, and `t/175` fail for setup reasons.

The install and environment-export step must exist and precede the
full-suite step. This workflow setup must make the required tooling
available rather than changing expected results.
