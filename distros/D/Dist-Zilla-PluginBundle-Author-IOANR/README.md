# NAME

Dist::Zilla::PluginBundle::Author::IOANR - Build dists the way IOANR likes

# VERSION

version 1.172320

# OPTIONS

## `fake_release`

Doesn't commit or release anything

```
fake_release = 1
```

## `disable`

Specify plugins to disable. Can be specified multiple times.

```
disable = Some::Plugin
disable = Another::Plugin
```

## `assert_os`

Use [Devel::AssertOS](https://metacpan.org/pod/Devel::AssertOS) to control which platforms this dist will build on.
Can be specified multiple times.

```
assert_os = Linux
```

## `custom_builder`

If `custom_builder` is set, [Module::Build](https://metacpan.org/pod/Module::Build) will be used instead of
[Module::Build::Tiny](https://metacpan.org/pod/Module::Build::Tiny) with a custom build class set to `My::Builder`

## `semantic_version`

If `semantic_version` is true (the default), git tags will be in the form
`^v(\d+\.\d+\.\d+)$`. Otherwise they will be `^v(\d+\.\d+)$`.

# BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at [https://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR/issues](https://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR/issues).

# AVAILABILITY

The project homepage is [http://search.cpan.org/dist/Dist-Zilla-PluginBundle-Author-IOANR/](http://search.cpan.org/dist/Dist-Zilla-PluginBundle-Author-IOANR/).

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit [http://www.perl.com/CPAN/](http://www.perl.com/CPAN/) to find a CPAN
site near you, or see [https://metacpan.org/module/Dist::Zilla::PluginBundle::Author::IOANR/](https://metacpan.org/module/Dist::Zilla::PluginBundle::Author::IOANR/).

# SOURCE

The development version is on github at [http://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR](http://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR)
and may be cloned from [git://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR.git](git://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR.git)

# AUTHOR

Ioan Rogers <ioanr@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Ioan Rogers.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.
