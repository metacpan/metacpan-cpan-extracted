use v5.20;
use warnings;

use Test::More;
use Test::Deep;
use Test::DZil;

use Path::Tiny qw( path );
use Pod::Markdown::Github;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
           path(qw( source INSTALL ))  => "How to install....",
           path(qw( source Changes )) => << 'CHANGES',
Revision history for DZT-Sample:

{{$NEXT}}
  [Bug Fixes]
  - The software sort of works now.

  [Documentation]
  - Fixed embarrassing typos.

0.000   2025-07-05 03:46:12+01:00 Europe/London
  - Initial version

CHANGES
           path(qw( source dist.ini )) =>
             simple_ini( ['AutoPrereqs'], ['GatherDir'], ['MakeMaker'], ['CPANFile'], ['NextRelease'], [ 'UsefulReadme', { type => 'gfm' } ], ),
           path(qw( source lib/DZT/Sample.pm)) => << 'MODULE',

package DZT::Sample;
use strict;
use warnings;

use Carp;
use Text::Wrap 2021.0814;

our $VERSION = '0.001';

=head1 NAME

DZT::Sample - Sample DZ Dist

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

my $file = path( $tzil->tempdir, "build", "README.md" );

ok $file->exists, $file->basename . " exists";

ok my $text = $file->slurp_raw, "has content";

note $text;

done_testing;
