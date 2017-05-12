package Dist::Zilla::Plugin::JSAN::NPM;
BEGIN {
  $Dist::Zilla::Plugin::JSAN::NPM::VERSION = '0.06';
}

# ABSTRACT: Generate the `package.json` file, suitable for `npm` package manager 

use Moose;

with 'Dist::Zilla::Role::FileGatherer';

use Dist::Zilla::File::FromCode;

use JSON 2;
use Path::Class;

use File::ShareDir;


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


has 'engine' => (
    is          => 'rw',
    
    lazy        => 1,
    
    default     => sub { [] }
);


has 'bin' => (
    is          => 'rw',
    
    default     => ''
);



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
            
            $package->{ engines }       = $self->convert_engines($self->engine) if @{$self->engine} > 0;
            
            $package->{ directories }   = {
                "doc" => "./doc/mmd",
                "man" => "./man",
                "lib" => "./lib"
            };            
            
            $package->{ scripts }   = {
                "postactivate"  => '$SHELL __script/postactivate.sh',
                "postinstall"   => '$SHELL __script/postinstall.sh'
            };
            
            $package->{ bin }           = $self->bin if $self->bin;
                        
            return JSON->new->utf8(1)->pretty(1)->encode($package)
        }
    }));
    

    # backward compat with npm 0.3    
    $self->add_file(Dist::Zilla::File::FromCode->new({
        
        name => file('__script/postactivate.sh') . '',
        
        code => sub {
            
            return <<'POSTACTIVATE'

mkdir -p $npm_config_root/.jsan
cp -r ./lib/* $npm_config_root/.jsan      

POSTACTIVATE
        }
    }));
    
    
    $self->add_file(Dist::Zilla::File::FromCode->new({
        name => file('__script/postinstall.sh') . '',
        
        code => sub {
            return dir( File::ShareDir::dist_dir('Dist-Zilla-Plugin-JSAN') )->file('install_jsan.sh')->slurp;
        }
    }));
    
    
    $self->add_file(Dist::Zilla::File::FromCode->new({
        
        name => file('__script/semver.js') . '',
        
        code => sub {
            return dir( File::ShareDir::dist_dir('Dist-Zilla-Plugin-JSAN') )->file('semver.js')->slurp;
        }
    }));
    
}


#================================================================================================================================================================================================================================================
sub convert_dependencies {
	my ($self, $deps) = @_;
	
	my %converted = map {
	    
	    my $dep = $_;
	    
	    $dep =~ m/([\w\-\.]+)\s*(.+)/;
	    
	    $1 => $2;
	    
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
    qw( contributor dependency engine ) 
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;



__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::JSAN::NPM - Generate the `package.json` file, suitable for `npm` package manager 

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your F<dist.ini>:

    [JSAN::NPM]
    
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

=head1 DESCRIPTION

JSAN<->npm bridge, which generate the "package.json" file for your distribution, based on the content of "dist.ini"

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

