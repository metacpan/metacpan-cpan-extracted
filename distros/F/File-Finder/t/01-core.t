#! perl
use Test::More 'no_plan';

# use File::Find;
# use Data::Dumper;
# $Data::Dumper::Deparse = 1;

## test presence of documented protocol

require_ok('File::Finder');

can_ok('File::Finder',
       qw(new as_wanted as_options in collect));

require_ok('File::Finder::Steps');
can_ok('File::Finder::Steps',
       qw(or left begin right end not true false comma
	  follow
	  name perm type
	  print print0
	  user group nouser nogroup
	  links inum size atime mtime ctime
	  exec ok
	  prune
	  depth
	  ls
	  ffr
	 ));

isa_ok(my $f = File::Finder->new, "File::Finder");
isa_ok($f->as_wanted, "CODE");
isa_ok($f->as_options, "HASH");
