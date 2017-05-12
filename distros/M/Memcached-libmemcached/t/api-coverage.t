use strict;
use warnings;
use Test::More;

# t/pod-coverage shows what's been implemented but not documented
# t/api-coverage shows what's in the libmemcached API but not documented

use Memcached::libmemcached::API;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing" if $@;
plan tests => 1;

my $pc = Pod::Coverage->new(package => 'Memcached::libmemcached');
my %covered = map { $_=>1 } $pc->covered;

my @todo;
print "libmemcached_functions:\n";
for my $func (libmemcached_functions()) {
    print "$func\n";
    push @todo, $func unless $covered{$func};
}
if (@todo) {
    warn "  ".scalar(@todo)." Functions not yet implemented and documented:\n";
    warn "\t$_\n" for @todo;
}

pass; # don't treat as a failure
