package Git::IssueManager::Issue;
#ABSTRACT: class representing an Issue
use Moose;
use File::Basename;



has 'subject' => (is => 'rw', isa => 'Str', required => 1, trigger => sub {
                    my ($self, $new, $old) = @_;

                    die("subject exceeds 50 chars") unless length($new) < 51;

                }
                );

has 'priority' => (is => 'rw', isa => 'Str', default => 'low', trigger => sub {
            my ($self, $new, $old) = @_;

            die("unknown value (" . $new . ")") unless lc($new) eq "urgent" || lc($new) eq "high" ||
                                                       lc($new) eq "medium" || lc($new) eq "low";
});

has 'severity' => (is => 'rw', isa => 'Str', default => 'low',trigger => sub {
            my ($self, $new, $old) = @_;

            die("unknown value (" . $new . ")") unless lc($new) eq "critical" || lc($new) eq "high" ||
                                                       lc($new) eq "medium" || lc($new) eq "low";
});

has 'type' => (is => 'rw', isa => 'Str', default => 'bug', trigger => sub {
            my ($self, $new, $old) = @_;

            die("unknown value (" . $new . ")") unless lc($new) eq "bug" || lc($new) eq "security-bug" ||
                                                       lc($new) eq "improvement" || lc($new) eq "feature" ||
                                                       lc($new) eq "task";
});

has 'status' => (is => 'rw', isa => 'Str', default => 'open', trigger => sub {
            my ($self, $new, $old) = @_;

            die("unknown value (" . $new . ")") unless lc($new) eq "open" || lc($new) eq "assigned" ||
                                                       lc($new) eq "inprogress" || lc($new) eq "closed";
});

has 'substatus'  => (is => 'rw', isa => 'Str', default => 'none', trigger => sub {
            my ($self, $new, $old) = @_;

            die("unknown value (" . $new . ")") unless lc($new) eq "none" || lc($new) eq "fixed" ||
                                                       lc($new) eq "wontfix";
});

has 'comment' => (is => 'rw', isa=>'Str', default => "");


has 'description' => (is => 'rw', isa => 'Str', default => "");

has 'tags' => (is => 'rw', isa => 'ArrayRef[Str]', default => sub {return[];});

has 'attachements' => (is => 'rw', isa=> 'ArrayRef[Str]', default => sub{return [];});


has 'author' => (is=> 'rw', isa => 'Str', default => "");

has 'author_email' => (is => 'rw', isa => 'Str', default => "");

has 'worker' => (is => 'rw', isa => 'Str', default => "");

has 'worker_email' => ( is => 'rw', isa => 'Str', default =>"");

has 'creation_date' => (is => 'rw', isa=>'DateTime',default => sub{return DateTime->now();});

has 'closed_date' => (is => 'rw', isa=>'DateTime',default => sub{return DateTime->now();});

has 'last_change_date' => (is => 'rw', isa=>'DateTime',default => sub{return DateTime->now();});

has 'id' => (is => 'rw', isa => 'Str', default => "");

has 'estimated_time' => (is => 'rw', isa => 'Num', default => 0, trigger => sub {
            my ($self, $new, $old) = @_;

            die("unknown value (" . $new . ")") unless $new >=0 ;
});

has 'working_time' => (is => 'rw', isa=>'Num', default => 0, trigger => sub {
            my ($self, $new, $old) = @_;

            die("unknown value (" . $new . ")") unless $new >= 0;
});


sub addTag
{
  my $self = shift;
  my $tag  = shift;

  die("no tag given") unless defined($tag);
  die("too many tags") unless @{$self->tags}<11;
  die("tag exceeds 20 chars") unless length($tag) < 21;

  push (@{$self->tags}, $tag);
}


sub delTag
{
  my $self  = shift;
  my $tag   = shift;

  die("no tag given") unless defined($tag);

  my $i     = 0;

  for my $t (@{$self->tags})
  {
    if ($t eq $tag)
    {
      last;
    }
    $i++;
  }

  splice(@{$self->tags},$i,1);

}

sub addAttachement
{
  my $self       = shift;
  my $attachment = shift;

  die("no attachment given") unless defined($attachment);
  die("file does not exist") unless -e $attachment;


  push (@{$self->attachements}, $attachment);
}

sub delAttachment
{
  my $self        = shift;
  my $attachment  = shift;

  die("no attachment given") unless defined($attachment);

  my $i     = 0;

  for my $a (@{$self->attachments})
  {
    if ($a eq $attachment)
    {
      last;
    }
    $i++;
  }

  splice(@{$self->attachments},$i,1);
}


sub _createAttachmentTree
{
  my $self        = shift;
  my $repository  = shift;
  my @tree;

  for my $a (@{$self->attachments})
  {
    my $hash = $repository->createFileObjectFromFile($a);
    my $t = {
        ref     => $hash,
        path    => fileparse($a),
        mode    => "100644",
        type    => "blob"
    };
    push(@tree, $t);
  }


  return $repository->createTree(\@tree);
}

sub createIssue
{
  my $self        = shift;
  my $repository  = shift;

  die("No Git::LowLevel object given") unless ref($repository) eq "Git::LowLevel";

  my $ref   = $repository->getReference('refs/heads/issues');
  my $root  = $ref->getTree();

  my $issueTree = $root->newTree();
  my $path = $self->subject;
  $path=~s/\s/_/g;
  $issueTree->path($self->subject);

  my $subject   = $issueTree->newBlob();
  $subject->path("subject");
  $subject->_content($self->subject);
  $issueTree->add($subject);

  my $priority    = $issueTree->newBlob();
  $priority->path("priority");
  $priority->_content($self->priority);
  $issueTree->add($priority);

  my $severity    = $issueTree->newBlob();
  $severity->path("severity");
  $severity->_content($self->severity);
  $issueTree->add($severity);

  my $type        = $issueTree->newBlob();
  $type->path("type");
  $type->_content($self->type);
  $issueTree->add($type);

  if (defined($self->substatus)  && length($self->substatus) > 0)
  {
    my $substatus   = $issueTree->newBlob();
    $substatus->path("substatus");
    $substatus->_content($self->substatus);
    $issueTree->add($substatus);
  }

  if (defined($self->comment) && length($self->comment)> 0)
  {
    my $comment    = $issueTree->newBlob();
    $comment->path("comment");
    $comment->_content($self->comment);
    $issueTree->add($comment);
  }

  if (defined($self->description) && length($self->description)> 0)
  {
    my $description = $issueTree->newBlob();
    $description->path("description");
    $description->_content($self->description);
    $issueTree->add($description);
  }

  if (defined($self->worker) && length($self->worker)> 0)
  {
    my $worker      = $issueTree->newBlob();
    $worker->path("worker");
    $worker->_content($self->worker . "<" . $self->worker_email . ">");
    $issueTree->add($worker);
  }

  my $estimated   = $issueTree->newBlob();
  $estimated->path("estimated");
  $estimated->_content($self->estimated_time);
  $issueTree->add($estimated);

  my $working_time = $issueTree->newBlob();
  $working_time->path("working");
  $working_time->_content($self->working_time);
  $issueTree->add($working_time);

  if (defined($self->tags) && @{$self->tags}> 0)
  {
    my $tags         = $issueTree->newBlob();
    $tags->path("tags");
    $tags->_content(join "\n", @{$self->tags});
    $issueTree->add($tags);
  }


  return $issueTree;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::IssueManager::Issue - class representing an Issue

=head1 VERSION

version 0.1

=head1 DESCRIPTION

B<Git::IssueManager::Issue> represents an issue within the Git::IssueManager module. Issues can be
added, removed, modified and listed.

Make sure that you understand all the attributes before adding issues to your repository.

=head1 ATTRIBUTES

=head2 subject

The subject/ title of the issue

At most 50 chars allowed.

=head2 priority

The priority of the issue. Possible values are:

=over

=item I<urgent> - the most highes level of priority

=item I<high>

=item I<medium>

=item I<low>

=back

The default value is B<low>.

=head2 severity

The severity of the issue. Possible values are:

=over

=item I<critical>

=item I<high>

=item I<medium>

=item I<low>

=back

The default value is B<low>

=head2 type

The type of the issue. Possible values are:

=over

=item I<bug> - a problem within the code, preventing the correct working of the software

=item I<security-bug> - a security related problem within the code, preventing the correct working of the software

=item I<improvement> - an enhancement to an already existing feature

=item I<feature> - a completly new feature

=item I<task> - a simple task, which should be done (please use rarely)

=back

The default values is B<bug>.

=head2 status

The status of the issue. Possible values are:

=over

=item I<open> - nothing has been done yet

=item I<assigned> - the issue has been assigned to a developer

=item I<inprogess> - somebody is working on the issue

=item I<closed> - the issue is closed

=back

The default value is B<open>.

=head2 substatus

A substatus to the actual status. Possible values are:

=over

=item I<none> - there is no substatus

=item I<fixed> - the bug was fixed

=item I<wontfix> - the issue has been closed but it will never be fixed

=back

The default value is B<none>.

=head2 comment

A comment to the current status of the issue.

Only Plain Text is allowed.

Default value is the empty string.

=head2 description

The full description of the issue.

Only Plain Text and Markdown are allowed.

B<no HTML>

The default value is the empty string.

=head2 tags

An arrayref of tags/ keywords for better identifying the issue.

Maximum length of one tag is B<20> characters.

Maximum number of tags is B<10>.

=head2 attachments

An arrayref of files attached to this issue, for example documentation or text files presenting
error messages, screenshots, etc.

=head2 author

The author of the issue, can be the name or an anomynized nickname

=head2 author_email

The authors email for sending status changes of the issue

=head2 worker

The persons name working on solving the issue

=head2 worker_email

The email address of the person working on this issue

=head2 creation_date

A datetime object representing the date/time the issue was created

=head2 closed_date

A datetime object representing the date/time the issue was closed, only valid if status is closed

=head2 last_change_date

A datetime object representing the date/time the issue was last modified

=head2 id

id of the issue

=head2 estimated_time

The estimated time for solving this issue in B<Minutes>

Default value is B<0>, meaning no estimate set.

=head2 working_time

The current time in B<Minutes> already spent on this issue

The default value is B<0>.

=head1 METHODS

=head2 addTag

add another tag to the issue.

B<Example:>

  $issue->addTag("File");

=over

=item B<1. Parameter:> Tag to add to the issue

=back

=head2 delTag

del a tag from the issue

B<Example:>

  $issue->delTag("File");

=over

=item B<1. Parameter> Tag to remove from issue

=back

=head2 addAttachment

Add another attachment to the issue.

B<Example:>

  $issue->addAttachement("/tmp/test.txt");

=over

=item B<1. Parameter> path to the attachment to add

=back

Make sure the attachment exist at the given path and stays there until the issue has been
added.

=head2 delAttachement

Remove an attachment from the issue.

B<Example:>

  $issue->delAttachement("/tmp/test");

=over

=item B<1. Parameter> Attachment path to remove from issue

=back

=head2 _createAttachmentTree - internal method, do not call directly

creates a git repository tree object from the attachment array and return the hash of the object

=over 
=item B<1. Parameter> reference to a Git::RepositoryHL object

=back

=head2 createIssue

Creates the issue inside the given git repository and commits these changes to the issues branch

=over

=item B<1. Parameter> reference to a Git::RepositoryHL object

=back

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
