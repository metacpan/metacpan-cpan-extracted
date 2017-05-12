use strict;
use warnings;

use Test::More;
use Test::Fatal;
use lib 't/lib';
use MockZilla;
use Dist::Zilla::Plugin::ReportVersions::Tiny;

# FILENAME: 3part_prereq.t
# CREATED: 18/03/12 02:38:04 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test 3-part versions being pre-requisites

my $rv;
is(
    exception {
        $rv = Dist::Zilla::Plugin::ReportVersions::Tiny->new(
            plugin_name => 'ReportVersions::Tiny',
            zilla       => MockZilla->dzil,
        );
    },
    undef,
    'Can initialise plugin'
);

MockZilla->set_prereqs(
    {
        runtime => {
            requires => {
                'a' => '1.2.3',
                'b' => 'v1.2.3',
                'c' => v1.2.3,
                'd' => 'v1.2',
                'e' => v1.2,
                'f' => '1.2',
                'g' => 1.2,
            },
        },
        build => {
            requires => {
                'a' => '1.2.4',
                'b' => 'v1.2.4',
                'c' => v1.2.4,
                'd' => 'v1.3',
                'e' => v1.3,
                'f' => '1.3',
                'g' => 1.3,
            },
        },

    }
);

my $modules;

is(
    exception { $modules = $rv->applicable_modules },
    undef, 'can collect modules',
);

my $body = $rv->generate_test_from_prereqs;

my $m = $rv->generate_eval_stubs($modules);

like( $m, qr/'a','1\.2\.4'/,  'bad 3 part normalises semi-sanely' );
like( $m, qr/'b','v1\.2\.4'/, 'string 3 part normalises sanely' );
like( $m, qr/'c','v1\.2\.4'/, 'bare 3 part normalises sanely' );
like( $m, qr/'d','v1\.3'/,    'string 2 part normalises sanely' );
like( $m, qr/'e','v1\.3'/,    'bare 2 part normalises sanely' );
like( $m, qr/'f','1\.3'/,     'string decimal normalises sanely' );
like( $m, qr/'g','1\.3'/,     'bare decimal normalises sanely' );

done_testing;

