# Lemonldap::NG::Manager kinematic

## Initialization

    PSGI file
     |
     +-> Common::PSGI::run() (Manager inheritance)
          |
          +-> Common::PSGI::new() unless(defined $self)
          |
          +-> Manager::init()
          |    |
          |    +-> Handler::PSGI::Router::init()
          |    |    |
          |    |    +-> Common::PSGI::init()
          |    |    |
          |    |    +-> Handler::PSGI::Base::init()
          |    |
          |    +-> Manager::<modules>::addRoutes()
          |        (module can be one of `Conf`, `Sessions`, `Notifications`)
          |         |
          |         +-> Common::PSGI::Router::addRoute()
          |
          +-> Handler::PSGI::Base::_run()
               |
               +-> if protected:
                   Handler::PSGI::Base::_authAndTrace()


_Common::PSGI::run()_ returns a subroutine

## HTTP responses

PSGI system launch the previous sub returned by Handler::PSGI::Base::\_run()

    sub
     |
     +-> if protection is set:
     |   Lemonldap::NG::Handler::SharedConf::run()
     |
     +-> Common::PSGI::Router::handler ( Lemonldap::NG::Common::PSGI::Request->new() )
          |
          +-> Common::PSGI::Router::followPath()
               |
               +-> Launch the corresponding Manager::<module> subroutine declared with addRoutes()

