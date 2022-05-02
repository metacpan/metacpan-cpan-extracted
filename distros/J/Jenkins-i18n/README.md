# jenkins-translation-tool

CLI to generate missing translation keys and missing properties files and remove
unused keys for a given language.

This is a fork from the original Perl script `translation-tool.pl` available at
the [official Jenkins project](https://github.com/jenkinsci/jenkins).

## Differences from the original tool

### New features

#### Improved online documentation

```
$ jtt --help
Usage:
      jtt --lang=xx

      options:
        --dir=directory    -> source folder for searching files, optional
        --help             -> print this help message and exits
        --man              -> provides this CLI manpage and exits
        --lang=xx          -> language code to use
        --add              -> optional, generate new files and add new keys to existing
                              files if present
        --remove           -> optional, remove unused key/value pair for existing files
                              if present
        --counter          -> optional, to each translated key, unique value is added
                              to easily identify match missing translation with value
                              in source code if present
        --target=directory -> optional, target directory for writing files
        --debug            -> optional, print debugging messages to STDOUT when they
                              are available
```

#### Better formatted output

Warnings per translation file:

```
Got warnings for core/src/main/resources/hudson/model/Messages_pt_BR.properties:
	Empty 'HealthReport.EmptyString'
	Empty 'MultiStageTimeSeries.EMPTY_STRING'
	Same 'UpdateCenter.PluginCategory.maven'
	Same 'UpdateCenter.PluginCategory.devops'
	Same 'UpdateCenter.PluginCategory.devsecops'
	Same 'JDK.DisplayName'
	Same 'Hudson.DisplayName'
	Same 'Item.Permissions.Title'
	Same 'Queue.Unknown'
	Same 'Run.Summary.Unknown'
```

This is a translation summary:

```
         Translation Status

    Status         Total      %
    -----------------------------
    Done           2044     98.64
    Missing        0        0
    Orphan         5        0.241
    Empty          2        0.096
    Same           21       1.013
    No Jenkins     0        0
```

### No caching

The script `translation-tool.pl` tried to implement some sort of processing
results caching, but that didn't work very well. On the other hand, the script
should procedure results reasonably fast (~2,7s in a Intel i5-7200U 2.50GHz
with encrypted disk), so it's not an issue per see not having it.

Cache may be implemented in the future again.

### No encoding conversion

The script `translation-tool.pl` tried to convert Jenkins properties from
ASCII to UTF-8 and vice-versa using regular expressions. No need to tell how
well that worked.

The best way to achieve that is to use your preferred IDE, see
[the suggested workflow](Workflow.md) for more details on that.

### No editor execution

`jtt` won't execute a given editor per missing file. This might be seems as a
useful feature, but it can become a real issue if you have hundred of files to
be open in a IDE.

Different IDE's have different ways to handle that (like opening tabs), which
might be useful per see, but stills can hog down your computer if too many are
required.

### Reviewed command line options

Command line options are now are properly handled with parsing and validation.

### Always includes original sentences

When there are new keys to translate, the original English text will always be
included with the `---TranslateMe` prefix (which must be removed, obviously).

## See also

- A suggested [workflow](Workflow.md) to carry on translations with `jtt`.
- A bit of [history](History.md) that influenced how design decisions were
made to this project.

## Install

### TLDR

You will need to have Perl version 5.14 or higher available in your system,
which should be default for UNIX-like operational systems like Linux and MacOSX.

  ```
  cpan Jenkins::i18n
  ```

### Detailed description

There are several ways to install Perl modules, all very well documented by
the community. Those external dependencies are all Perl modules available at
[CPAN](https://metacpan.org/).

Here is a list of ways to do it:

1. Install with [cpan](https://metacpan.org/dist/CPAN/view/scripts/cpan#SYNOPSIS) CLI and [local::lib](https://metacpan.org/pod/local::lib).
2. Install [perlbrew](https://perlbrew.pl/), install your personal `perl` then use `cpan` CLI.
3. Install modules as root using `cpan` CLI: worst and not recommended method.

## Development details

### Dependencies

See the `Makefile.PL` file for `TEST_REQUIRES` and `PREREQ_PM` entries.

### Testing

Once the dependencies are installed, you can run the tests available for this
module:

```
prove -lvm
```

Here is a sample:

```
$ prove -lvm
t/Jenkins-i18n.t ....
1..1
ok 1 - use Jenkins::i18n;
ok
t/removed_unused.t ..
1..15
ok 1 - dies without file parameter
ok 2 - get the expected error message
ok 3 - dies without keys parameter
ok 4 - get the expected error message
ok 5 - dies with invalid keys parameter
ok 6 - get the expected error message
# Without a license
ok 7 - got the expected number of keys removed
ok 8 - resulting properties file has the expected number of lines
ok 9 - dies with invalid license parameter
ok 10 - get the expected error message
# Restoring file
# With a license
ok 11 - got the expected number of keys removed
ok 12 - resulting properties file has the expected number of lines
# Restoring file
# With a backup
ok 13 - got the expected number of keys removed
ok 14 - resulting properties file has the expected number of lines
ok 15 - File has a backup as expected
ok
All tests successful.
Files=2, Tests=16,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.14 cusr  0.01 csys =  0.17 CPU)
Result: PASS
```

You can also get testing coverage if `Devel::Cover` is installed:

```
~/jenkins-translation-tool$ perl Makefile.PL
Generating a Unix-style Makefile
Writing Makefile for Jenkins::i18n
Writing MYMETA.yml and MYMETA.json

~/jenkins-translation-tool$ make
Skip blib/lib/Jenkins/bench.pl (unchanged)
Skip blib/lib/Jenkins/i18n/Warnings.pm (unchanged)
Skip blib/lib/Jenkins/i18n/Stats.pm (unchanged)
Skip blib/lib/Jenkins/i18n/ProcOpts.pm (unchanged)
Skip blib/lib/Jenkins/i18n.pm (unchanged)
cp lib/Jenkins/i18n/Properties.pm blib/lib/Jenkins/i18n/Properties.pm
cp bin/jtt blib/script/jtt
"perl" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/jtt
Manifying 1 pod document
Manifying 5 pod documents

jenkins-translation-tool$ cover -test
Deleting database ~/jenkins-translation-tool/cover_db
cover: running make test "OPTIMIZE=-O0 -fprofile-arcs -ftest-coverage" "OTHERLDFLAGS=-fprofile-arcs -ftest-coverage"
PERL_DL_NONLAZY=1 "perl" "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" t/*.t
t/find_files.t ....... ok   
t/Jenkins-i18n.t ..... ok   
t/load_jelly.t ....... ok   
t/load_properties.t .. ok   
t/proc_opts.t ........ ok    
t/removed_unused.t ... ok     
t/stats.t ............ ok     
t/warnings.t ......... ok     
All tests successful.
Files=8, Tests=99,  3 wallclock secs ( 0.04 usr  0.00 sys +  2.53 cusr  0.17 csys =  2.74 CPU)
Result: PASS
Reading database from ~/jenkins-translation-tool/cover_db


---------------------------- ------ ------ ------ ------ ------ ------ ------
File                           stmt   bran   cond    sub    pod   time  total
---------------------------- ------ ------ ------ ------ ------ ------ ------
blib/lib/Jenkins/i18n.pm       91.2   78.5   66.6   92.8  100.0   72.3   87.3
.../Jenkins/i18n/ProcOpts.pm  100.0  100.0   66.6  100.0  100.0    7.5   98.9
...enkins/i18n/Properties.pm  100.0   66.6   33.3  100.0  100.0    6.2   88.3
...lib/Jenkins/i18n/Stats.pm   78.9   83.3    n/a  100.0  100.0    6.8   83.6
.../Jenkins/i18n/Warnings.pm   97.3   90.0    n/a  100.0  100.0    6.9   96.4
Total                          94.2   80.4   53.3   98.3  100.0  100.0   91.3
---------------------------- ------ ------ ------ ------ ------ ------ ------


HTML output written to ~/jenkins-translation-tool/cover_db/coverage.html
done.
```

## References

- [Jenkins Internationalization](https://www.jenkins.io/doc/developer/internationalization/)
- [i18n](https://wiki.mageia.org/en/What_is_i18n,_what_is_l10n)
- [Online convertion of UTF-8 to Java entities](http://itpro.cz/juniconv/)

## Copyright and licence

This software is copyright (c) 2022 of Alceu Rodrigues de Freitas Junior,
arfreitas at cpan.org

This file is part of Jenkins Translation Tool project.

Jenkins Translation Tool is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your option)
any later version.

Jenkins Translation Tool is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Jenkins Translation Tool. If not, see (http://www.gnu.org/licenses/).

The original `translation-tool.pl` script was licensed through the MIT License,
copyright (c) 2004-, Kohsuke Kawaguchi, Sun Microsystems, Inc., and a number
of other of contributors. Translations files generated by the Jenkins
Translation Tool CLI are distributed with the same MIT License.
