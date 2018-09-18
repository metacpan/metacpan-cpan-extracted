# Git::IssueManager

Git::IssueManager is a Perl Module for using git as an issue store creating a
**distributed issue management system**.
It uses the *Git::LowLevel* Module to store issues in a **issue** branch using trees and blobs.

## EXAMPLE
```Perl
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
```

## MOTIVATION

Issue management is an essential part in modern software engineering. In most cases tools
like *jira* or *github* are used for this task. The central nature of these tools is a large
disadvantage if you are often on the road. Furthermore if you are using *git* for version control you have everything available for **distributed issue management**.

### Advantages

*   save your issues within your project
*   manage issues on the road, without internet access
*   write your own scripts for issue management

### Disadvantages

*   no easy way to let users add issues without pull request yet
*   not all functions implemented yet

## FEATURES

*   add issues
*   list issues
*   assign workers to an issue
*   start and close issues
*   delete issues
