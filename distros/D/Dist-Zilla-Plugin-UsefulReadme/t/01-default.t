use v5.20;
use warnings;

use Test::More;
use Test::Deep;
use Test::DZil;

use List::Util qw( first );
use Path::Tiny qw( path );
use Pod::Simple::Text 3.23;

use experimental qw( postderef );

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
           path(qw( source dist.ini )) => simple_ini( ['AutoPrereqs'], ['GatherDir'], [ 'UsefulReadme' ], ['MakeMaker'] ),
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

=begin :readme

=head1 prepend:INSTALLATION

This is something for before the installation.

=end :readme

=begin :readme

=head1 append:INSTALLATION

This is something that is after the installation.

=end :readme

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

my $file = path( $tzil->tempdir, "build", "README" );

ok $file->exists, $file->basename . " exists";

ok my $text = $file->slurp_raw, "has content";

note $text;

like $text, qr/INSTALLATION\n+\s*This is something for before the installation.\n/, "prepend";

like $text, qr/\s*This is something that is after the installation.\n+AUTHOR\n/, "append";

my $plugin = first { $_->isa("Dist::Zilla::Plugin::UsefulReadme") } $tzil->plugins->@*;
ok $plugin, "got plugin";

cmp_deeply $plugin->dump_config, {
    "Dist::Zilla::Plugin::UsefulReadme" => {
        'sections' => [
            'name',                                         #
            'status',                                       #
            'synopsis',                                     #
            'description',                                  #
            'recent changes',                               #
            'requirements',                                 #
            'installation',                                 #
            'security considerations',                      #
            '/support|bugs/',                               #
            'source',                                       #
            '/authors?/',                                   #
            '/contributors?/',                              #
            '/copyright|license|copyright and license/',    #
            'see also'                                      #
        ],
        'parser_class'     => 'Pod::Simple::Text',
        'source'           => 'lib/DZT/Sample.pm',
        'location'         => 'build',
        'type'             => 'text',
        'filename'         => 'README',
        'section_fallback' => 1,
        'encoding'         => 'utf8',
        'phase'            => 'build',
        'regions'          => [ 'stopwords', 'Pod::Coverage', 'Test::MixedScripts' ]
    }

  },
  "dump_config";

cmp_deeply $tzil->distmeta->{prereqs}{develop}{requires},
  superhashof(
    {
        "Dist::Zilla::Plugin::UsefulReadme" => "v0.4.3",
        "Pod::Simple::Text"                 => '3.23',
    }
  ),
  "add_prereqs";

done_testing;
