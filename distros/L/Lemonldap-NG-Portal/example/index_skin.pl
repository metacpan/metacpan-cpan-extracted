#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;
use HTML::Template;
use strict;

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {

        # ACCESS TO CONFIGURATION
        # By default, Lemonldap::NG uses the default lemonldap-ng.ini file to
        # know where to find its configuration
        # (generaly /etc/lemonldap-ng/lemonldap-ng.ini)
        # You can specify by yourself this file :
        #configStorage => { confFile => '/path/to/my/file' },
        # or set explicitely parameters :
        #configStorage => {
        #  type => 'File',
        #  dirName => '/usr/local/lemonldap-ng/data//conf'
        #},
        # Note that YOU HAVE TO SET configStorage here if you've declared this
        # portal as SOAP configuration server in the manager

        # OTHERS
        # You can also overload any parameter issued from manager
        # configuration. Example:
        #globalStorage => 'Apache::Session::File',
        #globalStorageOptions => {
        #  'Directory' => '/var/lib/lemonldap-ng/sessions/',
        #  'LockDirectory' => '/var/lib/lemonldap-ng/sessions/lock/',
        #},
        # Note that YOU HAVE TO SET globalStorage here if you've declared this
        # portal as SOAP session server in the manager
    }
);

# Get skin and template parameters
my ( $templateName, %templateParams ) = $portal->display();

# HTML template creation
my $template = HTML::Template->new(
    filename          => "$templateName",
    die_on_bad_params => 0,
    cache             => 0,
    global_vars       => 1,
    loop_context_vars => 1,
    filter            => [
        sub { $portal->translate_template(@_) },
        sub { $portal->session_template(@_) }
    ],
);

# Give parameters to the template
while ( my ( $k, $v ) = each %templateParams ) {
    $template->param( $k, $v );
}

# Display it
print $portal->header('text/html; charset=utf-8');
print $template->output;

