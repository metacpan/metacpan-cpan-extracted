package Email::Template;

use warnings;
use strict;
use Carp 'croak';
use Encode qw( encode );

=head1 NAME

Email::Template - Send "multipart/alternative" (text & html) email from a Template

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Email::Template;
    Email::Template->send( '/path/to/email/template.tt2',
        {
            From    => 'sender@domain.tld',
            To      => 'recipient@domain.tld',
            Subject => 'Email::Template is easy to use',

            tt_vars => { key => $value, ... },
            convert => { rightmargin => 80, no_rowspacing => 1, ... }
        }
    ) or warn "could not send the email";

=head1 DESCRIPTION

This is a fairly simple interface to generate "multipart/alternative" emails with both
"text/html" and "text/plain" components using a single HTML based Template Toolkit template.

The HTML, once processed by Template Toolkit, is converted to text using
HTML::FormatText::WithLinks::AndTables. Both HTML and text versions are then attached
and sent via MIME::Lite.

Be sure to validate your sender and recipient addresses first (ie. Email::Valid->rfc822 ).

=head1 A NOTE ABOUT CHARACTER SETS

If your template files are non-ASCII, be sure to pass { ENCODING => 'utf-8' } (or whatever)
in the tt_new argument; otherwise, you will get gibberish in the emails.

The text/html and text/plain parts are encoded using utf-8 by default, or pass in 'charset'
to choose a different one (e.g. iso-8859-1).

=head1 EXPORTS

None by default.

=head1 METHODS

=head2 send

The first argument to send() is the path to the Template file. Absolute paths are allowed.
If the path is relative, it works the same as when using Template Toolkit.

The second argument to send() is a hash reference containing the following possible options.

=head3 MIME::Lite

    # REQUIRED

        From    => 'sender@domain.tld',
        To      => 'recipient@domain.tld',
        Subject => 'a subject for your email',

    # OPTIONAL

        # charset to use for the text and html MIME parts (default utf-8)
        charset => 'utf-8',

        # arguments to be passed to MIME::Lite send()
        mime_lite_send => ['smtp', 'some.host', Debug=>1 ],

        # additional attachments to add via MIME::Lite attach()
        mime_lite_attach => [ {Type=>...,Data=>...}, ... ],

        # do not send(), just return the prepared MIME::Lite object
        return_mime_lite => 1,

=head3 Template Toolkit

    # OPTIONAL

        # configuration options passed into Template->new()
        tt_new  => { INCLUDE_PATH => '/path/to/templates', ... },

        # variables to interpolate via Template->process()
        tt_vars => { key => $value, ... },

=head3 HTML::FormatText::WithLinks::AndTables

    # OPTIONAL

        # configuration options passed into convert()
        convert => { rm => 80, no_rowspacing => 1, ... }

NOTE: all additional arguments not explicitely mentioned above will be passed into
MIME::Lite->new()

Assuming "return_mime_lite => 1" was not passed in the arguments list, on success
send() returns the value of MIME::Lite->as_string(), or on failure returns nothing.

=cut

use Template;
use MIME::Lite;
use HTML::FormatText::WithLinks::AndTables;

sub send {
    shift if $_[0] eq __PACKAGE__ or ref $_[0];

    my ($path_to_tt2, $args) = @_;
    if ($path_to_tt2 =~ /^\//) {
        croak "Invalid path to template ($path_to_tt2)\n"
            if not -e $path_to_tt2 and -T _; # make sure template exists
        $args->{tt_new}->{ABSOLUTE} ||= 1;
    }
    croak "Invalid or missing arguments to Email::Template->send()\n"
        if not _required_args($args); # make sure required args are present

    # process the template
    my $tt = Template->new($args->{tt_new});
    $tt->process($path_to_tt2, $args->{tt_vars}, \my $html) or croak $tt->error, "\n";

    # convert html to text
    my $text = HTML::FormatText::WithLinks::AndTables->convert($html, $args->{convert});

    my %mime_lite_args = map { $_ => $args->{$_} }
        grep { ! /^(?:
            tt_vars | tt_args | mime_lite_send |
            mime_lite_attach | return_mime_lite |
            convert
        )\z/x } keys %$args;

    my $charset = $args->{charset} || 'utf-8';

    # send the email
    my $email = MIME::Lite->new( %mime_lite_args, Type => 'multipart/alternative' );
    $email->attach( Type => "text/plain; charset=${charset}", Data => encode( $charset, $text ) );
    $email->attach( Type => "text/html; charset=${charset}", Data => encode( $charset, $html ) );
    if ( $args->{mime_lite_attach} and ref $args->{mime_lite_attach} eq 'ARRAY' ) {
        for (@{ $args->{mime_lite_attach} }) {
            next if not ref $_ eq 'HASH';
            $email->attach(%$_);
        }
    }
    return $email if $args->{return_mime_lite};

    my $raw_email = $email->as_string;
    my @send_args = $args->{mime_lite_send} ? @{ $args->{mime_lite_send} } : ();
    $email->send(@send_args);
    return if not $email->last_send_successful; # requires $MIME::Lite::VERSION >= 3.01_04
    return $raw_email;
}

sub _required_args {
    my $args = shift;
    return if not ref $args eq 'HASH';
    for (qw( To From Subject )) {
        return if not $args->{$_};
    }
    return 1;
}

=head1 SEE ALSO

    Template
    MIME::Lite
    HTML::FormatText::WithLinks::AndTables

=head1 AUTHOR

Shaun Fryer, C<< <pause.cpan.org at sourcery.ca> >>

=head1 CONTRIBUTORS

Ryan D Johnson, C<< <ryan@innerfence.com> >>, charset support

=head1 BUGS

Please report any bugs or feature requests to C<bug-email-template at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Template>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Template


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Template>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Template>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Template>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Template>

=back


=head1 ACKNOWLEDGEMENTS

Everybody. :)
L<http://en.wikipedia.org/wiki/Standing_on_the_shoulders_of_giants>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Shaun Fryer, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Email::Template
