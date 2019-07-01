##@file
# menu for lemonldap::ng portal
package Lemonldap::NG::Portal::Main::Menu;

use strict;
use Mouse;
use Clone 'clone';

our $VERSION = '2.0.3';

extends 'Lemonldap::NG::Common::Module';

# PROPERTIES

has menuModules => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $conf = $_[0]->{conf};
        my @res;
        foreach (qw(Appslist ChangePassword LoginHistory OidcConsents Logout)) {
            my $cond = $conf->{"portalDisplay$_"} // 1;
            $_[0]->p->logger->debug("Evaluate condition $cond for module $_");
            my $tmp =
              $_[0]->{p}
              ->HANDLER->buildSub( $_[0]->{p}->HANDLER->substitute($cond) );
            push @res, [ $_, $tmp ] if ($tmp);
        }
        return \@res;
    }
);

has specific => ( is => 'rw', default => sub { {} } );

has imgPath => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        return $_[0]->{conf}->{impgPath}
          || $_[0]->{conf}->{staticPrefix} . '/logos';
    }
);

# INITIALIZATION

sub init {
    1;
}

# RUNNING METHODS

# Prepare menu template elements
# Returns hash (=list) containing :
#  - DISPLAY_MODULES
#  - DISPLAY_TAB
#  - AUTH_ERROR
#  - AUTH_ERROR_TYPE
sub params {
    my ( $self, $req ) = @_;
    $self->{conf}->{imgPath} ||= $self->{staticPrefix};
    my %res;
    my @defaultTabs = (qw/appslist password logout loginHistory oidcConsents/);
    my @customTabs = split( /,\s*/, $self->{conf}->{customMenuTabs} || '' );

    # Tab to display
    # Get the tab URL parameter

    # Force password tab in case of password error
    if (
        $req->menuError
        and scalar(
            grep { $_ == $req->menuError } (
                25,    #PE_PP_CHANGE_AFTER_RESET
                26,    #PE_PP_PASSWORD_MOD_NOT_ALLOWED
                27,    #PE_PP_MUST_SUPPLY_OLD_PASSWORD
                28,    #PE_PP_INSUFFICIENT_PASSWORD_QUALITY
                29,    #PE_PP_PASSWORD_TOO_SHORT
                30,    #PE_PP_PASSWORD_TOO_YOUNG
                31,    #PE_PP_PASSWORD_IN_HISTORY
                32,    #PE_PP_GRACE
                33,    #PE_PP_EXP_WARNING
                34,    #PE_PASSWORD_MISMATCH
                39,    #PE_BADOLDPASSWORD
                74,    #PE_MUST_SUPPLY_OLD_PASSWORD
            )
        )
      )
    {
        $res{DISPLAY_TAB} = "password";
    }

    # else calculate modules to display
    else {
        my $tab = $req->param("tab");
        if ( defined $tab
            and grep ( /^$tab$/, ( @defaultTabs, @customTabs ) ) )
        {
            $self->logger->debug( "Select menu tab "
                  . $req->param("tab")
                  . "from GET parameter" );
            $res{DISPLAY_TAB} = $req->param("tab");
        }
        else {
            $res{DISPLAY_TAB} = "appslist";
        }
    }

    $res{DISPLAY_MODULES} = $self->displayModules($req);
    $res{AUTH_ERROR_TYPE} =
      $req->error_type( $res{AUTH_ERROR} = $req->menuError );

    # Display menu 2fRegisters link only if at least a 2F device is registered
    $res{sfaManager} =
      $self->p->_sfEngine->display2fRegisters( $req, $req->userData );
    $self->logger->debug("Display 2fRegisters link") if $res{sfaManager};

    return %res;
}

## @method arrayref displayModules()
# List modules that can be displayed in Menu
# @return modules list
sub displayModules {
    my ( $self, $req ) = @_;
    my $displayModules = [];

    # Foreach module, eval condition
    # Store module in result if condition is valid
    foreach my $module ( @{ $self->menuModules } ) {
        $self->logger->debug("Check if $module->[0] has to be displayed");

        if ( $module->[1]->( $req, $req->sessionInfo ) ) {
            my $moduleHash = { $module->[0] => 1 };
            if ( $module->[0] eq 'Appslist' ) {
                $moduleHash->{'APPSLIST_LOOP'} = $self->appslist($req);
            }
            elsif ( $module->[0] eq 'LoginHistory' ) {
                $moduleHash->{'SUCCESS_LOGIN'} =
                  $self->p->mkSessionArray( $req,
                    $req->{sessionInfo}->{_loginHistory}->{successLogin},
                    "", 0, 0 );
                $moduleHash->{'FAILED_LOGIN'} =
                  $self->p->mkSessionArray( $req,
                    $req->{sessionInfo}->{_loginHistory}->{failedLogin},
                    "", 0, 1 );
            }
            elsif ( $module->[0] eq 'OidcConsents' ) {
                $moduleHash->{'OIDC_CONSENTS'} =
                  $self->p->mkOidcConsent( $req, $req->sessionInfo );
            }
            push @$displayModules, $moduleHash;
        }
    }

    return $displayModules;
}

## @method arrayref appslist()
# Returns categories and applications list as HTML::Template loop
# @return categories and applications list
sub appslist {
    my ( $self, $req ) = @_;
    my $appslist = [];

    return $appslist unless defined $self->conf->{applicationList};

    # Reset level
    my $catlevel = 0;

    my $applicationList = clone( $self->conf->{applicationList} );
    my $filteredList = $self->_filter( $req, $applicationList );
    push @$appslist,
      $self->_buildCategoryHash( $req, "", $filteredList, $catlevel );

    # We must return an ARRAY ref
    return ( ref $appslist->[0]->{categories} eq "ARRAY" )
      ? $appslist->[0]->{categories}
      : [];
}

## @method private hashref _buildCategoryHash(string catname,hashref cathash, int catlevel)
# Build hash for a category
# @param catname Category name
# @param cathash Hash of category elements
# @param catlevel Category level
# @return Category Hash
sub _buildCategoryHash {
    my ( $self, $req, $catid, $cathash, $catlevel ) = @_;
    my $catname = $cathash->{catname} || $catid;
    my $applications;
    my $categories;

    # Extract applications from hash
    my $apphash;
    foreach my $catkey ( sort keys %$cathash ) {
        next if $catkey =~ /(type|options|catname|order)/;
        if ( $cathash->{$catkey}->{type} eq "application" ) {
            $apphash->{$catkey} = $cathash->{$catkey};
        }
    }

    # Display applications first
    if ( scalar keys %$apphash > 0 ) {
        foreach my $appkey (
            sort {
                ( $apphash->{$a}->{order} || 0 )
                  <=> ( $apphash->{$b}->{order} || 0 )
                  or $a cmp $b
            }
            keys %$apphash
          )
        {
            push @$applications,
              $self->_buildApplicationHash( $appkey, $apphash->{$appkey} );
        }
    }

    # Display subcategories
    foreach my $catkey (
        sort {
            ( $cathash->{$a}->{order} || 0 )
              <=> ( $cathash->{$b}->{order} || 0 )
              or $a cmp $b
        }
        grep { not /^(?:catname|type|options|order)$/ } keys %$cathash
      )
    {

        if ( $cathash->{$catkey}->{type} eq "category" ) {
            push @$categories,
              $self->_buildCategoryHash( $req, $catkey, $cathash->{$catkey},
                $catlevel + 1 );
        }
    }

    my $categoryHash = {
        category => 1,
        catname  => $catname,
        catid    => $catid,
        catlevel => $catlevel
    };
    $categoryHash->{applications} = $applications if $applications;
    $categoryHash->{categories}   = $categories   if $categories;
    return $categoryHash;
}

## @method private hashref _buildApplicationHash(string appid, hashref apphash)
# Build hash for an application
# @param $appid Application ID
# @param $apphash Hash of application elements
# @return Application Hash
sub _buildApplicationHash {
    my ( $self, $appid, $apphash ) = @_;
    my $applications;

    # Get application items
    my $appname = $apphash->{options}->{name} || $appid;
    my $appuri  = $apphash->{options}->{uri}  || "";
    my $appdesc = $apphash->{options}->{description};
    my $applogo = $apphash->{options}->{logo};

    # Detect sub applications
    my $subapphash;
    foreach my $key ( sort keys %$apphash ) {
        next if $key =~ /(type|options|catname|order)/;
        if ( $apphash->{$key}->{type} eq "application" ) {
            $subapphash->{$key} = $apphash->{$key};
        }
    }

    # Display sub applications
    if ( scalar keys %$subapphash > 0 ) {
        foreach my $appkey (
            sort {
                ( $subapphash->{$a}->{order} || 0 )
                  <=> ( $subapphash->{$b}->{order} || 0 )
                  or $a cmp $b
            }
            keys %$subapphash
          )
        {
            push @$applications,
              $self->_buildApplicationHash( $appkey, $subapphash->{$appkey} );
        }
    }

    my $applicationHash = {
        application => 1,
        appname     => $appname,
        appuri      => $appuri,
        appdesc     => $appdesc,
        applogo     => $applogo,
        appid       => $appid,
    };
    $applicationHash->{applications} = $applications if $applications;
    return $applicationHash;
}

## @method private string _filter(hashref apphash)
# Duplicate hash reference
# Remove unauthorized menu elements
# Hide empty categories
# @param $apphash Menu elements
# @return filtered hash
sub _filter {
    my ( $self, $req, $apphash ) = @_;
    my $filteredHash;
    my $key;

    # Copy hash reference into a new hash
    foreach $key ( keys %$apphash ) {
        $filteredHash->{$key} = $apphash->{$key};
    }

    # Filter hash
    $self->_filterHash( $req, $filteredHash );

    # Hide empty categories
    $self->_isCategoryEmpty($filteredHash);

    return $filteredHash;
}

## @method private string _filterHash(hashref apphash)
# Remove unauthorized menu elements
# @param $apphash Menu elements
# @return filtered hash
sub _filterHash {
    my ( $self, $req, $apphash ) = @_;

    foreach my $key ( keys %$apphash ) {
        next if $key =~ /(type|options|catname|order)/;
        if (    $apphash->{$key}->{type}
            and $apphash->{$key}->{type} eq "category" )
        {

            # Filter the category
            $self->_filterHash( $req, $apphash->{$key} );
        }
        if (    $apphash->{$key}->{type}
            and $apphash->{$key}->{type} eq "application" )
        {

            # Find sub applications and filter them
            foreach my $appkey ( keys %{ $apphash->{$key} } ) {
                next if $appkey =~ /(type|options|catname|order)/;

                # We have sub elements, so we filter them
                $self->_filterHash( $req, $apphash->{$key} );
            }

            # Check rights
            my $appdisplay = $apphash->{$key}->{options}->{display}
              || "auto";
            my ( $vhost, $appuri ) =
              $apphash->{$key}->{options}->{uri} =~ m#^https?://([^/]*)(.*)#;
            $vhost =~ s/:\d+$//;
            $vhost = $self->p->HANDLER->resolveAlias($vhost);
            $appuri ||= '/';

            # Remove if display is "no" or "off"
            delete $apphash->{$key} and next if ( $appdisplay =~ /^(no|off)$/ );

            # Keep node if display is "yes" or "on"
            next if ( $appdisplay =~ /^(yes|on)$/ );

            my $cond = undef;

            # Handle partner rules (SAML, CAS or OIDC)
            if ( $appdisplay =~ /^sp:\s*(.*)$/ ) {
                my $p = $1;
                if ( my $sub = $self->p->spRules->{$p} ) {
                    eval {
                        delete $apphash->{$key}
                          unless ( $sub->( $req, $req->sessionInfo ) );
                    };
                    if ($@) {
                        $self->logger->error("Partner rule $p returns: $@");
                    }
                }
                next;
            }

            # If a specific rule exists, get it from cache or compile it
            if ( $appdisplay !~ /^auto$/i ) {
                if ( $self->specific->{$key} ) {
                    $cond = $self->specific->{$key};
                }
                else {
                    $cond = $self->specific->{$key} =
                      $self->p->HANDLER->buildSub(
                        $self->p->HANDLER->substitute($appdisplay) );
                }
            }

            # Check grant function if display is "auto" (this is the default)
            delete $apphash->{$key}
              unless (
                $self->p->HANDLER->grant(
                    $req, $req->sessionInfo, $appuri, $cond, $vhost
                )
              );
            next;
        }
    }

}

## @method private void _isCategoryEmpty(hashref apphash)
# Check if a category is empty
# @param $apphash Menu elements
# @return boolean
sub _isCategoryEmpty {
    my $self = shift;
    my ($apphash) = @_;
    my $key;

    # Test sub categories
    foreach $key ( keys %$apphash ) {
        next if $key =~ /(type|options|catname|order)/;
        if (    $apphash->{$key}->{type}
            and $apphash->{$key}->{type} eq "category" )
        {
            delete $apphash->{$key}
              if $self->_isCategoryEmpty( $apphash->{$key} );
        }
    }

    # Test this category
    if ( $apphash->{type} and $apphash->{type} eq "category" ) {

        # Temporary store 'options'
        my $tmp_options = $apphash->{options};
        my $tmp_catname = $apphash->{catname};
        my $tmp_order   = $apphash->{order};

        delete $apphash->{type};
        delete $apphash->{options};
        delete $apphash->{catname};
        delete $apphash->{order};

        if ( scalar( keys %$apphash ) ) {

            # There are sub categories or sub applications
            # Restore type and options
            $apphash->{type}    = "category";
            $apphash->{options} = $tmp_options;
            $apphash->{catname} = $tmp_catname;
            $apphash->{order}   = $tmp_order;

            # Return false
            return 0;
        }
        else {

            # Return true
            return 1;
        }
    }
    return 0;
}

1;
