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
[NextRelease]
filename = ChangeLog

[UsefulReadme]
type = pod
section = name
section = recent changes

[PodWeaver]
[%PodWeaver]
RecentChanges.changelog =
RecentChanges.region    = :readmefoo
SAMPLE

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
           path(qw( source dist.ini )) => $ini,
           path(qw( source ChangeLog )) => << 'CHANGES',
Revision history for DZT-Sample:

{{$NEXT}}
  [Bug Fixes]
  - The software sort of works now.

  - This again?

  [Documentation]
  - Fixed embarrassing typos.

0.000   2025-05-07 13:42:12+01:00 Europe/London
  - Initial version crawled out of a rock.

CHANGES
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

my $file = path( $tzil->tempdir, "build", "README.pod" );

ok $file->exists, $file->basename . " exists";

ok my $text = $file->slurp_raw, "has content";

note $text;

like $text, qr/^=begin :readmefoo\n+=head1 RECENT CHANGES/m, "region configured via dist.ini";

done_testing;
