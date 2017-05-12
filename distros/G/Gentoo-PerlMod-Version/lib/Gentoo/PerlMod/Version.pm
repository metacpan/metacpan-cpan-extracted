use 5.006;
use strict;
use warnings;

package Gentoo::PerlMod::Version;

our $VERSION = 'v0.8.1';

# ABSTRACT: Convert arbitrary Perl Modules' versions into normalized Gentoo versions.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Sub::Exporter::Progressive -setup => { exports => [qw( gentooize_version )] };
use version 0.77;

sub gentooize_version {
  my ( $perlver, $config ) = @_;
  $config ||= {};
  if ( not defined $perlver ) {
    return _err_perlver_undefined($config);
  }
  $config->{lax} = 0 unless defined $config->{lax};
  if ( _env_hasopt('always_lax') ) {
    $config->{lax} = _env_getopt('always_lax');
  }

  if ( $perlver =~ /\Av?[\d.]+\z/msx ) {
    return _lax_cleaning_0($perlver);
  }

  if ( $perlver =~ /\Av?[\d._]+(-TRIAL)?\z/msx ) {
    if ( $config->{lax} > 0 ) {
      return _lax_cleaning_1($perlver);
    }
    return _err_matches_trial_regex_nonlax( $perlver, $config );
  }

  if ( 2 == $config->{lax} ) {
    return _lax_cleaning_2($perlver);
  }
  return _err_not_decimal_or_trial( $perlver, $config );
}

###
#
# character to code translation
#
###

## no critic ( ProhibitMagicNumbers )
my $char_map = {
  ( map { $_ => $_ } 0 .. 9 ),    # 0..9
  ( map { chr( $_ + 65 ) => $_ + 10 } 0 .. 25 ),    # A-Z
  ( map { chr( $_ + 97 ) => $_ + 10 } 0 .. 25 ),    # a-z
};

# _code_for('z') -> $number
#

sub _code_for {
  my $char = shift;
  if ( not exists $char_map->{$char} ) {
    my $char_ord = ord $char;
    return _err_bad_char( $char, $char_ord );
  }
  return $char_map->{$char};
}

###
#
# Pair to number transformation.
#
#   _enc_pair( 'x','y' ) ->  $number
#
##

sub _enc_pair {
  my (@tokens) = @_;
  if ( not @tokens ) {
    return q{};
  }
  if ( @tokens < 2 ) {
    return _code_for( shift @tokens );
  }
  return ( _code_for( $tokens[0] ) * 36 ) + ( _code_for( $tokens[1] ) );
}

###
#
#  String to dotted-decimal conversion
#
# $dotstring = _ascii_to_int("HELLOWORLD");
#
###
sub _ascii_to_int {
  my $string = shift;
  my @chars = split //msx, $string;
  my @output;

  while (@chars) {
    push @output, _enc_pair( splice @chars, 0, 2, () );
  }

  return join q{.}, @output;
}

#
# Handler for gentooize_version( ... { lax => 0 } )
#
sub _lax_cleaning_0 {
  my $version = shift;
  return _expand_numeric($version);
}

#
# Handler for gentooize_version( ... { lax => 1 } )
#

sub _lax_cleaning_1 {
  my $version       = shift;
  my $isdev         = 0;
  my $prereleasever = undef;

  if ( $version =~ s/-TRIAL\z//msx ) {
    $isdev = 1;
  }
  if ( $version =~ s/_(.*)\z/$1/msx ) {
    $prereleasever = "$1";
    $isdev         = 1;
    if ( $prereleasever =~ /_/msx ) {
      return _err_lax_multi_underscore($version);
    }
  }
  $version = _expand_numeric($version);
  if ($isdev) {
    $version .= '_rc';
  }
  return $version;
}

#
# Handler for gentooize_version( ... { lax => 2 } )
#

sub _lax_cleaning_2 {
  my $version = shift;
  my $istrial = 0;

  my $has_v = 0;

  if ( $version =~ s/-TRIAL\z//msx ) {
    $istrial = 1;
  }
  if ( $version =~ s/\Av//msx ) {
    $has_v = 1;
  }

  my @parts = split /([._])/msx, $version;
  my @out;
  for (@parts) {
    if (/\A[_.]\z/msx) {
      push @out, $_;
      next;
    }
    if (/\A\d\z/msx) {
      push @out, $_;
      next;
    }
    push @out, _ascii_to_int($_);
  }

  my $version_out = join q{}, @out;
  if ($istrial) {
    $version_out .= '-TRIAL';
  }
  if ($has_v) {
    $version_out = 'v' . $version_out;
  }
  return _lax_cleaning_1($version_out);
}

#
# Expands dotted decimal to a float, and then chunks the float.
#
# my $clean = _expand_numeric( $dirty );
#
sub _expand_numeric {
  my $perlver = shift;

  my $ver = version->parse($perlver)->normal;

  $ver =~ s/\Av//msx;    # strip leading v

  my @tokens = split /[.]/msx, $ver;
  my @out;

  for (@tokens) {
    s/\A0+([1-9])/$1/msx;    # strip leading 0's
    push @out, $_;
  }

  return join q{.}, @out;
}

BEGIN {
  for my $err (qw( perlver_undefined matches_trial_regex_nonlax not_decimal_or_trial bad_char lax_multi_underscore )) {
    my $code = sub {
      require Gentoo::PerlMod::Version::Error;
      my $sub = Gentoo::PerlMod::Version::Error->can($err);
      goto $sub;
    };
    ## no critic ( ProhibitNoStrict )
    no strict 'refs';
    *{ __PACKAGE__ . '::_err_' . $err } = $code;
  }
  for my $env (qw( opts hasopt getopt )) {
    my $code = sub {
      require Gentoo::PerlMod::Version::Env;
      my $sub = Gentoo::PerlMod::Version::Env->can($env);
      goto $sub;
    };
    ## no critic ( ProhibitNoStrict )

    no strict 'refs';
    *{ __PACKAGE__ . '::_env_' . $env } = $code;
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::PerlMod::Version - Convert arbitrary Perl Modules' versions into normalized Gentoo versions.

=head1 VERSION

version v0.8.1

=head1 SYNOPSIS

    use Gentoo::PerlMod::Version qw( :all );

    # http://search.cpan.org/~gmpassos/XML-Smart-1.6.9/
    say gentooize_version( '1.6.9' )  # 1.6.9

    http://search.cpan.org/~pip/Math-BaseCnv-1.6.A6FGHKE/

    say gentooize_version('1.6.A6FGHKE')   #  <-- death, this is awful

    # -- Work-In-Progress Features --

    say gentooize_version('1.6.A6FGHKE',{ lax => 1}) # <-- still death

    say gentooize_version('1.6.A6FGHKE',{ lax => 2}) # 1.6.366.556.632.14  # <-- the best we can do.

    say gentooize_version('1.9902-TRIAL')   #  <-- death, this is not so bad, but not a valid gentoo/stable version

    say gentooize_version('1.9902-TRIAL', { lax => 1 })   #  1.990.200_rc # <-- -TRIAL gets nuked, 'rc' is added.

=head1 DESCRIPTION

This module acts as a reference implementation of how Gentoo maps CPAN and Perl versions, and transforms
them into derived versions that are suitable for Gentoo dependency tracking.

Perl has several primary formats of versions, the most notable one being C<float> style versions, in the form
C<x.yyyyyyyyyyy> where the number of C<y>'s are arbitrary, and are interpreted as a floating point value.

That is, C<1.001> is B<NOT> the same as C<1.01> and C<1.1>

However, Gentoo's version scheme sees C<1.001> similar to C<1.001.000> which is similar to C<1.1.0> and thus,
similar to C<1.1>.

Obviously this will not do, because when somebody says they need C<< >=1.05 (g:1.5) >> expecting C<< 1.06 (g:1.6) >>, but instead
get C<< 1.009 (g:1.9) >>, things will break.

Hence, detection of these cases and normalizing them is essential:

  1.001 -> 1.1.0
  1.01  -> 1.10.0
  1.1   -> 1.100.0
  1.05  -> 1.50.0
  1.06  -> 1.60.0
  1.009 -> 1.9.0

  1.9.0 < 1.50.0 < 1.60.0

The simplest use of this library is with the shipped tool, C<gentoo-perlmod-version.pl>

  gentoo-perlmod-version.pl --oneshot 1.06  # 1.6.0

=head1 FUNCTIONS

=head2 gentooize_version

    my $normalized = gentooize_version( $weird_version )

gentooize_version tries hard to mangle a version that is part of a CPAN dist into a normalized form
for Gentoo, which can be used as the version number of the C<ebuild>, while storing the original upstream version in the
C<ebuild>.

    CPAN: Foo-Bar-Baz 1.5
    print gentooize_version('1.5');  # -> 1.500.0
    -> dev-perl/Foo-Bar-Baz-1.500.0.ebuild
    cat dev-perl/Foo-Bar-Baz-1.500.0.ebuild
    # ...
    # MODULE_VERSION="1.5"
    # ...

Normal behavior accepts only sane non-testing versions, i.e.:

    0.1         -> 0.001.0
    0.001       -> 0.1.0
    1.1         -> 1.001.0
    1.123.13    -> 1.123.13

Etc.

This uses L<< C<version.pm>|version >> to read versions and to normalize them.

    0.1    # 0.100.0
    0.01   # 0.10.0
    0.001  # 0.1.0
    0.0001 # 0.0.100

So assuming Perl can handle your versions, they can be normalized.

=head3 lax level 1

    my $normalized = gentooize_version( $werid_version, { lax => 1 } );

B<EXPERIMENTAL:> This feature is still in flux, and the emitted versions may change.

This adds one layer of laxativity, and permits parsing and processing of "Developer Release" builds.

    1.10-TRIAL  # 1.100.0_rc
    1.11-TRIAL  # 1.110.0_rc
    1.1_1       # 1.110.0_rc

=head3 lax level 2

    my $normalized = gentooize_version( $werid_version, { lax => 2 } );

B<EXPERIMENTAL:> This feature is still in flux, and the emitted versions may change.

This adds another layer of laxativity, and permits parsing and processing of packages with versions not officially supported by
Perl.

This means versions such as

    1.6.A       # 1.6.10
    1.6.AA      # 1.6.370
    1.6.AAA      # 1.6.370.10
    1.6.AAAA      # 1.6.370.370

    1.6.A6FGHKE # 1.6.366.556.632.14

This is performed by some really nasty tricks, and treats the ASCII portion like a set of pairs.

    1.6.A6.FG.HK.E

And each ASCII pair is treated like a Base36 number.

    0 -> 0
    ....
    9 -> 9
    A -> 10
    ...
    Z -> 35

A6 is thus

    10 * 36 + 6 => 366

As you can see, its really nasty, and hopefully its not needed.

=head1 ENVIRONMENT

This module recognizes the environment variable GENTOO_PERLMOD_VERSION_OPTS for a few features.

These are mostly useful for system wide or user-wide policies that may be applicable for using this module, depending on where
it is used.

This field is split by white-space and each token has a meaning.

=head2 always_lax

  GENTOO_PERLMOD_VERSION_OPTS+=" always_lax=0 "
  GENTOO_PERLMOD_VERSION_OPTS+=" always_lax=1 "
  GENTOO_PERLMOD_VERSION_OPTS+=" always_lax=2 "
  GENTOO_PERLMOD_VERSION_OPTS+=" always_lax   "# same as always_lax=1
  GENTOO_PERLMOD_VERSION_OPTS+=" -always_lax  "# unset always_lax

This environment setting, if specified, overrides any specification of "lax" in the code. If this specified more than once,
the right-most one applies.

Specifying C<-always_lax> will unset the setting, making it behave as if it had not been previously specified.

=head2 taint_safe

  GENTOO_PERLMOD_VERSION_OPTS+=" taint_safe  " #on
  GENTOO_PERLMOD_VERSION_OPTS+=" -taint_safe " #off

As it stands, this module only emits messages via STDOUT/STDERR when an error occurs. For diagnosis, sometimes user provided
data can appear in this output.

Specifying this option will remove the information as specified by the user where possible, to eliminate this risk if this
is a security issue for you.

It is not a guarantee of safety, but merely a tool you might find useful, depending on circumstances.

=head2 carp_debug

  GENTOO_PERLMOD_VERSION_OPTS+=" carp_debug " #on
  GENTOO_PERLMOD_VERSION_OPTS+=" -carp_debug " #off

Lots of information is passed to our internal carp proxy that could aid in debugging a future problem.
To see this information instead of the simple message that is usually sent to C<Carp>, enable this option.

B<Note:> As values in the hashes that would be printed can come from users, C<carp_debug> is ignored if C<taint_safe> is on.

=head1 THANKS

=over 4

=item Torsten Veller - Inspiration for this Module and all the work on Gentoo Perl.

=item Vincent Pit - For solving most of the real bugs in this code before people tried to use them.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
