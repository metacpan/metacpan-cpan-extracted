CONTRIBUTING
============
 
Thanks for considering contributing to this distribution.

(Please note that numbers in square brackets, for example `[0]` refer to references
at the bottom of this file.)

This distribution is managed with `Dist::Zilla`[0]. It is *not*
necessary to install Dist::Zilla to contribute.

Please consider working on the code as stored in the code
repository.  Patches against the distributed code are welcome, but
patches or pull requests against the code in the repository are even
more welcome.

The public repository for this code is managed with git and is hosted at GitLab.
It is available via the web at:

  https://gitlab.com/djerius/iterator-flex

You can submit code changes by forking the repository, pushing your code
changes to your clone, and then submitting a merge request. Detailed
instructions for doing that is available here:

  https://docs.gitlab.com/ee/user
  https://docs.gitlab.com/ee/user/project/merge_requests/getting_started.html


My primary repository actually uses Mercurial, so if you are more
comfortable using that, drop a line to Diab Jerius <djerius@cpan.org>.


Installing Dependencies
-----------------------

Dependencies for this module are recorded in the `META.json` file.
Installation is most easily done with `cpanminus`[1], which can be
made available locally via:

  $ curl -L https://cpanmin.us/ -o cpanm
  $ chmod +x cpanm

To install the dependencies into a local directory (to avoid polluting
your Perl distribution),

  $ export PERL5LIB=${PERL5LIB}:$PWD/local
  $ cpanm -l local --installdeps --with-recommends --with-develop .

This installs the dependencies into the `./local` directory.  Be sure
to clean up the PERL5LIB environment variable when you are done!


Working without Dist::Zilla
---------------------------

This directory contains a working Build.PL that will allow you to
work without `Dist::Zilla`.

If you have installed dependencies into a local directory, make sure that
is in your `PERL5LIB` path.

Then, as usual,

  $ perl Build.PL
  $ ./Build
  $ ./Build test

Working with Dist::Zilla
------------------------
 
`Dist::Zilla` is a tool whose flexibility is derived from a wide range
of plugins.  The first step is to install `Dist::Zilla` itself:

  $ cpanm Dist::Zilla

Then, install the plugins that this module requires.  In this example
they are stored locally, to avoid polluting your Perl distribution.
If you haven't already done so, add the local directory to your
`PERL5LIB` path:

  $ export PERL5LIB=${PERL5LIB}:$PWD/local
  $ dzil authordeps --missing | cpanm -l local

You should then also install any additional requirements not needed by the
dzil build but may be needed by tests or other development:
 
  $ dzil listdeps --author --missing | cpanm -l local
  $ dzil listdeps --develop --missing | cpanm -l local
  $ cpanm -l local --installdeps --with-develop .
 
Once installed, here are some dzil commands you might try:
 
  $ dzil build
  $ dzil test
  $ dzil xtest
 
You can learn more about `Dist::Zilla` at http://dzil.org/.
 
Submitting Patches
------------------

Please submit patches as merge requests using the web-based repository tools or
as attachments to bug reports.

Submitting Bug Reports
----------------------

If you have found a bug, but do not have an accompanying patch to fix it, you
can submit an issue report 

at this website:

  https://rt.cpan.org/Public/Dist/Display.html?Name=Iterator-Flex

or via email to:

  bug-iterator-flex@rt.cpan.org

or via email to:

 Diab Jerius <djerius@cpan.org>


Idiosyncracies
--------------

* Some files are generated during the build and copied from the
  release (see the [CopyFilesFromRelease] section in `dist.ini`]

* Modify `templates/CONTRIBUTING.md` to change `CONTRIBUTING.md`


References
==========

[0] http://dzil.org/.

[1] https://github.com/miyagawa/cpanminus
 
