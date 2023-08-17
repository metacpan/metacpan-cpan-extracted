use strict;
use warnings;

package # no_index
  TestCPANfile;

use Test::More;
use Test::DZil;

use Module::CPANfile::Environment;
use Module::CPANfile::Requirement;
use Path::Tiny qw( path tempdir );

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = (@Test::More::EXPORT, qw(
    check_cpanfile
    build_dist
    skip_without_encoding
));

sub check_cpanfile {
    my ($code, $prereqs) = @_;

    my @prereqs = @{ $prereqs || [] };

    my $env = Module::CPANfile::Environment->new('cpanfile');
    $env->parse( $code );

    my $from_cpanfile = $env->prereqs->as_cpan_meta->as_string_hash;

    my $ok = 1;
    while ( my $plugin = shift @prereqs ) {
        next if !$plugin;

        my $stage = 'runtime';
        my $rel   = 'requires';

        my (undef, $name) = split /\s+\/\s+/, $plugin;

        if ( $name ) {
            my ($phase, $type) = $name =~ /\A
              (Build|Test|Runtime|Configure|Develop)?
              (Requires|Recommends|Suggests|Conflicts)
            \z/x;
         
            if ($type) {
              $stage = lc $phase if defined $phase;
              $rel   = lc $type;
            }
        }

        my @requirements = @{ (shift @prereqs) || [] };

        if ( !$from_cpanfile->{$stage} ) {
            $ok = 0;
            return;
        }

        MODULE:
        while ( my $module = shift @requirements ) {
            shift @requirements if $requirements[0] =~ m{\A\d} || $requirements[0] =~ m{(>|<|>=|<=|!=|==)};

            if ( $module =~ m{\A-} ) {
                $stage = shift @requirements if $module eq '-phase';
                $rel   = shift @requirements if $module eq '-relationship';
                next MODULE;
            }

            $ok = 0 if !$from_cpanfile->{$stage}->{$rel}->{$module};
        }
    }

    return $ok;
}

sub skip_without_encoding {
    plan skip_all => 'Dist::Zilla 5 required for Encoding tests'
        if Dist::Zilla->VERSION < 5;
}

sub build_dist {
    my @prereqs = @{ shift || [] };
    my $config  = shift || {};

    $config->{filename} ||= 'cpanfile';

    my $test   = {
        content => 'requires Moo => 1;',
        name    => $config->{filename} || 'cpanfile',
        user    => 'Test-Author',
        repo    => 'Test-CPANFILES',
        %{ shift() || {} },
    };

    my $plugin_name = 'SyncCPANfile';
    my $dir = tempdir();

    my @plugins = (
        # Bare minimum instead of @Basic.
        qw(
            GatherDir
            License
            FakeRelease
        ),
        @{ $test->{plugins} || [] },
        [$plugin_name => $config],
    );

    # Use spew_raw instead of add_files so we can use non-utf-8 bytes.
    $dir->child($config->{filename})->spew_raw($test->{content} . "\n");

    my $ini = simple_ini({ name => $test->{repo} }, @plugins);

    while ( my $plugin = shift @prereqs ) {
        $ini .= sprintf "\n[%s]\n", $plugin;
        my $modules =  shift @prereqs;

        while ( my $module = shift @{ $modules || [] } ) {
            $ini .= sprintf "%s = %s\n", $module, shift @{ $modules || [] };
        }
    }

    my $tzil = Builder->from_config(
        {
            dist_root => $dir,
        },
        {
            add_files => {
                'source/dist.ini'   => $ini,
                'source/lib/Foo.pm' => "package Foo;\n\$VERSION = 1;\n",
            }
        }
    );

    $tzil->build;

    # Get the cpanfile in dzil's source dir.
    my ($cpanfile) = map { path($_) }
        grep { $_->basename eq $test->{name} }
            $tzil->root->children;

    # Return several values and shortcuts to simplify testing.
    return {
        zilla    => $tzil,
        cpanfile => $cpanfile,
        plugin   => $tzil->plugin_named($plugin_name),
        user     => $test->{user},
        repo     => $test->{repo},
    };
}

1;
