# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::RootFiles;
use strict;
use warnings;
use 5.012;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::FileSlurp qw(slurpBinFile);

our $VERSION = 0.995;


use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
        
    return $self;
}

sub reload {
    my ($self) = @_;
    
    # Can load files only once due to register(),
    # and we ain't doing it here
    
    return;
}

sub load_files {
    my ($self) = shift;

    # Empty cache
    my %files;
    $self->{cache} = \%files;  

    my $fcount = 0;

    my $extrabase = "";
    if($self->{path} =~ /Images/i) {
        $extrabase = "/Maplat/Web/Images";
    } elsif($self->{path} =~ /Static/i) {
        $extrabase = "/Maplat/Web/Static";
    }

    my @DIRS = reverse @INC;
    if(defined($self->{EXTRAINC})) {
        push @DIRS, @{$self->{EXTRAINC}};
    }

    foreach my $bdir (@DIRS) {
        next if($bdir eq ".");
        my $fulldir = $bdir . $extrabase;
        print "   ** checking $fulldir \n";
        if(-d $fulldir) {
            #print "   **** loading extra static files\n";
            $fcount += $self->load_dir($fulldir);
        }
    }

    if(-d $self->{path}) {
        $fcount += $self->load_dir($self->{path});
    } else {
        #print "   **** WARNING: configured dir " . $self->{path} . " does not exist!\n";
    }
    $fcount += 0; # Dummy for debug breakpoint
    return;

}

sub load_dir {
    my ($self, $basedir) = @_;

    my $fcount = 0;

    opendir(my $dfh, $basedir) or croak($!);
    while((my $fname = readdir($dfh))) {
        next if($fname =~ /^\./);
        my $nfname = $basedir . "/" . $fname;
        if(-d $nfname) {
            # Got ourself a directory, go recursive
            $fcount += $self->load_dir($nfname);
            next;
        }
        
        next if(!($fname ~~ @{$self->{rootfile}}));

        #print STDERR "Load $nfname\n";
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
                when(/txt/i) {
                    $type = "text/plain";
                }
                when(/css/i) {
                    $type = "text/css";
                }
                when(/js/i) {
                    $type = "application/javascript";
                }
                when(/ico/i) {
                    $type = "image/vnd.microsoft.icon";
                }
            }
            
            my $data = slurpBinFile($nfname);
            my %entry = (name   => $kname,
                        fullname=> $nfname,
                        type    => $type,
                        data    => $data,
                        );
            $self->{cache}->{'/' . $fname} = \%entry; # Store under full name
            $fcount++;
        }
    }
    closedir($dfh);
    return $fcount;
}

sub register {
    my $self = shift;
    
    $self->load_files;
    
    my $loginh = $self->{server}->{modules}->{$self->{login}};
    
    # Register every file on its own
    foreach my $url (keys %{$self->{cache}}) {
        $self->register_webpath($url, "get");
        $loginh->register_publicurl($url);
    }
    return;
}

sub get {
    my ($self, $cgi) = @_;
    
    my $name = $cgi->path_info();
    
    return (status  =>  404) unless defined($self->{cache}->{$name});
    return (status          =>  200,
            type            => $self->{cache}->{$name}->{type},
            data            => $self->{cache}->{$name}->{data},
            expires         => $self->{expires},
            cache_control   =>  $self->{cache_control},
            );
}

1;
__END__

=head1 NAME

Maplat::Web::RootFiles - provide static files to browser

=head1 SYNOPSIS

This module provides RAM caching of static files. This special module registers some defined
files directly in the root of the webpaths AND MARKS THEM PUBLIC.

=head1 DESCRIPTION

During the reload() calls, this modules recursively loads all files in the configured directory
into RAM and delivers them to the browser very fast.

It also sets chache_control and expires header to further reduce the load on the server. For multiple
base directories (for example images, sounds, ...) you can use this module multiple times.

All matching files are mapped directly to the root directory and marked public (circumventing the Login module).

This is only usefull for a very limited set of files like "favicon.ico" or "robots.txt". To make this work,
this module needs to be configured after the login module.

=head1 Configuration

        <module>
                <modname>rootfiles</modname>
                <pm>RootFiles</pm>
                <options>
                        <path>Maplat/Web/Static</path>
                        <cache_control>max-age=3600, must-revalidate</cache_control>
                        <expires>+1h</expires>
                        <rootfile>favicon.ico</rootfile>
                        <rootfile>robots.txt</rootfile>
                        <login>authentification</login>
                </options>
        </module>

=head2 get

Deliver the static, chached files.

=head2 load_files

Internal function.

=head2 load_dir

Internal function.

=head1 Dependencies

This module depends on the Maplat::Web::Login module already beein configured.

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
