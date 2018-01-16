package MarpaX::Languages::PowerBuilder::SRQ;
no if $] >= 5.018, warnings => "experimental::smartmatch";
use base qw(MarpaX::Languages::PowerBuilder::base);

#a SRQ parser and compiler to SQL by Nicolas Georges

sub unref{
    return unless defined wantarray;
    my $val = shift;
    my $ref = ref $val;
    return unless $ref;
    my $unref={
        ARRAY  => sub{ @$val }, 
        HASH   => sub{ %$val }, 
        SCALAR => sub{ $$val }, 
        GLOB   => sub{ $$val }, 
        REF    => sub{ $$val }, 
        Regexp => sub{ $val  },   #don't unref a regexp.
    };
    return $unref->{$ref}() if exists $unref->{$ref};
    for(keys %$unref){
        return $unref->{$_}() 
            if $val->isa($_);
    }
    return;
}

sub value{
    my $self =shift;
    #lazzy retrieve of value
    $self->{value} = $self->{recce}->value unless exists $self->{value};
    $self->{value};
}

sub sql{
    my $self = shift;
    my $val = $self->value();
    return _compile( $$val );
}

sub _compile{
    my $ast = shift;
    my $level = shift // 1;
    my $tabs = "\t" x $level;
    my $select = exists $ast->{select} ? $ast->{select} : $ast;
    my $sql;
    #arguments
    foreach my $arg(unref $ast->{arguments}){
        $sql .= "// argument $arg->{name} ($arg->{type})\n";
    }
    $sql .= "SELECT";
    $sql .= ' DISTINCT ' if exists $select->{distinct};
    $sql .= "\n\t";
    $sql .= join ",\n\t", map{ $$_ } unref $select->{selection}//[];
    $sql .= "\n\tFROM ";
    $sql .= join ",\n\t", unref $select->{tables}//[];
    #joins are threated like where clause
    if(unref $select->{wheres}//[] + unref $select->{joins}//[]){
        $sql .= "\n\tWHERE ";
        my $where = "(";
        foreach( unref $select->{wheres} ){
            $where .= "\t";
            $where .= "($_->{exp1} " . uc($_->{op})." ";
            if(ref $_->{exp2}){
                $where .= "(" . _compile($_->{exp2}, $level+1) . ")";
            }
            else{
                $where .= "$_->{exp2}";
            }
            $where .= ")";
            $where .= uc " $_->{logic}\n" if exists $_->{logic};
        }
        $where .=")\n";
        
        my @joins = map{ "\t(" . join(" ", $_->{left}, uc($_->{op}), $_->{right}).")" } unref $select->{joins};
        $sql .= join " AND\n", @joins, $where;
    }
    #groups
    if(unref $select->{groups}//[]){
      $sql .= "\tGROUP BY ";
      $sql .= join ",\n\t", unref $select->{groups};
    }
    #havings
    if(unref $select->{havings}//[]){
        $sql .= "\n\tHAVING ";
        foreach( unref $select->{havings} ){
            $sql .= "\t";
            $sql .= "($_->{exp1} " . uc($_->{op})." ";
            $sql .= "$_->{exp2})";
            $sql .= uc " $_->{logic}\n" if exists $_->{logic};
        }
    }
    #unions
    $sql .= "\n" if exists $select->{unions};
    foreach my $union ( unref $select->{unions}//[] ){
        $sql .= "UNION(\n";
        $sql .= _compile( $union, $level+1 );
        $sql .= ")\n";
    }
    #orders
    if(exists $ast->{orders}){
        $sql .= "\tORDER BY ";
        $sql .= join ",\n\t" , map { $_->{name} . " " . uc $_->{dir} } unref $ast->{orders};
    }
    
    if($level > 1){
        $sql =~ s/^/$tabs/gm;
    }
    return $sql;
}

sub version{
    my (undef, $name, @children) = @_;
    return { lc $name => $children[1] };
}

sub table{
    my (undef, $name, @children) = @_;
    return $children[3];
}

sub tables{
    my (undef, @children) = @_;
    return { 'tables' => \@children };
}

sub distinct{ { 'distinct' => @_>1?1:0 } }

sub column{
    my (undef, $name, @children) = @_;
    return bless \$children[3], 'column';
}

sub selection{
    my (undef, @children) = @_;
    return { 'selection' => \@children };
}

sub compute{
    my (undef, $name, @children) = @_;
    return bless \$children[3], 'compute';
}

sub join{
    my (undef, $name, @children) = @_;
    return { left => $children[3], op => $children[6], right => $children[9] };
}

sub joins{
    my (undef, @children) = @_;
    return { 'joins' => \@children };
}

sub argument{
    my (undef, $name, @children) = @_;
    return { name => $children[3], type => $children[6] };
}

sub arguments{
    my (undef, @children) = @_;
    return { 'arguments' => \@children };
}

sub where_logic{
    my (undef, $name, @children) = @_;
    return { exp1 => $children[3], op => $children[6], exp2 => $children[7], logic => $children[10] };
}

sub where{
    my (undef, $name, @children) = @_;
    return { exp1 => $children[3], op => $children[6], exp2 => $children[7] };
}

sub where_exp2{
    my (undef, $name, @children) = @_;
    return $children[1];
}

sub where_nest{
    my (undef, $name, @children) = @_;
    return $children[1];
}

sub wheres{
    my (undef, @children) = @_;
    return { 'wheres' => \@children };
}

sub group{
    my (undef, $name, @children) = @_;
    return $children[3];
}

sub groups{
    my (undef, @children) = @_;
    return { 'groups' => \@children };
}

sub having_logic{
    my (undef, $name, @children) = @_;
    return { exp1 => $children[3], op => $children[6], exp2 => $children[7], logic => $children[10] };
}

sub havings{
    my (undef, @children) = @_;
    return { 'havings' => \@children };
}

sub order{
    my (undef, $name, @children) = @_;
    return { name => $children[3], dir => (lc($children[6]//'no') eq 'yes')?'asc':'desc' };
}

sub orders{
    my (undef, @children) = @_;
    return \@children;
}

sub pbselect{
    my (undef, @children) = @_;
    my %mixed;
    %mixed = (%mixed, %$_) for grep{ exists $_->{unions} ? not $_->{unions} ~~ [] : 1 } grep { ref eq 'HASH' } @children;
    return \%mixed;
}

sub unions{ shift; { unions => [ @_ ] } }
sub union { $_[3] }

sub query{
    my (undef, @children) = @_;
    my $h = { select => $children[0] };
    $h->{orders} = $children[1] unless $children[1] ~~ [];
    $h->{arguments} = $children[2]->{arguments} unless $children[2]->{arguments} ~~ [];
    return $h;
}

sub selection_item{
    my (undef, $item) = @_;
    return $item;
}

sub string{
    my (undef, $string) = @_;
    #remove bounding quotes and escape chars.
    $string =~ s/^"|"$//g;
    $string =~ s/~(.)/$1/g;
    return $string;
}

sub quoted_db_identifier{
    my (undef, $dbidentifier) = @_;
    return $dbidentifier;
}

1;