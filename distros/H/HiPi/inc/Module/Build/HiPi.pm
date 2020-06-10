package Module::Build::HiPi;

use 5.14.0;
use strict;
use warnings;
use Module::Build;
use Config;
use File::Copy;
use Cwd;
use File::Path;
our @ISA = qw( Module::Build );

our $VERSION ='0.81';

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
}

sub ACTION_build {
    my $self = shift;
    $self->SUPER::ACTION_build;
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

sub hipi_build_xs {
    my $self = shift;
    
    return if $^O !~ /linux/i;
    
    $self->log_info(qq(Building XS Files\n));
    
    my @modules = (
        { name => 'Utils', version => $VERSION, autopath => 'HiPi/Utils', libs => '' },
        { name => 'Exec', version => $VERSION, autopath => 'HiPi/Utils/Exec', libs => '-lz' },
        { name => 'I2C',  version => $VERSION, autopath => 'HiPi/Device/I2C', libs => '' },
        { name => 'SPI',  version => $VERSION, autopath => 'HiPi/Device/SPI', libs => '' },
        { name => 'GPIO', version => $VERSION, autopath => 'HiPi/GPIO', libs => '' },
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

sub hipi_build_data {
    my $self = shift;
    require File::Copy::Recursive;
    File::Copy::Recursive::dircopy('mylib/auto/share','blib/lib/auto/share');
}

1;
