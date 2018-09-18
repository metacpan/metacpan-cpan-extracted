package Git::IssueManager;
#ABSTRACT: Module for managing issues in a git branch within your repository
use Moose;
use MooseX::Privacy;
use DateTime;
use DateTime::TimeZone;
use Data::Dumper;
use Git::LowLevel;


has 'gitcmd'  => (is => 'ro', isa => 'Str', default=>"git");

has 'repository' => (is =>'rw', isa => 'Git::LowLevel');

has '_open' => (is => 'rw', isa => 'Git::LowLevel::Tree', traits => [qw/Private/]);

has '_assigned' => (is => 'rw', isa => 'Git::LowLevel::Tree', traits => [qw/Private/]);


has '_inprogress' => (is => 'rw', isa => 'Git::LowLevel::Tree', traits => [qw/Private/]);

has '_closed' => (is => 'rw', isa => 'Git::LowLevel::Tree', traits => [qw/Private/]);

has '_root' => (is => 'rw', isa => 'Git::LowLevel::Tree', traits => [qw/Private/]);

sub ready
{
  my $self = shift;
  my $ref  = $self->repository->getReference('refs/heads/issues');
  return 0 unless $ref->exist;

  my $version = $ref->find('.version');
  return 0 unless defined($version) && ref($version) eq "Git::LowLevel::Blob";

  my $tag = $ref->find('.tag');
  return 0 unless defined($tag) && ref($tag) eq "Git::LowLevel::Blob";

  return 1;
}


sub version
{
  my $self = shift;

  return unless $self->ready();

  my $ref     = $self->repository->getReference('refs/heads/issues');
  my $version = $ref->find(".version");

  return $version->content;
}

sub tag
{
  my $self = shift;

  return unless $self->ready();

  my $ref     = $self->repository->getReference('refs/heads/issues');
  my $tag     = $ref->find(".tag");

  return $tag->content;
}


sub init
{
  my $self      = shift;
  my $issue_tag = shift;

  return unless ! $self->ready();

  die("no issue tag given") unless defined($issue_tag) && length($issue_tag) > 0;

  my $ref     = $self->repository->getReference('refs/heads/issues');
  my $root    = $ref->getTree();

  my $version = $root->newBlob();
  $version->path(".version");
  $version->_content("0.1");
  $root->add($version);

  my $tag = $root->newBlob();
  $tag->path(".tag");
  $tag->_content($issue_tag);
  $root->add($tag);

  $ref->commit("initialized issue manager");

}


sub add
{
  my $self  = shift;
  my $issue = shift;

  die("IssueManager not initialized") unless $self->ready();
  die("no issue given") unless defined($issue) && ref($issue) eq "Git::IssueManager::Issue";

  my $ref = $self->repository->getReference('refs/heads/issues');
  my $root = $ref->getTree();

  my $issueTree=$issue->createIssue($self->repository);

  my $base=$root->find($issue->status);
  if (!defined($base))
  {
    $base = $root->newTree();
    $base->path($issue->status);
    $root->add($base);
  }
  $base->add($issueTree);
  $ref->commit("added issue " . $issue->subject);
}

sub parseIssue
{
  my $self          = shift;
  my $d             = shift;
  my $tag           = shift;
  my $status        = shift;
  my $subject       = $d->find("subject");
  my $description   = $d->find("description");
  my $priority      = $d->find("priority");
  my $severity      = $d->find("severity");
  my $type          = $d->find("type");
  my $worker        = $d->find("worker");
  my $substatus     = $d->find("substatus");
  my $comment       = $d->find("comment");
  my $estimated     = $d->find("estimated");
  my $working       = $d->find("working");
  my $tags          = $d->find("tags");
  my $id            = $tag . "-" . substr($subject->hash(),0,8);
  my $cd            = $d->timestamp_added();
  my $ld            = $d->timestamp_last();
  my $author        = $d->committer();

  # check for required attributes
  die("description not available for issue " . $id) unless defined($description);
  die("priority not available for issue " . $id) unless defined($priority);
  die("severity not available for issue " . $id) unless defined($severity);
  die("type not available for issue " . $id) unless defined($type);


  my $tz=DateTime::TimeZone->new( name => 'local' );
  my $issue       = Git::IssueManager::Issue->new(subject => $subject->content);
  $issue->status($status);
  $issue->description($description->content());
  $issue->priority($priority->content());
  $issue->severity($severity->content());
  $issue->type($type->content());
  $issue->id($id);
  $issue->creation_date(DateTime->from_epoch( epoch =>$cd, time_zone=>$tz));
  $issue->last_change_date(DateTime->from_epoch( epoch =>$ld, time_zone=>$tz));

  if (defined($worker))
  {
    $worker->content()=~/^(.*)\<(.*)\>$/;
    $issue->worker($1);
    $issue->worker_email($2);
  }

  if (defined($author))
  {
    $author=~/^(.*)\<(.*)\>$/;
    $issue->author($1);
    $issue->author_email($2);
  }


  return $issue;
}


sub list
{
  my $self  = shift;
  my @issues;

  die("IssueManager not initialized") unless $self->ready();
  my $ref = $self->repository->getReference('refs/heads/issues');
  my $root = $ref->getTree();
  my $open        = $ref->find("open");
  my $closed      = $ref->find("closed");
  my $assigned    = $ref->find("assigned");
  my $inprogress  = $ref->find("inprogess");
  my $tag         = $ref->find(".tag")->content();
  my @all;

  my @statusse = ("open","closed","assigned","inprogress");
  for my $s (@statusse)
  {
    for my $status ($root->find($s))
    {
      for my $i ($status->get())
      {
        my $issue = $self->parseIssue($i,$tag,$s);
        push(@issues,$issue);
      }
    }
  }

  return @issues;
}

sub delete
{
  my $self  = shift;
  my $id    = shift;
  my @statusse = ("open","closed","assigned","inprogress");

  die("IssueManager not initialized") unless $self->ready();
  my $ref   = $self->repository->getReference('refs/heads/issues');
  my $tag   = $ref->find(".tag")->content();
  my $root  = $ref->getTree();


  for my $s (@statusse)
  {
    for my $status ($root->find($s))
    {
      for my $i ($status->get())
      {
        if (ref($i) eq "Git::LowLevel::Tree")
        {
          my $subject = $i->find("subject");
          my $mytag = $tag . "-" . substr($subject->hash(),0,8);
          if ($id eq  $mytag)
          {
             $status->del($i);
             $ref->commit("removed issue " . $i->mypath);
             return;
           }
        }
      }
    }
  }
  die("issue " . $id . " not found\n");
}


sub changeStatus
{
  my $self  = shift;
  my $id    = shift;
  my $status= shift;

  die("unknown status") unless $status eq "open" || $status eq "closed" || $status eq "inprogress" || $status eq "assigned";

  my @statusse = ("open","assigned","inprogress","closed");

  die("IssueManager not initialized") unless $self->ready();
  my $ref   = $self->repository->getReference('refs/heads/issues');
  my $tag   = $ref->find(".tag")->content();
  my $root  = $ref->getTree();


  for my $s (@statusse)
  {
    next unless $s ne $status;
    for my $stat ($root->find($s))
    {
      for my $i ($stat->get())
      {
        if (ref($i) eq "Git::LowLevel::Tree")
        {
          my $subject = $i->find("subject");
          my $mytag = $tag . "-" . substr($subject->hash(),0,8);
          if ($id eq  $mytag)
          {
             my $base=$root->find($status);
             $stat->del($i);
             my $issue = $self->parseIssue($i, $tag, $s);
             $issue->status($status);
             my $issueTree=$issue->createIssue($self->repository);

             if (!defined($base))
             {
               $base = $root->newTree();
               $base->path($status);
               $root->add($base);
             }
             $base->add($issueTree);
             $ref->commit("closed issue " . $i->mypath);
             return;
           }
        }
      }
    }
  }
  die("issue " . $id . " not found\n");
}

sub assign
{
  my $self         = shift;
  my $id           = shift;
  my $worker_name  = shift;
  my $worker_email = shift;
  my $status       = "assigned";
  my @statusse = ("open","assigned","inprogress","closed");

  die("IssueManager not initialized") unless $self->ready();
  my $ref   = $self->repository->getReference('refs/heads/issues');
  my $tag   = $ref->find(".tag")->content();
  my $root  = $ref->getTree();


  for my $s (@statusse)
  {
    next unless $s ne $status;
    for my $stat ($root->find($s))
    {
      for my $i ($stat->get())
      {
        if (ref($i) eq "Git::LowLevel::Tree")
        {
          my $subject = $i->find("subject");
          my $mytag = $tag . "-" . substr($subject->hash(),0,8);
          if ($id eq  $mytag)
          {
             my $base=$root->find($status);
             $stat->del($i);
             my $issue = $self->parseIssue($i, $tag, $s);
             $issue->status($status);
             $issue->worker($worker_name);
             $issue->worker_email($worker_email);

             my $issueTree=$issue->createIssue($self->repository);

             if (!defined($base))
             {
               $base = $root->newTree();
               $base->path($status);
               $root->add($base);
             }
             $base->add($issueTree);
             $ref->commit("closed issue " . $i->mypath);
             return;
           }
        }
      }
    }
  }
  die("issue " . $id . " not found\n");

}



sub close
{
  my $self  = shift;
  my $id    = shift;

  $self->changeStatus($id, "closed");
}

sub open
{
  my $self  = shift;
  my $id    = shift;

  $self->changeStatus($id, "open");
}

sub start
{
  my $self  = shift;
  my $id    = shift;

  $self->changeStatus($id, "inprogress");
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::IssueManager - Module for managing issues in a git branch within your repository

=head1 VERSION

version 0.1

=head1 DESCRIPTION

Git::IssueManager is a Perl Module for using git as an issue store creating a
B<distributed issue management system>.
It uses the Git::LowLevel Module to store issues in a B<issue> branch using trees
and blobs.

=head2 EXAMPLE

  use Git::IssueManager;

  my $manager     = Git::IssueManager->new(repository=>Git::LowLevel->new(git_dir=> "."));
  if (!$manager->ready)
  {
    print("IssueManager not initialized yet. Please call \"init\" command to do so.");
    exit(-1);
  }

  my @issues=$manager->list();

  for my $i (@issues)
  {
    print $i->subject . "\n";
  }

=head2 MOTIVATION

Issue management is an essential part in modern software engineering. In most cases tools
like I<jira> or I<github> are used for this task. The central nature of these tools is a large
disadvantage if you are often on the road. Furthermore if you are using I<git> for version
control you have everything available for B<distributed issue management>.

B<Advantages:>

=over 12

=item save your issues within your project

=item manage issues on the road, without internet access

=item write your own scripts for issue management

=back

B<Disadvantages:>

=over 12

=item no easy way to let users add issues without pull request yet

=item not all functions implemented yet

=back

=head2 FEATURES

=over 12

=item add issues

=item list issues

=item assign workers to an issue

=item start and close issues

=item delete issues

=back

=head1 ATTRIBUTES

=head2 gitcmd

the path to the git command, default is using your path

=head2 repository

Git::Repository object on which to do the issue management

=head2 _open

B<private attribute>

=head2 _assigned

B<private attribute>

=head2 _inprogress

B<private attribute>

=head2 _closed

B<private attribute>

=head2 _root

B<private attribute>

=head1 METHODS

=head2 ready

validates if everything is in place for issue management

=head2 version

returns the version number of the issue system within the issue branch

=head2 tag

returns the issue tag to prepend in front of all issue ids

=head2 init

initialize the repository for managing issues

=head2 add

  add an issue to the repository

  first paramter is an GitIssueManager::Issue object

=head2 parseIssue

  parsed the given Git::LowLevel::Tree object as an Issue

=head2 delete

  delete an issue from the issue list

=head2 changeStatus

  set status of an issue

=head2 assign

  assign a worker to  an issue

=head2 close

  close an issue

=head2 open

  open an issue

=head2 start

  start an issue

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Git::IssueManager/>.

=head1 BUGS

Please report any bugs or feature requests by email to
L<byterazor@federationhq.de|mailto:byterazor@federationhq.de>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
