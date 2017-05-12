package Mail::Action::StorageTest;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;
use Test::Exception;

use File::Path;
use File::Spec;

sub module      { 'Mail::Action::Storage' }
sub subclass    { 'Mail::Action::StorageSub' }
sub storage_dir { 'storage' }

sub startup :Test( startup => 2 )
{
    my $self        = shift;
    my $module      = $self->module();
    my $storage_dir = $self->storage_dir();

    use_ok( $module );
    can_ok( $module, 'new' );

    mkdir $storage_dir unless -d $storage_dir;
}

sub shutdown :Test( shutdown )
{
    my $self = shift;
    rmtree $self->storage_dir() unless $ENV{PERL_TEST_DEBUG};
}

sub setup :Test( setup => 1 )
{
    my $self   = shift;
    my $module = $self->module();

    $self->{storage} = $module->new( $self->storage_dir() );
    isa_ok( $self->{storage}, $module );
}

sub test_new_exception :Test
{
    my $self   = shift;
    my $module = $self->module();

    throws_ok { $module->new() } qr/No storage directory/,
        'new() should throw exception without directory given';
}

sub test_fetch :Test( 3 )
{
    my $self          = shift;
    my $storage       = $self->{storage};
    my $storage_class = $self->subclass();

    my $s = $storage_class->new( 'storage' );

    can_ok( $storage, 'fetch' );

    $storage->save( { foo => 'bar', baz => 'quux', name => 'why' }, 'why' );
    my $result = $s->fetch( 'why' );
    is_deeply( $result, { foo => 'bar', baz => 'quux', name => 'why' },
        'fetch() should return loaded data' );
    isa_ok( $result, $s->stored_class(), '... blessed into storage class' );
}

sub test_storage_dir :Test( 2 )
{
    my $self    = shift;
    my $storage = $self->{storage};

    can_ok( $storage, 'storage_dir' );
    is( $storage->storage_dir(), $self->storage_dir(),
        'storage_dir() should return directory set in constructor' );
}

sub test_stored_class :Test( 2 )
{
    my $self    = shift;
    my $storage = $self->{storage};

    can_ok( $storage, 'stored_class' );
    is( $storage->stored_class(), '', 'stored_class() should be blank' );
}

sub test_storage_extension :Test( 2 )
{
    my $self    = shift;
    my $storage = $self->{storage};

    can_ok( $storage, 'storage_extension' );
    is( $storage->storage_extension(), 'mas',
        'storage_extension() should be mas' );
}

sub test_storage_file :Test( 2 )
{
    my $self    = shift;
    my $storage = $self->{storage};

    can_ok( $storage, 'storage_file' );
    is( $storage->storage_file( 'foo' ),
        File::Spec->catfile( 'storage', 'foo.mas' ),
        'storage_file() should return directory path of file with extension' );
}

sub test_create :Test
{
    my $self    = shift;
    my $storage = $self->{storage};

    # empty body, just exists
    can_ok( $storage, 'create' );
}

sub test_exists :Test( 2 )
{
    my $self    = shift;
    my $storage = $self->{storage};

    can_ok( $storage, 'exists' );
    ok( ! $storage->exists( 'foo' ),
        'exists() should return false unless stored object exists' );
}

sub test_save :Test( 2 )
{
    my $self    = shift;
    my $storage = $self->{storage};

    can_ok( $storage, 'save' );

    $storage->save( { foo => 'bar', baz => 'quux', name => 'eks' }, 'eks' );
    ok( $storage->exists( 'eks' ),
        'save() should store file checkable with exists' );
}

package Mail::Action::RealAddress;

sub new
{
    my ($class, %args) = @_;
    bless \%args, $class;
}

package Mail::Action::StorageSub;

use base 'Mail::Action::Storage';

sub stored_class { 'Mail::Action::RealAddress' }

1;
