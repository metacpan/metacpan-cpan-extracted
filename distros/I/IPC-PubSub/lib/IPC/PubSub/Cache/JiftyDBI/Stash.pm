package IPC::PubSub::Cache::JiftyDBI::Stash;
use strict;
use warnings;

use Jifty::DBI::Handle;
use Jifty::DBI::SchemaGenerator;
use IPC::PubSub::Cache::JiftyDBI::Stash::Item;
use IPC::PubSub::Cache::JiftyDBI::Stash::Publisher;

use File::Temp qw/ tempfile tempdir /;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    my %args = (
        db_init => 0,
        db_config => undef,
        db_handle => undef,
        table_prefix => 'pubsub_',
        @_
    );

    if ($args{'table_prefix'}) {

         IPC::PubSub::Cache::JiftyDBI::Stash::Item->table_prefix($args{'table_prefix'});
         IPC::PubSub::Cache::JiftyDBI::Stash::Publisher->table_prefix($args{'table_prefix'});
    }

    if ($args{'db_handle'}) {
            $self->handle($args{'db_handle'});

    } else {
    unless ( $args{'db_config'} ) {
        my $filename;
        ( undef, $filename ) = tempfile();

        $args{'db_config'} = { driver => 'SQLite', database => $filename };
    }

    $self->_connect( %{$args{'db_config'}} );

    }
    if ( $args{'db_init'} ) {
        $self->_generate_db();
    }
    return $self;
}

sub handle {
    my $self = shift;
    $self->{'handle'} = shift if (@_);
    return $self->{'handle'};
}

sub _generate_db {
    my $self = shift;
    my $gen = Jifty::DBI::SchemaGenerator->new( $self->handle );
    $gen->add_model( IPC::PubSub::Cache::JiftyDBI::Stash::Item->new( handle => $self->handle ) );
    $gen->add_model( IPC::PubSub::Cache::JiftyDBI::Stash::Publisher->new( handle => $self->handle ) );
    my @statements = $gen->create_table_sql_statements;
    $self->handle->begin_transaction;
    for my $statement (@statements) {
        my $ret = $self->handle->simple_query($statement);
    }
    $self->handle->commit;

}


sub _connect {
    my $self = shift;


    my $handle = Jifty::DBI::Handle->new();
    $handle->connect(@_);
    $self->handle($handle);
}


1;
