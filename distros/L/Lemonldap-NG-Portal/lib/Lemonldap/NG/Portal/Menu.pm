##@file
# menu for lemonldap::ng portal

##@class
# menu class for lemonldap::ng portal
package Lemonldap::NG::Portal::Menu;

use strict;
use warnings;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LibAccess;
use base qw(Lemonldap::NG::Portal::_LibAccess);
use Clone qw(clone);

our $VERSION  = '1.4.0';
our $catlevel = 0;

## @method void menuInit()
# Prepare menu template elements
# @return nothing
sub menuInit {
    my $self = shift;
    $self->{apps}->{imgpath} ||= '/apps/';

    # Modules to display
    $self->{menuModules} ||= "Appslist ChangePassword LoginHistory Logout";
    $self->{menuDisplayModules} = $self->displayModules();

    # Extract password from POST data
    $self->{oldpassword}     = $self->param('oldpassword');
    $self->{newpassword}     = $self->param('newpassword');
    $self->{confirmpassword} = $self->param('confirmpassword');
    $self->{dn}              = $self->{sessionInfo}->{dn};
    $self->{user}            = $self->{sessionInfo}->{_user};

    # Try to change password
    $self->{menuError} =
      $self->_subProcess(
        qw(passwordDBInit modifyPassword passwordDBFinish sendPasswordMail))
      unless $self->{ignorePasswordChange};

    # Default menu error code
    $self->{menuError} = PE_PASSWORD_OK if ( $self->{passwordWasChanged} );
    $self->{menuError} ||= $self->{error};

    # Tab to display
    # Get the tab URL parameter
    $self->{menuDisplayTab} = $self->param("tab") || "none";

    # Default to appslist if invalid tab URL parameter
    $self->{menuDisplayTab} = "appslist"
      unless ( $self->{menuDisplayTab} =~ /^(password|logout|loginHistory)$/ );

    # Force password tab in case of password error
    $self->{menuDisplayTab} = "password"
      if (
        (
            scalar(
                grep { $_ == $self->{menuError} } (
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
      );

    # Application list for old templates
    if ( $self->{useOldMenuItems} ) {
        $self->{menuAppslistMenu} = $self->appslistMenu();
        $self->{menuAppslistDesc} = $self->appslistDescription();
    }

    return;
}

## @method arrayref displayModules()
# List modules that can be displayed in Menu
# @return modules list
sub displayModules {
    my $self           = shift;
    my $displayModules = [];

    # Modules list
    my @modules = split( /\s/, $self->{menuModules} );

    # Foreach module, eval condition
    # Store module in result if condition is valid
    foreach my $module (@modules) {
        my $cond = $self->{ 'portalDisplay' . $module };
        $cond = 1 unless defined $cond;

        $self->lmLog( "Evaluate condition $cond for module $module", 'debug' );

        if ( $self->safe->reval($cond) ) {
            my $moduleHash = { $module => 1 };
            $moduleHash->{'APPSLIST_LOOP'} = $self->appslist()
              if ( $module eq 'Appslist' );
            if ( $module eq 'LoginHistory' ) {
                $moduleHash->{'SUCCESS_LOGIN'} =
                  $self->mkSessionArray(
                    $self->{sessionInfo}->{loginHistory}->{successLogin},
                    "", 0, 0 );
                $moduleHash->{'FAILED_LOGIN'} =
                  $self->mkSessionArray(
                    $self->{sessionInfo}->{loginHistory}->{failedLogin},
                    "", 0, 1 );
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
    my ($self) = splice @_;
    my $appslist = [];

    return $appslist unless defined $self->{applicationList};

    # Reset level
    $catlevel = 0;

    my $applicationList = clone( $self->{applicationList} );
    my $filteredList    = $self->_filter($applicationList);
    push @$appslist, $self->_buildCategoryHash( "", $filteredList, $catlevel );

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
    my ( $self, $catid, $cathash, $catlevel ) = splice @_;
    my $catname = $cathash->{catname} || $catid;
    my $applications;
    my $categories;

    # Extract applications from hash
    my $apphash;
    foreach my $catkey ( sort keys %$cathash ) {
        next if $catkey =~ /(type|options|catname)/;
        if ( $cathash->{$catkey}->{type} eq "application" ) {
            $apphash->{$catkey} = $cathash->{$catkey};
        }
    }

    # Display applications first
    if ( scalar keys %$apphash > 0 ) {
        foreach my $appkey ( sort keys %$apphash ) {
            push @$applications,
              $self->_buildApplicationHash( $appkey, $apphash->{$appkey} );
        }
    }

    # Display subcategories
    foreach my $catkey ( sort keys %$cathash ) {
        next if $catkey =~ /(type|options|catname)/;
        if ( $cathash->{$catkey}->{type} eq "category" ) {
            push @$categories,
              $self->_buildCategoryHash( $catkey, $cathash->{$catkey},
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
    my ( $self, $appid, $apphash ) = splice @_;
    my $applications;

    # Get application items
    my $appname = $apphash->{options}->{name} || $appid;
    my $appuri  = $apphash->{options}->{uri}  || "";
    my $appdesc = $apphash->{options}->{description};
    my $applogo = $apphash->{options}->{logo};

    # Detect sub applications
    my $subapphash;
    foreach my $key ( sort keys %$apphash ) {
        next if $key =~ /(type|options|catname)/;
        if ( $apphash->{$key}->{type} eq "application" ) {
            $subapphash->{$key} = $apphash->{$key};
        }
    }

    # Display sub applications
    if ( scalar keys %$subapphash > 0 ) {
        foreach my $appkey ( sort keys %$subapphash ) {
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

## @method string appslistMenu()
# Returns HTML code for application list menu.
# @return HTML string
sub appslistMenu {
    my $self = shift;

    # We no more use XML file for menu configuration
    unless ( defined $self->{applicationList} ) {
        $self->abort(
            "XML menu configuration is deprecated",
"Please use lmMigrateConfFiles2ini to migrate your menu configuration"
        );
    }

    # Use configuration to get menu parameters
    my $applicationList = clone( $self->{applicationList} );
    my $filteredList    = $self->_filter($applicationList);

    return $self->_displayConfCategory( "", $filteredList, $catlevel );
}

## @method string appslistDescription()
# Returns HTML code for application description.
# @return HTML string
sub appslistDescription {
    my $self = shift;

    # We no more use XML file for menu configuration
    unless ( defined $self->{applicationList} ) {
        $self->lmLog(
"XML menu configuration is deprecated. Please use lmMigrateConfFiles2ini to migrate your menu configuration",
            'error'
        );
        return "&nbsp;";
    }

    # Use configuration to get menu parameters
    my $applicationList = clone( $self->{applicationList} );
    return $self->_displayConfDescription( "", $applicationList );
}

## @method string _displayConfCategory(string catname, hashref cathash, int catlevel)
# Creates and returns HTML code for a category.
# @param catname Category name
# @param cathash Hash of category elements
# @param catlevel Category level
# @return HTML string
sub _displayConfCategory {
    my ( $self, $catname, $cathash, $catlevel ) = splice @_;
    my $html;
    my $key;

    # Init HTML list
    $html .= "<ul class=\"category cat-level-$catlevel\">\n";
    $html .= "<li class=\"catname\">\n";
    $html .= "<span>$catname</span>\n" if $catname;

    # Increase category level
    $catlevel++;

    # Extract applications from hash
    my $apphash;
    foreach $key ( keys %$cathash ) {
        next if $key =~ /(type|options|catname)/;
        if (    $cathash->{$key}->{type}
            and $cathash->{$key}->{type} eq "application" )
        {
            $apphash->{$key} = $cathash->{$key};
        }
    }

    # display applications first
    if ( scalar keys %$apphash > 0 ) {
        $html .= "<ul>";
        foreach $key ( keys %$apphash ) {
            $html .= $self->_displayConfApplication( $key, $apphash->{$key} );
        }
        $html .= "</ul>";
    }

    # Display subcategories
    foreach $key ( keys %$cathash ) {
        next if $key =~ /(type|options|catname)/;
        if (    $cathash->{$key}->{type}
            and $cathash->{$key}->{type} eq "category" )
        {
            $html .=
              $self->_displayConfCategory( $key, $cathash->{$key}, $catlevel );
        }
    }

    # Close HTML list
    $html .= "</li>\n";
    $html .= "</ul>\n";

    return $html;
}

## @method private string _displayConfApplication(string appid, hashref apphash)
# Creates HTML code for an application.
# @param $appid Application ID
# @param $apphash Hash of application elements
# @return HTML string
sub _displayConfApplication {
    my $self = shift;
    my ( $appid, $apphash ) = @_;
    my $html;
    my $key;

    # Get application items
    my $appname = $apphash->{options}->{name} || $appid;
    my $appuri  = $apphash->{options}->{uri}  || "";

    # Display application
    $html .=
        "<li title=\"$appid\" class=\"appname $appid\"><span>"
      . ( $appuri ? "<a href=\"$appuri\">$appname</a>" : "<a>$appname</a>" )
      . "</span>\n";

    # Detect sub applications
    my $subapphash;
    foreach $key ( keys %$apphash ) {
        next if $key =~ /(type|options|catname)/;
        if ( $apphash->{$key}->{type} eq "application" ) {
            $subapphash->{$key} = $apphash->{$key};
        }
    }

    # Display sub applications
    if ( scalar keys %$subapphash > 0 ) {
        $html .= "<ul>";
        foreach $key ( keys %$subapphash ) {
            $html .=
              $self->_displayConfApplication( $key, $subapphash->{$key} );
        }
        $html .= "</ul>";
    }

    $html .= "</li>";
    return $html;
}

## @method private string _displayConfDescription(string appid, hashref apphash)
# Create HTML code for application description.
# @param $appid Application ID
# @param $apphash Hash
# @return HTML string
sub _displayConfDescription {
    my $self = shift;
    my ( $appid, $apphash ) = @_;
    my $html = "";
    my $key;

    if ( defined $apphash->{type} and $apphash->{type} eq "application" ) {

        # Get application items
        my $appname = $apphash->{options}->{name} || $appid;
        my $appuri  = $apphash->{options}->{uri}  || "";
        my $appdesc = $apphash->{options}->{description};
        my $applogofile = $apphash->{options}->{logo};
        my $applogo     = $self->{apps}->{imgpath} . $applogofile
          if $applogofile;

        # Display application description
        $html .= "<div id=\"$appid\" class=\"appsdesc\">\n";
        $html .=
"<a href=\"$appuri\"><img src=\"$applogo\" alt=\"$appid logo\" /></a>\n"
          if $applogofile;
        $html .= "<p class=\"appname\">$appname</p>\n" if defined $appname;
        $html .= "<p class=\"appdesc\">$appdesc</p>\n" if defined $appdesc;
        $html .= "</div>\n";
    }

    # Sublevels
    foreach $key ( keys %$apphash ) {
        next if $key =~ /(type|options|catname)/;
        $html .= $self->_displayConfDescription( $key, $apphash->{$key} );
    }

    return $html;
}

## @method private string _filter(hashref apphash)
# Duplicate hash reference
# Remove unauthorized menu elements
# Hide empty categories
# @param $apphash Menu elements
# @return filtered hash
sub _filter {
    my ( $self, $apphash ) = splice @_;
    my $filteredHash;
    my $key;

    # Copy hash reference into a new hash
    foreach $key ( keys %$apphash ) {
        $filteredHash->{$key} = $apphash->{$key};
    }

    # Filter hash
    $self->_filterHash($filteredHash);

    # Hide empty categories
    $self->_isCategoryEmpty($filteredHash);

    return $filteredHash;
}

## @method private string _filterHash(hashref apphash)
# Remove unauthorized menu elements
# @param $apphash Menu elements
# @return filtered hash
sub _filterHash {
    my $self = shift;
    my ($apphash) = @_;
    my $key;
    my $appkey;

    foreach $key ( keys %$apphash ) {
        next if $key =~ /(type|options|catname)/;
        if (    $apphash->{$key}->{type}
            and $apphash->{$key}->{type} eq "category" )
        {

            # Filter the category
            $self->_filterHash( $apphash->{$key} );
        }
        if (    $apphash->{$key}->{type}
            and $apphash->{$key}->{type} eq "application" )
        {

            # Find sub applications and filter them
            foreach $appkey ( keys %{ $apphash->{$key} } ) {
                next if $appkey =~ /(type|options|catname)/;

                # We have sub elements, so we filter them
                $self->_filterHash( $apphash->{$key} );
            }

            # Check rights
            my $appdisplay = $apphash->{$key}->{options}->{display}
              || "auto";
            my $appuri = $apphash->{$key}->{options}->{uri};

            # Remove if display is "no" or "off"
            delete $apphash->{$key} and next if ( $appdisplay =~ /^(no|off)$/ );

            # Keep node if display is "yes" or "on"
            next if ( $appdisplay =~ /^(yes|on)$/ );

            # Check grant function if display is "auto" (this is the default)
            delete $apphash->{$key} unless ( $self->_grant($appuri) );
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
        next if $key =~ /(type|options|catname)/;
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

        delete $apphash->{type};
        delete $apphash->{options};
        delete $apphash->{catname};

        if ( scalar( keys %$apphash ) ) {

            # There are sub categories or sub applications
            # Restore type and options
            $apphash->{type}    = "category";
            $apphash->{options} = $tmp_options;
            $apphash->{catname} = $tmp_catname;

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

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::Menu - Portal menu functions

=head1 SYNOPSIS

    use Lemonldap::NG::Portal::Simple;
    my $portal = Lemonldap::NG::Portal::Simple->new(
      {
      }
    );

    # Init portal menu
    $portal->menuInit();


=head1 DESCRIPTION

Lemonldap::NG::Portal::Menu is used to build menu.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2008, 2009, 2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2008, 2009, 2010, 2011, 2012, 2013 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut


