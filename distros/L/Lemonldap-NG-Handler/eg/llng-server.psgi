# PSGI app that can replace FastCGI server
#
# To use it with uWSGI, use for example:
#
# $ uwsgi --plugins psgi --socket :5000 --psgi e2e-tests/llng-server.psgi
#
# Set LLNG_DEFAULTCONFFILE if it is not in the right place
#$ENV{LLNG_DEFAULTCONFFILE} = 'e2e-tests/conf/lemonldap-ng.ini';

our (
  $sourceServer
);

$sourceServer ||= $ENV{SOURCE_SERVER} || 'nginx';
my $class = (
      $sourceServer eq 'nginx'   ? 'Lemonldap::NG::Handler::Server::Nginx'
    : $sourceServer eq 'traefik' ? 'Lemonldap::NG::Handler::Server::Traefik'
    :                              die("Unknown server $sourceServer")
);

my %builder = (
    handler => sub {
        eval "require $class";
        return $class->run( {} );
    },
    reload => sub {
        eval "require $class";
        return $class->reload();
    },
    manager => sub {
        require Lemonldap::NG::Manager;
        return Lemonldap::NG::Manager->run( {} );
    },
    portal => sub {
        require Lemonldap::NG::Portal;
        return Lemonldap::NG::Portal->run( {} );
    },
    cgi => sub {
        require CGI::Emulate::PSGI;
        require CGI::Compile;
        return sub {
            my $script = $_[0]->{SCRIPT_FILENAME};
            return $_apps{$script}->(@_) if ( $_apps{$script} );
            $_apps{$script} =
              CGI::Emulate::PSGI->handler( CGI::Compile->compile($script) );
            return $_apps{$script}->(@_);
        };
    },
    psgi => sub {
        return sub {

            # Reimplement split_pathinfo
            if ( $_[0]->{SCRIPT_NAME}
                and rindex( $_[0]->{PATH_INFO}, $_[0]->{SCRIPT_NAME}, 0 ) == 0 )
            {
                $_[0]->{PATH_INFO} =
                  substr( $_[0]->{PATH_INFO}, length( $_[0]->{SCRIPT_NAME} ) );
            }

            my $script = $_[0]->{SCRIPT_FILENAME};
            return $_apps{$script}->(@_) if ( $_apps{$script} );
            $_apps{$script} = do $script;
            unless ( $_apps{$script} and ref $_apps{$script} ) {
                my $errmsg = $@ || $! || "unknown error";
                die("Unable to load $_[0]->{SCRIPT_FILENAME}: $errmsg");
            }
            return $_apps{$script}->(@_);
        }
    },
);

# This middleware is a workaround for the fact that UWSGI does not
# automatically downgrade UTF8 strings, unlike Apache and FastCGI
# We can't blame it because PSGI responses are supposed to be byte string, not
# unicode strings
# It can be disabled by setting the LLNG_SKIPUTF8DOWNGRADE environment variable
sub optional_utf8_middleware {
    my $app = shift;
    if ( !$ENV{LLNG_SKIPUTF8DOWNGRADE} ) {
        return sub {
            my $env = shift;
            my $res = $app->($env);

            # Downgrade headers
            map { utf8::downgrade($_) } @{ $res->[1] };

            # Downgrade body
            map { utf8::downgrade($_) } @{ $res->[2] }
              if ref( $res->[2] ) eq "ARRAY";
            return $res;
        };
    }
    else {
        return $app;
    }
}

sub {
    my $type = $_[0]->{LLTYPE} || 'handler';
    return $_apps{$type}->(@_) if ( defined $_apps{$type} );
    if ( defined $builder{$type} ) {
        my $app = $builder{$type}->();
        $_apps{$type} = optional_utf8_middleware($app);
        return $_apps{$type}->(@_);
    }
    die "Unknown PSGI type $type";
};
