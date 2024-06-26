use strict;
use warnings;
package Git::Fingerd 2.093523;
use Net::Finger::Server 0.003;
BEGIN { our @ISA = qw(Net::Finger::Server); }
# ABSTRACT: let people finger your git server for... some reason

use Git::PurePerl;
use List::Util qw(max);
use Path::Class;
use SUPER;
use String::Truncate qw(elide);
use Text::Table;

#pod =head1 DESCRIPTION
#pod
#pod This module implements a simple C<finger> server that describes the contents of
#pod a server that hosts git repositories.  You can finger C<@servername> for a
#pod listing of repositories and finger C<repo@servername> for information about
#pod a single repository.
#pod
#pod This was meant to provide a simple example for Net::Finger::Server, but enough
#pod people asked for the code that I've released it as something reusable.  Here's
#pod an example program using Git::Fingerd:
#pod
#pod   #!/usr/bin/perl
#pod   use Git::Fingerd -run => {
#pod     isa     => 'Net::Server::INET',
#pod     basedir => '/var/lib/git',
#pod   };
#pod
#pod This program could then run out of F<xinetd>.
#pod
#pod =for Pod::Coverage new basedir
#pod
#pod =cut

sub new {
  my ($class, %config) = @_;

  my $basedir = delete $config{basedir} || Carp::croak('no basedir supplied');
  my $self = $class->SUPER(%config, log_level => 0);
  $self->{__PACKAGE__}{basedir} = $basedir;

  return $self;
}

sub basedir { $_[0]->{__PACKAGE__}{basedir} }

sub username_regex { qr{[-a-z0-9]+}i   }

sub listing_reply {
  my $basedir = $_[0]->basedir;
  my @dirs = sort <$basedir/*>;

  my $table = Text::Table->new('Repository', '  Description');

  my %repo;

  for my $i (reverse 0 .. $#dirs) {
    my $dir = $dirs[$i];
    my $mode = (stat $dir)[2];
    unless ($mode & 1) {
      splice @dirs, $i, 1;
      next;
    }

    my $repo = $dir;
    s{\A$basedir/}{}, s{\.git\z}{} for $repo;
    my $desc = `cat $dir/description`;
    chomp $desc;

    $repo{ $repo } = $desc;
  }

  my $desc_len = 79 - 3 - (List::Util::max map { length } keys %repo);

  for my $repo (sort { lc $a cmp lc $b } keys %repo) {
    $table->add($repo => '  ' . elide($repo{$repo}, $desc_len));
  }

  return "$table";
}

sub user_reply {
  my ($self, $username, $arg) = @_;

  my $basedir = $self->basedir;
  my $gitdir  = "$basedir/$username.git";

  return "unknown repository\n" unless -d $gitdir;

  my $mode = (stat $gitdir)[2];

  return "unknown repository\n" unless $mode & 1;

  my $repo    = Git::PurePerl->new({ gitdir => $gitdir });

  my $cloneurl = file( $gitdir, 'cloneurl' )->slurp( chomp => 1 );
  my $desc     = $repo->description;
  chomp($cloneurl, $desc);

  my @refs = $repo->ref_names;
  my @tags  = grep { s{^refs/tags/}{} } @refs;
  my @heads = grep { s{^refs/heads/}{} } @refs;

  my $reply = "Project  : $username
Desc.    : $desc
Clone URL: $cloneurl
";

  $reply .= "\n[heads]\n";
  for my $head (sort @heads) {
    my $sha = $repo->ref_sha1("refs/heads/$head");
    $reply .= sprintf "%-15s = %s\n", $head, $sha;
  }

  $reply .= "\n[tags]\n";
  for my $tag (sort @tags) {
    my $sha = $repo->ref_sha1("refs/tags/$tag");
    $reply .= sprintf "%-15s = %s\n", $tag, $sha;
  }

  if (my $ref = $repo->ref("refs/heads/master")) {
    my $tree = $ref->tree;
    for ($tree->directory_entries) {
      next unless $_->filename eq 'README';
      my $obj = $_->object;
      $reply .= "\n[README]\n" . $obj->content . "\n";
    }
  }

  return $reply;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Fingerd - let people finger your git server for... some reason

=head1 VERSION

version 2.093523

=head1 DESCRIPTION

This module implements a simple C<finger> server that describes the contents of
a server that hosts git repositories.  You can finger C<@servername> for a
listing of repositories and finger C<repo@servername> for information about
a single repository.

This was meant to provide a simple example for Net::Finger::Server, but enough
people asked for the code that I've released it as something reusable.  Here's
an example program using Git::Fingerd:

  #!/usr/bin/perl
  use Git::Fingerd -run => {
    isa     => 'Net::Server::INET',
    basedir => '/var/lib/git',
  };

This program could then run out of F<xinetd>.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=for Pod::Coverage new basedir

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
