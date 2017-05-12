use 5.006;
use strict;
use warnings;

package Gentoo::PerlMod::Version::Error;

our $VERSION = 'v0.8.1';

# ABSTRACT: Various error message and diagnostic bits.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

BEGIN {

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









sub perlver_undefined {
  my ($config) = @_;
  ## no critic ( RequireInterpolationOfMetachars )
  return _fatal(
    {
      code    => 'perlver_undefined',
      config  => $config,
      message => 'Argument \'$perlver\' to gentooize_version was undefined',
    },
  );
}







sub matches_trial_regex_nonlax {
  my ( $perlver, $config, ) = @_;
  return _fatal(
    {
      code                  => 'matches_trial_regex_nonlax',
      config                => $config,
      want_lax              => 1,
      message               => 'Invalid version format (non-numeric data, either _ or -TRIAL ).',
      message_extra_tainted => qq{ Version: >$perlver< },
      version               => $perlver,
    },
  );
}







sub not_decimal_or_trial {
  my ( $perlver, $config ) = @_;
  return _fatal(
    {
      code                  => 'not_decimal_or_trial',
      config                => $config,
      want_lax              => 2,
      message               => 'Invalid version format (non-numeric/ASCII data).',
      message_extra_tainted => qq{ Version: >$perlver< },
      version               => $perlver,
    },
  );
}







sub bad_char {
  my ( $char, $char_ord ) = @_;
  return _fatal(
    {
      code                  => 'bad_char',
      message               => 'A Character in the version is not in the ascii-to-int translation table.',
      message_extra_tainted => qq{ Missing character: $char ( $char_ord )},
    },
  );
}







sub lax_multi_underscore {
  my ($version) = @_;
  return _fatal(
    {
      code                  => 'lax_multi_underscore',
      message               => q{More than one _ in a version is not permitted},
      message_extra_tainted => qq{ Version: >$version< },
      version               => $version,
    },
  );
}
#
# _format_error({
#   code => "some_string",
#   message => "Some message"
#   message_extra_tainted => "And $tainted " # extra data for non-taint-safe envs.
#   want_lax => n # optional
# })
#

sub _format_error {
  my ($conf) = @_;
  my $message = $conf->{message};
  if ( exists $conf->{want_lax} ) {
    my $lax = $conf->{want_lax};
    $message .= qq{\n Set { lax => $lax } for more permissive behaviour. };
  }
  if ( _env_hasopt('taint_safe') ) {
    return $message;
  }
  if ( _env_hasopt('carp_debug') ) {
    $conf->{env_config} = _env_opts;
    require Data::Dumper;
    local $Data::Dumper::Indent    = 2;
    local $Data::Dumper::Purity    = 0;
    local $Data::Dumper::Useqq     = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Quotekeys = 0;
    return Data::Dumper::Dumper($conf);
  }
  if ( exists $conf->{'message_extra_tainted'} ) {
    $message .= $conf->{'message_extra_tainted'};
  }
  if ( exists $conf->{'stack'} ) {
    for ( @{ $conf->{stack} } ) {
      if ( $_->[0] !~ /\AGentoo::PerlMod::Version(?:|::Error|::Env)\z/msx ) {
        $message .= sprintf qq[\n - From %s in %s at line %s\n], $_->[0] || q[], $_->[1] || q[], $_->[2] || q[];
        last;
      }
    }
  }
  return $message;
}

use overload q[""] => \&_format_error;

sub _fatal {
  my ($conf) = @_;
  require Carp;
  $conf->{stack} = [
    map { [ $_->[0], $_->[1], $_->[2], ] }
    map { [ caller $_, ] } 0 .. 10,
  ];
  return Carp::croak( bless $conf, __PACKAGE__ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::PerlMod::Version::Error - Various error message and diagnostic bits.

=head1 VERSION

version v0.8.1

=head1 FUNCTIONS

=head2 perlver_undefined

    return perlver_undefined( $config );

Error condition thrown when L<< C<gentooize_version>|Gentoo::PerlMod::Version::gentooize_version >> is passed C<undef> for the C<$perlver>

=head2 matches_trial_regex_nonlax

    return matches_trial_regex_nonlax( $perlver, $config );

=head2 not_decimal_or_trial

    return not_decimal_or_trial( $perlver , $config )

=head2 bad_char

    return bad_char( $char, $char_ord );

=head2 lax_multi_underscore

    return lax_multi_underscore( $version )

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
