use v5.20;
use warnings;

use Test::More;
use Test::Deep;
use Test::DZil;

use Path::Tiny qw( path );

my $ini = simple_ini( ['AutoPrereqs'], ['GatherDir'], ['MakeMaker'] );
$ini .= << "SAMPLE";
[UsefulReadme]
section = VERSION
section = DESCRIPTION
section = SPORK
section = /AUTHORS?/
fallback = 0
SAMPLE

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
           path(qw( source dist.ini )) => $ini,
           path(qw( source lib/DZT/Sample.pm)) => << 'MODULE',

package DZT::Sample;
use strict;
use warnings;

use Carp;
use Text::Wrap 2021.0814;

our $VERSION = '0.001';

=head1 NAME

DZT::Sample - Sample DZ Dist

=begin :readme

=head1 SPORK

This should only be visible in the README.

=end :readme

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

# use DDP; p $tzil;

my $file = path( $tzil->tempdir, "build", "README" );

ok $file->exists, $file->basename . " exists";

ok my $text = $file->slurp_raw, "has content";

note $text;

like $text, qr/^SPORK\n+\s*This should only be visible in the README/m, ":readme section included";

done_testing;
