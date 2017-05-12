
package Hardware::Vhdl::Automake::CLI;

use Hardware::Vhdl::Automake::UnitName;
use Hardware::Vhdl::Automake::Project;
use Hardware::Vhdl::Automake::Compiler::ModelSim;
use File::Basename;
use File::Spec::Functions;
use Win32::Shortcut;
use YAML;
#use Data::Dumper;
use Cwd;
use IO::Socket;
use Net::hostent;              # for OO version of gethostbyaddr
#use Win32::GuiTest qw(FindWindowLike GetWindowText SetForegroundWindow SendKeys);

use strict;
use warnings;

#&be_server;

sub new {
    my $class = shift;
    my $self = {
        std_out => \*STDOUT,
      };
    bless $self, $class;
}

sub be_server {
    local $|=1;

    my $PORT = 8119;                  # pick something not in use

    my $server = IO::Socket::INET->new(
        Proto     => 'tcp',
        LocalPort => $PORT,
        Listen    => 2, #SOMAXCONN,
        Reuse     => 1
      );

    die "Can't setup server" unless $server;
    print "[Server $0 accepting clients on port $PORT]\n";

    my $project = Hardware::Vhdl::Automake::CLI->new();
    my %dir2proj;
    my $client;
    while ($client = $server->accept()) {
        $client->autoflush(1);
        $project->{std_out} = $client;
        #print $client "Welcome to $0; type help for command list.\n";
        my $hostinfo = gethostbyaddr($client->peeraddr);
        printf "\n[Connect from %s]\n", $hostinfo->name || $client->peerhost;
        #print $client "Command? ";
        $_=<$client>; { # while (defined($_=<$client>)) {
            chomp;
            print "client said '$_'\n";
            #print $client "you said '$_'\n";
            if ($_ =~ /^generate_compile (.*)$/) {
                my $dir = $1;
                eval {
                    if (exists $dir2proj{$dir} && -f $dir2proj{$dir}) {
                        my $ppf = $dir2proj{$dir};
                        unless ($project->{projfile} eq $ppf && $project->{projfile_mtime} == -M($ppf)) {
                            $project->{projfile} = $ppf;
                            $project->load();
                        }
                    } else {
                        my $ppf = $project->{projfile};
                        $project->find_project($dir);
                        unless (defined $ppf && $project->{projfile} eq $ppf && $project->{projfile_mtime} == -M($ppf)) {
                            $project->load();
                        }
                        $dir2proj{$dir} = $project->{projfile};
                    }
                    $project->{compiled_ok} = 0;
                    $project->generate() || die "Generate failed\n";
                    $project->compile();
                    #$project->scan_for_filehandle();
                    $project->save();
                    if (0 && $project->{compiled_ok}) {
                        my @windows = FindWindowLike(0, "^ModelSim PE ", "");
                        if (@windows==1) {
                            SetForegroundWindow($windows[0]);
                            #SendKeys("{HOME}warmstart; {#}{ENTER}{PAUSE 1000}{UP}{HOME}{DELETE 12}{END}",10);
                            SendKeys("{HOME}warmstart; {#}{ENTER}",10);
                            print $client "ModelSim restart requested\n";
                        } else {
                            print $client scalar(@windows)." ModelSim instances found - no restart requested\n";
                        }
                    }
                  };
                my $err = $@;
                if ($err) {
                    print $client "ERROR: $err\n";
                }
            } else {
                print $client "ERROR: command not recognised\n";
            }
        }
        $project->{std_out} = \*STDOUT;
        close $client;
        print "[disconnect]\n";
    }
}

sub parse_cli {
    #print "Hardware::Vhdl::Automake::CLI args are ",join(' ', @ARGV),"\n";
    my $job = shift @ARGV;
    if (lc $job eq 'build') {
        my $project = Hardware::Vhdl::Automake::CLI->new();
        $project->find_and_load_project(getcwd());
        $project->generate();
        $project->compile();
        $project->save();
    } elsif (lc $job eq 'instance_template') {
        my $entname = <STDIN>;
        if ($entname !~ m/^ \s* ((?:[A-Za-z][A-Za-z0-9_]*)|(?:\\.*?\\)) \s* \. \s* ((?:[A-Za-z][A-Za-z0-9_]*)|(?:\\.*?\\)) \s* $/x) {
            die "Selected text does not look like a library.entity_name\n";
        }
        my $libname = $1;
        $entname = $2;
        my $project = Hardware::Vhdl::Automake::CLI->new();
        $project->{std_out} = undef;
        $project->find_and_load_project(getcwd());
        my $ent_dunit = $project->{project}->find_dunit_by_short_name(Hardware::Vhdl::Automake::UnitName->new('entity', $libname, $entname)->short_string);
        die "Component insertion error; entity $libname.$entname not found in project" unless defined $ent_dunit;
        $ent_dunit->entity_instance(sub { print shift });
        exit 0;
    } else {
        die "command '$job' was not recognised.";
    }
    print "Finished.\n";
}

if (0) {
    my $filelist = &file_list("E:/VHDL projects/serswitch/");
    #print Dump($filelist);
    my $project = &load_or_construct_project("E:/VHDL projects/serswitch/", 'serswitch', $filelist);
    &generate($project);
    &compile($project);
    &save($project);
    print "Finished.\n";
}

sub find_and_load_project {
    my $self = shift;
    my $dir = shift;
    $self->find_project($dir);
    $self->load();
}
    
sub find_project {
    my $self = shift;
    my $dir = shift;
    my @projfiles;
    my $stdout = $self->{std_out};
    while (1) {
        print $stdout "looking for project in $dir...\n" if defined $stdout;
        my @allfiles = &files_in_dir($dir);
        # find any .hdl_proj files in this directory
        @projfiles = grep { m/.hdl_proj$/i } @allfiles;
        # find any .hdl_proj files linked to from this directory
        for my $linkfile (grep { m/.lnk$/i } @allfiles) {
            my $link = Win32::Shortcut->new();
            if ($link->Load($linkfile)) {
                my $linksto = $link->{Path};
                if ($linksto =~ m/.hdl_proj$/i && -f $linksto) { push @projfiles, $linksto }
            }
        }
        last if (@projfiles);
        # nothing found here - try the parent dir...
        my $pdir = dirname($dir);
        last if ($pdir eq $dir);
        $dir = $pdir;
    }
    die "No project file was found.\n" unless @projfiles;
    die "More than one possible project file was found.\n" unless @projfiles==1;
    $self->{projfile} = $projfiles[0];
}

sub load {
    my $self = shift;
    my $stdout = $self->{std_out};
        
    print $stdout "Loading project file: $self->{projfile}\n" if defined $stdout;
    ($self->{project}, $self->{compiler}) = YAML::LoadFile($self->{projfile});
    $self->{projfile_mtime} = -M($self->{projfile});

    $self->{project}->set_status_callback( sub { $self->status_report(@_) } );
    $self->{compiler}->set_status_callback( sub { $self->status_report(@_) } );

    $self;
}

sub generate {
    my $self = shift;
    $self->{project}->generate_all;
}

sub compile {
    my $self = shift;
    $self->{project}->compile($self->{compiler});
}

sub scan_for_filehandle {
    my $self = shift;
    &_scan_for_filehandle($self->{project}, '$project->{project}');
    &_scan_for_filehandle($self->{compiler}, '$project->{compiler}');
}

sub _scan_for_filehandle {
    my ($ref, $name, @path) = @_;
    my $r2 = reftype $ref;
    #print STDERR "scanning $name:\n";
    if ($r2) {
        if ($r2 eq 'GLOB') {
            print "$name is a GLOB reference!\n";
        } elsif ($r2 =~ /^(SCALAR|CODE|REF|LVALUE)$/) {
            # go no further
        } elsif ($r2 eq 'ARRAY') {
            # scan array elements
            for my $i (0..$#{$ref}) {
                if (ref $ref->[$i]) {
                    my $nref = $ref->[$i];
                    my $sifref = "$nref"; # stringified version
                    &_scan_for_filehandle($nref, $name."[$i]", @path, $sifref) unless grep({$_ eq $sifref} @path);
                }
            }
        } elsif ($r2 eq 'HASH') {
            # HASH - scan key-value pairs
            for my $k (keys %$ref) {
                if (ref $ref->{$k}) {
                    my $nref = $ref->{$k};
                    my $sifref = "$nref"; # stringified version
                    &_scan_for_filehandle($nref, $name."{$k}", @path, $sifref) unless grep({$_ eq $sifref} @path);
                }
            }
        }
    }
}

sub save {
    my $self = shift;
    if (-f $self->{projfile}) { rename $self->{projfile}, $self->{projfile}.".backup" }
    YAML::DumpFile($self->{projfile}, $self->{project}, $self->{compiler});
    $self->{projfile_mtime} = -M($self->{projfile});
    if (0) {
        # save in Data::Dumper format
        my $fh;
        open $fh, '>', $self->{projfile}.".ddump" || die "Can't write Data::Dumper format project file";
        local $Data::Dumper::Purity = 1;
        print $fh Dumper($self->{project}, $self->{compiler});
    }
}

sub load_or_construct_project {
    my $self = shift;
    my ($projdir, $projname, $filelist) = @_;

    my $stdout = $self->{std_out};
    $self->{projfile} = catfile($projdir, $projname.".hdl_proj");

    if (-f $self->{projfile}) {
        print $stdout "Loading existing project...\n";
        ($self->{project}, $self->{compiler}) = YAML::LoadFile($self->{projfile});
    } else {
        print $stdout "Creating a new project...\n";
        # create a new project
        $self->{project} = new Hardware::Vhdl::Automake::Project;
        $self->{project}->hdl_dir($projdir."hdl");

        # create a compiler instance
        $self->{compiler} = new Hardware::Vhdl::Automake::Compiler::ModelSim({basedir => $projdir."sim"});
    }

    # ensure that the project has the right files, compiled into the right libraries
    # first find out what files are in the project
    my %projfiles;
    for my $sourcefileobj ($self->{project}->sourcefiles) {
        #print $stdout "Project contains file ".$sourcefileobj->file."\n";
        $projfiles{$sourcefileobj->file} = { library => $sourcefileobj->library, object => $sourcefileobj }
    }
    # remove any that we don't want, or where the library is wrong
    for my $sourcefile (keys %projfiles) {
        my @flmatches = grep { $_->{file} eq $sourcefile } @$filelist;
        if (@flmatches>1) { die "file '$sourcefile' exists more than once in file list!\n" }
        if (@flmatches == 0 || $flmatches[0]->{library} ne $projfiles{$sourcefile}->{library}) {
            print $stdout "Removing '$sourcefile' from project.\n";
            $self->{project}->remove_sourcefiles($projfiles{$sourcefile}->{object});
            delete $projfiles{$sourcefile};
        }
    }
    # add any files that are in @$filelist but not in the project
    for my $file (@$filelist) {
        unless (exists $projfiles{$file->{file}}) {
            print $stdout "Adding '$file->{file}' to project.\n";
            $self->{project}->add_sourcefiles($file)
        }
    }

    &save($self);

    $self->{project}->set_status_callback( \&status_report );
    $self->{compiler}->set_status_callback( \&status_report );

    $self;
}

sub file_list {
    my ($basedir) = @_;
    my $list = [];
    for my $libdir (&directories_in_dir($basedir)) {
        my $library = basename($libdir);
        for my $sourcefile (grep { m/\.vhd$/i } &files_in_dir($libdir)) {
            push @$list, { file => $sourcefile, library => $library};
        }
    }
    $list;
}

sub status_report {
    my $self = shift;
    my $report = shift;
    local $| = 1;
    my $type = $report->{type};
    my $stdout = $self->{std_out};
    if ($type eq 'error' || $type eq 'warning') {
        print {$stdout} uc($type).": ".$report->{text}."\n";
        print $stdout "    line: ".$report->{sourceline}."\n" if defined $report->{sourceline};
        for my $st (qw/ src gen /) {
            if (defined $report->{$st.'file'}) {
                print $stdout "    $st: at ";
                my $fn = $report->{$st.'file'};
                $fn =~ s!/!\\!g;
                print $stdout $fn.' line '.$report->{$st.'linenum'};
                print $stdout "\n";
            }
        }
    } elsif ($type eq 'assert_fail') {
        print $stdout "ASSERTION FAIL: ".$report->{text}."\n";
        print $stdout "    expected: ".$report->{expected}."\n";
        print $stdout "    got: ".$report->{got}."\n";
    } elsif ($type eq 'generate1') {
        print $stdout "Generating HDL from source file ".$report->{file}."\n";
    } elsif ($type eq 'generated') {
        print $stdout "  generated ".$report->{duname}->short_string."\n";
    } elsif ($type eq 'generate2') {
        print $stdout "Generating (pass 2) ".$report->{duname}->short_string."\n";
    } elsif ($type eq 'hdl_copy') {
        print $stdout "copying new HDL for ".$report->{duname}->short_string." at ".$report->{file}." line 1\n";
    } elsif ($type eq 'compile_start') {
        print $stdout "\n".$report->{text}."\n";
    } elsif ($type =~ m/^(mklib|config|compile_finish|compile_abort)$/) {
        print $stdout $report->{text}."\n";
        $self->{compiled_ok}=1 if $type eq 'compile_finish';
    } elsif ($type eq 'compile') {
        print $stdout "  compiling ".$report->{duname}->short_string."\t(because $report->{reason})\n";
    } elsif ($type eq 'compile_skip') {
        #print $stdout "  not compiling ".$report->{duname}->short_string."\n";
    } elsif ($type =~ m/^(generate1poss|generate2poss)$/) {
        # suppress output
    } else {
        print $stdout "\n".Dump($report);
    }
}

sub directories_in_dir {
    my $dir = shift;
    my $dh;
    opendir $dh, $dir || return ();
    map { catdir($dir,$_) } grep { !m/^\.{1,2}$/ && -d $dir . '/' . $_ } readdir $dh;
}

sub files_in_dir {
    my $dir = shift;
    my $dh;
    opendir $dh, $dir || return ();
    map { catfile($dir,$_)  } grep { !m/^\.{1,2}$/ && -f $dir . '/' . $_ } readdir $dh;
}

1;
