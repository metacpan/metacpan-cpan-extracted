#!perl
use Test::More;
eval "use Test::Perl::Critic";
if ($@) {
    plan skip_all => "Test::Perl::Critic required for testing Perl PBP compliance" if $@;
}
else {
    Test::Perl::Critic::all_critic_ok();
}
