# NAME

Dist::Zilla::PluginBundle::IDOPEREL - IDOPEREL's plugin bundle for Dist::Zilla.

# SYNOPSIS

In your dist.ini file:

        [@IDOPEREL]

# DESCRIPTION

This module is a bundle of plugins for [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) that is regularly
used by me (Ido Perlmuter). If you find it suits your needs, feel free
to install and use it.

This bundle provides the following plugins and bundles:

      [@Filter]
      -bundle = @Basic
      -remove = Readme

      [@Git]

      [VersionFromModule]
      [AutoPrereqs]
      [CheckChangesHasContent]
      [Test::DistManifest]
      [GitHub::Meta]
      [InstallGuide]
      [MetaJSON]
      [MinimumPerl]
      [NextRelease]
      [ReadmeFromPod]
      [TestRelease]
      [Signature]

      [ReadmeAnyFromPod]
      type = markdown
      filename = README.md
      location = build

      [CopyFilesFromBuild]
      copy = README.md

      [Encoding]
      encoding = bytes
      match = \.(jpg|png|gif|gz|zip)$

# INTERNAL METHODS

## configure

# AUTHOR

Ido Perlmuter, `<ido at ido50.net>`

# BUGS

Please report any bugs or feature requests to `bug-dist-zilla-pluginbundle-idoperel at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-PluginBundle-IDOPEREL](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-PluginBundle-IDOPEREL). I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

        perldoc Dist::Zilla::PluginBundle::IDOPEREL

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-IDOPEREL](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-IDOPEREL)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Dist-Zilla-PluginBundle-IDOPEREL](http://annocpan.org/dist/Dist-Zilla-PluginBundle-IDOPEREL)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-IDOPEREL](http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-IDOPEREL)

- Search CPAN

    [http://search.cpan.org/dist/Dist-Zilla-PluginBundle-IDOPEREL/](http://search.cpan.org/dist/Dist-Zilla-PluginBundle-IDOPEREL/)

# LICENSE AND COPYRIGHT

Copyright 2010-2016 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
