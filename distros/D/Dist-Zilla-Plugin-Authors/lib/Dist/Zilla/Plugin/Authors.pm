package Dist::Zilla::Plugin::Authors;
use strict;
use warnings;
use utf8;
use Git::Wrapper;
use List::MoreUtils qw(uniq);
use Moose;
with qw/Dist::Zilla::Role::FileGatherer/;

sub git_log_grep {
  my $string = shift;
  my $git = shift;
  return map { s/^\s*$string\s*//; $_ }
    grep { /$string/ }
    $git->RUN('log', {grep => $string});
}

sub gather_files {
  my ($self, $arg) = @_;
  my $file = Dist::Zilla::File::FromCode->new({
    name => 'AUTHORS',
    code_return_type => 'bytes',
    code => sub {
      my $git = Git::Wrapper->new('./');
      my @authors = $git->RUN('log', {pretty => "format:%aN <%aE>"});
      my @signed_authors = git_log_grep('Signed-off-by:', $git);
      my @co_authors = git_log_grep('Co-authored-by:', $git);
      foreach (@signed_authors, @co_authors) {
        eval {
          my @_co_authors = $git->RUN('check-mailmap', $_);
          push @authors, @_co_authors;
        };
      }
      return join("\n", uniq sort @authors);
    },
  });
  $self->add_file($file);
  return;
}

1;

__END__

=pod
 
=encoding UTF-8
 
=head1 NAME
 
Dist::Zilla::Plugin::Authors - Build AUTHORS file from Git history
 
=head1 VERSION
 
version 0.1.0

=head1 SYNOPSIS
 
If you want to auto-generate an AUTHORS file listing all commiters from Git
history you can use this Plugin like the example below.
 
    name = Foo-Bar
    [@Basic]
    [Authors]

=head1 DESCRIPTION
 
Auto generate AUTHORS file including every commiters in the format:

    Author Name <author email>

It collects also every author name on Git commit messages containing the
strings below:

    Signed-off-by: Author Name <author email>
    Co-authored-by: Author Name <author email>

The Dist::Zilla::Plugin::Authors respects the `.mailmap` to reduce duplication
of authors on the generated AUTHORS file.

=head1 AUTHOR
 
Joenio Marques da Costa <joenio@joenio.me>
 
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Joenio Marques da Costa.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
 
=cut
