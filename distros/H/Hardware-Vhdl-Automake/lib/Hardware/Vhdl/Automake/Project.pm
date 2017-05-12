package Hardware::Vhdl::Automake::Project;
use Hardware::Vhdl::Automake::SourceFile;
use Hardware::Vhdl::Automake::DesignUnit;
use File::Spec::Functions;
use File::Path;
use File::Temp qw/ tempfile tempdir /;
use Carp;
use YAML;

use strict;
use warnings;

our $VERSION = "1.00";

sub new { # class or object method, returns a new project object
    my $class=shift;
    $class = ref $class || $class;
    my $self={
        sourcefiles => [],
        dunits => {},
        projectfile => undef,
        hdldir => undef,
        status_callback => undef,
    };
    bless $self, $class;
}

sub set_status_callback {
    my $self = shift;
    $self->{status_callback} = shift;
}

sub report_status {
    my $self = shift;
    &{$self->{status_callback}}(@_) if defined $self->{status_callback};
}

sub save {
    my $self=shift;
    my $saveas = shift;
    $self->{projectfile} = $saveas if defined $saveas;
    croak "Project filename not given" unless defined $self->{projectfile};
    if (-f $self->{projectfile}) { rename $self->{projectfile}, $self->{projectfile}.".backup" }
    YAML::DumpFile($self->{projectfile}, $self);
}

sub load {
    my $self=shift;
    my $loadfrom = shift;
    croak "Project filename not given" unless defined $loadfrom;
    for my $k (keys %$self) {
        delete $self->{$k};
    }
    my ($data) = YAML::LoadFile($loadfrom);
    #TODO! check loaded data is valid
    for my $k (keys %$data) {
        $self->{$k} = $data->{$k};
        delete $data->{$k};
    }
    $self->{projectfile} = $loadfrom;
}

sub hdl_dir { # getter/setter method.  default hdl dir is {save filename}.'_files'
    my $self = shift;
    $self->{hdl_dir} = shift if @_;
    $self->{hdl_dir};
}

sub project_file { # getter/setter method.  file is also changed by load/save with parameter
    my $self = shift;
    $self->{projectfile} = shift if @_;
    $self->{projectfile};    
}

sub add_sourcefiles {
    my $self=shift;
    for my $sourcespec (@_) {
        push @{$self->{sourcefiles}}, new Hardware::Vhdl::Automake::SourceFile($sourcespec);
        #!TODO: check for source file duplication?
    }
}

sub remove_sourcefiles {
    my $self=shift;
    for my $sourceobj (@_) {
        my $srch = "$sourceobj";
        my $n = @{$self->{sourcefiles}};
        @{$self->{sourcefiles}} = grep { "$_" ne $srch } @{$self->{sourcefiles}};
        croak "Source file '".$sourceobj->file."' was not removed from the project because it was not found." if $n == @{$self->{sourcefiles}}; 
    }
}

sub sourcefiles {
    my $self=shift;
    @{$self->{sourcefiles}};
}

sub designunits {
    my $self=shift;
    values %{$self->{dunits}};
}

sub packages {
    my $self=shift;
    grep { $_->type eq 'package' } $self->designunits;
}

sub package_bodies {
    my $self=shift;
    grep { $_->type eq 'package body' } $self->designunits;
}

sub entities {
    my $self=shift;
    grep { $_->type eq 'entity' } $self->designunits;
}

sub architectures {
    my $self=shift;
    grep { $_->type eq 'architecture' } $self->designunits;
}

sub configurations {
    my $self=shift;
    grep { $_->type eq 'configuration' } $self->designunits;
}

sub generate_all {
    my $self = shift;
    croak "project's hdl_dir needs to be set before attempting generate_all" unless defined $self->hdl_dir;
    
    $self->{dunits_prev} = $self->{dunits};
    $self->{dunits} = {};
        
    unless (defined $self->{gen1_tempdir} && -d $self->{gen1_tempdir}) {
        $self->{gen1_tempdir} = tempdir("temp_XXXXXXXX", DIR => $self->hdl_dir, CLEANUP => 1);
    }
    
    for my $sourcefile (@{$self->{sourcefiles}}) {
        eval {
            $self->report_status({
                    type    => 'generate1poss',
                    text    => 'Considering generating (pass 1)',
                    file    => $sourcefile->file,
                });
            $sourcefile->generate_phase1($self->{status_callback}, $self->{gen1_tempdir});
        };
        my $err = $@;
        if ($err) {
            $self->report_status({
                    type    => 'generate1_error',
                    text    => "Error while generating (pass 1): $err",
                    file    => $sourcefile->file,
                });
            $self->{dunits} = $self->{dunits_prev};
            delete $sourcefile->{outfh};
            delete $self->{dunits_prev};
            return 0;
        }
        $self->add_dunits($sourcefile->designunits);
    }

    {
        # insert component declarations into the arch or package body hdl, taken from the entity declarations
        my $ent_dunit_finder = sub { $self->find_dunit_by_short_name(Hardware::Vhdl::Automake::UnitName->new('entity', $_[0], $_[1])->short_string) };
        for my $dunit ($self->architectures, $self->package_bodies) {
            $self->report_status({
                    type    => 'generate2poss',
                    text    => 'Considering generating (pass 2)',
                    duname  => $dunit->name,
                });
            $dunit->do_component_inserts($self->{status_callback}, $ent_dunit_finder);
        }
    }
    
    for my $dunit ($self->designunits) {
        #my $file = name2file($dunit->type).(defined $dunit->pname ? ' '.name2file($dunit->pname) : '').' '.name2file($dunit->sname);
        my $file = $dunit->name->filename_string;
        {
            my $lang = $dunit->sourcefile->language;
            if ($lang =~ m/^VHDL/i) {
                $file .= '.vhd'
            } elsif ($lang =~ m/^Verilog/i) {
                $file .= '.v'
            }
        }
        my $path = $self->hdl_dir; #catdir($self->hdl_dir, name2file($dunit->name->library_dirname_string)); 
        $file = catfile($path, $file); 
        if ($dunit->file ne $file) {
            $self->report_status({
                    type    => 'hdl_copy',
                    text    => 'New design unit code copied to HDL dir',
                    duname  => $dunit->name,
                    file    => $file,
                });
            mkpath $path;
            $dunit->move_file($file);
        }
    }
    
    for my $old_dunit (values %{$self->{dunits_prev}}) {
        my $new_dunit = $self->find_matching_dunit($old_dunit);
        if (defined $new_dunit) { 
            $new_dunit->copy_compiler_info_from($old_dunit);
        } else {
            # delete stuff relating to old dunit, no longer present
            unlink $old_dunit->file;
        }
    }
    delete $self->{dunits_prev};
    1;
}

sub add_dunits {
    my $self = shift;
    for my $du (@_) {
        my $k = $du->name->short_string;
        if (exists $self->{dunits}{$k}) {
            #TODO: check for duplicate definitions of dunit?
            carp "There seem to be duplicate definitions of $k"
        }
        $self->{dunits}{$k} = $du;
    }
}

sub find_matching_dunit {
    my $self = shift;
    my $search_dunit = shift;
    my $k = $search_dunit->name->short_string;
    exists $self->{dunits}{$k} ? $self->{dunits}{$k} : undef;
}

sub find_dunit_by_name {
    my $self = shift;
    my $duname = shift;
    my $k = $duname->short_string;
    exists $self->{dunits}{$k} ? $self->{dunits}{$k} : undef;
}

sub find_dunit_by_short_name {
    my $self = shift;
    my $k = shift;
    exists $self->{dunits}{$k} ? $self->{dunits}{$k} : undef;
}

sub libraries {
    my $self = shift;
    my %libs;
    for my $dunit (values %{$self->{dunits}}) {
        $libs{$dunit->name->library} = undef;
    }
    keys %libs;
}

sub find_parents {
    my $self = shift;
    # for design units of type package_body or architecture, set the 'parent' attribute to be the matching primary design unit
    for my $dunit ( $self->architectures ) {
        $dunit->parent($self->find_dunit_by_name(Hardware::Vhdl::Automake::UnitName->new('entity', $dunit->library, $dunit->pname)));
    }
    for my $dunit ($self->package_bodies ) {
        $dunit->parent($self->find_dunit_by_name(Hardware::Vhdl::Automake::UnitName->new('package', $dunit->library, $dunit->pname)));
    }
}

=for notes
    New Compile algorithm.
    Create a mapping of hdl files to design-unit objects (or duname objects)
    from _info files get a mapping from each hdl file to a binary file, and a list of dunit names of dependencies
    convert this into a mapping from each DUnit object to a binary file and a list of references to dependency DUnit objects
    recompile a dunit if its hdl has changed, or if its binary file is older than the binary file for any of its dependencies.
=cut

sub compile {
    my $self = shift;
    my $tool = shift;
    $self->find_parents;
    $tool->compile_start;
    eval {
        for my $lib ($self->libraries) {
            $tool->ensure_library($lib);
        }
        
        my ($hdl2bin, $hdl2deps) = $tool->get_deps;
        
        for my $dunit ($self->designunits) {
            my $hdlfile = canonpath($dunit->file);
            $hdlfile = lc $hdlfile if File::Spec->case_tolerant();
            
            # tell the dunit what its compiled name is and what its dependencies are
            my $info = $dunit->get_compile_info($tool->toolid);
                
            $info->{compiled_name} = defined $hdl2bin->{$hdlfile} ? $hdl2bin->{$hdlfile} : undef;
            
            $info->{dependencies} = [];
            if (defined $hdl2deps->{$hdlfile}) {
                for my $depname (@{$hdl2deps->{$hdlfile}}) {
                    my $depdunit = $self->find_dunit_by_name($depname);
                    push @{$info->{dependencies}}, $depdunit if defined $depdunit;
                }
            }
            
            for my $depname ($dunit->compile_after) {
                my $depdunit = $self->find_dunit_by_name($depname);
                push @{$info->{dependencies}}, $depdunit if defined $depdunit;
            }

            # need to add the package header to the dependency list of a package body
            if ($dunit->type eq 'package body') {
                my $depdunit = $dunit->parent;
                push @{$info->{dependencies}}, $depdunit if defined $depdunit;
            }
            
            $dunit->set_compile_info($tool->toolid, $info);
        }

        for my $dunit (
            $self->dependency_sort($self->packages),
            $self->package_bodies,
            $self->entities,
            $self->architectures,
            $self->configurations,
        ) {
            $tool->compile($dunit);
        }
        
    };
    my $err = $@;
    if ($err) {
        $tool->compile_abort;
        #croak $err;
        warn $err;
    } else {
        $tool->compile_finish;
    }
}

sub dependency_sort {
    my $self = shift;
    my @dunits = @_;
    my @sorted;

    # We will work with du short-names for the sort.  make a lookup of short-name to dunit object
    #  to simplify conversion back at the end.  Also useful for the graph build.
    my %name2du;
    for my $dunit (@dunits) { $name2du{$dunit->name->short_string} = $dunit }

    # build the dependency graph: each du short-name maps to a list of other du short-names.
    # only include dus that are in the list that was passed in.
    my $tdeps = {};
    for my $dunit (@dunits) {
        @{$tdeps->{$dunit->name->short_string}} = grep { exists $name2du{$_} } map { $_->short_string } $dunit->compile_after;
    }
    #print "Dependency graph = ".Dump($tdeps);
    
    # Topological sort!
    #  Make list of nodes with no dependencies
    my @q;
    for my $m (keys %$tdeps) {
        if (@{$tdeps->{$m}} == 0) {
            push @q, $m;
            delete $tdeps->{$m};
        }
    }
    
    while (keys %$tdeps > 0) {
        die "Topological sort can't find any starting points: there must be a dependency loop\n" if @q==0;
        my $n = pop(@q);
        push @sorted, $n;
        #~ for each node m with an edge e from n to m do
        for my $m (keys %$tdeps) {
            if (grep {$_ eq $n} @{$tdeps->{$m}}) {
                #~ remove edge e from the graph
                @{$tdeps->{$m}} = grep {$_ ne $n} @{$tdeps->{$m}};
                #~ if m has no other incoming edges then insert m into Q
                if (@{$tdeps->{$m}} == 0) {
                    push @q, $m;
                    delete $tdeps->{$m};
                }
            }
        }
    }
    #print "Topo sort output = ".Dump([@sorted, reverse @q]);
    map { $name2du{$_} } (@sorted, reverse @q);
}

1;
