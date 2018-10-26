package Devel::Examine::Subs;
use 5.008;
use warnings;
use strict;

our $VERSION = '1.70';

use Carp;
use Data::Compare;
use Data::Dumper;
use Devel::Examine::Subs::Engine;
use Devel::Examine::Subs::Preprocessor;
use Devel::Examine::Subs::Postprocessor;
use File::Basename;
use File::Copy;
use File::Edit::Portable;
use PPI;
use Symbol qw(delete_package);

BEGIN {

    # we need to do some trickery for Devel::Trace::Subs due to circular
    # referencing, which broke CPAN installs. DTS does nothing if not presented,
    # per this code

    eval {
        require Devel::Trace::Subs;
        import Devel::Trace::Subs qw(trace);
    };

    if (! defined &trace){
        *trace = sub {};
    }
}

#
# public methods
#

sub new {
   
    # set up for tracing

    if ($ENV{DES_TRACE}){
        $ENV{DTS_ENABLE} = 1;
        $ENV{TRACE} = 1;
    }

    trace() if $ENV{TRACE};

    my $self = {};
    bless $self, shift;
    my $p = $self->_params(@_);

    # default configs

    $self->{namespace} = __PACKAGE__;
    $self->{params}{regex} = 1;
    $self->{params}{backup} = 0;

    $self->_config($p);

    return $self;
}
sub all {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{engine} = 'all';
    
    $self->run($p);
}
sub has {

    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{post_proc} = 'file_lines_contain';
    $self->{params}{engine} = 'has';
    
    $self->run($p);
}
sub missing {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{engine} = 'missing';
    
    $self->run($p);
}
sub lines {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{engine} = 'lines';
    
    if ($self->{params}{search} || $p->{search}){
        $self->{params}{post_proc} = 'file_lines_contain';
    }

    $self->run($p);
}
sub module {
    
    trace() if $ENV{TRACE};

    my $self = shift;

    my $p;

    # allow for single string value

    if (@_ == 1){
        my %p;
        $p{module} = shift;
        $p = $self->_params(%p);
    }
    else {
        $p = $self->_params(@_);
    }

    # set the preprocessor up, and have it return before
    # the building/compiling of file data happens

    $self->{params}{pre_proc} = 'module';
    $self->{params}{pre_proc_return} = 1;

    $self->{params}{engine} = 'module';

    $self->run($p);
}
sub objects {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{post_proc} = 'subs';
    $self->{params}{engine} = 'objects';

    $self->run($p);
}
sub search_replace {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{post_proc}
      = ['file_lines_contain', 'subs', 'objects'];

    $self->{params}{engine} = 'search_replace';

    $self->run($p);
}
sub replace {

    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{pre_proc} = 'replace';
    $self->{params}{pre_proc_return} = 1;

    $self->run($p);
}
sub inject_after {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = $self->_params(@_);

    if (! $p->{injects} && ! $self->{params}{injects}){
        $p->{injects} = 1;
    }

    $self->{params}{post_proc}
      = ['file_lines_contain', 'subs', 'objects'];

    $self->{params}{engine} = 'inject_after';

    $self->run($p);
}
sub inject {
    trace() if $ENV{TRACE};
    my $self = shift;
    my $p = $self->_params(@_);

    # inject_use/inject_after_sub_def are preprocs

    if (
        $p->{inject_use} || $p->{inject_after_sub_def} || defined $p->{line_num}
    ){
        $self->{params}{pre_proc} = 'inject';
        $self->{params}{pre_proc_return} = 1;
    }

    $self->run($p);
}
sub remove {
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{pre_proc} = 'remove';
    $self->{params}{pre_proc_return} = 1;

    $self->run($p);
}
sub order {
    trace() if $ENV{TRACE};

    my $self = shift;

    if ($self->{params}{directory}){
        confess "\norder() can only be called on an individual file, not " .
                "a directory at this time\n\n";
    }

    return @{ $self->{order} };
}
sub backup {
    trace() if $ENV{TRACE};

    my $self = shift;
    my $state = shift || 0;

    $self->{params}{backup} = $state if defined $state;
    return $self->{params}{backup};
}

#
# publicly available semi-private developer methods
#

sub add_functionality {

    trace() if $ENV{TRACE};
    
    my $self = shift;
    my $p = $self->_params(@_);

    $self->_config($p);
    
    my $to_add = $self->{params}{add_functionality};
    my $in_prod = $self->{params}{add_functionality_prod};

    my @allowed = qw(
        pre_proc
        post_proc
        engine
    );

    my $is_allowed = 0;

    for (@allowed){
        if ($_ eq $to_add){
            $is_allowed = 1;
            last;
        }
    }
    
    if (! $is_allowed){
        confess "Adding a non-allowed piece of functionality...\n";
    }

    my %dt = (
            pre_proc => sub {
                trace() if $ENV{TRACE};
                return $in_prod
                    ? $INC{'Devel/Examine/Subs/Preprocessor.pm'}
                    : 'lib/Devel/Examine/Subs/Preprocessor.pm';
            },

            post_proc => sub {
                trace() if $ENV{TRACE};
                return $in_prod
                    ? $INC{'Devel/Examine/Subs/Postprocessor.pm'}
                    : 'lib/Devel/Examine/Subs/Postprocessor.pm';
            },

            engine => sub {
                trace() if $ENV{TRACE};
                return $in_prod
                    ? $INC{'Devel/Examine/Subs/Engine.pm'}
                    : 'lib/Devel/Examine/Subs/Engine.pm';
            },
    );

    my $caller = (caller)[1];

    open my $fh, '<', $caller
      or confess "can't open the caller file $caller: $!";

    my $code_found = 0;
    my @code;

    while (<$fh>){
        chomp;
        if (m|^#(.*)<des>|){
            $code_found = 1;
            next;
        }
        next if ! $code_found;
        last if m|^#(.*)</des>|;
        push @code, $_;
    }

    my $file = $dt{$to_add}->();
    my $copy = $self->{params}{copy};

    if ($copy) {
        copy $file, $copy or die $!;
        $file = $copy;
    }

    my $sub_name;
    
    if ($code[0] =~ /sub\s+(\w+)/){
        $sub_name = $1;
    }
    else {
        confess "couldn't extract the sub name";
    }

    my $des = Devel::Examine::Subs->new(file => $file);

    my $existing_subs = $des->all;

    if (grep { $sub_name eq $_ } @$existing_subs) {
        confess "the sub you're trying to add already exists";
    }

    $des = Devel::Examine::Subs->new(
        file => $file,
        engine => 'objects',
        post_proc => [qw(subs end_of_last_sub)],
    );

    $p = {
        engine => 'objects', 
        post_proc => [qw(subs end_of_last_sub)],
        post_proc_return => 1,
    };

    my $start_writing = $des->run($p);

    my $rw = File::Edit::Portable->new;

    $rw->splice(file => $file, insert => \@code, line => $start_writing);

    # the weird spaces are required for layout... they're not erroneous

    my @insert = ("        $sub_name => \\&$sub_name,");

    $rw->splice(
        file => $file, 
        find => 'my\s+\$dt\s+=\s+\{',
        insert => \@insert,
    );

    return 1;
}
sub engines {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $module = $self->{namespace} . "::Engine";
    my $engine = $module->new;
 
    my @engines;

    for (keys %{$engine->_dt}){
        push @engines, $_ if $_ !~ /^_/;
    }
    return @engines;
}
sub pre_procs {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $module = $self->{namespace} . "::Preprocessor";
    my $pre_proc = $module->new;

    my @pre_procs;

    for (keys %{ $pre_proc->_dt }){
        push @pre_procs, $_ if $_ !~ /^_/;
    }
    return @pre_procs;
}
sub post_procs {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $module = $self->{namespace} . "::Postprocessor";
    my $post_proc = $module->new;

    my @post_procs;

    for (keys %{ $post_proc->_dt }){
        push @post_procs, $_ if $_ !~ /^_/;
    }
    return @post_procs;
}
sub run {

    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = shift;

    $self->_config($p);

    $self->_run_end(0);

    my $struct;

    if ($self->{params}{directory}){
        $struct = $self->_run_directory;
    }
    else {
        $struct = $self->_core;
        $self->_write_file if $self->{write_file_contents};
    }

    $self->_run_end(1);

    return $struct;
}
sub valid_params {
    trace() if $ENV{TRACE};
    return %{ $_[0]->{valid_params} };
}

#
# private methods
#

sub _cache {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $file = shift;
    my $struct = shift;

    if ($self->{params}{cache_dump}){

        print Dumper $self->{cache};

        if ($self->{params}{cache_dump} > 1){
            exit;
        }
    }

    if (! $struct && $file){
        return $self->{cache}{$file};
    }
    if ($file && $struct){
        $self->{cache}{$file} = $struct;
    }
}
sub _cache_enabled {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    return $self->{params}{cache};
}
sub _cache_safe {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $value = shift;

    $self->{cache_safe} = $value if defined $value;

    return $self->{cache_safe};
}
sub _clean_config {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $config_vars = shift; # href of valid params
    my $p = shift;           # href of params passed in

    for my $var (keys %$config_vars){
       
        last if ! $self->_run_end;

        # skip if it's a persistent var

        next if $config_vars->{$var} == 1;

        delete $self->{params}{$var};
    }

    # delete non-valid params

    for my $param (keys %$p){
        if (! exists $config_vars->{$param}){
            print "\n\nDES::_clean_config() deleting invalid param: $param\n";
            delete $p->{$param};
        }
    }
}
sub _clean_core_config {
    
    trace() if $ENV{TRACE};

    my $self = shift;

    # delete params we collected after _clean_config()

    delete $self->{params}{file_contents};
    delete $self->{params}{order};

    my @core_phases = qw(
        pre_proc
        post_proc
        engine
    );

    for (@core_phases){
        delete $self->{params}{$_};
    }
}
sub _config {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = shift;

    my %valid_params = (

        # persistent

        backup => 1,
        cache => 1,
        copy => 1,
        diff => 1,
        extensions => 1,
        file => 1,
        maxdepth => 1,
        no_indent => 1,
        regex => 1,

        # persistent - core phases

        pre_proc => 1,
        post_proc => 1,
        engine => 1,

        # transient

        directory => 0,
        search => 0,
        replace => 0,
        injects => 0,
        code => 0,
        include => 0,
        exclude => 0,
        lines => 0,
        module => 0,
        objects_in_hash => 0,
        pre_proc_dump => 0,
        post_proc_dump => 0,
        engine_dump => 0,
        core_dump => 0,
        pre_proc_return => 0,
        post_proc_return => 0,
        engine_return => 0,
        config_dump => 0,
        cache_dump => 0,
        inject_use => 0,
        inject_after_sub_def => 0,
        delete => 0,
        file_contents => 0,
        exec => 0,                  # replace(), search_replace()
        limit => 0,
        line_num => 0,              # inject()
        add_functionality => 0,
        add_functionality_prod => 0,
        order => 0,
    );

    $self->{valid_params} = \%valid_params;

    # get previous run's config

    %{$self->{previous_run_config}} = %{$self->{params}};

    # clean config

    $self->_clean_config(\%valid_params, $p);

    for my $param (keys %$p){

        # validate the file

        if ($param eq 'file'){
            $self->_file($p);
            next;
        }

        $self->{params}{$param} = $p->{$param};
    }

    # check if we can cache

    if ($self->_cache_enabled) {

        my @unsafe_cache_params
            = qw(file extensions include exclude search);

        my $current = $self->{params};
        my $previous = $self->{previous_run_config};

        for (@unsafe_cache_params) {
            my $safe = Compare($current->{$_}, $previous->{$_}) || 0;

            $self->_cache_safe($safe);

            last if !$self->_cache_safe;
        }
    }

    if ($self->{params}{config_dump}){
        print Dumper $self->{params};
    }
}
sub _file {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = shift;

    $self->{params}{file} = defined $p->{file}
        ? $p->{file}
        : $self->{params}{file};

    # if a module was passed in, dig up the file

    if ($self->{params}{file} =~ /::/){

        my $module = $self->{params}{file};
        (my $file = $module) =~ s|::|/|g;
        $file .= '.pm';
       
        my $module_is_loaded;

        if (! $INC{$file}){
            my $import_ok = eval {
                require $file;
                import $module;
                1;
            };

            if (! $import_ok){
                $@ = "\nDevel::Examine::Subs::_file() speaking ... " .
                     "Can't transform module to a file name\n\n"
                     . $@;
                confess $@;
            }
        }
        else {
            $module_is_loaded = 1;
        }

        # set the file param

        $self->{params}{file} = $INC{$file};

        if (! $module_is_loaded){
            delete_package $module;
            delete $INC{$file};
        }
    }

    # configure directory searching for run()

    if (-d $self->{params}{file}){
        $self->{params}{directory} = 1;
        $self->{params}{extensions} 
          = defined $p->{extensions} ? $p->{extensions} : [qw(*.pm *.pl)];
    }
    else {
        if (! $self->{params}{file} || ! -f $self->{params}{file}){
            die "Invalid file supplied: $self->{params}{file} $!";
        }
   }

   return $self->{params}{file};
}
sub _params {
    trace() if $ENV{TRACE};
    my $self = shift;
    my %params = @_;
    return \%params;
}
sub _read_file {

    # this sub prepares a temp copy of the original file,
    # recseps changed to local platform for PPI

    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = shift;

    my $file = $p->{file};

    return if ! $file;

    if ($self->{params}{backup}) {
        my $basename = basename($file);
        my $bak = "$basename.bak";

        copy $file, $bak
            or confess "DES::_read_file() can't create backup copy $bak!";
    }

    die "Can't call method \"serialize\" on an undefined file\n" if ! -f $file;

    $self->{rw} = File::Edit::Portable->new;

    my $ppi_doc;

    if ($self->{rw}->recsep($file, 'hex') ne $self->{rw}->platform_recsep('hex')) {
        my $fh = $self->{rw}->read($file);

        my $tempfile = $self->{rw}->tempfile;
        my $tempfile_name = $tempfile->filename;
        my $platform_recsep = $self->{rw}->platform_recsep;

        $self->{rw}->write(
            copy => $tempfile_name,
            contents => $fh,
            recsep => $platform_recsep
        );

        $ppi_doc = PPI::Document->new($tempfile_name);

        close $tempfile;
    }
    else {
        $ppi_doc = PPI::Document->new($file);
    }

    @{ $p->{file_contents} } = split /\n/, $ppi_doc->serialize;


    if (! $p->{file_contents}->[0]){
        return 0;
    }
    else {
        $self->{params}{file_contents} = $p->{file_contents};
        return 1;
    }
}
sub _run_directory {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = shift;

    my $dir = $self->{params}{file};

    $self->{rw} = File::Edit::Portable->new;

    my @files = $self->{rw}->dir(
        dir => $dir,
        maxdepth => $self->{params}{maxdepth} || 0,
        types => $self->{params}{extensions},
        list => 1,
    );

    my %struct;

    for my $file (@files){
        
        $self->{params}{file} = $file;
        my $data = $self->_core($p);

        $self->_write_file if $self->{write_file_contents};

        if (ref $data eq 'HASH' || ref $data eq 'ARRAY'){
            $struct{$file} = $data;
        }
    }

    return \%struct;
}
sub _run_end {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $value = shift;

    $self->{run_end} = $value if defined $value;

    # we clean core_config here

    $self->_clean_core_config if $value;

    return $self->{run_end};
}
sub _write_file {

    trace() if $ENV{TRACE};

    my $self = shift;

    my $copy = $self->{params}{copy};
    
    my $file = $self->{params}{file};
    my $contents = $self->{write_file_contents};

    return if ! $file;

    if ($self->{params}{directory} && $copy && ! -d $copy){
        warn "\n\nin directory mode, all files are copied to the dir named " .
             "in the copy param, which is $copy\n\n";

        mkdir $copy or confess "can't create directory $copy";
    }
    if ($copy && -d $copy){
        copy $file, $copy;
        my $filename = basename $file;
        $file = "$copy/$filename";
    }
    elsif ($copy) {
        $file = $copy;
    }

    my $write_response;

    my $write_ok = eval {
        $write_response
          = $self->{rw}->write(file => $file, contents => $contents);
        1;
    };

    if (! $write_ok || ! $write_response){
        $@ = "\nDevel::Examine::Subs::_write_file() speaking...\n\n" .
             "File::Edit::Portable::write() returned a failure status.\n\n" .
             $@;
        confess $@;
    }
}

#
# private methods for core phases
#

sub _core {

    trace() if $ENV{TRACE};
    
    my $self = shift;
    my $p = $self->{params};

    $self->_read_file($p);

    # pre processor

    my $data;

    if ($self->{params}{pre_proc}){
        my $pre_proc = $self->_pre_proc;

        $data = $pre_proc->($p, $data);

        if ($self->{params}{pre_proc_dump}){
            print Dumper $data;
            exit;
        }

        if ($p->{write_file_contents}){
            $self->{write_file_contents} = $p->{write_file_contents};
        }

        # for things that don't need to process files
        # (such as 'module'), return early

        if ($self->{params}{pre_proc_return}){
            return $data;
        }
    }

    # processor

    my $subs = $data;

    # bypass the proc if cache

    my $cache_enabled = $self->_cache_enabled;
    my $cache_safe = $self->_cache_safe;

    if ($cache_enabled && $cache_safe && $self->_cache($p->{file})){
        $subs = $self->_cache($p->{file});
    }
    else {
        $subs = $self->_proc($p);
    } 

    return if ! $subs;

    # write to cache

    if ($self->_cache_enabled && ! $self->_cache($p->{file})){
        $self->_cache($p->{file}, $subs);
    }

    # post processor

    if ($self->{params}{post_proc}){
        for my $post_proc ($self->_post_proc($p, $subs)){
            $subs = $post_proc->($p, $subs);
            $self->{write_file_contents} = $p->{write_file_contents};
        }
    }  

    if ($self->{params}{post_proc_return}){
        return $subs;
    }

    # engine

    my $engine = $self->_engine($p, $subs);

    if ($self->{params}{engine}){
        $subs = $engine->($p, $subs);
        $self->{write_file_contents} = $p->{write_file_contents};
    }

    # core dump

    if ($self->{params}{core_dump}){
        print "\n\t Core Dump called...\n\n";
        print "\n\n\t Dumping data... \n\n";
        print Dumper $subs;

        print "\n\n\t Dumping instance...\n\n";
        print Dumper $self;

        exit;
    }

    return $subs;
}
sub _pre_proc {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = shift;
    my $subs = shift;

    my $pre_proc = $self->{params}{pre_proc};

    if (not $pre_proc or $pre_proc eq ''){
        return $subs;
    }
   
    # tell _core() to return directly from the pre_processor 
    # if necessary, and bypass post_proc and engine

    if ($pre_proc eq 'module'){
       $self->{params}{pre_proc_return} = 1;
    }

    my $cref;
    
    if (not ref($pre_proc) eq 'CODE'){
        my $pre_proc_module = $self->{namespace} . "::Preprocessor";
        my $compiler = $pre_proc_module->new;

        if (! $compiler->exists($pre_proc)){
            confess "Devel::Examine::Subs::_pre_proc() speaking...\n\n" .
                  "pre_processor '$pre_proc' is not implemented.\n";
        }

        my $compiled_ok = eval {
            $cref = $compiler->{pre_procs}{$pre_proc}->();
            1;
        };
        
        if (! $compiled_ok){
            $@ = "\n[Devel::Examine::Subs speaking] " .
                  "dispatch table in Devel::Examine::Subs::Preprocessor " .
                  "has a mistyped function as a value, but the key is ok\n\n"
            . $@;
            confess $@;
        }

    }

    if (ref($pre_proc) eq 'CODE'){
        $cref = $pre_proc;
    }
    
    return $cref;
}
sub _proc {
   
    # this method is the core data collection/manipulation
    # routine (aka the 'Processor phase') for all of DES

    # make sure all unit tests are successful after any change
    # to this subroutine

    # if you want the data structure to look differently before 
    # reaching here, use a pre_proc. If you want it different 
    # afterwards, use a post_proc or an engine

    trace() if $ENV{TRACE};
    
    my $self = shift;
    my $p = shift;
   
    my $file = $self->{params}{file};

    return {} if ! $file;

    my $PPI_doc = PPI::Document->new($file);   
    my $PPI_subs = $PPI_doc->find('PPI::Statement::Sub');

    return if ! $PPI_subs;

    my %subs;
    $subs{$file} = {};
    my @sub_order;

    for my $PPI_sub (@{$PPI_subs}){
        
        my $include 
          = defined $self->{params}{include} ? $self->{params}{include} : [];
        my $exclude
          = defined $self->{params}{exclude} ? $self->{params}{exclude} : [];

        delete $self->{params}{include} if $exclude->[0];

        my $name = $PPI_sub->name;
        
        push @sub_order, $name;

        # skip over excluded (or not included) subs

        next if grep {$name eq $_ } @$exclude;

        if ($include->[0]){
            next if (! grep {$_ && $name eq $_} @$include);
        }

        $subs{$file}{subs}{$name}{start} = $PPI_sub->line_number;
        $subs{$file}{subs}{$name}{start}--;

        # yep, its a hard to find thing 'y' is :)

        my $lines = $PPI_sub =~ y/\n//;

        $subs{$file}{subs}{$name}{end}
          = $subs{$file}{subs}{$name}{start} + $lines;

        my $count_start = $subs{$file}{subs}{$name}{start};
        $count_start--;

        my $sub_line_count
          = $subs{$file}{subs}{$name}{end} - $count_start;

        $subs{$file}{subs}{$name}{num_lines} = $sub_line_count;

        @{ $subs{$file}{subs}{$name}{code} } = split /\n/, $PPI_sub->content;
    }
  
    @{ $p->{order} } = @sub_order; 
    @{ $self->{order} } = @sub_order;

    return \%subs;
}
sub _post_proc {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = shift;
    my $struct = shift;

    my $post_proc = $self->{params}{post_proc};

    my $post_proc_dump = $self->{params}{post_proc_dump};

    my @post_procs;

    if ($post_proc){

        my @post_proc_list;

        if (ref $post_proc ne 'ARRAY'){
            push @post_proc_list, $post_proc;
        }
        else {
            @post_proc_list = @{$post_proc};
        }

        for my $pf (@post_proc_list){

            my $cref;

            if (ref $pf ne 'CODE'){

                my $post_proc_module = $self->{namespace} . "::Postprocessor";
                my $compiler = $post_proc_module->new;

                # post_proc isn't in the dispatch table

                if (! $compiler->exists($pf)){
                    confess "\nDevel::Examine::Subs::_post_proc() " .
                          "speaking...\n\npost_proc '$pf' is not " .
                          "implemented. '$post_proc' was sent in.\n";
                }
                
                my $compiled_ok = eval {
                    $cref = $compiler->{post_procs}{$pf}->();
                    1;
                };
        
                if (! $compiled_ok){
                    $@ = "\n[Devel::Examine::Subs speaking] " .
                          "dispatch table in " .
                          "Devel::Examine::Subs::Postprocessor has a mistyped " .
                          "function as a value, but the key is ok\n\n"
                    . $@;
                    confess $@;
                }
            } 
            if (ref($pf) eq 'CODE'){
                $cref = $pf;
            }

            if ($post_proc_dump && $post_proc_dump > 1){
                $self->{params}{post_proc_dump}--;
                $post_proc_dump = $self->{params}{post_proc_dump};
            }

            if ($post_proc_dump && $post_proc_dump == 1){
                my $subs = $cref->($p, $struct);
                print Dumper $subs;
                exit;
            }
            push @post_procs, $cref;
        }
    }
    else {
        return;
    }
    return @post_procs;
}
sub _engine {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $p = shift;
    my $struct = shift;

    my $engine 
      = defined $p->{engine} ? $p->{engine} : $self->{params}{engine};

    if (not $engine or $engine eq ''){
        return $struct;
    }

    my $cref;

    if (not ref($engine) eq 'CODE'){

        # engine is a name

        my $engine_module = $self->{namespace} . "::Engine";
        my $compiler = $engine_module->new;

        # engine isn't in the dispatch table

        if (! $compiler->exists($engine)){
            confess "engine '$engine' is not implemented.\n";
        }

        my $compiled_ok = eval {
            $cref = $compiler->{engines}{$engine}->();
            1;
        };

        # engine has bad func val in dispatch table, but key is ok

        if (! $compiled_ok){
            $@ = "\n[Devel::Examine::Subs speaking] " .
                  "dispatch table in Devel::Examine::Subs::Engine " .
                  "has a mistyped function as a value, but the key is ok\n\n"
            . $@;
            confess $@;
        }
    }

    if (ref($engine) eq 'CODE'){
        $cref = $engine;
    }

    if ($self->{params}{engine_dump}){
        my $subs = $cref->($p, $struct);
        print Dumper $subs;
        exit;
    }

    return $cref;
}

#
# pod
#

sub _pod{1;} #vim placeholder
1; 
__END__

=head1 NAME

Devel::Examine::Subs - Get info about, search/replace and inject code into
Perl files and subs.

=for html
<a href="http://travis-ci.org/stevieb9/devel-examine-subs"><img src="https://secure.travis-ci.org/stevieb9/devel-examine-subs.png"/>
<a href='https://coveralls.io/github/stevieb9/devel-examine-subs?branch=master'><img src='https://coveralls.io/repos/stevieb9/devel-examine-subs/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Devel::Examine::Subs;

    # examine a file

    my $des = Devel::Examine::Subs->new( file => 'perl.pl' );

    # examine all the Perl files in a directory

    my $des = Devel::Examine::Subs->new( file => '/path/to/directory' );

    # load a module by name. Uses %INC to find the path after loading it

    my $des = Devel::Examine::Subs->new( file => 'Some::Module::Name' );

Get all sub names in a file

    my $aref = $des->all;

Get all the subs as objects

    $subs = $des->objects;

    for my $sub (@$subs){
        $sub->name;       # name of sub
        $sub->start;      # first line number of sub in file
        $sub->end;        # last line number of sub in file
        $sub->line_count; # number of lines in sub
        $sub->code;       # entire sub code from file
        $sub->lines;      # lines that match search term
    }

Get the sub objects within a hash

    my $subs = $des->objects( objects_in_hash => 1 );

    for my $sub_name (keys %$subs) {

        print "$sub_name\n";

        my $sub = $subs->{$sub_name};

        print $sub->start . "\n" .
              $sub->end . "\n";
              ...
    }

Get all subs containing "string" in the body

    my $search = 'string';
    my $aref = $des->has( search => $search );

Search and replace code in subs

    $des->search_replace( exec => sub { $_[0] =~ s/this/that/g; } );

Inject code into sub after a search term (preserves previous line's indenting)

    my @code = <DATA>;

    $des->inject_after(
                    search => 'this',
                    code => \@code,
                  );

    __DATA__

    # previously uncaught issue

    if ($foo eq "bar"){
        confess 'big bad error';
    }

Print out all lines in all subs that contain a search term

    my $subs = $des->lines(search => 'this');

    for my $sub (keys %$subs){

        print "\nSub: $sub\n";

        for my $line (@{ $subs->{$sub} }){
            my ($line_num, $text) = each %$line;
            say "Line num: $line_num";
            say "Code: $text\n";
        }
    }

The structures look a bit differently when 'file' is a directory.
You need to add one more layer of extraction.

    my $files = $des->objects;

    for my $file (keys %$files){
        for my $sub (@{$files->{$file}}){
            ...
        }
    }

Print all subs within each Perl file under a directory

    my $files = $des->all( file => 'lib/Devel/Examine' );

    for my $file (keys %$files){
        print "$file\n";
        print join('\t', @{$files->{$file}});
    }

Most methods can include or exclude specific subs

    my $has = $des->has( include => ['dump', 'private'] );

    my $missing = $des->missing( exclude => ['this', 'that'] );

    # note that 'exclude' param renders 'include' invalid


=head1 DESCRIPTION

Gather information about subroutines in Perl files (and in-memory modules),
with the ability to search/replace code, inject new code, get line counts,
get start and end line numbers, access the sub's code and a myriad of other
options.  Files are parsed using L<PPI>, not by inspecting packages or
coderefs.



=head1 METHODS

See the L</PARAMETERS> for the full list of params, and which ones
are persistent across runs using the same object.



=head2 C<new>

Mandatory parameters: C<file =E<gt> $filename>

Instantiates a new object. If C<$filename> is a directory, we'll iterate
through it finding all Perl files. If C<$filename> is a module name
(eg: C<Data::Dump>), we'll attempt to load the module, extract the file for
the module, and load the file. CAUTION: this will be a production C<%INC> file
so be careful.

Only specific params are guaranteed to stay persistent throughout a run on the
same object, and are best set in C<new()>. These parameters are C<file>,
C<extensions>, C<maxdepth>, C<cache>, C<regex>, C<copy>, C<no_indent>,
C<backup> and C<diff>.

Note: omit the C<file> parameter if all you'll be using is the C<module()> method.



=head2 C<all>

Mandatory parameters: None

Returns an array reference containing the names of all subroutines found in
the file, listed in the order they appear in the file.






=head2 C<has>

Mandatory parameters: C<search =E<gt> 'term'>

Returns an array reference containing the names of the subs where the
subroutine contains the search text.




=head2 C<missing>

Mandatory parameters: C<search =E<gt> 'term'>

The exact opposite of has.



=head2 C<lines>

Mandatory parameters: C<search =E<gt> 'text'>

Gathers together all line text and line number of all subs where the
subroutine contains lines matching the search term.

Returns a hash reference with the subroutine name as the key, the value being
an array reference which contains a hash reference in the format line_number
=E<gt> line_text.




=head2 C<objects>

Mandatory parameters: None

Optional parameters: C<objects_in_hash =E<gt> 1>

Returns an array reference of subroutine objects. If the optional
C<objects_in_hash> is sent in with a true value, the objects will be returned
in a hash reference where the key is the sub's name, and the value is the sub
object.

See L</SYNOPSIS> for the structure of each object.




=head2 C<module('Module::Name')>

Mandatory parameters: C<'Module::Name'>. Note that this is one public method
that takes its parameter in string format (as opposed to hash format).

Note that this method pulls the subroutine names from the namespace (which may
include C<include>ed subs. If you only want a list of subs within the actual
module file, send the module name as the value to the C<file> parameter, and
use the common methods (C<all>, C<has>, C<missing> etc) to extract the names.

Returns an array reference containing the names of all subs found in the
module's namespace symbol table.



=head2 C<order>

After one of the other user methods are called, call this method to get returned to you an array of
the names of subs you collected, in the order that they appear in the file. By default, because we use hashes internally, subs aren't ever in proper order.




=head2 C<search_replace>

Mandatory parameters: C<exec =E<gt> $cref>

Core optional parameter: C<copy =E<gt> 'filename.txt'>

Coderef should be created in the form C<sub { $_[0] =~ s/search/replace/; };>.
This allows us to avoid string C<eval>, and allows us to use any regex
modifiers you choose. The C<$_[0]> element represents each line in the file,
as we loop over them.



=head2 C<replace>

Parameters: C<exec =E<gt> $cref, limit =E<gt> 1>

This is the entire file brother to the sub-only C<search_replace()>. The C<limit> parameter
specifies how many successful replacements to do, starting at the top of the file. Set to a
negative integer for unlimited (this is the default).

The C<exec> parameter is a code reference, eg: C<my $cref = sub {$_[0] =~ s/this/that/;}>.
All standard Perl regular expressions apply, along with their modifiers. The
C<$_[0]> element represents each line in the file, as we loop over them.

Returns the number of lines changed in file mode, and an empty hashref in directory mode.











=head2 C<inject_after>

Mandatory parameters: C<search =E<gt> 'this', code =E<gt> \@code>

Injects the code in C<@code> into the sub within the file, where the sub
contains the search term. The same indentation level of the line that contains
the search term is used for any new code injected. Set C<no_indent> parameter
to a true value to disable this feature.

By default, an injection only happens after the first time a search term is
found. Use the C<injects> parameter (see L</PARAMETERS>) to change this
behaviour. Setting to a positive integer beyond 1 will inject after that many
finds. Set to a negative integer will inject after all finds.

The C<code> array should contain one line of code (or blank line) per each
element. (See L</SYNOPSIS> for an example). The code is not manipulated prior
to injection, it is inserted exactly as typed. Best to use a heredoc,
C<__DATA__> section or an external text file for the code.



Optional parameters:

=over 4



=item C<copy>

See C<search_replace()> for a description of how this parameter is used.

=item C<injects>

How many injections do you want to do per sub? See L</PARAMETERS> for more
details.

=back



=head2 C<inject>

Parameters (all are mutually exclusive, use only one):

C<line_num =E<gt> 33> with C<code =E<gt> \@code> or,
C<inject_use =E<gt> ['use Module::Name', 'use Module2::Name']> or,
C<inject_after_sub_def =E<gt> ['code line 1;', 'code line 2;']>

C<line_num> will inject the block of code in the array reference immediately after the line number specified.

C<inject_use> will inject the statements prior to all existing C<use>
statements that already exist in the file(s). If none are found, will inject
the statements right after a C<Package> statement if found.

Technically, you don't have to inject a C<use> statement, but I'd advise it.

C<inject_after_sub_def> will inject the lines of code within the array
reference value immediately following all sub definitions in a file.
Next line indenting is used, and sub definitions with their opening brace
on a separate line than the definition itself is caught.




=head2 C<remove>

Parameters: C<delete =E<gt> ['string1', 'string2']>

Deletes from the file(s) the entire lines that contain the search terms.

This method is file based... the work happens prior to digging up subs, hence
C<exclude>, C<include> and other sub-based parameters have no effect.


=head2 C<backup(Bool)>

Configure whether to make a filename.bak copy of all files read by DES. A true
value sent in will enable this feature, a false value will disable it. Returns
1 (true) if this feature is enabled, and 0 (false) if not.

Disabled by default.

=head1 C<DEVELOPER METHODS>

=head2 C<valid_params>

Returns a hash where the keys are valid parameter names, and the value is a
bool where if true, the parameter is persistent (remains between calls on the
same object) and if false, the param is transient, and will be made C<undef>
after each method call finishes.


=head2 C<run>

Parameter format: Hash reference

All public methods call this method internally. This is the only public method
that takes its parameters as a single hash reference. The public methods set certain
variables (filters, engines etc). You can get the same effect programatically
by using C<run()>. Here's an example that performs the same operation as the
C<has()> public method:

    my $params = {
            search => 'text',
            post_proc => 'file_lines_contain',
            engine => 'has',
    };

    my $return = $des->run($params);

This allows for very fine-grained interaction with the application, and makes
it easy to write new engines and for testing.





=head2 C<add_functionality>

WARNING!: This method is for development of this distribution only!

While writing new processors, set the processor type to a callback within the
local working file. When the code performs the actions you want it to, put a
comment line before the code with C<#<des>> and a line following the code with
C<#</des>>. DES will slurp in all of that code live-time, inject it into the
specified processor, and configure it for use. See
C<examples/write_new_engine.pl> for an example of creating a new 'engine'
processor.

Returns 1 on success.

Parameters:

=over 4

=item C<add_functionality>

Informs the system which type of processor to inject and configure. Permitted
values are 'pre_proc', 'post_proc' and 'engine'.

=item C<add_functionality_prod>

Set to a true value, will update the code in the actual installed Perl module
file, instead of a local copy.

=back





Optional parameters:

=over 4

=item C<copy> 

Set it to a new file name which will be a copy of the specified file, and only
change the copy. Useful for verifying the changes took properly.

=back


=head2 C<pre_procs>, C<post_procs>, C<engines>

For development. Returns the list of the respective built-in callbacks.




=head1 PARAMETERS

There are various parameters that can be used to change the behaviour of the
application. Some are persistent across calls, and others aren't. You can
change or null any/all parameters in any call, but some should be set in the
C<new()> method (set it and forget it).

The following list are persistent parameters, which need to be manually
changed or nulled. Consider setting these in C<new()>.

=over 4

=item C<file>

State: Persistent

Default: None

The name of a file, directory or module name. Will convert module name to a
file name if the module is installed on the system. It'll C<require> the
module temporarily and then 'un'-C<require> it immediately after use.

If set in C<new()>, you can omit it from all subsequent method calls until you
want it changed. Once changed in a call, the updated value will remain
persistent until changed again.

=item C<backup>

State: Persistent

Default: Disabled

Set this to a true value to have a C<.bak> file copy created on all file reads.
The C<.bak> file will be created in the directory the script is run in.

=item C<extensions>

State: Persistent

Default: C<['*.pm', '*.pl')]>

By default, we load only C<*.pm> and C<*.pl> files. Use this parameter to load
different files. Only useful when a directory is passed in as opposed to a
file. This parameter is persistent until manually reset and should be set in
C<new()>.

Values: Array reference where each element is the names of files to find. Any wildcard or regex that are valid in L<File::Find::Rule's|http://search.cpan.org/~rclamp/File-Find-Rule-0.33/lib/File/Find/Rule.pm> are valid here. For example, C<[qw(*.pm *.pl)]> is the default.


=item C<maxdepth>

When running in directory mode, how many levels deep do you want to traverse? Default is unlimited. Set to a positive integer to set.


=item C<cache>

State: Persistent

Default: Undefined

If multiple calls on the same object are made, caching will save the
file/directory/sub information, saving tremendous work for subsequent calls.
This is dependant on certain parameters not changing between calls.

Set to a true value (1) to enable. Best to call in the C<new> method.


=item C<copy>

State: Persistent

Default: None

For methods that write to files, you can optionally work on a copy that you
specify in order to review the changes before modifying a production file.

Set this parameter to the name of an output file. The original file will be
copied to this name, and we'll work on this copy.


=item C<regex>

State: Persistent

Default: Enabled

Set to a true value, all values in the 'search' parameter become regexes. For
example with regex on, C</thi?s/> will match "this", but without regex, it
won't. Without 'regex' enabled, all characters that perl treats as special
must be escaped. This parameter is persistent; it remains until reset
manually.


=item C<no_indent>

State: Persistent

Default: Disabled

In the processes that write new code to files, the indentation level of the
line the search term was found on is used for inserting the new code by
default. Set this parameter to a true value to disable this feature and set
the new code at the beginning column of the file.

=item C<diff>

State: Persistent

Not yet implemented. 

Compiles a diff after each edit using the methods that edit files.

=back

The following parameters are not persistent, ie. they get reset before
entering the next call on the DES object. They must be passed in to each
subsequent call if the effect is still desired.


=over 4

=item C<include>

State: Transient

Default: None

An array reference containing the names of subs to include. This
(and C<exclude>) tell the Processor phase to generate only these subs,
significantly reducing the work that needs to be done in subsequent method
calls.



=item C<exclude>

State: Transient

Default: None

An array reference of the names of subs to exclude. See C<include> for further
details.

Note that C<exclude> renders C<include> useless.




=item C<injects>

State: Transient

Default: 1

Informs C<inject_after()> how many injections to perform. For instance, if a
search term is found five times in a sub, how many of those do you want to
inject the code after?

Default is 1. Set to a higher value to achieve more injects. Set to a negative
integer to inject after all.



=item C<pre_proc_dump>, C<post_proc_dump>, C<engine_dump>, C<cache_dump>,
C<core_dump>

State: Transient

Default: Disabled

Set to 1 to activate, C<exit()>s after completion.

Print to STDOUT using Data::Dumper the structure of the data following the
respective phase. The C<core_dump> will print the state of the data, as well
as the current state of the entire DES object.

NOTE: The 'post_proc' phase is run in such a way that the filters can be
daisy-chained. Due to this reason, the value of C<post_proc_dump> works a
little differently. For example:

    post_proc => ['one', 'two'];

...will execute filter 'one' first, then filter 'two' with the data that came
out of filter 'one'. Simply set the value to the number that coincides with
the location of the filter. For instance, C<post_proc_dump =E<gt> 2;> will
dump the output from the second filter and likewise, C<1> will dump after the
first.

For C<cache_dump>, if it is set to one, it'll dump cache but the application
will continue. Set this parameter to an integer larger than one to have the
application C<exit> immediately after dumping the cache to STDOUT.


=item C<pre_proc_return>, C<post_proc_return>, C<engine_return>

State: Transient

Default: Disabled

Returns the structure of data immediately after being processed by the
respective phase. Useful for writing new 'phases'. (See "SEE ALSO" for
details).

NOTE: C<post_proc_return> does not behave like C<post_proc_dump>. It will
only return after all post_procs have executed.




=item C<config_dump>

State: Transient

Default: Disabled

Prints to C<STDOUT> with C<Data::Dumper> the current state of all loaded
configuration parameters.



=item C<pre_proc, post_proc, engine>

State: Transient

Default: undef

These are mainly used to set up the public methods with the proper callbacks
used by the C<run()> command.

C<engine> and C<pre_proc> take either a single string that contains a valid
built-in callback, or a single code reference of a custom callback.

C<post_proc> works a lot differently. These modules can be daisy-chained.
Like C<engine> and C<pre_proc>, you can send in a string or cref, or to chain,
send in an aref where each element is either a string or cref. The filters
will be executed based on their order in the array reference.


=back



=head1 REPOSITORY



L<https://github.com/stevieb9/devel-examine-subs>

=head1 BUILD REPORTS

CPAN Testers: L<http://matrix.cpantesters.org/?dist=Devel-Examine-Subs>

=head1 DEBUGGING

If C<Devel::Trace::Subs> is installed, you can configure stack tracing.

In your calling script, set C<$ENV{DES_TRACE} = 1>.

See C<perldoc Devel::Trace::Subs> for information on how to access the traces.


=head1 SEE ALSO

=over 4

=item C<perldoc Devel::Examine::Subs::Preprocessor>

Information related to the 'pre_proc' phase core modules.

=item C<perldoc Devel::Examine::Subs::Postprocessor>

Information related to the 'post_proc' phase core modules.

=item C<perldoc Devel::Examine::Subs::Engine>

Information related to the 'engine' phase core modules.

=back







=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Examine::Subs

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the
Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
