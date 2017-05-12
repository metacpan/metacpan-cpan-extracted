package FabForce::DBDesigner4::XML;

# ABSTRACT: parse XML file

use 5.006001;
use strict;
use warnings;
use XML::Twig;
use FabForce::DBDesigner4::Table qw(:const);

our $VERSION     = '0.3';

sub new{
    my ($class) = @_;
    my $self = {};
    bless $self,$class;
    
    $self->_reset_tables;
    $self->_is_fabforce( 0 );
    $self->_reset_columns;
    $self->_reset_tableids;
    $self->_reset_relationsid;
    
    return $self;
}# new

sub parsefile{
    my ($self,$filename) = @_;
    return unless $filename;
    $self->_reset_tables;
    $self->_is_fabforce( 0 );
    my $parser  = XML::Twig->new(twig_handlers => { 
        'TABLE'       => sub{_tables($self,@_)},
        'COLUMN'      => sub{_column($self,@_)},
        'RELATION'    => sub{_relation($self,@_)},
        'INDEXCOLUMN' => sub{_index($self,@_)},
        'DBMODEL'     => sub{$self->_is_fabforce(1)},
    });
    $parser->parsefile($filename);
    my $root = $parser->root;
    return unless($self->_is_fabforce);
    
    for my $table( $self->_all_tables ){
        $table->columns( $self->_table_columns( $table->name ) );
        $table->column_details( $self->_table_column_details( $table->name ) );
        $table->key( $self->_key( $table->name ) );
    }

    return [ $self->_all_tables ];
}# parsefile

sub _tables{
    my ($self,$t,$table) = @_;
    
    my $name = $table->{att}->{Tablename};
    my $xPos = $table->{att}->{XPos};
    my $yPos = $table->{att}->{YPos};
    
    my $tableobj = FabForce::DBDesigner4::Table->new();
    $tableobj->name($name);
    $tableobj->coords([$xPos,$yPos,0,0]);
    
    $self->_add_table( $tableobj );
    $self->_tableid( $table->{att}->{ID}, $name );
}# _tables

sub _column{
    my ($self,$t,$col) = @_;
    
    my $parent_table   = $col->{parent}->{parent}->{att}->{Tablename};
    my $name           = $col->{att}->{ColName};
    my $datatype       = _datatypes('id2name',$col->{att}->{idDatatype});
    my $typeAttr       = $col->{att}->{DatatypeParams} ? $col->{att}->{DatatypeParams} : '';
    my $notnull        = $col->{att}->{NotNull} ? 'NOT NULL' : '';
    my $default        = $col->{att}->{DefaultValue};
    my $autoinc        = $col->{att}->{AutoInc} ? 'AUTOINCREMENT' : '';

    $col->{att}->{DataType} = $datatype;
    
    if( $datatype !~ m!INT! ){
        $autoinc = "";
    }
    
    if ( $typeAttr ) {
        $typeAttr =~ s/\\a/'/g;
    }

    $datatype .= $typeAttr;
    
    my $quotes         = ( defined $default and $default =~ m!^\d+(?:\.\d*)?$! ) ?
                                    "" : "'";
    
    my $info           = '';
    $info .= $notnull.' '              if $notnull;
    $info .= sprintf "DEFAULT %s%s%s ", $quotes,$default,$quotes
                                       if defined $default and $default ne '';
    $info .= $autoinc                  if $autoinc;
    
    $info  =~ s!\s+\z!!;
    
    $self->_add_columns( $parent_table, {$name => [$datatype,$info]} );
    $self->_add_column_details( $parent_table, $col->{att} );
    $self->_key( $parent_table, $name ) if $col->{att}->{PrimaryKey};
}# _column

sub _relation{
    my ($self,$t,$rel) = @_;
    
    my $src       = $self->_tableid( $rel->{att}->{SrcTable} );
    my @relations = split(/\\n/,$rel->{att}->{FKFields});
    my ($obj)     = grep{$_->name() eq $src}$self->_all_tables;
    my $f_id      = $self->_tableid( $rel->{att}->{DestTable} );
    my ($f_table) = grep{$_->name() eq $f_id}$self->_all_tables;
    my $type      = $rel->{att}->{Kind};
    
    for my $relation(@relations){
        my ($owncol,$foreign) = split(/=/,$relation,2);
        $obj->addRelation(    [ 1, $f_id.'.'.$foreign, $src.'.'.$owncol, $type ]);
        $f_table->addRelation([ 1, $f_id.'.'.$foreign, $src.'.'.$owncol, $type ]);
    }
}# _relation

sub _index{
    my ($self) = @_;
}# _index

sub _is_fabforce{
    my ($self,$value) = @_;
    $self->{_ISFABFORCE_} = $value if defined $value;
    return $self->{_ISFABFORCE_};
}

sub _add_table{
    my ($self,$table) = @_;
    push @{ $self->{_TABLES_} }, $table;
}

sub _reset_tables{
    my ($self) = @_;
    $self->{_TABLES_} = [];
}

sub _all_tables{
    my ($self) = @_;
    
    return @{ $self->{_TABLES_} };
}

sub _reset_columns{
    my ($self) = @_;
    $self->{_COLUMNS_} = {};
}

sub _table_columns{
    my ($self,$name) = @_;
    return $self->{_COLUMNS_}->{$name} if exists $self->{_COLUMNS_}->{$name};
    return;
}

sub _add_columns{
    my ($self,$table,$value) = @_;
    push @{ $self->{_COLUMNS_}->{$table} }, $value if defined $value;
}

sub _table_column_details {
    my ($self, $name) = @_;
    return $self->{_COLUMN_DETAILS_}->{$name};
}

sub _add_column_details {
    my ($self, $table, $details) = @_;
    push @{ $self->{_COLUMN_DETAILS_}->{$table} }, $details if defined $details;
}

sub _reset_relationsid{
    my ($self) = @_;
    $self->{_RELATIONSID_} = {};
}

sub _relationsid{
    my ($self,$key,$value) = @_;
    $self->{_RELATIONSID_}->{$key} = $value if defined $value;
    return $self->{_RELATIONSID_}->{$key} if exists $self->{_RELATIONSID_}->{$key};
    return;
}

sub _reset_tableids{
    my ($self) = @_;
    $self->{_TABLEIDS_} = {};
}

sub _tableid{
    my ($self,$id,$value) = @_;
    $self->{_TABLEIDS_}->{$id} = $value if defined $value;
    return $self->{_TABLEIDS_}->{$id} if exists $self->{_TABLEIDS_}->{$id};
    return;
}

sub _key{
    my ($self,$table,$value) = @_;
    push @{ $self->{_KEYS_}->{$table} }, $value if defined $value;
    return $self->{_KEYS_}->{$table} if exists $self->{_KEYS_}->{$table};
    return;
}

sub _printRelations{
    my ($self,$struct) = @_;
    return " ";
}# _printRelations

sub _datatypes{
    my ($type,$key) = @_;
    $key = uc($key);
    my %name2id = (
                   'TINYINT'            =>  1,
                   'SMALLINT'           =>  2,
                   'MEDIUMINT'          =>  3,
                   'INT'                =>  4,
                   'INTEGER'            =>  5,
                   'BIGINT'             =>  6,
                   'FLOAT'              =>  7,
                   'DOUBLE'             =>  9,
                   'DOUBLE PRECISION'   => 10,
                   'REAL'               => 11,
                   'DECIMAL'            => 12,
                   'NUMERIC'            => 13,
                   'DATE'               => 14,
                   'DATETIME'           => 15,
                   'TIMESTAMP'          => 16,
                   'TIME'               => 17,
                   'YEAR'               => 18,
                   'CHAR'               => 19,
                   'VARCHAR'            => 20,
                   'BIT'                => 21,
                   'BOOL'               => 22,
                   'TINYBLOB'           => 23,
                   'BLOB'               => 24,
                   'MEDIUMBLOB'         => 25,
                   'LONGBLOB'           => 26,
                   'TINYTEXT'           => 27,
                   'TEXT'               => 28,
                   'MEDIUMTEXT'         => 29,
                   'LONGTEXT'           => 30,
                   'ENUM'               => 31,
                   'SET'                => 32,
                   'Varchar(20)'        => 33,
                   'Varchar(45)'        => 34,
                   'Varchar(255)'       => 35,
                   'GEOMETRY'           => 36,
                   'LINESTRING'         => 38,
                   'POLYGON'            => 39,
                   'MULTIPOINT'         => 40,
                   'MULTILINESTRING'    => 41,
                   'MULTIPOLYGON'       => 42,
                   'GEOMETRYCOLLECTION' => 43,
                  );
    my %id2name;
    for( keys %name2id ){
        $id2name{$name2id{$_}} = uc($_);
        $name2id{uc($_)}       = $name2id{$_};
        $name2id{lc($_)}       = $name2id{$_};
    }
    
    my $value;
    if($type eq 'name2id' && exists($name2id{$key})){
      $value = $name2id{$key};
    }
    elsif($type eq 'id2name' && exists($id2name{$key})){
      $value = $id2name{$key};
    }
    else{
        $value = 35;
    }
    
    return $value;
}# _datatypes

1;
__END__
=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head2 writeXML

=head2 parsefile


=cut
