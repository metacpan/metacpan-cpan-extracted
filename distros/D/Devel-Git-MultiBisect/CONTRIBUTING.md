Thank you for considering contributing to this distribution.  This file contains instructions that will help you work with the source code.

Because the objective of Devel-Git-MultiBisect is to assist you in diagnosing
problems with Perl libraries which use `git` as their version control systems,
this distribution's test suite of necessity entails using real git
repositories.

Up through version 0.15, we bundled two such repositories
within the distribution as git submodules.  This enabled us to compose test
files based on real-world uses of this library.  But this approach came with
two costs:

* The tarball shipped to CPAN was massive:  around 2.24 megabytes.

* A few CPANtesters rigs repeatedly failed for reasons not well understood --
  even though other CPANtesters rigs run by the same individuals gave the
  distribution repeated PASSes.

Beginning with version 0.16 we are taking a different approach.  Instead of
bundling other GitHub repositories as submodules within this distribution, we
now ask potential developers to do `git clone`s of two CPAN distributions and
do `git checkout`s of them on the same machine where you are working on
Devel-Git-MultiBisect.  Specifically:

* Let's assume that you have an environmental variable which holds the path to
  the directory into which you `git clone` repositories from GitHub.
```
$ mkdir -p $HOMEDIR/gitwork
$ export GIT_WORKDIR=$HOMEDIR/gitwork
$ cd $GIT_WORKDIR
```
* At this point you would usually proceed via:
```
$ git clone git@github.com:jkeenan/devel-git-multibisect.git
$ cd devel-git-multibisect
$ perl Makefile.PL && make
```
... and then proceed to hack on the codebase.

* However, if you want to give Devel-Git-MultiBisect a thorough inspection
  before installing from CPAN, or if you want to run a thorough set of tests
  during development, you should now do this:
```
$ git clone git@github.com:jkeenan/devel-git-multibisect.git
$ git clone git@github.com:jkeenan/list-compare.git
$ git clone git@github.com:jkeenan/dummyrepo.git
$ export PERL_LIST_COMPARE_GIT_CHECKOUT_DIR=$GIT_WORKDIR/list-compare
$ export PERL_DUMMYREPO_GIT_CHECKOUT_DIR=$GIT_WORKDIR/dummyrepo
$ cd devel-git-multibisect
$ perl Makefile.PL && make
$ make test
```
Certain files in the test suite will seek out files in the directories pointed
to by `$PERL_LIST_COMPARE_GIT_CHECKOUT_DIR` and `$PERL_DUMMYREPO_GIT_CHECKOUT_DIR`.
The coverage provided by those tests will match or exceed that provided by the
test suite in versions earlier than 0.16.

