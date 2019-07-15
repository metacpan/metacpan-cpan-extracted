package Module::Build::HiPi::BCM2835;

use 5.14.0;
use strict;
use warnings;
use Module::Build;
use Config;
use File::Copy;
use Cwd;
use File::Path;
our @ISA = qw( Module::Build );

our $VERSION ='0.64';

sub process_xs_files {
	my $self = shift;

	# Override Module::Build with a null implementation
	# We will be doing our own custom XS file handling
}

sub hipi_run_command {
	my ($self, $cmds) = @_;
	my $cmd = join( ' ', @$cmds );
    if ( !$self->verbose and $cmd =~ /(cc|gcc|g\+\+|cl).+-o\s+(\S+)/ ) {
		my $object_name = File::Basename::basename($2);
		$self->log_info("    CC -o $object_name\n");
    } elsif ( !$self->verbose and $cmd =~ /(configure|make)/i ) {
		$self->log_info("    SH $1\n")
    } else {
		$self->log_info("$cmd\n");
	}
	my $rc = system($cmd);
	die "Failed with exit code $rc\n$cmd\n"  if $rc != 0;
	die "Ctrl-C interrupted command\n$cmd\n" if $rc & 127;
}

sub ACTION_clean {
    my $self = shift;
    $self->SUPER::ACTION_clean;
    File::Path::remove_tree('BCM2835/buildlib') if -d 'BCM2835/buildlib';
    unlink('mylib/lib/libbcm2835Static.a');
}

sub ACTION_build {
    my $self = shift;
    $self->SUPER::ACTION_build;
    $self->hipi_build_bcm2835_library;
    $self->hipi_build_xs;
    $self->log_info(qq(Build Complete\n));
}


# Build test action invokes build first
sub ACTION_test {
	my $self = shift;
	$self->depends_on('build');
	$self->SUPER::ACTION_test;
}

# Build install action invokes build first
sub ACTION_install {
	my $self = shift;
	$self->depends_on('build');
	$self->SUPER::ACTION_install;
}

sub hipi_build_bcm2835_library {
    my $self = shift;
    
    $self->log_info(qq(Building bcm2835 library\n));
    mkdir( 'mylib/lib', 0777 ) if !-d 'mylib/lib';
    my $tgtlib = 'mylib/lib/libbcm2835Static.a';
    
    return if $self->up_to_date( [ 'Build', 'BCM2835/src/src/bcm2835.c', 'BCM2835/src/src/bcm2835.h' ], [ $tgtlib ] );
     
    my $gcc = $Config{cc};
    $gcc = 'gcc' if $gcc eq 'cc';
    my $gxx = $gcc;
    $gxx =~ s/^gcc/g\+\+/;
    my $gld = $Config{ld};
    
    chdir('BCM2835');
    my $buildlibdir = Cwd::abs_path( getcwd() );
    die 'Failed to determine working directory' unless $buildlibdir && $buildlibdir =~ /\/BCM2835/;
    
    $buildlibdir .= '/buildlib';
    mkdir( $buildlibdir, 0777 );
        
    chdir('buildlib');
    my $quiet = ( $self->verbose ) ? '' : '--quiet ';
    my @cmd = (
                qq(sh ../src/configure $quiet--prefix=$buildlibdir CC=$gcc CXX=$gxx LD=$gld),
        );

        $self->hipi_run_command( \@cmd );
    @cmd = (
                qq(make $quiet),
        );
    $self->hipi_run_command( \@cmd );
    
    chdir('../../');
    
    # copy the lib
    my $srclib = 'BCM2835/buildlib/src/libbcm2835.a';
    File::Copy::copy( $srclib, $tgtlib );
}


sub hipi_build_xs {
    my $self = shift;
    
    return if $^O !~ /linux/i;
    
    $self->log_info(qq(Building XS Files\n));
    
    my @modules = (
        { name => 'BCM2835', version => $VERSION, autopath => 'HiPi/BCM2835', libs => '-Lmylib/lib -lbcm2835Static' },
    );
    
    #----------------------------------------------
    # determine typemap
    #----------------------------------------------
    
    my $perltypemap;
	
	for my $incpath (@INC) {
		my $perlcheckfile = qq($incpath/ExtUtils/typemap);
		if ( !$perltypemap && -f $perlcheckfile ) {
			$perltypemap = $perlcheckfile;
			$perltypemap =~ s/\\/\//g;
		}
		last if $perltypemap;
	}

	die 'Unable to determine Perl typemap' if !defined($perltypemap);
    
    for my $mod ( @modules ) {
        my $xsfile   = qq($mod->{name}.xs);
        my $cfile    = qq($mod->{name}.c);
        my $ofile    = qq($mod->{name}.o);
        my $autopath = 'blib/arch/auto/' . $mod->{autopath};
        my $bsfile   = qq($autopath/$mod->{name}.bs);
        my $dllfile  = qq($autopath/$mod->{name}.) . $Config{dlext};
        
        File::Path::make_path( $autopath, { mode => 0755 } );
        
        # make bootscript file
        if ( open my $fh, '>', $bsfile ) {
            close $fh;
        }
        
        # Build Object File
        
        unless ( $self->up_to_date( $xsfile, $cfile ) ) {
            
            for ( qw( o def c xsc obj ) ) {
                my $fname = qq($mod->{name}.$_);
                unlink( $fname ) if -f $fname;
            }
            require ExtUtils::ParseXS;
            ExtUtils::ParseXS::process_file(
                filename    => $xsfile,
                output      => $cfile,
                prototypes  => 0,
                linenumbers => 0,
                typemap     => [
                    $perltypemap,
                    'typemap',
                ],
            );
            
            my @cmd = (
                $Config{cc},
                '-c -o',
                $ofile,
                $Config{ccflags},
                $Config{optimize},
                '-DVERSION=\"' . $mod->{version} . '\" -DXS_VERSION=\"' . $mod->{version} . '\"',
                $Config{cccdlflags},
                '-Imylib/include',
                '-I' . $Config{archlibexp} . '/CORE',
                $cfile,
            );
            $self->hipi_run_command( \@cmd );  
        }
        
        # Link Object
        unless( $self->up_to_date( $cfile, $dllfile ) ) {
            
            my $libdirs = $Config{libpth};
            $libdirs =~ s/\s+/ -L/g;
            
            unlink( $dllfile );
            my @cmd = (
                $Config{ld},
                qq(-L$libdirs),
                $Config{lddlflags},
                $ofile,
                '-o ' . $dllfile,
                $mod->{libs}
            );
            $self->hipi_run_command( \@cmd );
        }
    }
}

1;
