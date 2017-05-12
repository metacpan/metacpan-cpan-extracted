package Geo::Coder::Cache;
use base 'Cache::FileCache';
use strict;

use vars qw($VERSION $AUTOLOAD);

$VERSION = '0.06';

our $HOME = $ENV{'HOME'} || $ENV{'LOGDIR'};
our %default_cache_args = (
    'namespace' => 'geo-coder-cache',
    'cache_root' => "$HOME/.cache",
    'default_expires_in' => 86400);

sub new {
  my($class, %param) = @_;
  my $geocoder = delete $param{geocoder} or Carp::croak("Usage: new(geocoder => \$geocoder)");
  ($default_cache_args{namespace} = 'geo-coder-cache-' . lc ref($geocoder)) =~ s{::}{-}g;
  my %cache_args = (%default_cache_args, %param);
  my $self = $class->SUPER::new(\%cache_args);
  $self->{geocoder} = $geocoder;
  return $self;
}

# delegate all other method calls the the cache object.
sub AUTOLOAD
{
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);

    # We create the function here so that it will not need to be
    # autoloaded the next time.
    no strict 'refs';
    *$method = sub {
      my $self = shift;
      $self->{'geocoder'}->$method(@_);
    };
    goto &$method;
}

sub DESTROY {}  # avoid AUTOLOADing it

sub geocode {
  my $self = shift;
  my %param;
  if (@_ % 2 == 0) {
    %param = @_;
  } else {
    $param{location} = shift;
  }
  if ($param{location}) {
    my $location = $self->get($param{location});
    if (defined($location)) {
      return $location;
    }
  }
  my $location = $self->{geocoder}->geocode(%param);
  $self->set($param{location}, $location);
  return $location;
}

1;
__END__

=head1 NAME

Geo::Coder::Cache - Add cache for Geo::Coder::*

=head1 SYNOPSIS

  # for Geo::Coder::Yahoo
  use Geo::Coder::Yahoo;
  use Geo::Coder::Cache;
  my $geocoder = Geo::Coder::Cache->new(geocoder => Geo::Coder::Yahoo->new(appid => 'Your App ID'));
  my $location = $geocoder->geocode(location => '701 1st Ave, Sunnyvale, CA 94089');

  # for Geo::Coder::Google
  use Geo::Coder::Google;
  use Geo::Coder::Cache;
  my $geocoder = Geo::Coder::Cache->new(geocoder => Geo::Coder::Google->new(apikey => 'Your API Key'));
  my $location = $geocoder->geocode(location => '1600 Amphitheatre Pkwy, Mountain View, CA 94043');

=head1 DESCRIPTION

Geo::Coder::Cache is a Geo::Coder::* wrapper with local file cache implemented by Cache::FileCache.

=head1 METHOD

=over 4

=item new

This method constructs a new C<Geo::Coder::Cache> object and returns it.
C<geocoder> is required, and all the other options will be passed to C<Cache::FileCache>.

  KEY                     DEFAULT
  -----------             --------------------
  geocoder                REQUIRED
  namespace               geo-coder-cache
  cache_root              $HOME/.cache
  default_expires_in      86400

=item get

=item set

=item remove

Geo::Coder::Cache itself is a Cache::FileCache, so please check
C<Cache::FileCahce> for cache related methods.

=item geocode

It is the primary method of this class. It will retrive result from cache
first, and return if cache hit. Otherwise it will call
Geo::Coder::*->geocode and then save the result in cache.

=head1 SEE ALSO

Cache::FileCache

=head1 AUTHOR

Yen-Ming Lee, E<lt>leeym@leeym.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Yen-Ming Lee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
