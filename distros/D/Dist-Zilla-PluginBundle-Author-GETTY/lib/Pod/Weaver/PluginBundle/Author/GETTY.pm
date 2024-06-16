use strict;
use warnings;
package Pod::Weaver::PluginBundle::Author::GETTY;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: GETTY's default Pod::Weaver config
$Pod::Weaver::PluginBundle::Author::GETTY::VERSION = '0.115';

use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
  my @plugins;
  push @plugins, (
    [ '@GETTY/CorePrep',    _exp('@CorePrep'), {} ],
    [ '@GETTY/Name',        _exp('Name'),      {} ],
    [ '@GETTY/Version',     _exp('Version'),   {} ],

    [ '@GETTY/Prelude',     _exp('Region'),  { region_name => 'prelude'     } ],
    [ '@GETTY/Synopsis',    _exp('Generic'), { header      => 'SYNOPSIS'    } ],
    [ '@GETTY/Description', _exp('Generic'), { header      => 'DESCRIPTION' } ],
    [ '@GETTY/Overview',    _exp('Generic'), { header      => 'OVERVIEW'    } ],

    [ '@GETTY/Stability',   _exp('Generic'), { header      => 'STABILITY'   } ],
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
    [ '@GETTY/Leftovers', _exp('Leftovers'), {} ],
    [ '@GETTY/postlude',  _exp('Region'),    { region_name => 'postlude' } ],
    [ '@GETTY/Bugs',      _exp('Bugs'),   {} ],
    [ '@GETTY/Authors',   _exp('Authors'),   {} ],
    [ '@GETTY/Legal',     _exp('Legal'),     {} ],
    [ '@GETTY/List',      _exp('-Transformer'), { 'transformer' => 'List' } ],
  );

  return @plugins;
}

1;

__END__

=pod

=head1 NAME

Pod::Weaver::PluginBundle::Author::GETTY - GETTY's default Pod::Weaver config

=head1 VERSION

version 0.115

=head1 DESCRIPTION

So far just a fork of L<Pod::Weaver::PluginBundle::RJBS>

=head1 OVERVIEW

Roughly equivalent to:

=over 4

=item *

C<@Default>

=item *

C<-Transformer> with L<Pod::Elemental::Transformer::List>

=back

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
