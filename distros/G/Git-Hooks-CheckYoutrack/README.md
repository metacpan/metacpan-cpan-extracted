# Name

Git::Hooks::CheckYoutrack - Git::Hooks plugin which requires youtrack ticket number on each commit message
A perl cpan module - https://metacpan.org/pod/Git::Hooks::CheckYoutrack

# Installation

You can install this module like any other cpan module using cpan or cpanm which automatically installs dependencies.

    cpanm Git::Hooks::CheckYoutrack
    or
    cpan Git::Hooks::CheckYoutrack
    
You can also install from source (clone of this repository)

     perl Makefile.PL
     make test
     make install

# Synopsis

As a `Git::Hooks` plugin you don't use this Perl module directly. Instead, you
may configure it in a Git configuration file like this:

    [githooks]
    
       # Enable the plugin
       plugin = CheckYoutrack

    [githooks "checkyoutrack"]

       # '/youtrack' will be appended to this host
       youtrack-host = "https://example.myjetbrains.com"

       # Refer: https://www.jetbrains.com/help/youtrack/standalone/Manage-Permanent-Token.html
       # to create a Bearer token
       # You can also set YoutrackToken ENV instead of this config
       youtrack-token = "<your-token>"

       # Regular expression to match for Youtrack ticket id
       matchkey = "^((?:P)(?:AY|\\d+)-\\d+)"

       # Setting this flag will aborts the commit if valid Youtrack number not found
       # Shows a warning message otherwise - default false
       required = true 

       # Print the fetched youtrack ticket details like Assignee, State etc..,
       # default false
       print-info = true

# Description

This plugin hooks the following git hooks to guarantee that every commit message 
cites a valid Youtrack Id in the log message, so that you can be certain that 
every commit message has a valid link to the Youtrack ticket. Refer [Git::Hooks Usage](https://metacpan.org/pod/Git::Hooks#USAGE) 
for steps to install and use Git::Hooks

This plugin also hooks prepare-commit-msg to pre-populate youtrack ticket sumary on the 
commit message if the current working branch name is starting with the valid ticket number

# Hooks

## **commit-msg**, **applypatch-msg**

These hooks are invoked during the commit, to check if the commit message
starts with a valid Youtrack ticket Id.

## **update**

This hook is for remote repository and should be installed and configured at the remote git server.
Checks for youtrack ticket on each commit message pushed to the remote repository and deny push
if its not found and its required = true in the config, shows a warning message on client side 
if config required = false but accepts the push.

## **prepare-commit-msg**

This hook is invoked before a commit, to check if the current branch name start with 
a valid youtrack ticket id and pre-populates the commit message with youtrack ticket: summary

# Usage Instruction

Create a generic script that will be invoked by Git for every hook. Go to hooks directory of your repository,
for local repository it is .git/hooks/ and for remote server it is ./hooks/ and create a simple executable perl script

       $ cd /path/to/repo/.git/hooks
    
       $ cat >git-hooks.pl <<'EOT'
       #!/usr/bin/env perl
       use Git::Hooks;
       run_hook($0, @ARGV);
       EOT
    
       $ chmod +x git-hooks.pl

Now you should create symbolic links pointing to this perl script for each hook you are interested in

For local repository

    $ cd /path/to/repo/.git/hooks

    $ ln -s git-hooks.pl commit-msg
    $ ln -s git-hooks.pl applypatch-msg
    $ ln -s git-hooks.pl prepare-commit-msg

For remote repository

    $ cd /path/to/repo/hooks

    $ ln -s git-hooks.pl update
    
# Author

Dinesh Dharmalingam, &lt;dd.dinesh.rajakumar@gmail.com>

# License

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
