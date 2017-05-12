package My::Package;
use Lemonldap::NG::Handler::SharedConf;
@ISA = qw(Lemonldap::NG::Handler::SharedConf);

use Log::Log4perl;

sub logForbidden {
    my $class = shift;
    my $log   = Log::Log4perl->get_logger("My::Package");
    $log->warn(
            'The user "'
          . $datas->{$whatToTrace}
          . '" was reject when he tried to access to '
          . shift,
    );
}

__PACKAGE__->init(
    {

        # ACCESS TO CONFIGURATION

      # By default, Lemonldap::NG uses the default lemonldap-ng.ini file to know
      # where to find is configuration
      # (generaly /etc/lemonldap-ng/lemonldap-ng.ini)
      # You can specify by yourself this file :
      #configStorage => { confFile => '/path/to/my/file' },

        # You can also specify directly the configuration
        # (see Lemonldap::NG::Handler::SharedConf(3))
        #configStorage => {
        #      type => 'File',
        #      dirName => '/usr/local/lemonldap-ng/data/conf/'
        #},

        # STATUS MODULE
        # Uncomment this to activate status module:
        #status => 1,

        # REDIRECTIONS
        # You have to set this to explain to the handler if runs under SSL
        # or not (for redirections after authentications). Default is true.
        https => 0,

        # You can also fix the port (for redirections after authentications)
        #port => 80,

        # CUSTOM FUNCTION
        # If you want to create customFunctions in rules, declare them here:
        #customFunctions    => 'function1 function2',
        #customFunctions    => 'Package::func1 Package::func2',

        # OTHERS
        # You can also overload any parameter issued from manager
        # configuration. Example:
        #globalStorage => 'Lemonldap::NG::Common::Apache::Session::SOAP',
        #globalStorageOptions => {
        #    proxy => 'http://auth.example.com/index.pl/sessions',
        #    proxyOptions => {
        #        timeout => 5,
        #    },
        #    # If soapserver is protected by HTTP Basic:
        #    User     => 'http-user',
        #    Password => 'pass',
        #},
    }
);
1;
