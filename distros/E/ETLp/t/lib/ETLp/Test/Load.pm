package ETLp::Test::Load;

use Test::More;
use Data::Dumper;
use Carp;
use ETLp::Loader::CSV;
use ETLp::File::Config;
use base (qw(ETLp::Test::Base ETLp::Test::DBBase));
use Try::Tiny;
use ETLp::Role::Config;

sub new_args {
    (
        keep_logger     => 0,
        create_log_file => 0
    );
}

sub _sqlite_ddl {
    return (
        q{
            create table scores (
                id    integer,
                name  text,
                score real,
                file_id integer
            )
        },
    );
}

sub _oracle_ddl {
    return (
        q{
            create table scores (
                id    integer,
                name  varchar2(20),
                score number,
                file_id integer
            )
        },
    );
}

sub _mysql_ddl {
    my $self = shift;
    return (
        q{
            create table scores (
                id    integer,
                name  varchar(20),
                score float,
                file_id integer
            )
        },
    );
}

sub _postgresql_ddl {
    my $self = shift;
    return $self->_mysql_ddl; 
}

sub _drop_ddl {
    return (q{drop table scores},);
}

sub _drop_sqlite_ddl {
    my $self = shift;
    return $self->_drop_ddl;
}

sub _drop_mysql_ddl {
    my $self = shift;
    return $self->_drop_ddl;
}

sub _drop_postgresql_ddl {
    my $self = shift;
    return $self->_drop_ddl;
}

sub _drop_oracle_ddl {
    my $self = shift;
    my @ddl  = $self->_drop_ddl;
    return @ddl;
}




sub test : Tests(8) {
    my $self = shift;

    my $file_def_dir   = $self->file_def_dir;
    my $data_directory = $self->csv_dir;

    my $sth = $self->dbh->prepare(
        'insert into scores(id, name, score) values (?, ?, ?)');

    my $rule_conf = ETLp::File::Config->new(
        directory  => $file_def_dir,
        definition => 'score_def.cfg'
    );

    my $loader = ETLp::Loader::CSV->new(
        table     => 'scores',
        columns   => $rule_conf->fields,
        directory => $data_directory,
        file_id   => 5,
        localize  => 1,
    );

    unless ($loader->load('scores.csv.loc')) {
        die $loader->error;
    }

    my $loaded_rows = [
        ['1', 'Smith', '50', 5],
        ['2', 'Jones', '30', 5],
        ['3', 'White', '89', 5],
        ['4', 'Brown', '73', 5]
    ];

    my $rs = $self->dbh->selectall_arrayref('select * from scores');
    is_deeply($loaded_rows, $rs, 'Rows loaded');

    is($loader->rows_loaded, 4, 'Record count');

    $self->dbh->do('delete from scores');
    $self->dbh->commit;

    $loader = ETLp::Loader::CSV->new(
        table     => 'scores',
        columns   => $rule_conf->fields,
        directory => $data_directory,
        file_id   => 5,
        localize  => 1,
        skip      => 1,
    );

    unless ($loader->load('scores_header.csv.loc')) {
        die $loader->error;
    }

    $rs = $self->dbh->selectall_arrayref('select * from scores');

    is_deeply($loaded_rows, $rs, 'Rows loaded - header skipped');

    $self->dbh->do('delete from scores');
    $self->dbh->commit;

    $loader = ETLp::Loader::CSV->new(
        table     => 'scores',
        columns   => $rule_conf->fields,
        directory => $data_directory,
        file_id   => 5,
        localize  => 1,
        skip      => 2,
    );

    unless ($loader->load('scores_header_2rows.csv.loc')) {
        die $loader->error;
    }

    $rs = $self->dbh->selectall_arrayref('select * from scores');

    is_deeply($loaded_rows, $rs, 'Rows loaded - 2 header rows skipped');

    $loader = ETLp::Loader::CSV->new(
        table     => 'no_scores',
        columns   => $rule_conf->fields,
        directory => $data_directory,
        file_id   => 5,
        localize  => 1,
        skip      => 2,
    );

    $loader->dbh->{PrintError} = 0;
    $loader->dbh->{RaiseError} = 1;
    is($loader->load('scores.csv.loc'), 0, 'Load Failed');

    like(
        $loader->error,
        qr/no such table|table or view does not exist|doesn't exist|does not exist/s,
        'Trapped DB Error'
    );
    is($loader->rows_loaded, 0, '0 Rows Loaded');

    $self->dbh->do('delete from  scores');
    $self->dbh->commit;

    $loader = ETLp::Loader::CSV->new(
        table              => 'scores',
        columns            => $rule_conf->fields,
        directory          => $data_directory,
        file_id            => 5,
        ignore_field_count => 1,
        localize           => 1,
    );

    unless ($loader->load('scores_missing.csv.loc')) {
        die $loader->error;
    }

    $loaded_rows = [
        ['1', 'Smith', '50',  5],
        ['2', 'Jones', undef, 5],
        ['3', 'White', '89',  5],
        ['4', 'Brown', '73',  5]
    ];

    $rs = $self->dbh->selectall_arrayref('select * from scores');
    is_deeply($rs, $loaded_rows, 'Rows loaded - field number mismatch');

}

1;

