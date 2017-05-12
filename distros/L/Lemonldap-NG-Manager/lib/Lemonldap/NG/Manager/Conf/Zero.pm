package Lemonldap::NG::Manager::Conf::Zero;

sub zeroConf {
    my ( $domain, $sessionDir, $persistentSessionDir, $notificationDir ) = @_;
    $domain               ||= 'example.com';
    $sessionDir           ||= '/var/lib/lemonldap-ng/sessions';
    $persistentSessionDir ||= '/var/lib/lemonldap-ng/psessions';
    $notificationDir      ||= '/var/lib/lemonldap-ng/notifications';
    return {
        'timeout'             => 72000,
        'loginHistoryEnabled' => 1,
        'userDB'              => 'Demo',
        'applicationList'     => {
            '2administration' => {
                'manager' => {
                    'options' => {
                        'logo'        => 'configure.png',
                        'name'        => 'WebSSO Manager',
                        'display'     => 'auto',
                        'uri'         => "http://manager.$domain/manager.html",
                        'description' => 'Configure LemonLDAP::NG WebSSO'
                    },
                    'type' => 'application'
                },
                'sessions' => {
                    'type'    => 'application',
                    'options' => {
                        'display'     => 'auto',
                        'uri'         => "http://manager.$domain/sessions.html",
                        'description' => 'Explore WebSSO sessions',
                        'logo'        => 'database.png',
                        'name'        => 'Sessions explorer'
                    }
                },
                'catname'       => 'Administration',
                'notifications' => {
                    'type'    => 'application',
                    'options' => {
                        'description' => 'Explore WebSSO notifications',
                        'uri' => "http://manager.$domain/notifications.html",
                        'display' => 'auto',
                        'logo'    => 'database.png',
                        'name'    => 'Notifications explorer'
                    }
                },
                'type' => 'category'
            },
            '3documentation' => {
                'type'     => 'category',
                'localdoc' => {
                    'options' => {
                        'description' =>
                          'Documentation supplied with LemonLDAP::NG',
                        'display' => 'on',
                        'uri'     => "http://manager.$domain/doc/",
                        'name'    => 'Local documentation',
                        'logo'    => 'help.png'
                    },
                    'type' => 'application'
                },
                'officialwebsite' => {
                    'options' => {
                        'description' => 'Official LemonLDAP::NG Website',
                        'uri'         => 'http://lemonldap-ng.org/',
                        'display'     => 'on',
                        'logo'        => 'network.png',
                        'name'        => 'Offical Website'
                    },
                    'type' => 'application'
                },
                'catname' => 'Documentation'
            },
            '1sample' => {
                'test1' => {
                    'options' => {
                        'description' =>
                          'A simple application displaying authenticated user',
                        'uri'     => "http://test1.$domain/",
                        'display' => 'auto',
                        'logo'    => 'demo.png',
                        'name'    => 'Application Test 1'
                    },
                    'type' => 'application'
                },
                'catname' => 'Sample applications',
                'type'    => 'category',
                'test2'   => {
                    'type'    => 'application',
                    'options' => {
                        'description' =>
'The same simple application displaying authenticated user',
                        'uri'     => "http://test2.$domain/",
                        'display' => 'auto',
                        'name'    => 'Application Test 2',
                        'logo'    => 'thumbnail.png'
                    }
                }
            }
        },
        'cfgNum'               => 0,
        'globalStorageOptions' => {
            'Directory' => $sessionDir,
            'generateModule' =>
              'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
            'LockDirectory' => "$sessionDir/lock"
        },
        'macros' => {
            '_whatToTrace' =>
              '$_auth eq \'SAML\' ? "$_user\\@$_idpConfKey" : "$_user"'
        },
        'notificationStorageOptions' => {
            'dirName' => $notificationDir
        },
        'authentication'   => 'Demo',
        'demoExportedVars' => {
            'mail' => 'mail',
            'cn'   => 'cn',
            'uid'  => 'uid'
        },
        'domain'                   => $domain,
        'globalStorage'            => 'Apache::Session::File',
        'passwordDB'               => 'Demo',
        'persistentStorage'        => 'Apache::Session::File',
        'persistentStorageOptions' => {
            'Directory'     => $persistentSessionDir,
            'LockDirectory' => "$persistentSessionDir/lock"
        },
        'reloadUrls' => {
            "reload.$domain" => "http://reload.$domain/reload"
        },
        'sessionDataToRemember' => {},
        'notification'          => 1,
        'groups'                => {},
        'exportedHeaders'       => {
            "test1.$domain" => {
                'Auth-User' => '$uid'
            },
            "test2.$domain" => {
                'Auth-User' => '$uid'
            }
        },
        'registerDB'          => 'Demo',
        'registerUrl'         => "http://auth.$domain/register.pl",
        'portal'              => "http://auth.$domain/",
        'notificationStorage' => 'File',
        'locationRules'       => {
            "test1.$domain" => {
                'default'  => 'accept',
                '^/logout' => 'logout_sso'
            },
            "test2.$domain" => {
                'default'  => 'accept',
                '^/logout' => 'logout_sso'
            },
            "manager.$domain" => {
                'default'                                  => '$uid eq "dwho"',
                '(?#Configuration)^/(manager\.html|conf/)' => '$uid eq "dwho"',
                '(?#Sessions)/sessions' => '$uid eq "dwho" or $uid eq "rtyler"',
                '(?#Notifications)/notifications' =>
                  '$uid eq "dwho" or $uid eq "rtyler"',
            }
        },
        'whatToTrace'   => '_whatToTrace',
        'securedCookie' => 0,
        'cookieName'    => 'lemonldap',
        'cfgAuthor'     => 'The LemonLDAP::NG team',
        'exportedVars'  => {
            'UA' => 'HTTP_USER_AGENT'
        },
        'portalSkin' => 'bootstrap',
        'portalSkinBackground' =>
          '1280px-Cedar_Breaks_National_Monument_partially.jpg',
        'mailUrl'                    => "http://auth.$domain/mail.pl",
        'localSessionStorage'        => 'Cache::FileCache',
        'localSessionStorageOptions' => {
            'namespace'          => 'lemonldap-ng-sessions',
            'default_expires_in' => 600,
            'directory_umask'    => '007',
            'cache_root'         => '/tmp',
            'cache_depth'        => 3,
        },
    };
}

1;
