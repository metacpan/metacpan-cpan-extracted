use Test::More;
use utf8;
use Data::Dumper;
use I22r::Translate;
use t::Constants;
use strict;
use warnings;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
if (defined $DB::OUT) {
    # if Perl debugger is running
    binmode $DB::OUT, ':encoding(UTF-8)';
}

ok(1, 'starting test');
t::Constants::skip_remaining_tests() unless $t::Constants::CONFIGURED;

my $src = 'en';

my %INPUT = (
    lcase => 'View all posts by {{_1}}'
    );

t::Constants::basic_config();

my @dest = @ARGV ? @ARGV : qw(es de ja ko ru th ja da tr);

foreach my $dest (@dest) {

    my %R = I22r::Translate->translate_hash(
	src => $src, dest => $dest, text => \%INPUT,
	filter => [ 'Literal' ], return_type => 'hash' );
    
    # diag Dumper(\%INPUT,\%R);

    ok(scalar keys %R == scalar keys %INPUT,
       'output count equals input count');
    ok($R{lcase}{TEXT} =~ /\{\{_1\}\}/,
       'literal text preserved')
	or diag Dumper (\%INPUT, \%R);
}

done_testing();

