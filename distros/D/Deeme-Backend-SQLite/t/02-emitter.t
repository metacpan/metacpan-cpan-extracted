use Deeme::Obj -strict;

use Test::More;
use Deeme;
use Carp::Always;
subtest 'SQLite Backend' => sub {

    my $connection;
    eval {
        use DBI;
        $connection = DBI->connect("dbi:SQLite:dbname=/tmp/deeme.db");
    };
    if ( !$connection or $@ ) {
        plan skip_all => 'No DBI or DBD::SQLite driver avaible';
    }
    use_ok("Deeme::Backend::DBI");

    # Normal event
    use Deeme::Backend::SQLite;
    my $Backend = Deeme::Backend::SQLite->new( database => "/tmp/deeme.db", );
    my $e = Deeme->new( backend => $Backend );

    my $called;
    $e->on( test1 => sub { die("OK!") } );
    eval { $e->emit('test1'); };
    like $@, qr/OK\!/, 'event was emitted once';

    # Error
    $e->on( die => sub { die "works!\n" } );
    eval { $e->emit('die') };
    like $@, qr/works\!/, 'right error';

    $e->on( error => sub { die $_[1] } );

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
    eval { $e->emit_safe( error => 'intentional' ) };
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
    $e->reset;    #Resetting events on db
};
use_ok("Deeme::Backend::SQLite");

done_testing();
