#!/usr/bin/perl

use strict;
use 5.010;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'FusqlFS::Builder',
    code  => q{
        eval 'use Module::Build::Debian';

        sub ACTION_buildtests
        {
            eval 'use Test::Inline';
            return if $@;

            my $tests = Test::Inline->new(
                verbose     => 1,
                readonly    => 0,
                check_count => 2,
                input       => 'lib',
                output      => 't',
                manifest    => 't/manifest',
                file_content => sub () {
                    my ($inline, $script) = @_;
                    my $testno = $script->tests;
                    my $plan = $testno? "plan tests => $testno;": "plan 'no_plan';";
                    my $class = $script->class;
                    my $testclass = '';
                    my $require = $class;
                    my $instantiate = 1;

                    #my $content = $script->merged_content;
                    my $content = join "\n", map { $_->content; } $script->setup;
                    my $sorted = $script->sorted;
                    if ($sorted)
                    {
                        $content .= join "\n", map { $_->setup? '': '
#'.$_->begin.'
{
my $_tname = \''.$_->name.'\';
my $_tcount = '.($_->tests? $_->tests: 'undef').';

'.$_->content.'}
'
                        } @$sorted;
                    }

                    $testclass = $1 if ($content =~ /^#!class (\S+)/m);
                    $require = $1 if ($content =~ /^#!req (\S+)/m);
                    $require = '' if ($content =~ /^#!noreq/m);
                    $instantiate = 0 if ($content =~ /^#!noinst/m);

                    my $result = "use strict;\nuse v5.10.0;\n";
                    $result .= "use Test::More;\nuse Test::Deep;\n";
                    if ($testclass)
                    {
                        $result .= "use $testclass;\n";
                        $result .= "if ($testclass->can('set_up'))\n{ plan skip_all => 'Initialization failed' unless $testclass->set_up(); }\n";
                    }
                    $result .= "$plan\n\n";
                    if ($require)
                    {
                        $result .= "require_ok '$require';\n";
                    }
                    if ($instantiate)
                    {
                        $result .= "our \$_tobj = $class->new();\n";
                        $result .= "isa_ok \$_tobj, '$class', 'Class $class instantiated';\n\n";
                    }
                    $content =~ s/{_tpkg}/$class/g;
                    $result .= "our \$_tcls = '$class';\n";
                    $result .= $content;
                    if ($testclass)
                    {
                        $result .= "\n$testclass->tear_down() if $testclass->can('tear_down');\n";
                    }
                    $result .= "\n1;";
                    return $result;
                },
            );
            $tests->add_all;
            $tests->save;
        }
    },
);

my $build = $class->new(
    module_name   => 'FusqlFS',
    license       => 'gpl3',
    dist_author   => 'Konstantin Stepanov <me@kstep.me>',
    dist_abstract => 'fusqlfs - FUSE file system to mount DB and provide tools to control and admin it',
    dist_version_from => 'lib/FusqlFS/Version.pm',
    requires => {
        'perl'         => '5.010',

        'Getopt::Long'     => 0,
        'Getopt::ArgvFile' => 0,

        'Pod::Usage'   => 0,
        'Carp'         => 0,
        'Cwd'          => 0,

        'DBI'          => '1.600',

        'POSIX'        => 0,
        'Fcntl'        => 0,
        'Fuse'         => '0.09',
    },
    build_requires => {
        'Test::More'   => 0,
        'Test::Deep'   => 0,
        'Test::Inline' => 0,
        'B::Lint'      => 0,
    },
    recommends => {
        'DBD::mysql'   => 0,
        'DBD::Pg'      => 0,
        'DBD::SQLite'  => 0,

        'XML::Simple'  => 0,
        'JSON::Syck'   => 0,
        'YAML::Tiny'   => 0,
    },
    add_to_cleanup => [ '*.bak', 'FusqlFS-*' ],
);

$build->create_build_script;

