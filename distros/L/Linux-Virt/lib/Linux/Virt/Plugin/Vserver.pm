package Linux::Virt::Plugin::Vserver;
{
  $Linux::Virt::Plugin::Vserver::VERSION = '0.15';
}
BEGIN {
  $Linux::Virt::Plugin::Vserver::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Linux-Vserver plugin for Linux::Virt

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Carp;
use English '-no_match_vars';
use File::Blarf;

extends 'Linux::Virt::Plugin';

sub _init_priority { return 10; }

# Check if this is a Vserver/VE
# undef - no vserver
# 1 - Linux-Vserver
sub is_vm {
    my $self = shift;

    # Linux-Vserver
    if ( open( my $FH, '<', "/proc/self/status" ) ) {
        local $/ = undef;
        my $proc = $FH;
        close($FH);
        if ( $proc =~ m/(s_context|VxID):\s+(\d+)/ ) {
            my $cid = $2;
            if ($cid) {

                # Ok, this is a Linux-Vserver
                return 1;
            }
        } ## end if ( $proc =~ m/(s_context|VxID):\s+(\d+)/)
    } ## end if ( open( my $FH, '<'...))

    # No Vserver
    return;
} ## end sub is_vm

# Check if this is a Linux-Vserver Host (i.e. running an vserver-enabled kernel)
# undef - no vserver
# 1 - Linux Vserver
sub is_host {
    my $self = shift;

    # Linux-Vserver
    if ( open( my $FH, '<', "/proc/self/status" ) ) {
        local $/ = undef;
        my $proc = <$FH>;
        close($FH);
        if ( $proc =~ m/(s_context|VxID):\s+(\d+)/ ) {
            my $cid = $2;
            if ( $cid && $cid == 0 ) {
                return 1;
            }
        } ## end if ( $proc =~ m/(s_context|VxID):\s+(\d+)/)
    } ## end if ( open( my $FH, '<'...))

    # No Vserver-enabled host
    return;
} ## end sub is_host

sub _get_arch_by_ctx {
    my $self = shift;
    my $ctx  = shift;

    my $ctx_file = "/proc/virtual/$ctx/nsproxy";
    if ( -f $ctx_file && open( my $FH, "<", $ctx_file ) ) {
        while ( my $line = <$FH> ) {
            if ( $line =~ m/^Machine:\s*(\S+)\s*$/ ) {
                my $arch = $1;
                close($FH);
                return $arch;
            }
        } ## end while ( my $line = <$FH> )
        close($FH);
    } ## end if ( -f $ctx_file && open...)
    return;
} ## end sub _get_arch_by_ctx

# We can't rely on the names reported by
# vserver-stat, they are often truncated,
# so we'll find the name by the (possible)
# dynamic context id in /etc/vserver/<vs>/run
sub _get_vs_name_by_ctx {
    my $self = shift;
    my $ctx  = shift;

    my $name = undef;

    my $basedir = "/etc/vservers";
    if ( opendir( my $DH, $basedir ) ) {
        while ( my $vs_name = readdir($DH) ) {
            my $entry = "$basedir/$vs_name";

            # skip non-dirs
            next if ( !-d $entry );

            # skip self and parent
            next if $entry =~ m/\.\.?/;
            my $ctx_file = "$entry/run";
            if ( -f $ctx_file ) {
                my $ctx_test = &File::Blarf::slurp( $ctx_file, { Chomp => 1, } );
                $ctx_test =~ s/^\s+//;
                $ctx_test =~ s/\s+$//;
                if ( $ctx eq $ctx_test ) {
                    closedir($DH);
                    return $vs_name;
                }
            } ## end if ( -f $ctx_file )
        } ## end while ( my $vs_name = readdir...)
        closedir($DH);
    } ## end if ( opendir( my $DH, ...))
    return;
} ## end sub _get_vs_name_by_ctx

sub vms {
    my $self        = shift;
    my $vserver_ref = shift;
    my $opts        = shift || {};
    local $ENV{LANG} = "C";
    my $VSS;
    if ( !open( $VSS, '-|', "/usr/sbin/vserver-stat" ) ) {
        my $msg = "Could not execute /usr/sbin/vserver-stat! Is util-vserver installed?: $!";
        $self->logger()->log( message => $msg, level => 'error', );
        return;
    }
    while ( my $line = <$VSS> ) {
        next if $line =~ m/^CTX\s+PROC\s+VSZ/;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        my ( $ctx, $proc, $vsz, $rss, $usertime, $systime, $uptime, $name ) = split( /\s+/, $line );
        $name = $self->_get_vs_name_by_ctx($ctx) || $name;
        $vserver_ref->{$name}{'ctx'}      = $ctx;
        $vserver_ref->{$name}{'proc'}     = $proc;
        $vserver_ref->{$name}{'vsz'}      = $vsz;
        $vserver_ref->{$name}{'rss'}      = $rss;
        $vserver_ref->{$name}{'usertime'} = $usertime;
        $vserver_ref->{$name}{'systime'}  = $systime;
        $vserver_ref->{$name}{'uptime'}   = $uptime;
        $vserver_ref->{$name}{'name'}     = $name;

    } ## end while ( my $line = <$VSS>)
    close($VSS);

    # post-process all vservers, gather remaining information
    # - get init status (apps/init/mark -> default?)
    # - get utsnodename
    # - get caps
    # - get limits
    # - get ips
    foreach my $name ( keys %{$vserver_ref} ) {

        # this is a linux-vserver
        $vserver_ref->{$name}{'virt'}{'type'} = 'vserver';

        # read arch from nsproxy
        $vserver_ref->{$name}{'virt'}{'arch'} = $self->_get_arch_by_ctx( $vserver_ref->{$name}{'ctx'} );

        # get vdir from /etc/vservers/<vs>/vdir symlink
        my $vdir = "/etc/vservers/$name/vdir";
        if ( -l $vdir ) {
            $vserver_ref->{$name}{'vdir'} = readlink($vdir);
        }

        # all spaces may be reported in GB or MB, so convert if needed
        # convert GB to MB
        foreach my $prop (qw(vsz rss)) {

            # remove trailing MB indicator
            $vserver_ref->{$name}{$prop} =~ s/m$//i;
            if ( $vserver_ref->{$name}{$prop} =~ m/g$/i ) {
                $vserver_ref->{$name}{$prop} =~ s/g$//i;
                $vserver_ref->{$name}{$prop} *= 1024;
            }
        } ## end foreach my $prop (qw(vsz rss))

        # all time are reported as XdYhZ or XhYmZ or XmYsZ
        # convert all to seconds
        foreach my $prop (qw(usertime systime uptime)) {
            my ( $day, $hour, $minute, $second, $ms );
            if ( $vserver_ref->{$name}{$prop} =~ m/^(\d+)d0?(\d+)h0?(\d+)$/i ) {
                ( $day, $hour, $minute, $second, $ms ) = ( $1, $2, $3, 0, 0 );
            }
            elsif ( $vserver_ref->{$name}{$prop} =~ m/^(\d+)h0?(\d+)m0?(\d+)$/i ) {
                ( $day, $hour, $minute, $second, $ms ) = ( 0, $1, $2, $3, 0 );
            }
            elsif ( $vserver_ref->{$name}{$prop} =~ m/^(\d+)m0?(\d+)s0?(\d+)$/i ) {
                ( $day, $hour, $minute, $second, $ms ) = ( 0, 0, $1, $2, $3 );
            }
            else {
                ( $day, $hour, $minute, $second, $ms ) = ( 0, 0, 0, 0, 0 );
            }
            $vserver_ref->{$name}{$prop} = $second + $minute * 60 + $hour * 60 * 60 + $day * 60 * 60 * 24;
        } ## end foreach my $prop (qw(usertime systime uptime))

        # - get init status (apps/init/mark -> default?)
        $vserver_ref->{$name}{'init'} = 0;
        my $init_file = "/etc/vservers/$name/apps/init/mark";
        if ( -e $init_file ) {
            if ( open( my $FH, "<", $init_file ) ) {
                my $mark = <$FH>;
                close($FH);
                chomp($mark);
                if ( $mark eq 'default' ) {
                    $vserver_ref->{$name}{'init'} = 1;
                }
            } ## end if ( open( my $FH, "<"...))
        } ## end if ( -e $init_file )

        # - get utsnodename
        $vserver_ref->{$name}{'utsnodename'} = $name;
        my $uts_nodename_file = "/etc/vservers/$name/uts/nodename";
        if ( -e $uts_nodename_file ) {
            if ( open( my $FH, "<", $uts_nodename_file ) ) {
                my $uts_nodename = <$FH>;
                close($FH);
                chomp($uts_nodename);
                $vserver_ref->{$name}{'utsnodename'} = $uts_nodename;
            } ## end if ( open( my $FH, "<"...))
        } ## end if ( -e $uts_nodename_file)

        # - get caps
        # see http://www.linux-vserver.org/Capabilities_and_Flags
        # and http://www.linux-vserver.org/util-vserver:Capabilities_and_Flags
        foreach my $cap_name (qw(ccapabilities flags nflags bcapabilities ncapabilities)) {
            $vserver_ref->{$name}{$cap_name} = undef;
            my $caps_file = "/etc/vservers/$name/$cap_name";
            if ( -e $caps_file ) {
                if ( open( my $FH, "<", $caps_file ) ) {
                    while ( my $cap = <$FH> ) {
                        chomp($cap);
                        $vserver_ref->{$name}{$cap_name}{$cap} = 1;
                    }
                    close($FH);
                } ## end if ( open( my $FH, "<"...))
            } ## end if ( -e $caps_file )
        } ## end foreach my $cap_name (qw(ccapabilities flags nflags bcapabilities ncapabilities))

        # - get limits
        my $limits_file = "/proc/virtual/" . $vserver_ref->{$name}{'ctx'} . "/limit";
        if ( -e $limits_file ) {
            if ( open( my $FH, "<", $limits_file ) ) {
                while ( my $line = <$FH> ) {
                    chomp($line);

                    # table header
                    next if $line =~ m/^Limit\s+/i;
                    my ( $res, $current, $min, $max, $soft, $hard, $hits ) = split( /[\s\/]+/, $line );

                    # remove trailing ':'
                    $res =~ s/:$//;

                    # remove trailing '/'
                    $min  =~ s#/$##;
                    $soft =~ s#/$##;

                    # skip resources w/o limit
                    next if ( $min == -1 && $max == -1 );

                    $vserver_ref->{$name}{'limits'}{$res}{'current'} = $current;
                    $vserver_ref->{$name}{'limits'}{$res}{'min'}     = $min;
                    $vserver_ref->{$name}{'limits'}{$res}{'max'}     = $max;
                    $vserver_ref->{$name}{'limits'}{$res}{'soft'}    = $soft;
                    $vserver_ref->{$name}{'limits'}{$res}{'hard'}    = $hard;
                    $vserver_ref->{$name}{'limits'}{$res}{'hits'}    = $hits;
                } ## end while ( my $line = <$FH> )
                close($FH);
            } ## end if ( open( my $FH, "<"...))
        } ## end if ( -e $limits_file )

        # - get ips
        # any interfaces defined at all?
        my $if_dir = '/etc/vservers/'.$name.'/interfaces';
        if ( -d $if_dir ) {
            if ( opendir( my $DH, $if_dir ) ) {
                while ( my $dir_entry = readdir($DH) ) {
                    next if $dir_entry =~ m/\.\.?/;
                    my $dir         = "$if_dir/$dir_entry";
                    my $ip_file     = "$dir/ip";
                    my $dev_file    = "$dir/dev";
                    my $prefix_file = "$dir/prefix";
                    my ( $ip, $dev, $prefix );
                    if ( -f $ip_file ) {
                        $ip = File::Blarf::slurp( $ip_file, { Chomp => 1, } );
                    }
                    if ( -f $dev_file ) {
                        $dev = File::Blarf::slurp( $dev_file, { Chomp => 1, } );
                    }
                    if ( -f $prefix_file ) {
                        $prefix = File::Blarf::slurp( $prefix_file, { Chomp => 1, } );
                    }
                    if ( $ip && $dev && $prefix ) {
                        my $key = $self->_get_ip_hash_key( $ip, $prefix, $dev );
                        $vserver_ref->{$name}{'ips'}{$key}{'ip'}     = $ip;
                        $vserver_ref->{$name}{'ips'}{$key}{'prefix'} = $prefix;
                        $vserver_ref->{$name}{'ips'}{$key}{'dev'}    = $dev;
                    } ## end if ( $ip && $dev && $prefix)
                } ## end while ( my $dir_entry = readdir...)
                closedir($DH);
            } ## end if ( opendir( my $DH, ...))
        } ## end if ( -d $if_dir )
    } ## end foreach my $name ( keys %{$vserver_ref...})

    return 1;
} ## end sub vms

sub _get_ip_hash_key {
    my $self   = shift;
    my $ip     = shift // '';
    my $prefix = shift // '';
    my $dev    = shift // '';

    return $ip . '/' . $prefix . 'dev' . $dev;
} ## end sub _get_ip_hash_key

sub is_running {
    my $self   = shift;
    my $vsname = shift;

    # remove domain part
    $vsname =~ s/\.[a-z0-9]$//i;

    my $vs_ref = {};

    $self->vms($vs_ref);

    if ( $vs_ref->{$vsname} ) {
        return 1;
    }
    else {
        return;
    }
} ## end sub is_running

sub start {
    my $self   = shift;
    my $vsname = shift;
    my $opts   = shift || {};

    my $cmd = "/usr/sbin/vserver $vsname start >/dev/null 2>&1";
    $self->sys()->run_cmd( $cmd, $opts );

    if ( !$self->is_running($vsname) ) {
        sleep(120);
    }

    return $self->is_running($vsname);
} ## end sub start

sub stop {
    my $self   = shift;
    my $vsname = shift;
    my $opts   = shift || {};

    my $cmd = "/usr/sbin/vserver $vsname stop >/dev/null 2>&1";

    my $max_tries = 10;

    foreach my $try ( 1 .. $max_tries ) {
        $self->sys()->run_cmd( $cmd, $opts );
        last if ( !$self->is_running($vsname) );
        sleep 30;
    }

    # vserver $vsname stop
    if ( $self->is_running($vsname) ) {
        my $msg = "Could not stop Vserver! Aborting.";
        return;
    }
    else {
        return 1;
    }
} ## end sub stop

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Linux::Virt::Plugin::Vserver - Linux-Vserver plugin for Linux::Virt

=head1 METHODS

=head2 is_host

Returns a true value if this is run on a vserver host.

=head2 is_running

Returns a true value if the given vserver is currently running on the
local host.

=head2 is_vm

Returns a true value if this is run inside a vserver.

=head2 start

Start the given vserver.

=head2 stop

Stop the given vserver.

=head2 vms

List all running VMs.

=head1 NAME

Linux::Virt::Plugin::Vserver - Linux Vserver Plugin for Linux::Virt

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
