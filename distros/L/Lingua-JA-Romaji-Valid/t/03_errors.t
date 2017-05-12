use strict;
use warnings;
use Test::More qw(no_plan);
use Lingua::JA::Romaji::Valid;

my $validator = Lingua::JA::Romaji::Valid->new;

for my $method (qw/as_romaji as_name as_fullname/) {
    my @false = (undef, '', 0);

    for (@false) {
        my @warn;
        local $SIG{__WARN__} = sub { @warn = @_ };
        eval { $validator->as_name($_) };
        ok !$@ && !@warn, "$method handled a false value properly";
        note $@ if $@;
        note @warn if @warn;
    }

    my @meta = ('kakko(ii)', 'email@localhost', 'looks $variable');

    for (@meta) {
        eval { $validator->as_name($_) };
        ok !$@, "$method quoted meta characters";
        note $@ if $@;
    }
}
