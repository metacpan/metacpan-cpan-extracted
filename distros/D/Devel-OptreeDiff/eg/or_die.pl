use Data::Dumper 'Dumper';
use Devel::OptreeDiff 'fmt_optree_diff';
print
    map "$_\n",
    fmt_optree_diff( sub { print @_  },
                     sub { print @_ or die $! } );
