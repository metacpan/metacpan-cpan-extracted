package Dist::Zilla::Plugin::JSAN::Bundle;
BEGIN {
  $Dist::Zilla::Plugin::JSAN::Bundle::VERSION = '0.06';
}

# ABSTRACT: Bundle the library files into "tasks", using information from Components.JS 

use Moose;

with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::FileMunger';

use Dist::Zilla::File::FromCode;

use JSON 2;
use Path::Class;
use Capture::Tiny qw/capture/;


has 'npm_root' => (
    isa     => 'Str',
    is      => 'rw',
);


has 'roots_only_for_release' => (
    is      => 'rw',
    default => 1
);


#================================================================================================================================================================================================================================================
sub gather_files {
}


#================================================================================================================================================================================================================================================
sub munge_files {
    my $self = shift;
    
    return unless -f 'Components.JS';
    
    my $components = file('Components.JS')->slurp;

    #removing // style comments
    $components =~ s!//.*$!!gm;

    #extracting from outermost {} brackets
    $components =~ m/(\{.*\})/s;
    $components = $1;

    my $deploys = decode_json $components;

    foreach my $deploy (keys(%$deploys)) {
        $self->concatenate_for_task($deploys, $deploy);
    }
}


#================================================================================================================================================================================================================================================
sub concatenate_for_task {
    my ($self, $deploys, $task_name) = @_;
    
    my @components = $self->expand_task_entry($deploys, $task_name);
    die "No components in task: [$task_name]" unless @components > 0;
    
    my @dist_dirs = split /-/, $self->zilla->name;
    push @dist_dirs, $task_name;
    $dist_dirs[-1] .= '.js';
    
    my $generate    = sub {
        my $bundle_content = ''; 
        
        foreach my $comp (@components) {
            $bundle_content .= $self->get_component_content($comp) . ";\n";
        }
        
        return $bundle_content;
    };
    
    $self->add_file(Dist::Zilla::File::FromCode->new({
        
        name => file('lib', 'Task', @dist_dirs) . '',
        
        code => $generate
    }));
    
    if (!$self->roots_only_for_release || $ENV{ DZIL_RELEASING }) {
    
        my $root_file_name = join("-", 'task', map { lc } @dist_dirs);
        
        $self->add_file(Dist::Zilla::File::FromCode->new({
            
            name => file($root_file_name) . '',
            
            code => $generate
        }));
    }
}


#================================================================================================================================================================================================================================================
sub expand_task_entry {
    my ($self, $deploys, $task_name, $seen) = @_;
    
    $seen = {} if !$seen;
    
    die "Recursive visit to task [$task_name] when expanding entries" if $seen->{ $task_name };
    
    $seen->{ $task_name } = 1; 
    
    return map { 
			
		/^\+(.+)/ ? $self->expand_task_entry($deploys, $1, $seen) : $_;
		
	} @{$deploys->{ $task_name }};    
}


#================================================================================================================================================================================================================================================
sub get_component_content {
    my ($self, $component) = @_;
    
    if ((ref $component eq 'HASH') && $component->{ text }) {
        
        return $component->{ text };
    
    } elsif ($component =~ /^jsan:(.+)/) {
        
        my @file = ($self->get_npm_root, '.jsan', split /\./, $1);
        $file[ -1 ] .= '.js';
        
        return file(@file)->slurp;
    } elsif ($component =~ /^=(.+)/) {
        return file($1)->slurp;
    } else {
        my $file_name = $self->comp_to_filename($component);
        
        my ($found) = grep { $_->name eq $file_name } (@{$self->zilla->files});
        
        return $found->content;
    } 
}


#================================================================================================================================================================================================================================================
sub get_npm_root {
    my ($self) = @_;
    
    return $self->npm_root if $self->npm_root;
    
    $self->log('Trying to determine the `root` config setting of `npm`');
    
    my $root = $ENV{npm_config_root};
    
    if ($root) {
        
        $self->npm_root($root);
        
        $self->log("Found: [$root]");
        
        return $self->npm_root;
    };
    
    my $exit_code;
    
    my ($stdout, $stderr) = capture {
        system('npm root -g');
        
        $exit_code = $? >> 8;
    };
    
    chomp($stdout);
    
    if (!$exit_code) {
        $self->log("Found: [$stdout]");
        
        $self->npm_root($stdout);
        
        return $self->npm_root;
    };
    
    $self->log('`npm config get root` failed, trying with [sudo]');
    
    ($stdout, $stderr) = capture {
        system('sudo npm config get root');
        
        $exit_code = $? >> 8;
    };
    
    chomp($stdout);
    
    if (!$exit_code) {
        $self->log("Found: [$stdout]");
        
        $self->npm_root($stdout);
        
        return $self->npm_root;
    };
    
    die "Can't determine the `npm` root"; 
}


#================================================================================================================================================================================================================================================
sub comp_to_filename {
	my ($self, $comp) = @_;
	
    my @dirs = split /\./, $comp;
    $dirs[-1] .= '.js';
	
	return file('lib', @dirs);
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;



__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::JSAN::Bundle - Bundle the library files into "tasks", using information from Components.JS 

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your F<dist.ini>:

    [JSAN::Bundle]

In your F<Components.JS>:

    COMPONENTS = {
        
        "Core" : [
            "KiokuJS.Reference",
            
            "KiokuJS.Exception",
            "KiokuJS.Exception.Network",
            "KiokuJS.Exception.Format",
            "KiokuJS.Exception.Overwrite",
            "KiokuJS.Exception.Update",
            "KiokuJS.Exception.Remove",
            "KiokuJS.Exception.LookUp",
            "KiokuJS.Exception.Conflict"
        ],
        
        
        "Prereq" : [
            "=/home/cleverguy/js/some/file.js",
            "jsan:Task.Joose.Core",
            "jsan:Task.JooseX.Attribute.Bootstrap",
            
            "jsan:Task.JooseX.Namespace.Depended.NodeJS",
            
            "jsan:Task.JooseX.CPS.All",
            "jsan:Data.UUID",
            "jsan:Data.Visitor"
        ],
        
        
        "All" : [
            "+Core",
            "+Prereq"
        ]
    } 

=head1 DESCRIPTION

This plugins concatenates several source files into single bundle using the information from Components.JS file.

This files contains a simple JavaScript assignment (to allow inclusion via <script> tag) of the JSON structure.

First level entries of the JSON structure defines a bundles. Each bundle is an array of entries. 

Entry, starting with the "=" prefix denotes the file from the filesystem. 

Entry, starting with the "jsan:" prefix denotes the module from the jsan library. See L<Module::Build::JSAN::Installable>.

Entry, starting with the "+" prefix denotes the content of another bundle.

All other entries denotes the javascript files from the "lib" directory. For example entry "KiokuJS.Reference" will be fetched
as the content of the file "lib/KiokuJS/Reference.js"

All bundles are stored as "lib/Task/Distribution/Name/BundleName.js", assuming the name of the distrubution is "Distribution-Name"
and name of bundle - "BundleName". During release, all bundles also gets added to the root of distribution as
"task-distribution-name-bundlename.js". To enable the latter feature for regular builds add the `roots_only_for_release = 0` config option  

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

