use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More tests => 3;

use Devel::Confess qw(source);

my $file = __FILE__;
my @lines;

sub Foo::foo {
  push @lines, __LINE__; die "error";
}

sub Bar::bar {
  push @lines, __LINE__; Foo::foo(@_);
}

sub Baz::baz {
  push @lines, __LINE__; Bar::bar(@_);
}

eval { Baz::baz([1]) };

for my $line (@lines) {
  ok $@ =~ /context for \Q$file\E line $line:/, 'trace includes required line';
}

