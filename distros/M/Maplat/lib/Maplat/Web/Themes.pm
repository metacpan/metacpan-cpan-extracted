# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::Themes;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::DBSerialize;

our $VERSION = 0.995;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    my @themes;
    foreach my $key (sort keys %{$self->{view}}) {
        my %theme = %{$self->{view}->{$key}};
        $theme{name} = $key;
        
        push @themes, \%theme;
    }
    $self->{Themes} = \@themes;
    
    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{webpath}, "get");
    $self->register_prerender("prerender");
    return;
}

sub get {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    my $seth = $self->{server}->{modules}->{$self->{usersettings}};
    
    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{pagetitle},
        webpath         =>  $self->{webpath},
        AvailThemes     =>  $self->{Themes},
    );    
    
    # We don't actually set the Theme into webdata here, this is done during the prerender stage.
    # Also, we don't handle the "select a default theme if non set" case, TemplateCache falls back to
    # its own default theme anyway
    my $mode = $cgi->param('mode') || 'view';
    if($mode eq "setvalue") {
        my $theme = $cgi->param('theme') || "";
        if($theme ne "") {
            my $templname = $cgi->param("template_$theme") || "";
            if($templname ne "") {
                $seth->set($webdata{userData}->{user}, "UserLayout", \$templname);
            }
        }
    }

    my $template = $self->{server}->{modules}->{templates}->get("themes", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub prerender {
    my ($self, $webdata) = @_;
    
    # Unless the user is logged in, we don't have set a user selected Theme
    return if(!defined($webdata->{userData}) ||
              !defined($webdata->{userData}->{user}) ||
              $webdata->{userData}->{user} eq "");
    
    my $seth = $self->{server}->{modules}->{$self->{usersettings}};
    my ($ok, $templname) = $seth->get($webdata->{userData}->{user}, "UserLayout");
    
    if(defined($templname)) {
        $templname = dbderef($templname);
    }
    if($ok && defined($templname) && $templname ne "") {
        # Now, we have to check if this theme is still available
        $ok = 0;
        foreach my $theme (@{$self->{Themes}}) {
            if($templname eq $theme->{template}) {
                $ok = 1;
                last;
            }
        }
        # If not OK, we just do nothing and let TemplateCache use its default Theme
        if($ok) {
            $webdata->{UserLayout} = $templname;
        }
    }

    return;
}

1;
__END__

=head1 NAME

Maplat::Web::Themes - add theming support to your project

=head1 SYNOPSIS

Add pre-configures themes to your Maplat project.

=head1 DESCRIPTION

This module overrides the layout template configured in the TemplateCache module. It also adds
a simple webmask, so each user can select his/her prefered theme.

Configuration is saved on a per-user basis through the usersettings-module. The default-theme is the first one
configured. This overrides the default layout configured in the TemplateCache module.

=head1 Configuration

    <module>
        <modname>themes</modname>
        <pm>Themes</pm>
        <options>
            <webpath>/settings/themes</webpath>
            <pagetitle>Themes</pagetitle>
            <usersettings>usersettings</usersettings>
            <view>
                <name>Classic</name>
                <template>magnalayout_classic</template>
                <screenshot>/pics/selectlayout_classic.png</screenshot>
                <description>The original. This is how this website is supposed to look! If you have problems, try using this theme before reporting a bug.</description>
            </view>
            <view>
                <name>Modern</name>
                <template>magnalayout_modern</template>
                <screenshot>/pics/selectlayout_modern.png</screenshot>
                <description>Similar in Look&amp;Feel to the new Intranet site.</description>
            </view>
            <view>
                <name>Typewriter</name>
                <template>magnalayout_typewriter</template>
                <screenshot>/pics/selectlayout_typewriter.png</screenshot>
                <description>Similar to classic, but with fixed width fonts and some other visual tweaks.</description>
            </view>
        </options>
    </module>

=head2 get

Provides the configuration webinterface.

=head2 prerender

This hooks into the TemplateCache module with the prerender callback. It overrides the
$webdata->{UserLayout} variable, forcing the TemplateCache module to use the Themes-configured
template as layout instead of its internal default.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::UserSettings as "usersettings"

=head1 SEE ALSO

Maplat::Web
Maplat::Web::UserSettings

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
