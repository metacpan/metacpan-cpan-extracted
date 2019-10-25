package Test::Mock::Drive;

use strict;
use warnings;

use aliased 'Google::RestApi::DriveApi3';
use Test::MockObject::Extends;

use Test::Mock::RestApi;
 
sub new {
  my $self = DriveApi3->new(
    api => Test::Mock::RestApi->new(),
  );
  $self = Test::MockObject::Extends->new($self);
  $self->mock('filter_files', sub { 'aaa: bbb'; });
  return $self;
}

1;
