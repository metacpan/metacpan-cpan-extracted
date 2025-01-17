# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl stat2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 25;
use Data::Dumper;
use File::stat;
use Fcntl qw (S_IRUSR S_IWUSR S_IXUSR);

BEGIN { &use_ok('File::stat2') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub eqv
{
  return (($_[0] && $_[1]) or ((! $_[0]) && (! $_[1])));
}

for my $file ('Makefile', 'Makefile22')
  {
    my $st1 = stat  ($file);
    my $st2 = stat2 ($file);

    &ok (&eqv ($st1, $st2), 'equivalent');

    next unless ($st1);

    &isa_ok ($st1, 'File::stat');
    &isa_ok ($st2, 'File::stat');
    &isa_ok ($st2, 'File::stat2');

    &ok (scalar (@$st1) == scalar (@$st2), 'same size');

    for my $attr (qw (dev ino mode nlink uid gid rdev size blksize blocks))
      {
        &ok ($st1->$attr eq $st2->$attr, "check $attr");
      }
    for my $attr (qw (atime mtime ctime))
      {
        &ok (abs ($st1->$attr - $st2->$attr) <= 1., "check $attr");
      }

    &ok (&eqv (-x $st1, -x $st2), 'check -x');
    &ok (&eqv (-f $st1, -f $st2), 'check -f');

    for my $mode (S_IRUSR, S_IWUSR, S_IXUSR)
      {
        &ok (&eqv ($st1->cando (S_IRUSR, 1), $st2->cando (S_IRUSR, 1)), "check cando $mode");
      }

  }
