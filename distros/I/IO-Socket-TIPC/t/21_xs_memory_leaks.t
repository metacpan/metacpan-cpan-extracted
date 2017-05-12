use strict;
use warnings;
use IO::Socket::TIPC;
use Test::More;
BEGIN {
	eval "use Devel::Leak";
	plan skip_all => "need Devel::Leak (NOTE: Devel::Leak is noisy.)" if $@;
};

my $tests;
BEGIN { $tests = 0 };

my @fields = (qw(
	family addrtype scope
	ref id zone cluster node
	ntype instance domain
	stype lower upper
));


my %get_fields = (map { ("get_$_" => 1) } (@fields));
my %set_fields = (map { ("set_$_" => 1) } (@fields));
delete($set_fields{set_family}); # there is no set_family(), for good reasons


# Test::More seems to preallocate some of its own stuff, and various things
# might autoload, or populate lookup tables on the first run, or whatever.
# So, to be safe, dry run the whole system before real testing begins.
is  (1, 1, "dry run 'is'");
isnt(1, 2, "dry run 'isnt'");
ok(try(1, "get_family") || 1,"dry run try()");
BEGIN { $tests += 3 };


my $loop = 0;
foreach my $field ("get_addrtype",sort(keys %get_fields, keys %set_fields)) {
	try(  5, $field); # warmup laps, preallocate whatever before we test
	my $alloc_count1 = try(   1, $field);
	my $alloc_count2 = try(1000, $field);
	is($alloc_count2, $alloc_count1, "$field doesn't leak") if $loop++;
}
BEGIN { $tests += 27 };

sub try {
	my ($tries, $field) = @_;
	my ($before_count, $after_count) = (0, 0);
	my $handle;
	$before_count = Devel::Leak::NoteSV($handle);
	for(1..$tries) {
		my $sockaddr = IO::Socket::TIPC::Sockaddr->new("{1000,$tries}");
		my $retval = 0;
		if(exists($set_fields{$field})) {
			$sockaddr->$field(1);
		} else {
			$retval += $sockaddr->$field();
		}
	}
	$after_count = Devel::Leak::CheckSV($handle);
	return $after_count - $before_count;
}

# make sure we can detect a real leak, they'll return something like "10" and 
# "1", respectively
isnt(try(10,"__leak_a_scalar"), try(1,"__leak_a_scalar"),"detection works");
BEGIN { $tests += 1 };



BEGIN { plan tests => $tests };
