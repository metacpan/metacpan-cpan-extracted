package LedgerSMB::Installer::OS::unix v0.999.0;

use v5.20;
use experimental qw(signatures);
use parent qw(LedgerSMB::Installer::OS);

use Carp qw( croak );
use File::Path qw( make_path remove_tree );
use File::Spec;
use HTTP::Tiny;
use Log::Any qw($log);


sub pg_config_extra_paths($self) {
    my @paths = qw(
        /opt/pgsql/bin
        /usr/lib/postgresql/bin
        /usr/local/pgsql/bin
        /usr/local/postgres/bin
        );
    push @paths, File::Spec->catdir( $ENV{POSTGRES_HOME}, 'bin' )
        if $ENV{POSTGRES_HOME};
    push @paths, File::Spec->catdir( $ENV{POSTGRES_LIB}, File::Spec->updir, 'bin' )
        if $ENV{POSTTGRES_LIB};
    return @paths;
}

sub am_system_perl($self) {
    return ($^X eq '/usr/bin/perl');
}

sub prepare_installer_env($self, $config) {
    $self->have_cmd('cpanm', 0);
    $self->have_cmd('gzip');     # fatal, used by 'tar'
    $self->have_cmd('tar');      # fatal
    $self->have_cmd('make');     # fatal
}

sub cpanm_install($self, $installpath, $locallib, $unmapped_mods) {
    unless ($self->{cmd}->{cpanm}) {
        make_path( File::Spec->catdir( $installpath, 'tmp' ) );

        my $http = HTTP::Tiny->new;
        my $r    = $http->get( 'https://cpanmin.us/' );
        if ($r->{status} == 599) {
            croak $log->fatal( "Unable to request https://cpanmin.us/: " . $r->{content} );
        }
        elsif (not $r->{success}) {
            croak $log->fatal( "Unable to request https://cpanmin.us/: $r->{status} - $r->{reason}" );
        }
        else {
            my $cpanm = File::Spec->catfile( $installpath, 'tmp', 'cpanm' );
            open( my $fh, '>', $cpanm )
                or croak $log->fatal( "Unable to open output file tmp/cpanm" );
            binmode $fh, ':raw';
            print $fh $r->{content};
            close( $fh ) or warn $log->warning( "Failure closing file tmp/cpanm" );
            chmod( 0755, $cpanm ) or warn $log->warning( "Failure making tmp/cpanm executable" );
            $self->{cmd}->{cpanm} = $cpanm;
        }
    }

    local $ENV{PERL_CPANM_HOME} = File::Spec->catdir( $installpath, 'tmp' );
    my @cmd = (
        $self->{cmd}->{cpanm},
        '--notest',
        '--metacpan',
        '--without-recommends',
        '--local-lib', $locallib,
        $unmapped_mods->@*
        );

    $log->debug( "system(): " . join(' ', map { "'$_'" } @cmd ) );

    system(@cmd) == 0
        or croak $log->fatal( "Failure running cpanm - exit code: $?" );
    remove_tree( File::Spec->catdir( $installpath, 'tmp' ) );
}

sub pkgs_from_modules($self, $mods) {
    croak $log->fatal( 'Generic Unix support does not include package installers' );
}

sub pkg_install($self, $pkgs) {
    croak $log->error( 'Generic linux support does not include package installers' );
}

sub untar($self, $tar, $target, %options) {
    my @cmd = ($self->{cmd}->{tar}, 'xzf', $tar, '-C', $target);
    push @cmd, ('--strip-components', $options{strip_components})
        if $options{strip_components};
    $log->debug( 'system(): ' . join(' ', map { "'$_'" } @cmd ) );
    system(@cmd) == 0
        or croak $log->fatal( "Failure executing tar: $!" );
}

sub generate_start_script($self, $installpath, $locallib) {
    ###TODO: capture file open error
    my $script = File::Spec->catfile( $installpath, 'server-start' );
    open( my $fh, '>', $script );
    my $starman = $self->have_cmd( 'starman', 0, [ File::Spec->catdir( $locallib, 'bin' ) ] );
    my $locallib_lib = File::Spec->catdir( $locallib, 'lib' );

    say $fh <<~EOF;
      #!/bin/bash

      cd $installpath
      exec $^X \\
          -I lib \\
          -I $locallib_lib \\
          $starman \\
          --listen 0.0.0.0:5762 \\
          --workers \${LSMB_WORKERS:-5} \\
          --preload-app bin/ledgersmb-server.psgi
      EOF
    ###TODO: capture mode change error
    chmod( 0755, $script );
}

1;
