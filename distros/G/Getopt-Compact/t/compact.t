#!/usr/bin/perl
# test Getopt::Compact

use strict;
use lib qw(../lib lib);
use Test::More;
use File::Spec;
use vars qw/$VERSION/;

$VERSION = '1.3';  # test - do not modify

use constant FILE_USAGE1 => File::Spec->catfile(qw/data usage1.txt/);

plan tests => 10;

eval { require Getopt::Compact };
ok(!$@, "compile Getopt::Compact");
diag $@ if $@;

my $topts = new Getopt::Compact(modes => [qw(baseline)])->opts();

my(@joobs, $go);
@ARGV = ('-w', 'woo', '-v', '--joobies', 1, '--joobies', 2,
	 '--zanzibar', '-y', '-f', '-k');
$go = new Getopt::Compact
    (name => 'Getopt::Compact test script',
     modes => [qw(verbose test debug)],
     struct =>
     [[[qw(w wibble)], qq(specify a wibble parameter), ':s'],
      [[qw(f foobar foo)], qq(apply foobar algorithm)],
      [[qw(j joobies)], qq(jooby integer list), '=i', \@joobs],
      ["baz", qq(baz option)],
      [[qw(z zany zanzibar)], qq(z option)],
      [[qw(x y)], qq(The x or y option)],
      [[qw(k l jay kay)], qq(The k, l, jay or kay option)],
      ]);

my $opts = $go->opts;

is_deeply(\@joobs, [1, 2], "integer list with reference");
is($opts->{wibble}, 'woo', 'optional string argument');
is($opts->{verbose}, 1, 'mode option works');
is($opts->{zany}, 1, 'multiple argument specification (>2)');
is($opts->{x}, 1, 'first option used as key (2 single char options)');
is($opts->{foobar}, 1, 'second option used as key (multiple options)');
is($opts->{jay}, 1, 'first long option used as key (multiple single & long)');

# test usage string
my $changed_t = chdir 't' if -d 't';
write_file(FILE_USAGE1, $go->usage) if $topts->{baseline};
my $e_usage = read_file(FILE_USAGE1);
is($go->usage, $e_usage, "usage string matches");

# test finding programs
chdir File::Spec->updir if $changed_t;
my $script = $go->_find_program;
is($script, $0, 'program $0 found');


######################################################################

sub write_file {
    my($file, $content) = @_;
    open FH, ">$file" || die "write $file: $!\n";
    print FH $content;
    close FH;
}
sub read_file {
    my($file) = @_;
    open FH, $file || die "read $file: $!\n";
    local $/;
    my $content = <FH>;
    close FH;
    return $content;
}
