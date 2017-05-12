use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Deep;

{
    package MySpecialMunger;
    our $VERSION = '0.666';
    use Moose;
    extends 'Dist::Zilla::Plugin::MungeFile';

    sub munge_file
    {
        my ($self, $file) = @_;
        $self->next::method(
            $file,
            { my_arg => 'hello, this is dog' },
        );
    }
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ '=MySpecialMunger' => { finder => ':MainModule' } ],
            ),
            'source/lib/Module.pm' => <<'MODULE'
package Module;

my $string = "{{ uc($my_arg) }}";
1;
MODULE
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $content = $tzil->slurp_file('build/lib/Module.pm');

is(
    $content,
    <<'NEW_MODULE',
package Module;

my $string = "HELLO, THIS IS DOG";
1;
NEW_MODULE
    'module content is transformed, using arguments passed in from the subclassed plugin',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'MySpecialMunger',
                    config => {
                        'Dist::Zilla::Plugin::MungeFile' => {
                            finder => [ ':MainModule' ],
                            files => [ ],
                            version => Dist::Zilla::Plugin::MungeFile->VERSION,
                        },
                    },
                    name => '=MySpecialMunger',
                    version => '0.666',
                },
            ),
        }),
    }),
    'distmeta is correct',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
