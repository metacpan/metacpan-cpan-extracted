package Hardware::Vhdl::Automake::SourceFile;

use Hardware::Vhdl::Automake::DesignUnit;
use Hardware::Vhdl::Lexer;
use Hardware::Vhdl::Automake::PreProcessor;
use File::Temp qw/tempfile/;
use Digest::MD5;
use Carp;

use strict;
use warnings;

sub _mod_time_of_file {
    my $file = shift;
    # -M  Script start time minus file modification time, in days.
    # $^T The time at which the program began running, in seconds since the epoch (beginning of 1970). The values returned by the -M, -A, and -C filetests are based on this value. 
    my $age = -M $file;
    if (!defined $age) { return undef; }
    if (!defined $age) {
        warn "error in _mod_time_of_file";
        for my $depth (0..4) {
            my ($package, $filename, $line) = caller $depth;
            warn " called at $filename line $line\n";
        }
        croak "file age of '$file' not found";
    }
    return $^T - 86400*$age;
}

sub new { # class or object method, returns a new object
    my $class = shift;
    my $arg1 = shift;
    
    $class = ref $class || $class;
    my $self={
        file => undef,
        language => undef,
        library => 'work',
        dunits => [],
        # generate_phase1 args
        generate_as => 'file', # 'string', 'file' or 'none'
        generate_in => undef, # save design unit code in these dirs if defined, else a temp. dir
        calc_md5 => 0,
        filewide_libs => 0,
        gen_dunits => [],
    };
    
    if (ref $arg1 eq 'HASH') {
        # copy args to self
        for my $argname (qw/ file language library generate_as calc_md5 /) {
            if (exists $arg1->{$argname}) {
                $self->{$argname} = $arg1->{$argname};
                delete $arg1->{$argname};
            }
        }
        # check there are no passed args left
        if (scalar keys %$arg1) { croak "unrecognised parameter(s) ".join(', ', keys %$arg1)." passed" }
    } else {
        $self->{file} = $arg1;
    }
    
    #! TODO: check $self->file is defined and is a valid filename
    if (!defined $self->{language}) {
        if ($self->{file} =~ /\.vhdl?$/i) { $self->{language} = 'VHDL' }
        if ($self->{file} =~ /\.v(lg)?$/i) { $self->{language} = 'Verilog' }
    }

	bless $self, $class;
}

sub DESTROY {
    my $self = shift;
    # attempt to ensure that no circular references (SourceFile->DesignUnit->SourceFile) are left
    $self->{gen_dunits} = undef;
}

sub _output_code {
    die "not implemented";
    &_output_token(@_);
}

sub _output_token {
    my ($self, $token, $type) = @_;
    if (substr($type, 0, 1) eq 'c') {
        $self->{current_dunit}{digester}->add($token.' ');
        $self->{current_dunit}{ncode} ++;
    } elsif ($type eq 'wn') {
        $self->{current_dunit}{digester}->add(chr(13));
    }
    if ($self->{generate_as} eq 'string') {
        $self->{current_dunit}{vcode} .= $token;
    } elsif ($self->{generate_as} eq 'file') {
        my $fh = $self->{outfh};
        print $fh $token;
    }
}

sub designunits {
    my $self=shift;
    @{$self->{dunits}};
}

sub file     { $_[0]->{file}     }
sub language { $_[0]->{language} }
sub library  { $_[0]->{library}  }

sub sourcefiles_unchanged {
    # returns true if the source file, and any files it includes, are unchanged since the last time hdl was generated
    my $self = shift;
    #return 0 if (!(defined $self->{source_mtime} && -f $self->file && ($^T - 86400*(-M $self->file)) <= $self->{source_mtime}));
    my ($file, $mtime);
    DEPFILE: while ( ($file, $mtime) = each %{$self->{depfile_mtime}} ) {
        if (!defined $mtime) {
            print "no m-time known for '$file'\n";
            return 0;
        }
        if (!-f $file) {
            print "file '$file' is missing\n";
            return 0;
        }
        if (_mod_time_of_file($file) > $mtime) {
            print "file '$file' has changed (according to timestamp)\n";
            #~ print "actual timestamp is "._mod_time_of_file($file).", recorded timestamp is $mtime\n" if $file =~ /n_uart_a_tb_funcs\.vhd$/i;
            return 0;
        }
    }
    # all dependency files are present and not changed
    return 1;
}

sub all_generated_dunits_present {
    my $self = shift;
    my $all_present = 1;
    for my $dunit (@{$self->{dunits}}) {
        if (!-f $dunit->file) { $all_present=0; last; }
    }
    $all_present;
}

sub generate_phase1 {
    my ($self, $report_callback, $tempdir) = @_;
    my $uptodate = 1;
    my $reason = '';
    unless (exists $self->{dunits} && @{$self->{dunits}}>0) {
        $reason = "there are no generated dunits for this sourcefile: need to generate";
        $uptodate = 0;
    }
    if ($uptodate && !$self->sourcefiles_unchanged) {
        $reason = "a dependency for this sourcefile has changed: need to generate";
        $uptodate = 0;
    }
    if ($uptodate && !$self->all_generated_dunits_present) {
        $reason = "not all generated dunits for this sourcefile are still present: need to generate";
        $uptodate = 0;
    }
    if ($uptodate) {
        $reason = "up to date - not generating";
        return;
    }
    $self->{gen_dunits} = [];
    $self->{tempdir} = $tempdir;
    
    &{$report_callback}({
        type    => 'generate1',
        text    => 'Generating (pass 1)',
        file    => $self->file,
        reason  => $reason,
    }) if defined $report_callback;

    $self->{compiler_options} = {
            vhdl_language_version => '93', # should be '87' or '93'
            check_for_synthesis => 0, # Turns on limited synthesis rule compliance checking. Checks to see that signals read by a process are in the sensitivity list.
            generate_default_binding => 1, # Instructs the compiler not to generate a default binding during compilation. You must explicitly bind all components in the design if you set this to false.
            prefer_explicit_function_definition => 0, # Directs the compiler to resolve ambiguous function overloading by favoring the explicit function definition over the implicit function definition.
            ignore_vital_errors => 0, # Directs the compiler to ignore VITAL compliance error
            use_builtin_1164 => 1, # Causes the source files to be compiled taking advantage of the built-in version of the IEEE std_logic_1164 package.
            run_time_range_checks => 1, # In some designs, this could result in a 2X speed increase.
            hide_internal_data => 0, # Hides the internal data of the compiled design unit
            use_builtin_vital => 1, # If disabled, causes VCOM to use VHDL code for VITAL procedures rather than the accelerated and optimized timing and primitive packages built into the simulator kernel. Optional.
            vital95_check => 1, # If disabled, disables VITAL95 compliance checking if you are using VITAL 2.2b.
            error_case_static => 1, # Changes case static warnings into errors.
            error_others_static => 1, # Enables errors that result from "others" clauses that are not locally static.
            warn_unbound_component => 1,
            warn_process_without_wait => 1,
            warn_null_range => 1,
            warn_no_space_in_time_literal => 1,
            warn_multiple_drivers_on_unresolved_signal => 1,
            warn_compliance => 1,
            warn_optimization => 1,
            perform_default_binding => 0, # Enables default binding when it has been disabled via the RequireConfigForAllDefaultBinding option in the modelsim.ini file.
        };

    $self->_generate_dunits($report_callback);
    
    $self->{dunits} = $self->{gen_dunits};
    delete $self->{gen_dunits};
    delete $self->{tempdir};
    delete $self->{outfh};
    delete $self->{compiler_options};
    
    $self->{source_mtime} = _mod_time_of_file($self->file);
}

# this regex pattern captures a VHDL name (use inside brackets): 
my $vhdlnamere = '(?:[A-Za-z][A-Za-z0-9_]*)|(?:\\\\.*?\\\\)';

sub _dunit_break {
    my ($self, $token_q, $n, $report_callback) = @_;
    $self->_flush_tokens($token_q, $n);
    $self->_new_dunit($report_callback);
}

sub _flush_tokens {
    # flush the token output queue. leaving the last $n Code tokens (type starts with 'c') in the queue
    my ($self, $token_q, $n) = @_;
    # at what index do the tokens in the queue start to belong to the next dunit rather than the current one?  answer->$i
    my $i = @{$token_q};
    while ($n>0 && $i>0) {
        $n-- if substr($token_q->[--$i][1], 0, 1) eq 'c';
    }
    # output those tokens to the current dunit
    for my $j (0..$i-1) {
        $self->_output_token(@{shift @$token_q});
    }
}

sub _generate_dunits {
    my ($self, $report_callback) = @_;
    my $linesource = Hardware::Vhdl::Automake::PreProcessor->new(sourcefile => $self->{file});
    my $lexer = Hardware::Vhdl::Lexer->new({linesource => $linesource, nhistory => 8});
    #~ print "#- generating design units from ".$linesource->sourcefile."\n";
    
    # now start parsing the source file
    my ($token, $type, $basetype);
    my $begun = 0; # track whether we have seen a 'begin' in the current design unit
    $self->_new_dunit($report_callback);
    my @tokens = (); # delayed token output queue
    while (1) {
        eval {
            ($token, $type) = $lexer->get_next_token;
        };
        if ($@) {
            croak "Lexer or preprocessor error at ". $linesource->sourcefile . " line " . $linesource->linenum . ": $@\n";
        }
        last if (!defined $token);
        $basetype = substr($type, 0, 1);
        $self->_output_token(@{shift @tokens}) while @tokens > 20;
        if ($type eq 'wn') {
            # newline in source file
            my $lln = $linesource->linenum;
            my $lfn = $linesource->sourcefile;
            unless ($self->{current_dunit}{linenum_in} == $lln && $self->{current_dunit}{sourcefile} eq $lfn) {
                push @{$self->{current_dunit}{line2source}}, [$self->{current_dunit}{linenum_out}, $lfn, $lln];
                $self->{current_dunit}{linenum_in} = $lln;
                $self->{current_dunit}{sourcefile} = $lfn;
            }
            push @tokens, ["\n", 'wn']; # output a system-standard newline
            $self->{current_dunit}{linenum_in} ++;
            $self->{current_dunit}{linenum_out} ++;
        } else {
            push @tokens, [$token, $type];
        }
        if ($basetype eq 'r' && $token =~ /^ \s* --< \s* compiler_option \s+ (\S+) \s* (\S+) \s* >(--.*) $/xi) {
            # a compiler option change
            $self->{compiler_options}{lc $1} = $2;
            #print "# setting compiler option '$1' to '$2'\n";
        } elsif ($basetype eq 'r' && $self->{current_dunit}{type} ne '' && $token =~ /^ \s* --< \s* component  \s+ ($vhdlnamere) \s* \. \s* ($vhdlnamere) \s* >(--.*) $/xi) {
            # request to insert a component declaration here: remember the details, we'll do it during phase 2
            my ($lib, $pname, $rem) = ($1, $2, $3);
            $self->_flush_tokens(\@tokens, 0);
            die "assertion failed" unless @tokens == 0;
            my $startdigest = $self->{current_dunit}{digester}->clone->hexdigest;
            push @{$self->{current_dunit}{component_inserts}}, [tell $self->{outfh}, $self->{current_dunit}{linenum_out}, $startdigest, $lib, $pname];
        } elsif ($basetype eq 'c') {
            my @hist;
            $hist[3] = $lexer->history(2).' '.$lexer->history(1).' '.$lexer->history(0);
            for my $i (4..8) {
                $hist[$i] = $lexer->history($i-1).' '.$hist[$i-1];
            }
            
            if ($self->{current_dunit}{type} ne '') {
                # we are inside a design unit at the moment
                
                # if we see a 'use' or 'library' statement, we must have finished the current design unit, so start a new one
                my $n = 0;
                $n = 7 if $hist[8] =~ m/[ ;] use ($vhdlnamere) \. ($vhdlnamere) \. ($vhdlnamere) ;$/i;
                $n = 5 if $hist[8] =~ m/[ ;] use ($vhdlnamere) \. ($vhdlnamere) ;$/i;
                $n = 3 if $hist[8] =~ m/[ ;] library ($vhdlnamere) ;$/i;
                if ($n > 0) {
                        # we must be outside a dunit now
                        #print "# Found end of $self->{current_dunit}{type} $self->{current_dunit}{pname} at line ".($linesource->linenum)."\n";
                        $self->_dunit_break(\@tokens, $n, $report_callback);
                }

                my $bd = $self->{current_dunit}{brackdepth};
                
                if ($self->{current_dunit}{type} eq 'entity' && !defined $self->{current_dunit}{entheader_start}) {
                    $self->_flush_tokens(\@tokens, 1);
                    $self->{current_dunit}{entheader_start} = tell $self->{outfh};
                    $self->{current_dunit}{entheader_startline} = $self->{current_dunit}{linenum_out};
                } elsif (defined $self->{current_dunit}{entheader_start} && !defined $self->{current_dunit}{entheader_end}
                 && $bd==0 && lc $token ne 'generic' && lc $token ne 'port' && $token ne '(' && $token ne ';') {
                    $self->_flush_tokens(\@tokens, 1);
                    $self->{current_dunit}{entheader_end} = tell $self->{outfh};
                }
                
                if ($token eq '(') {
                    $self->{current_dunit}{brackdepth} ++;
                } elsif ($token eq ')' && $bd>0) {
                    $self->{current_dunit}{brackdepth} --;
                } elsif ($token eq 'begin' && $bd==0) {
                    $self->{current_dunit}{begun} = 1;
                }
            }
            
            if ($hist[8] =~ m/[ ;] use ($vhdlnamere) \. ($vhdlnamere) \. ($vhdlnamere) ;$/i) {
                my ($lib, $pname) = ($1, $2);
                if (lc $lib eq 'work') { $lib = $self->library }
                #print "# Found lib use of '$lib' . '$pname' at line ".($linesource->linenum)."\n";
                push @{$self->{current_dunit}{compile_after}}, new Hardware::Vhdl::Automake::UnitName('package', $lib, $pname);
            } elsif ($hist[6] =~ m/ ;? (entity|package|package body) ($vhdlnamere) is$/i) {
                # start of entity/package/package body
                my ($type, $pname) = (lc $1, $2);
                #print "# Found start of $type $pname at line ".($linesource->linenum)."\n";
                if ($self->{current_dunit}{type} ne '') {
                    $self->_dunit_break(\@tokens, $type eq 'package body' ? 4 : 3, $report_callback);
                    $self->_new_dunit($report_callback);
                }
                $self->{current_dunit}{type} = $type;
                $self->{current_dunit}{pname} = $pname;
            } elsif (lc $token eq 'is' && $lexer->history(5) =~ m/^;?$/ && $lexer->history(4) =~ m/^(configuration|architecture)$/i && lc $lexer->history(2) eq 'of') {
                # start of configuration or architecture
                if ($self->{current_dunit}{type}) {
                    $self->_dunit_break(\@tokens, 5, $report_callback);
                    $self->_new_dunit($report_callback);
                }
                $self->{current_dunit}{type} = lc $lexer->history(4);
                if ($lexer->history(4) =~ /^a/i) {
                    # it's an architecture
                    $self->{current_dunit}{sname} = $lexer->history(3);
                    $self->{current_dunit}{pname} = $lexer->history(1);
                } else {
                    # it's a configuration
                    $self->{current_dunit}{pname} = $lexer->history(3);
                }
                $begun = 0;
                #print "# Found start of $self->{current_dunit}{type} $self->{current_dunit}{pname} at line ".($linesource->linenum)."\n";
            }
            
        }
    }
    $self->_output_token(@{shift @tokens}) while @tokens;
    $self->_new_dunit($report_callback, 1);
    #print "#- finished generating design units at line ".$linesource->linenum." of ".$linesource->sourcefile."\n";
    delete $self->{current_dunit};
    
    $self->{depfile_mtime} = {};
    for my $file ($linesource->files_used) {
        #~ print "file used: $file\n" if $linesource->sourcefile;
        my $timestamp = _mod_time_of_file($file);
        $self->{depfile_mtime}{$file} = $timestamp if defined $timestamp;
        #~ print "recorded timestamp of $file as $timestamp\n" if  $linesource->sourcefile =~ /app_and_abridge_tb\.vhd$/i;
    }
}

sub _new_dunit {
    my ($self, $report_callback, $last) = @_;
    if (exists $self->{current_dunit}) {
        close $self->{outfh} if defined $self->{outfh};
        delete $self->{outfh};
        if (defined $self->{current_dunit} && $self->{current_dunit}{type}) {
            # add compiler options to the digest
            my ($compopt, $optval);
            for $compopt ( sort keys %{$self->{compiler_options}}) {
                $optval = $self->{compiler_options}{$compopt};
                $self->{current_dunit}{digester}->add("--< compiler_option $compopt $optval >--");
            }

            my $dunit = new Hardware::Vhdl::Automake::DesignUnit({
                sourcefile => $self, 
                library => $self->library, 
                file => $self->{current_dunit}{file}, 
                type => $self->{current_dunit}{type}, 
                pname => $self->{current_dunit}{pname},
                sname => $self->{current_dunit}{sname},
                digest => $self->{current_dunit}{digester}->hexdigest,
                line2source => $self->{current_dunit}{line2source},
                compile_after => $self->{current_dunit}{compile_after},
                component_inserts => $self->{current_dunit}{component_inserts},
                entheader_start => $self->{current_dunit}{entheader_start},
                entheader_end => $self->{current_dunit}{entheader_end},
                entheader_startline => $self->{current_dunit}{entheader_startline},
                #entheader_sourcefile => $self->{current_dunit}{entheader_sourcefile},
            });
            while (($compopt, $optval) = each %{$self->{compiler_options}}) {
                $dunit->set_compiler_option($compopt, $optval);
            }
            push @{$self->{gen_dunits}}, $dunit;
            &$report_callback({
                    type    => 'generated',
                    text    => 'New design unit code generated',
                    duname  => @{$self->{gen_dunits}}[-1]->name,
                }) if defined $report_callback;
        } else {
            if ($self->{current_dunit}{ncode} != 0) {
                local $/ = undef;
                my $fh;
                open $fh, '<', $self->{current_dunit}{file};
                print "--- code left over:\n";
                print <$fh>;
                close $fh;
                carp "code left over from ".$self->{current_dunit}{line2source}[0][1]." line ".$self->{current_dunit}{line2source}[0][2]."\n";
            };
            if (defined $self->{current_dunit}{file} && -f $self->{current_dunit}{file}) {
                unlink $self->{current_dunit}{file} || die "unlink of '$self->{current_dunit}{file}' failed";
                -f $self->{current_dunit}{file} && die "unlink of '$self->{current_dunit}{file}' succeeded but file is still there";
            }
        }
    }
    if ($last) {
        delete $self->{current_dunit};
    } else {
        $self->{current_dunit} = {
            type => '', 
            name => undef, 
            lib_refs => [],
            digester => Digest::MD5->new,
            sourcefile => '',
            ncode => 0,
            linenum_in => 0,
            linenum_out => 1,
            compile_after => [],
            begun => 0, # have we seen a 'begin' token for the current dunit?
            brackdepth => 0, # how deep in nested brackets are we?
        };
        $self->{current_dunit}{vcode} = '' if ($self->{generate_as} eq 'string');
        if ($self->{generate_as} eq 'file') {
            ($self->{outfh}, $self->{current_dunit}{file}) = tempfile( "genhdl_XXXXXXXX", SUFFIX => '.vhd', UNLINK => 1, DIR => $self->{tempdir});
        }
    }
    $self->{current_dunit};
}

sub generate_phase1_fake {
    my ($self) = @_;
    return if ($self->sourcefiles_unchanged && $self->all_generated_dunits_present);
    
    # read source file, write an hdl file for each, in a temporary location
    # remember the components that each dunit declares, if any
    # remember mtime of sourcefile and its included files
    $self->{dunits} = [];
    push @{$self->{dunits}}, new Hardware::Vhdl::Automake::DesignUnit({ sourcefile => $self, type => 'entity', name => 'small' });
    push @{$self->{dunits}}, new Hardware::Vhdl::Automake::DesignUnit({ sourcefile => $self, type => 'architecture', name => 'tiddly', pname => 'small' });
}

sub id_match {
    # return boolean indicating whether the two VHDL indentifiers passed are the same
    substr($_[0], 0, 1) eq '\\' ?
        $_[0] eq $_[1] :
        lc $_[0] eq lc $_[1];
}

1;