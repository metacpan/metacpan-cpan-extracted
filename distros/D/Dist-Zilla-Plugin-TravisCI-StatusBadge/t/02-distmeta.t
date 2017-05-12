#!/usr/bin/env perl

use Test::Spec;
use Test::Exception;
use Test::DZil;

use t::lib::Builder;

describe "TravisCI::StatusBadge" => sub {
    describe "trying distmeta()" => sub {
        my ( $tzil );

        describe "using homepage" => sub {
            before all => sub {
                $tzil = t::lib::Builder->tzil([ 'TravisCI::StatusBadge' ]);

                $tzil->expects( 'distmeta' )
                    ->returns(+{
                        resources => {
                            homepage => 'https://github.com/Wu-Wu/p5-Foo-Bar',
                        }
                    })
                    ->at_least( 1 );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should contains a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{\Qtravis-ci.org/Wu-Wu/p5-Foo-Bar.png?branch=master\E},
                );
            };
        };

        describe "using repository.web" => sub {
            before all => sub {
                $tzil = t::lib::Builder->tzil([ 'TravisCI::StatusBadge' ]);

                $tzil->expects( 'distmeta' )
                    ->returns(+{
                        resources => {
                            repository => {
                                web => 'https://github.com/Wu-Wu-Wu/p5-foo-bar-baz',
                            },
                        }
                    })
                    ->at_least( 1 );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should contains a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{\Qtravis-ci.org/Wu-Wu-Wu/p5-foo-bar-baz.png?branch=master\E},
                );
            };
        };

        describe "using repository.url" => sub {
            before all => sub {
                $tzil = t::lib::Builder->tzil([ 'TravisCI::StatusBadge' ]);

                $tzil->expects( 'distmeta' )
                    ->returns(+{
                        resources => {
                            repository => {
                                url => 'https://github.com/Foo42/p5-Qux-Bar.git',
                            },
                        }
                    })
                    ->at_least( 1 );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should contains a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{\Qtravis-ci.org/Foo42/p5-Qux-Bar.png?branch=master\E},
                );
            };
        };

        describe "using first match" => sub {
            before all => sub {
                $tzil = t::lib::Builder->tzil([ 'TravisCI::StatusBadge' ]);

                $tzil->expects( 'distmeta' )
                    ->returns(+{
                        resources => {
                            homepage => 'https://github.com/Bar42foo/p5-Qux-Qux1',
                            repository => {
                                web => 'https://github.com/Foo42bar/p5-Qux-Qux',
                                url => 'https://github.com/Foo42/p5-Qux-Qux.git',
                            },
                        }
                    })
                    ->at_least( 1 );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should contains a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{\Qtravis-ci.org/Bar42foo/p5-Qux-Qux1.png?branch=master\E},
                );
            };
        };

        describe "for ssh repos" => sub {
            before all => sub {
                $tzil = t::lib::Builder->tzil([ 'TravisCI::StatusBadge' ]);

                $tzil->expects( 'distmeta' )
                    ->returns(+{
                        resources => {
                            repository => {
                                url => 'git@github.com:Qux-42/Foo-Bar.git',
                            },
                        }
                    })
                    ->at_least( 1 );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should contains a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{\Qtravis-ci.org/Qux-42/Foo-Bar.png?branch=master\E},
                );
            };
        };

        describe "for incomplete github source" => sub {
            before all => sub {
                $tzil = t::lib::Builder->tzil([ 'TravisCI::StatusBadge' ]);

                $tzil->expects( 'distmeta' )
                    ->returns(+{
                        resources => {
                            homepage => 'https://github.com/Wu-Wu',
                        }
                    })
                    ->at_least( 1 );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should not contains a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{[^\QBuild Status\E]},
                );
            };
        };

        describe "for not github source" => sub {
            before all => sub {
                $tzil = t::lib::Builder->tzil([ 'TravisCI::StatusBadge' ]);

                $tzil->expects( 'distmeta' )
                    ->returns(+{
                        resources => {
                            repository => {
                                url => 'https://bitbucket.org/Bar42foo/p5-qux.git',
                            },
                        }
                    })
                    ->at_least( 1 );
            };

            it "should build dist" => sub {
                lives_ok { $tzil->build; };
            };

            it "should not contains a badge" => sub {
                my $content = eval { $tzil->slurp_file( 'source/README.md' ); };

                like(
                    $content,
                    qr{[^\QBuild Status\E]},
                );
            };
        };
    };
};

runtests unless caller;
