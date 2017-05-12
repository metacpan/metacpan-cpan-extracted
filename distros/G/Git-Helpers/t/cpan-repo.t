use strict;
use warnings;

use Test::Fatal qw( exception );
use Test::RequiresInternet ( 'fastapi.metacpan.org' => 443 );
use Test::More;

use Git::Helpers::CPAN ();

foreach my $name ( 'Git::Helpers', 'Git-Helpers' ) {
    subtest "Found $name" => sub {
        my $cpan = Git::Helpers::CPAN->new( name => $name );
        is_deeply(
            $cpan->repository,
            {
                type => 'git',
                url  => 'https://github.com/oalders/git-helpers.git',
                web  => 'https://github.com/oalders/git-helpers',
            },
            $name
        );
    };
}

foreach my $name ( 'Git::HelpersXXX', 'Git-HelpersXXX' ) {
    subtest "Not found: $name" => sub {
        my $cpan = Git::Helpers::CPAN->new( name => $name );
        like(
            exception { $cpan->repository }, qr{cannot find}i,
            'search failed'
        );
    };
}

done_testing();
