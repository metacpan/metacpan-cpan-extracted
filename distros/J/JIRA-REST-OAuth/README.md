# NAME

JIRA::REST::OAuth - Sub Class JIRA::REST providing OAuth 1.0 support.

[![Build Status](https://travis-ci.org/schobes/JIRA-REST-OAuth.svg?branch=master)](https://travis-ci.org/schobes/JIRA-REST-OAuth)

# VERSION

Version 1.04

# SYNOPSIS

Module is a sub-class of JIRA::REST, to provide OAuth support, no functionality 
differences between the two.

    use JIRA::REST::OAuth;
    my $jira = JIRA::REST::OAuth->new(
        {
            url                => 'https://jira.example.net',
            rsa_private_key    => '/path/to/private/key.pem',
            oauth_token        => '<oauth_token>',
            oauth_token_secret => '<oauth_token_secrete>',
            consumer_key       => '<key>',
        }
    );
    ...

# EXPORT

None

# AUTHOR

Adam R. Schobelock, `<schobes at gmail.com>`

# BUGS



Please report any bugs or feature requests through the web interface at 
[https://github.com/schobes/JIRA-REST-OAuth/issues](https://github.com/schobes/JIRA-REST-OAuth/issues).  I will be notified, and 
then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JIRA::REST::OAuth

You can also look for information at:

- GitHub Repository

    [https://github.com/schobes/JIRA-REST-OAuth](https://github.com/schobes/JIRA-REST-OAuth)

- GitHub Issue Tracker (report bugs here)

    [https://github.com/schobes/JIRA-REST-OAuth/issues](https://github.com/schobes/JIRA-REST-OAuth/issues)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/JIRA-REST-OAuth](http://annocpan.org/dist/JIRA-REST-OAuth)

- CPAN Ratings

    [https://cpanratings.perl.org/d/JIRA-REST-OAuth](https://cpanratings.perl.org/d/JIRA-REST-OAuth)

- Search CPAN

    [https://metacpan.org/release/JIRA-REST-OAuth](https://metacpan.org/release/JIRA-REST-OAuth)

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Adam R. Schobelock.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
