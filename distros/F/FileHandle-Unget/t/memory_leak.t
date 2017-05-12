use strict;
use FileHandle::Unget;
use Test::More tests => 1;

eval 'require Devel::Leak';

# For initial memory allocation
new FileHandle::Unget();

# Check for memory leaks.
SKIP:
{
  skip('Devel::Leak not installed',1) unless defined $Devel::Leak::VERSION;

  my $fhu_handle;

  my $start_fhu = Devel::Leak::NoteSV($fhu_handle);

  my $fhu = new FileHandle::Unget();
  undef $fhu;

  my $end_fhu = Devel::Leak::NoteSV($fhu_handle);

  # 1
  cmp_ok($end_fhu - $start_fhu, '<=', 0, 'Memory leak');
}
