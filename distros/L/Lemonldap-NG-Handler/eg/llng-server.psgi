# PSGI app that can replace FastCGI server
#
# To use it with uWSGI, use for example:
#
# $ uwsgi --plugins psgi --socket :5000 --psgi e2e-tests/llng-server.psgi
#
# Set LLNG_DEFAULTCONFFILE if it is not in the right place
#$ENV{LLNG_DEFAULTCONFFILE} = 'e2e-tests/conf/lemonldap-ng.ini';

my %builder = (
    handler => sub {
        require Lemonldap::NG::Handler::Server::Nginx;
        return Lemonldap::NG::Handler::Server::Nginx->run( {} );
    },
    reload => sub {
        require Lemonldap::NG::Handler::Server::Nginx;
        return Lemonldap::NG::Handler::Server::Nginx->reload();
    },
    status => sub {
        require Lemonldap::NG::Handler::Server::Nginx;
        return Lemonldap::NG::Handler::Server::Nginx->status();
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

            # Fix PATH_INFO when using Nginx with default uwsgi_params
            # See #2031
            ( $_[0]->{PATH_INFO} ) =
              $_[0]->{REQUEST_URI} =~ /^(?:\Q$_[0]->{SCRIPT_NAME}\E)?([^?]*)/;

            my $script = $_[0]->{SCRIPT_FILENAME};
            return $_apps{$script}->(@_) if ( $_apps{$script} );
            $_apps{$script} = do $script;
            unless ( $_apps{$script} and ref $_apps{$script} ) {
                die "Unable to load $_[0]->{SCRIPT_FILENAME}";
            }
            return $_apps{$script}->(@_);
        }
    },
);

sub {
    my $type = $_[0]->{LLTYPE} || 'handler';
    return $_apps{$type}->(@_) if ( defined $_apps{$type} );
    if ( defined $builder{$type} ) {
        $_apps{$type} = $builder{$type}->();
        return $_apps{$type}->(@_);
    }
    die "Unknown PSGI type $type";
};
