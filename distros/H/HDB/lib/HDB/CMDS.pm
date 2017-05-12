#############################################################################
## Name:        CMDS.pm
## Purpose:     HDB::CMDS
## Author:      Graciliano M. P.
## Modified by:
## Created:     14/01/2003
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package HDB::CMDS ;
use HDB::Parser ;

use strict qw(vars);
no warnings ;

our $VERSION = '1.0' ;

########
# VARS #
########

  my %args_select = (
  table  =>  [qw(table)] ,
  where  =>  [qw(where w)] ,
  limit  =>  [qw(limit limite)] ,
  sort   =>  [qw(sort order)] ,
  group  =>  [qw(group grop)] ,
  return =>  [qw(return ret r)] ,
  col    =>  [qw(col cols)] ,
  cache  => [[qw(cache)],1] ,
  );
  
  my %DEFAULT_COLS = (
  'address'      => 200 ,
  'age'          => 'INTEGER' ,
  'bairro'       => 30 ,
  'cep'          => 9 ,
  'cidade'       => 40 ,
  'city'         => 40 ,
  'country'      => 4 ,
  'data'         => 'int(9999999999)' ,
  'date'         => 'int(9999999999)' ,
  'descricao'    => 'TEXT' ,
  'email'        => 50 ,
  'endereco'     => 200 ,
  'estado'       => 3 ,
  'fax'          => 'INTEGER' ,
  'hits'         => 'INTEGER' ,
  'hora'         => 8 ,
  'id'           => 'INTEGER' ,
  'idade'        => 'INTEGER' ,
  'mail'         => 50 ,
  'message'      => 'TEXT' ,
  'msg'          => 'TEXT' ,
  'mensagem'     => 'TEXT' ,
  'name'         => 40 ,
  'nick'         => 16 ,
  'nome'         => 40 ,
  'pais'         => 4 ,
  'pass'         => 16 ,
  'password'     => 16 ,
  'phone'        => 'INTEGER' ,
  'preco'        => 15 ,
  'price'        => 15 ,
  'senha'        => 16 ,
  'sex'          => 1 ,
  'sexo'         => 1 ,
  'size'         => 5 ,
  'state'        => 3 ,
  'tamanho'      => 5 ,
  'tel'          => 'INTEGER' ,
  'telefone'     => 'INTEGER' ,
  'temperatura'  => 4 ,
  'time'         => 10 ,
  'titulo'       => 250 ,
  'title'        => 250 ,
  'uf'           => 3 ,
  'uid'          => 8 ,
  'url'          => 250 ,
  'username'     => 16 ,
  'user'         => 16 ,
  'zip'          => 9 ,
  );
  
  
  my @DEFAULT_TYPES = qw(* TEXT INT FLOAT BOOL) ;
  
  my %DEFAULT_MOD = (
  'MySQL'    => 'mysql' ,
  'SQLite'   => 'sqlite' ,
  'Oracle'   => 'Oracle' ,
  ) ;

  
###################
# PREDEFINED_COLS #
###################

sub predefined_columns { return( %DEFAULT_COLS ) ;}

#################
# DEFAULT_TYPES #
#################

sub default_types { return( @DEFAULT_TYPES ) ;}

###############
# DEFAULT_MOD #
###############

sub default_mod { return( %DEFAULT_MOD ) ;}

###########
# ALIASES #
###########

sub sel { &select ;}
sub cols { &names ;}
sub creat { &create ;}
sub create_table { &create ;}
sub predefined_cols { &predefined_columns ;}
sub sql { $_[0]->{sql} ;}

##########
# SELECT #
##########

sub select {
  my $this = shift ;
  my (undef , $where , @args) = @_ ;
  
  if ($_[0] =~ /^table$/i) { @args = @_ ; $where = undef ;}
  elsif ($#_ >= 2 && $#_ <= 3 && ( ref $_[2] || $_[2] =~ /^(?:(?:n|names?|c|cols?|columns?)\s*[,;]*\s*)?(?:\$?[\$\@\%]{1,2}|<[\$\@\%]>)$/i ) ) {
    if (ref $_[2]) { @args = HDB::CORE::parse_ref($_[2]) ;}
    elsif ($#_ == 2) { @args = ('return' , $_[2]) ;}
  }
  elsif ($#_ == 1 && $_[1] =~ /^(?:(?:n|names?|c|cols?|columns?)\s*[,;]*\s*)?(?:\$?[\$\@\%]{1,2}|<[\$\@\%]>)$/i ) {
    @args = ('return' , $_[1]) ;
    $where = undef ;
  }
  
  if ($#_ >= 2 && $where =~ /^(?:cache|col|cols|grop|group|limit|limite|order|r|ret|return|sort|table|w|where)$/si) {
    unshift (@args, $where) ;
    $where = undef ;
  }
  
  my %args ;
  &HDB::CORE::parse_args(\%args , \%args_select , @args) ;
  
  $args{table} = $_[0] if !defined $args{table} ;
  $args{where} = $where if !defined $args{where} ;
  
  $args{table} = _format_table_name($args{table}) ;
  
  if (! defined $args{return}) {
    if ( $_[-1] =~ /^(?:(?:n|names?|c|cols?|columns?)\s*[,;]*\s*)?(?:\$?[\$\@\%]{1,2}|<[\$\@\%]>)$/i ) { $args{return} = $_[-1] ;}
  }
  
  $this->{return} = $args{return} ;
  
  $this->{sql} = undef ;

  {
    my ($cols , $db_max) ;
      
    if ($args{col} =~ /^\s*([<>])\s*([\w\.]+)/) {
      $db_max = $1 ; 
      $cols = $2 ;
    }
    else { $cols = $args{col} ;}

    if ($db_max) {
      if ($db_max eq '>') { $db_max = 'max' ;}
      elsif ($db_max eq '<') { $db_max = 'min' ;}
      if ($cols eq '') { $cols = "$db_max(ID) as ID" ;}
      else { $cols = "$db_max($cols) as $cols" ;}
    }
    elsif ($cols eq "") { $cols = '*' ;}
    else {
      $cols =~ s/^\s*,//s ;
      $cols =~ s/,\s*$//s ;
    }
    
    my $where = &HDB::Parser::Parse_Where($args{where},$this) ;
    
    my $group ;
    if ( $args{group} ) { $group = "GROUP BY $args{group}" ;}
    
    my $sort ;
    
    if ( $args{sort} ) {
      ($sort) = ( $args{sort} =~ /([\w\.]+)/gs ) ;
      $sort = "ORDER BY $sort" ;
      if ($args{sort} =~ /</s) { $sort .= ' DESC' ;}
    }
    #elsif (! defined $args{sort} ) { $sort = "ORDER BY ID" ;}
    
    my $limit ;
    if ($args{limit} ne '') {
      my ($sz,$init) = ( $args{limit} =~ /(\d+)(?:\D+(\d+)|)/ );
      my $into_where ;
      ($limit , $into_where) = $this->LIMIT($sz,$init) ;
      if ( $into_where ) { $where = "$where AND ($into_where)" ;}
    }
    
    $this->{sql} = "SELECT $cols FROM $args{table}" ;
    $this->{sql} .= " $where" if $where ne '' ;
    $this->{sql} .= " $group" if $group ne '' ;
    $this->{sql} .= " $sort" if $sort ne '' ;
    $this->{sql} .= " $limit" if $limit ne '' ;
  }

 $this->_undef_sth ;
 
 eval{
    $this->{sth} = $this->dbh->prepare( $this->{sql} ) ;
    $this->{sth}->{ShowErrorStatement} = 1 ;
    $this->{sth}->execute ;
    $this->{sth}->err ;
  };

  return $this->Error("SQL error: $this->{sql}") if $@ ;
  
  return $this->Return( $args{return} ) ;
}

##########
# INSERT #
##########

sub insert {
  my $this = shift ;
  
  my ($table , @up) = @_ ;
  
  $table = _format_table_name($table) ;
  
  if ($#_ == 1) { @up = HDB::CORE::parse_ref($_[1]) ;}
  
  return $this->Error('Invalid table!') if !$table ;
  return $this->Error('Nothing to insert!') if !@up ;
  
  my @names = $this->names($table) ;

  my @cols ;
  if (ref($_[1]) eq 'HASH') {
    my %up = @up ;
    @up = () ;
    
    foreach my $names_i ( @names ) {
      if    (defined $up{$names_i})     { push(@up , $up{$names_i}) ; push(@cols , $names_i) ;}
      elsif (defined $up{uc($names_i)}) { push(@up , $up{uc($names_i)}) ; push(@cols , $names_i) ;}
      elsif (defined $up{lc($names_i)}) { push(@up , $up{lc($names_i)}) ; push(@cols , $names_i) ;}
      elsif (defined $up{"\u\L$names_i\E"}) { push(@up , $up{"\u\L$names_i\E"}) ; push(@cols , $names_i) ;}
    }
  }
  else { @cols = @names ;}
  
  foreach my $up_i ( @up ) {
    if (ref($up_i) eq 'HASH') { $up_i = &HDB::Encode::Pack_HASH($up_i) ;}
    elsif (ref($up_i) eq 'ARRAY') { $up_i = &HDB::Encode::Pack_ARRAY($up_i) ;}
    &HDB::Parser::filter_null_bytes($up_i) ;
  }
  
  $this->_undef_sth ;

  {
    my @ins_pnt = ('?') x @up ;
    $this->{sql} = "INSERT INTO $table (". join(',',@cols) .") VALUES (". join(',',@ins_pnt) .")" ;
    eval { $this->{sth} = $this->dbh->prepare( $this->{sql} ) };
  }
  
  $this->{sth}->{ShowErrorStatement} = 1 ;
  
  eval {
    $this->lock_table($table) if $this->{SQL}{LOCK_TABLE} ;
    $this->{sth}->execute(@up) ;
    $this->unlock_table($table) if $this->{SQL}{LOCK_TABLE} ;
    $this->{sth}->err ;
  };
  
  $this->_undef_sth ;
  
  return $this->Error("SQL error: $this->{sql}\nERROR MSG:\n$@") if $@ ;
  
  $this->ON_INSERT(\@cols,\@up) if $this->can('ON_INSERT') ;
  
  return 1 ;
}

##########
# UPDATE #
##########

sub update {
  my $this = shift ;
  my ($table , $where , %up) = @_ ;
  
  $table = _format_table_name($table) ;
  
  if ($#_ == 2) { %up = HDB::CORE::parse_ref($_[2]) ;}
  
  if (! $table) { $this->Error('Invalid table!') ;}
  if (! %up) { $this->Error('Nothing to update!') ;}
  
  $where = &HDB::Parser::Parse_Where($where,$this) ;
  
  my ($set_cols,@up) ;
  
  my @names = $this->names($table) ;
    
  foreach my $names_i ( @names ) {
    if    (defined $up{$names_i})     { push(@up , $up{$names_i}) ; $set_cols .= "$names_i = ? , " ;}
    elsif (defined $up{uc($names_i)}) { push(@up , $up{uc($names_i)}) ; $set_cols .= "\U$names_i\E = ? , " ;}
    elsif (defined $up{lc($names_i)}) { push(@up , $up{lc($names_i)}) ; $set_cols .= "\L$names_i\E = ? , " ;}
    elsif (defined $up{"\u\L$names_i\E"}) { push(@up , $up{"\u\L$names_i\E"}) ; $set_cols .= "\u\L$names_i\E = ? , " ;}
  }

  return if !@up ;
  
  foreach my $up_i ( @up ) {
    if (ref($up_i) eq 'HASH') { $up_i = &HDB::Encode::Pack_HASH($up_i) ;}
    elsif (ref($up_i) eq 'ARRAY') { $up_i = &HDB::Encode::Pack_ARRAY($up_i) ;}
    &HDB::Parser::filter_null_bytes($up_i) ;
  }
  
  $set_cols =~ s/ , $// ;
  
  $this->{sql} = "UPDATE $table SET $set_cols $where" ;

  $this->_undef_sth ;
  eval { $this->{sth} = $this->dbh->prepare( $this->{sql} ) };  
  
  eval {
    $this->lock_table($table) if $this->{SQL}{LOCK_TABLE} ;
    $this->{sth}->execute(@up) ;
    $this->unlock_table($table) if $this->{SQL}{LOCK_TABLE} ;
  };
  
  $this->_undef_sth ;
  
  return $this->Error("SQL error: $this->{sql}\nERROR MSG:\n$@") if $@ ;
  return 1 ;
}

##########
# DELETE #
##########

sub delete {
  my $this = shift ;
  my ($table , $where) = @_ ;
  
  $table = _format_table_name($table) ;
  
  if (! $table) { $this->Error('Invalid table!') ;}
  
  $where = &HDB::Parser::Parse_Where($where,$this) ;
  
  $this->{sql} = "DELETE FROM $table $where" ;
  
  eval {
    $this->lock_table($table) if $this->{SQL}{LOCK_TABLE} ;
    $this->dbh->do( $this->{sql} ) ;
    $this->unlock_table($table) if $this->{SQL}{LOCK_TABLE} ;
  };

  return $this->Error("SQL error: $this->{sql}\nERROR MSG:\n$@") if $@ ;
  return 1 ;
}

##########
# CREATE #
##########

sub create {
  my $this = shift ;
  my ($table , @cols) = @_ ;
  
  $table = _format_table_name($table) ;
  
  if ($#_ == 1) { @cols = HDB::CORE::parse_ref($_[1]) ;}
  
  if (! $table) { $this->Error('Invalid table!') ;}
  if (! @cols) { $this->Error('Cols not paste!') ;}
  
  my %tables = map { ("\L$_\E") => 1 } ($this->tables) ;
  if ( $tables{"\L$table\E"} ) { return ;}
  
  my (%cols,@order) ;
  
  for (my $i = 0 ; $i <= $#cols ; $i+=1) {
    my $name = $cols[$i] ;
    my $type ;
    
    if (ref($name)) {
      $name = HDB::CORE::parse_ref($name) ;
      $type = 'DEFAULT' ;
    }
    else { $type = $cols[$i+1] ; $i++ ;}
    
    my $is_primary ;
    if ($name =~ /^\s*\*/) { $name =~ s/^\s*\*\s*//gs ; $is_primary = 1 ;}
    
    $name =~ s/^\s+//gs ;
    $name =~ s/\s+$//gs ;
    
    $type = $this->get_type( $type , $name ) ;

    if ($is_primary) { $type = $this->Set_PRIMARYKEY($type) ;}
    
    push(@order , $name) ;
    $cols{$name} = $type ;
  }
  
  if (ref($_[1]) eq 'HASH') { @order = sort @order ;}
  
  if (! $cols{id}) {
    push(@order , 'id') ;
    $cols{id} = $this->AUTOINCREMENT() ;
    if ($cols{id} !~ /PRIMARY[\s_-]*KEY/si) { $cols{id} .= ' PRIMARY KEY' ;}
  }
  
  $this->{sql} = "CREATE TABLE $table (" ;
  
  my $c ;
  foreach my $order_i ( @order ) {
    if (++$c > 1) { $this->{sql} .= " , " ;}
    $this->{sql} .= "$order_i $cols{$order_i}" ;
  }
  
  $this->{sql} .= ")" ;
  
  eval { $this->dbh->do( $this->{sql} ) };

  return $this->Error("SQL error: $this->{sql}\nERROR MSG:\n$@") if $@ ;
  
  $this->ON_CREATE($table,\%cols,\@order) if $this->can('ON_CREATE') ;
  
  return 1 ;
}

#######
# CMD #
#######

sub cmd {
  my $this = shift ;
  
  $this->{sql} = $_[0] ;
  my $return = $_[1] ;
  
  $this->_undef_sth ;
  
  eval{
    $this->{sth} = $this->dbh->prepare( $this->{sql} ) ;
    $this->{sth}->execute ;
  };

  return $this->Error("SQL error: $this->{sql}") if $@ ;
  
  return $this->Return( $return ) ;
}

#########
# NAMES #
#########

sub names {
  my $this = shift ;
  my ( $table ) = @_ ;
  
  $table = _format_table_name($table) ;
  
  if (! $table) { return $this->Error('Invalid table!') ;}
  elsif ( $this->{CACHE}{names}{$table} ) { return @{ $this->{CACHE}{names}{$table} } ;}
  
  if ( $this->{SQL}{SHOW} ) { $this->{sql} = "SHOW COLUMNS FROM $table" ;}
  elsif ( $this->{SQL}{LIMIT} ) { $this->{sql} = "SELECT * FROM $table LIMIT 1" ;}
  else { $this->{sql} = "SELECT * FROM $table" ;}
  
  $this->_undef_sth ;
  eval{
    $this->{sth} = $this->dbh->prepare( $this->{sql} ) ;
    $this->{sth}->execute ;
  };

  return $this->Error("SQL error: $this->{sql}") if $@ ;

  my @names ;
  
  if (  $this->{SQL}{SHOW}  ) {
    while (my $ref = $this->{sth}->fetchrow_arrayref) { push(@names , @$ref[0]) ;}
  }
  else {
    ## substr() to make a copy of the value and avoid DBI bug!
    eval { @names = map { substr($_ , 0) } @{ $this->{sth}->{'NAME'} } };
    #eval { @names = @{ $this->{sth}->{'NAME'} } };
  }
  
  $this->_undef_sth ;

  return () if !@names ;
  
  if ( $this->{cache} ) {
    $this->{CACHE}{names}{$table} = \@names ;
  }
  
  return @names ;
}

##########
# TABLES #
##########

sub tables {
  my $this = shift ;

  my @tables = map {
    $_ =~ s/.*\.//;
    $_ =~ s/(['"`])(.*)\1/$2/gs; ## some DB return quoted.
    $_
  } $this->dbh->tables() ;
 
  return( sort @tables ) ;
}

###############
# TABLES_HASH #
###############

sub tables_hash {
  return map { $_ => 1 } $_[0]->tables ;
}

################
# TABLE_EXISTS #
################

sub table_exists {
  my %tables = $_[0]->tables ;
  return 1 if $tables{$_[1]} ;
  return ;
}

#################
# TABLE_COLUMNS #
#################

sub table_columns {
  my $this = shift ;
  my ( $table ) = @_ ;

  if (! $table) { $this->Error('Invalid table!') ; return ;}
  
  return $this->dbh->table_info($table) ;
}

########
# DROP #
########

sub drop {
  my $this = shift ;
  my ( $table ) = @_ ;
  
  $table = _format_table_name($table) ;
  
  if (! $table) { $this->Error('Invalid table!') ; return ;}
  
  my %tables = map { ("\L$_\E") => 1 } ($this->tables) ;
  if (! $tables{"\L$table\E"} ) { return ;}
  
  $this->flush_table_cache($table) ;
  
  eval{ $this->dbh->do("DROP TABLE $table") };

  return $this->Error("DROP ERROR: table $table") if $@ ;
  
  $this->ON_DROP($table) if $this->can('ON_DROP') ;
  
  return 1 ;
}

##############
# DUMP_TABLE #
##############

sub dump_table {
  my $this = shift ;
  my ( $table ) = @_ ;
  
  $table = _format_table_name($table) ;
  
  if (!$table) { $this->Error('Invalid table!') ; return ;}
  
  my $dump ;

  $dump .= "TABLE $table:\n\n" ;
      
  my %cols = $this->table_columns($table) ;
  my @cols = $this->names($table) ;
  
  foreach my $Key (@cols) {
    $dump .= "  $Key = $cols{$Key}\n" ;
  }
  
  $dump .= "\nROWS:\n\n" ;
  
  my @sel = $this->select( $table , '@$' ) ;
  foreach my $sel_i ( @sel ) {
    $dump .= "$sel_i\n" ;
  }
  
  return $dump ;
}

###############
# FLUSH_CACHE #
###############

sub flush_cache {
  if ( !$_[0]->{CACHE} ) { return ;}
  my @sth = $_[0]->_get_cache_sth ;
  delete $_[0]->{CACHE} ;
  foreach my $sth_i ( @sth ) { $sth_i->finish if $sth_i ;}
  return 1 ;
}

#####################
# FLUSH_TABLE_CACHE #
#####################

sub flush_table_cache {
  my $this = shift ;
  my ( $table ) = @_ ;
  
  $table = _format_table_name($table) ;
  
  if ( !$this->{CACHE} ) { return ;}

  my @sth = $this->_get_cache_table_sth($table) ;

  delete $this->{CACHE}{names}{$table} ;
  delete $this->{CACHE}{insert}{$table} ;
  delete $this->{CACHE}{update}{$table} ;
  
  foreach my $sth_i ( @sth ) { $sth_i->finish if $sth_i ;}
  
  return 1 ;
}

######################
# _FORMAT_TABLE_NAME #
######################

sub _format_table_name {
  my ( $table ) = @_ ;
  $table =~ s/(?:\.|::)/_/gs ;
  $table =~ s/[^\w\.]//gs ;
  return $table ;
}

#######################
# _FORMAT_COLUMN_NAME #
#######################

sub _format_column_name {
  my ( $col ) = @_ ;
  $col =~ s/(?:\.|::)/_/gs ;
  $col =~ s/[^\w\.]//gs ;
  return $col ;
}

##################
# _GET_CACHE_STH #
##################

sub _get_cache_sth {
  my $cache = $_[0]->{CACHE} ;
  my @types = qw(insert update) ;
  
  my @sth ;
  
  foreach my $types_i ( @types ) {
    foreach my $Key ( keys %{$$cache{$types_i}} ) {
      push(@sth , $$cache{$types_i}{$Key}{sth} ) ;
    }
  }
  
  return @sth ;
}

########################
# _GET_CACHE_TABLE_STH #
########################

sub _get_cache_table_sth {
  my $cache = $_[0]->{CACHE} ;
  my $table = $_[1] ;
  my @types = qw(insert update) ;
  
  my @sth ;
  
  foreach my $types_i ( @types ) {
    push(@sth , $$cache{$types_i}{$table}{sth} ) ;
  }
  
  return @sth ;
}

##############
# _UNDEF_STH #
##############

sub _undef_sth {
  if ( $_[0]->{sth} ) {
    $_[0]->{sth}->finish ;
    $_[0]->{sth} = undef ;
  }
}

##########
# RETURN #
##########

sub Return {
  my $this = shift ;
  my ( $return ) = @_ ;

  my $ret_names ;

  $return =~ s/\s//gs ;
  if ($return =~ /^(?:n|c)/si ) {
    $ret_names = 1 ;
    $return =~ s/[^\$\@\%<>]//gs ;
  }

  if ($return !~ /^(?:\$?[\$\@\%]{1,2}|<[\$\@\%]>)$/ ) { $return = '$' ;}

  $return =~ s/^\$\$\%$/\$\$\@/ ;
  $return =~ s/^\%\%$/\$\%/ ;
  
  my $sth = $_[1] || $this->{sth} ;
  return undef if !$sth ;
  
  if ($return =~ /<\s*([\$\@\%])\s*>\s*$/) {
    my $type = $1 ;
    local(*HANDLE);
    tie(*HANDLE, 'HDB::CMDS::TieHandle',$sth,$type) ;
    return( \*HANDLE ) ;
  }
  
  my $ret_type ;
  if    ($return =~ /\@$/) { $ret_type = 1 ;}
  elsif ($return =~ /\%$/) { $ret_type = 2 ;}

  my @names ;
  
  eval{
    my $names = $sth->{'NAME'} ;
    @names = @{$names} ;
  };
  
  if (! @names) { $this->_undef_sth ; return undef ;}
  
  my @rows ;
  while (my $ref = $sth->fetchrow_arrayref) {
    foreach my $ref_i ( @$ref ) {
      &HDB::Parser::unfilter_null_bytes($ref_i) ;
      
      if    ( &HDB::Encode::Is_Packed_HASH($ref_i) ) { $ref_i = &HDB::Encode::UnPack_HASH($ref_i) ;}
      elsif ( &HDB::Encode::Is_Packed_ARRAY($ref_i) ) { $ref_i = &HDB::Encode::UnPack_ARRAY($ref_i) ;}
    }
    if ($ret_type == 1) { push(@rows , [@$ref]) ;}
    elsif ($ret_type == 2) {
      my %hash ;
      for my $i (0..$#names) { $hash{ $names[$i] } = $$ref[$i] ;}
      push(@rows , \%hash) ;
    }
    else { push(@rows , join("::" , @$ref ) ) ;}
  }
  
  $this->_undef_sth ;
  
  my @ret_names ;
  
  if ($ret_names) { @ret_names = \@names ;}
  
  if ($return =~ /^[\@\%\$]$/) {
    if (wantarray) { return( @ret_names , @rows ) ;}
    else { return( $rows[0] ) ;}
  }
  elsif ($return =~ /^\$\$$/) { return( @ret_names , $rows[0] ) ;}
  elsif ($return =~ /^\$\@$/) { return( @ret_names , @{ $rows[0] } ) ;}
  elsif ($return =~ /^\$\%$/) { return( @ret_names , %{ $rows[0] } ) ;}
  elsif ($return =~ /^\$\$\@$/) {
    if    ( ref( @{$rows[0]}[0] ) eq 'HASH' )  { return( @ret_names , %{@{$rows[0]}[0]} ) ;}
    elsif ( ref( @{$rows[0]}[0] ) eq 'ARRAY' ) { return( @ret_names , @{@{$rows[0]}[0]} ) ;}
    else                                       { return( @ret_names , @{ $rows[0] } ) ;}
  }
  elsif ($return =~ /^\@[\@\%\$]$/) { return( @ret_names , @rows ) ;}
}

# $
# @
# %
# @@
# @%
# %%

############
# GET_TYPE #
############

sub get_type {
  my $this = shift ;
  my ( $type , $name ) = @_ ;
  
  $type =~ s/^\s+//gs ;
  $type =~ s/\s+$//gs ;

  ## *
  
  if ($type =~ /^(?:\*|)$/s) { $type = 'TEXT' ;}


  ## TEXT

  if ($type eq 'TEXT' || $type =~ /^(?:TEXT\s*)?(\d+|\(\s*\d+\s*\))$/s) {
    my $sz = $1 ; $sz =~ s/\D//gs ;
    $sz = 65535 if $sz eq '' ;
    
    if ( !$this->Accept_Type('TEXT') ) { $type = $this->Type_TEXT($sz) ;}
    else {
      if    ($sz == 0)           { $type = "INTEGER" ;}
      elsif ($sz <= 255)         { $type = "VARCHAR($sz)" ;}
      elsif ($sz <= 65535 )      { $type = 'TEXT' ;}
      elsif ($sz <= 16777215 )   { $type = 'MEDIUMTEXT' ;}
      elsif ($sz <= 4294967295 ) { $type = 'LONGTEXT ' ;}
      if ( !$this->Accept_Type($type) ) { $type = $this->Type_TEXT($sz) ;}
    }
  }
  
  ## INTEGER
  
  if ($type =~ /^(?:INTEGER|INT)\s*(?:\(?([\+\-]?\d+|\w+)\)?|)$/si) {
    my $sz = $1 ;
    
    if ( !$this->Accept_Type('INTEGER') ) { $type = $this->Type_INTEGER($sz) ;}
    else {
      if (!$sz) { $type = "INTEGER" ;}
      elsif ($sz =~ /^(?:t|tin|shor)/i) { $type = "TINYINT" ;}
      elsif ($sz =~ /^(?:s|sma)/i) { $type = "SMALLINT" ;}
      elsif ($sz =~ /^(?:m|med)/i) { $type = "MEDIUMINT" ;}
      elsif ($sz =~ /^(?:b|big)/i) { $type = "BIGINT" ;}
      elsif ($sz =~ /^[\+\-]?\d+$/) {
        if    ($sz >= -127 && $sz <= 127)               { $type = "TINYINT" ;}
        elsif ($sz >= -32768 && $sz <= 32767)           { $type = "SMALLINT" ;}
        elsif ($sz >= -8388608 && $sz <= 8388607)       { $type = "MEDIUMINT" ;}
        elsif ($sz >= -2147483648 && $sz <= 2147483647) { $type = "INTEGER" ;}
        elsif ($sz < -2147483648 || $sz > 2147483647)   { $type = "BIGINT" ;}
      }
      if (! $this->Accept_Type($type)) { $type = $this->Type_INTEGER($sz) ;}
    }
  }
  
  ## FLOAT
  
  elsif ($type =~ /^(\s*[\+\-]\s*(?:FLOATING|FLOAT|DOUBLE))\s*(?:\((.*?)\)|())$/si) {
    $type = $this->Type_FLOAT($1,$2) ;
  }
  
  ## INT
  
  elsif ($type =~ /\w+INT$/si) {
    if (! $this->Accept_Type($type)) { $type = 'INTEGER' ;}
  }
  
  ## BOOLEAN
  
  elsif ($type =~ /^(?:boolean|boo?l)$/si) { $type = 'BOOLEAN' ;}
  
  ## AUTO
  
  elsif ($type =~ /^(?:AUTOINCREMENT|AUTO)$/si) { $type = $this->AUTOINCREMENT() ;}
  
  ## DEF
  
  elsif ($type =~ /^(?:DEFAULT|DEF)$/si) {
    $type = $DEFAULT_COLS{$name} || 'TEXT' ;
    $type = $this->get_type($type) ;
  }
  
  ## TYPE MASK:
  
  if ( $this->{SQL}{TYPES_MASK} && $this->{SQL}{TYPES_MASK}{$type} ) {
    $type = $this->{SQL}{TYPES_MASK}{$type} ;
  }
  
  return( $type ) ;
}

##################
# SET_PRIMARYKEY #
##################

sub Set_PRIMARYKEY {
  my $this = shift ;
  my ( $type ) = @_ ;
  
  my $primarykey = $this->PRIMARYKEY() ;
  my $primarykey_re = $primarykey ;
  $primarykey_re =~ s/\s+/\\s\+/gs ;
  
  if ($type !~ /$primarykey_re/si) { $type .= " $primarykey" ;}
  
  return( $type ) ;
}

###############
# ACCEPT_TYPE #
###############

sub Accept_Type {
  my $this = shift ;
  my $type = "\L$_[0]\E" ;
  
  if (ref($this->{SQL}{TYPES}) eq 'ARRAY') {
    my %types = map { ("\L$_\E") => 1 } @{ $this->{SQL}{TYPES} } ;
    $this->{SQL}{TYPES} = \%types ;
  }
  
  if ( $this->{SQL}{TYPES}{$type} || $this->{SQL}{TYPES}{'*'} ) { return( 1 ) ;}
  return( undef ) ;
}

########################
# HDB::CMDS::TIEHANDLE #
########################

package HDB::CMDS::TieHandle ;

sub TIEHANDLE {
  my $class = shift ;
  my $this = { sth => $_[0] , type => $_[1] } ;
  bless($this , $class) ;
}

sub READLINE  {
  my $this = shift ;
  my $sth = $this->{sth} ;

  if ($this->{type} eq "\$") {
    my $ref = $sth->fetchrow_arrayref ; return if !$ref ;
    return( join("::" , @$ref ) ) ;
  }
  elsif ($this->{type} eq "\@") {
    my $ref = $sth->fetchrow_arrayref ; return if !$ref ;
    foreach my $ref_i ( @$ref ) {
      &HDB::Parser::unfilter_null_bytes($ref_i) ;
      
      if    ( &HDB::Encode::Is_Packed_HASH($ref_i) ) { $ref_i = &HDB::Encode::UnPack_HASH($ref_i) ;}
      elsif ( &HDB::Encode::Is_Packed_ARRAY($ref_i) ) { $ref_i = &HDB::Encode::UnPack_ARRAY($ref_i) ;}
    }
    return( @$ref ) ;
  }
  elsif ($this->{type} eq "\%") {
    my $ref = $sth->fetchrow_hashref ; return if !$ref ;
    foreach my $Key ( keys %$ref ) {
      &HDB::Parser::unfilter_null_bytes($$ref{$Key}) ;
      
      if    ( &HDB::Encode::Is_Packed_HASH($$ref{$Key}) ) { $$ref{$Key} = &HDB::Encode::UnPack_HASH($$ref{$Key}) ;}
      elsif ( &HDB::Encode::Is_Packed_ARRAY($$ref{$Key}) ) { $$ref{$Key} = &HDB::Encode::UnPack_ARRAY($$ref{$Key}) ;}
    }
    return( %$ref ) ;
  }

  return ;
}

sub DESTROY  {

}

#######
# END #
#######

1;

__END__

=head1 NAME

HDB::CMDS - Hybrid DataBase Commands

=head1 DESCRIPTION

This are the commands/methods to access/manage the databases.

=head1 select

Make a SQL select query.

Example:

  my @sel = $HDB->select('users' , 'name =~ joe' , '@%') ; ## table , where , return
  
  ## ... or ...
  
  my @sel = $HDB->select('users' , 'name =~ joe' , cols => 'name,user,id' , limit => 1 , '@%') ;
  
  ## ... or ...
  
  my @sel = $HDB->select(
  table  => 'users' ,           ## Need to start with 'table' to paste a full HASH of arguments!
  where  => 'name == joe' ,
  col    => 'name, user , id' ,
  limit  => '1' ,
  sort   => 'id' ,
  group  => 'name' ,
  cache  => '0' ,
  return => '@%' ,  
  ) ;
  

B<Arguments:>

=over 10

=item TABLE

The table name.

=item WHERE

Where condintion. See the topic 'WHERE' for format.

=item COL

Columns to return and order, separated by ','.

Example:

  col => 'city'        # Return only the column city.
  col => 'city,state'  # Return the column city and state in this order.
  col => '>ID'         # Return the max ID.
  col => '<ID'         # Return the min ID.


=item LIMIT

Limit of return or/and start of returns.

Example:

  limit => '10'    # Make the limit of returns to 10.
  limit => '10,2'  # Make the limit of returns to 10 and the returns will start from 2.
  limit => '0,2'   # Returns will start from 2.

=item SORT

Column to use for sort (order). If > or < is used in the beggin set the ascending or descending sort.

Example:

  sort => 'ID'   # Sort by ID in the ascending order.
  sort => '>ID'  # Sort by ID in the ascending order.
  sort => '<ID'  # Sort by ID in the *descending order.

=item GROUP

Column(s) to group.

Example:

  group => 'city'          # Group only the col city
  group => 'city , state'  # Group the col city and state.


=item CACHE

Turn on/off the cache of sth and col names.

=item RETURN

The return type. See the topic L</RETURN> for format.

=back

=head1 insert ( table , data )

Insert data inside a table.

You can call it sending the data by column order or hash (by column name):

  # Cols of table users: name , email , id

  $HDB->insert( 'users' , 'joe' , 'joe@mail.com' , 1 );
  
  # Or with a hash:
  
  $HDB->insert( 'users' , {
  'name' => 'joe' ,
  'email' => 'joe@mail.com' ,
  'id' => 1 ,
  } );

=head1 update ( table , where , data )

Update a table. The data need to be a HASH or a ref to a HASH:

  $HDB->update( 'users' , 'user == joe' , {
  name => 'Joe Tribiany' ,
  email => 'foo@mail.com' ,
  } );
  
  # Or:
  
  $HDB->update( 'users' , 'user == joe' , name => 'Joe Tribiany' , email => 'foo@mail.com' );

=head1 delete ( table , where )

Delete entrys of a table:

  $HDB->delete( 'users' , 'user == joe' );

=head1 create ( table , columns )

Create a new tables. You send the columns in the order that they will be in the table, and the TYPES are based in the size:

  $HDB->create( 'users' ,
  user  => 100 ,            # A col for strings, with the max size 100.
  name  => 150 ,            # A col for strings, with the max size 150.
  more  => 4096 ,           # A col for strings, with the max size 4Kb.
  more2 => 1048576          # A col for strings, with the max size 1Mb.
  more3 => '*'              # A col for strings.
  age   => 'int(200)' ,     # A col for numbers, with the max number 200.
  numb  => 'float' ,        # A floating point with normal precision.
  numb1 => 'double' ,       # A floating point with big precision.
  numb2 => 'float(10)' ,    # A floating point with precision 10.
  numb3 => '+float(10,4)' , # for floating points. This will be unsigned (only positive values).
                            # 10 is the max digit size (including decimal).
                            # 4 is the precision (number digits after decimal point).
  adm   => bool ,           # For boolean entrys.
  );
  
  ** FLOAT is not enable in any database, and can be changed to INTEGER. The precision and UNSIGNED options are not enabled for all too.
  ** Use FLOAT for normal precision, and DOUBLE for big precision for portable way.
  
In MySQL the cols type will be:

  $HDB->create( 'users' ,
  user  => 100 ,            # VARCHAR(100)
  name  => 150 ,            # VARCHAR(150)
  more  => 4096 ,           # TEXT
  more2 => 1048576          # MEDIUMTEXT
  more3 => '*'              # TEXT
  age   => 'int(200)' ,     # SMALLINT
  numb  => 'float' ,        # FLOAT
  numb1 => 'double' ,       # DOUBLE
  numb2 => 'float(10)' ,    # FLOAT(10)
  numb3 => '+float(10,4)' , # FLOAT(10,4) UNSIGNED
  adm   => bool ,           # BOOLEAN
  );
  
In SQLite the cols type will be:

  $HDB->create( 'users' ,
  user  => 100 ,            # VARCHAR(100)
  name  => 150 ,            # VARCHAR(150)
  more  => 4096 ,           # TEXT
  more2 => 1048576          # TEXT
  more3 => '*'              # TEXT
  age   => 'int(200)' ,     # INTEGER
  numb  => 'float' ,        # FLOAT
  numb1 => 'double' ,       # FLOAT
  numb2 => 'float(10)' ,    # FLOAT
  numb3 => '+float(10,4)' , # FLOAT
  adm   => bool ,           # BOOLEAN  
  );

B<** Note that the column ID will be always created and will be AUTOINCREMENT, unless you set the type by your self.>

You can use predefined col names (templates) for the columns. This is good if you don't want to think in the size that the type of data can have:

  $HDB->create( 'users' ,
  user  => 100 ,
  ['email'] ,      # The predefined col name. Same as:   email => 50
  name  => 150 ,
  );

=head1 drop ( table )

Drop (remove) a table:

  $HDB->drop( 'users' );

=head1 cmd ( SQL , RETURN )

Send a SQL query to the database. The return will be in the format of the argument RETURN:

  my @sel = $HDB->cmd('select * from users','@%');


=head1 dump_table

Return a string with the table dumped.

=head1 tables

Return an ARRAY with tables of the database.

=head1 table_exists ( TABLE )

Return TRUE if TABLE exists.

=head1 tables_hash

Same as tables(), but return a HASH, with the tables as keys and 1 as values.
Good if you want to make: if ($tables{users}) {...}

=head1 table_columns

Return a HASH with the columns and respective type (based in the DB type).

=head1 names

Return an ARRAY with the names of the columns in the table, with the respective order.

=head1 sql

Return the last SQL command sent to the DB.

=head1 flush_cache

Clean the HDB cache (in the HDB object, not in the database).

=head1 flush_table_cache

Clean the HDB cache of a table (in the HDB object, not in the database).

=head1 get_type

Convert the HDB type to the database type:

  my $db_col_type = $HDB->get_type( 1000 );
  
  ...
  
  my $db_col_type = $HDB->get_type( 'int(200)' );

=head1 default_types

Return a list of the default types of HDB.

=head1 predefined_columns

Return a HASH with the predefined columns and sets.

=head1 default_mod

Return a HASH with the HDB::MOD installed by default in this version.

The HASH:

  keys   => full name.
  values => id for HDB.

=head1 RETURN

Commands like select has a return argument, that will tell how to format the results and the type of the variable.

The return has 2 parts.

First, the type of the variable (@|$):

  @ >> Will return an array.
  $ >> Will return the first line of the results (row), or the parsed reference of the 2nd part.
  
  ** If the first part is omitted, @ will be used.

Second, the format ($|@|%):

  $ >> The rows will have the columns separated by '::', like:  joe::joe@mail.com::1
  @ >> The cols of each row will be inside an ARRAY.
  % >> The cols of each row will be inside a HASH.

Examples:

  return => '@$'   # Will return an ARRAY, with the cols in each line of the array separated by '::'.
  return => '@@'   # Will return an ARRAY of ARRAYS (with the cols in the SUB-ARRAY).
  return => '@%'   # Will return an ARRAY of HASHES (with the cols in the HASH).

  return => '$$'   # Will return the cols of the first result (row) separated by '::'. (return a sinlge SCALAR)
  return => '$@'   # Will return the cols of the first result (row) inside an ARRAY. (return a sinlge ARRAY)
  return => '$%'   # Will return the cols of the first result (row) inside a HASH. (return a sinlge HASH)
  
  return => '$$@'  # Special case: Parse the encoded ref of the first col in the first row. See HDB::Encode.
  return => '$$%'  # Same as $$@.

  return => '<$>'  # Special: Parse sth row by row, returning a SCALAR, with the columns separated by '::'.
  return => '<@>'  # Special: Parse sth row by row, returning a ARRAY with the values of the columns.
  return => '<%>'  # Special: Parse sth row by row, returning a HASH of columns and values.
  
  return => '$'    # Like @$
  return => '@'    # Like @@
  return => '%'    # Like @%

  return => '%%'   # Like $%

If you want the list of columns returned, put NAMES in the begin of return:

  return => 'NAMES,@@'  # Will return the reference to an ARRAY with the columns names and the ARRAY of ARRAYS.
  
  ## USAGE:
  my ($cols_names , @sel) = $HDB->select('users','NAMES,@%') ;
  my @cols_names = @$cols_names ;

The best way to think in the I<RETURN> type is to think in what variable type will receive the result,
and in what type you want the informations inside the result.

  ## For an ARRAY receiveing and for informations in HASH type: @%
  my @sel = $HDB->select('users','@%') ;
  print "$sel[0]{name}\n" ;
  
  ## For a SCALAR receiveing and for informations in ARRAY type: $@
  my $name = $HDB->select('users', col => 'name' , '$@') ;
  
  ## For a HASH receiveing and for informations in HASH type: %%
  my %user = $HDB->select('users', "id == 1" '%%') ; ## return only 1 row!
  print "$user{name}\n" ;

=head2 RETURN USAGE (Code Examples):

  my @sel = $HDB->select( table => users , return => '@$' );
  
  foreach my $sel_i ( @sel ) {
    my @cols = split("::" , $sel_i) ;
    ...
  }
  
  ##########################################################

  my @sel = $HDB->select( table => users , return => '@@' );
  
  foreach my $sel_i ( @sel ) {
    my @cols = @$sel_i ;
    ...
  }
  
  ##########################################################

  my @sel = $HDB->select( table => users , return => '@%' );
  
  foreach my $sel_i ( @sel ) {
    my %cols = %$sel_i ;
    ...
  }
  
  ##########################################################

  my ($names,@sel) = $HDB->select( table => users , return => 'NAMES,@%' );
  my @names = @$names ;

  foreach my $sel_i ( @sel ) {
    my %cols = %$sel_i ;
    ...
  }
  
  ##########################################################

  my %hash = $HDB->select( table => users , col => 'encoded' , return => '$$@' );
  
  foreach my $Key ( keys %hash ) {
    my $Value = $hash{$Key} ;
    print "$Key = $Value\n" ;
  }
  
  ##########################################################
  
  my $hdbhandle = $HDB->select( table => users , return => '<$>' );
  
  while( my $row = <$hdbhandle> ) {
    my @cols = split("::" , $row) ;
    ...
  }
  
  ##########################################################
  
  my $hdbhandle = $HDB->select( table => users , return => '<@>' );
  
  while( my @cols = <$hdbhandle> ) {
    ...
  }
  
  ##########################################################
  
  my $hdbhandle = $HDB->select( table => users , return => '<%>' );
  
  while( my %cols = <$hdbhandle> ) {
    foreach my $Key ( keys %cols ) { print "$Key = $cols{$Key}\n" ;}
    ...
  }
  
  ##########################################################

  my $sel_row_0 = $HDB->select( table => users , return => '$$' );
  my @cols = split("::" , $sel_row_0) ;
  
  ##########################################################

  my @cols = $HDB->select( table => users , return => '$@' ); ## Return ROW 0.
  
  ##########################################################

  my %cols = $HDB->select( table => users , return => '$%' ); ## Return ROW 0.
  

=head1 SEE ALSO

L<HDB>, L<HDB::Encode>, L<HDB::sqlite>, L<HDB::mysql>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

