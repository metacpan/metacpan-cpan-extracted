# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::LogoCache;
use strict;
use warnings;
use 5.010;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::FileSlurp qw(slurpBinFile);

our $VERSION = 0.995;


use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    $self->{lastUpdate} = "19700101";
    if(!defined($self->{EXTRAINC})) {
        my @tmp;
        $self->{EXTRAINC} = \@tmp;
    }
           
    return $self;
}

sub reload {
    my ($self) = shift;
    delete $self->{cache} if defined $self->{cache};

    my %files;
    
    my @dirs;
    foreach my $bdir (@INC, @{$self->{EXTRAINC}}) {
        if($bdir ne ".") {
            my $fname = $bdir . "/" . $self->{imgpath};
            next if($fname ~~ @dirs);
            if(-d $fname) {
                push @dirs, $fname;
            }
        }
    }
    {
        my $fname = './' . $self->{imgpath};
        if(-d $fname) {
            push @dirs, $fname;
        }
    }
    

    foreach my $bdir (@dirs) {
        print "    Reading files in $bdir...\n";
        opendir(my $dfh, $bdir) or croak($!);
        while((my $fname = readdir($dfh))) {
            next if($fname =~ /^\./);
            if($fname =~ /(.*)\.([a-zA-Z0-9]*)/) {
                my ($kname, $type) = ($1, $2);
                given($type) {
                    when(/jpg/i) {
                        $type = "image/jpeg";
                    }
                    when(/bmp/i) {
                        $type = "image/bitmap";
                    }
                    when(/htm/i) {
                        $type = "text/html";
                    }
                    when(/css/i) {
                        $type = "text/css";
                    }
                    when(/js/i) {
                        $type = "application/javascript";
                    }
                }
                
                my $nfname = $bdir . "/" . $fname;
                my $data = slurpBinFile($nfname);
        
                my %entry = (name   => $kname,
                            fullname=> $nfname,
                            type    => $type,
                            data    => $data,
                            );
                $files{$self->{imgwebpath} . $fname} = \%entry; # Store under full name
            } else {
                croak("Filename $fname has no extension");
            }
        }
        closedir($dfh);
    }
    $self->{cache} = \%files;
    
    $self->reloadTemplates();
    return;
}

sub register {
    my $self = shift;
    
    $self->register_webpath($self->{webpath}, "get");
    $self->register_webpath($self->{imgwebpath}, "get");
    $self->register_defaultwebdata("get_defaultwebdata");
    return;
}

sub get {
    my ($self, $cgi) = @_;
    
    my $name = $cgi->path_info();
    
    if($name eq $self->{webpath}) {
        return $self->getDescription;
    }
    
    return (status  =>  404) unless defined($self->{cache}->{$name});
    return (status          =>  200,
            type            => $self->{cache}->{$name}->{type},
            data            => $self->{cache}->{$name}->{data},
            expires         => $self->{expires},
            cache_control   =>  $self->{cache_control},
            );
}

sub getDescription {
    my ($self) = @_;
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{pagetitle},
        webpath        =>  $self->{webpath},
        LogoDayText =>  $self->{description},
    );
    
    my $template = $self->{server}->{modules}->{templates}->get("logoday", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_defaultwebdata {
    my ($self, $webdata) = @_;
    
    $self->reloadTemplates();
    
    my $view = $webdata->{userData}->{logoview} || 'logout';
    if(!defined($self->{$view})) {
        $view = "logout";
    }
    
    $webdata->{MainHeaderLogo} = $self->{$view};
    $webdata->{HasSpecialLogo} = $self->{$view . "_has_special"};
    return;
}

sub reloadSingleTemplate {
    my ($self, $tname) = @_;
    
    my @dirs;
    foreach my $bdir (@INC, @{$self->{EXTRAINC}}) {
        if($bdir ne ".") {
            my $fname = $bdir . "/" . $self->{layoutpath};
            next if($fname ~~ @dirs);
            if(-d $fname) {
                push @dirs, $fname;
            }
        }
    }
    {
        my $fname = './' . $self->{layoutpath};
        if(-d $fname) {
            push @dirs, $fname;
        }        
    }

    $self->{$tname . "_has_special"} = 0;
    
    foreach my $bdir (@dirs) {
        my $special = $bdir . "/" . $self->{lastUpdate} . "_" . $tname . ".tt";
        my $normal = $bdir . "/" . $tname . ".tt";
        
        if(-e $special) {
            $self->{$tname} = slurpBinFile($special);
            $self->{$tname . "_has_special"} = 1;
        } elsif(-e $normal && $self->{$tname . "_has_special"} == 0) {
            $self->{$tname} = slurpBinFile($normal);
            $self->{$tname . "_has_special"} = 0;
        }
    }
    return;
}

sub reloadDescription {
    my ($self) = @_;
    
    my @dirs;
    foreach my $bdir (@INC, @{$self->{EXTRAINC}}) {
        if($bdir ne ".") {
            my $fname = $bdir . "/" . $self->{layoutpath};
            next if($fname ~~ @dirs);
            if(-d $fname) {
                push @dirs, $fname;
            }
        }
    }
    {
        my $fname = './' . $self->{layoutpath};
        if(-d $fname) {
            push @dirs, $fname;
        }        
    }
    
    foreach my $bdir (@dirs) {
        my $special = $bdir . "/" . $self->{lastUpdate} . "_description.tt";
        
        if(-e $special) {
            $self->{description} = slurpBinFile($special);
        }
    }
    return;
}

sub reloadTemplates {
    my ($self) = @_;
    
    my $today = getShortFiledate;
    if(defined($self->{today})) {
        $today = $self->{today};
    }
    return if($today eq $self->{lastUpdate});
    
    $self->{lastUpdate} = $today;

    foreach my $logoview (@{$self->{views}->{view}}) {
        $self->reloadSingleTemplate($logoview->{logodisplay});
    }
    
    $self->reloadDescription();
    
    return;
}

1;
__END__

=head1 NAME

Maplat::Web::LogoCache - date-based logo display

=head1 SYNOPSIS

This module generates the logo bar in the default layout and provides the LogoDay functionality

=head1 DESCRIPTION

This module generates the logo bar for the default layout, depending on the view selected. It also provides
a LogoDay functionality, meaning it can display special logos on configured days (on this days, it also displays
an additional menu plus description page).

This module must be configured AFTER the Login module, because it hooks into its "Views" functionality.

=head1 Configuration

        <module>
                <modname>logo</modname>
                <pm>LogoCache</pm>
                <options>
                        <imgpath>MaplatWeb/Logo/Images</imgpath>
                        <layoutpath>MaplatWeb/Logo/layout</layoutpath>
                        <imgwebpath>/logo/pics/</imgwebpath>
                        <webpath>/user/special</webpath>
                        <pagetitle>LogoDay</pagetitle>
                        <cache_control>max-age=3600, must-revalidate</cache_control>
                        <expires>+1h</expires>

                        <!-- The <today> tag forces the module to assume the given date as
                                the basis for displaying the "Logo of the day" -->
                        <!--<today>20090918</today>-->

                        <views>
                                <view logodisplay="someview" />
                                <view logodisplay="otherview" />
                                <view logodisplay="differentview" />
                                <view logodisplay="admin" />
                                <view logodisplay="logout" />
                        </views>
                </options>
        </module>

=head2 get

Get Logo and descriptions.

=head2 getDescription

Return the rendered descriptions of LogoDays.

=head2 reloadSingleTemplate

Internal function - reload a single template file.

=head2 reloadTemplates

Internal function - dispatch reloads for all templates.

=head2 reloadDescription

Internal function - reload the description template.

=head1 Dependencies

This module depends on the Login module beeing already configured, because it hooks
into its "views" functionality

Maplat::Web::Login

=head1 SEE ALSO

Maplat::Web
Maplat::Web::Login

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
