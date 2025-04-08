# Test viewer API

use warnings;
use Lemonldap::NG::Manager::Conf::Diff;
use Test::More;
use strict;
use IO::String;
use JSON qw(from_json);
use Storable qw(dclone);

require 't/test-lib.pm';

# Load lemonldap-ng-noDiff.ini
my $client;
ok(
    $client = LLNG::Manager::Test->new(
        ini => {
            viewerAllowDiff  => 0,
            viewerHiddenKeys =>
              "samlIDPMetaDataNodes samlSPMetaDataNodes portalDisplayLogout",
            viewerAllowBrowser => '$env->{REMOTE_ADDR} ne "127.0.0.1"',
        }
    ),
    'Client object'
);

sub getDiff {
    my (
        $application_list_old, $application_list_new,
        $other_keys_old,       $other_keys_new
    ) = @_;
    return [
        $client->p->Lemonldap::NG::Manager::Conf::Diff::diff( {
                applicationList => $application_list_old,
                %{ $other_keys_old // {} }
            },
            {
                applicationList => $application_list_new,
                %{ $other_keys_new // {} }
            },
        )
    ];
}
my $baseconfig = {
    '1sample' => {
        'applicationtest1' => {
            'options' => {
                'name' => 'Application Test 1',
                'uri'  => 'https://test.internal/'
            },
            'order' => 15,
            'type'  => 'application'
        },
        'type'    => 'category',
        'catname' => 'Sample applications',
        'order'   => 1,
    },
};

subtest "Add a category" => sub {
    my $diff = getDiff(
        $baseconfig,
        {
            %$baseconfig,
            '2new' => {
                'mynewapp1' => {
                    'options' => {
                        'name' => 'My new app 1',
                        'uri'  => 'https://test.internal/'
                    },
                    'order' => 15,
                    'type'  => 'application'
                },
                'type'    => 'category',
                'catname' => 'New applications',
                'order'   => 1,
            },
        }
    );
    is_deeply(
        $diff,
        [
            undef,
            {
                'applicationList' => {
                    'New applications' => {
                        'My new app 1' => {
                            'options' => {
                                'name' => 'My new app 1',
                                'uri'  => 'https://test.internal/'
                            },
                            'order' => 15,
                            'type'  => 'application'
                        },
                        'catname' => 'New applications',
                        'type'    => 'category'
                    }
                }
            }
        ],
        "Expected result"
    );
};

subtest "Delete a category" => sub {
    my $diff = getDiff( {
            %$baseconfig,
            '2new' => {
                'mynewapp1' => {
                    'options' => {
                        'name' => 'My new app 1',
                        'uri'  => 'https://test.internal/'
                    },
                    'order' => 15,
                    'type'  => 'application'
                },
                'type'    => 'category',
                'catname' => 'New applications',
                'order'   => 1,
            },
        },
        $baseconfig
    );
    is_deeply(
        $diff,
        [ {
                'applicationList' => {
                    'New applications' => {
                        'My new app 1' => {
                            'options' => {
                                'name' => 'My new app 1',
                                'uri'  => 'https://test.internal/'
                            },
                            'order' => 15,
                            'type'  => 'application'
                        },
                        'catname' => 'New applications',
                        'type'    => 'category'
                    }
                }
            }
        ],
        "Expected result"
    );
};

subtest "Add an application" => sub {
    my $oldconfig = dclone($baseconfig);
    my $newconfig = dclone($baseconfig);
    $newconfig->{'1sample'}->{newapp} = {
        'options' => {
            'name' => 'A new app',
            'uri'  => 'https://test.internal/'
        },
        'order' => 15,
        'type'  => 'application'
    };

    my $diff = getDiff( $oldconfig, $newconfig );
    is_deeply(
        $diff,
        [
            undef,
            {
                'applicationList' => {
                    'Sample applications' => {
                        'A new app' => {
                            'options' => {
                                'name' => 'A new app',
                                'uri'  => 'https://test.internal/'
                            },
                            'order' => 15,
                            'type'  => 'application'
                        }
                    }
                }
            }
        ],
        "Expected diff"
    );
};

subtest "Remove an application" => sub {
    my $oldconfig = dclone($baseconfig);
    my $newconfig = dclone($baseconfig);
    $oldconfig->{'1sample'}->{newapp} = {
        'options' => {
            'name' => 'A new app',
            'uri'  => 'https://test.internal/'
        },
        'order' => 15,
        'type'  => 'application'
    };

    my $diff = getDiff( $oldconfig, $newconfig );
    is_deeply(
        $diff,
        [ {
                'applicationList' => {
                    'Sample applications' => {
                        'A new app' => {
                            'options' => {
                                'name' => 'A new app',
                                'uri'  => 'https://test.internal/'
                            },
                            'order' => 15,
                            'type'  => 'application'
                        }
                    }
                }
            }
        ],
        "Expected diff"
    );
};

subtest "Modify an application (option)" => sub {
    my $oldconfig = dclone($baseconfig);
    my $newconfig = dclone($baseconfig);
    $newconfig->{'1sample'}->{applicationtest1}->{options}->{uri} =
      "http://new.uri/";

    my $diff = getDiff( $oldconfig, $newconfig );
    is_deeply(
        $diff,
        [ {
                'applicationList' => {
                    'Sample applications' => {
                        'Application Test 1' => {
                            'options' => {
                                'uri' => 'https://test.internal/'
                            }
                        }
                    }
                }
            },
            {
                'applicationList' => {
                    'Sample applications' => {
                        'Application Test 1' => {
                            'options' => {
                                'uri' => 'http://new.uri/'
                            }
                        }
                    }
                }
            }
        ],
        "Expected diff"
    );
};

subtest "Modify an application (name)" => sub {
    my $oldconfig = dclone($baseconfig);
    my $newconfig = dclone($baseconfig);
    $newconfig->{'1sample'}->{applicationtest1}->{options}->{name} =
      "New application name";

    my $diff = getDiff( $oldconfig, $newconfig );
    is_deeply(
        $diff,
        [ {
                'applicationList' => {
                    'Sample applications' => {
                        'New application name' => {
                            'options' => {
                                'name' => 'Application Test 1'
                            }
                        }
                    }
                }
            },
            {
                'applicationList' => {
                    'Sample applications' => {
                        'New application name' => {
                            'options' => {
                                'name' => 'New application name'
                            }
                        }
                    }
                }
            }
        ],
        "Expected diff"
    );
};

subtest "Multiple changes" => sub {
    my $oldconfig = dclone($baseconfig);
    my $newconfig = dclone($baseconfig);

    $oldconfig->{'1sample'}->{applicationtest1}->{options}->{oldoption} = "old";
    $oldconfig->{'1sample'}->{oldapp} = {
        'options' => {
            'name' => 'Application to be removed',
            'uri'  => 'https://old.example.com'
        },
        'order' => 15,
        'type'  => 'application'
    };

    $newconfig->{'1sample'}->{applicationtest1}->{options}->{newoption} = "new";
    $newconfig->{'1sample'}->{newapp} = {
        'options' => {
            'name' => 'A new app',
            'uri'  => 'https://test.internal/'
        },
        'order' => 15,
        'type'  => 'application'
    };

    my $diff = getDiff( $oldconfig, $newconfig );
    is_deeply(
        $diff,
        [ {
                'applicationList' => {
                    'Sample applications' => {
                        'Application Test 1' => {
                            'options' => {
                                'newoption' => undef,
                                'oldoption' => 'old'
                            },
                        },
                        'Application to be removed' => {
                            'options' => {
                                'name' => 'Application to be removed',
                                'uri'  => 'https://old.example.com'
                            },
                            'order' => 15,
                            'type'  => 'application'
                        }
                    }
                }
            },
            {
                'applicationList' => {
                    'Sample applications' => {
                        'A new app' => {
                            'options' => {
                                'name' => 'A new app',
                                'uri'  => 'https://test.internal/'
                            },
                            'order' => 15,
                            'type'  => 'application'
                        },
                        'Application Test 1' => {
                            'options' => {
                                'newoption' => 'new',
                                'oldoption' => undef
                            },
                        }
                    }
                }
            }
        ],
        "Expected diff"
    );
};

subtest "Multiple applications with the same name" => sub {
    my $appList = {
        '1sample' => {
            'applicationtest1' => {
                'options' => {
                    'description' => 'Application Test 1',
                    'display'     => 'auto',
                    'logo'        => 'network.png',
                    'name'        => 'Application Test 1',
                    'tooltip'     => 'New app tooltip',
                    'uri'         => 'https://test.internal/'
                },
                'order' => 15,
                'type'  => 'application'
            },
            'appli1' => {
                'options' => {
                    'description' => 'Application Test 1',
                    'display'     => 'auto',
                    'logo'        => 'network.png',
                    'name'        => 'Application Test 1',
                    'tooltip'     => 'New app tooltip',
                    'uri'         => 'https://test.example.com/'
                },
                'order' => 16,
                'type'  => 'application'
            },
            'type'    => 'category',
            'catname' => 'Sample applications',
            'order'   => 1,
        },
    };
    my $diff =
      getDiff( $appList, $appList, { mykey => 1 }, { mykey => 2 } );
    is_deeply(
        $diff,
        [ {
                'mykey' => 1
            },
            {
                'mykey' => 2
            }
        ],
        "Diff only exposes mykey"
    );
};

done_testing();

