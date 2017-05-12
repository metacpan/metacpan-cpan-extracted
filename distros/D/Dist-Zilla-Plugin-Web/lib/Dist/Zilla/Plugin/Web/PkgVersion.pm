package Dist::Zilla::Plugin::Web::PkgVersion;
$Dist::Zilla::Plugin::Web::PkgVersion::VERSION = '0.0.10';
# ABSTRACT: Embedd module version to sources

use Moose;

use Path::Class;

with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Plugin::Web::Role::FileMatcher';



sub munge_files {
    my ($self) = @_;
    
    $self->for_each_matched_file(sub {
        my ($file)    = @_;

        my $content             = $file->content;
        my $content_copy        = $content;
        
        pos $content = 0;
        
        
        while ($content =~ m!
            ( (\s*) /\*  VERSION  (?'comma',)?  \*/)  
        !msxg) {
            
            my $overall             = $1;
            my $overall_quoted      = quotemeta $overall;
            
            my $comma               = $3 || '';
            my $whitespace          = $2;
            
            my $version             = $self->zilla->version;
            
            $version = "'$version'" if $version !~ m/^\d+(\.\d+)?$/;
            
            $content_copy =~ s!$overall_quoted!${whitespace}/*PKGVERSION*/VERSION : ${version}${comma}!;
        }
        
        $file->content($content_copy) if $content_copy ne $content;
    });
}


no Moose;
__PACKAGE__->meta->make_immutable();


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Web::PkgVersion - Embedd module version to sources

=head1 VERSION

version 0.0.10

=head1 SYNOPSIS

In your F<dist.ini>:

    [Web::PkgVersion]
    file_match = ^lib/.*\.js$           ; default, regex for file names to process 
    file_match = ^lib/.*\.css$          ; allow several values
    excelude_match = ^lib/special.css$  ; default, regex for file names to exclude 
                                        ; from processing
    excelude_match = ^lib/donotinclude.css$  ; allow several values

In your sources:

    Class('Digest.MD5', {
        
        /*VERSION,*/
        
        has : {
            ...
        }
    })
    
    Class('Digest.MD5', {
        /*VERSION*/
    })

will become after build:

    Class('Digest.MD5', {
        
        VERSION : 0.01,
         
        has : {
            ...
        }
    })
    
    Class('Digest.MD5', {
        VERSION : 0.01
    })

=head1 DESCRIPTION

This plugin will process the files in your distribution, matching any of the "file_match" regular expressions. 
Files matching any of the "excelude_match" regular expression will not be processed.

Processing will mean the following: this plugin will replace the 

    /*VERSION*/
    /*VERSION,*/ 

placeholders with the distribution version.  

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
