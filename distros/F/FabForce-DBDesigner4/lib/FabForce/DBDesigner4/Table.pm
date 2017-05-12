package FabForce::DBDesigner4::Table;

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    IDENTIFYING_1_TO_1
    IDENTIFYING_1_TO_N
    NON_IDENTIFYING_1_TO_N
    NON_IDENTIFYING_1_TO_1
);

our %EXPORT_TAGS = (
    'const' => [@EXPORT_OK]
);

use constant {
    IDENTIFYING_1_TO_1     => 0,
    IDENTIFYING_1_TO_N     => 1,
    NON_IDENTIFYING_1_TO_N => 2,
    NON_IDENTIFYING_1_TO_1 => 5,
};

our $VERSION     = '0.07';

sub new{
    my ($class,%args) = @_;
    my $self = {};
    
    bless $self,$class;
    
    $self->{COORDS}          = [];
    $self->{COLUMNS}         = [];
    $self->{COLUMNS_DETAILS} = [];
    $self->{NAME}            = '';
    $self->{RELATIONS}       = [];
    $self->{KEY}             = [];
    $self->{ATTRIBUTE}       = {};
  
    $self->{COORDS}          = $args{-coords}         if(_checkArg('coords'        , $args{-coords}        ));
    $self->{COLUMNS}         = $args{-columns}        if(_checkArg('columns'       , $args{-columns}       ));
    $self->{COLUMNS_DETAILS} = $args{-column_details} if(_checkArg('columnsdetails', $args{-columnsdetails}));
    $self->{NAME}            = $args{-name}           if(_checkArg('name'          , $args{-name}          ));
    $self->{RELATIONS}       = $args{-relations}      if(_checkArg('relations'     , $args{-relations}     ));
    $self->{KEY}             = $args{-key}            if(_checkArg('key'           , $args{-key}           ));
    $self->{INDEX}           = $args{-index}          if(_checkArg('index'         , $args{-index}         ));
    $self->{ATTRIBUTE}       = $args{-attr}           if(_checkArg('attribute'     , $args{-attr}          ));
    
    return $self;
}# new

sub columns{
    my ($self,$ar) = @_;
    unless($ar && _checkArg('columns',$ar)){
        my @columns;
        for my $col(@{$self->{COLUMNS}}){
            my $string = join('',keys(%$col));
            for my $val(values(%$col)){
                for my $elem(@$val){
                    if( defined $elem ){
                        $elem = 'VARCHAR(255)'              if $elem =~ /^varchar$/i;
                        $elem = "ENUM('1','0') DEFAULT '0'" if $elem =~ /^enum$/i;
                        
                        $string .= " ".$elem;
                    }
                }
            }
            push(@columns,$string);
        }
        return @columns;
    }
    $self->{COLUMNS} = $ar;
    return 1;
}# columns

sub column_details {
    my ($self, $details) = @_;

    if ( $details && _checkArg('columndetails', $details) ) {
        $self->{COLUMNS_DETAILS} = $details;
    }

    return $self->{COLUMNS_DETAILS};
}

sub column_names{
    my ($self) = @_;
    my @names;
    
    for my $col ( @{ $self->{COLUMNS} } ){
        push @names, join '', keys %$col;
    }

    return @names;
}

sub columnType{
    my ($self,$name) = @_;
    return unless($name);
    
    my $type = '';
    
    for(0..scalar(@{$self->{COLUMNS}})-1){
        my ($key) = keys(%{$self->{COLUMNS}->[$_]});
        if($key eq $name){
            $type = $self->{COLUMNS}->[$_]->{$key}->[0];
            last;
        }
    }
    return $type;
}# columnType

sub columnInfo{
    my ($self,$nr) = @_;
    return $self->{COLUMNS}->[$nr];
}# columnInfo

sub addColumn{
    my ($self,$ar) = @_;
    return unless($ar && ref($ar) eq 'ARRAY');
    push(@{$self->{COLUMNS}},{$ar->[0] => [@{$ar}[1,2]]});
    return 1;
}# addColumn

sub stringsToTableCols{
    my ($self,@array) = @_;
    
    my @returnArray;
    for my $col(@array){
        $col =~ s!,\s*?$!!;
        $col =~ s!^\s*!!;
        next if((not defined $col) or $col eq '');
        my ($name,$type,$info) = split(/\s+/,$col,3);
        push(@returnArray,{$name => [$type,$info]});
    }
    
    return @returnArray;
}# arrayToTableCols

sub coords{
    my ($self,$ar) = @_;
    return @{$self->{COORDS}} unless($ar && _checkArg('coords',$ar));
    $self->{COORDS} = $ar;
    return 1;
}# start

sub name{
    my ($self,$value) = @_;
    return $self->{NAME} unless($value && _checkArg('name',$value));
    $self->{NAME} = $value;
    return 1;
}# name

sub relations{
    my ($self,$value) = @_;
    return @{$self->{RELATIONS}} unless($value && _checkArg('relations',$value));
    $self->{RELATIONS} = $value;
    return 1;
}# relations

sub addRelation{
    my ($self,$value) = @_;
    return unless($value && ref($value) eq 'ARRAY' && scalar(@$value) == 4);
    push(@{$self->{RELATIONS}},$value);
    return 1;
}# addRelation

sub removeRelation{
    my ($self,$index) = @_;
    return unless(defined $index or $index > (scalar(@{$self->{RELATIONS}})-1));
    splice(@{$self->{RELATIONS}},$index,1);
}# removeRelation

sub changeRelation{
    my ($self,$index,$value) = @_;
    return unless(defined $index and defined $value);
    $self->{RELATIONS}->[$index]->[0] = $value;
}# changeRelation

sub key{
    my ($self,$value) = @_;
    return @{$self->{KEY}} unless($value && _checkArg('key',$value));
    $self->{KEY} = $value;
    return 1;
}# key

sub tableIndex{
    my ($self,$value) = @_;
    return @{$self->{INDEX}} unless($value && _checkArg('index',$value));
    $self->{INDEX} = $value;
    return 1;
}# tableIndex

sub attribute{
    my ($self,$value) = @_;
    return @{$self->{ATTRIBUTE}} unless($value && _checkArg('attribute',$value));
    $self->{ATTRIBUTE} = $value;
    return 1;
}# attribute

sub get_foreign_keys{
    my ($table) = @_;
    
    unless( defined $table->{_foreign_relations} ){
        my $tablename = $table->name();
        my @relations = grep{$_->[1] =~ /^$tablename\./}$table->relations();
        $table->{_foreign_relations} = { _getForeignKeys(@relations) };
    }
    return $table->{_foreign_relations};
}

sub _checkArg{
  my ($type,$value) = @_;
  my $return = 0;
  if($value){
    $return = 1 if($type eq 'coords' 
                   && ref($value) eq 'ARRAY' 
                   && scalar(@$value) == 4
                   && !grep{/\D/}@$value);
                   
    $return = 1 if($type eq 'columns'
                   && ref($value) eq 'ARRAY'
                   && !(!grep{ref($_) eq 'HASH'}@$value));

    $return = 1 if( $type eq 'columndetails' && ref($value) eq 'ARRAY' );
                   
    $return = 1 if($type eq 'name' 
                   && ref(\$value) eq 'SCALAR');
    
    $return = 1 if($type eq 'relations' 
                   && ref($value) eq 'ARRAY'
                   && !(!grep{ref($_) eq 'ARRAY'}@$value));
    
    $return = 1 if($type eq 'key'
                   && ref($value) eq 'ARRAY'
                   && !(!grep{ref(\$_) eq 'SCALAR'}@$value));
    
    $return = 1 if($type eq 'index'
                   && ref($value) eq 'ARRAY'
                   && !(!grep{ref(\$_) eq 'SCALAR'}@$value));
                   
    $return = 1 if($type eq 'attribute'
                   && ref($value) eq 'HASH');
  }
  
  return $return;
}# checkArg



sub _getForeignKeys{
    my @rels = @_;
    my %relations;
    for my $rel(@rels){
        next unless $rel;
        my $start           = (split(/\./,$rel->[1]))[1];
        my ($table,$target) =  split(/\./,$rel->[2]);
        push(@{$relations{$table}},[$start,$target]);
    }
    return %relations;
}# getForeignKeys

1;
__END__

=head1 DBDesigner4::Table

Each table is an object which contains information about the columns,
the relations and the keys.

Methods of the table-objects

=head2 name

  # set the tablename
  $table->name('tablename');
  # get the tablename
  my $name = $table->name();
  
=head2 columns

  # set the tablecolumns
  my @array = ({'column1' => ['int','not null']});
  $table->columns(\@array);
  
  # get the columns
  print $_,"\n" for($table->columns());
  
=head2 columnType

  # get datatype of n-th column (i.e. 3rd column)
  my $datatype = $table->columnType(3);
  
=head2 columnInfo

  # get info about n-th column (i.e. 4th column)
  print Dumper($table->columnInfo(4));
  
=head2 stringsToTableCols

  # maps column information to hash (needed for columns())
  my @columns = ('col1 varchar(255) primary key', 'col2 int not null');
  my @array   = $table->stringsToTableCols(@columns);

=head2 addColumn

  # add the tablecolumn
  my $column = ['column1','int','not null'];
  $table->addColumn($column);

=head2 relations

  # set relations
  my @relations = ([1,'startTable.startCol','targetTable.targetCol']);
  $table->relations(\@relations);
  # get relations
  print $_,"\n" for($table->relations());

=head2 addRelation

  $table->addRelation([1,'startTable.startCol','targetTable.targetCol']);

=head2 removeRelation

  # removes a relation (i.e. 2nd relation)
  $table->removeRelation(2);

=head2 key

  # set the primary key
  $table->key(['prim1']);
  # get the primary key
  print "the primary key contains these columns:\n";
  print $_,"\n" for($table->key());

=head2 attribute

=head2 changeRelation

=head2 coords

=head2 new

=head2 tableIndex

=head2 column_details

=head2 column_names

  my @names = $table->column_names
  print $_,"\n" for @names;

=head2 get_foreign_keys

  my %foreign_keys = $table->get_foreign_keys;
  use Data::Dumper;
  print Dumper \%foreign_keys;

=cut
