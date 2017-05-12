use strict;
use warnings;
package Pod::Weaver::PluginBundle::RJBS;
# ABSTRACT: RJBS's default Pod::Weaver config
$Pod::Weaver::PluginBundle::RJBS::VERSION = '5.010';
#pod =head1 OVERVIEW
#pod
#pod I<Roughly> equivalent to:
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
    [ '@RJBS/CorePrep',       _exp('@CorePrep'),        {} ],
    [ '@RJBS/SingleEncoding', _exp('-SingleEncoding'),  {} ],
    [ '@RJBS/Name',           _exp('Name'),             {} ],
    [ '@RJBS/Version',        _exp('Version'),          {} ],

    [ '@RJBS/Prelude',     _exp('Region'),  { region_name => 'prelude'     } ],
    [ '@RJBS/Synopsis',    _exp('Generic'), { header      => 'SYNOPSIS'    } ],
    [ '@RJBS/Description', _exp('Generic'), { header      => 'DESCRIPTION' } ],
    [ '@RJBS/Overview',    _exp('Generic'), { header      => 'OVERVIEW'    } ],

    [ '@RJBS/Stability',   _exp('Generic'), { header      => 'STABILITY'   } ],
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
    [ '@RJBS/Leftovers', _exp('Leftovers'), {} ],
    [ '@RJBS/postlude',  _exp('Region'),    { region_name => 'postlude' } ],
    [ '@RJBS/Authors',   _exp('Authors'),   {} ],
    [ '@RJBS/Contributors', _exp('Contributors'), {} ],
    [ '@RJBS/Legal',     _exp('Legal'),     {} ],
    [ '@RJBS/List',      _exp('-Transformer'), { 'transformer' => 'List' } ],
  );

  return @plugins;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::RJBS - RJBS's default Pod::Weaver config

=head1 VERSION

version 5.010

=head1 OVERVIEW

I<Roughly> equivalent to:

=over 4

=item *

C<@Default>

=item *

C<-Transformer> with L<Pod::Elemental::Transformer::List>

=back

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
