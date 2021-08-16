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
    my @created;
    for (@_) { 
        my $path = File::Spec->catfile($d, $_);
        my $text = $_;
        $text =~ s/[^\x20-\x7e]/?/g;
        if ( create_file($path, $text) ) {
            push @created, $path;
        }
    } 
    return @created;
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
        return 1 if close FILE;
    }
    $file =~ s/\n/\\n/g;
    $file =~ s/\s/\\ /g;
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
  our($found, $print, $warn) = ();

  { local *STDOUT;
    open STDOUT, '>', \$print or die;
    $function -> ();
    close STDOUT or die;
  }

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

sub options {
    local @ARGV = @_;
    my $opt = do {
	    require File::Rename::Options; 
	    File::Rename::Options::GetOptions(1);
    };
    die "Bad options '@_'" unless $opt;
    die "Not options '@ARGV'" if @ARGV;
    return $opt;
}
    
sub is_windows {
    unless ( $] < 5.014 ) {
	if ( eval { require Perl::OSType; } ) { 
            return Perl::OSType::is_os_type('Windows'); 
	}
	diag $@;
    }
    return ($^O =~ m{Win}) 
} 

sub script_name {
    return +(is_windows() ? 'file-rename' : 'rename');
}

1;
