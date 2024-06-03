use v5.34.0;
use Dist::Zilla::Pragmas;
package Pod::Weaver::PluginBundle::RJBS 5.031;
# ABSTRACT: RJBS's default Pod::Weaver config

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
sub _exp ($self) { Pod::Weaver::Config::Assembler->expand_package($self) }

sub mvp_bundle_config ($self, $arg) {
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

  if (my $perl_window = $Dist::Zilla::PluginBundle::RJBS::perl_window) {
    push @plugins, $self->_perl_window_plugin($perl_window);
  }

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

my %WINDOW;

$WINDOW{none} = <<~'END';
  This code is effectively abandonware.  Although releases will sometimes be
  made to update contact info or to fix packaging flaws, bug reports will
  mostly be ignored.  Feature requests are even more likely to be ignored.  (If
  someone takes up maintenance of this code, they will presumably remove this
  notice.) This means that whatever version of perl is currently required is
  unlikely to change -- but also that it might change at any new maintainer's
  whim.
  END

my $STOCK = <<~'END';
  Although it may work on older versions of perl, no guarantee is made that the
  minimum required version will not be increased.  The version may be increased
  for any reason, and there is no promise that patches will be accepted to
  lower the minimum required perl.
  END

$WINDOW{toolchain} = <<~"END";
  This module is part of CPAN toolchain, or is treated as such.  As such, it
  follows the agreement of the Perl Toolchain Gang to require no newer version
  of perl than one released in the last ten years.  This version may change by
  agreement of the Toolchain Gang, but for now is governed by the L<Lancaster
  Consensus|https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/lancaster-consensus.md>
  of 2013 and the Lyon Amendment of 2023 (described at the linked-to document).

  $STOCK
  END

$WINDOW{extreme} = <<~"END";
  This library should run on perls released even an extremely long time ago.  It
  should work on any version of perl released in the last ten years.

  $STOCK
  END

$WINDOW{'long-term'} = <<~"END";
  This library should run on perls released even a long time ago.  It should
  work on any version of perl released in the last five years.

  $STOCK
  END

$WINDOW{standard} = <<~"END";
  This module should work on any version of perl still receiving updates from
  the Perl 5 Porters.  This means it should work on any version of perl
  released in the last two to three years.  (That is, if the most recently
  released version is v5.40, then this module should work on both v5.40 and
  v5.38.)

  $STOCK
  END

# To be used almost exclusively on stuff that I write for my own use and ship
# to CPAN as a matter of convenience, rather than for libraries I expect to
# become part of anyone's software stack. -- rjbs, 2021-04-03
$WINDOW{'no-mercy'} = <<~"END";
  This module is shipped with no promise about what version of perl it will
  require in the future.  In practice, this tends to mean "you need a perl from
  the last three years," but you can't rely on that.  If a new version of perl
  ship, this software B<may> begin to require it for any reason, and there is
  no promise that patches will be accepted to lower the minimum required perl.
  END

sub _perl_window_plugin ($self, $name) {
  Carp::confess("unknown perl window $name") unless exists $WINDOW{$name};

  return [
    '@RJBS/PerlSupport',
    _exp('GenerateSection'),
    {
      title  => 'PERL VERSION',
      text   => [ split /\n/, $WINDOW{$name} ],
    }
  ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::RJBS - RJBS's default Pod::Weaver config

=head1 VERSION

version 5.031

=head1 OVERVIEW

I<Roughly> equivalent to:

=over 4

=item *

C<@Default>

=item *

C<-Transformer> with L<Pod::Elemental::Transformer::List>

=back

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
