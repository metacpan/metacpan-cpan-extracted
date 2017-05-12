package Hardware::Vhdl::Automake::Compiler::ModelSim;
@ISA = ('Hardware::Vhdl::Automake::CompileTool');

use Hardware::Vhdl::Automake::UnitName;
use Hardware::Vhdl::Automake::CompileTool;
use File::Spec::Functions;
use File::Basename;
use File::Path;
use YAML;
use Carp;

use strict;
use warnings;

=head1 NAME

Hardware::Vhdl::Automake::Compiler::ModelSim - ModelSim compilation tool controller

=cut

sub compile {
    my $self  = shift;
    my $dunit = shift;

    $self->ensure_library( $dunit->library );
    chdir $self->{basedir};

    # remember this dunit as passed to the compiler, but not compiled
    my $dukey = $dunit->name->short_string;
    $self->{compiled}{$dukey} = 0;

    #my $libdir = $self->{lib_mapping}{$dunit->library};
   
    # we must recompile if there is not compile info for the du or if the code digest has changed
    my $ci       = $dunit->get_compile_info( $self->toolid );
    
    #~ if (exists $ci->{dependencies}) {
        #~ print "$dukey depends on:\n";
        #~ for my $ddu (@{$ci->{dependencies}}) {
            #~ print "  ".$ddu->name->short_string."\n";
        #~ }
    #~ } else {
        #~ print "$dukey has no dependency info\n";
    #~ }
    
    my $uptodate = defined $ci->{digest};
    my $reason = '';
    if (!$uptodate) { $reason = "there is no record of any previous compilation of the design unit" }
    
    # we must recompile if the code digest has changed
    if ($uptodate) { 
        $uptodate = $ci->{digest} eq $dunit->digest;
        if (!$uptodate) { $reason = "code digest changed" }
    }
    
    # we must recompile if the design unit is not in the library 
    if ($uptodate) {
        unless (defined $ci->{compiled_name}) {
            $uptodate=0;
            $reason = "design unit is not listed in library info";
        }
    }

    # we must recompile if the compiled file is missing
    my $compfile = $self->compiled_file($dunit);
    if ($uptodate) {
        unless (defined $compfile && -f $compfile) {
            $uptodate=0;
            $reason = "compiled data for design unit is missing";
        }
    }

    # we must recompile if any of the du's dependencies have been recompiled since this dunit was recompiled
    if ($uptodate && exists $ci->{dependencies}) {
        my $bin_age = -M $compfile;
        for my $ddu (@{$ci->{dependencies}}) {
            my $dep_compfile = $self->compiled_file($ddu);
            if (defined $dep_compfile && -f $dep_compfile && (-M $dep_compfile < $bin_age)) {
                $uptodate = 0;
                $reason = "depended dunit ".$ddu->name->short_string." changed"; #: '$dep_compfile' is newer than '$compfile'";
                last;
            }
        }
    }
              
    if ($uptodate) {
        $self->report_status(
            {
                type    => 'compile_skip',
                text    => 'Skipping ModelSim compile',
                duname  => $dunit->name,
                file    => $dunit->file,
            }
        );
    } else {
        $self->report_status(
            {
                type    => 'compile',
                text    => 'Doing ModelSim compile',
                duname  => $dunit->name,
                file    => $dunit->file,
                reason  => $reason,
            }
        );

        $self->_compile2($dunit);
        
        $ci->{digest} = $dunit->digest;
        $dunit->set_compile_info( $self->toolid, $ci );
        
        # remember this dunit as compiled
        $self->{compiled}{$dukey} = 1;
    }
}

sub init {
    my $self = shift;
    my $arg1 = shift;

    $self->{lib_mapping} = {};

    if ( ref $arg1 eq 'HASH' ) {

        # check required args
        for my $argname (qw/ basedir /) {
            croak "'$argname' parameter is required for new Compiler::ModelSim" unless exists $arg1->{$argname};
        }

        # copy allowed args to self
        for my $argname (qw/ basedir /) {
            if ( exists $arg1->{$argname} ) {
                $self->{$argname} = $arg1->{$argname};
                delete $arg1->{$argname};
            }
        }

        # check there are no passed args left
        if ( scalar keys %$arg1 ) { croak "unrecognised parameter(s) " . join( ', ', keys %$arg1 ) . " passed" }
    } else {
        croak "Compiler::ModelSim::new should be passed a hashref of information";
    }

    #~ $self->set_modelsim_path("C:\\ProgramFiles\\FpgaAdv40\\Modeltech\\win32pe");
    $self->set_modelsim_path("C:\\ProgramFiles\\Modeltech\\win32pe");
}

sub set_modelsim_path {
    my $self = shift;
    $self->{modelsim_path} = shift;
    for my $prog (qw/vlib vcom vlog vdel/) {
        $self->{$prog} = catfile( $self->{modelsim_path}, $prog );
    }
}

sub compile_start {
    my $self = shift;
    $self->report_status( { type => 'compile_start', text => 'Starting ModelSim compilation' } );
    $self->{compiled} = {};
    unless (-f catfile( $self->{basedir}, 'modelsim.ini') ) { $self->write_modelsim_ini }
}

sub _compile2 {
    my ($self, $dunit) = @_;
    my @r;
    my @deps;
    my $lang = $dunit->sourcefile->language;
    if ( defined $lang && $lang =~ /^Verilog$/i ) {
        @r = $self->sys_capture( [ $self->{vlog}, '-source', '-work', $dunit->library, $dunit->file ] );
    } elsif ( defined $lang && $lang =~ /^VHDL/i ) {
        my @opts;
        push @opts, $dunit->get_compiler_option('vhdl_language_version') eq '87' ? '-87' : '-93';
        
        my ($optname, $switchname);
        # switches which we should set if the option is true
        my %opt2switch = (
            check_for_synthesis => '-check_synthesis', # Turns on limited synthesis rule compliance checking. Checks to see that signals read by a process are in the sensitivity list.
            prefer_explicit_function_definition => '-explicit', # Directs the compiler to resolve ambiguous function overloading by favoring the explicit function definition over the implicit function definition.
            ignore_vital_errors => '-ignorevitalerrors', # Directs the compiler to ignore VITAL compliance error
            hide_internal_data => '-nodebug', # Hides the internal data of the compiled design unit
            perform_default_binding => '-performdefaultbinding', # Enables default binding when it has been disabled via the RequireConfigForAllDefaultBinding option in the modelsim.ini file.
        );
        while (($optname, $switchname) = each (%opt2switch)) {
            push @opts, $switchname if $dunit->get_compiler_option($optname);
        }

        #~ push @opts, '-coverAll' if $dunit->get_compiler_option('check_for_synthesis'); #! bodge for coverage testing

        # switches which we should set if the option is FALSE
        %opt2switch = (
            generate_default_binding => '-ignoredefaultbinding', # Instructs the compiler not to generate a default binding during compilation. You must explicitly bind all components in the design if you set this to false.
            use_builtin_vital => '-novital', # If disabled, causes VCOM to use VHDL code for VITAL procedures rather than the accelerated and optimized timing and primitive packages built into the simulator kernel. Optional.
            use_builtin_1164 => '-no1164', # Causes the source files to be compiled taking advantage of the built-in version of the IEEE std_logic_1164 package.
            run_time_range_checks => '-nocheck', # In some designs, this could result in a 2X speed increase.
            vital95_check => '-novitalcheck', # If disabled, disables VITAL95 compliance checking if you are using VITAL 2.2b.
            error_case_static => '-nocasestaticerror', # Changes case static warnings into errors.
            error_others_static => '-noothersstaticerror', # Enables errors that result from "others" clauses that are not locally static.
            warn_unbound_component => ['-nowarn', 1],
            warn_process_without_wait => ['-nowarn', 2],
            warn_null_range => ['-nowarn', 3],
            warn_no_space_in_time_literal => ['-nowarn', 4],
            warn_multiple_drivers_on_unresolved_signal => ['-nowarn', 5],
            warn_compliance => ['-nowarn', 6],
            warn_optimization => ['-nowarn', 7],
        );
        while (($optname, $switchname) = each (%opt2switch)) {
            push @opts, (ref $switchname ? @$switchname : $switchname) unless $dunit->get_compiler_option($optname);
        }
        
        @r = $self->sys_capture( [ $self->{vcom}, @opts, '-source', '-work', $dunit->library, $dunit->file ] );
        #~ print "Command = <<".join(' ', $self->{vcom}, @opts, '-source', '-work', $dunit->library, $dunit->file).">>\n";
    }
    #~ print "Command output = <<".join("", @r).">>\n";
    {

        # scan the output for errors
        $r[0] = '' if !defined $r[0];
        if ( $r[0] !~ /Model Technology ModelSim .* (vcom|vlog) .* Compiler/i ) {
            $self->report_status(
                {
                    type => 'assert_fail',
                    text => 'First line of output from ModelSim compile command was not as expected',
                    got  => $r[0],
                    expected => 'Model Technology ModelSim .* (vcom|vlog) .* Compiler',
                }
            );
            croak "ModelSim compile failure";
        }
        shift @r;
        my $sourceline = '';
        my $where      = '';
        my $compile_error_flag = 0;
        for my $rl (@r) {
            if ( $rl =~ /^###### (.*)\((\d+)\):(.*)$/ ) {
                $where = [ $1, $2 ];
                $sourceline = $3;
            } elsif ( $rl =~ /^(?:\*\* Warning|WARNING): (.*)\((\d+)\):(.*)$/ ) {
                my $report = {
                        type       => 'warning',
                        text       => 'ModelSim compile warning; ' . $3,
                        duname     => $dunit->name,
                        genfile    => $1,
                        genlinenum => $2,
                    };
                $report->{sourceline} = $sourceline if $1 eq $where->[0] && $2 == $where->[1];
                my ($lfn, $lln) = $dunit->line_to_source($report->{genlinenum});
                if (defined $lfn) {
                    $report->{srcfile} = $lfn;
                    $report->{srclinenum} = $lln;
                }
                $self->report_status($report);
            } elsif ( $rl =~ /^(?:\*\* Error|ERROR): (.*)\((\d+)\):(.*)$/ ) {
                my $report = {
                        type       => 'error',
                        text       => 'ModelSim compile error; ' . $3,
                        duname     => $dunit->name,
                        genfile    => $1,
                        genlinenum => $2,
                    };
                $report->{sourceline} = $sourceline if $1 eq $where->[0] && $2 == $where->[1];
                my ($lfn, $lln) = $dunit->line_to_source($report->{genlinenum});
                if (defined $lfn) {
                    $report->{srcfile} = $lfn;
                    $report->{srclinenum} = $lln;
                }
                $self->report_status($report);
                #~ if ( $report->{text} =~ /^ModelSim compile error; Could not find .*\\(\S+)\.(\S)\s*$/ ) {
                    #~ print "We may need to compile package $1.$2 first\n";
                #~ }
                $compile_error_flag = 1;
            } elsif ( $rl =~ /^(?:\*\* Error|ERROR): (.*)$/ ) {
                my $report = {
                    type    => 'error',
                    text    => 'ModelSim compile error; ' . $1,
                    duname  => $dunit->name,
                    genfile    => $dunit->file,
                    genlinenum => 1,
                };
                my ($lfn, $lln) = $dunit->line_to_source($report->{genlinenum});
                if (defined $lfn) {
                    $report->{srcfile} = $lfn;
                    $report->{srclinenum} = $lln;
                }
                $self->report_status($report);
                $compile_error_flag = 1;
            }
        }
        if ($compile_error_flag) {
            croak "compile error";
        }

    }
}
    
sub compile_finish {
    my $self = shift;
    $self->report_status( { type => 'compile_finish', text => 'Finished ModelSim compilation' } );
}

sub compile_abort {
    my $self = shift;
    $self->report_status( { type => 'compile_abort', text => 'Aborting ModelSim compilation' } );
}

sub ensure_library {
    my $self    = shift;
    my $libname = shift;
    my $libdir  = catdir( $self->{basedir}, &name_to_filename($libname) );
    unless ( -d $libdir && -f catfile( $libdir, '_info' ) ) {
        $self->report_status(
            {
                type     => 'mklib',
                text     => 'Creating ModelSim library',
                library  => $libname,
                location => $libdir,
            }
        );
        mkpath(dirname($libdir));
        $self->_vlib($libdir, $libname);
    }
    unless ( defined $self->{lib_mapping}{$libname} && $self->{lib_mapping}{$libname} eq $libdir ) {
        $self->{lib_mapping}{$libname} = $libdir;
        $self->write_modelsim_ini;
    }
}

sub _vlib {
    my ($self, $libdir, $libname) = @_;
    my @r = $self->sys_capture( [ $self->{vlib}, $^O eq 'MSWin32' ? '-dos' : '-unix', $libdir ] );
    if (@r) {

        # there should be no output unless there is an error
        $self->report_status(
            {
                type     => 'error',
                text     => 'vlib error: ' . join( '; ', @r ),
                library  => $libname,
                location => $libdir,
            }
        );
        croak 'vlib error: ' . join( '; ', @r );
    }
}

sub write_modelsim_ini {
    my $self = shift;
    my $fh;
    $self->report_status(
        {
            type => 'config',
            text => 'Updating modelsim.ini',
        }
    );
    open $fh, '>', catfile( $self->{basedir}, 'modelsim.ini' ) || croak "Couldn't write modelsim.ini:$!";
    print $fh "[Library]\n";
    print $fh "others = \$MODEL_TECH/../modelsim.ini\n";
    while ( my ( $lib, $dir ) = each %{ $self->{lib_mapping} } ) {
        print $fh "$lib = $dir\n";
    }
    close $fh;
}

sub get_deps {
    my $self = shift;
    my $hdl2bin = {};
    my $hdl2deps = {};
    my ($lib, $libdir);
    while ( ($lib, $libdir) = each %{$self->{lib_mapping}}) {
        $self->_parse_modelsim_info($libdir, $lib, $hdl2deps, $hdl2bin);
    }
    ($hdl2bin, $hdl2deps);
}

# this regex pattern captures a VHDL name: ((?:[A-Za-z][A-Za-z0-9_]*)|(?:\\.*?\\))
sub _parse_modelsim_info {
    my ($self, $libdir, $libname, $deps, $src2bin) = @_;
    my $file = catfile($libdir, '_info');
    my %dutypes = (
        E => 'entity',
        A => 'architecture',
        C => 'configuration',
        P => 'package',
        B => 'package body',
        v => 'Verilog unit',
    );
    
    my $fh;
    -f $file || return ($deps, $src2bin);
    open $fh, "<$file" || die "Couldn't read ModelSim library info file '$file': $!\n";
    
    my $line;
    my $cunit = {type => undef, source => undef, depends => []};
    while (1) {
        my $line = <$fh>;
        if (defined $line) {
            chomp $line;
        } else {
            $line = 'E_'; # dummy value to mark end of file
        }
        my $p = substr($line, 0, 1); # prefix
        my $a = substr($line, 1); # arguments
        
        if (exists $dutypes{$p}) {
            
            # new dunit data is starting
            if (defined $cunit->{source}) {
                $deps->{$cunit->{source}} = $cunit->{depends};
                $src2bin->{$cunit->{source}} = $cunit->{compiled_name};
            }
            
            # start a new set of info
            $cunit = {
                type => $dutypes{$p}, 
                source => undef, 
                depends => [], 
                compiled_name => $a,
            };
            
        } elsif ($p eq 'D') {
            # a dependency for the current dunit
            if ($a =~ m/^(A) ((?:[A-Za-z][A-Za-z0-9_]*)|(?:\\.*?\\)) ((?:[A-Za-z][A-Za-z0-9_]*)|(?:\\.*?\\)) ((?:[A-Za-z][A-Za-z0-9_]*)|(?:\\.*?\\)) (\S{22,22})\s*$/) {
                my ($type, $lib, $pname, $sname, $chash) = ($dutypes{$1}, $2, $3, $4, $5);
                $lib = $libname if $lib eq 'work';
                push @{$cunit->{depends}}, Hardware::Vhdl::Automake::UnitName->new($type, $lib, $pname, $sname);
            } elsif ($a =~ m/^([EPCBv]) ((?:[A-Za-z][A-Za-z0-9_]*)|(?:\\.*?\\)) ((?:[A-Za-z][A-Za-z0-9_]*)|(?:\\.*?\\))( \S{22,22})?\s*$/) {
                my ($type, $lib, $pname, $chash) = ($dutypes{$1}, $2, $3, $4);
                $lib = $libname if $lib eq 'work';
                push @{$cunit->{depends}}, Hardware::Vhdl::Automake::UnitName->new($type, $lib, $pname);
            } else {
                die "unrecognised line format at $file line $.: '$p$a'; stopped";
            }                
        } elsif ($p eq 'F') {
            # the filename of the source code that was compiled into the current dunit
            $cunit->{source} = canonpath($a);
            $cunit->{source} = lc $cunit->{source} if File::Spec->case_tolerant();
        } elsif ($p eq 'n') {
            # the filename/dirname of the compiled dunit
            $cunit->{compiled_name} = $a;
        }
        last if ($line eq 'E_');
    }
    
    ($deps, $src2bin);
}


sub compiled_file {
    my $self = shift;
    my $dunit = shift;
    my $info = $dunit->get_compile_info(ref $self);
    return undef unless defined $info->{compiled_name};
    my $compiled_name = $info->{compiled_name};
    my $libdir = $self->{lib_mapping}{$dunit->library};
    my $cfile = undef;
    if ( $dunit->type eq 'architecture' ) {
        my $parent = $dunit->parent;
        if (defined $parent) {
            my $info = $parent->get_compile_info(ref $self);
            $cfile = catfile( $libdir, $info->{compiled_name}, $compiled_name . '.dat' ) if defined $info->{compiled_name};
        }
    } elsif ( $dunit->type eq 'package body' ) {
        my $parent = $dunit->parent;
        if (defined $parent) {
            my $info = $parent->get_compile_info(ref $self);
            $cfile = catfile( $libdir, $info->{compiled_name}, 'body.dat' ) if defined $info->{compiled_name};
        }
    } elsif ( $dunit->type eq 'Verilog unit' ) {
        $cfile = catfile( $libdir, $compiled_name, 'verilog.dat' );
    } else { # entity, package, configuration:
        $cfile = catfile( $libdir, $compiled_name, '_primary.dat' );
    }
    $cfile;
}

my $modelsim_filename_char_lookup;

sub name_to_filename {
    my $name = shift;
    my $file = '';
    if ( substr( $name, 0, 1 ) eq '\\' ) {
        for my $cc ( map { ord $_ } split( //, $name ) ) {
            my $rc = $modelsim_filename_char_lookup->[ $cc ];
            croak "Illegal character ($cc) in name '$name'" unless defined $rc;
            $file .= $rc;
        }
    } else {
        $file = lc $name;
    }
    $file;
}

# lookup table for ModelSim identifier->filename character translation
# undef means that that character is not allowed.
$modelsim_filename_char_lookup = [
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    '@040',
    '!',
    '@042',
    '#',
    '$',
    '%',
    '&',
    '\'',
    '(',
    ')',
    '@052',
    '+',
    ',',
    '-',
    '.',
    '@057',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '@072'
    ,    # character 072 actually seems to just get mapped to ':', but this crashes compiler with "Cannot open file" error
    ';',
    '@074',
    '=',
    '@076',
    '@077',
    '@@',
    '@a',
    '@b',
    '@c',
    '@d',
    '@e',
    '@f',
    '@g',
    '@h',
    '@i',
    '@j',
    '@k',
    '@l',
    '@m',
    '@n',
    '@o',
    '@p',
    '@q',
    '@r',
    '@s',
    '@t',
    '@u',
    '@v',
    '@w',
    '@x',
    '@y',
    '@z',
    '[',
    '@134',
    ']',
    '^',
    '_',
    '`',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '{',
    '@174',
    '}',
    '~',
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    undef,
    ' ',
    '¡',
    '¢',
    '£',
    '¤',
    '¥',
    '¦',
    '§',
    '¨',
    '©',
    'ª',
    '«',
    '¬',
    '­',
    '®',
    '¯',
    '°',
    '±',
    '²',
    '³',
    '´',
    'µ',
    '¶',
    '·',
    '¸',
    '¹',
    'º',
    '»',
    '¼',
    '½',
    '¾',
    '¿',
    'À',
    'Á',
    'Â',
    'Ã',
    'Ä',
    'Å',
    'Æ',
    'Ç',
    'È',
    'É',
    'Ê',
    'Ë',
    'Ì',
    'Í',
    'Î',
    'Ï',
    'Ğ',
    'Ñ',
    'Ò',
    'Ó',
    'Ô',
    'Õ',
    'Ö',
    '×',
    'Ø',
    'Ù',
    'Ú',
    'Û',
    'Ü',
    'İ',
    'Ş',
    'ß',
    'à',
    'á',
    'â',
    'ã',
    'ä',
    'å',
    'æ',
    'ç',
    'è',
    'é',
    'ê',
    'ë',
    'ì',
    'í',
    'î',
    'ï',
    'ğ',
    'ñ',
    'ò',
    'ó',
    'ô',
    'õ',
    'ö',
    '÷',
    'ø',
    'ù',
    'ú',
    'û',
    'ü',
    'ı',
    'ş',
    'ÿ'
];

1;
