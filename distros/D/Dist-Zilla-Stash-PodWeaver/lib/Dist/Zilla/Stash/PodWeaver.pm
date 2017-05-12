# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-Stash-PodWeaver
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::Stash::PodWeaver;
{
  $Dist::Zilla::Stash::PodWeaver::VERSION = '1.005';
}
# git description: v1.004-1-gfd36825

BEGIN {
  $Dist::Zilla::Stash::PodWeaver::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: A stash of config options for Pod::Weaver

use Pod::Weaver::Config::Assembler ();
use Moose;

# bug fix for attribute order
with 'Dist::Zilla::Role::Stash::Plugins' => { -version => 1.006 };


sub expand_package {
  my ( $self, $pack ) = @_;
  # Cannot start an ini line with '='
  $pack =~ s/^\+/=/;
  Pod::Weaver::Config::Assembler->expand_package($pack);
}

1;

__END__

=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS PluginBundles PluginName dists zilla
dist-zilla Flibberoloo ini cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::Stash::PodWeaver - A stash of config options for Pod::Weaver

=head1 VERSION

version 1.005

=head1 SYNOPSIS

  # dist.ini

  [@YourFavoritePluginBundle]

  [%PodWeaver]
  -StopWords.include = WordsIUse ThatAreNotWords

=head1 DESCRIPTION

This performs the L<Dist::Zilla::Role::Stash> role
(using L<Dist::Zilla::Role::DynamicConfig>
and    L<Dist::Zilla::Role::Stash::Plugins>).

When using L<Dist::Zilla::Plugin::PodWeaver>
with a I<config_plugin> it's difficult to pass more
configuration options to L<Pod::Weaver> plugins.

This is often the case when using a
L<Dist::Zilla::PluginBundle|Dist::Zilla::Role::PluginBundle>
that uses a
L<Pod::Weaver::PluginBundle|Pod::Weaver::PluginBundle::Default>.

This stash is intended to allow you to set other options in your F<dist.ini>
that can be accessed by L<Pod::Weaver> plugins.

Because you know how you like your dists built,
(and you're using PluginBundles to do it)
but you need a little extra customization.

=head1 USAGE

The attributes should be separated from the plugin name with a dot:
C<PluginName.attributes>.
The PluginName will be passed to
C<< Pod::Weaver::Config::Assembler->expand_package() >>
so the PluginName should include the leading character
to identify its type:

=over 4

=item *

C<> (no character) (Pod::Weaver::Section::I<Name>)

=item *

C<-> Plugin (Pod::Weaver::Plugin::I<Name>)

=item *

C<@> Bundle (Pod::Weaver::PluginBundle::I<Name>)

=item *

C<+> Full Package Name (I<Name>)

An ini config line cannot start with an I< = >
so this module will convert any lines that start with I< + > to I< = >.

=back

For example

  Complaints.use_fake_email = 1

Would set the 'use_fake_email' attribute to '1'
for the [fictional] I<Pod::Weaver::Section::Complaints> plugin.

  -StopWords.include = Flibberoloo

Would add 'Flibberoloo' to the list of stopwords
added by the L<Pod::Weaver::Plugin::StopWords> plugin.

  +Some::Other::Module.silly = 1

Would set the 'silly' flag to true on I<Some::Other::Module>.

=head1 METHODS

=head2 expand_package

Expand shortened package monikers to the full package name.

Changes leading I<+> to I<=> and then passes the value to
I<expand_package> in L<Pod::Weaver::Config::Assembler>.

See L</USAGE> for a description.

=head1 BUGS AND LIMITATIONS

=over

=item *

Arguments can only be specified in a F<dist.ini> stash once,
even if the plugin would normally allow multiple entries
in a F<weaver.ini>.  Since the arguments are dynamic (unknown to the class)
the class cannot specify which arguments should accept multiple values.

To work around this you can add brackets (and subscripts)
to config lines to specify that an attribute is an array:

  Plugin.attr[0] = first
  Plugin.attr[1] = second

See L<Config::MVP::Slicer/CONFIGURATION SYNTAX> for more information.

=item *

Including the package name gives the options a namespace
(instead of trying to set the I<include> attribute for 2 different plugins).

Unfortunately this does not automatically set the options on the plugins.
The plugins need to know to use this stash.

So if you'd like to be able to use this stash with a L<Pod::Weaver>
plugin that doesn't support it, please contact that plugin's author(s)
and let them know about this module.

If you are a L<Pod::Weaver> plugin author,
have a look at
L<Dist::Zilla::Role::Stash::Plugins/get_stashed_config> and
L<Dist::Zilla::Role::Stash::Plugins/merge_stashed_config>
to see easy ways to get values from this stash.

Please contact me (and/or send patches) if something doesn't work
like you think it should.

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Stash::PodWeaver

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Stash-PodWeaver>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Stash-PodWeaver>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Stash-PodWeaver>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Stash-PodWeaver>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Stash-PodWeaver>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Stash::PodWeaver>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-stash-podweaver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Stash-PodWeaver>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Dist-Zilla-Stash-PodWeaver>

  git clone https://github.com/rwstauner/Dist-Zilla-Stash-PodWeaver.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
