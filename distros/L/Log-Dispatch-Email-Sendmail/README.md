# NAME

Log::Dispatch::Email::Sendmail - Subclass of Log::Dispatch::Email that sends e-mail using Sendmail

# VERSION

Version 0.03

# SYNOPSIS

[Log::Dispatch::Email::MailSendmail](https://metacpan.org/pod/Log%3A%3ADispatch%3A%3AEmail%3A%3AMailSendmail) is no longer suitable for all
situations because it doesn't use Sendmail to send mail (despite the
name of the module) instead it uses SMTP and doesn't support AUTH.

This module sends mail using Sendmail. It has the overhead of a
fork/exec so it should only be used where really needed.

    use Log::Dispatch;

    my $log = Log::Dispatch->new(
      outputs => [
          [
              'Email::Sendmail',
              min_level => 'emerg',
              to        => [qw( foo@example.com bar@example.org )],
              subject   => 'Big error!'
          ]
      ],
    );

    $log->emerg("Something bad is happening");

# SUBROUTINES/METHODS

## send\_email

Send a message

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

No known bugs.

# SEE ALSO

[Log::Dispatch::Email::MailSendmail](https://metacpan.org/pod/Log%3A%3ADispatch%3A%3AEmail%3A%3AMailSendmail)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Dispatch::Email::Sendmail

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log::Dispatch::Log::Sendmail](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log::Dispatch::Log::Sendmail)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Log-Dispatch-Log-Sendmail](http://annocpan.org/dist/Log-Dispatch-Log-Sendmail)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Log-Dispatch-Log-Sendmail](http://cpanratings.perl.org/d/Log-Dispatch-Log-Sendmail)

- Search CPAN

    [http://search.cpan.org/dist/Log-Dispatch-Log-Sendmail/](http://search.cpan.org/dist/Log-Dispatch-Log-Sendmail/)

# ACKNOWLEDGEMENTS

Kudos to Dave Rolksy for the entire Log::Dispatch framework.

# LICENSE AND COPYRIGHT

Copyright 2013-2022 Nigel Horne.

This program is released under the following licence: GPL
