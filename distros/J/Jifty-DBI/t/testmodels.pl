package Sample::Employee;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {

column dexterity => type is 'integer';
column name      => 
    type is 'varchar',
    is indexed;
column label     => type is 'varchar';
column type      => type is 'varchar';
column age       => is computed;

};

sub age {
    my $self = shift;
    return $self->dexterity * 2;
}

sub schema_sqlite {
    return q{
    CREATE TABLE employees (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
      dexterity integer   ,
      name varchar   ,
      label varchar   ,
      type varchar
    ) ;
    CREATE INDEX employees1 ON employees (name) ;
    };
}

sub schema_pg {
    return q{
    CREATE TABLE employees (
      id serial NOT NULL ,
      dexterity integer ,
      name varchar ,
      label varchar ,
      type varchar ,
      PRIMARY KEY (id)
    ) ;
    CREATE INDEX employees1 ON employees (name) ;
    };

}

package Sample::Address;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {

column employee_id =>
  references Sample::Employee;

column name =>
  type is 'varchar',
  default is 'Frank';

column phone =>
  type is 'varchar';

column street =>
  type is 'varchar',
  since '0.2.4',
  till '0.2.8';

};

sub validate_name { 1 }

my $schema_version = undef;
sub schema_version {
    my $class = shift;
    my $new_schema_version = shift;
    $schema_version = $new_schema_version if defined $new_schema_version;
    return $schema_version;
}

sub schema_sqlite {
    return q{
    CREATE TABLE addresses (
     id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
     employee_id integer   ,
     name varchar  DEFAULT 'Frank' ,
     phone varchar
    ) ;
    }
}

sub schema_sqlite_024 {
    return q{
    CREATE TABLE addresses (
     id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
     employee_id integer   ,
     name varchar  DEFAULT 'Frank' ,
     phone varchar ,
     street varchar
    ) ;
    }
}

sub schema_pg {
    return q{
    CREATE TABLE addresses ( 
      id serial NOT NULL , 
      employee_id integer  ,
      name varchar DEFAULT 'Frank' ,
      phone varchar ,
      PRIMARY KEY (id)
    ) ;
    };
}

sub schema_pg_024 {
    return q{
    CREATE TABLE addresses ( 
      id serial NOT NULL , 
      employee_id integer  ,
      name varchar DEFAULT 'Frank' ,
      phone varchar ,
      street varchar ,
      PRIMARY KEY (id)
    ) ;
    };
}

package Sample::Corporation;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {

column name =>
    type is 'varchar',
    is mandatory;

column us_state =>
    type is 'varchar',
    is mandatory,
    since '0.2.4',
    till '0.2.8';

};

sub schema_sqlite {
    return q{
    CREATE TABLE corporations (
     id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
     name varchar NOT NULL
    ) ;
    }
}

sub schema_sqlite_024 {
    return q{
    CREATE TABLE corporations (
     id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
     name varchar NOT NULL ,
     us_state varchar NOT NULL
    ) ;
    }
}

sub schema_pg {
    return q{
    CREATE TABLE corporations ( 
      id serial NOT NULL , 
      name varchar NOT NULL ,
      PRIMARY KEY (id)
    ) ;
    };
}

sub schema_pg_024 {
    return q{
    CREATE TABLE corporations ( 
      id serial NOT NULL , 
      name varchar NOT NULL ,
      us_state varchar NOT NULL ,
      PRIMARY KEY (id)
    ) ;
    };
}

sub schema_version {
    my $class = shift;
    my $new_schema_version = shift;
    $schema_version = $new_schema_version if defined $new_schema_version;
    return $schema_version;
}

1;
