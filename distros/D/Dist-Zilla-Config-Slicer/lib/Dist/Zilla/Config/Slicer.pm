# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-Config-Slicer
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::Config::Slicer;
# git description: v0.200-6-g8420185

our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: Config::MVP::Slicer customized for Dist::Zilla
$Dist::Zilla::Config::Slicer::VERSION = '0.201';
use Config::MVP::Slicer ();
use Dist::Zilla::Util 4 ();
use Moose;

extends 'Config::MVP::Slicer';

sub _build_match_package {
  # NOTE: Dist::Zilla::Util 4.3 claims this method "is likely to change go away"
  return sub { Dist::Zilla::Util->expand_config_package_name($_[0]) eq $_[1] };
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS cpan testmatrix url annocpan anno bugtracker
rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::Config::Slicer - Config::MVP::Slicer customized for Dist::Zilla

=head1 VERSION

version 0.201

=head1 SYNOPSIS

  my $slicer = Dist::Zilla::Config::Slicer->new({
    config => $section->{payload},
  });

  $slicer->merge($plugin);

=head1 DESCRIPTION

This is a subclass of L<Config::MVP::Slicer>
that overrides the default
L<match_package|Config::MVP::Slicer/match_package>
to expand packages according to L<Dist::Zilla>'s rules.

=for test_synopsis my ($section, $plugin);

=head1 SEE ALSO

=over 4

=item *

L<Config::MVP::Slicer>

=item *

L<Dist::Zilla::Role::PluginBundle::Config::Slicer>

A role to consume in your own C<PluginBundle>
to automatically enable config slicing.

=item *

L<Dist::Zilla::PluginBundle::ConfigSlicer>

A C<PluginBundle> that combines L<< @Filter|Dist::Zilla::PluginBundle::Filter >>
with L<Dist::Zilla::Role::PluginBundle::Config::Slicer|Dist::Zilla::Role::PluginBundle::Config::Slicer>
so you can override the configuration for a bundle
that doesn't have config slicing built in.

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Config::Slicer

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-Config-Slicer>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-config-slicer at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Config-Slicer>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Dist-Zilla-Config-Slicer>

  git clone https://github.com/rwstauner/Dist-Zilla-Config-Slicer.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
