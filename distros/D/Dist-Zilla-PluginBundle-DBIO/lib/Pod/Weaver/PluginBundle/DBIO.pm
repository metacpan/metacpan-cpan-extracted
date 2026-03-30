package Pod::Weaver::PluginBundle::DBIO;
# ABSTRACT: Pod::Weaver configuration for DBIO distributions
our $VERSION = '0.900001';
use strict;
use warnings;


use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
  my ($self, $args) = @_;
  my $heritage = ($args->{payload} && $args->{payload}{heritage}) || 0;

  my @plugins;
  push @plugins, (
    [ '@DBIO/CorePrep',       _exp('@CorePrep'),       {} ],
    [ '@DBIO/SingleEncoding', _exp('-SingleEncoding'),  {} ],
    [ '@DBIO/Name',           _exp('Name'),             {} ],
    [ '@DBIO/Version',        _exp('Version'),          {} ],

    [ '@DBIO/Prelude',     _exp('Region'),  { region_name => 'prelude'     } ],
    [ '@DBIO/Synopsis',    _exp('Generic'), { header      => 'SYNOPSIS'    } ],
    [ '@DBIO/Description', _exp('Generic'), { header      => 'DESCRIPTION' } ],
    [ '@DBIO/Overview',    _exp('Generic'), { header      => 'OVERVIEW'    } ],
    [ '@DBIO/Stability',   _exp('Generic'), { header      => 'STABILITY'   } ],

    [ '@DBIO/Attributes', _exp('Collect'), {
      header  => 'ATTRIBUTES',
      command => 'attr',
    } ],
    [ '@DBIO/Methods', _exp('Collect'), {
      header  => 'METHODS',
      command => 'method',
    } ],

    [ '@DBIO/Leftovers', _exp('Leftovers'), {} ],
    [ '@DBIO/Postlude',  _exp('Region'),    { region_name => 'postlude' } ],
    [ '@DBIO/Authors',   _exp('Authors'),   {} ],

    [ '@DBIO/Legal', _exp('GenerateSection'), {
      title       => 'COPYRIGHT AND LICENSE',
      is_template => 0,
      text        => [
        'Copyright (C) 2026 DBIO Authors',
        ($heritage ? (
          'Portions Copyright (C) 2005-2025 DBIx::Class Authors',
          'Based on DBIx::Class, heavily modified.',
        ) : ()),
        '',
        'This is free software; you can redistribute it and/or modify it under',
        'the same terms as the Perl 5 programming language system itself.',
      ],
    } ],
  );

  return @plugins;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::DBIO - Pod::Weaver configuration for DBIO distributions

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

Via L<Dist::Zilla::PluginBundle::DBIO> (automatic):

  [@DBIO]

Or explicitly:

  [PodWeaver]
  config_plugin = @DBIO

=head1 DESCRIPTION

L<Pod::Weaver> configuration for all DBIO distributions. Supports
inline C<=attr> and C<=method> commands that are collected into
B<ATTRIBUTES> and B<METHODS> sections.

=head1 COMMANDS

=head2 =attr

Documents attributes. Place after C<has> declarations.
Collected into an B<ATTRIBUTES> section.

=head2 =method

Documents methods. Place after C<sub> definitions.
Collected into a B<METHODS> section.

=head1 COPYRIGHT NOTICE

Default (new DBIO code):

  Copyright (C) 2026 DBIO Authors

With C<heritage = 1> (code derived from DBIx::Class):

  Copyright (C) 2026 DBIO Authors
  Portions Copyright (C) 2005-2025 DBIx::Class Authors
  Based on DBIx::Class, heavily modified.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
