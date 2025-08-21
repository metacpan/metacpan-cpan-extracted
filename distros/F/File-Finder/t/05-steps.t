#! perl
use Test::More 'no_plan';

require_ok('File::Finder');

isa_ok(my $f = File::Finder->new, "File::Finder");

use File::Find;
sub fin {
  my $wanted = shift;

  my @results;
  find(sub {$wanted->() and push @results, $File::Find::name}, @_);
  @results;
}

is_deeply([File::Finder->in(qw(.))],
	  [fin(sub { 1 }, '.')],
	  'all names');

is_deeply([File::Finder->name(qr/\.t$/)->in(qw(.))],
	  [fin(sub { /\.t$/ }, '.')],
	  'all files named *.t via regex');

is_deeply([File::Finder->name('*.t')->in(qw(.))],
	  [fin(sub { /\.t$/ }, '.')],
	  'all files named *.t via glob');

is_deeply([File::Finder->perm('+0444')->in(qw(.))],
	  [fin(sub { (stat($_))[2] & 0444 }, '.')],
	  'readable by someone');

is_deeply([File::Finder->perm('-0444')->in(qw(.))],
	  [fin(sub { ((stat($_))[2] & 0444) == 0444 }, '.')],
	  'readable by everyone');

is_deeply([File::Finder->perm('+0222')->in(qw(.))],
	  [fin(sub { (stat($_))[2] & 0222 }, '.')],
	  'writeable by someone');

is_deeply([File::Finder->perm('+0111')->in(qw(.))],
	  [fin(sub { (stat($_))[2] & 0111 }, '.')],
	  'executable by someone');

is_deeply([File::Finder->perm('0644')->in(qw(.))],
	  [fin(sub { ((stat($_))[2] & 0777) == 0644 }, '.')],
	  'mode 0644');

is_deeply([File::Finder->perm('0755')->in(qw(.))],
	  [fin(sub { ((stat($_))[2] & 0777) == 0755 }, '.')],
	  'mode 755');

{
  my $dirperm = (stat ".")[2] & 07777;
  is_deeply([File::Finder->perm($dirperm)->in(qw(.))],
	    [fin(sub { ((stat($_))[2] & 07777) == $dirperm }, '.')],
	    'mode same as current directory');
}

is_deeply([File::Finder->type('f')->in(qw(.))],
	  [fin(sub { -f }, '.')],
	  'all files');

is_deeply([File::Finder->eval(sub { stat('/') })->type('f')->in(qw(.))],
	  [fin(sub { -f }, '.')],
	  'all files even after messing with _ pseudo handle');

SKIP: {
  skip 'user/group tests not supported on this platform', 8 if $^O eq 'MSWin32';

  is_deeply([File::Finder->user($<)->in(qw(.))],
	    [fin(sub { -o }, '.')],
	    'owned');

  is_deeply([File::Finder->not->user($<)->in(qw(.))],
	    [fin(sub { not -o }, '.')],
	    'not owned');

  is_deeply([File::Finder->group(0+$()->in(qw(.))],
	    [fin(sub { $( == (stat)[5] }, '.')],
	    'group');

  is_deeply([File::Finder->not->group(0+$()->in(qw(.))],
	    [fin(sub { $( != (stat)[5] }, '.')],
	    'not group');

  is_deeply([File::Finder->nouser->in(qw(.))],
	    [fin(sub { not defined getpwuid((stat)[4]) }, '.')],
	    'nouser');

  is_deeply([File::Finder->not->nouser->in(qw(.))],
	    [fin(sub { defined getpwuid((stat)[4]) }, '.')],
	    'not nouser');

  is_deeply([File::Finder->nogroup->in(qw(.))],
	    [fin(sub { not defined getgrgid((stat)[5]) }, '.')],
	    'nogroup');

  is_deeply([File::Finder->not->nogroup->in(qw(.))],
	    [fin(sub { defined getgrgid((stat)[5]) }, '.')],
	    'not nogroup');
}

is_deeply([File::Finder->links('-2')->in(qw(.))],
	  [fin(sub { (stat)[3] < 2 }, '.')],
	  'less than 2 links');

is_deeply([File::Finder->links('+1')->in(qw(.))],
	  [fin(sub { (stat)[3] > 1 }, '.')],
	  'more than 1 link');

is_deeply([File::Finder->size('-10c')->in(qw(.))],
	  [fin(sub { -s $_ < 10 }, '.')],
	  'less than 10 bytes');

is_deeply([File::Finder->size('+10c')->in(qw(.))],
	  [fin(sub { -s $_ > 10 }, '.')],
	  'more than 10 bytes');

is_deeply([File::Finder->contains('AvErYuNlIkElYsTrInG')->in(qw(.))],
	  ["./" . __FILE__],
	  'files with a very unlikely string');
