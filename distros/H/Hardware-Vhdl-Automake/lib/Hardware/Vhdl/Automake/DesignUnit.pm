package Hardware::Vhdl::Automake::DesignUnit;
# just a holder of information, at the moment
use Hardware::Vhdl::Automake::UnitName;
use Carp;
use Hardware::Vhdl::Automake::PreProcessor;
use File::Copy;
use File::Temp qw/ tempfile /;
use File::Basename;
use Digest::MD5;

use strict;
use warnings;

sub new { # class or object method, returns a new object
	my $class = shift;
    my $arg1 = shift;
    
    $class = ref $class || $class;
	my $self={
        sourcefile => undef,
        file => undef,
        name => undef,
        compiler_options => {},
    };
    
    if (ref $arg1 eq 'HASH') {
        # check required args
        for my $argname (qw/ sourcefile type library pname line2source /) {
            croak "'$argname' parameter is required for new $class" unless exists $arg1->{$argname};
        }
        
        # create UnitName from given args
        eval {
            if (exists $arg1->{sname}) {
                $self->{name} = Hardware::Vhdl::Automake::UnitName->new($arg1->{type}, $arg1->{library}, $arg1->{pname}, $arg1->{sname});
                delete $arg1->{sname};
            } else {
                $self->{name} = Hardware::Vhdl::Automake::UnitName->new($arg1->{type}, $arg1->{library}, $arg1->{pname});
            }
        };
        croak $@ if $@;
        for my $argname (qw/ type library pname sname /) { delete $arg1->{$argname} }
        
        # copy other required args to self
        for my $argname (qw/ sourcefile file digest line2source compile_after /) {
            if (exists $arg1->{$argname}) {
                $self->{$argname} = $arg1->{$argname};
                delete $arg1->{$argname};
            } else {
                croak "$class->new requires a '$argname' argument";
            }
        }
        
        # copy these optional args to self if they are defined
        for my $argname (qw/ component_inserts entheader_start entheader_end entheader_startline /) {
            if (exists $arg1->{$argname}) {
                $self->{$argname} = $arg1->{$argname};
                delete $arg1->{$argname};
            }
        }
        # check there are no passed args left
        if (scalar keys %$arg1) { croak "unrecognised parameter(s) ".join(', ', keys %$arg1)." passed to Hardware::Vhdl::Automake::DesignUnit constructor" }
    } else {
        croak "${class}::new should be passed a hashref of information";
    }

	bless $self, $class;
}

sub set_compiler_option {
    my ($self, $compopt, $optval) = @_;
    $self->{compiler_options}{$compopt} = $optval;
}

sub get_compiler_option {
    my ($self, $compopt) = @_;
    defined $self->{compiler_options}{$compopt} ? $self->{compiler_options}{$compopt} : '';
}

sub line_to_source {
    # given a line number in the generated HDL, return the source file and line number it came from.
    my $self = shift;
    my $genline = shift;
    # line2source => [
    #     [ <hdl_line>, <source_file>, <source_line> ],
    #     [ <hdl_line>, <source_file>, <source_line> ],
    # ]
    my $n = @{$self->{line2source}}; # no. of entries in the lookup table
    if ($n>0) {
        my $i = 0;
        while ($i+1 < $n && $self->{line2source}[$i+1][0] <= $genline) { $i++ }
        ($self->{line2source}[$i][1], $self->{line2source}[$i][2] + $genline - $self->{line2source}[$i][0]);
    } else {
        (undef, 0);
    }
}

sub sourcefiles {
    my $self = shift;
    my @files = ($self->sourcefile->file);
    my %got = ( $files[0] => undef );
    for my $l2s (@{$self->{line2source}}) {
        if (!exists $got{$l2s->[1]}) {
            push @files, $got{$l2s->[1]};
            $got{$l2s->[1]} = undef;
        }
    }
    wantarray ? @files : \@files;
}

sub dump_l2s {
    my ($self, $where) = @_;
    print "##### $where, line2source =\n";
    for my $l2s (@{$self->{line2source}}) {
        print "# $l2s->[0] -> $l2s->[1] line $l2s->[2]\n";
    }
    print "#####\n";
}

sub _line_insert_prepare {
    my ($self, $insat) = @_;
    #$self->dump_l2s('before _line_insert_prepare');
    # prepare to add more hdl lines at hdl file line number $insat (do this before calls to _line_insert)
    my $n = @{$self->{line2source}}; # no. of entries in the lookup table
    my $i = 0;
    while ($i+1 < $n && $self->{line2source}[$i+1][0] <= $insat+1) { $i++ }
    if ($self->{line2source}[$i][0] != $insat+1) {
        splice @{$self->{line2source}}, $i+1, 0, [$insat+1, $self->line_to_source($insat+1)];
    }
    $self->{insat} = $insat;
    $self->{l2sii} = $i+1;
    #$self->dump_l2s('after _line_insert_prepare');
}

sub _line_insert {
    my ($self, $sfn, $sln) = @_;
    #print "# _line_insert at index $self->{l2sii}\n";
    splice @{$self->{line2source}}, $self->{l2sii}, 0, [$self->{line2source}[$self->{l2sii}][0], $sfn, $sln];
    $self->{l2sii}++;
    for my $i ($self->{l2sii} .. @{$self->{line2source}}-1) {
        $self->{line2source}[$i][0]++;
    }
    #$self->dump_l2s('after _line_insert');
}

sub _line_insert_complete {
    # tidy up after calls to _line_insert
    my ($self) = @_;
    delete $self->{insat};
    delete $self->{l2sii};
}

sub _tidy_line2source_table {
    my ($self) = @_;
    my $i = @{$self->{line2source}}-1;
    while ($i>0) {
        if ($self->{line2source}[$i][1] eq $self->{line2source}[$i-1][1]
         && ($self->{line2source}[$i][2]-$self->{line2source}[$i-1][2])==($self->{line2source}[$i][0]-$self->{line2source}[$i-1][0])
         ) {
            splice @{$self->{line2source}}, $i, 1;
        }
        $i--;
    }
    #$self->dump_l2s('after _tidy_line2source_table');
}

sub move_file {
    my $self = shift;
    my $newname = shift;
    croak "Can't move design unit HDL to '$newname': already exists as a directory" if -d $newname;
    croak "Can't move design unit HDL to '$newname': source file is missing" unless -f $self->file;
    copy($self->file, $newname) || croak "Failed to move design unit HDL to '$newname': $!";
    unlink $self->file || warn "Failed to delete temporary file '".$self->file."' for '".$self->name->short_string."': $!";
    carp "Failed to delete temporary file '".$self->file."': it's still there" if -f $self->file;
    $self->{file} = $newname;
}

sub copy_compiler_info_from {
    my ($self, $copyfrom) = @_;
    $self->{compile_info} = $copyfrom->{compile_info};
}

# accessor functions
sub name { $_[0]->{name} }
sub sourcefile { $_[0]->{sourcefile} }
sub file { $_[0]->{file} }
sub digest { $_[0]->{digest} }
sub compile_after { defined $_[0]->{compile_after} ? @{$_[0]->{compile_after}} : () }
sub parent { 
    my $self = shift;
    $self->{parent} = $_[0] if @_;
    $self->{parent};
}

sub type { $_[0]->{name}->type } # returns package, package body, entity, architecture, or configuration
sub library { $_[0]->{name}->library }
sub pname { $_[0]->{name}->pname }
sub sname { $_[0]->{name}->sname }

sub get_compile_info { defined $_[0]->{compile_info}{$_[1]} ? $_[0]->{compile_info}{$_[1]} : {} }
sub set_compile_info { $_[0]->{compile_info}{$_[1]} = $_[2] }

# generate phase 2 (insert component definitions) stuff

sub do_component_inserts {
    # insert component declarations into the arch or package body hdl, taken from the entity declarations
    my ($self, $status_callback, $ent_dunit_finder) = @_;
    my $ci = $self->{component_inserts};
    return unless defined $ci && @$ci>0;
    
    &{$status_callback}({
        type    => 'generate2',
        text    => 'Generating (pass 2)',
        duname  => $self->name,
    }) if defined $status_callback;
        
    # create new digest object
    # open original dunit file for reading
    my $fhi;
    open $fhi, '<', $self->{file} || die "Could not read phase 1 HDL file: $!";
    # create new temp file
    my ($fho, $newfile) = tempfile( "XXXXXXXX", DIR => dirname($self->{file}) );
    my $digester = Digest::MD5->new;
    for my $cii (@$ci) {
        my ($pos, $linenum, $digest_at_insert, $lib, $pname) = @$cii;
        # find the entity dunit from which we need to insert
        my $ent_dunit = $ent_dunit_finder->($lib, $pname);
        $self->_component_insert_error($status_callback, $linenum, "Component insertion error; entity $lib.$pname not found in project") unless defined $ent_dunit;
        my $entstart = $ent_dunit->{entheader_start};
        $self->_component_insert_error($status_callback, $linenum, "Component insertion error; declaration of $lib.$pname was not found in entity HDL") unless defined $entstart;
        my $entend   = $ent_dunit->{entheader_end};
        $self->_component_insert_error($status_callback, $linenum, "Component insertion error; end of declaration of $lib.$pname was not found in entity HDL") unless defined $entend;

        # copy from fi to fo up to position $pos
        &_copy_part_file($fho, $fhi, $pos);
        $self->_line_insert_prepare($linenum);
        # feed $digest_at_insert into digester
        $digester->add('--insert_at:'.$digest_at_insert.':');
        # output a newline to fo
        print $fho "\ncomponent $pname\n";
        my @insert_command_pos = $self->line_to_source($linenum);
        $self->_line_insert(@insert_command_pos);
        # open the hdl file for the entity
        my $linesource = Hardware::Vhdl::Automake::PreProcessor->new(no_processing => 1, sourcefile => $ent_dunit->file, startat => $entstart, endat => $entend, linenum => $ent_dunit->{entheader_startline});
        my $lexer = Hardware::Vhdl::Lexer->new({linesource => $linesource});
        my $head = '';
        my ($token, $type);
        while( (($token, $type) = $lexer->get_next_token) && defined $token) {
            #diag("$type: '$token'");
            if (substr($type, 0, 1) eq 'c') {
                $digester->add($token.' ');
            } elsif ($type eq 'wn') {
                $digester->add(chr(13));
                $self->_line_insert($ent_dunit->line_to_source($linesource->linenum));
            }
            print $fho $token;
            # feed token into digester if (substr($type, 0, 1) eq 'c');
        }
        $self->_line_insert($ent_dunit->line_to_source($linesource->linenum));
        print $fho "\nend component;";
        $self->_line_insert(@insert_command_pos);

        # adjust line number refs
        $self->_line_insert_complete;
    }
    &_copy_part_file($fho, $fhi, -s $self->{file});
    # delete original dunit file, replace dunit file by temp file
    close $fhi;
    close $fho;
    rename($newfile, $self->{file}) || die "Could not replace pass 1 HDL file: $!";
    # append digest
    $self->{digest} .= $digester->hexdigest;
    $self->_tidy_line2source_table;
    delete $self->{component_inserts};
}

sub entity_instance {
    # if the design unit is an entity, feeds a component instantiation template into the function referenced by $add_output
    my ($self, $add_output) = @_;
    if ($self->name->type eq 'entity') {
        my $entstart = $self->{entheader_start};
        my $entend   = $self->{entheader_end};
        unless (defined $entstart && defined $entend) {
            &{$add_output}("-- Instantiation template insertion error; declaration of ".$self->name->short_string." was not found in entity HDL\n");
            return;
        }            
        &{$add_output}('    '.$self->name->pname.'_i : '.$self->name->pname.' ');
        # open the hdl file for the entity
        my $linesource = Hardware::Vhdl::Automake::PreProcessor->new(no_processing => 1, sourcefile => $self->file, startat => $entstart, endat => $entend, linenum => $self->{entheader_startline});
        my $tp = Hardware::Vhdl::Lexer->new({linesource => $linesource});
        my $bd=0; # bracket depth
        my $intype=0; # are we after the colon in the "identifiers : type" structure?
        my @ids;
        my $typeetc = '';
        my ($tok, $tt);
        while ((($tok, $tt) = $tp->get_next_token) && defined $tok) {
            #print " $bd $tt: '$tok'\n";
            my $end=0;
            if ($tt eq 'cp') {
                if ($tok eq '(') {
                    $bd++;
                }
                elsif ($tok eq ')') { $bd--; $end=1 if $bd==0; }
                elsif ($bd==1 && $tok eq ';') { $intype=0; $end=2 }
                elsif ($bd==1 && $tok eq ':') { $intype=1 }
            }
            if ($end) {
                $end += @ids;
                for my $id (@ids) {
                    &{$add_output}("        $id => $id".($end==2 ? '' : ',')." --$typeetc\n");
                    $end--;
                }
                @ids=();
                $typeetc='';
                $intype=0;
            }
            if ($bd==0) {
                #&{$add_output}($tok) unless $tok eq ';';
                if ($tok =~ /^(generic|port)$/i) { &{$add_output}("\n      ".lc($tok)." map (\n") }
                elsif ($tok eq ')') { &{$add_output}('      ) ') }
            } elsif ($intype) {
                $typeetc .= $tt eq 'wn' ? ' ' : $tok;
            } elsif ($tt eq 'ci' && $bd==1) {
                push @ids, $tok;
            } elsif ($tt eq 'r' && @ids==0) {
                &{$add_output}("        $tok\n");
            }
        }
        &{$add_output}(";\n");
    }
}

sub _copy_part_file {
    my ($fho, $fhi, $upto) = @_;
    while (1) {
        my $nget = $upto - tell($fhi);
        last if $nget <= 0 || eof($fhi);
        $nget = 16000 if $nget > 16000;
        local $/ = \$nget;
        my $buf = readline($fhi);
        print $fho $buf;
    }
}

sub _component_insert_error {
    my ($dunit, $status_callback, $linenum, $err) = @_;
    my $report = {
        type    => 'error',
        text    => $err,
        duname  => $dunit->name,
        genfile    => $dunit->file,
        genlinenum => $linenum,
    };
    my ($lfn, $lln) = $dunit->line_to_source($report->{genlinenum});
    if (defined $lfn) {
        $report->{srcfile} = $lfn;
        $report->{srclinenum} = $lln;
    }
    &$status_callback($report);
    croak $err;
}

1;