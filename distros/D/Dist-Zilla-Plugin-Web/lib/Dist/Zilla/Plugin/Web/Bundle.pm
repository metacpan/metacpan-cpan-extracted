package Dist::Zilla::Plugin::Web::Bundle;
$Dist::Zilla::Plugin::Web::Bundle::VERSION = '0.0.10';
# ABSTRACT: Bundle the library files into "tasks", using information from components.json 

use Moose;

with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::FileMunger';

use Dist::Zilla::File::Generated;

use JSON -support_by_pp, -no_export;
use Path::Class;
use IPC::Run qw( run );
use File::ShareDir;
use Capture::Tiny qw/capture/;


has 'lazy' => (
    isa     => 'Bool',
    is      => 'rw',
    
    default => 0
);



has 'filename' => (
    isa     => 'Str',
    is      => 'rw',
    
    default => 'components.json'
);


has 'lib_dir' => (
    isa     => 'Str',
    is      => 'rw',
    
    default => 'lib'
);


has 'bundle_files' => (
    is      => 'rw',
    
    default => sub { {} }
);


has 'npm_root' => (
    is      => 'ro',
    
    lazy    => 1,
    
    builder => '_get_npm_root',    
);


has 'components' => (
    is          => 'ro',
    lazy        => 1,
    builder     => '_build_components_info',
);


#================================================================================================================================================================================================================================================
sub _build_components_info {
    my ($self) = @_;

    my $content = file($self->filename)->slurp;

    #removing // style comments
    $content =~ s!//.*$!!gm;

    #extracting from outermost {} brackets
    $content =~ m/(\{.*\})/s;
    $content = $1;
    
    my $json = JSON->new->relaxed->allow_singlequote->allow_barekey;

    return $json->decode($content);
}



#================================================================================================================================================================================================================================================
sub gather_files {
}


#================================================================================================================================================================================================================================================
# need to build bundles in the "munge" phase - to allow other munge plugins to modify the sources
sub munge_files {
    my ($self) = @_;
    
    $self->process_components();
}


#================================================================================================================================================================================================================================================
sub process_components {
    my $self = shift;
    
    return unless -f $self->filename;
    
    my $components = $self->components;
    
    foreach my $component (keys(%$components)) {
        $self->process_component($components, $component);
    }
    
    # unless the lazy flag is set (false by default) - generate the content of all bundles right away
    # otherwise leave them, allowing to other mungers to modify the individual source files before bundling
    unless ($self->lazy) {
        $_->content foreach (values(%{$self->bundle_files})) ;
    } 
}


#================================================================================================================================================================================================================================================
sub process_component {
    my ($self, $components, $component) = @_;
    
    my $componentInfo   = $components->{ $component };
    $componentInfo      = { contains => $componentInfo } if ref $componentInfo eq 'ARRAY';
    
    my $saveAs          = $componentInfo->{ saveAs };
    
    $self->bundle_files->{ $component } = Dist::Zilla::File::Generated->new({
        
        name => $saveAs || "foo.js",
        
        code => sub {
            my $bundle_content  = ''; 
            my $is_js           = 1;
            
            foreach my $entry (@{$componentInfo->{ contains }}) {
                $is_js = 0 if $entry =~ /\.css$/;
                
                $bundle_content .= $self->get_entry_content($entry, $component) . ($is_js ? ";\n" : '');
            }
            
            my $minify = $componentInfo->{ minify } || '';
            
            if ($minify eq 'yui') {
                my $yui     = dir( File::ShareDir::dist_dir('Dist-Zilla-Plugin-Web'), 'minifiers' )->file('yuicompressor-2.4.6.jar') . '';
                my $type    = $is_js ? 'js' : 'css';
                
                my ($child_out, $child_err);

                my $success = run [ "java", "-jar", "$yui", "--type", "$type" ], '<', \$bundle_content, '>', \$child_out, '2>', \$child_err;
                
                die "Error during minification with YUI: $child_err" unless $success;                
                
                $bundle_content = $child_out;
            }
            
            return $bundle_content;
        }
    });
    
    # only store the bundles that has "saveAs"     
    if ($saveAs) {
        my $already_has_file    = $self->get_dzil_file($saveAs);
        
        $self->zilla->prune_file($already_has_file) if $already_has_file;
        
        $self->add_file($self->bundle_files->{ $component }); 
    }
}


#================================================================================================================================================================================================================================================
sub get_entry_content {
    my ($self, $entry, $component) = @_;
    
    if ((ref $entry eq 'HASH') && $entry->{ text }) {
        
        return $entry->{ text };
        
    } elsif ($entry =~ /^\+(.+)/) {
        
        my $bundleFile  = $self->bundle_files->{ $1 };
        
        die "Reference to non-existend bundle [$1] from [$component]" if !$bundleFile;
        
        return $bundleFile->content;
    
    } elsif ($entry !~ /\// && $entry !~ /\.js$/ && $entry !~ /\.css$/) {
        
        return $self->get_file_content($self->entry_to_filename($entry), $component);
        
    } else {
        return $self->get_file_content($entry, $component);
    } 
}


#================================================================================================================================================================================================================================================
sub get_dzil_file {
    my ($self, $file_name) = @_;
    
    my $found;
    
    for my $file (@{$self->zilla->files}) {
        
        if ($file->name eq $file_name) {
            $found = $file;
            
            last;
        }
    }
    
    return $found;
}


#================================================================================================================================================================================================================================================
sub get_file_content {
    my ($self, $file_name, $component) = @_;
    
    my $found = $self->get_dzil_file($file_name);
    
    # return content of gathered file if found
    return $found->content if $found;
    
    # return content of file in the distribution if presenteed
    return file($file_name)->slurp . '' if -e $file_name;
    
    # when file name starts with "node_modules" also look in global modules (as last resort) 
    if ($file_name =~ m!^node_modules/(.*)!) {
        my $npm_file_name = dir($self->npm_root)->file($1);
        
        return file($npm_file_name)->slurp . '' if -e $npm_file_name;
    }
    
    # cry out
    die "Can't find file [$file_name] in [$component]"; 
}


#================================================================================================================================================================================================================================================
sub _get_npm_root {
    
    my $child_exit_status;
    
    my ($npm_root, $stderr) = capture {
        system('npm root -g');
        
        $child_exit_status = $? >> 8;
    };    
    
    die "Error when getting npm root: $child_exit_status" if $child_exit_status;
    
    chomp($npm_root);
    
    return $npm_root;
}




#================================================================================================================================================================================================================================================
sub entry_to_filename {
	my ($self, $entry) = @_;
	
    my @dirs = split /\./, $entry;
    $dirs[-1] .= '.js';
	
	return file($self->lib_dir, @dirs);
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Web::Bundle - Bundle the library files into "tasks", using information from components.json 

=head1 VERSION

version 0.0.10

=head1 SYNOPSIS

In your F<dist.ini>:

    [NPM::Bundle]
    filename = components.json ; default

In your F<components.json>:

    {
        
        Core : {
            contains    : [
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
        }
        
        
        Prereq : {
            
            contains    : [
                "node_modules/task-joose-stable/joose-stable.js",
                "node_modules/joosex-attribute/joosex-attribute.js"
            ],
        },
        
        
        All : {
            saveAs      : 'kiokujs-all.js',
            
            contains    : [
                "+Core",
                "+Prereq"
            ]
        },
        
        
        AllMin : {
            saveAs      : 'kiokujs-all-min.js',
            
            minify      : 'yui',
            
            contains    : [
                "+All"
            ]
        }
    } 

=head1 DESCRIPTION

This plugins concatenates several source files into single bundle using the information from components.json file.

This files contains a simple JavaScript assignment (to allow inclusion via <script> tag) of the JSON structure.

First level entries of the JSON structure defines a bundles. Each bundle is an array of entries. 

Entry, starting with the "+" prefix denotes the content of another bundle.

All other entries denotes the javascript files from the "lib" directory. For example entry "KiokuJS.Reference" will be fetched
as the content of the file "lib/KiokuJS/Reference.js"

All bundles are stored as "lib/Task/Distribution/Name/BundleName.js", assuming the name of the distrubution is "Distribution-Name"
and name of bundle - "BundleName". During release, all bundles also gets added to the root of distribution as
"task-distribution-name-bundlename.js". To enable the latter feature for regular builds add the `roots_only_for_release = 0` config option  

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
