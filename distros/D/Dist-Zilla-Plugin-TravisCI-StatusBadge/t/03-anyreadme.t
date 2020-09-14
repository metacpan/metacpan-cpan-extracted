#!/usr/bin/env perl

use lib qw( t/lib );
use Test::Spec;
use Test::Exception;
use Test::DZil;

use Builder;

my $config = [ 'TravisCI::StatusBadge' ];

sub spoof_distmeta {
    my ( $username ) = @_;

    return +{
        resources => {
            homepage => 'https://github.com/' . $username . '/p5-Foo-Bar',
        }
    };
}

describe "TravisCI::StatusBadge" => sub {
    my ( $tzil );

    describe "for README.mkdn" => sub {
        before all => sub {
            $tzil = t::lib::Builder->tzil_for( 'README.mkdn', 'markdown', $config );

            $tzil->expects( 'distmeta' )
                ->returns( spoof_distmeta( 'Wu-Wu-x' ) )
                ->at_least( 1 );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/README.mkdn' ); };

            like(
                $content,
                qr{\Qtravis-ci.org/Wu-Wu-x/p5-Foo-Bar.png?branch=master\E},
            );
        };
    };

    describe "for README.markdown" => sub {
        before all => sub {
            $tzil = t::lib::Builder->tzil_for( 'README.markdown', 'markdown', $config );

            $tzil->expects( 'distmeta' )
                ->returns( spoof_distmeta( 'Wu-Wu-y' ) )
                ->at_least( 1 );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/README.markdown' ); };

            like(
                $content,
                qr{\Qtravis-ci.org/Wu-Wu-y/p5-Foo-Bar.png?branch=master\E},
            );
        };
    };

    describe "for README.md" => sub {
        before all => sub {
            $tzil = t::lib::Builder->tzil_for( 'README.md', 'markdown', $config );

            $tzil->expects( 'distmeta' )
                ->returns( spoof_distmeta( 'Wu-Wu-z' ) )
                ->at_least( 1 );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

            like(
                $content,
                qr{\Qtravis-ci.org/Wu-Wu-z/p5-Foo-Bar.png?branch=master\E},
            );
        };
    };

    describe "for Readme.mkdn" => sub {
        before all => sub {
            $tzil = t::lib::Builder->tzil_for( 'Readme.mkdn', 'markdown', $config );

            $tzil->expects( 'distmeta' )
                ->returns( spoof_distmeta( 'Wu-Wu-a' ) )
                ->at_least( 1 );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/Readme.mkdn' ); };

            like(
                $content,
                qr{\Qtravis-ci.org/Wu-Wu-a/p5-Foo-Bar.png?branch=master\E},
            );
        };
    };

    describe "for Readme.markdown" => sub {
        before all => sub {
            $tzil = t::lib::Builder->tzil_for( 'Readme.markdown', 'markdown', $config );

            $tzil->expects( 'distmeta' )
                ->returns( spoof_distmeta( 'Wu-Wu-b' ) )
                ->at_least( 1 );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/Readme.markdown' ); };

            like(
                $content,
                qr{\Qtravis-ci.org/Wu-Wu-b/p5-Foo-Bar.png?branch=master\E},
            );
        };
    };

    describe "for Readme.md" => sub {
        before all => sub {
            $tzil = t::lib::Builder->tzil_for( 'Readme.md', 'markdown', $config );

            $tzil->expects( 'distmeta' )
                ->returns( spoof_distmeta( 'Wu-Wu-c' ) )
                ->at_least( 1 );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/Readme.md' ); };

            like(
                $content,
                qr{\Qtravis-ci.org/Wu-Wu-c/p5-Foo-Bar.png?branch=master\E},
            );
        };
    };

    describe "for README1.md" => sub {
        before all => sub {
            $tzil = t::lib::Builder->tzil_for( 'README1.md', 'markdown', $config );

            $tzil->expects( 'distmeta' )
                ->returns( spoof_distmeta( 'Wu-Wu-d' ) )
                ->at_least( 1 );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should not contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/README1.md' ); };

            like(
                $content,
                qr{[^\Q[![Build Status]\E]},
            );
        };
    };

    describe "for README.pod" => sub {
        before all => sub {
            $tzil = t::lib::Builder->tzil_for( 'README.pod', 'pod', $config );

            $tzil->expects( 'distmeta' )
                ->returns( spoof_distmeta( 'Wu-Wu-c' ) )
                ->at_least( 1 );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/README.pod' ); };

            like(
                $content,
                qr{\Q<img alt="Build Status" src="https://travis-ci.org/Wu-Wu-c/p5-Foo-Bar.png?branch=master"\E},
            );
        };
    };

    describe "for README1.pod" => sub {
        before all => sub {
            $tzil = t::lib::Builder->tzil_for( 'README1.pod', 'pod', $config );

            $tzil->expects( 'distmeta' )
                ->returns( spoof_distmeta( 'Wu-Wu-d' ) )
                ->at_least( 1 );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should not contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/README1.pod' ); };

            like(
                $content,
                qr{[^\Q<img alt="Build Status"\E]},
            );
        };
    };

    describe "for README.mdx" => sub {
        before all => sub {
            $tzil = t::lib::Builder->tzil_for( 'README.mdx', 'markdown', $config );

            $tzil->expects( 'distmeta' )
                ->returns( spoof_distmeta( 'Wu-Wu-e' ) )
                ->at_least( 1 );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should not contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/README.mdx' ); };

            like(
                $content,
                qr{[^\Q[![Build Status]\E]},
            );
        };
    };
};

runtests unless caller;
