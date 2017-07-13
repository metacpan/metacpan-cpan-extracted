my $root_dir                  = $properties->{'dev.root.dir'};
my $trusted_hostname          = 'trusted.pastdev.com';
my $trusted_internal_hostname = 'trusted.pastdev.local';
my $web_hostname              = 'web.pastdev.com';

my $coord                = 'dev';
my $foo_tomcat_directory = "$root_dir/foo-tomcat";

return {
    base_tomcat => {
        hostname      => $properties->{'dev.foo.hostname'},
        catalina_base => "$root_dir/apache-tomcat"
    },
    foo => {
        automation => {
            username => $properties->{'dev.foo.automation.username'},
            password => $properties->{'dev.foo.automation.password'},
        },
        deployment => {
            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
            clean                       => [
                "$foo_tomcat_directory/conf/Catalina/localhost/", "$foo_tomcat_directory/temp/",
                "$foo_tomcat_directory/webapps/",                 "$foo_tomcat_directory/work/",
            ],
            resources => {
                bar => "$properties{'dev.foo.deployment.resources.dir'}/bar.war",
                baz => "$properties{'dev.foo.deployment.resources.dir'}/baz.war"
            },
            to_dir => "$foo_tomcat_directory/webapps",
        },
        hostname => $properties->{'dev.foo.hostname'},
        logs     => { catalina => "$foo_tomcat_directory/logs/catalina.out", },
        overlay  => {
            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
            base_dir            => "$properties{'dev.foo.overlay.dir'}/base",
            clean               => [ "$foo_tomcat_directory/" ],
            key                 => 'T',
            os                  => $properties{'dev.os'},
            resolver_coordinate => $coord,
            template_dir        => "$properties{'dev.foo.overlay.dir'}/template",
            to_dir              => $foo_tomcat_directory
        },
        site          => '',
        sudo_username => $properties->{'dev.foo.sudo_username'},
        tomcat        => {
            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
            ajp           => { port => 8509 },
            catalina_base => $foo_tomcat_directory,
            http          => { port => 8580 },
            jmx_port      => 8587,
            jpda_port     => 8586,
            service       => {
                action => {
                    'kill'   => { command_args => 'stop -force' },
                    'status' => { use_pid      => 1 }
                },
                command  => "$foo_tomcat_directory/bin/catalina.sh",
                pid_file => "/var/run/foo/catalina.pid",
            },
            shutdown => {
                port     => 8505,
                password => $properties->{'dev.foo.tomcat.shutdown.password'},
            },
            trust_store => {
                'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
                file                      => "$foo_tomcat_directory/certs/truststore.jks",
                include_java_home_cacerts => 1,
                password                  => $properties->{'dev.foo.tomcat.trust_store.password'},
            }
        },
        web => {
            context_path => '/foo',
            hostname     => $foo_web_hostname,
            https        => 1
        },
        web_direct => {
            'Config::Entities::inherit' => ['hostname'],
            context_path                => '/foo',
            https                       => 0,
            port                        => 8580
        }
    },
    trusted => {
        hostname          => $trusted_hostname,
        internal_hostname => $trusted_internal_hostname
    }
    }
