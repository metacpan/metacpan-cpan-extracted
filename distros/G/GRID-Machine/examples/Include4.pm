use strict;
use List::Util qw(sum);

sub sigma {
  sum(@_);
}

LOCAL {
  print "Installing new functions\n";
  for (qw(r w e x z s f d  t T B M A C)) {
    SERVER->sub( "$_" => qq{
        my \$file = shift;

        return -$_ \$file;
      }
    );
  }
}
