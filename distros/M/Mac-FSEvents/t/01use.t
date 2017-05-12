use Test::More;

use_ok 'Mac::FSEvents';

subtest 'does not implicitly import flags' => sub {
    package
        Does::Not::Flags;

    use Test::More;
    my @FLAGS = qw{
        NONE
        WATCH_ROOT
        IGNORE_SELF
        FILE_EVENTS
    };

    foreach my $flag (@FLAGS) {
        ok !__PACKAGE__->can($flag), 'flag ' . $flag . ' not imported without :flags';
    }
};

done_testing;
