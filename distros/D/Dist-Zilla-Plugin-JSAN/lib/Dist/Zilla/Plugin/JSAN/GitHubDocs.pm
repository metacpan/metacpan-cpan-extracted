package Dist::Zilla::Plugin::JSAN::GitHubDocs;
BEGIN {
  $Dist::Zilla::Plugin::JSAN::GitHubDocs::VERSION = '0.06';
}

# ABSTRACT: a plugin for Dist::Zilla which updates the 'gh-pages' branch after each release

use Moose;

use Archive::Tar;
use Git::Wrapper;
use File::Temp;
use Path::Class;
use Cwd qw(abs_path);

with 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::Git::DirtyFiles';


has 'extract' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'doc/html'
);


has 'push_to' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'origin'
);


has 'redirect_prefix' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'doc/html'
);


sub dist_name_as_url {
    my ($self) = @_;
    
    return join '/', (split /-/, $self->zilla->name);
}


sub after_release {
    my ($self, $archive) = @_;
    
    my $git             = Git::Wrapper->new('.');
    my $gh_exists       = eval { $git->rev_parse( '--verify', '-q', 'gh-pages' ); 1; };
    
    
    my @dirty_files = $self->list_dirty_files($git);
    
    if (@dirty_files) {
        $self->log_fatal("There are dirty files in the repo: [ @dirty_files ] - can't update gh-pages branch"); 
    }
    
    $self->log("Updating `gh-pages` branch");
    
    
    # setting up the temporary git repo
     
    my $temp_dir        = File::Temp->newdir();
    my $git_gh_pages    = Git::Wrapper->new( $temp_dir . '');
    
    $git_gh_pages->init('-q');
    
    $git_gh_pages->remote('add', 'src', abs_path('.'));
    $git_gh_pages->fetch(qw(-q src));
    
    
    if ($gh_exists) {
        $git_gh_pages->checkout('remotes/src/gh-pages');
    } else {
        $git_gh_pages->symbolic_ref('HEAD', 'refs/heads/gh-pages');
        
        my $index_file = file($temp_dir, 'index.html');
        
        my $fh = $index_file->openw();
        
        my $redirect_url    = $self->redirect_prefix . '/' . $self->dist_name_as_url . '.html';
        
        print $fh <<INDEX
        
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="refresh" content="0;url=$redirect_url">
    </head>
    
    <body>
    </body>
</html>

INDEX
;
        $fh->close();        
    }


    # exracting the relevant files from tarball 
    
    my $extract = $self->extract;
    $extract =~ s!^/!!;
    
    $extract = qr/^$extract/; 
    
    my $next = Archive::Tar->iter($archive . '');
    
    while (my $file = $next->()) {
        
        my @extract_path = split '/', $file->full_path;
        
        shift @extract_path;
        
        my $extract_path = join '/', @extract_path;
        
        if ($extract_path =~ $extract) {
            $file->extract( $temp_dir . '/' . $extract_path ) or warn "Extraction failed";    
        }
    }    

    # pushing updates  
    
    $git_gh_pages->add('.');
    
    # non-zero exit status if no files has been changed in docs
    eval {
        $git_gh_pages->commit('-m', '"gh-pages" branch update');
    }; 
    
    if ($gh_exists) {
        $git_gh_pages->checkout('-b', 'gh-pages');
    } 
    
    $git_gh_pages->push('src', 'gh-pages');
    
    $git->push($self->push_to, 'gh-pages');
    
    $self->log("`gh-pages` branch has been successfully updated");
}



__PACKAGE__->meta->make_immutable;
no Moose;

1; 



__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::JSAN::GitHubDocs - a plugin for Dist::Zilla which updates the 'gh-pages' branch after each release

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your F<dist.ini>:

    [JSAN::GitHubDocs]
    extract             = doc/html          ; default value
    redirect_prefix     = doc/html          ; default value
    push_to             = origin            ; default value

=head1 DESCRIPTION

After release, this plugin will extract the documentation from the tarball, using the 'extract' parameter to the 'gh-pages' branch of your repo.
Then it will push the updates to the "push_to" remote. 

The documentation then will be available as

    http://your_lowercased_github_user_name.github.com/Your-Dist-Name 

The plugin will add the "index.html" file, which redirects the user from the link above to the documentation of the main module (using 'redirect_prefix'
parameter):

    http://your_lowercased_github_user_name.github.com/Your-Dist-Name/doc/html/Your/Dist/Name.html

=cut

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

