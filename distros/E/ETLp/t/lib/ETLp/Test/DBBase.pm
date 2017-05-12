package ETLp::Test::DBBase;

#use Moose;
use Test::More;
use Data::Dumper;
use DBI;
use DBIx::VersionedDDL;
use DBI::Const::GetInfoType;
use FindBin qw($Bin);
use Cwd 'abs_path';
use Try::Tiny;
use ETLp::Config;
use ETLp::Schema;
use Log::Log4perl;
use Carp;

use base 'Test::Class';

sub new_db_args {
    return {
        dbh => DBI->connect(
            $ENV{DSN}, $ENV{USER},
            $ENV{PASS}, {RaiseError => 1, PrintError => 0, AutoCommit => 0}
        )
    };
}

sub get_driver {
    return lc shift->dbh->get_info($GetInfoType{SQL_DBMS_NAME});
}

sub db_version {
    return shift->dbh->get_info($GetInfoType{SQL_DBMS_VERSION});
}

sub dbh {
    return shift->{dbh};
}

sub get_ddl_dir {
    my $self   = shift;
    my $driver = $self->get_driver;
    return abs_path("$Bin/../ddl/$driver");
}

sub get_separator {
    my $self = shift;

    if ($self->get_driver eq 'oracle') {
        return '/';
    } else {
        return ';';
    }
}

sub _drop_general_ddl {
    my $self = shift;
    return;
}

sub _general_ddl {
    my $self = shift;
    return;
}
# overide if the tests require any additional tables
sub _sqlite_ddl {
    my $self = shift;
    return $self->_general_ddl;
}

# overide if the tests require any additional tables
sub _oracle_ddl {
    my $self = shift;
    return $self->_general_ddl;
}

# overide if the tests require any additional tables
sub _mysql_ddl {
    my $self = shift;
    return $self->_general_ddl;
}

# overide if the tests require any additional tables
sub _postgresql_ddl {
    my $self = shift;
    return $self->_general_ddl;
}


sub _execute_ddl {
    my $self = shift;
    my @ddl  = @_;

    foreach my $ddl (@ddl) {
        $self->dbh->do($ddl);
    }
}

# some tests require additional tables. These are created hear
sub _create_addtional_tables {
    my $self   = shift;
    my $driver = $self->get_driver;
    my @ddl;

    if ($driver eq 'oracle') {
        @ddl = $self->_oracle_ddl;
    } elsif ($driver eq 'sqlite') {
        @ddl = $self->_sqlite_ddl;
    } elsif ($driver eq 'mysql') {
        @ddl = $self->_mysql_ddl;
    }elsif ($driver eq 'postgresql') {
        @ddl = $self->_postgresql_ddl;
    } else {
        croak "Unknown database driver";
    }

    $self->_execute_ddl(@ddl);
}

# overide if the tests drop any additional tables
sub _drop_sqlite_ddl {
    my $self = shift;
    return $self->_drop_general_ddl;
}

# overide if the tests drop any additional tables
sub _drop_oracle_ddl {
    my $self = shift;
    return $self->_drop_general_ddl;
}

# overide if the tests drop any additional tables
sub _drop_mysql_ddl {
    my $self = shift;
    return $self->_drop_general_ddl;
}

# overide if the tests drop any additional tables
sub _drop_postgresql_ddl {
    my $self = shift;
    return $self->_drop_general_ddl;
}

# drop any tables requirwed for addtional testing
sub _drop_additional_tables {
    my $self   = shift;
    my $driver = $self->get_driver;
    my @ddl;

    if ($driver eq 'sqlite') {
        @ddl = $self->_drop_sqlite_ddl;
    } elsif ($driver eq 'oracle') {
        @ddl = $self->_drop_oracle_ddl;
    } elsif ($driver eq 'mysql') {
        @ddl = $self->_drop_mysql_ddl;
    } elsif ($driver eq 'postgresql') {
        @ddl = $self->_drop_postgresql_ddl;
    } else {
        croak "Unknown database driver";
    }

    $self->_execute_ddl(@ddl);
}

sub create_schema : Test(setup) {
    my $self = shift;
    $self->{dbh}                     = $self->new_db_args->{dbh};
    $self->{dbh}->{FetchHashKeyName} = 'NAME_lc';
    
    if ($self->get_driver eq 'oracle') {
        $self->dbh->{LongReadLen} = 1000000;
        $self->dbh->{LongTruncOk} = 1;
    }
    
    my $schema_dbh = $self->dbh->clone;
    $schema_dbh->{AutoCommit} = 1;

    my $schema = ETLp::Schema->connect(sub { $schema_dbh },
        {on_connect_call => 'datetime_setup'});

    my $logger = ETLp::Config->logger;

    # Only create the logger if it hasn't been already
    unless ($logger) {
        my $log_conf = qq(
            log4perl.rootLogger=DEBUG,NULL
            log4perl.appender.NULL=ETLp::Test::Log::Log4perl::Appender::Null
            log4perl.appender.NULL.layout   = Log::Log4perl::Layout::PatternLayout
        );

        Log::Log4perl::init(\$log_conf);
        $logger = Log::Log4perl::get_logger("DW");
    }

    ETLp::Config->schema($schema);
    ETLp::Config->dbh($self->dbh->clone);
    ETLp::Config->logger($logger);
    $self->dbh->{PrintError} = 0;

    my $sv = DBIx::VersionedDDL->new(
        dbh       => $self->dbh,
        ddl_dir   => $self->get_ddl_dir,
    );
    
    $sv->separator($self->get_separator);

    $sv->migrate();

    #create any tables for specififc tests
    $self->_create_addtional_tables;
    $self->{dbh}->{AutoCommit} = 0;
}

sub remove_schema : Test(teardown) {
    my $self = shift;

    $self->dbh->rollback;
    $self->_drop_additional_tables;
    
    #return;

    my $sv = DBIx::VersionedDDL->new(
        dbh       => $self->dbh,
        ddl_dir   => $self->get_ddl_dir,
    );
    
    $sv->separator($self->get_separator);

    $sv->migrate(0);
    $self->dbh->do("drop table schema_version");

    # Removal of Oracle tables with clobs may leave behind some detritus.
    # Empty the bin;
    if ($self->get_driver eq 'oracle') {
        my ($version) = ($self->db_version =~ /^(\d+)\./);
        if ($version >= 10) {
            try {
                $self->dbh->do("purge recyclebin");
            }
            catch {
                die "Couldn't purge recyclebin: $_";
            };
        }
    }
    
    $self->dbh->disconnect;
    #$self->{dbh} = undef;
}

1;
