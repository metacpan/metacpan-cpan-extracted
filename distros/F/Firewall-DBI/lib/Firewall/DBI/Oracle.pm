package Firewall::DBI::Oracle;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use DBIx::Custom;

#------------------------------------------------------------------------------
# 继承 Firewall::DBI::Role 方法属性
#------------------------------------------------------------------------------
with 'Firewall::DBI::Role';

has option => ( is => 'ro', isa => 'Undef | HashRef[Str]', default => undef, );

has '+dbi' => ( isa => 'DBIx::Custom', handles => qr/^(?:select|update|insert|delete|execute|user).*/, );

for my $func (qw( execute delete update insert batchExecute )) {
  around $func => sub {
    my $orig = shift;
    my $self = shift;
    my $result;

    eval {
      $result = $self->$orig(@_);
      $self->dbi->dbh->commit;
    };

    if ( !!$@ ) {
      if ( $self->dbi->dbh->rollback ) {
        confess "ERROR: $@";
      }
      else {
        confess "ERROR: $@\n" . $self->dbi->dbh->errstr;
      }
    }
    else {
      return $result;
    }
  };
}

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  my %param = ( @_ > 0 and ref( $_[0] ) eq 'HASH' ) ? %{$_[0]} : @_;

  if ( not defined $param{dsn} and defined $param{host} and defined $param{port} and defined $param{sid} ) {
    $param{dsn} = "dbi:Oracle:host=$param{host};sid=$param{sid};port=$param{port}";
  }

  return $class->$orig(%param);
};

sub clone {
  my $self = shift;
  return __PACKAGE__->new( dsn => $self->dsn, user => $self->user, password => $self->password,
    option => $self->option );
}

sub batchExecute {
  my $self = shift;
  $self->_rawExecute(@_);
}

sub _rawExecute {

  # 比multipleInsert略快，适合大批量或语句较复杂的操作
  my ( $self, $paramRef, $sqlString ) = @_;
  my $num = 0;
  my $sth = $self->dbi->dbh->prepare($sqlString);
  for my $param ( @{$paramRef} ) {
    $sth->execute( @{$param} );
    $self->dbi->dbh->commit if ++$num % 5000 == 0;
  }
}

sub _buildDbi {
  my $self  = shift;
  my %param = ( dsn => $self->dsn, user => $self->user, password => $self->password );
  $param{option} = $self->option // {AutoCommit => 0, RaiseError => 1, PrintError => 0};

  if ( defined $ENV{LANG} ) {
    $ENV{NLS_CURRENCY}      = '*';
    $ENV{NLS_DUAL_CURRENCY} = '*';
  }

  my $dbi = DBIx::Custom->connect(%param);
  $dbi->quote('');
  return $dbi;
}

sub disconnect {
  my $self = shift;
  $self->dbi->dbh->disconnect;
}

sub reconnect {
  my $self = shift;
  $self->disconnect;
  $self->{dbi} = $self->_buildDbi;
}

__PACKAGE__->meta->make_immutable;
1;
