#
#===============================================================================
#
#         FILE: Cli.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 20.10.2018 20:39:31
#     REVISION: ---
#===============================================================================
package Mega::Cli;

use utf8;
use strict;
use warnings;
use File::Spec;
use Lock::Socket;
use File::Basename;
use Carp qw/carp croak/;

our $VERSION = '0.02';

my $MEGA_CMD = {
    'mega_login'    => 'mega-login',
    'mega_logout'   => 'mega-logout',
    'mega_mkdir'    => 'mega-mkdir',
    'mega_put'      => 'mega-put',
    'mega_get'      => 'mega-get',
    'mega_export'   => 'mega-export',

};

my $DEFAULT_PATH        = '/usr/bin';
my $DEFAULT_LOCK_PORT   = 40000;

sub new {
    my ($class, %opt) = @_;
    my $self = {};

    $self->{path}           = $opt{-path}           // $DEFAULT_PATH;
    $self->{lock_port}      = $opt{-lock_port}      // $DEFAULT_LOCK_PORT;

    $self->{lock} = Lock::Socket->new(port => $self->{lock_port});
    eval {
        $self->{lock}->lock;
    };
    if ($@) {
        croak "Can't lock port $self->{lock_port}";
    }

    # Check exists all ptrogramm
    for my $cmd (keys %$MEGA_CMD) {
        my $cmd_path = File::Spec->catfile($self->{path}, $MEGA_CMD->{$cmd});
        if (not -f $cmd_path) {
            croak "Command: '$MEGA_CMD->{$cmd}' not found in path: '$cmd_path'";
        }
    }

    bless $self, $class;
    return $self;
}


sub login {
    my ($self, %opt) = @_;
    $self->{login}          = $opt{-login}          // croak "You must specify '-login' param";
    $self->{password}       = $opt{-password}       // croak "You must specify '-password' param";

    $self->logout();

    my $cmd = File::Spec->catfile($self->{path}, $MEGA_CMD->{mega_login});
    my $login_res = `$cmd '$self->{login}' '$self->{password}'`;
    if ($login_res) {
        croak "Can't login to mega: $login_res";
    }
    return 1;
}

sub uploadFile {
    my ($self, %opt) = @_;
    my $local_file          = $opt{-local_file}       // croak "You must specify '-local_file' param";
    my $remote_file         = $opt{-remote_file}      // croak "You must specify '-remote_file' param";
    my $create_dir          = $opt{-create_dir};
    
    my $param = $create_dir ? '-c ' : '';

    my $cmd = File::Spec->catfile($self->{path}, $MEGA_CMD->{mega_put});
    my $res = `$cmd $param '$local_file' '$remote_file'`;

    if ($res) {
        croak "Can't upload file: '$local_file' to '$remote_file'. Error: $res";
    }
    return 1;
}

sub downloadFile {
    my ($self, %opt) = @_;
    my $local_file          = $opt{-local_file}       // croak "You must specify '-local_file' param";
    my $remote_file         = $opt{-remote_file}      // croak "You must specify '-remote_file' param";
    
    my $cmd = File::Spec->catfile($self->{path}, $MEGA_CMD->{mega_get});
    my $res = `$cmd '$remote_file' '$local_file'`;

    if ($res) {
        croak "Can't download file: '$remote_file' to '$local_file'. Error: $res";
    }
    return 1;
}

sub createDir {
    my ($self, %opt) = @_;
    my $dir            = $opt{-dir}             // croak "You must specify '-dir' param";

    my $cmd = File::Spec->catfile($self->{path}, $MEGA_CMD->{mega_mkdir});
    my $create_dir_res = `$cmd -p '$dir'`;
    if ($create_dir_res) {
        croak "Can't create folder: $dir. Error: $create_dir_res";
    }
    return 1;
}

sub shareResource {
    my ($self, %opt) = @_;
    $opt{-action}   = '-a';
    my $res = $self->__share(%opt);

    if ($res =~ /^Exported.+(https:\/\/.+)$/) {
        return $1;
    }
    croak "Can't share resource '$opt{-remote_resource}'. Error: $res";
}

sub unshareResource {
    my ($self, %opt) = @_;
    $opt{-action}   = '-d';
    my $res = $self->__share(%opt);

    if ($res =~ /^Disabled export/) {
        return 1;
    }
    croak "Can't unshare resource: '$opt{-remote_resource}'. Error: $res";
}

sub __share {
    my ($self, %opt)        = @_;
    my $remote_resource     = $opt{-remote_resource}    // croak "You must specify param '-remote_resource'";
    my $action              = $opt{-action};

    my $cmd = File::Spec->catfile($self->{path}, $MEGA_CMD->{mega_export});
    my $res = `$cmd $action -f '$remote_resource'`;

    return $res;
}

sub logout {
    my ($self) = @_;

    my $cmd = File::Spec->catfile($self->{path}, $MEGA_CMD->{mega_logout});
    `$cmd`;
    return 1;
}

sub DESTROY {
    my ($self) = @_;
    
    $self->logout;

    # Unlock port
    if ($self->{lock}) {
        $self->{lock}->unlock;
    }
}

1;

=encoding utf8

=head1 NAME

B<Mega::Cli> - simple wrapper for Mega.nz cli

=head1 VERSION

    version 0.01

=head1 SYNOPSIS

This module use to upload, download, share file from Mega account. Module work only exclusively
    use Mega::Cli;

    #Create mega object
    my $mega = Mega::Cli->new(
        -path       => '/usr/bin',
    );

    #Login to mega
    $mega->login(
        -login      => $mega_login,
        -password   => $mega_password,
    );

    #Upload file
    my $local_file = '/tmp/test_file.txt';
    my $remote_file = '/tmp/cloud/test_file.txt';
    $mega->uploadFile(
        -local_file         => $local_file,
        -remote_file        => $remote_file,
        -create_dir         => 1,
    );

    #Download file
    $mega->downloadFile(
            -local_file     => $local_file,
            -remote_file    => $remote_file,
    );

    #Share file
    my $share_link = $mega->shareResource($remote_file);


=head1 METHODS

=head2 new(%opt)

Create L<Mega::Cli> object

    %opt:
        -path       => Path to mega cmd (default: /usr/bin)
        -lock_port  => Port to exclusively lock (default: 50000)

=head2 login(%opt) 

Login to mega account. Return 1 if success, die in otherwise

    %opt:
        -login      => Login from mega.nz
        -password   => Password from mega.nz

=head2 logout()

Logout from mega account

=head2 uploadFile(%opt)

Upload file from local disk to mega cloud. Return 1 if success, die in otherwise

    %opt:
       -local_file          => Full path to source file on local disk
       -remote_file         => Full path to remote file on cloud 
       -create_dir          => Create dir on cloud if dir not exists (default: 0)

=head2 downloadFile(%opt)

Download file from mega cloud to local disk. Return 1 if success, die in otherwise

    %opt:
       -local_file          => Full path to source file on local disk
       -remote_file         => Full path to remote file on cloud 

=head2 createDir(%opt)

Create dir on mega cloud
    
    %opt:
        -dir                => Dir name to create on mega cloud

=head2 shareResource(%opt) 

Share resource (file/folder) and get url to download resource. Return share link if success, die in otherwise

    %opt:
        -remote_resource    => Full path to remote resource to share

=head2 unshareResource(%opt) 

Unshare resource (file/folder). Return 1 if success, die in otherwise

    %opt:
        -remote_resource    => Full path to remote resource to unshare

=head1 DEPENDENCE

L<File::Spec>, L<Lock::Socket>

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
