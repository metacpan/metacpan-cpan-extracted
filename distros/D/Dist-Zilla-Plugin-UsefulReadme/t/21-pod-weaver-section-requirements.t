use v5.20;
use warnings;

use Test::More;
use Test::Deep;
use Test::DZil;
use Dist::Zilla::Plugin::PodWeaver;
use Dist::Zilla::Stash::PodWeaver;

use Path::Tiny qw( path );

my $ini = simple_ini( ['AutoPrereqs'], ['GatherDir'], ['MakeMaker'] );
$ini .= << "SAMPLE";
[MetaJSON]

[PodWeaver]

[UsefulReadme]
type = pod
section = name
section = requirements

SAMPLE

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
           path(qw( source dist.ini )) => $ini,
           path(qw( source weaver.ini )) => << 'WEAVER',
[@CorePrep]
[Name]
[Generic / DESCRIPTION]
[Requirements]
guess_prereqs = 1
region = :readme
WEAVER
           path(qw( source lib/DZT/Sample.pm)) => << 'MODULE',

package DZT::Sample;
use strict;
use warnings;

use Carp;
use Text::Wrap 2021.0814;

our $VERSION = '0.001';

# ABSTRACT: Sample DZ Dist

=head1 DESCRIPTION

Bar bo baz.

=cut

=head1 EXPORTS

None, really. This is for testing.

=head2 Something or other.

=head1 AUTHOR

E. Xavier Ample <example@example.org>

=cut

sub something() {
}

1;

MODULE
        }
    }
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

subtest "Pod::Weaver munged" => sub {

    my $file = path( $tzil->tempdir, "build", "lib/DZT/Sample.pm" );

    ok $file->exists, $file->basename . " exists";

    ok my $text = $file->slurp_raw, "has content";

    note $text;

    like $text, qr/^=begin :readme\n+=head1 REQUIREMENTS/m, "region configured via dist.ini";
    like $text, qr/See the F\<META\.json\>/,                "mentions META.json";

};

subtest "README" => sub {

    my $file = path( $tzil->tempdir, "build", "README.pod" );

    ok $file->exists, $file->basename . " exists";

    ok my $text = $file->slurp_raw, "has content";

    note $text;

    unlike $text, qr/^=begin :readme/m, "does not have :readme region";

    like $text, qr/^=head1 REQUIREMENTS/m, "has REQUIREMENTS from POD";

};

done_testing;
