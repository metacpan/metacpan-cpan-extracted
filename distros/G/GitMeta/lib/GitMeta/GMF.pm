###########################################
package GitMeta::GMF;
###########################################
# 2010, Mike Schilli <m@perlmeister.com>
###########################################
use strict;
use warnings;
use base qw(GitMeta);
use File::Temp qw(tempdir);
use Log::Log4perl qw(:easy);
use YAML qw(Load);
use Sysadm::Install qw(:all);
use File::Basename;

###########################################
sub expand {
###########################################
  my($self) = @_;

  $self->param_check("repo", "gmf_path");

  my $yml = $self->_fetch( 
      $self->{repo}, 
      $self->{gmf_path} );

  my @locs  = ();

  for my $entry ( @$yml ) {
    my $type = ref($entry);

    if($type eq "") {
      # plain git url
      push @locs, $entry;
    } else {
      my $class = "GitMeta::" .
               ucfirst( $entry->{type} );
      eval "require $class;" or
         LOGDIE "Class $class missing";
      my $expander = $class->new(%$entry);
      push @locs, $expander->expand();
    }
  }

  return @locs;
}

###########################################
sub _fetch {
###########################################
    my($self, $git_repo, $gmf_path) = @_;

    my $data;

    if( defined $git_repo ) {
        my($tempdir) = tempdir( CLEANUP => 1 );
        cd $tempdir;
        tap "git", "clone", $git_repo;
        $data = slurp(basename($git_repo) . 
                         "/$gmf_path");
        cdback;
    } else {
        $data = slurp( $gmf_path );
    }

    my $yml = Load( $data );

    return $yml;
}

###########################################
sub repo_dir_from_git_url {
###########################################
    my( $self, $url ) = @_;

    my $repo_dir;

    if( $url =~ m#/# ) {
        $repo_dir = basename $url;
    } elsif( $url =~ m#:(.*)# ) {
        $repo_dir = $1;
    } else {
        die "cannot determine dir from git url: $url";
    }

    $repo_dir =~ s/\.git$//g;

    return $repo_dir;
}

1;

__END__

=head1 NAME

    GitMeta::GMF

=head1 SYNOPSIS

    # myrepos.gmf

    # Another .gmf file somewhere in another gitmeta repo
    -
        type: GMF
        repo: user@devhost.com:git/gitmeta
        gmf_path: privdev.gmf

=head1 DESCRIPTION

GitMeta subclass to pull in another .gmf file.
Read the main GitMeta documentation for details.

=head1 LEGALESE

Copyright 2010-2011 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2010, Mike Schilli <cpan@perlmeister.com>
