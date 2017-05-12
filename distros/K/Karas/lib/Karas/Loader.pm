package Karas::Loader;
use strict;
use warnings;
use utf8;
use 5.0100000;
use Carp ();

use Karas;

use String::CamelCase;
use DBIx::Inspector;

sub load {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    $args{namespace} //= do {
        state $i=0;
        my $klass = "Karas::Loader::Anon" . $i++;
        {
            no strict 'refs';
            push @{"${klass}::ISA"}, 'Karas';
        }
        $klass;
    };
    my $row_class_map = $class->load_schema(%args);
    my $db = $args{namespace}->new(
        %args,
        row_class_map => $row_class_map,
    );
    return $db;
}

sub load_schema {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $connect_info = $args{connect_info} // Carp::croak "Missing mandatory parameter: connect_info";
    my $namespace = $args{namespace} // Carp::croak "Missing mandatory parameter: namespace";
    my $decamelize_map = $args{decamelize_map} || +{};

    my $dbh = DBI->connect(@$connect_info) or Carp::croak("Cannot connect to database: $DBI::errstr");
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    require Karas::Row;
    my %class_map;
    for my $table ($inspector->tables) {
        no strict 'refs';
        my $klass = sprintf( "%s::Row::%s",
            $namespace,
            $decamelize_map->{ $table->name } || String::CamelCase::camelize( $table->name )
        );
        $class_map{$table->name} = $klass;
        # setup inheritance
        unshift @{"${klass}::ISA"}, 'Karas::Row';
        # make accessors
        my @column_names = map { $_->name } $table->columns();
        $klass->mk_column_accessors(@column_names);
        # define 'table_name' method
        {
            my $table_name = $table->name;
            *{"${klass}::table_name"} = sub { $table_name };
        }
        # define 'primary_key' method
        {
            my @pk = map { $_->name } $table->primary_key();
            *{"${klass}::primary_key"} = sub { @pk };
        }
        # define 'column_names' method
        {
            *{"${klass}::column_names"} = sub { @column_names };
        }
        # define 'has_column'
        {
            my %column_names = map { $_ => 1 } @column_names;
            *{"${klass}::has_column"} = sub { $column_names{$_[1]} };
        }
    }
    return \%class_map;
}

1;

