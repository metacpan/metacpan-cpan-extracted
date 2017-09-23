use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Moose::Util 'find_meta';

use lib 't/lib';
use NoNetworkHits;
use NoPrereqChecks;
use Helper;

# we need the profiles dir to have gone through file munging first (for
# profile.ini), as well as get installed into a sharedir
plan skip_all => 'this test requires a built dist'
    unless -d 'blib/lib/auto/share/dist/Dist-Zilla-PluginBundle-Author-ETHER/profiles';

plan skip_all => 'minting requires perl 5.014' unless "$]" >= 5.013002;

my $tzil = Minter->_new_from_profile(
    [ 'Author::ETHER' => 'github' ],
    { name => 'My-New-Dist', },
    { global_config_root => path('corpus/global')->absolute },
);

# we need to stop the git plugins from doing their thing
foreach my $plugin (grep { ref =~ /Git/ } @{$tzil->plugins})
{
    next unless $plugin->can('after_mint');
    my $meta = find_meta($plugin);
    $meta->make_mutable;
    $meta->add_around_method_modifier(after_mint => sub { Test::More::note("in $plugin after_mint...") });
}

$tzil->chrome->logger->set_debug(1);
$tzil->mint_dist;
my $mint_dir = path($tzil->tempdir)->child('mint');

my @expected_files = qw(
    .ackrc
    .gitignore
    .mailmap
    .travis.yml
    Changes
    dist.ini
    CONTRIBUTING
    LICENCE
    README.pod
    lib/My/New/Dist.pm
    t/01-basic.t
);

cmp_deeply(
    [ recursive_child_files($mint_dir) ],
    bag(@expected_files),
    'the correct files are created',
);

my $module = path($mint_dir, 'lib/My/New/Dist.pm')->slurp_utf8;

like(
    $module,
    qr/^use strict;\nuse warnings;\npackage My::New::Dist;/m,
    'our new module has a valid package declaration',
);

like(
     $module,
    qr/^our \$VERSION = '0.001';$/m,
    'initial module $VERSION is calculated correctly',
);

like(
    $module,
    qr/\n\n1;\n__END__\n/,
    'the package code ends in a generic way',
);

like(
    $module,
    do {
        my $pattern = <<SYNOPSIS;
=pod

=head1 SYNOPSIS

    use My::New::Dist;

    ...

=head1 DESCRIPTION
SYNOPSIS
my $cut = <<CUT;

=cut
CUT
        qr/\Q$pattern\E/
    },
    'our new module has a brief generic synopsis and description',
);

like(
    $module,
    qr{=head1 FUNCTIONS/METHODS},
    'our new module has a pod section for functions and methods',
);

like(
    path($mint_dir, 't', '01-basic.t')->slurp_utf8,
    qr/^use My::New::Dist;\n\nfail\('this test is TODO!'\);$/m,
    'test gets generic content',
);

my $dist_ini = path($mint_dir, 'dist.ini')->slurp_utf8;
like(
    $dist_ini,
    qr/\[\@Author::ETHER\]\n:version = [\d.]+\n\n/,
    'plugin bundle and version is referenced in dist.ini',
);

unlike($dist_ini, qr/^\s/, 'no leading whitespace in dist.ini');
unlike($dist_ini, qr/[^\S\n]\n/, 'no trailing whitespace in dist.ini');
unlike($dist_ini, qr/\n\n\n/, 'no double blank links in dist.ini');
unlike($dist_ini, qr/\n\n\z/, 'file does not end with a blank line');

like(
    path($mint_dir, '.gitignore')->slurp_utf8,
    qr'^/My-New-Dist-\*/$'ms,
    '.gitignore file is created properly, with dist name correctly inserted',
);

is(
    path($mint_dir, 'Changes')->slurp_utf8,
    <<'CHANGES',
Revision history for My-New-Dist

{{$NEXT}}
          - Initial release.
CHANGES
    'Changes file is created properly, with dist name filled in but version template and whitespace preserved',
);

is(
    path($mint_dir, 'README.pod')->slurp_utf8,
    <<'README',
=pod

=head1 SYNOPSIS

    use My::New::Dist;

    ...

=head1 DESCRIPTION

...

=head1 FUNCTIONS/METHODS

=head2 C<foo>

...

=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

=for :list
* L<foo>

=cut
README
    'README.pod is generated and contains pod',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
