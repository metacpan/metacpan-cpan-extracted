# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::FTPSync;
use strict;
use warnings;

use 5.008000;

use Net::FTP;

our $VERSION = 0.995;

sub new {
    my ($class, $url, $localdir, $mode, $filetype) = @_;

    if($mode ne "copy" && $mode ne "move") {
        return;
    }
    if(!defined($filetype)) {
        $filetype = "";
    }

    my ($user, $pass, $server, $dir);
    if($url =~ /ftp\:\/\/(.*)\:(.*)\@([^\/]*)(.*)/o) {
        ($user, $pass, $server, $dir) = ($1, $2, $3, $4);
    } else {
        return;
    }

    my $ftp = Net::FTP->new($server, Debug => 0, Timeout => 10, Passive => 0)
        or return;
        #or croak "Cannot connect to $server: $@";

    $ftp->login($user, $pass)
        or return;
        #or croak "Cannot login ", $ftp->message;

    $ftp->cwd($dir)
        or return;
        #or croak "Cannot change working directory ", $ftp->message;

    $ftp->ascii()
        or return;
        #or croak "Cannot change to ASCII ", $ftp->message;

    my %config = (
        ftp        => $ftp,
        localdir=> $localdir,
        mode    => $mode,
        type    => $filetype,
    );

    my $self = bless \%config, $class;
    return $self;
}

sub toLocal {
    my ($self) = @_;

    my @files = $self->{ftp}->ls;
    my $type = $self->{type};

    foreach my $fname (@files) {
        next if($fname eq "." || $fname eq "..");
        next if($type ne "" && $fname !~ /\.$type$/);
        my $locname = $self->{localdir} . "/" . $fname;
        my $lfname = $self->{ftp}->get($fname, $locname);
        if(!defined($lfname)) {
            return 0;
        }
        if($self->{mode} eq "move") {
            $self->{ftp}->delete($fname);
        }
    }
    return 1;
}
        
sub toRemote {
    my ($self) = @_;

    my $globname = $self->{localdir} . "/*";
    if($self->{type} ne "") {
        $globname .= "." . $self->{type};
    }

    my @files = glob($globname);

    foreach my $fname (@files) {
        next if($fname eq "." || $fname eq "..");
        next if(!-f $fname);
        my $remotename = $fname;
        $remotename =~ s/^.*\///go;
        
        my $lfname = $self->{ftp}->put($fname, $remotename);
        if(!defined($lfname)) {
            return 0;
        }
        if($self->{mode} eq "move") {
            unlink $fname;
        }
    }
    return 1;
}

sub quit {
    my ($self) = @_;

    if($self->{ftp}) {
        $self->{ftp}->quit;
        delete $self->{ftp};
    }

    return;
}

sub DESTROY {
    my ($self) = @_;

    $self->quit;

    return;
}


1;

=head1 NAME

Maplat::Helpers::FTPSync - Sync files with a remote (ftp) server

=head1 SYNOPSIS

  use Maplat::Helpers::FTPSync;
  
  my $ftp = Maplat::Helpers::FTPSync($url, $localdir, $mode, $filetype);

=head1 DESCRIPTION

Copies or moves files from an FTP URL to a local dir (or the other way around).

=head2 new

Create a new instance. Takes 4 arguments: The FTP Url (including username+password), the local
directory, the mode ("copy" or "move") and the filetype.

The filetype is the case sensitive filenyme ending withour the dot, for example "bmp" or "xml".

=head2 toLocal

Copy or move the files from the FTP server to the local directory.

=head2 toRemote

Copy or move the files from the local directory to the FTP server.

=head2 quit

Close connection

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
