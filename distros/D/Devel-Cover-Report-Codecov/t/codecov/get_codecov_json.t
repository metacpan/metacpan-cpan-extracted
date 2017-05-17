use strict;
use warnings FATAL => 'all';
use utf8;

use JSON::XS;
use Test::Mock::Guard;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov;

sub get_codecov_json {
    Devel::Cover::Report::Codecov::get_codecov_json(@_);
}

subtest basic => sub {
    my $guard = mock_guard(
        'Devel::Cover::Report::Codecov',
        {
            get_file_coverage => sub {
                my ($file, $db) = @_;

                like $file, qr/lib\/Test\/(Foo|Bar)\.pm/, $file;
                is $db, 'db';

                return $file => [ undef, 1, 0, 5 ] if $file =~ qr/Foo/;
                return $file => [ undef, 2, 3, 8 ];
            },
        });

    my $files = [ 'lib/Test/Foo.pm', 'lib/Test/Bar.pm' ];

    cmp_deeply
        decode_json(get_codecov_json($files, 'db')),
        {
            coverage => {
                'lib/Test/Foo.pm' => [ undef, 1, 0, 5 ],
                'lib/Test/Bar.pm' => [ undef, 2, 3, 8 ],
            },
            messages => {},
        };
};

done_testing;
