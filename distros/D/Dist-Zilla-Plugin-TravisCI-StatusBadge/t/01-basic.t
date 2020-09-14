#!/usr/bin/env perl

use lib qw( t/lib );
use Test::Spec;
use Test::Exception;
use Test::DZil;

use Builder;

describe "TravisCI::StatusBadge" => sub {
    it "should compile ok" => sub {
        use_ok( 'Dist::Zilla::Plugin::TravisCI::StatusBadge' );
    };

    describe "when missed" => sub {
        describe "both user and repo" => sub {
            my ( $tzil );

            before all => sub {
                $tzil = t::lib::Builder->tzil(
                    [ 'TravisCI::StatusBadge' => {} ]
                );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should not contain a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{[^\Q[![Build Status]\E]},
                );
            };
        };

        describe "an user" => sub {
            my ( $tzil );

            before all => sub {
                $tzil = t::lib::Builder->tzil(
                    [ 'TravisCI::StatusBadge' => { repo => 'p5-John-Doe' } ]
                );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should not contain a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{[^\Q[![Build Status]\E]},
                );
            };
        };

        describe "a repo" => sub {
            my ( $tzil );

            before all => sub {
                $tzil = t::lib::Builder->tzil(
                    [ 'TravisCI::StatusBadge' => { user => 'johndoe' } ]
                );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should not contain a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{[^\Q[![Build Status]\E]},
                );
            };
        };
    };

    describe "when wrong README" => sub {
        my ( $tzil );

        before all => sub {
            $tzil = t::lib::Builder->tzil(
                [
                    'TravisCI::StatusBadge' => {
                        repo    => 'p5-John-Doe',
                        user    => 'johndoe',
                        readme  => 'README.markdown'
                    }
                ]
            );
        };

        it "should build dist" => sub {
            lives_ok { $tzil->build; };
        };

        it "should not contain a badge" => sub {
            my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

            like(
                $content,
                qr{[^\Q[![Build Status]\E]},
            );
        };
    };

    describe "otherwise" => sub {
        describe "when user and repo" => sub {
            my ( $tzil );

            before all => sub {
                $tzil = t::lib::Builder->tzil(
                    [
                        'TravisCI::StatusBadge' => {
                            repo    => 'p5-John-Doe',
                            user    => 'johndoe',
                        }
                    ]
                );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should contain a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{\Q[![Build Status]\E.*travis-ci\.org.*master.*johndoe/p5-John-Doe.*},
                );
            };
        };

        describe "when branch" => sub {
            my ( $tzil );

            before all => sub {
                $tzil = t::lib::Builder->tzil(
                    [
                        'TravisCI::StatusBadge' => {
                            repo    => 'p5-John-Doe',
                            user    => 'johndoe',
                            branch  => 'foo22',
                        }
                    ]
                );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should contain a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{\Q[![Build Status]\E.*travis-ci\.org.*foo22.*johndoe/p5-John-Doe.*},
                );
            };
        };

        describe "when vector" => sub {
            my ( $tzil );

            before all => sub {
                $tzil = t::lib::Builder->tzil(
                    [
                        'TravisCI::StatusBadge' => {
                            repo    => 'p5-John-Doe',
                            user    => 'johndoe',
                            vector  => 1,
                        }
                    ]
                );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should contain a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{\Q[![Build Status]\E.*travis-ci\.org.*svg\?branch.*johndoe/p5-John-Doe.*},
                );
            };
        };

        describe "when format = markdown" => sub {
            my ( $tzil_default, $tzil_markdown );

            before all => sub {
                $tzil_default = t::lib::Builder->tzil(
                    [
                        'TravisCI::StatusBadge' => {
                            repo    => 'p5-John-Doe',
                            user    => 'johndoe',
                        }
                    ]
                );
                $tzil_markdown = t::lib::Builder->tzil(
                    [
                        'TravisCI::StatusBadge' => {
                            repo    => 'p5-John-Doe',
                            user    => 'johndoe',
                            format  => 'markdown'
                        }
                    ]
                );
            };

            it "should build dist" => sub {
                lives_ok { $tzil_markdown->build; };
                $tzil_default->build;
            };

            it "should match up with default format" => sub {
                my $content_default = eval { $tzil_default->slurp_file( 'source/README.md' ); };
                my $content_markdown = eval { $tzil_markdown->slurp_file( 'source/README.md' ); };

                is $content_default, $content_markdown;
            };
        };

        describe "when format = pod" => sub {
            my ( $tzil );

            before all => sub {
                $tzil = t::lib::Builder->tzil_for_pod(
                    [
                        'TravisCI::StatusBadge' => {
                            repo    => 'p5-John-Doe',
                            user    => 'johndoe',
                            format  => 'pod',
                            readme  => 'README',
                        }
                    ]
                );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should contain a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README' ); };

                like(
                    $content,
                    qr{\Q<img alt="Build Status"},
                );
            };
        };
    };
};

runtests unless caller;
