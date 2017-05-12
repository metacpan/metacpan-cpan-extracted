use Deeme::Obj -strict;

use Test::More;
use Deeme;
use Deeme::Backend::Meerkat;

subtest 'MongoDB Backend' => sub {

    my $connection;
    eval {
        use MongoDB;
        $connection = MongoDB->connect( 'mongodb://localhost:27017' );
    };
    if ( !$connection or $@ ) {
        plan skip_all => 'No MongoDB passwordless connection on machine';
    }
    use_ok("Deeme::Backend::Meerkat");
    # Normal event

    my $Backend = Deeme::Backend::Meerkat->new(
        database => "deeme_test",
        host     => "mongodb://localhost:27017",
    );
    my $e = Deeme->new( backend => $Backend );
    $e->reset;    #Resetting events on db
    my $called;
    $e->on( test1 => sub { die("OK!") } );
    eval { $e->emit('test1'); };
    like $@, qr/OK\!/, 'event was emitted once';

    # Error
    $e->on( die => sub { die "works!\n" } );
    eval { $e->emit('die') };
    is $@, "works!\n", 'right error';

    $e->on( error => sub { die "$_[1]" } );
    # Unhandled error event
    eval { $e->emit( error => 'just' ) };
    like $@, qr/just/, 'right error';

    eval { $e->emit_safe( error => 'works' ) };
    like $@, qr/works/, 'right error';
    $e->reset;
    # Exception in error event
    $e->once( error => sub { die "$_[1]entional" } );
    eval { $e->emit( error => 'int' ) };
    like $@, qr/intentional/, 'right error';
    $e->once( error => sub { die "$_[1]entional" } );
    eval { $e->emit_safe( error => 'int' ) };
    like $@, qr/Event "error" failed: intentional/, 'right error';

    $e->reset;
    my $cb1 = $e->on(
        test2 => sub {
            my ( $self, $msg ) = @_;
            die "test2: $msg\n";
        }
    );
    my $cb2 = $e->on(
        error => sub {
            like pop, qr/Event "test2" failed: test2: works!/, 'right error';
        }
    );

    $e->emit_safe( 'test2', 'works!' );
    my $cb3 = $e->on(
        test2 => sub {
            my ( $self, $msg ) = @_;
            die "test2 die again!: $msg\n";
        }
    );
    my $cb = $e->on(
        test2 => sub {
            my ( $self, $msg ) = @_;
            die "test2 die again again!: $msg\n";
        }
    );
    is scalar @{ $e->subscribers('test2') }, 3, 'three subscribers';
    $e->unsubscribe( test2 => $cb );
    is scalar @{ $e->subscribers('test2') }, 2, 'two subscribers';
    $e->emit_safe( 'test2', 'works!' );
    $e->unsubscribe( test2 => $cb1 );
    $e->unsubscribe( test2 => $cb3 );
    is scalar @{ $e->subscribers('test2') }, 0, 'no subscribers';
    $e->once( one_time => sub { die("OK!") } );
    is scalar @{ $e->subscribers('one_time') }, 1, 'one subscriber';
    $e->unsubscribe( one_time => $cb3 );
    is scalar @{ $e->subscribers('one_time') }, 1, 'one subscriber';
    eval { $e->emit('one_time'); };
    like $@, qr/OK\!/, 'event was emitted once';
    $e->reset;
};
use_ok("Deeme::Backend::Meerkat::Model::Event");

done_testing();
