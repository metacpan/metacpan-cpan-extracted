use strict;
use warnings;
use Test::More;

use feature ':all';

use File::Basename qw<dirname>;
my $file=__FILE__;
my $dir=dirname $file;

{
  #Perform a check only . Redirect stderr to stdout
  my $cmd="$^X -I $dir/../lib -MError::Show -c $dir/syntax-ok.pl";
  my $result=`$cmd 2>&1`;

  ok $result =~ /syntax OK/;
  ok $? == 0, "Status code";
}

{
  #Run if no errors
  my $cmd="$^X -I $dir/../lib -MError::Show $dir/syntax-ok.pl";
  my $result=`$cmd 2>&1`;

  ok $result =~ /HELLO/;
  ok $? == 0, "Status code";
}


{
  #Test a file with a warning
  #Perform a check only . Redirect stderr to stdout
  my $cmd="$^X -I $dir/../lib -MError::Show -c $dir/syntax-warning.pl";
  my $result=`$cmd 2>&1`;

  ok $result =~ /syntax OK/;
  ok $? == 0, "Status code";
}

{
  #Test a file with a warning
  #Run if no errors
  my $cmd="$^X -I $dir/../lib -MError::Show $dir/syntax-warning.pl";
  my $result=`$cmd 2>&1`;

  ok $result =~ /HELLO/;
  ok $? == 0, "Status code";
}
{
  #Test a file with a warning. But we force it to treat the warning as an error
  #when just checking
  #
  my $cmd="$^X -I $dir/../lib -MError::Show=warn -c $dir/syntax-warning.pl";
  my $result=`$cmd 2>&1`;

  ok $result =~ /HELLO/;
  ok $? == 0, "Status code";
}
{

  #Test a file with a error
  #should fail
  my $cmd="$^X -I $dir/../lib -MError::Show -c $dir/syntax-error.pl";
  my $result=`$cmd 2>&1`;

  say STDERR $result;
  ok $result !~ /syntax OK/;
  ok $? != 0, "Status code";
}
{

  #Run a file with a error
  #should fail
  my $cmd="$^X -I $dir/../lib -MError::Show $dir/syntax-error.pl";
  my $result=`$cmd 2>&1`;

  say STDERR $result;
  ok $result !~ /syntax OK/;
  ok $? != 0, "Status code";
}




done_testing;
