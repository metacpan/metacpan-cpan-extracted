package Github::Fork::Parent;

use 5.006;
use strict;
use warnings;

=head1 NAME

Github::Fork::Parent - Perl module to determine which repository stands in a root of GitHub forking hierarchy.

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.01';


=head1 SYNOPSIS

my $parent_url = github_parent('git://github.com/chorny/plagger.git');
#returns https://github.com/miyagawa/plagger

=head1 FUNCTIONS

=head2 github_parent

Takes link to repository (git://, git@ or http://) and returns http link to root repository.

=head2 github_parent_author

Takes link to repository (git://, git@ or http://) and returns owner of root repository.

=cut

use JSON;
#use YAML::Tiny 1.40;
use LWP::UserAgent;

use Exporter 'import';
our @EXPORT = qw(github_parent github_parent_author);

sub get_repo_data {
  my ($author,$project)=@_;
  #my $url = "http://github.com/api/v2/yaml/repos/show/$author/$project/network";
  my $url = "https://api.github.com/repos/$author/$project";

  my $ua=LWP::UserAgent->new();
  $ua->timeout(50);
  my $response = $ua->get($url);
  if ($response->is_success) {
    my $yaml = $response->content();
    return $yaml;
  } else {
    if ($response->code eq '404') {
      return undef;
    } else {
      die "Could not GET data (".$response->status_line.")";
    }
  }
}

sub parse_github_links {
  my $link=shift;
  $link =~ s/\.git$//; #github does not allow repositories ending in .git, so we can safely remove extension
  if ($link=~m{^
    (?:\Qgit://github.com/\E|git\@github\.com:|https?://github\.com/)
    ([^/]+)/([^/]+) #repository name can contain dots
    $ }x 
  ) {
    return ($1,$2);
  } else {
    return (undef,undef);
  }
  
}

sub github_parent {
  my $link=shift;
  my ($author,$project)=parse_github_links($link);
  return $link unless $author;
  my $yaml_content=get_repo_data($author,$project);
  if ($yaml_content) {
    #my $yaml=YAML::Tiny->read_string($yaml_content) or die;
    my $yaml=decode_json($yaml_content);
    my $source_url=$yaml->{source}{html_url};
    die unless $source_url;
    return $source_url;
  } else {
    die "No content for $author/$project";
  }
}

sub github_parent_author {
  #my $link=shift;
  #my $link1=github_parent($link);
  #my ($author,$project)=parse_github_links($link1);
  #die "Cannot get author from '$link1'" unless $author;
  #return $author;
  my $link=shift;
  my ($author,$project)=parse_github_links($link);
  return $link unless $author;
  my $yaml_content=get_repo_data($author,$project);
  if ($yaml_content) {
    #my $yaml=YAML::Tiny->read_string($yaml_content) or die;
    my $yaml=decode_json($yaml_content);
    return $author unless $yaml->{'fork'};
    my $source=$yaml->{source}{owner}{login};
    die "No login in YAML for $link" unless $source;
    return $source;
  } else {
    die "No content";
  }
}

=head1 AUTHOR

Alexandr Ciornii, C<< <alexchorny at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-github-fork-parent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Github-Fork-Parent>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Github::Fork::Parent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Github-Fork-Parent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Github-Fork-Parent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Github-Fork-Parent>

=item * Search CPAN

L<http://search.cpan.org/dist/Github-Fork-Parent/>

=back


=head1 SEE ALSO

Net::GitHub

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009-2017 Alexandr Ciornii.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Github::Fork::Parent
