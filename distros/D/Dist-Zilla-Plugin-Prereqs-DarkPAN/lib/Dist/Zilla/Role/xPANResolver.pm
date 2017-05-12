use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Role::xPANResolver;

our $VERSION = 'v0.3.0';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

# FILENAME: xPANResolver.pm
# CREATED: 30/10/11 14:05:14 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Tools to resolve a package to a URI from a CPAN/DARKPAN mirror.












use Moose::Role qw( around );

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $payload = $config->{ +__PACKAGE__ } = {};

  ## no critic (RequireInterpolationOfMetachars)
  $payload->{ q[$] . __PACKAGE__ . q[::VERSION] } = $VERSION;
  $payload->{q[$App::Cache::VERSION]}            = $App::Cache::VERSION            if $INC{'App/Cache.pm'};
  $payload->{q[$Parse::CPAN::Packages::VERSION]} = $Parse::CPAN::Packages::VERSION if $INC{'Parse/CPAN/Packages.pm'};
  $payload->{q[$URI::VERSION]}                   = $URI::VERSION                   if $INC{'URI.pm'};
  return $config;
};

no Moose::Role;

my $c;

sub _cache {
  return $c if defined $c;
  $c = do {
    require App::Cache;
    ## no critic (ProhibitMagicNumbers)
    App::Cache->new(
      {
        ttl         => 30 * 60,
        application => __PACKAGE__,
      },
    );
  };
  return $c;
}

sub _content_for {
  my ( undef, $url ) = @_;
  return _cache->get_url($url);
}

sub _parse_for {
  my ( $self, $url ) = @_;
  my $cache_url = $url . '#parsed';
  require Parse::CPAN::Packages;
  return _cache->get_code(
    $cache_url,
    sub {
      my $content = $self->_content_for($url);
      return Parse::CPAN::Packages->new($content);
    },
  );
}

sub _resolver_for {
  my ( $self, $baseurl ) = @_;
  require URI;
  my $path   = URI->new('modules/02packages.details.txt.gz');
  my $absurl = $path->abs($baseurl)->as_string;
  return $self->_parse_for($absurl);
}

sub resolve_module {
  my ( $self, $baseurl, $module ) = @_;
  my $p = $self->_resolver_for($baseurl)->package($module);
  my $d = $p->distribution();
  require URI;
  my $modroot = URI->new('authors/id/')->abs( URI->new($baseurl) );
  my $modpath = URI->new( $d->prefix )->abs($modroot);
  return $modpath->as_string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::xPANResolver - Tools to resolve a package to a URI from a CPAN/DARKPAN mirror.

=head1 VERSION

version v0.3.0

=head1 METHODS

=head2 resolve_module

  with 'Dist::Zilla::Role::xPANResolver';

  sub foo {
    my $self = @_;
    my $uri = $self->resolve_module(
      'http://some.darkpan.org', 'FizzBuzz::Bazz'
    );
  }

This should resolve the Module to the applicable package, and return the most
recent distribution.

It should then return a fully qualified path to that resource suitable for
passing to C<wget> or C<cpanm>.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Role::xPANResolver",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
