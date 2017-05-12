use Test::Roo;
use lib 't/lib';
with 'Test::DZP::Changes';

test first_release_with_changes => sub {
    my $self = shift;
    $self->_set_tzil_ini_opts;
    $self->test_changes('first_release');
};

run_me {test_repo_name => 'first_release'};
done_testing;
