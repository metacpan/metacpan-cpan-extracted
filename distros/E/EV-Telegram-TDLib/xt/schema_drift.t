use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
}

eval { require Alien::TDLib; 1 } or plan skip_all => 'Alien::TDLib not available';
require EV::Telegram::TDLib::Schema;
no warnings 'once';

my $header = Alien::TDLib->dist_dir . '/include/td/telegram/td_api.h';
plan skip_all => "no header at $header" unless -r $header;

open my $h, '<', $header or die "$header: $!";
my $src = do { local $/; <$h> };
close $h;

my %live;
$live{$1} = 1 while $src =~ /^class (\w+) final : public Function \{/mg;
my %shipped = %EV::Telegram::TDLib::Schema::FUNCTIONS;

my @added   = sort grep { !exists $shipped{$_} } keys %live;
my @removed = sort grep { !exists $live{$_} } keys %shipped;

diag sprintf 'catalogue from TDLib %s, installed TDLib %s',
    $EV::Telegram::TDLib::Schema::TDLIB_VERSION, (Alien::TDLib->version // '?');
diag sprintf '%d added: %s',   scalar @added,   join ', ', splice @added, 0, 10   if @added;
diag sprintf '%d removed: %s', scalar @removed, join ', ', splice @removed, 0, 10 if @removed;

# Drift is expected and harmless: call() passes unknown functions through.
# This reports rather than fails, so a TDLib bump never reddens CI. The one
# thing worth failing on is the scan itself breaking: an unmatched class
# regex empties %live and reports every shipped function as removed.
cmp_ok scalar(keys %live), '>', 500, 'the header scan found functions';
ok 1, 'schema drift reported';
done_testing;
