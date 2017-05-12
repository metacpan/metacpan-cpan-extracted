#!/usr/bin/env perl

use Test::Spec;
use Test::Exception;
use Test::DZil;

use t::lib::Builder;

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

            it "should not contains a badge" => sub {
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

            it "should not contains a badge" => sub {
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

            it "should not contains a badge" => sub {
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

        it "should not contains a badge" => sub {
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

            it "should contains a badge" => sub {
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

            it "should contains a badge" => sub {
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

            it "should contains a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{\Q[![Build Status]\E.*travis-ci\.org.*svg\?branch.*johndoe/p5-John-Doe.*},
                );
            };
        };
    };
};

runtests unless caller;
