package LedgerSMB::Installer::OS v0.999.10;

use v5.20;
use experimental qw(signatures);

use Cwd qw( getcwd );
use File::Basename qw( fileparse );
use File::Spec;

use Log::Any qw($log);

sub am_system_perl($self) {
    return !!0;
}

sub have_cmd($self, $cmd, $fatal = 1, $extra_path = []) {
    if ($self->{cmd} and $self->{cmd}->{$cmd}) {
        $log->debug( "Found cached command $self->{cmd}->{$cmd}" );
        return $self->{cmd}->{$cmd};
    }

    my $executable = '';
    if (File::Spec->file_name_is_absolute( $cmd )) {
        $executable = $cmd if -x $cmd;
    }
    else {
        my (undef, $dirs) = File::Spec->splitpath( $cmd );
        if ($dirs) {
            $cmd = File::Spec->catfile( getcwd(), $cmd );
            $executable = $cmd if -x $cmd;
        }
        else {
            # Prefer specific added paths over system path; we may have
            # installed something specific; if we did, we don't want to
            # find the system global thing in its place.
            for my $path ($extra_path->@*, File::Spec->path) {
                my $expanded = File::Spec->catfile( $path, $cmd );
                next if not -x $expanded;

                $executable = $expanded;
                last;
            }
        }
    }
    if ($executable) {
        $self->{cmd} //= {};
        $self->{cmd}->{$cmd} = $executable;
        $log->info( "Command $cmd found as $executable" );
    }
    elsif (not $fatal) {
        $log->info( "Command $cmd not found" );
    }
    else {
        die "Missing '$cmd'";
    }
    return $executable;
}

sub executable_name($self, $command) {
    return $command;
}

sub have_pkgs($self, $pkgs) {
}

sub pg_config_extra_paths($self) {
    return ();
}

sub pkgs_from_modules($self, $mod) {
    die 'Operating system and distribution support needs to override the "pkgs_from_modules" method';
}

sub pkg_can_install($self) {
    return 0; # there's no such thing as generic installer support across operating systems
}

sub pkg_install($self) {
    die 'Operating system and distribution support needs to override the "pkg_install" method';
}

sub pkg_uninstall($self) {
    die 'Operating system and distribution support needs to override the "pkg_uninstall" method';
}

sub name($self) {
    die 'Operating system and distribution support needs to override the "name" method';
}

sub cleanup_env($self, $config, %args) {
}

1;
