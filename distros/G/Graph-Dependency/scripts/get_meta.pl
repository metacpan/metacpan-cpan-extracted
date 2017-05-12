#!/usr/bin/perl -w

use strict;

my $module = shift;

die ("Need a module name") unless $module;

# turn "Foo::Bar" into "Foo-Bar"
$module =~ s/::/-/g;

# protect against random data
$module =~ s/[^\w\d\._+-]//g;

# return early if the META.yml file already exists
exit if -f "tmp/$module-META.yml";

my $url = "http://search.cpan.org/search?query=$module&mode=modules&n=50";

# search for the module to get the author name
my $rc = `wget '$url' -o /tmp/wget.log -O tmp/index.html`;

# grep for the module
# /author/DSKOLL/IO-stringy-2.110/lib/IO/Scalar.pm"><b>IO::Scalar</b>

my $m2 = $module; $m2 =~ s/-/::/g;
$rc = `grep 'author.*$m2' tmp/index.html`;

#print STDERR "$rc\n";

# try direct
$rc =~ /\/author\/(\w+)\/(.*?)\/.*$m2</; my $author = $1;
my $m = _replace($module,$2);

if (!defined $author)
  {
  $rc =~ /\/author\/(\w+)\/([\w+\.\d_-]+)\//; $author = $1;
  $m = _replace($module,$2);
  }

if (!defined $author)
  {
  # try again with: "<p><a href="/author/PMQS/"
  $rc = `grep '\/author\/' tmp/index.html`;
  # also use the supplied module name, (meaning Foo-Bar is in Foo-Bar-Baz)
  $rc =~ /\/author\/(\w+)\/(.*?)\//; $author = $1;
 
  $m = _replace($module,$2);
  print "$module => $m\n" if $m ne $module;
  }

$m =~ s/-[\d\._]+//;	# remove version info
print "$module => $m\n" if $m ne $module;
$module = $m;

die ("Couldn't find author for module $module") unless $author;

#unlink 'tmp/index.html';

print "Found author '$author' for module '$module'.\n";

# get the meta file
$rc = `perl scripts/get.pl '$module' '$author'`;


# replace one module name by another, unless it is perl or ponie
sub _replace
  {
  my ($old,$new) = @_;

  $new = $new || '';  
  $old = $new if $new !~ /^(perl|ponie)/;

  $old; 
  }
