package Flickr::Roles::Caching;

use Carp;
use CHI;
use Types::Standard qw( Maybe Bool Str Int InstanceOf HashRef );
use 5.010;
use Moo::Role;

our $VERSION = '1.22';

has cache_duration => (
    is       => 'rw',
    isa      => Int,
    required => 1,
    default  => 900,
);

has '_cache' => (
    is      => 'ro',
    isa     => InstanceOf ['CHI::Driver'],
    default => sub {
        CHI->new(
            driver => 'Memory',
            global => 1
        );
    },
);

has 'cache_key' => ( is => 'rwp', );

has cache_hit => ( is => 'rwp', );

no Moo::Role;

1;

__END__



=pod

=head1 NAME

Flickr::Roles::Caching - Caching behaviors for the Flickr::Tools

=head1 VERSION

CPAN:        1.22

Development: 1.22_01

=head1 SYNOPSIS

=head2 in consuming package

 package Flickr::Tools::of-some-kind;

 use Flickr::API::of-some-similar-kind;

 with qw(Flickr::Roles::Caching);

 sub getSomething-from-flickr {

   my ($self, $args) = @_;
   my $pre_expire = 0;

   $self->_set_cache_hit(1);

   if (defined($args->{clear_cache}) and $args->{clear_cache}) { $pre_expire = 1; }

   $self->_set_cache_key('meaningful-cache-key');

   $data = $self->_cache->get($self->cache_key, expire_if => sub { $pre_expire } );
   if (!defined $data) {
       $data = $self->{_api}->some-api-call;
       $self->_set_cache_hit(0);
       $self->_cache->set( $self->cache_key, $data, $self->cache_duration);
   }

   return $data;

 }

=head2 in calling script

 use Flickr::Tools::of-some-kind;

 my $tool = Flickr::Tools::of-some-kind->new(cache_duration => 3600, ...);

 say $tool->cache_duration; # will print 3600

 $tool->cache_duration(300); # set the cache duration to 300 seconds

 $tool->getSomething-from-flickr;

 if ($tool->cache_hit) {

    say "gotSomething from cache";

  }
  else {

    say "had to go to Flickr to getSomthing";

  }

  $tool->getSomething-else-from-flickr(clear_cache => 1, arg1 => val1, arg2 => val2...);




=head1 DESCRIPTION

This module adds a caching role for the Flickr::Tools packages.

=head1 PUBLIC ATTRIBUTES

=over

=item C<cache_duration>

The duration, in seconds, for the cache to keep the information.
When the cache expires, it will re-fetch the data from Flickr if
you request it again.


=item C<cache_hit>

Returns whether the last cache get was from cache or fetched into the
cache.


=item C<cache_key>

This is the last used key into the cache. It is here, but it probably
doesn't return what you think it will.

=back

=head1 PRIVATE ATTRIBUTES

=over


=item C<_cache>

This is a reference to a CHI cache kept in the Flickr::Tool object.


=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

CHI, Perl 5.10 and Moo.

=head1 INCOMPATIBILITIES

None known of, yet.

=head1 BUGS AND LIMITATIONS

Yes

=head1 AUTHOR

Louis B. Moore <lbmoore@cpan.org>

=head1 LICENSE AND COPYRIGHT


Copyright (C) 2015 Louis B. Moore <lbmoore@cpan.org>


This program is released under the Artistic License 2.0 by The Perl Foundation.
L<http://www.perlfoundation.org/artistic_license_2_0>


=cut
