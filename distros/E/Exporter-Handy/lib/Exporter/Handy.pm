package Exporter::Handy;

use utf8;
use strict;
use warnings;

# ABSTRACT: An EXPERIMENTAL subclass of <Exporter::Extensible>, which helps create easy-to-extend modules that export symbols
our $VERSION = '0.200000';

use Exporter::Extensible -exporter_setup => 1;

sub xtags : Export {
  require Exporter::Handy::Util;
  Exporter::Handy::Util::xtags({ sig => ':' }, @_)
}


# PRAGMATA
# Remember: Pragmas effect the current compilation context.
# No need to keep track of where we are importing into...
# They require their ->import() method to be called directly, no matter how deep the call stack happens to be.
# Just call ->import() directly, like below, and it will do the right thing.
sub strict      : Export(-) { strict->import   }
sub warnings    : Export(-) { warnings->import }
sub utf8        : Export(-) { utf8->import     }

sub strictures  : Export(-) {
  strict->import;
  warnings->import
}

sub sane : Export(-) {
  utf8->import;
  strict->import;
  warnings->import;
}


# use Exporter::Handy qw(-sane -features), exporter_setup => 1;
sub features {  # :Export(-?) syntax was not working before version 0.11 of Exporter::Extensible
  my ($exporter, $arg)= @_;

  # default features to turn on/off
  my %feats = (
    'current_sub'     => 1, # Perl v5.16+ (2012) : enable __SUB__ token that returns a ref to the current subroutine (or undef).
    'evalbytes'       => 1, # Perl v5.16+ (2012) : like string eval, but it treats its argument as a byte string.
    'fc'              => 1, # Perl v5.16+ (2012) : enable the fc function (Unicode casefolding).
    'lexical_subs'    => 1, # Perl v5.18+ (2012) : enable declaration of subroutines via my sub foo, state sub foo and our sub foo syntax.
    'say'             => 1, # Perl v5.10+ (2007) : enable the Raku-inspired "say" function.
    'state'           => 1, # Perl v5.10+ (2007) : enable state variables.
    'unicode_eval'    => 1, # Perl v5.16+ (2012) : changes the behavior of plain string eval to work more consistently, especially in the Unicode world.
    'unicode_strings' => 1, # Perl v5.12+ (2010) : use Unicode rules in all string operations (unless either use locale or use bytes are also within the scope).
  );

  my @args = eval { @$arg };  # if $arg is an ARRAY-ref, than it denotes a list of features
  my %args = eval { %$arg };  # if $arg is a HASH-ref, then it denotes individual overrides (1: on, 0:off)

  if (@args) {
    if ($args[0] eq '+') { # request to keep defaults.
      shift @args;
      %args = map { $_ => 1 } @args;
    } else {              # replace defaults
      %feats =  map { $_ => 1 } @args;
    }
  }

  # handle individual overrides
  %feats = (%feats, %args);

  return unless %feats;

  # determine features to be turned ON or OFF
  my (@on, @off);
  for (keys %feats) {
    next if m/^-/;  # ignore inline args à la <Exporter::Extensible>, if any: -prefix, -as, ...

    if (defined $feats{$_} && $feats{$_}) {
      push @on, $_;
    } else {
      push @off, $_;
    }
  }

  # Do the actual work
  require feature;
  feature->import(@on) if @on;
  feature->unimport(@off) if @off;
}
__PACKAGE__->exporter_register_option('features', \&features, '?');

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Tabulo[n] cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto
metadata placeholders metacpan

=head1 NAME

Exporter::Handy - An EXPERIMENTAL subclass of <Exporter::Extensible>, which helps create easy-to-extend modules that export symbols

=head1 VERSION

version 0.200000

=head1 SYNOPSIS

Define a module with exports

  package My::Utils;
  use Exporter::Handy -exporter_setup => 1;

  export(qw( foo $x @STUFF -strict_and_warnings ), ':baz' => ['foo'] );

  sub foo { ... }

  sub strict_and_warnings {
    strict->import;
    warnings->import;
  }

Create a new module which exports all that, and more

  package My::MoreUtils;
  use My::Utils -exporter_setup => 1;
  sub util_fn3 : Export(:baz) { ... }

Use the module

  use My::MoreUtils qw( -strict_and_warnings :baz @STUFF );
  # Use the exported things
  push @STUFF, foo(), util_fn3();

=head1 DESCRIPTION

This module is currently EXPERIMENTAL. You are advised to restrain from using it.

You have been warned.

=head1 FUNCTIONS

=head2 xtags

Build one or more B<export tags> suitable for L<Exporter::Handy>, L<Exporter::Extensible> and co.

    use Exporter::Handy -exporter_setup => 1, xtags;

    export(
        foo
        baz
        xtags(
          bar => [qw( $bozo @baza boom )],
        ),
    );

=head1 OPTIONS

=head2 strict, warnings, feature, utf8

The below statement:

    use Exporter::Handy -strict;

is equivalent to:
    use Exporter::Handy;
    use strict;

Same thing for "feature", "warnings", "utf8";

=head2 strictures

The below statement:

    use Exporter::Handy -strictures;

is equivalent to:
    use Exporter::Handy;
    use strict;
    use warnings;

=head2 sane

The below statement:

    use Exporter::Handy -sane;

is equivalent to:
    use Exporter::Handy;
    use strict;
    use warnings;

=head2 features

The below statement:

    use Exporter::Handy -features;

is equivalent to:
    use Exporter::Handy;
    use feature (
      'current_sub',      # Perl v5.16+ (2012) : enable __SUB__ token that returns a ref to the current subroutine (or undef).
      'evalbytes',        # Perl v5.16+ (2012) : like string eval, but it treats its argument as a byte string.
      'fc',               # Perl v5.16+ (2012) : enable the fc function (Unicode casefolding).
      'lexical_subs',     # Perl v5.18+ (2012) : enable declaration of subroutines via my sub foo, state sub foo and our sub foo syntax.
      'say',              # Perl v5.10+ (2007) : enable the Raku-inspired "say" function.
      'state',            # Perl v5.10+ (2007) : enable state variables.
      'unicode_eval',     # Perl v5.16+ (2012) : changes the behavior of plain string eval to work more consistently, especially in the Unicode world.
      'unicode_strings',  # Perl v5.12+ (2010) : use Unicode rules in all string operations (unless either use locale or use bytes are also within the scope).
    );

whereas the below statement:

    use Exporter::Handy -features => [qw(say)];

is equivalent to:

    use Exporter::Handy;
    use feature (
      'say',              # Perl v5.10+ (2007) : enable the Raku-inspired "say" function.
    );

=head1 AUTHORS

Tabulo[n] <dev@tabulo.net>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/tabulon-perl/p5-Exporter-Handy/issues>.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/tabulon-perl/p5-Exporter-Handy>

  git clone https://github.com/tabulon-perl/p5-Exporter-Handy.git

=head1 CONTRIBUTOR

=for stopwords Tabulo

Tabulo <dev-git.perl@tabulo.net>

=head1 LEGAL

This software is copyright (c) 2023 by Tabulo[n].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
