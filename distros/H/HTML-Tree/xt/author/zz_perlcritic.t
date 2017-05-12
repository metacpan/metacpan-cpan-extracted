#!perl -T

use Test::More;

eval "use Test::Perl::Critic";

if ($@) {
    Test::More::plan( skip_all =>
            "Test::Perl::Critic required for testing PBP compliance" );
}
else {
    Test::Perl::Critic->import(
        -verbose  => 8,
        -severity => 5,
        -exclude => [
          # fails to detect a package is accessing objects of its own class:
          'ProhibitAccessOfPrivateData',
          # subs expected to return a scalar *should* "return undef":
          'ProhibitExplicitReturnUndef',
        ],
    );
}

all_critic_ok();
