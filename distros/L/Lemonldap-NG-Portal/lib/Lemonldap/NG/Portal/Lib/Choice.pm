package Lemonldap::NG::Portal::Lib::Choice;

use strict;
use Mouse;
use Safe;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  URIRE
);

extends 'Lemonldap::NG::Portal::Lib::Wrapper';
with 'Lemonldap::NG::Portal::Lib::OverConf';

our $VERSION = '2.22.0';

has modules    => ( is => 'rw', default => sub { {} } );
has rules      => ( is => 'rw', default => sub { {} } );
has type       => ( is => 'rw' );
has catch      => ( is => 'rw', default => sub { {} } );
has sessionKey => ( is => 'ro', default => '_choice' );

my $_choiceRules;
my $_disabledModules = {};

# INITIALIZATION

# init() must be called by module::init() with a number:
#  - 0 for auth
#  - 1 for userDB
#  - 2 for passwordDB
sub init {
    my ( $self, $type ) = @_;
    $self->type($type);

    unless ( $self->conf->{authChoiceModules}
        and %{ $self->conf->{authChoiceModules} } )
    {
        $self->error("'authChoiceModules' is empty");
        return 0;
    }

    foreach my $name ( keys %{ $self->conf->{authChoiceModules} } ) {
        my @mods =
          split( /;\s*/, $self->conf->{authChoiceModules}->{$name} );
        my $module = '::'
          . [ 'Auth', 'UserDB', 'Password' ]->[$type] . '::'
          . $mods[$type];
        my $over;
        if ( $mods[5] ) {
            eval { $over = JSON::from_json( $mods[5] ) };
            if ($@) {
                $self->logger->error("Bad over value ($@), skipped");
            }
        }
        if ( $module = $self->loadModule( $module, $over ) ) {
            $self->modules->{$name} = $module;
            $self->logger->debug(
                [qw(Authentication User Password)]->[$type]
                  . " module $name selected" );
        }
        else {
            $_disabledModules->{$name}->{$type} = 1;
            $self->logger->error( "Choice: unable to load $name ("
                  . [ 'Auth', 'UserDB', 'Password' ]->[$type]
                  . "), disabling it: "
                  . $self->error );
            $self->error('');
        }

        # Test if auth module wants to catch some path
        unless ($type) {
            if ( $module->can('catch') ) {
                $self->catch->{$name} = $module->catch;
            }
        }

        # Display conditions
        my $cond = $mods[4];
        if ( defined $cond and $cond ne "" ) {    # 0 is a valid rule!
            my $rule =
              $self->p->buildRule( $cond, "Choice condition for $name" );
            return 0 unless $rule;
            $_choiceRules->{$name} = $rule;
        }
        else {
            $self->logger->debug("No rule for $name");
            $_choiceRules->{$name} = sub { 1 };
        }
    }
    unless ( keys %{ $self->modules } ) {
        $self->error('Choice: no available module found, aborting');
        return 0;
    }
    return 1;
}

# RUNNING METHODS

sub checkChoice {
    my ( $self, $req ) = @_;
    my ( $name, $how ) = $self->_getChoiceFromReq($req);

    return 0 unless ($name);
    $self->logger->debug("Choice $name selected from $how");

    unless ( defined $self->modules->{$name} ) {
        $self->logger->error("Unknown choice '$name'");
        return 0;
    }

    unless ( $req->data->{findUserChoice} ) {

        # Store choice if module loops
        $req->pdata->{_choice}       = $name;
        $req->data->{_authChoice}    = $name;
        $req->sessionInfo->{_choice} = $name;
        $self->p->_authentication->authnLevel("${name}AuthnLevel");
    }

    return $name if ( $req->data->{ "enabledMods" . $self->type } );
    $req->data->{ "enabledMods" . $self->type } =
      [ $self->modules->{$name} ];
    return $name;
}

sub _getChoiceFromReq {
    my ( $self, $req ) = @_;

    # Check Choice from pdata
    if ( defined $req->pdata->{_choice} ) {
        return ( $req->pdata->{_choice}, "pdata" );
    }
    elsif (( defined $req->data->{_authChoice} )
        or ( defined $req->data->{_choice} ) )
    {
        my $name = $req->data->{_authChoice} || $req->data->{_choice};
        return ( $name, "req->data" );
    }

    # Check with catch method
    foreach ( keys %{ $self->catch } ) {
        if ( $req->path_info =~ $self->catch->{$_} ) {
            return ( $_, "caught path " . $req->path_info );
        }
    }

    # Set by OAuth Resource Owner grant // RESTServer pwdCheck
    if ( $req->data->{_pwdCheck} and $self->{conf}->{authChoiceAuthBasic} ) {
        return ( $self->{conf}->{authChoiceAuthBasic}, "basic auth context" );
    }

    if ( $req->data->{findUserChoice} ) {
        return ( $req->data->{findUserChoice}, "findUser" );
    }

    if ( $req->parameters->get( $self->conf->{authChoiceParam} ) ) {
        return ( $req->parameters->get( $self->conf->{authChoiceParam} ),
            "param" );
    }

    # Use the choice from current session unless we are doing an upgrade
    # in which case the user should be offered to choose again
    unless ( $req->data->{discardChoiceForCurrentSession} ) {
        if ( $req->userData->{_choice} ) {
            return ( $req->userData->{_choice}, "userData" );
        }
        if ( $req->sessionInfo->{_choice} ) {
            return ( $req->sessionInfo->{_choice}, "sessionInfo" );
        }
    }

    if ( $self->conf->{authChoiceSelectOnly} ) {
        my @allowed_choices = grep { $self->_evaluateRule( $req, $_ ) }
          keys %{ $self->conf->{authChoiceModules} };
        if ( @allowed_choices == 1 ) {
            return ( $allowed_choices[0], "only available" );
        }
    }

    # Try hook
    my $context = {};
    my $h       = $self->p->processHook( $req, 'getAuthChoice', $context );
    return 0 if ( $h != PE_OK );
    if ( $h == PE_OK and $context->{choice} ) {
        return ( $context->{choice}, "hook" );
    }

    return 0;
}

sub name {
    my ( $self, $req, $type ) = @_;
    unless ($req) {
        return 'Choice';
    }

    my $module = $req->data->{ "enabledMods" . $self->type }->[0];
    if ( my $sub = eval { $module->can('name') } ) {
        return $sub->($module, $req, $type );
    }
    else {
        my $n = ref($module);
        $n =~ s/^Lemonldap::NG::Portal::(?:(?:UserDB|Auth)::)?//;
        return $n;
    }
}

package Lemonldap::NG::Portal::Main;

# Build authentication loop displayed in template
# Return authLoop array reference
sub _buildAuthLoop {
    my ( $self, $req ) = @_;
    my @authLoop;

    # Test authentication choices
    unless ( ref $self->conf->{authChoiceModules} eq 'HASH' ) {
        $self->logger->warn("No authentication choices defined");
        return [];
    }

    foreach ( sort keys %{ $self->conf->{authChoiceModules} } ) {

        my $name = $_;

        # Name can have a digit as first character
        # for sorting purpose
        # Remove it in displayed name
        $name =~ s/^(\d*)?(\s*)?//;

        # Replace also _ by space for a nice display
        $name =~ s/\_/ /g;

        # Find modules associated to authChoice
        my ( $auth, $userDB, $passwordDB, $url, $condition ) =
          split( /;\s*/, $self->conf->{authChoiceModules}->{$_} );

        unless ( $self->_evaluateRule( $req, $_ ) ) {
            $self->logger->debug(
                    "Condition returns false, authentication choice $_"
                  . " will not be displayed" );
        }
        else {
            if (    $auth
                and not $_disabledModules->{$_}->{0}
                and $userDB
                and not $_disabledModules->{$_}->{1}
                and $passwordDB
                and not $_disabledModules->{$_}->{2} )
            {
                $self->logger->debug("Displaying authentication choice $_");

                # Default URL
                $req->data->{cspFormAction} ||= {};
                if ( defined $url and $url =~ URIRE ) {
                    my $csp_uri = $self->cspGetHost($url);
                    $req->data->{cspFormAction}->{$csp_uri} = 1;
                }
                else {
                    $url .= '#';
                }
                $self->logger->debug("Use URL $url");

                eval {
                    my $mod = $self->_authentication->modules->{$_};
                    $mod->initDisplay($req) if $mod->can('initDisplay');
                };
                $self->logger->info(
                    "Unable to initialize choice $_ display: $@")
                  if $@;

                my $name_without_space = $name =~ s/^\s*//r;

                # Options to store in the loop
                my $optionsLoop = {
                    name                       => $name,
                    key                        => $_,
                    module                     => $auth,
                    url                        => $url,
                    "name_$name_without_space" => 1,
                    "module_$auth"             => 1,
                    "key_$_"                   => 1,
                };

                # Get displayType for this module
                no strict 'refs';
                my $displayType = eval {
                    $self->_authentication->modules->{$_}
                      ->can('getDisplayType')->( $self, $req );
                } || 'logo';

                $self->logger->debug(
                    "Display type $displayType for module $auth");
                $optionsLoop->{$displayType} = 1;
                my $logo = $_;

                my $foundLogo = 0;

                # If displayType is logo, check if key.png is available
                if (  -e $self->conf->{templateDir}
                    . "/../htdocs/static/common/modules/"
                    . $logo
                    . ".png" )
                {
                    $optionsLoop->{logoFile} = $logo . ".png";
                    $foundLogo = 1;
                }
                else {
                    $optionsLoop->{logoFile} = $auth . ".png";
                }

                # Compatibility, with Custom, try the module name if
                # key was not found
                if ( $auth eq 'Custom' and not $foundLogo ) {
                    $logo =
                      ( ( $self->{conf}->{customAuth} || "" ) =~ /::(\w+)$/ )
                      [0];
                    if (
                        $logo
                        and ( -e $self->conf->{templateDir}
                            . "/../htdocs/static/common/modules/"
                            . $logo
                            . ".png" )
                      )
                    {
                        $optionsLoop->{logoFile} = $logo . ".png";
                    }
                }

                # If a choice has already been selected,
                # activate the corresponding form
                if ( $req->data->{_authChoice} ) {
                    $optionsLoop->{ACTIVE_FORM} =
                      ( $req->data->{_authChoice} eq $_ );

                }

                # if not, activate the first form in the list
                else {
                    $optionsLoop->{ACTIVE_FORM} = @authLoop ? 0 : 1;
                }

                # Register item in loop
                push @authLoop, $optionsLoop;

                $self->logger->debug(
                    "Authentication choice $name_without_space will be displayed");
            }
            else {
                $self->logger->debug(
"Authentication choice $_ is invalid and will not be displayed"
                );
                $req->error("Authentication choice $_ is invalid");
                next;
            }
        }

    }

    return \@authLoop;

}

sub _evaluateRule {
    my ( $self, $req, $choice ) = @_;

    my $extraData = {};
    $extraData->{targetAuthnLevel} = $req->pdata->{targetAuthnLevel}
      if defined $req->pdata->{targetAuthnLevel};
    unless ( $_choiceRules->{$choice} ) {
        $self->logger->error("$choice has no rule");
        $_choiceRules->{$choice} = sub { 1 };
    }
    return $_choiceRules->{$_}->( $req, $extraData );
}

1;

