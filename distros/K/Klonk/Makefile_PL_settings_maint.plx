use strict;
use warnings;

sub {
    my ($opt) = @_;

    $opt->{DEVELOP_REQUIRES} = {
        'Test::Pod'                => 1.22,
        'Pod::Markdown::Githubert' => 0,
    };
}
