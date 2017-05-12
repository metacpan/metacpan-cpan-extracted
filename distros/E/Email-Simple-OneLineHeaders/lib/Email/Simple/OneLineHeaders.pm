package Email::Simple::OneLineHeaders;

use 5.00503;
use strict;
use Carp;
use Email::Simple;
use vars qw($VERSION @ISA);
$VERSION = '1.92';
@ISA = qw(Email::Simple);

=head1 NAME

Email::Simple::OneLineHeaders - same as Email::Simple but without the folding

=head1 SYNOPSIS

    my $mail = Email::Simple::OneLineHeaders->new($text);
    print $mail->as_string;

=head1 DESCRIPTION

The original Email::Simple might output something like this:

Received: from [10.10.10.178] (account jonathan [10.10.10.178] verified)
 by imiinc.com (CommuniGate Pro SMTP 4.3.4)
 with ESMTPA id 130117 for jonathan@imiinc.com; Wed, 27 Jul 2005 23:01:07 -0700

But this module outputs one line headers:

Received: from [10.10.10.178] (account jonathan [10.10.10.178] verified) by imiinc.com (CommuniGate Pro SMTP 4.3.4) with ESMTPA id 130117 for jonathan@imiinc.com; Wed, 27 Jul 2005 23:01:07 -0700


=head1 METHODS

Same as Email::Simple

=cut

sub _header_as_string {
    my ($self, $field, $data) = @_;
    my @stuff = @$data;
    # Ignore "empty" headers
    return '' unless @stuff = grep { defined $_ } @stuff;
    return join "", map { $_ = "$field: $_$self->{mycrlf}";
                           $_ }
                    @stuff;
}

1;

__END__

=head1 CAVEATS

Email::Simple handles only RFC2822 formatted messages.  This means you
cannot expect it to cope well as the only parser between you and the
outside world, say for example when writing a mail filter for
invocation from a .forward file (for this we recommend you use
L<Email::Filter> anyway).  For more information on this issue please
consult RT issue 2478, http://rt.cpan.org/NoAuth/Bug.html?id=2478 .

=head1 AUTHOR

Jonathan Buhacoff <jonathan@pnc.net>

=head1 COPYRIGHT AND LICENSE

This derivative work is
Copyright (C) 2005 Jonathan Buhacoff <jonathan@pnc.net>

Original work is
Copyright 2004 by Casey West
Copyright 2003 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Email::Simple 1.92, by Casey West

Perl Email Project, http://pep.kwiki.org .

=cut
