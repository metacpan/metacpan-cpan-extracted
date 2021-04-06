use v5.20.0;
use warnings;
package Pod::Weaver::PluginBundle::RJBS;
# ABSTRACT: RJBS's default Pod::Weaver config
$Pod::Weaver::PluginBundle::RJBS::VERSION = '5.015';
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
  my ($self, $arg) = @_;

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

  if (my $perl_support = $Dist::Zilla::PluginBundle::RJBS::perl_support) {
    push @plugins, $self->_perl_support_plugin($perl_support);
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

my %SUPPORT;

$SUPPORT{toolchain} = <<'END';
This module is part of CPAN toolchain, or is treated as such.  As such, it
follows the agreement of the Perl Toolchain Gang to require no newer version of
perl than v5.8.1.  This version may change by agreement of the Toolchain Gang,
but for now is governed by the L<Lancaster
Consensus|https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/lancaster-consensus.md>
of 2013.
END

my $STOCK = <<'END';
Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.
END

$SUPPORT{extreme} = <<"END";
This module has an extremely long-term perl support period.  That means it will
not require a version of perl released fewer than ten years ago.

$STOCK
END

$SUPPORT{longterm} = <<"END";
This module has a long-term perl support period.  That means it will not
require a version of perl released fewer than five years ago.

$STOCK
END

$SUPPORT{standard} = <<"END";
This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

$STOCK
END

# To be used almost exclusively on stuff that I write for my own use and ship
# to CPAN as a matter of convenience, rather than for libraries I expect to
# become part of anyone's software stack. -- rjbs, 2021-04-03
$SUPPORT{'no-mercy'} = <<"END";
This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is no
promise that patches will be accepted to lower the minimum required perl.
END

sub _perl_support_plugin {
  my ($self, $name) = @_;

  Carp::confess("unknown perl support level $name") unless exists $SUPPORT{$name};

  return [
    '@RJBS/PerlSupport',
    _exp('GenerateSection'),
    {
      title  => 'PERL VERSION SUPPORT',
      text   => [ split /\n/, $SUPPORT{$name} ],
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

version 5.015

=head1 OVERVIEW

I<Roughly> equivalent to:

=over 4

=item *

C<@Default>

=item *

C<-Transformer> with L<Pod::Elemental::Transformer::List>

=back

=head1 PERL VERSION SUPPORT

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is no
promise that patches will be accepted to lower the minimum required perl.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
