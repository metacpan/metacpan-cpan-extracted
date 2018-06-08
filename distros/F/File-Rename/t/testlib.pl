use strict;

require File::Spec;
require File::Path;

sub main_argv { local @ARGV = @_; main () } 

my $tempdir;

sub tempdir {
    my $d = 'temp' . $$;
    File::Path::rmtree $d if -d $d;
    File::Path::mkpath $d;
    return ($tempdir = $d);
}

sub create {
    my $d = $tempdir;
    die unless $d and -d $d;
    for (@_) { 
        create_file(File::Spec->catfile($d, $_), $_) or die; 
    } 
}

sub listdir {
    my $d = shift;
    local *DIR;
    unless (opendir DIR, $d) { diag "Can't opendir $d: $!"; return }
    my @read = readdir DIR;
    closedir DIR or die $!;
    return (grep {!/^\./} @read);
}

sub create_file {
    my $file = shift;
    local *FILE; 
    if (open  FILE, '>', $file) {
    	print FILE @_;
    	close FILE or die $!;
	return 1;
    }
    $file =~ s/\n/\\n/;
    diag "Can't create file \"$file\": $!\n";
    return;
} 

sub test_rename_files {
    my($sub, $file, $verbose, $warning, $printed) = @_;
    my @file = ref $file ? @$file : $file;
    test_rename_function( 
	sub { File::Rename::rename_files($sub, $verbose, @file) },
	$warning, $printed
    );
}

sub test_rename_list {
    my($sub, $fh, $verbose, $warning, $printed) = @_;
    test_rename_function( 
	sub { File::Rename::rename_list($sub, $verbose, $fh) },
	$warning, $printed
    );
}

sub test_rename_function {
  my ($function, $warning, $printed) = @_;
  our($found, $print, $warn);

  { local *STDOUT;
    open STDOUT, '>'. 'log' or die "Can't create log file: $!\n";
    undef $warn;
    $function -> ();
    close STDOUT or die;
  }

  { local *READ; 
    open READ, '<'. 'log' or die "Can't read log file: $!\n";
    local $/;
    $print = <READ>; 
    close READ or die;
  }

    undef $found;
    if( $warning ) {
	if( $warn ) {
	    if( $warn =~ s/^\Q$warning\E\b.*\n//sm ) { $found ++ }
	}
    	else { $warn = "(no warning)\n" }
	     
	unless( $found ) {
	    $warning =~ s/^/EXPECT: WARN: /mg; diag $warning;
	}
    }
    elsif( $printed ) {
	if( $print ) {
	    if( $print =~ s/^\Q$printed\E(\s.*)?\n//sm ) { $found ++ }
	}
    	else { $print = "(no output)\n" }
	     
	unless( $found ) {
	    $printed =~ s/^/EXPECT: PRINT: /mg; diag $printed;
	}
    }
    else {
	$found++ unless $warn or $print;
    }	
}

sub diag_rename {
    if( our $warn ) { $warn =~ s/^/WARN: /mg; diag $warn; }
    if( our $print ) { $print =~ s/^/PRINT: /mg; diag $print; }
}

1;
