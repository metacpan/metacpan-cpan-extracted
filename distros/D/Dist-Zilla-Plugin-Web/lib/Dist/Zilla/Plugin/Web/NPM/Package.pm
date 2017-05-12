package Dist::Zilla::Plugin::Web::NPM::Package;
$Dist::Zilla::Plugin::Web::NPM::Package::VERSION = '0.0.10';
# ABSTRACT: Generate the `package.json` file, suitable for `npm` package manager 

use Moose;

with 'Dist::Zilla::Role::FileGatherer';
# to allow `dzil run` commands
with 'Dist::Zilla::Role::BuildRunner';

with 'Dist::Zilla::Role::AfterBuild';

use Dist::Zilla::File::FromCode;

use JSON 2;
use Path::Class;

use File::ShareDir;
use Cwd;


has 'name' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default => sub {
        return lc($_[0]->zilla->name)
    }
);


has 'version' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default => sub {
        my $version = $_[0]->zilla->version;
        
        $version .= '.0' if $version !~ m!\d+\.\d+\.\d+!;
        
        # strip leading zeros
        $version =~ s/\.0+(\d+)/.$1/g;
        
        return $version
    }
);


has 'author' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default => sub {
        return $_[0]->zilla->authors->[0]
    }
);


has 'description' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default => sub {
        return $_[0]->zilla->abstract
    }
);


has 'homepage' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default => sub {
        my $meta = $_[0]->zilla->distmeta;
        
        return $meta->{ resources } && $meta->{ resources }->{ homepage }
    }
);


has 'repository' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default => sub {
        my $meta = $_[0]->zilla->distmeta;
        
        return $meta->{ resources } && $meta->{ resources }->{ repository }
    }
);


has 'contributor' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default => sub {
        my @authors = @{$_[0]->zilla->authors};
        
        shift @authors;
        
        return \@authors;
    }
);


has 'main' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default => sub {
        my $name = $_[0]->zilla->name;
        
        $name =~ s!-!/!g;
        
        return 'lib/' . $name;
    }
);


has 'dependency' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default     => sub { [] }
);


has 'devDependency' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default     => sub { [] }
);



has 'engine' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default     => sub { [] }
);


has 'bin' => (
    is          => 'rw',
    
    default     => sub { [] }
);


has 'links_deps' => (
    is          => 'rw',
    
    default     => 1
);



#================================================================================================================================================================================================================================================
# to satisfy BuildRunner
sub build {
}



#================================================================================================================================================================================================================================================
sub gather_files {
    my ($self) = @_;
    
    $self->add_file(Dist::Zilla::File::FromCode->new({
        
        name => file('package.json') . '',
        
        code => sub {
            
            my $package = {};
            
            $package->{ $_ } = $self->$_ for qw( name version description homepage repository author main );
            
            $package->{ contributors }  = $self->contributor;
            $package->{ dependencies }  = $self->convert_dependencies($self->dependency) if @{$self->dependency} > 0;
            $package->{ dependencies }  = $self->convert_dependencies($self->dependency) if @{$self->dependency} > 0;
            
            $package->{ engines }       = $self->convert_engines($self->engine) if @{$self->engine} > 0;
            
            $package->{ directories }   = {
                "doc" => "./doc/mmd",
                "man" => "./man",
                "lib" => "./lib"
            };            
            
            $package->{ bin }           = $self->convert_dependencies($self->bin) if @{$self->bin} > 0;
                        
            return JSON->new->utf8(1)->pretty(1)->encode($package)
        }
    }));
}


#================================================================================================================================================================================================================================================
sub convert_dependencies {
	my ($self, $deps) = @_;
	
	my %converted = map {
	    
	    my $dep = $_;
	    
	    $dep =~ m/   ['"]?  ([\w\-._]+)  ['"]?  \s*   (.*)/x;
	    
	    $1 => ($2 || '*');
	    
	} (@$deps);
	
	return \%converted;
}


#================================================================================================================================================================================================================================================
sub convert_engines {
    my ($self, $engines) = @_;
    
    my @converted = map {
        
        my $engine = $_;
        
        $engine =~ m/^["']?(.*?)["']?$/;
        
        $1 || '';
        
    } (@$engines);
    
    return \@converted;
}


#================================================================================================================================================================================================================================================
sub mvp_multivalue_args { 
    qw( contributor dependency devDependency engine bin ) 
}


#================================================================================================================================================================================================================================================
sub after_build {
    my ($self, $params) = @_;
    
    return unless $self->links_deps;
    
    my $build_root  = $params->{ build_root };
    
    my $dir = getcwd;
    
    chdir($build_root);
    
    for my $package (keys(%{$self->convert_dependencies($self->dependency)})) {
        next if -d dir($build_root, "node_modules", $package);
        
        my $res = `npm link $package`;
        
        chomp($res);
        
        $self->log($res);
    }
    
    for my $package (keys(%{$self->convert_dependencies($self->devDependency)})) {
        next if -d dir($build_root, "node_modules", $package);
        
        my $res = `npm link $package`;
        
        chomp($res);
        
        $self->log($res);
    }
    
    chdir($dir);
}






no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Web::NPM::Package - Generate the `package.json` file, suitable for `npm` package manager 

=head1 VERSION

version 0.0.10

=head1 SYNOPSIS

In your F<dist.ini>:

    [Web::NPM::Package]
    
    name            = some-distro   ; lowercased distribution name if not provided
    version         = 1.2.3         ; version, appended with ".0" to conform semver
                                    ; (if not provided)
                                    
    author          = Clever Guy <cg@cleverguy.org> ; the 1st specified author
    
    contributor     = Clever Guy2 <cg2@cleverguy.org> ; note the singular spelling
    contributor     = Clever Guy3 <cg3@cleverguy.org> ; other authors from main config
    
    description     = Some clever, yet compact description ; asbtract from main config

    homepage        = http://cleverguy.org      ; can recommend Dist::Zilla::Plugin::GithubMeta
    repository      = git://git.cleverguy.org   ;
    
    main            = 'lib/some/distro'         ; default to main module in distribution
    
    dependency      = foo 1.0.0 - 2.9999.9999           ; note the singular spelling
    dependency      = bar >=1.0.2 <2.1.2                ; 
    
    engine          = node >=0.1.27 <0.1.30             ; note the singular spelling
    engine          = dode >=0.1.27 <0.1.30             ;
    
    bin             = bin_name ./bin/path/to.js 

=head1 DESCRIPTION

Generate the "package.json" file for your distribution, based on the content of "dist.ini"

Link the dependencies (including "devDepencies" after build). Linking is not performed, if the distribution
already contains the package in "node_modules"

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
