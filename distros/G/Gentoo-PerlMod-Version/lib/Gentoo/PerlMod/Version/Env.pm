use 5.006;
use strict;
use warnings;

package Gentoo::PerlMod::Version::Env;

our $VERSION = 'v0.8.1';

# ABSTRACT: Get/parse settings from %ENV

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

my $state;
my $env_key = 'GENTOO_PERLMOD_VERSION_OPTS';







sub opts {
  return $state if defined $state;
  $state = {};
  return $state if not defined $ENV{$env_key};
  my (@tokes) = split /\s+/msx, $ENV{$env_key};
  for my $token (@tokes) {
    if ( $token =~ /\A([^=]+)=(.+)\z/msx ) {
      $state->{"$1"} = "$2";
    }
    elsif ( $token =~ /\A-(.+)\z/msx ) {
      delete $state->{"$1"};
    }
    else {
      $state->{$token} = 1;
    }
  }
  return $state;
}











sub hasopt {
  my ($opt) = @_;
  return exists opts()->{$opt};
}











sub getopt {
  my ($opt) = @_;
  return opts()->{$opt};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::PerlMod::Version::Env - Get/parse settings from %ENV

=head1 VERSION

version v0.8.1

=head1 FUNCTIONS

=head2 C<opts>

    my $hash = Gentoo::PerlMod::Version::Env::opts();

=head2 C<hasopt>

    GENTOO_PERLMOD_VERSION=" foo=5 ";

    if ( Gentoo::PerlMod::Version::Env::hasopt('foo') ) {
        pass('has opt foo');
    }

=head2 C<getopt>

    GENTOO_PERLMOD_VERSION=" foo=5 ";

    if ( Gentoo::PerlMod::Version::Env::hasopt('foo') ) {
        is( Gentoo::PerlMod::Version::Env::getopt('foo'), 5 , ' foo == 5' );
    }

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
