package LedgerSMB::Installer::Configuration v0.999.11;

use v5.20;
use experimental qw(signatures);

use Cwd qw( getcwd );
use File::Spec;
use Symbol;


use HTTP::Tiny;
use Log::Any qw($log);

my $http = HTTP::Tiny->new;


sub new( $class, %args ) {
    return bless {
        # initialization options
        _assume_yes  => $args{assume_yes} // 0,
        _installpath => $args{installpath} // 'ledgersmb',
        _locallib    => $args{locallib} // 'local',
        _loglevel    => $args{loglevel} // 'info',
        _prep_env    => $args{prepare_env},
        _sys_pkgs    => $args{sys_pkgs},
        _verify_sig  => $args{verify_sig} // 1,
        _version     => $args{version},
        _uninstall_env  => $args{uninstall_env},

        # internal state
        _deps  => undef,
        _cleanup_pkgs => [],
    }, $class;
}

sub dependency_url($self, $distro, $id) {
    return "https://download.ledgersmb.org/f/dependencies/$distro/$id.json";
}

sub have_deps($self) {
    return (defined $self->{_deps}
            and defined $self->{_deps}->{packages}
            and $self->{_deps}->{packages}->@*);
}

sub retrieve_precomputed_deps($self, $name, $id) {
    return unless $name and $id;

    my $url  = $self->dependency_url($name, $id);

    $log->info( "Retrieving dependency listing from $url" );
    my $r = $http->get( $url );
    my $pkgs;
    if ($r->{success}) {
        $self->{_deps} = JSON::PP->new->utf8->decode( $r->{content} );
        $pkgs = $self->{_deps}->{packages};
    }
    elsif ($r->{status} == 599) {
        die $log->fatal(
            'Error trying to retrieve precomputed dependencies: ' . $r->{content}
            );
    }
    $self->{_deps_retrieved} = 1;
    return ($self->{_deps}->{packages}, $self->{_deps}->{modules});
}

sub mark_pkgs_for_cleanup($self, $pkgs) {
    push $self->{_cleanup_pkgs}->@*, $pkgs->@*;
}

sub pkgs_for_cleanup($self) {
    return $self->{_cleanup_pkgs}->@*;
}

sub normalize_paths($self) {
    my $installpath = $self->installpath;
    if (not File::Spec->file_name_is_absolute( $installpath )) {
        my @dirs = File::Spec->splitdir( $installpath );
        if (@dirs) {
            if ($dirs[0] ne File::Spec->curdir) {
                $self->installpath( File::Spec->catdir( getcwd(), $installpath ) );
            }
        }
    }
    my $locallib = $self->locallib;
    if (not File::Spec->file_name_is_absolute( $locallib )) {
        my @dirs = File::Spec->splitdir( $locallib );
        if (@dirs == 1) {
            $self->locallib( File::Spec->catdir( $installpath, $locallib ) );
        }
        else {
            $self->locallib( File::Spec->catdir( getcwd(), $locallib ) );
        }
    }
}

sub effective_compute_deps( $self ) {
    return '' unless $self->sys_pkgs;
    return '' if $self->{_deps};

    if (defined $self->compute_deps) {
        return $self->compute_deps;
    }

    $log->warning( "Result of 'effective_compute_deps()' not reliable: "
                   . "no attempt to retrieve dependencies" )
        unless $self->{_deps_retrieved};

    return 1;
}

sub effective_prepare_env( $self ) {
    if (defined $self->prepare_env) {
        return $self->prepare_env;
    }

    return 1 if $self->assume_yes;

    # ask and set 'prepare_env' (so uninstall_env can use it) ...
    if (-t STDIN) {
        while (1) {
            my $key = '';
            print "\nPackage installation required. Proceed? (y/N) ";
            my $line = <STDIN>;
            $key = substr( $line, 0, 1 );
            if (lc($key) eq 'y') {
                $self->prepare_env( 1 );
                return 1;
            }
            elsif (lc($key) eq 'n'
                   or $key eq "\n") {
                $self->prepare_env( 0 );
                return 0;
            }
            else {
                say "\nInvalid input";
            }
        }
    }
    else {
        $log->info( "Input is not a TTY; assuming answer 'no' to package installation permission" );
        $self->prepare_env( 0 );
        return 0;
    }
}

sub effective_uninstall_env( $self ) {
    if (defined $self->uninstall_env) {
        return $self->uninstall_env;
    }

    return $self->effective_prepare_env;
}

sub effective_version( $self ) {
    return $self->version if defined $self->version;
    $log->debug( "Resolving 'latest' version to actual version number" );

    my $r = $http->get( 'https://api.github.com/repos/ledgersmb/LedgerSMB/releases/latest' );
    if ($r->{success}) {
        my $content = JSON::PP->new->utf8->decode( $r->{content} );

        if (defined $content
            and defined $content->{tag_name}) {
            $self->version( $content->{tag_name} );
            $log->info( "Resolved 'latest' version to $content->{tag_name} for installation" );

            return $content->{tag_name};
        }
        else {
            die $log->fatal( "Information for 'latest' release does not include tag_name" );
        }
        # unreachable
    }
    elsif ($r->{status} == 599) {
        die $log->fatal(
            'Error trying to retrieve precomputed dependencies: ' . $r->{content}
            );
    }
    # unreachable
}

sub option_callbacks($self, $options) {
    my %opts = (
        'yes|y!'             => sub { $self->assume_yes( $_[1] ) },
        'system-packages!'   => sub { $self->sys_pkgs( $_[1] ) },
        'prepare-env!'       => sub { $self->prepare_env( $_[1] ) },
        'target=s'           => sub { $self->installpath( $_[1] ) },
        'local-lib=s'        => sub { $self->locallib( $_[1] ) },
        'log-level=s'        => sub { $self->loglevel( $_[1] ) },
        'verify-sig!'        => sub { $self->verify_sig( $_[1] ) },
        );

    return %opts{$options->@*};
}

for my $acc (qw( assume_yes installpath locallib loglevel
                 compute_deps prepare_env sys_pkgs
                 verify_sig uninstall_env version cpanfile cpanfile_path )) {
    my $ref = qualify_to_ref $acc;
    *{$ref} = sub($self, $arg = undef) {
        $self->{"_$acc"} = $arg
            if defined $arg;
        return $self->{"_$acc"};
    };
}

1;
