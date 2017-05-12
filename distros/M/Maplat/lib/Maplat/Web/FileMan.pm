# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::FileMan;
use strict;
use warnings;

use 5.012;


use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::FileSlurp qw(slurpBinFile);
use File::Basename;

our $VERSION = 0.995;

use Carp;
use Readonly;
Readonly my $TESTRANGE => 1_000_000;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do

    return;
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{manage}->{webpath}, "get_manage");
    $self->register_webpath($self->{download}->{webpath}, "get_download");
    $self->register_webpath($self->{checkfname}->{webpath}, "get_fname");
    return;
}

sub get_list {
    my ($self, $basepath) = @_;
    
    my @files;
    
    my $dfh;
    if(!opendir($dfh, $basepath)) {
        return @files;
    }
    while((my $fname = readdir($dfh))) {
        next if($fname =~ /^\./);
        my $fullfname = $basepath . '/' . $fname;
        if(-f $fullfname) {
            push @files, $fname;
        }
    }
    closedir($dfh);
    @files = sort @files;
    return @files;
}

sub clean_fname {
    my ($self, $filename) = @_;
    
    my $safe_filename_characters = "a-zA-Z0-9_.-";
    $filename =~ s/\\/\//go;
    my ( $name, $path, $extension ) = fileparse ( $filename, '\..*' );  
    $filename = $name . $extension;
    $filename =~ tr/ /_/;
    $filename =~ s/[^$safe_filename_characters]//g;
    return $filename;
}

sub get_manage {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    
    my @files = $self->get_list($self->{basepath});
    
    # Delete files if required
    my $mode = $cgi->param('mode') || 'view';
    given($mode) {
        when("delete") {
            my @delfiles = $cgi->param('delfile');
            foreach my $delfile (@delfiles) {
                if($delfile ~~ @files) {
                    unlink $self->{basepath} . '/' . $delfile;
                }
            }
            @files = $self->get_list($self->{basepath});
        }
        
        when("upload") {    
            # Make filename safe(r)
            
            my $fh = $cgi->param("upfile");
            my $filename = $cgi->param("upfname");
            $filename = $self->clean_fname($filename);
            
            # Now, handle the upload data
            #my $fh = $cgi->upload("filename");
            if($fh) {
                my $ofh;
                if(open($ofh, ">", $self->{basepath} . '/' . $filename)) {
                    binmode $ofh;    
                    while((my $data = <$fh>)) {
                        print $ofh $data;
                    }
                    close $ofh;
                }
            }
            @files = $self->get_list($self->{basepath});
        }
    }
    
    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{manage}->{pagetitle},
        webpath         =>  $self->{manage}->{webpath},
        downwebpath     =>  $self->{download}->{webpath},
        checkfname      =>  $self->{checkfname}->{webpath},
        uncpath         =>  $self->{uncpath},
        AvailFiles  =>  \@files,
    );    
    
    my $template = $self->{server}->{modules}->{templates}->get("fileman", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_download {
    my ($self, $cgi) = @_;

    my @files = $self->get_list($self->{basepath});

    my $filename = $cgi->path_info();
    my $remove = $self->{download}->{webpath} . "/";
    $filename =~ s/^$remove//;
    
    if(!($filename ~~ @files)) {
        return (status  =>  404);
    }
    
    my $fullname = $self->{basepath} . '/' . $filename;
    if(!(-f $fullname)) {
        return (status  =>  404);
    }
    
    my $data = slurpBinFile($fullname);
    

    return (status  =>  404) unless defined($data);
    return (status  =>  200,
            type    => "application/octet-stream",
            "Content-Disposition" => "attachment; filename=\"$filename\";",
            data    => $data);
}

sub get_fname {
    my ($self, $cgi) = @_;
    
    my $filename = $cgi->param('fname') || '';
    $filename = $self->clean_fname($filename);
    
    return (status  =>  200,
            type    => "text/plain",
            data    => $filename);
}

1;
__END__

=head1 NAME

Maplat::Web::FileMan - simple web based filemanager

=head1 SYNOPSIS

Provides a simple filemanager for the web interface.

=head1 DESCRIPTION

This is a very simple up- and downloadmanager for the web interface. It's mostly used in conjunction with
the VNC module.

FileMan currently does not support subdirectories.

=head1 Configuration

    <module>
        <modname>vncfileman</modname>
        <pm>FileMan</pm>
        <options>
            <manage>
                <pagetitle>VNC FileManager</pagetitle>
                <webpath>/vnc/file/manage</webpath>
            </manage>
            <download>
                <webpath>/vnc/file/download</webpath>
            </download>
            <checkfname>
                <webpath>/vnc/file/checkfname</webpath>
            </checkfname>
            <basepath>/media/Fernwartung</basepath>
            <uncpath>\\10.176.45.17\Fernwartung</uncpath>
        </options>
    </module>


=head2 get_download

Provides the download capabilities.

=head2 get_list

Internal function, generates a list of downloadable files.

=head2 get_manage

Main FileMan web interface.

=head2 clean_fname

Internal function, clean up filenames to only allow certain "safe" characters.

=head2 get_fname

Returns a cleaned up filename (used from AJAX to provide the user feedback how to file will be named after upload).

=head1 SEE ALSO

Maplat::Web

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
