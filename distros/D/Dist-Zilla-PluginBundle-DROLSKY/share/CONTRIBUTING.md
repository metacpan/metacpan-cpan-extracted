# CONTRIBUTING

Thank you for considering contributing to this distribution. This file
contains instructions that will help you work with the source code.

Please note that if you have any questions or difficulties, you can reach the
maintainer(s) through the bug queue described later in this document
(preferred), or by emailing the releaser directly. You are not required to
follow any of the steps in this document to submit a patch or bug report;
these are just recommendations, intended to help you (and help us help you
faster).

The distribution is managed with
[Dist::Zilla](https://metacpan.org/release/Dist-Zilla).

However, you can still compile and test the code with the
{{ -e 'Makefile.PL' ? q{`MakeFile.PL`} : -e 'Build.PL' ? q{`Build.PL`} : 'ERROR: no Makefile.PL or Build.PL!!!' }}
in the repository:
{{ if ( -e 'Makefile.PL' ) {
'
    perl Makefile.PL
    make
    make test
'
} else {
'
    perl Build.PL
    ./Build
    ./Build test
'
} }}

You may need to satisfy some dependencies. The easiest way to satisfy
dependencies is to install the last release. This is available at
https://metacpan.org/release/{{ $dist->name }}

You can use [`cpanminus`](https://metacpan.org/pod/App::cpanminus) to do this
without downloading the tarball first:

    $ cpanm --reinstall --installdeps --with-recommends {{
  $main_package = $dist->main_module->name;
  $main_package =~ s{^lib/}{};
  $main_package =~ s{\.pm$}{};
  $main_package =~ s{/}{::}g;
  $main_package
}}

[`Dist::Zilla`](https://metacpan.org/pod/Dist::Zilla) is a very powerful
authoring tool, but requires a number of author-specific plugins. If you would
like to use it for contributing, install it from CPAN, then the following
command to install the needed distros:

    $ dzil authordeps --missing | cpanm

There may also be additional requirements not needed by the dzil build which
are needed for tests or other development:

    $ dzil listdeps --author --missing | cpanm

Or, you can use the 'dzil stale' command to install all requirements at once:

    $ cpanm Dist::Zilla::App::Command::stale
    $ dzil stale --all | cpanm

You can also do this via cpanm directly:

    $ cpanm --reinstall --installdeps --with-develop --with-recommends {{ $main_package }}

Once installed, here are some dzil commands you might try:

    $ dzil build
    $ dzil test
    $ dzil test --release
    $ dzil xtest
    $ dzil listdeps --json
    $ dzil build --notgz

You can learn more about Dist::Zilla at http://dzil.org/.
{{
if ((my $link = $dist->distmeta->{resources}{repository}{web}) =~ /github/) {
"\n" . 'The code for this distribution is [hosted on GitHub](' . $link . ').'
. "\n" .'
You can submit code changes by forking the repository, pushing your code
changes to your clone, and then submitting a pull request. Please update the
Changes file with a user-facing description of your changes as part of your
work. See the GitHub documentation for [detailed instructions on pull
requests](https://help.github.com/articles/creating-a-pull-request)'; }
}}

If you have found a bug, but do not have an accompanying patch to fix it, you
can submit an issue report [via the web]({{ $dist->distmeta->{resources}{bugtracker}{web} // 'WARNING: bugtracker data not set!' }}){{ $dist->distmeta->{resources}{bugtracker}{mailto} ? ' or [via email](' . $dist->distmeta->{resources}{bugtracker}{mailto} . ')' : q{} }}.
{{
my $extra = $dist->distmeta->{resources}{x_MailingList}
    ? "\n\n" . 'There is a mailing list available for users of this distribution,' . "\n" . $dist->distmeta->{resources}{x_MailingList}
    : '';
$extra .= $dist->distmeta->{resources}{x_IRC}
    ? "\n\n" . 'This distribution also has an IRC channel at' . "\n" . $dist->distmeta->{resources}{x_IRC}
    : '';
$extra;
}}
{{ if ( -e '.travis.yml' ) {
    my ($path) = `git remote show -n origin` =~ /github\.com:(.+)\.git/;
    my $ci_links = "on Linux by [Travis](https://travis-ci.org/$path)";
    if ( -e 'appveyor.yml' ) {
        # AppVeyor paths use my username, not the GitHub group name.
        $path =~ s{^.+/}{autarch/};
        $ci_links .= " and on Windows by [AppVeyor](https://ci.appveyor.com/project/$path)";
    }
    my $ci = "
## Continuous Integration

All pull requests for this distribution will be automatically tested
$ci_links.";

$ci .= '

All CI results will be visible in the pull request on GitHub. Follow the
appropriate links for details when tests fail. PRs cannot be merged until tests
pass.';

$ci;

} }}

{{ if ( -e 'tidyall.ini' ) {
'
## TidyAll

This distribution uses
[Code::TidyAll](https://metacpan.org/release/Code-TidyAll) to enforce a
uniform coding style. This is tested as part of the author testing suite. You
can install and run tidyall by running the following commands:

    $ cpanm Code::TidyAll
    $ tidyall -a

Please run this before committing your changes and address any issues it
brings up.'
} }}

## Contributor Names

If you send a patch or pull request, your name and email address will be
included in the documentation as a contributor (using the attribution on the
commit or patch), unless you specifically request for it not to be. If you
wish to be listed under a different name or address, you should submit a pull
request to the `.mailmap` file to contain the correct mapping.

## Generated By

This file was generated via {{ ref($plugin) . ' ' . ($plugin->VERSION || '<self>') }} from a
template file originating in {{
    (my $module = $plugin->dist) =~ s/-/::/g;
    eval "require $module";
    $plugin->dist . '-' . $module->VERSION
}}.
