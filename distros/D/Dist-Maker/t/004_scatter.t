#!perl -w
use strict;
use Test::More;

use Dist::Maker::Config;
use Dist::Maker::Scatter;
use Dist::Maker::Util qw(slurp available_templates);
use File::Path qw(rmtree);

END{ rmtree '.test/scatter/', { verbose => 0 } }

my $config = Dist::Maker::Config->new(
    user_data => {
        user => {
            name  => 'foo',
            email => 'bar at example.com',
        },
    },
);

my @installers = qw(Makefile.PL Build.PL);

my @files = qw(
    lib/Foo/Bar.pm
    Changes
    author/requires.cpanm
    .gitignore
    .shipit
    MANIFEST.SKIP
    t/000_load.t
    t/001_basic.t
    xt/pod.t
    xt/podcoverage.t
    xt/podspell.t
    xt/podsynopsis.t
    xt/perlcritic.t
);

my %shouldnt_exist = (
    'CLI' => {
        'xt/podcoverage.t' => 1,
        'xt/podsynopsis.t' => 1,
    },
);

foreach my $template(available_templates()) {
    note "Template: $template";

    my $x = Dist::Maker::Scatter->new(
        dist      => 'Foo::Bar',
        template  => $template,
        config    => $config,
        cache_dir => '.test_cache',
    );

    my $map = $x->content_map();
    ok $map, 'content_map';

    my @exists_installers;
    foreach my $file(@installers) {
        push @exists_installers, $file if exists $map->{$file} && length($map->{$file}) > 0;
    }
    ok @exists_installers, "Installer @{[join ', ', @exists_installers]} exists correctly.";

    my @files_needed = @files;
    my $is_readme_needed = !('Build.PL' ~~ @exists_installers && $map->{'Build.PL'} =~ /create_readme/);
    push @files_needed, 'README' if $is_readme_needed;

    foreach my $file(@files_needed) {
        if(!$shouldnt_exist{$template}{$file}) {
            ok exists $map->{$file}, "$file built successfully";
            cmp_ok length($map->{$file}), '>', 0, '... with some contents';
        }
        else {
            ok !exists $map->{$file}, "$file should not exist";
        }
    }

    if ($is_readme_needed) {
        like $map->{README}, qr/Foo::Bar/;
        like $map->{README}, qr/\b foo \b/xms,
            'README must include $user.name';

        like $map->{README}, qr/ [^\n] \n \z/xms, 'ends with a newline';
    }

    like $map->{'lib/Foo/Bar.pm'}, qr/\b foo \b/xms,
        'main module must include $user.name';
    like $map->{'lib/Foo/Bar.pm'}, qr/\Qbar at example.com\E/xms,
        'main module must include $user.email';

    my $d = ".test/scatter/" . $x->template;
    note "Scatter to $d";
    rmtree $d, { verbose => 0 } if -e $d;
    $x->scatter($d);

    foreach my $file(@files_needed, @exists_installers) {
        next if $shouldnt_exist{$template}{$file};

        ok -e File::Spec->catfile($d, $file),
            "$file exists in the file system";
    }

    ok !exists $map->{EXTRA_FILES}; # meta file
}

pass 'done';

done_testing;
