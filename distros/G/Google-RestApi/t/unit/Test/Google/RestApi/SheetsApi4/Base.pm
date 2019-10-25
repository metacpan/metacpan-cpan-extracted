package Test::Google::RestApi::SheetsApi4::Base;

use YAML::Any qw(Dump);
use Test::Most;
use Test::Mock::Worksheet;

use parent 'Test::Class';

sub startup : Tests(startup => 1) {
  my $self = shift;
  $self->{name} = "'Customer_Addresses'!";
  use_ok $self->class();
  return;
}

sub constructor {
  my $self  = shift;

  my $class = $self->class();
  can_ok $class, 'new';
  ok my $obj = $class->new(@_), '... and the constructor should succeed';
  isa_ok $obj, $class, '... and the object it returns';

  return;
}

sub worksheet : Test(setup) { shift->{worksheet} = Test::Mock::Worksheet->new(); }

1;
