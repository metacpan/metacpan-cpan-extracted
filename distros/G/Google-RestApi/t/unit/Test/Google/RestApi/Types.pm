package Test::Google::RestApi::Types;

use Test::Unit::Setup;

use File::Basename qw( dirname );

use parent 'Test::Class';

use Google::RestApi::Types qw( :all );

sub readable_fs : Tests(6) {
  my $self = shift;
  is_valid $0, ReadableFile, "File is readable";
  is_not_valid "xxxx", ReadableFile, "File does not exist";
  is_not_valid dirname($0), ReadableFile, "File is a dir";
  is_valid dirname($0), ReadableDir, "Dir is readable";
  is_not_valid $0, ReadableDir, "Dir is a file and";
  is_not_valid "xxxx", ReadableDir, "Dir does not exist";
  return;
}

1;
