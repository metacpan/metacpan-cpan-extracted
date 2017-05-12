#!perl
use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;
use LWP::UserAgent;
use Encode qw(encode_utf8);
use JSON::PP;

# Check if we can get to CPAN index, skip if not
my $ua = LWP::UserAgent->new(keep_alive => 1);
$ua->env_proxy;
my $res = $ua->get("http://cpanidx.org/cpanidx/json/mod/Dist-Zilla-Plugin-CheckVersionIncrement");
if (!$res->is_success) {
    plan skip_all => 'Cannot access CPAN index';
}
# Check that CPAN index returns something that contains a version
# number, skip if not
my $yaml_octets = encode_utf8($res->decoded_content);
my $payload = JSON::PP->new->decode($yaml_octets);
if (!(@$payload && $payload->[0]{mod_vers})) {
    plan skip_all => 'CPAN index did not return a version number';
}


# This needs to be the name of an actual module on CPAN. May as well
# be this one.
my $module_text = <<'MODULE';
package Dist::Zilla::Plugin::CheckVersionIncrement;
1;
MODULE

my $tzil_minversion = Builder->from_config(
    { dist_root => 'corpus/empty' },
    {
        add_files => {
            'source/Dist/Zilla/Plugin/CheckVersionIncrement.pm' => $module_text,
            'source/dist.ini' => dist_ini({
                    name     => 'Dist-Zilla-Plugin-CheckVersionIncrement',
                    abstract => 'Testing CheckVersionIncrement',
                    version  => '0.000001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, (
                    'CheckVersionIncrement',
                    'GatherDir',
                    'FakeRelease',
                )
            ),
        },
    }
);

my $tzil_maxversion = Builder->from_config(
    { dist_root => 'corpus/empty' },
    {
        add_files => {
            'source/Dist/Zilla/Plugin/CheckVersionIncrement.pm' => $module_text,
            'source/dist.ini' => dist_ini({
                    name     => 'Dist-Zilla-Plugin-CheckVersionIncrement',
                    abstract => 'Testing CheckVersionIncrement',
                    version  => '999.999999',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, (
                    'CheckVersionIncrement',
                    'GatherDir',
                    'FakeRelease',
                )
            ),
        },
    }
);

throws_ok { $tzil_minversion->release; } qr/aborting release of version [0-9._]+ because a higher version \([0-9._]+\) is already indexed on CPAN/, 'Aborted release when a higher version was indexed';
lives_ok { $tzil_maxversion->release; } 'Allowed release when a lower version was indexed';

done_testing(2);
