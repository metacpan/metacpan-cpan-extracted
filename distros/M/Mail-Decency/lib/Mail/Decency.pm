package Mail::Decency;


use strict;
use warnings;

use version 0.74; our $VERSION = qv( "v0.1.6" );


=head1 NAME

Mail::Decency - Anti-Spam fighting framework


=head1 DESCRIPTION

Mail::Decency is an interface between postfix (MTA), a bunch of policies (eg DNSBL, SPF, ..), multiple content filters (eg DSPAM, Bogofilter, ClamAV, DKIM validation, ...) and a log parser.

It is based on POE and Moose and runs as a daemon with multiple forked instances.

=head1 SYNOPSIS

Setting up a new policy server

    use Mail::Decency::Policy;
    my $policy = Mail::Decency::Policy->new( {
        config => '/etc/decency/policy.yml'
    } );
    $policy->run;

Setting up a new content filter

    use Mail::Decency::ContentFilter;
    my $content_filter = Mail::Decency::ContentFilter->new( {
        config => '/etc/decency/content-filter.yml'
    } );
    $content_filter->run;

Setting up a new syslog parser

    use Mail::Decency::LogParser;
    my $syslog_parser = Mail::Decency::LogParser->new( {
        config => '/etc/decency/log-parser.yml'
    } );
    $syslog_parser->run;



=head1 INTRODUCTION

For now, decency is in alpha-testing state. Don't use it in production. Also: API changes could occure.

=head2 WHY ANOTHER POLICY SERVER OR CONTENT FILTER ?

Well, that is the first reason why: there is no single (open source) application that combines both that i know of. The spam threat has not been decreased over the time, quite the contrary: it has hugely increased. I think it is of the outermost importance to bring those two points of defense as close together as possible.

The second reason: CPAN. The existing (perl implemented) solutions lack imho the modular design for being as extendable as they could be and are not released on CPAN.

The third reason is distributability (is this an English word?). In high traffic environments a distributed (mail server) structure is not uncommon. The content filter and policy server solution should be designed for this scenario.

The fourth and last reason is more personal. Complex and voluminous configuration lead often to human mistakes (or at least on my part). decency tries to have a simplified and maintainable configuration. Then again, maybe the configuration seams much easier to me, because i wrote it..

=head3 IS IT "POSTFIX ONLY" ?

No, or at least it does not has to be. For now, mainly postfix is supported, but most other MTAs should be able to implement the content filter. Exim should be able to use the policy server (with a L<<a href="http://www.bebt.de/blog/debian/archives/2006/07/30/T06_12_27/index.html">work around</a>>). For the log parser, there is only a postfix parser modules available, but others can be implemented. Because i work mainly (you could say only) with postfix, i cannot implement other "bindings" then for postfix. But i try to keep it as modular as possible, not to slow down any effort to do this.

=head3 WHAT ABOUT QPSMTPD ?

Yes, there is qpsmtpd, which does implement the above mentioned techniques (content filtering, policy server) and is also open source. However the approach is entirely different: it is a replacement for your smtp(d) server. It  does implements it's policy and content filters capabilities and then delivers the mails to your MTA (postfix, exim, qmail, ..). This is of course more flexible regarding the mail servers which support it, but also reduces the "backend MTA" to a delivery server. decency's approach is the "other way around": it relies on your MTA as the "main SMTP server" and integrates itself below.

To put it exaggeratedly: with qpsmtpd you could substitute the backend MTA. With decency, you could substitute your anti-spam measurements. Therefore i would not argue that both address the same issue.

Which approach is better or worse is not the question (imho), it is more: which can you integrate in your environment.

=head2 HOW DOES IT WORK ?

There are three components involved in the process:

=over

=item 1. Policy server

Sits at the very frontier and fights spam before it is received with various measurements.

=item 2. Content filter

Middleware for applying all kinds of content filtering, such as spam filters and virus filter from third party. Also implements some own filters (DKIM, Archive, ..) without external software.

=item 3. Log parser

Mail server log analyses is most important for running a healthy system, this tries to simply this effort.

=back


=head2 THE STRUCTURE

    ------------           --------------           ------------------
    | INTERNET | -[SMTP]-> | MAILSERVER | -[SMTP]-> | CONTENT FILTER |
    ------------           --------------           ------------------
                               |   ^                       |
                               v   |                   [REINJECT]
                             ----------                    v
                             | POLICY |               --------------
                             ----------               | MAILSERVER |
                                                      --------------

=over

=item * A mail is to be received from the internet, the mail server does not yet accept it.

=item * The mail server applies his own policies and then asks the policy server whether the mail shall pass.

=item * The mail server rejects the mail finally or accepts and receive it and delivers it to the content filter.

=item * The content filter might reject the mail, which will force the mail server to bounce it, or passes it again and re-inject it into another mail server process.

=item * The mail server delivers the mail (eg mailbox)

=back

=head2 SHOULD I USE IT IN PRODUCTION

No. Not yet. Far more

=head1 SEE ALSO

=over

=item * L<Mail::Decency::Policy>

=item * L<Mail::Decency::ContentFilter>

=item * L<Mail::Decency::LogParser>

=item * http://blog.foaa.de/decency

=back



=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
