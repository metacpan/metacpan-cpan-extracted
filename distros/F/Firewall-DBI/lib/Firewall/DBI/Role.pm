package Firewall::DBI::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;

has dsn => ( is => 'ro', isa => 'Str', required => 1, );

has user => ( is => 'ro', isa => 'Str', required => 1, );

has password => ( is => 'ro', isa => 'Str', required => 1, );

has dbi => ( is => 'ro', lazy => 1, builder => '_buildDbi', );

#------------------------------------------------------------------------------
# 继承该角色必须实现的方法
#------------------------------------------------------------------------------
requires 'clone';
requires 'batchExecute';

sub getAttrMembers {
  my ( $self, $attrTypes, $dataObj ) = @_;
  my $attrMembers = {};
  my ( $min, $max ) = ( 0, 0 );
  for my $attr ( keys %{$attrTypes} ) {
    my $attrType = $attrTypes->{$attr};
    if ( $attrType eq '@' ) {
      $attrMembers->{$attr} = $dataObj->$attr;
    }
    elsif ( $attrType eq '%k' ) {
      $attrMembers->{$attr} = [ keys %{$dataObj->$attr} ];
    }
    elsif ( $attrType eq '%v' ) {
      $attrMembers->{$attr} = [ values %{$dataObj->$attr} ];
    }
    my $length = scalar @{$attrMembers->{$attr}};
    $max = $max > $length ? $max : $length;
    $min = $min < $length ? $min : $length;
  }
  return ( wantarray ? ( $attrMembers, $max, $min ) : $attrMembers );
}

sub parseColumnMap {
  my ( $self, $columnMap ) = @_;
  my $attrWhichIsSingle    = {};
  my $attrWhichContainList = {};
  my $attrTypes;
  confess "ERROR: columnMap 参数不是一个数组的引用" if ref($columnMap) ne 'ARRAY';
  for my $columnInfo ( @{$columnMap} ) {
    my ( $column, $attr, $attrType );
    if ( $columnInfo =~ /^\s*(?<column>\w+)\s* => \s*(?<attr>\w+)\s*(?: \| \s* (?<attrType>\@|\%k|\%v) )?\s*$/xo ) {
      ( $column, $attr, $attrType ) = ( $+{column}, $+{attr}, $+{attrType} );
    }
    elsif ( $columnInfo =~ /^\s*(?<column>\w+)\s*(?: \| \s* (?<attrType>\@|\%k|\%v) )?\s*$/xo ) {
      $column   = $attr = $+{column};
      $attrType = $+{attrType};
    }
    else {
      confess "ERROR: columnMap 中的元素 $columnInfo 格式不符合要求";
    }
    if ( defined $attrType ) {
      $attrWhichContainList->{$column} = $attr;
      $attrTypes->{$attr}              = $attrType;
    }
    else {
      $attrWhichIsSingle->{$column} = $attr;
    }
  }
  return ( $attrWhichIsSingle, $attrWhichContainList, $attrTypes );
}

sub batchInsert {
  my ( $self, $columnMap, $tableName, $dataObjs ) = @_;
  my ( $attrWhichIsSingle, $attrWhichContainList, $attrTypes ) = $self->parseColumnMap($columnMap);
  my @params;
  return if not defined $dataObjs;
  # 早期异常拦截
  confess "ERROR: dataObjs 参数不是一个hash的引用 也不是一个数组的引用" if ref($dataObjs) !~ /^(?:HASH|ARRAY)$/o;
  my @columnsSingle = keys %{$attrWhichIsSingle};
  my @attrsSingle   = values %{$attrWhichIsSingle};
  my @columnsList   = keys %{$attrWhichContainList};
  my @attrsList     = values %{$attrWhichContainList};
  my @columns       = ( @columnsSingle, @columnsList );
  my @questionMarks = map {'?'} ( 0 .. $#columns );
  my $sqlString = "insert into $tableName (" . join( ',', @columns ) . ") values (" . join( ',', @questionMarks ) . ")";

  # 从 5.012 values 可以处理数组与hash的引用
  for my $dataObj ( values %{$dataObjs} ) {
    my @param;
    my ( $column, $attr );
    for my $i ( 0 .. $#columnsSingle ) {
      ( $column, $attr ) = ( $columnsSingle[$i], $attrsSingle[$i] );
      $param[$i] = $dataObj->$attr;
    }
    if ( not defined $attrTypes ) {
      push( @params, \@param );
    }
    else {
      my ( $attrMembers, $maxAttrMemberNums ) = $self->getAttrMembers( $attrTypes, $dataObj );
      for my $j ( 0 .. $maxAttrMemberNums - 1 ) {
        for my $k ( 0 .. $#columnsList ) {
          $column                            = $columnsList[$k];
          $attr                              = $attrsList[$k];
          $param[ $#columnsSingle + 1 + $k ] = $attrMembers->{$attr}[$j];
        }
        push( @params, \@param );
      }
    }
  }
  $self->batchExecute( \@params, $sqlString );
}

1;
