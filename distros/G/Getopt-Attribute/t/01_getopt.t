use warnings;
use strict;
use Test::More tests => 11;
use Getopt::Attribute;

BEGIN {
    @ARGV = qw(--noverbose --all --size=23 --more --more --more --quiet
      --library lib/stdlib --library lib/extlib --def2=4
      --define os=linux --define vendor=redhat --man -- --more);
}
our $verbose : Getopt(verbose!);
is($verbose, 0, 'turned-off boolean option');
our $all : Getopt(all);
is($all, 1, 'turned-on boolean option');
our $size : Getopt(size=s);
is($size, 23, 'string option');
our $more : Getopt(more+);
is($more, 3, 'flag given several times');
our @library : Getopt(library=s);
our $library = join ':' => @library;
is($library, 'lib/stdlib:lib/extlib', 'array option');
our %defines : Getopt(define=s);
our $defines = join ', ' => map "$_ => $defines{$_}" => keys %defines;
ok( keys(%defines) == 2
      && $defines{os} eq 'linux'
      && $defines{vendor} eq 'redhat',
    'hash option'
);

sub quiet : Getopt(quiet) {
    our $quiet_msg = 'seen quiet';
}
is(our $quiet_msg, 'seen quiet', 'option with code handler');
usage() if our $man : Getopt(man);
sub usage { our $man_msg = 'seen man' }
is(our $man_msg, 'seen man', 'another option with code handler');
ok(length(@ARGV) == 1 && $ARGV[0] eq '--more', 'non-option option-look-a-like');
our $def : Getopt(def=i 42);
our $def2 : Getopt(def2=i 42);
is($def,  42, 'defaulting');
is($def2, 4,  'setting other than default');
