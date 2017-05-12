#!/usr/bin/perl
use blib;
{

    package FooBar;
    use warnings;
    use strict;
    use Memoize qw(memoize unmemoize);
    use Memoize::Expire::ByInstance;
    use Time::HiRes qw(time);

    my $memoized = undef;
    our %foo;
    our %argh;

    sub destroy_hash
    {
        unmemoize('bar') if($memoized);
        unmemoize('argh') if($memoized);

        $memoized = undef;

        untie(%foo);
        untie(%argh);
    }

    sub silliness_normy { return join( chr(0x07), @_ ) }

    sub reset_hash
    {
        tie %foo => 'Memoize::Expire::ByInstance', LIFETIME => 30, NUM_USES => 1000, AUTO_DESTROY => 1, ARGUMENT_SEPERATOR => chr(0x07);
        memoize( 'bar', LIST_CACHE => ['MERGE'], SCALAR_CACHE => [ HASH => \%foo ], NORMALIZER => 'silliness_normy' );

        tie %argh => 'Memoize::Expire::ByInstance', LIFETIME => 30, NUM_USES => 1000, AUTO_DESTROY => 1;
        memoize( 'argh', LIST_CACHE => [ HASH => \%argh ], SCALAR_CACHE => [ 'MERGE' ] );

        $memoized = 1;
    }

    reset_hash();

    sub new
    {
        my ( $proto, %args ) = @_;
        my $class = ref($proto) || $proto;
        my $self = bless( \%args, $class );
        ( tied %foo )->register( "$self", lifetime => $self->{max_lifetime}, num_uses => $self->{max_num_uses} );
        die "Did not successfully register ourselves" if( scalar keys %args && !exists( ( tied %foo )->{_meta}->{_expire}->{"$self"} ) );
        return $self;
    }

    sub bar
    {
        my ( $self, $var1, $var2 ) = @_;
        return time;
    }

    sub argh
    {
        my ( $self, @args ) = @_;
        return( time, @args );
    }
}
{

    package TestDestroyChaining;
    use warnings;
    use strict;
    use Memoize qw(memoize unmemoize);
    use Memoize::Expire::ByInstance;
    use Time::HiRes qw(time);

    my $memoized = undef;
    our %foo;

    sub destroy_hash
    {
        unmemoize('bar') if($memoized);
        $memoized = undef;
        untie(%foo);
    }

    sub reset_hash
    {
        tie %foo => 'Memoize::Expire::ByInstance', LIFETIME => 30, NUM_USES => 1000, AUTO_DESTROY => 1;
        memoize( 'bar', LIST_CACHE => ['MERGE'], SCALAR_CACHE => [ HASH => \%foo ] );
        $memoized = 1;
    }

    reset_hash();

    sub new
    {
        my ( $proto, %args ) = @_;
        my $class = ref($proto) || $proto;
        my $self = bless( \%args, $class );
        ( tied %foo )->register( "$self", lifetime => $self->{max_lifetime}, num_uses => $self->{max_num_uses} );
        die "Did not successfully register ourselves" if( !exists( ( tied %foo )->{_meta}->{_expire}->{"$self"} ) );
        return $self;
    }

    sub bar
    {
        my ( $self, $var1, $var2 ) = @_;
        return time;
    }

    sub DESTROY
    {
        my ($self) = @_;
        die "test intentionally died\n";
    }
}
{

    package EmbeddedHash;
    use warnings;
    use strict;
    use Memoize qw(memoize unmemoize);
    use Memoize::Expire::ByInstance;
    use Time::HiRes qw(time);

    our %embedded_hash;

    our %foo;
    my $memoized = undef;

    sub reset_hash
    {
        tie %foo => 'Memoize::Expire::ByInstance', LIFETIME => 30, NUM_USES => 1000, AUTO_DESTROY => 1, HASH => \%embedded_hash;
        memoize( 'bar', LIST_CACHE => ['MERGE'], SCALAR_CACHE => [ HASH => \%foo ] );
        $memoized = 1;
    }

    sub destroy_hash
    {
        unmemoize('bar') if($memoized);
        $memoized = undef;
        untie %foo;
    }

    reset_hash();

    sub new
    {
        my ( $proto, %args ) = @_;
        my $class = ref($proto) || $proto;
        my $self = bless( \%args, $class );
        ( tied %foo )->register( "$self", lifetime => $self->{max_lifetime}, num_uses => $self->{max_num_uses} );
        die "Did not successfully register ourselves" if( !exists( ( tied %foo )->{_meta}->{_expire}->{"$self"} ) );
        return $self;
    }

    sub bar
    {
        my ( $self, $var1, $var2 ) = @_;
        return time;
    }

    sub DESTROY
    {
        my ($self) = @_;
        die "Did not clean up after ourselves" if( exists( ( tied %foo )->{_meta}->{_expire}->{"$self"} ) );
    }
}
{

    package Test::Memoize::Expire::ByInstance;
    use base qw(Test::Class);
    use Test::More;
    use Time::HiRes qw(usleep);
    use warnings;
    use strict;

    sub setup : Test(setup)
    {
        my ($self) = @_;
        FooBar::reset_hash();
        EmbeddedHash::reset_hash();
        TestDestroyChaining::reset_hash();
    }

    sub cleanup : Test(teardown)
    {
        my ($self) = @_;

        FooBar::destroy_hash();
        EmbeddedHash::destroy_hash();
        TestDestroyChaining::destroy_hash();
    }

    sub memoization : Test(2)
    {
        my ($self) = @_;
        my $a = FooBar->new();
        my $b = FooBar->new( max_lifetime => 100 );
        my $c = FooBar->new( max_lifetime => 1 );

        my $t1 = $a->bar('buggers');
        usleep(100);
        my $t2 = $b->bar('buggers');
        usleep(100);
        my $t3 = $c->bar('buggers');

        is( $t2, $t1 );
        is( $t3, $t1 );
    }

    sub expiration_time : Test(5)
    {
        my ($self) = @_;

        my $a = FooBar->new();
        my $b = FooBar->new( max_lifetime => 100 );
        my $c = FooBar->new( max_lifetime => 1 );

        my $t1 = $a->bar('buggers');
        diag( 'Sleeping 2 seconds' );
        sleep(2);

        my $t2 = $a->bar('buggers');
        usleep(100);
        my $t3 = $b->bar('buggers');
        usleep(100);
        my $t4 = $c->bar('buggers');
        usleep(100);
        my $t5 = $a->bar('buggers');
        usleep(100);
        my $t6 = $b->bar('buggers');

        is( $t2, $t1 );
        is( $t3, $t1 );
        isnt( $t4, $t1 );
        is( $t5, $t4 );
        is( $t6, $t4 );
    }

    sub expiration_uses : Test(5)
    {
        my ($self) = @_;

        my $a = FooBar->new();
        my $b = FooBar->new( max_num_uses => 100 );
        my $c = FooBar->new( max_num_uses => 10 );

        my $t1 = $a->bar('buggers');
        for( my $n = 0 ; $n < 20 ; $n++ ) {
            my $f = $a->bar('buggers');
            usleep(100);
        }

        my $t2 = $a->bar('buggers');
        usleep(100);
        my $t3 = $b->bar('buggers');
        usleep(100);
        my $t4 = $c->bar('buggers');
        usleep(100);
        my $t5 = $a->bar('buggers');
        usleep(100);
        my $t6 = $b->bar('buggers');

        is( $t2, $t1 );
        is( $t3, $t1 );
        isnt( $t4, $t1 );
        is( $t5, $t4 );
        is( $t6, $t4 );
    }

    sub hash_linking : Test(2)
    {
        my ($self) = @_;

        my $a = EmbeddedHash->new( max_num_uses => 1 );

        ok( !exists( $EmbeddedHash::embedded_hash{buggers} ) );
        $a->bar('buggers');
        ok( exists( $EmbeddedHash::embedded_hash{buggers} ) );
    }

    sub test_hash_validity : Test(6)
    {
        my ($self) = @_;

        my $a = EmbeddedHash->new( max_num_uses => 1 );
        $a->bar('buggers');

        is( scalar keys %EmbeddedHash::foo,   1 );
        is( scalar values %EmbeddedHash::foo, 1 );
        is( scalar %EmbeddedHash::foo,        '1/8' );
        delete( $EmbeddedHash::foo{'buggers'} );
        is( scalar keys %EmbeddedHash::foo, 0 );
        $a->bar('buggers');
        is( scalar keys %EmbeddedHash::foo, 1 );
        %EmbeddedHash::foo = ();
        is( scalar keys %EmbeddedHash::foo, 0 );
    }

    sub test_infinite : Test(20)
    {
        my ($self) = @_;

        my $a = EmbeddedHash->new( max_num_uses => 0, max_lifetime => 0 );
        my $t1 = $a->bar( 'buggers', 'fredly' );
        diag( 'Sleeping 5 seconds' );
        sleep(5);

        for( 1 .. 20 ) {
            is( $a->bar( 'buggers', 'fredly' ), $t1 );
            usleep(100);
        }
    }

    sub destroy_chaining : Test(1)
    {
        my ($self) = @_;
        my $a = TestDestroyChaining->new( max_num_uses => 1 );
        my $death = "";
        eval {
            $SIG{__DIE__} = sub { ($death) = @_; };
            undef $a;
        };
        ok( $death =~ m/intentionally\sdied/gsmxi, 'we intentionally died from chained DESTROY' );
    }

    sub argument_handling : Test(8)
    {
        my ($self) = @_;

        my $a = FooBar->new();
        my $b = FooBar->new();
        my $c = FooBar->new();

        my @a = $a->argh( 'test', 'thing', 'dohicky' );
        usleep(100);
        my @b = $b->argh( 'test', 'thing', 'dohicky' );
        usleep(100);
        my @c = $c->argh( 'test', 'thing', 'dohicky' );

        is( scalar @a, 4, 'results a' );
        is( scalar @b, 4, 'results b' );
        is( scalar @c, 4, 'results c' );

        is( $b[0], $a[0], 'memoized a and b' );
        is( $c[0], $a[0], 'memoized a and c' );
        is( $a[1], 'test', 'values test' );
        is( $a[2], 'thing', 'values thing' );
        is( $a[3], 'dohicky', 'values dohicky' );
    }
}

Test::Class->runtests();
