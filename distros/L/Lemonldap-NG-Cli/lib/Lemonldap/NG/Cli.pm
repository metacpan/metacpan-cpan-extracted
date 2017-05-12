package Lemonldap::NG::Cli;

# Required packages

use strict;
use Lemonldap::NG::Common::Conf;

use feature qw (switch);

# Constants

our $VERSION = "0.2";

my $ERRORS =
{
     TOO_FEW_ARGUMENTS  => "Too few arguments",
     UNKNOWN_ACTION     => "Unknown action",
     CONFIG_WRITE_ERROR => "Error while writting the configuration",
     NOT_IMPLEMENTED    => "Not yet implemented",
};

## @cmethod Lemonldap::NG::Cli new ()
# Create a new Lemonldap::NG::Cli object
#
# @return New Lemonldap::NG::Cli object
sub new
{
     my ($class) = @_;

     my $this =
     {
          "confAccess" => Lemonldap::NG::Common::Conf->new ()
     };

     $this->{conf} = $this->{confAccess}->getConf ();

     bless ($this, $class);
     return $this;
}

## @method int saveConf ()
# Save LemonLDAP::NG configuration
#
# @return Configuration identifier.
sub saveConf
{
     my ($self) = @_;
     my $ret = $self->{confAccess}->saveConf ($self->{conf});
     return $ret;
}

## @method int run (array argv)
# Run the application
#
# @param @argv List of arguments of the command line
# @return Exit code
sub run
{
     my ($self, @argv) = @_;

     $self->{argv} = \@argv;
     $self->{argc} = @argv;

     if (!$self->parseCmd ())
     {
          print STDERR $self->getError (), "\n";
          return 1;
     }

     if (!$self->action ())
     {
          print STDERR $self->getError (), "\n";
          return 1;
     }

     if ($self->{action}->{save})
     {
          # Save configuration
          my $cfgNb = $self->saveConf ();

          # If there is no config identifier, then an error occured
          if (!$cfgNb)
          {
               $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR});
               return 0;
          }

          print "Configuration $cfgNb created!\n";
     }

     return 0;
}

## @method bool parseCmd ()
# Parse command line
#
# @return true on success, false otherwise
sub parseCmd
{
     my ($self) = @_;

     # check if there is at least on action specified
     if ($self->{argc} < 1)
     {
          $self->setError ($ERRORS->{TOO_FEW_ARGUMENTS});
          return 0;
     }

     given ($self->{argv}[0])
     {
          ## Variables

          when ("set")
          {
               # set takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $var = $self->{argv}[1];
               my $val = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type => "set",
                    save => 1,
                    var  => $var,
                    val  => $val,
               };
          }

          when ("unset")
          {
               # unset takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $var = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "unset",
                    save => 1,
                    var  => $var
               };
          }

          when ("get")
          {
               # get takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $var = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "get",
                    save => 0,
                    var  => $var,
               };
          }

          ## Macros

          when ("set-macro")
          {
               # set-macro takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $m_name = $self->{argv}[1];
               my $m_expr = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type => "set-macro",
                    save => 1,
                    name => $m_name,
                    expr => $m_expr
               };
          }

          when ("unset-macro")
          {
               # unset-macro takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $m_name = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "unset-macro",
                    save => 1,
                    var  => $m_name
               };

          }

          when ("get-macro")
          {
               # get-macro tkaes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $m_name = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "get-macro",
                    save => 0,
                    name => $m_name
               };
          }

          ## Applications

          when ("apps-set-cat")
          {
               # apps-set-cat takes two parameter
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $catid   = $self->{argv}[1];
               my $catname = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type => "apps-set-cat",
                    save => 1,
                    id   => $catid,
                    name => $catname
               };
          }

          when ("apps-get-cat")
          {
               # apps-get-cat takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $catid = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "apps-get-cat",
                    save => 0,
                    id   => $catid
               };
          }

          when ("apps-add")
          {
               # apps-add takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $appid = $self->{argv}[1];
               my $catid = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type  => "apps-add",
                    save => 1,
                    appid => $appid,
                    catid => $catid
               };
          }

          when ("apps-set-uri")
          {
               # apps-set-uri takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $appid  = $self->{argv}[1];
               my $appuri = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type => "apps-set-uri",
                    save => 1,
                    id   => $appid,
                    uri  => $appuri
               };
          }

          when ("apps-set-name")
          {
               # apps-set-name takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $appid   = $self->{argv}[1];
               my $appname = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type => "apps-set-name",
                    save => 1,
                    id   => $appid,
                    name => $appname
               };
          }

          when ("apps-set-desc")
          {
               # apps-set-desc takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $appid   = $self->{argv}[1];
               my $appdesc = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type => "apps-set-desc",
                    save => 1,
                    id   => $appid,
                    desc => $appdesc
               };
          }

          when ("apps-set-logo")
          {
               # apps-set-logo takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $appid   = $self->{argv}[1];
               my $applogo = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type => "apps-set-logo",
                    save => 1,
                    id   => $appid,
                    logo => $applogo
               };
          }

          when ("apps-set-display")
          {
               # apps-set-display takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $appid  = $self->{argv}[1];
               my $appdpy = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type => "apps-set-display",
                    save => 1,
                    id   => $appid,
                    dpy  => $appdpy
               };
          }

          when ("apps-get")
          {
               # apps-get takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $appid = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "apps-get",
                    save => 0,
                    id   => $appid
               };
          }

          when ("apps-rm")
          {
               # apps-rm takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $appid = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "apps-rm",
                    save => 1,
                    id   => $appid
               };
          }

          ## Rules

          when ("rules-set")
          {
               # rules-set takes 3 parameters
               if ($self->{argc} < 4)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $uri  = $self->{argv}[1];
               my $expr = $self->{argv}[2];
               my $rule = $self->{argv}[3];

               # define action
               $self->{action} =
               {
                    type => "rules-set",
                    save => 1,
                    uri  => $uri,
                    expr => $expr,
                    rule => $rule
               };
          }

          when ("rules-unset")
          {
               # rules-unset takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $uri  = $self->{argv}[1];
               my $expr = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type => "rules-unset",
                    save => 1,
                    uri  => $uri,
                    expr => $expr
               };
          }

          when ("rules-get")
          {
               # rules-get takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $uri = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "rules-get",
                    save => 0,
                    uri  => $uri
               };
          }

          ## exported variables

          when ("export-var")
          {
               # export-var takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $key = $self->{argv}[1];
               my $val = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type => "export-var",
                    save => 1,
                    key  => $key,
                    val  => $val
               };
          }

          when ("unexport-var")
          {
               # unexport-var takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $key = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "unexport-var",
                    save => 1,
                    key  => $key
               };
          }

          when ("get-exported-vars")
          {
               # get-exported-varis doesn't take any parameter

               # define action
               $self->{action} =
               {
                    type => "get-exported-vars",
                    save => 0
               };
          }

          ## exported headers

          when ("export-header")
          {
               # export-header takes 3 parameters
               if ($self->{argc} < 4)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $vhost  = $self->{argv}[1];
               my $header = $self->{argv}[2];
               my $expr   = $self->{argv}[3];

               # define action
               $self->{action} =
               {
                    type   => "export-header",
                    save   => 1,
                    vhost  => $vhost,
                    header => $header,
                    expr   => $expr
               };
          }

          when ("unexport-header")
          {
               # unexport-header takes two parameter
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $vhost  = $self->{argv}[1];
               my $header = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type   => "unexport-header",
                    save   => 1,
                    vhost  => $vhost,
                    header => $header,
               };
          }

          when ("get-exported-headers")
          {
               # get-exported-header takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $vhost = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type  => "get-exported-headers",
                    save  => 0,
                    vhost => $vhost
               };
          }

          ## virtual host

          when ("vhost-add")
          {
               # vhost-add takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $vhost = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type  => "vhost-add",
                    save  => 1,
                    vhost => $vhost
               };
          }

          when ("vhost-del")
          {
               # vhost-del takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $vhost = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type  => "vhost-del",
                    save  => 1,
                    vhost => $vhost
               };
          }

          when ("vhost-set-port")
          {
               # vhost-set-port takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $vhost = $self->{argv}[1];
               my $port  = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type  => "vhost-set-port",
                    save  => 1,
                    vhost => $vhost,
                    port  => $port
               };
          }

          when ("vhost-set-https")
          {
               # vhost-set-https takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $vhost = $self->{argv}[1];
               my $https = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type  => "vhost-set-https",
                    save  => 1,
                    vhost => $vhost,
                    https => $https
               };
          }


          when ("vhost-set-maintenance")
          {
               # vhost-set-maintenance takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $vhost = $self->{argv}[1];
               my $off   = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type  => "vhost-set-maintenance",
                    save  => 1,
                    vhost => $vhost,
                    off   => $off
               };
          }

          when ("vhost-list")
          {
               # vhost-list doesn't take any parameter

               # define action
               $self->{action} =
               {
                    type => "vhost-list",
                    save => 0
               };
          }

          ## global storage

          when ("global-storage")
          {
               # global-storage doesn't take any parameter

               # define action
               $self->{action} =
               {
                    type => "global-storage",
                    save => 0
               };
          }

          when ("global-storage-set-dir")
          {
               # global-storage takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $path = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "global-storage-set-dir",
                    save => 1,
                    path => $path
               };
          }

          when ("global-storage-set-lockdir")
          {
               # global-storage takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $path = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type => "global-storage-set-lockdir",
                    save => 1,
                    path => $path
               };
          }

          ## reload URLs

          when ("reload-urls")
          {
               # reload-urls doesn't take any parameter

               # define action
               $self->{action} =
               {
                    type => "reload-urls",
                    save => 0
               };
          }

          when ("reload-url-add")
          {
               # reload-url-add takes two parameters
               if ($self->{argc} < 3)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $vhost = $self->{argv}[1];
               my $url   = $self->{argv}[2];

               # define action
               $self->{action} =
               {
                    type  => "reload-url-add",
                    save  => 0,
                    vhost => $vhost,
                    url   => $url
               };
          }

          when ("reload-url-del")
          {
               # reload-url-del takes one parameter
               if ($self->{argc} < 2)
               {
                    $self->setError ("$_: ".$ERRORS->{TOO_FEW_ARGUMENTS});
                    return 0;
               }

               my $vhost = $self->{argv}[1];

               # define action
               $self->{action} =
               {
                    type  => "reload-url-del",
                    save  => 0,
                    vhost => $vhost
               };
          }

          # no action found
          default
          {
               $self->setError ("$_: ".$ERRORS->{UNKNOWN_ACTION});
               return 0;
          }
     }

     return 1;
}

## @method bool action ()
# Execute action parsed by parseCmd() method
#
# @return true on success, false otherwise
sub action
{
     my ($self) = @_;

     given ($self->{action}->{type})
     {
          ## Variables

          when ("set")
          {
               my $var = $self->{action}->{var};
               my $val = $self->{action}->{val};

               $self->{conf}->{$var} = $val;
          }

          when ("unset")
          {
               my $var = $self->{action}->{var};

               if (not defined ($self->{conf}->{$var}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no variables named '$var'");
                    return 0;
               }

               delete $self->{conf}->{$var};
          }

          when ("get")
          {
               my $var = $self->{action}->{var};

               if (not defined ($self->{conf}->{$var}))
               {
                    $self->setError ("$_: There is no variables named '$var'");
                    return 0;
               }

               print "$var = '", $self->{conf}->{$var}, "'\n";
          }

          ## Macros

          when ("set-macro")
          {
               my $m_name = $self->{action}->{name};
               my $m_expr = $self->{action}->{expr};

               $self->{conf}->{macros}->{$m_name} = $m_expr;
          }

          when ("unset-macro")
          {
               my $m_name = $self->{action}->{name};

               if (not defined ($self->{conf}->{macros}->{$m_name}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no macros named '$m_name'");
                    return 0;
               }

               delete $self->{conf}->{macros}->{$m_name};
          }

          when ("get-macro")
          {
               my $m_name = $self->{action}->{name};

               if (not defined ($self->{conf}->{macros}->{$m_name}))
               {
                    $self->setError ("$_: There is no macros named '$m_name'");
                    return 0;
               }

               print "$m_name = '", $self->{conf}->{macros}->{$m_name}, "'\n";
          }

          ## Applications

          when ("apps-set-cat")
          {
               my $catid   = $self->{action}->{id};
               my $catname = $self->{action}->{name};

               if (defined ($self->{conf}->{applicationList}->{$catid}))
               {
                    $self->{conf}->{applicationList}->{$catid}->{catname} = $catname;
               }
               else
               {
                    $self->{conf}->{applicationList}->{$catid} =
                    {
                         type    => "category",
                         catname => $catname
                    };
               }
          }

          when ("apps-get-cat")
          {
               my $catid = $self->{action}->{id};

               if (not defined ($self->{conf}->{applicationList}->{$catid}))
               {
                    $self->setError ("$_: There is no category '$catid'");
                    return 0;
               }

               print "$catid: ", $self->{conf}->{applicationList}->{$catid}->{catname}, "\n";
          }

          when ("apps-add")
          {
               my $appid = $self->{action}->{appid};
               my $catid = $self->{action}->{catid};

               if (not defined ($self->{conf}->{applicationList}->{$catid}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": Category '$catid' doesn't exist");
                    return 0;
               }

               if (defined ($self->{conf}->{applicationList}->{$catid}->{$appid}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": Application '$appid' exists");
                    return 0;
               }

               $self->{conf}->{applicationList}->{$catid}->{$appid} =
               {
                    type => "application",
                    options =>
                    {
                         logo        => "demo.png",
                         name        => $appid,
                         description => $appid,
                         display     => "auto",
                         uri         => "http://test1.example.com"
                    }
               };
          }

          when ("apps-set-uri")
          {
               my $appid  = $self->{action}->{id};
               my $appuri = $self->{action}->{uri};

               my $found = 0;
               while (my ($catid, $applist) = each %{$self->{conf}->{applicationList}} and $found != 1)
               {
                    while (my ($_appid, $app) = each %{$applist} and $found != 1)
                    {
                         if ($appid eq $_appid)
                         {
                              $app->{options}->{uri} = $appuri;
                              $found = 1;
                         }
                    }
               }

               if ($found == 0)
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": Application '$appid' not found");
                    return 0;
               }
          }

          when ("apps-set-name")
          {
               my $appid   = $self->{action}->{id};
               my $appname = $self->{action}->{name};

               my $found = 0;
               while (my ($catid, $applist) = each %{$self->{conf}->{applicationList}} and $found != 1)
               {
                    while (my ($_appid, $app) = each %{$applist} and $found != 1)
                    {
                         if ($appid eq $_appid)
                         {
                              $app->{options}->{name} = $appname;
                              $found = 1;
                         }
                    }
               }

               if ($found == 0)
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": Application '$appid' not found");
                    return 0;
               }
          }

          when ("apps-set-desc")
          {
               my $appid   = $self->{action}->{id};
               my $appdesc = $self->{action}->{desc};

               my $found = 0;
               while (my ($catid, $applist) = each %{$self->{conf}->{applicationList}} and $found != 1)
               {
                    while (my ($_appid, $app) = each %{$applist} and $found != 1)
                    {
                         if ($appid eq $_appid)
                         {
                              $app->{options}->{description} = $appdesc;
                              $found = 1;
                         }
                    }
               }

               if ($found == 0)
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": Application '$appid' not found");
                    return 0;
               }
          }

          when ("apps-set-logo")
          {
               my $appid   = $self->{action}->{id};
               my $applogo = $self->{action}->{logo};

               my $found = 0;
               while (my ($catid, $applist) = each %{$self->{conf}->{applicationList}} and $found != 1)
               {
                    while (my ($_appid, $app) = each %{$applist} and $found != 1)
                    {
                         if ($appid eq $_appid)
                         {
                              $app->{options}->{logo} = $applogo;
                              $found = 1;
                         }
                    }
               }

               if ($found == 0)
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": Application '$appid' not found");
                    return 0;
               }
          }

          when ("apps-set-display")
          {
               my $appid  = $self->{action}->{id};
               my $appdpy = $self->{action}->{dpy};

               my $found = 0;
               while (my ($catid, $applist) = each %{$self->{conf}->{applicationList}} and $found != 1)
               {
                    while (my ($_appid, $app) = each %{$applist} and $found != 1)
                    {
                         if ($appid eq $_appid)
                         {
                              $app->{options}->{display} = $appdpy;
                              $found = 1;
                         }
                    }
               }

               if ($found == 0)
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": Application '$appid' not found");
                    return 0;
               }
          }

          when ("apps-get")
          {
               my $appid = $self->{action}->{id};

               my $found = 0;
               while (my ($catid, $applist) = each %{$self->{conf}->{applicationList}} and $found != 1)
               {
                    while (my ($_appid, $app) = each %{$applist} and $found != 1)
                    {
                         if ($appid eq $_appid)
                         {
                              print "Category '$catid': ".$self->{conf}->{applicationList}->{$catid}->{catname}."\n";
                              print "Application '$appid': ".$app->{options}->{name}."\n";
                              print "- Description: ".$app->{options}->{description}."\n";
                              print "- URI: ".$app->{options}->{uri}."\n";
                              print "- Logo: ".$app->{options}->{logo}."\n";
                              print "- Display: ".$app->{options}->{display}."\n";
                              $found = 1;
                         }
                    }
               }

               if ($found == 0)
               {
                    $self->setError ("$_: Application '$appid' not found");
                    return 0;
               }
          }

          when ("apps-rm")
          {
               my $appid = $self->{action}->{id};

               my $found = 0;
               while (my ($catid, $applist) = each %{$self->{conf}->{applicationList}} and $found != 1)
               {
                    while (my ($_appid, $app) = each %{$applist} and $found != 1)
                    {
                         if ($appid eq $_appid)
                         {
                              delete $applist->{$appid};
                              $found = 1;
                         }
                    }
               }
          }

          ## Rules

          when ("rules-set")
          {
               my $uri  = $self->{action}->{uri};
               my $expr = $self->{action}->{expr};
               my $rule = $self->{action}->{rule};

               if (not defined ($self->{conf}->{locationRules}->{$uri}))
               {
                    $self->{conf}->{locationRules}->{$uri} = {};
               }

               $self->{conf}->{locationRules}->{$uri}->{$expr} = $rule;
          }

          when ("rules-unset")
          {
               my $uri  = $self->{action}->{uri};
               my $expr = $self->{action}->{expr};

               if (not defined ($self->{conf}->{locationRules}->{$uri}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no virtual host '$uri'");
                    return 0;
               }

               if (not defined ($self->{conf}->{locationRules}->{$uri}->{$expr}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is rule '$expr' for virtual host '$uri'");
                    return 0;
               }

               delete $self->{conf}->{locationRules}->{$uri}->{$expr};
          }

          when ("rules-get")
          {
               my $uri = $self->{action}->{uri};

               if (not defined ($self->{conf}->{locationRules}->{$uri}))
               {
                    $self->setError ("$_: There is no virtual host '$uri'");
                    return 0;
               }

               print "Virtual Host : $uri\n";
               while (my ($expr, $rule) = each %{$self->{conf}->{locationRules}->{$uri}})
               {
                    print "- $expr => '$rule'\n";
               }
          }

          ## exported variables

          when ("export-var")
          {
               my $key = $self->{action}->{key};
               my $val = $self->{action}->{val};

               $self->{conf}->{exportedVars}->{$key} = $val;
          }

          when ("unexport-var")
          {
               my $key = $self->{action}->{key};

               if (not defined ($self->{conf}->{exportedVars}->{$key}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no exported variables named '$key'");
                    return 0;
               }

               delete $self->{conf}->{exportedVars}->{$key};
          }

          when ("get-exported-vars")
          {
               while (my ($key, $val) = each %{$self->{conf}->{exportedVars}})
               {
                    print "$key = $val\n";
               }
          }

          ## exported headers

          when ("export-header")
          {
               my $vhost  = $self->{action}->{vhost};
               my $header = $self->{action}->{header};
               my $expr   = $self->{action}->{expr};

               if (not defined ($self->{conf}->{exportedHeaders}->{$vhost}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no virtual host '$vhost'\n");
                    return 0;
               }

               $self->{conf}->{exportedHeaders}->{$vhost}->{$header} = $expr;
          }

          when ("unexport-header")
          {
               my $vhost  = $self->{action}->{vhost};
               my $header = $self->{action}->{header};
               my $expr   = $self->{action}->{expr};

               if (not defined ($self->{conf}->{exportedHeaders}->{$vhost}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no virtual host '$vhost'\n");
                    return 0;
               }

               if (not defined ($self->{conf}->{exportedHeaders}->{$vhost}->{$header}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no header named '$header' exported for virtual host '$vhost'\n");
                    return 0;
               }

               delete $self->{conf}->{exportedHeaders}->{$vhost}->{$header};
          }

          when ("get-exported-headers")
          {
               my $vhost = $self->{action}->{vhost};

               if (not defined ($self->{conf}->{exportedHeaders}->{$vhost}))
               {
                    $self->setError ("$_: There is no virtual host '$vhost'\n");
                    return 0;
               }

               while (my ($header, $expr) = each %{$self->{conf}->{exportedHeaders}->{$vhost}})
               {
                    print "$header: '$expr'\n";
               }
          }

          ## virtual hosts

          when ("vhost-add")
          {
               my $vhost = $self->{action}->{vhost};

               if (defined ($self->{conf}->{vhostOptions}->{$vhost}) or defined ($self->{conf}->{locationRules}->{$vhost}) or defined ($self->{conf}->{exportedHeaders}->{$vhost}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": Virtual host '$vhost' already exist");
                    return 0;
               }

               $self->{conf}->{vhostOptions}->{$vhost} =
               {
                    vhostMaintenance => '0',
                    vhostPort => '-1',
                    vhostHttps => '-1'
               };
               $self->{conf}->{locationRules}->{$vhost} =
               {
                    default => "deny"
               };
               $self->{conf}->{exportedHeaders}->{$vhost} =
               {
                    "Auth-User" => "\$uid"
               };
          }

          when ("vhost-del")
          {
               my $vhost = $self->{action}->{vhost};
               my $error = "No virtual host in: ";
               my $nerror = 0;

               if (not defined ($self->{conf}->{vhostOptions}->{$vhost}))
               {
                    $nerror++;
                    $error .= "vhostOptions ";
               }
               else
               {
                    delete $self->{conf}->{vhostOptions}->{$vhost};
               }

               if (not defined ($self->{conf}->{locationRules}->{$vhost}))
               {
                    $nerror++;
                    $error .= "locationRules ";
               }
               else
               {
                    delete $self->{conf}->{locationRules}->{$vhost};
               }

               if (not defined ($self->{conf}->{exportedHeaders}->{$vhost}))
               {
                    $nerror++;
                    $error .= "exportedHeaders";
               }
               else
               {
                    delete $self->{conf}->{exportedHeaders}->{$vhost};
               }

               if ($nerror == 3)
               {
                    $error .= ". abortting...";
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": $error");
                    return 0;
               }
               elsif ($nerror != 0)
               {
                    $error .= ". ignoring...";
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": $error");
               }
          }

          when ("vhost-set-port")
          {
               my $vhost = $self->{action}->{vhost};
               my $port  = $self->{action}->{port};

               if (not defined ($self->{conf}->{vhostOptions}->{$vhost}))
               {
                    if (not defined ($self->{conf}->{locationRules}->{$vhost}) and not defined ($self->{conf}->{exportedHeaders}->{$vhost}))
                    {
                         $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no virtual host '$vhost'");
                         return 0;
                    }
                    else
                    {
                         $self->{conf}->{vhostOptions}->{$vhost} =
                         {
                              vhostPort => $port,
                              vhostHttps => '-1',
                              vhostMaintenance => '0'
                         };
                    }
               }
               else
               {
                    $self->{conf}->{vhostOptions}->{$vhost}->{vhostPort} = $port;
               }
          }

          when ("vhost-set-https")
          {
               my $vhost = $self->{action}->{vhost};
               my $https = $self->{action}->{https};

               if (not defined ($self->{conf}->{vhostOptions}->{$vhost}))
               {
                    if (not defined ($self->{conf}->{locationRules}->{$vhost}) and not defined ($self->{conf}->{exportedHeaders}->{$vhost}))
                    {
                         $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no virtual host '$vhost'");
                         return 0;
                    }
                    else
                    {
                         $self->{conf}->{vhostOptions}->{$vhost} =
                         {
                              vhostPort => '-1',
                              vhostHttps => $https,
                              vhostMaintenance => '0'
                         };
                    }
               }
               else
               {
                    $self->{conf}->{vhostOptions}->{$vhost}->{vhostHttps} = $https;
               }
          }

          when ("vhost-set-maintenance")
          {
               my $vhost = $self->{action}->{vhost};
               my $off   = $self->{action}->{off};

               if (not defined ($self->{conf}->{vhostOptions}->{$vhost}))
               {
                    if (not defined ($self->{conf}->{locationRules}->{$vhost}) and not defined ($self->{conf}->{exportedHeaders}->{$vhost}))
                    {
                         $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no virtual host '$vhost'");
                         return 0;
                    }
                    else
                    {
                         $self->{conf}->{vhostOptions}->{$vhost} =
                         {
                              vhostPort => '-1',
                              vhostHttps => '-1',
                              vhostMaintenance => $off
                         };
                    }
               }
               else
               {
                    $self->{conf}->{vhostOptions}->{$vhost}->{vhostMaintenance} = $off;
               }
          }

          when ("vhost-list")
          {
               while (my ($vhost, $vhostoptions) = each %{$self->{conf}->{vhostOptions}})
               {
                    print "- $vhost => ";
                    print "Maintenance: $vhostoptions->{vhostMaintenance} | ";
                    print "Port: $vhostoptions->{vhostPort} | ";
                    print "HTTPS: $vhostoptions->{vhostHttps}\n";
               }
          }

          ## global storage

          when ("global-storage")
          {
               print "Global Storage options :\n";
               print "- Directory: $self->{conf}->{globalStorageOptions}->{Directory}\n";
               print "- Lock Directory: $self->{conf}->{globalStorageOptions}->{LockDirectory}\n";
          }

          when ("global-storage-set-dir")
          {
               my $path = $self->{action}->{path};

               $self->{conf}->{globalStorageOptions}->{Directory} = $path;
          }

          when ("global-storage-set-lockdir")
          {
               my $path = $self->{action}->{path};

               $self->{conf}->{globalStorageOptions}->{LockDirectory} = $path;
          }

          when ("reload-urls")
          {
               while (my ($vhost, $url) = each %{$self->{conf}->{reloadUrls}})
               {
                    print "- $vhost => $url\n";
               }
          }

          when ("reload-url-add")
          {
               my $vhost = $self->{action}->{vhost};
               my $url   = $self->{action}->{url};

               $self->{conf}->{reloadUrls}->{$vhost} = $url;
          }

          when ("reload-url-del")
          {
               my $vhost = $self->{action}->{vhost};

               if (not defined ($self->{conf}->{reloadUrls}->{$vhost}))
               {
                    $self->setError ("$_: ".$ERRORS->{CONFIG_WRITE_ERROR}.": There is no reload URLs setted for '$vhost'");
                    return 1;
               }

               delete $self->{conf}->{reloadUrls}->{$vhost};
          }

          # no implementation found
          default
          {
               $self->setError ("$_: ".$ERRORS->{NOT_IMPLEMENTED});
               return 0;
          }
     }

     return 1;
}

## @method void setError (string str)
# Set error message
#
# @param str Text of the error
sub setError
{
     my ($self, $msg) = @_;

     $self->{errormsg} = $msg;
}

## @method string getError ()
# Get error message
#
# @return Text of the error
sub getError
{
     my ($self) = @_;

     my $msg = $self->{errormsg};

     return $msg;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Cli - Command Line Interface to edit LemonLDAP::NG configuration.

=head1 SYNOPSIS

  use Lemonldap::NG::Cli;
  
  my $app = Lemonldap::NG::Cli->new ();
  my $ret = $app->run (\@ARGV);
  exit ($ret);

=head1 DESCRIPTION

Lemonldap::NG::Cli allow user to edit the configuration of Lemonldap::NG via the
command line.

=head1 SEE ALSO

L<Lemonldap::NG>, L<Lemonldap::NG::Common::Conf>

=head1 AUTHOR

David Delassus E<lt>david.jose.delassus@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, by David Delassus

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
