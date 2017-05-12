use Test::Roo;
use lib 't/lib';
with 'Test::DZP::Changes';

test v1_defaults => sub {
    my $self = shift;
    $self->_set_tzil_ini_opts;
    $self->test_changes('v1_defaults');
};

test v1_no_author => sub {
    my $self = shift;
    $self->_set_tzil_ini_opts([
            'ChangelogFromGit::CPAN::Changes' => {
                show_author => 0,
            }
        ],
    );

    $self->test_changes('v1_no_author');
};

test v1_email => sub {
    my $self = shift;
    $self->_set_tzil_ini_opts([
            'ChangelogFromGit::CPAN::Changes' => {
                show_author_email => 1,
            }
        ],
    );

    $self->test_changes('v1_email');
};

test v1_group_author => sub {
    my $self = shift;
    $self->_set_tzil_ini_opts([
            'ChangelogFromGit::CPAN::Changes' => {
                group_by_author => 1,
            }
        ],
    );

    $self->test_changes('v1_group_author');
};

test v1_group_author_email => sub {
    my $self = shift;
    $self->_set_tzil_ini_opts([
            'ChangelogFromGit::CPAN::Changes' => {
                group_by_author   => 1,
                show_author_email => 1,
            }
        ],
    );

    $self->test_changes('v1_group_author_email');
};

run_me({test_repo_name => 'test_repo'});
done_testing;
