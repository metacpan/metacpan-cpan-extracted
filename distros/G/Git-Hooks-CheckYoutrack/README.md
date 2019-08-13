# NAME

Git::Hooks::CheckYoutrack - Git::Hooks plugin which requires youtrack ticket number on each commit message

# SYNOPSIS

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
       youtrack-token = "<your-token>"

       # Regular expression to match for Youtrack ticket id
       matchkey = '^((?:P|M)(?:AY|\d+)-\d+)'

       # Setting this flag will aborts the commit if valid Youtrack number not found
       # Shows a warning message otherwise - default false
       required = true 

       # Print the fetched youtrack ticket details like Assignee, State etc..,
       # default false
       print-info = true

# DESCRIPTION

This plugin hooks the following git hooks to guarantee that every commit message 
cites a valid Youtrack Id in the log message, so that you can be certain that 
every commit message has a valid link to the Youtrack ticket. Refer [Git::Hooks Usage](https://metacpan.org/pod/Git::Hooks#USAGE) 
for steps to install and use Git::Hooks

This plugin also hooks prepare-commit-msg to pre-populate youtrack ticket sumary on the 
commit message if the current working branch name is starting with the valid ticket number

# METHODS

## **commit-msg**, **applypatch-msg**

These hooks are invoked during the commit, to check if the commit message
starts with a valid Youtrack ticket Id.

## **prepare-commit-msg**

This hook is invoked before a commit, to check if the current branch name start with 
a valid youtrack ticket id and pre-populates the commit message with youtrack ticket: summary

# SEE ALSO

Git::Hooks

Git::Hooks::CheckJira

# AUTHORS

Dinesh Dharmalingam, &lt;dinesh@exceleron.com>

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
