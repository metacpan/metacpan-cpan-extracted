#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {

      # ACCESS TO CONFIGURATION
      # By default, Lemonldap::NG uses the default lemonldap-ng.ini file to know
      # where to find its configuration
      # (generaly /etc/lemonldap-ng/lemonldap-ng.ini)
      # You can specify by yourself this file :
      #configStorage => { confFile => '/path/to/my/file' },
      # or set explicitely parameters :
      #configStorage => {
      #  type => 'File',
      #  dirName => '/usr/local/lemonldap-ng/data/conf/'
      #},
      # Note that YOU HAVE TO SET configStorage here if you've declared this
      # portal as SOAP configuration server in the manager

        # LOG
        # By default, all is logged in Apache file. To log user actions by
        # syslog, just set syslog facility here:
        #syslog => 'auth',

        # SOAP FUNCTIONS
        # Remove comment to activate SOAP Functions getCookies(user,pwd) and
        # error(language, code)
        Soap => 1,

        # Note that getAttibutes() will be activated but on a different URI
        # (http://auth.example.com/index.pl/sessions)
        # You can also restrict attributes and macros exported by getAttributes
        #exportedAttr => 'uid mail',

        # PASSWORD POLICY
        # Remove comment to use LDAP Password Policy
        #ldapPpolicyControl => 1,

        # Remove comment to store password in session (use with caution)
        #storePassword      => 1,

        # Remove comment to use LDAP modify password extension
        # (beware of compatibility with LDAP Password Policy)
        #ldapSetPassword    => 1,

        # RESET PASSWORD BY MAIL
        # SMTP server (default to localhost), set to '' to use default mail
        # service
        #SMTPServer => "localhost",

        # Mail From address
        #mailFrom => "noreply@test.com",

        # Mail subject
        #mailSubject => "Password reset",

 # Mail body (can use $password for generated password, and other session infos,
 # like $cn)
 #mailBody => 'Hello $cn,\n\nYour new password is $password',

        # LDAP filter to use
        #mailLDAPFilter => '(&(mail=$mail)(objectClass=inetOrgPerson))',

        # Random regexp
        #randomPasswordRegexp => '[A-Z]{3}[a-z]{5}.\d{2}',

        # LDAP GROUPS
        # Set the base DN of your groups branch
        #ldapGroupBase => 'ou=groups,dc=example,dc=com',
        # Objectclass used by groups
        #ldapGroupObjectClass => 'groupOfUniqueNames',
        # Attribute used by groups to store member
        #ldapGroupAttributeName => 'uniqueMember',
        # Attribute used by user to link to groups
        #ldapGroupAttributeNameUser => 'dn',
        # Attribute used to identify a group. The group will be displayed as
        # cn|mail|status, where cn, mail and status will be replaced by their
        # values.
        #ldapGroupAttributeNameSearch => ['cn'],

        # CUSTOM FUNCTION
        # If you want to create customFunctions in rules, declare them here:
        #customFunctions    => 'function1 function2',
        #customFunctions    => 'Package::func1 Package::func2',

        # NOTIFICATIONS SERVICE
        # Use it to be able to notify messages during authentication
        #notification => 1,
        # Note that the SOAP function newNotification will be activated on
        # http://auth.example.com/index.pl/notification
        # If you want to hide this, just protect "/index.pl/notification" in
        # your Apache configuration file

        # CROSS-DOMAIN
        # If you have some handlers that are not registered on the main domain,
        # uncomment this
        #cda => 1,

        # XSS protection bypass
        # By default, the portal refuse redirections that comes from sites not
        # registered in the configuration (manager) except for those coming
        # from trusted domains. By default, trustedDomains contains the domain
        # declared in the manager. You can set trustedDomains to empty value so
        # that, undeclared sites will be rejected. You can also set here a list
        # of trusted domains or hosts separated by spaces. This is usefull if
        # your website use Lemonldap::NG without handler with SOAP functions.
        # Exemples :
        #trustedDomains => 'my.trusted.host example2.com',
        #trustedDomains => '',

        # OTHERS
        # You can also overload any parameter issued from manager
        # configuration. Example:
        #globalStorage => 'Apache::Session::File',
        #globalStorageOptions => {
        #  'Directory' => '/var/lib/lemonldap-ng/sessions/'
        #  'LockDirectory' => '/var/lib/lemonldap-ng/sessions/lock/'
        #}
        # Note that YOU HAVE TO SET globalStorage here if you've declared this
        # portal as SOAP session server in the manager
        #},
    }
);

if ( $portal->process() ) {
    print $portal->header('text/html; charset=utf-8');
    print $portal->start_html;
    print "<h1>You are well authenticated !</h1>";
    print "Click <a href=\"$ENV{SCRIPT_NAME}?logout=1\">here</a> to logout";
    print $portal->end_html;
}
else {
    print $portal->header('text/html; charset=utf-8');
    print $portal->start_html;
    print 'Error: ' . $portal->error . '<br />';
    print '<form method="post" action="' . $ENV{SCRIPTNAME} . '">';
    print '<input type="hidden" name="url" value="' . $portal->get_url . '" />';
    print 'Login : <input name="user" /><br />';
    print
'Password : <input name="password" type="password" autocomplete="off"><br>';
    print '<input type="submit" value="OK" />';
    print '</form>';
    print $portal->end_html;
}

