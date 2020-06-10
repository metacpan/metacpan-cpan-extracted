#########################################################################################
# Package       HiPi::Utils
# Description:  HiPi Utilities
# Copyright:    Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Utils;

# this package is retained to provide backwards compatibility with old module functions

#########################################################################################

use strict;
use warnings;
use Carp;
require Exporter;
use base qw( Exporter );
use XSLoader;
use HiPi qw( :rpi );
use HiPi::RaspberryPi;

our $VERSION ='0.81';

our $defaultuser = 'pi';

our @EXPORT_OK = qw(
    get_groups
    create_system_group
    create_user_group
    group_add_user
    group_remove_user
    cat_file
    echo_file
    home_directory
    is_windows
    is_unix
    is_raspberry
    is_mac
    is_raspberry_2
    is_raspberry_3
    uses_device_tree
    system_type
);
                    
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub is_raspberry { HiPi::RaspberryPi::is_raspberry; }
sub is_raspberry_2 { HiPi::RaspberryPi::is_raspberry; }
sub is_raspberry_3 { HiPi::RaspberryPi::is_raspberry_2; }
sub uses_device_tree { HiPi::RaspberryPi::has_device_tree; }
sub is_windows { HiPi::RaspberryPi::os_is_windows; }
sub is_mac { HiPi::RaspberryPi::os_is_osx; }
sub is_unix { HiPi::RaspberryPi::os_is_linux; }
sub home_directory { HiPi::RaspberryPi::home_directory; }
sub system_type { HiPi::RaspberryPi::has_device_tree; }

XSLoader::load('HiPi::Utils', $VERSION) if HiPi::is_raspberry_pi();

sub get_groups {
    my $rhash = {};
    return $rhash unless is_raspberry;
    setgrent();
    while( my ($name,$passwd,$gid,$members) = getgrent() ){
        $rhash->{$name} = {
            gid     => $gid,
            members => [  split(/\s/, $members)  ],
        }
    }
    endgrent();
    return $rhash;
}

sub create_system_group {
    my($gname, $gid) = @_;
    if( $gid ) {
        system(qq(groupadd -f -r -g $gid $gname)) and croak qq(Failed to create group $gname with gid $gid : $!);
    } else {
        system(qq(groupadd -f -r $gname)) and croak qq(Failed to create group $gname : $!);
    }
}

sub create_user_group {
    my($gname, $gid) = @_;
    if( $gid ) {
        system(qq(groupadd -f -g $gid $gname)) and croak qq(Failed to create group $gname with gid $gid : $!);
    } else {
        system(qq(groupadd -f $gname)) and croak qq(Failed to create group $gname : $!);
    }
}

sub group_add_user {
    my($gname, $uname) = @_;
    system(qq(gpasswd -a $uname $gname)) and croak qq(Failed to add user $uname to group $gname : $!);
}

sub group_remove_user {
    my($gname, $uname) = @_;
    system(qq(gpasswd -d $uname $gname)) and croak qq(Failed to remove user $uname from group $gname : $!);
}

sub cat_file {
    my $filepath = shift;
    return '' unless HiPi::is_raspberry_pi();
    my $rval = '';
    {
        local $ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
        $rval = qx(qq(/bin/cat $filepath));
        if($?) {
            croak qq(reading file $filepath failed : $!);
        }
    }
    return $rval;
}

sub echo_file {
    my ($msg, $filepath, $append) = @_;
    return 0 unless HiPi::is_raspberry_pi();
    my $redir = ( $append ) ? '>>' : '>';
    my $canwrite = 0;
    # croak now if filepath is a directory
    croak qq($filepath is a directory) if -d $filepath;
    
    # first check if file exists;
    if( -f $filepath ) {
        $canwrite = ( -w $filepath ) ? 1 : 0;
    } else {
        my $dir = $filepath;
        $dir =~ s/\/[^\/]+$//;
        unless( -d $dir ) {
            croak qq(Cannot write to $filepath. Directory does not exist);
        }
        $canwrite = ( -w $dir ) ? 1 : 0;
    }
    
    my $command = qq(/bin/echo \"$msg\" $append $filepath);
    {
        local $ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
        if( $canwrite ) {
            system($command) and croak qq(Failed to echo to $filepath : $!);
        } else {
            croak qq(Failed to echo to $filepath : $!);
        }
    }
    
}

sub parse_udev_rule {
    # exists only for old version compatibility
    # return a default set
    return { gpio => { active => 1, group => 'gpio' }, spi => { active => 1, group => 'spi' }, };
}

sub set_udev_rules {
    # exists only for old version compatibility
    
}

sub parse_modprobe_conf {
    # exists only for old version compatibility

    # return a default set
    return { spidev => { active => 1, bufsiz => 4096 }, i2c_bcm2708 => { active => 1, baudrate => 100000 }, };
    
}

sub set_modprobe_conf {
    # exists only for old version compatibility
}

sub drop_permissions_name {
    my($username, $groupname) = @_;
    
    return 0 unless HiPi::is_raspberry_pi();
    
    $username ||= getlogin();
    $username ||= $defaultuser;
    
    my($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = getpwnam($username);
    my $targetuid = $uid;
    my $targetgid = ( $groupname ) ? (getgrnam($groupname))[2] : $gid;
    if( $targetuid > 0 && $targetgid > 0 ) {
        drop_permissions_id($targetuid, $targetgid);
    } else {
        croak qq(Could not drop permissions to uid $targetuid, gid $targetgid);
    }
    unless( $> == $targetuid && $< == $targetuid && $) == $targetgid && $( == $targetgid) {
        croak qq(Could not set Perl permissions to uid $targetuid, gid $targetgid);
    }
}

sub drop_permissions_id {
    my($targetuid, $targetgid) = @_;
    _drop_permissions_id($targetuid, $targetgid);
    $> = $targetuid;
    $< = $targetuid;
    $) = $targetgid;
    $( = $targetgid;
}

sub generate_mac_address {
    my @bytes = ();
    for (my $i = 0; $i < 6; $i ++) {
        push @bytes, int(rand(256));
    }
    
    # make sure bit 0 (broadcast) of first byte is not set,
    # and bit 1 (local) is set.
    # i.e. via bitwise AND with 254 and bitwise OR with 2.
    
    $bytes[0] &= 254;
    $bytes[0] |= 2;
    
    return sprintf('%02x:%02x:%02x:%02x:%02x:%02x', @bytes);
}

1;

__END__
