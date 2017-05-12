package Dist::Zilla::Plugin::JSAN;
BEGIN {
  $Dist::Zilla::Plugin::JSAN::VERSION = '0.06';
}

# ABSTRACT: a plugin for Dist::Zilla for building JSAN distributions


use Moose;
use Moose::Autobox;

use Path::Class;
use Dist::Zilla::File::InMemory;

with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::BuildRunner';


has 'docs_markup' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'mmd'
);


has 'css_url' =>  (
    isa     => 'Str',
    is      => 'rw',
    default => 'http://joose.it/markdown.css'
);


#================================================================================================================================================================================================================================================
sub build {
}


#================================================================================================================================================================================================================================================
sub gather_files {
    my $self = shift;
    
    my $markup = $self->docs_markup;
    
    my $method = "generate_docs_from_$markup";
    
    $self->$method();
}


#================================================================================================================================================================================================================================================
sub generate_docs_from_md {
    my $self = shift;
    
    require Text::Markdown;
    
    $self->extract_inlined_docs({
        html => \sub {
            my ($comments, $content) = @_;
            return (Text::Markdown::markdown($comments), 'html')
        },
        
        md => \sub {
            my ($comments, $content) = @_;
            return ($comments, 'md');
        }
    })
}


#================================================================================================================================================================================================================================================
sub generate_docs_from_mmd {
    my $self = shift;
    
    require Text::MultiMarkdown;
    
    my $css_url = $self->css_url;
    
    $self->extract_inlined_docs({
        html => sub {
            my ($comments, $content) = @_;
            return (Text::MultiMarkdown::markdown("css: $css_url \n\n" . $comments, { document_format => 'Complete' }), 'html')
        },
        
        mmd => sub {
            my ($comments, $content) = @_;
            return ($comments, 'mmd');
        }
    })
}


#================================================================================================================================================================================================================================================
sub generate_docs_from_pod {
    my $self = shift;
    
    require Pod::Simple::HTML;
    require Pod::Simple::Text;
    require Pod::Select;
    
    $self->extract_inlined_docs({
        html => sub {
            my ($comments, $content) = @_;
            
            my $result  = '';
            my $parser  = Pod::Simple::HTML->new;
            
            $parser->output_string( \$result );
            
            $parser->parse_string_document($content);
            
            return ($result, 'html')
        },
        
        
        txt => sub {
            my ($comments, $content) = @_;
            
            my $result  = '';
            my $parser  = Pod::Simple::Text->new;
            
            $parser->output_string( \$result );
            
            $parser->parse_string_document($content);
            
            return ($result, 'txt')
        },
        
        
        pod => sub {
            my ($comments, $content) = @_;
            
            # XXX really extract pod using Pod::Select and temporary file
            return ($content, 'pod');
        }
    })
}


#================================================================================================================================================================================================================================================
sub find_dist_packages {
    my ($self) = @_;
    
    return $self->zilla->files->grep(sub { $_->name =~ m!^lib/.+\.js$! });
}


#================================================================================================================================================================================================================================================
sub find_file {
    my ($self, $file_name) = @_;
    
    return ( $self->zilla->files->grep(sub { $_->name eq $file_name }) )->[0];
}


#================================================================================================================================================================================================================================================
sub extract_inlined_docs {
    my ($self, $convertors) = @_;
    
    my $markup      = $self->docs_markup;
    my $lib_dir     = dir('lib');
    my $js_files    = $self->find_dist_packages;
    
    
    foreach my $file (@$js_files) {
        (my $separate_docs_file_name = $file->name) =~ s|\.js$|.$markup|;
        
        my $separate_docs_file   = $self->find_file($separate_docs_file_name);
        
        my $content         = $file->content;
        
        my $docs_content    = $separate_docs_file ? $separate_docs_file->content : $self->strip_doc_comments($content);


        foreach my $format (keys(%$convertors)) {
            
            #receiving formatted docs
            my $convertor = $convertors->{$format};
            
            my ($result, $result_ext) = &$convertor($docs_content, $content);
            
            
            #preparing 'doc' directory for current format 
            my $format_dir = dir('doc', $format);
            
            #saving results
            (my $res = $file->name) =~ s|^$lib_dir|$format_dir|;
            
            $res =~ s/\.js$/.$result_ext/;
            
            $self->add_file(Dist::Zilla::File::InMemory->new(
                name        => $res,
                content     => $result
            ));
        }
    }
}



#================================================================================================================================================================================================================================================
sub strip_doc_comments {
    my ($self, $content) = @_;
    
    my @comments = ($content =~ m[^\s*/\*\*(.*?)\*/]msg);
    
    return join '', @comments; 
}




__PACKAGE__->meta->make_immutable;
no Moose;

1; 



=pod

=head1 NAME

Dist::Zilla::Plugin::JSAN - a plugin for Dist::Zilla for building JSAN distributions

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In F<dist.ini>:

    name                = Sample-Dist
    abstract            = Some clever yet compact description
    
    author              = Clever Guy #1
    author              = Clever Guy #2
    license             = LGPL_3_0
    copyright_holder    = Clever Guy
    
    
    ;=========================================================================
    ; version provider
    
    [Git::NextVersion]
    first_version   = 0.0.1
    
    
    ;=========================================================================
    ; include the link to git repo and web page
    
    [GithubMeta]
    
    
    ;=========================================================================
    ; choose/generate files to include
    
    [GatherDir]
    [PruneCruft]
    [License]
    
    
    ;=========================================================================
    ; JSAN-specific configuration
    
    [JSAN]                          ; generate docs
    docs_markup         = mmd       ; default
    css_url             = http://joose.it/markdown.css  ; default
    
    [JSAN::StaticDir]
    static_dir          = static    ; default
    
    [JSAN::PkgVersion]
    
    [JSAN::ReadmeFromMD]            ; should be after docs generation
    [JSAN::InstallInstructions]     ; add INSTALL file, describing the installation process
    [JSAN::Bundle]                  ; after docs generation to avoid docs for bundles
    
    
    ;=========================================================================
    ; `npm` configuration - package.json generation
    
    [JSAN::NPM]
    main                            = lib/Task/Sample/Dist/Core
    
    dependency                      = joose >= 3.14.0
    
    
    ;=========================================================================
    ; before release
    
    [Git::Check]
    [CheckChangesHasContent]
    [ConfirmRelease]
    
    
    ;=========================================================================
    ; release
    
    [JSAN::NPM::Publish]        ; publish in `npm`
    sudo = 1
     
    
    ;=========================================================================
    ; after release
    
    [Git::Commit / Commit_Dirty_Files]
     
    [Git::Tag]
     
    [NextRelease]
    format = %-9v %{yyyy-MM-dd HH:mm}d
    
    [Git::Commit / Commit_Changes]
     
    [Git::Push]
    push_to = origin
    
    [JSAN::GitHubDocs]          ; after all commits to have clean workspace
    
    [Twitter]
    tweet_url     = http://cleverguy.github.com/Sample-Dist
    tweet         = Released {{ '{{$DIST}}-{{$VERSION}} {{$URL}}' }}
    hash_tags     = #nodejs #npm

=head1 DESCRIPTION

This is a plugin for distribution-management tool L<Dist::Zilla>. It greatly simplifies the release process,
allowing you to focus on the code itself.

=head1 PLUGINS

Any usual Dist::Zilla plugins can be used. In the SYNOPSIS above we've used L<Dist::Zilla::Plugin::Git::Check> and L<Dist::Zilla::Plugin::CheckChangesHasContent>.
Additionally several JSAN-specific plugins were added:

L<Dist::Zilla::Plugin::JSAN::Bundle> - concatenate individual source files into bundles, based on information from Components.JS file

L<Dist::Zilla::Plugin::JSAN::StaticDir> - moves the content of the static directory to the distribution folder

L<Dist::Zilla::Plugin::JSAN::GitHubDocs> - updates the `gh-pages` branch with the documentation after each release

L<Dist::Zilla::Plugin::JSAN::NPM> - generate `package.json` file for your distribution

L<Dist::Zilla::Plugin::JSAN::NPM::Publish> - publish your distribution in `npm`

L<Dist::Zilla::Plugin::JSAN::PkgVersion> - embed version number in the source files

L<Dist::Zilla::Plugin::JSAN::ReadmeFromMD> - copies a main documentation file to the distribution root as README.md 

L<Dist::Zilla::Plugin::JSAN::InstallInstructions> - generates INSTALL file in the root of distribution with installation instructions

=head1 STARTING A NEW DISTRIBUTION

This plugin allows you to easily start a new JSAN distribution. Read L<Dist::Zilla::Plugin::JSAN::Minter> to know how.

=head1 AUTHOR

Nickolay Platonov, C<< <nplatonov at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-JSAN> or
L<http://github.com/SamuraiJack/Dist-Zilla-Plugin-JSAN/issues>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SOURCES

This module is stored in an open repository at the following address:

L<http://github.com/SamuraiJack/Dist-Zilla-Plugin-JSAN>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Nickolay Platonov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__








