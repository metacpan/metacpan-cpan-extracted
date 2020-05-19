use strict;
use warnings;
package Pod::Weaver::PluginBundle::MMCCLIMON;
# ABSTRACT: MMCCLIMON's default Pod::Weaver config
$Pod::Weaver::PluginBundle::MMCCLIMON::VERSION = '5.013';
#pod =head1 OVERVIEW
#pod
#pod Blatantly stolen from RJBS.  I<Roughly> equivalent to:
#pod
#pod =for :list
#pod * C<@Default>
#pod * C<-Transformer> with L<Pod::Elemental::Transformer::List>
#pod
#pod =cut

use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
  my @plugins;
  push @plugins, (
    [ '@MMCCLIMON/CorePrep',       _exp('@CorePrep'),        {} ],
    [ '@MMCCLIMON/SingleEncoding', _exp('-SingleEncoding'),  {} ],
    [ '@MMCCLIMON/Name',           _exp('Name'),             {} ],
    [ '@MMCCLIMON/Version',        _exp('Version'),          {} ],

    [ '@MMCCLIMON/Prelude',     _exp('Region'),  { region_name => 'prelude'     } ],
    [ '@MMCCLIMON/Synopsis',    _exp('Generic'), { header      => 'SYNOPSIS'    } ],
    [ '@MMCCLIMON/Description', _exp('Generic'), { header      => 'DESCRIPTION' } ],
    [ '@MMCCLIMON/Overview',    _exp('Generic'), { header      => 'OVERVIEW'    } ],

    [ '@MMCCLIMON/Stability',   _exp('Generic'), { header      => 'STABILITY'   } ],
  );

  for my $plugin (
    [ 'Attributes', _exp('Collect'), { command => 'attr'   } ],
    [ 'Methods',    _exp('Collect'), { command => 'method' } ],
    [ 'Functions',  _exp('Collect'), { command => 'func'   } ],
  ) {
    $plugin->[2]{header} = uc $plugin->[0];
    push @plugins, $plugin;
  }

  push @plugins, (
    [ '@MMCCLIMON/Leftovers', _exp('Leftovers'), {} ],
    [ '@MMCCLIMON/postlude',  _exp('Region'),    { region_name => 'postlude' } ],
    [ '@MMCCLIMON/Authors',   _exp('Authors'),   {} ],
    [ '@MMCCLIMON/Contributors', _exp('Contributors'), {} ],
    [ '@MMCCLIMON/Legal',     _exp('Legal'),     {} ],
    [ '@MMCCLIMON/List',      _exp('-Transformer'), { 'transformer' => 'List' } ],
  );

  return @plugins;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::MMCCLIMON - MMCCLIMON's default Pod::Weaver config

=head1 VERSION

version 5.013

=head1 OVERVIEW

Blatantly stolen from RJBS.  I<Roughly> equivalent to:

=over 4

=item *

C<@Default>

=item *

C<-Transformer> with L<Pod::Elemental::Transformer::List>

=back

=head1 AUTHOR

Michael McClimon <michael@mcclimon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Michael Mcclimon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
