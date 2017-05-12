# NAME

[![Build Status](https://travis-ci.org/binary-com/perl-Email-Folder-Search.svg?branch=master)](https://travis-ci.org/binary-com/perl-Email-Folder-Search) 
[![codecov](https://codecov.io/gh/binary-com/perl-Email-Folder-Search/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Email-Folder-Search)

Email::Folder::Search

# DESCRIPTION

Search email from mailbox file. This module is mainly to test that the emails are received or not.

# SYNOPSIS

    use Email::Folder::Search;
    my $folder = Email::Folder::Search->new('/var/spool/mbox');
    my %msg = $folder->get_email_by_address_subject(email => 'hello@test.com', subject => qr/this is a subject/);
    $folder->clear();

# Methods

## new($folder, %options)

takes the name of a folder, and a hash of options

options:

- timeout

    The seconds that get\_email\_by\_address\_subject will wait if the email cannot be found.

## search(email => $email, subject => qr/the subject/);

get emails with receiver address and subject(regexp). Return an array of messages which are hashref.

    my $msgs = search(email => 'hello@test.com', subject => qr/this is a subject/);

## clear

clear the content of mailbox

## init

init Email folder for test

# SEE ALSO

[Email::Folder](https://metacpan.org/pod/Email::Folder)
