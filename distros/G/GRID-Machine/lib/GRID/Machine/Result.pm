package GRID::Machine::Result;
use List::Util qw(first);
use overload q("") => 'str',
             '0+'  => 'bool';

my @legal = qw(type stdout stderr results errcode errmsg);
my %legal = map { $_ => 1 } @legal;

{ # Compatibility with the past: aliases
  no warnings;
  *rstdout = \&stdout;
  *rstderr = \&stderr;
}

sub new {
  my $class = shift || die "Error: Provide a class\n";
  my %args = @_;

  my $a = "";
  die "Illegal arg  $a\n" if $a = first { !exists $legal{$_} } keys(%args);

  $args{stderr}  = '' unless $args{stderr};
  $args{stdout}  = '' unless $args{stdout};
  $args{errcode} =  0 unless $args{errcode};
  $args{errmsg}  = '' unless $args{errmsg};

  bless \%args, $class;
}

sub ok {
  my $self = shift;

  return $self->{type} ne 'DIED';
}

sub noerr {
  my $self = shift;

  return (($self->{type} ne 'DIED') and  ($self->{stderr} eq ''));
}

sub bool {
  my $self = shift;

  0+$self->Results > 1 ? scalar($self->Results) : $self->result;
}

sub result {
  my $self = shift;

  return $self->{results}[0];
}

sub Results {
  my $self = shift;

  return @{$self->{results}};
}

sub str {
  my $self = shift;

  return $self->{stdout}.$self->{stderr}.$self->{errmsg}
}

GRID::Machine::MakeAccessors::make_accessors(@legal);

1;
