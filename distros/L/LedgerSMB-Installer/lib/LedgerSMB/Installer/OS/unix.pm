package LedgerSMB::Installer::OS::unix v0.999.11;

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

sub prepare_builder_env($self, $config) {
    warn $log->warning( 'generic Unix/Linux support does not install required module build tools' );
}

sub prepare_extraction_env($self, $config) {
    $self->have_cmd('gzip');                          # fatal, used by 'tar'
    $self->have_cmd('tar');                           # fatal
    $self->have_cmd('gpg', $config->verify_sig);      # fatal, when verification required
}

sub prepare_installer_env($self, $config) {
    $self->have_cmd('cpanm', 0);
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
        );

    # install dependencies from 'cpanfile' because that includes
    # version range restrictions
    my @deps_cmd = (@cmd, '--installdeps', $installpath);
    $log->debug( "system(): " . join(' ', map { "'$_'" } @deps_cmd ) );
    system(@deps_cmd) == 0
        or croak $log->fatal( "Failure running cpanm - exit code: $?" );

    # only install modules which were not satisfied from cpanfile
    # as fallback, because we're missing version range restrictions
    my @mods_cmd = (@cmd, '--skip-satisfied', $unmapped_mods->@*);
    $log->debug( "system(): " . join(' ', map { "'$_'" } @mods_cmd ) );
    system(@mods_cmd) == 0
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
    push @cmd, '--no-same-owner'
        if $options{no_same_owner};
    $log->debug( 'system(): ' . join(' ', map { "'$_'" } @cmd ) );
    system(@cmd) == 0
        or croak $log->fatal( "Failure executing tar - exit code: $?" );
}

sub verify_sig($self, $installpath, $tar, $sig, $key) {
    my $tempdir = File::Spec->catdir( $installpath, 'tmp' );
    my $gpgdir  = File::Spec->catdir( $tempdir, 'gnupg' );
    make_path( $tempdir, $gpgdir );
    chmod( 0700, $gpgdir )
        or warn $log->warning( "Unable to protect $gpgdir: $!" );

    my @cmd = (
        $self->{cmd}->{gpg},
        '--quiet',
        '--homedir', $gpgdir,
        '--no-autostart',
        '--batch',
        '--no-tty',
        '--yes',
        '--trust-model', 'always',
        '--no-default-keyring',
        '--keyring',
        File::Spec->catfile( $tempdir, 'verification-keyring.kbx' ),
        );

    $log->trace( "Importing key:\n$key" );
    $log->debug( 'system(): ' . join( ' ', map { "'$_'" } (@cmd, '--import') ) );
    open(my $fh, '|-', @cmd, '--import')
        or die "Can't open pipe to gpg for download verification: $!";
    print $fh $key;
    close($fh) or warn "Error closing pipe to gpg on key import: $!";

    $log->debug( 'system(): ' . join( ' ', map { "'$_'" } (@cmd, '--verify', $sig, $tar) ) );
    system( @cmd, '--verify', $sig, $tar ) == 0
        or croak $log->fatal( "Failure to verify gpg signature - exit code: $?" );

    remove_tree( $tempdir );

    $log->info( 'gpg signature validated correctly' );
}

sub generate_start_script($self, $installpath, $locallib) {
    ###TODO: capture file open error
    my $script = File::Spec->catfile( $installpath, 'server-start' );
    open( my $fh, '>', $script );
    my $starman = $self->have_cmd( 'starman', 0, [ File::Spec->catdir( $locallib, 'bin' ) ] );
    my $locallib_lib = File::Spec->catdir( $locallib, 'lib', 'perl5' );

    say $fh <<~EOF;
      #!/usr/bin/bash

      cd $installpath
      exec $^X \\
          -I $installpath/lib \\
          -I $installpath/old/lib \\
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
