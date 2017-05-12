package KeyedMutex::Memcached;

use strict;
use warnings;
use Carp;
use Scope::Guard qw(scope_guard);
use Time::HiRes ();

our $VERSION = '0.05';

sub new {
    my $class = shift;
    my $args = ref $_[0] ? $_[0] : +{@_};
    $args = +{
        interval => 0.01,
        trial    => 0,
        timeout  => 30,
        prefix   => 'km',
        cache    => undef,
        %$args,
        locked => 0,
    };

    croak('cache value should be object and appeared add and delete methods.')
      unless ( $args->{cache}
        && UNIVERSAL::can( $args->{cache}, 'add' )
        && UNIVERSAL::can( $args->{cache}, 'delete' ) );

    bless $args => $class;
}

sub lock {
    my ( $self, $key, $use_raii ) = @_;

    $key = $self->{prefix} . ':' . $key if ( $self->{prefix} );
    $self->{key}    = $key;
    $self->{locked} = 0;

    my $i  = 0;
    my $rv = 0;

    while ( $self->{trial} == 0 || ++$i <= $self->{trial} ) {
        $rv = $self->{cache}->add( $key, 1, $self->{timeout} ) ? 1 : 0;
        if ($rv) {
            $self->{locked} = 1;
            last;
        }
        Time::HiRes::sleep( $self->{interval} * rand(1) );
    }

    return $rv ? ( $use_raii ? scope_guard sub { $self->release } : 1 ) : 0;
}

sub release {
    my $self = shift;
    $self->{cache}->delete( $self->{key} );
    $self->{locked} = 0;
    1;
}

1;
__END__

=head1 NAME

KeyedMutex::Memcached - An interprocess keyed mutex using memcached

=head1 SYNOPSIS

  use KeyedMutex::Memcached;

  my $key   = 'query:XXXXXX';
  my $cache = Cache::Memcached::Fast->new( ... );
  my $mutex = KeyedMutex::Memcached->new( cache => $cache );

  until ( my $value = $cache->get($key) ) {
    {
      if ( my $lock = $mutex->lock( $key, 1 ) ) {
        #locked read from DB
        $value = get_from_db($key);
        $cache->set($key, $value);
        last;
      }
    };
  }

=head1 DESCRIPTION

KeyedMutex::Memcached is an interprocess keyed mutex using memcached.
This module is inspired by L<KeyedMutex>.

=head1 METHODS

=head2 new( %args )

Following parameters are recognized.

=over

=item cache

B<Required>. L<Cache::Memcached::Fast> object or similar interface object.

=item interval

Optional. The seconds for busy loop interval. Defaults to 0.01 seconds.

=item trial

Optional. When the value is being set zero, lock() method will be waiting until lock becomes released.
When the value is being set positive integer value, lock() method will be stopped on reached trial count.
Defaults to 0.

=item timeout

Optional. The seconds until lock becomes released. Defaults to 30 seconds.

=item prefix

Optional. Prefix of key to store memcached. The real key is prefix + ':' + key. Defaults to C<'km'>.

=back

=head2 lock($key, [ $use_raii ])

Get lock by each key. When getting lock successfully, returns 1, on failed returns 0.
If use_raii is being set true, return L<Scope::Guard> object as RAII.

=head2 locked

Which is the object has locked.

=head2 release

Release lock.

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
