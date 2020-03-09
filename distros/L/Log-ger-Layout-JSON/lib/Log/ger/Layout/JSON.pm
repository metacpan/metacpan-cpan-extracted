package Log::ger::Layout::JSON;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-07'; # DATE
our $DIST = 'Log-ger-Layout-JSON'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Log::ger::Layout::LTSV);

sub _encode {
    my ($pkg, $msg) = @_;

    state $json = do {
        require JSON::MaybeXS;
        JSON::MaybeXS->new->canonical;
    };
    $json->encode($msg);
}

sub get_hooks {
    __PACKAGE__->_get_hooks(@_);
}

1;
# ABSTRACT: Layout log message as a JSON object (hash)

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Layout::JSON - Layout log message as a JSON object (hash)

=head1 VERSION

This document describes version 0.002 of Log::ger::Layout::JSON (from Perl distribution Log-ger-Layout-JSON), released on 2020-03-07.

=head1 SYNOPSIS

 use Log::ger::Layout JSON => (
     add_fields         => {key3 => 'value', key4 => 'value', ...},         # optional
     add_special_fields => {_date => 'Date_GMT', _host => 'Hostname', ...}, # optional
     delete_fields      => ['key1', 'key2', qr/some-regex/, ...],           # optional
 );
 use Log::ger;

 # if you use it together with Log::ger::Format::None:
 log_warn({key1 => 'val1', key2 => 'val2', foo => 'bar', ...);

 # otherwise, using the standard formatter:
 log_warn("blah %s", ['some', 'data']);

The final message will be something like:

 {"foo":"bar", "key3":"value", "key4":"value", "_date":"2017-06-28T14:08:22", "_host":"example.com"}

or:

 {"message":"blah [\"some\",\"data\"]", "_date":"2017-06-28T14:08:22", "_host":"example.com"}

=head1 DESCRIPTION

This layouter allows you to log as JSON. If you use L<Log::ger::Format::None>,
you can pass a hashref. Otherwise, the message will be put in C<message> key.
You can then delete keys then add additional fields/keys (including special
fields, a la L<Log::ger::Layout::Pattern>).

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 add_fields => hash

=head2 add_special_fields => hash

Known special fields:

 Category: Category of the logging event
 Class: Fully qualified package [or class] name of the caller
 Date_Local: Current date in ISO8601 format (YYYY-MM-DD<T>hh:mm:ss) (localtime)
 Date_GMT: Current date in ISO8601 format (YYYY-MM-DD<T>hh:mm:ss) (GMT)
 File: File where the logging event occurred
 Hostname: (if Sys::Hostname is available)
 Location: Fully qualified name of the calling method followed by the
   callers source the file name and line number between parentheses.
 Line: Line number within the file where the log statement was issued
 Message: The message to be logged
 Method: Method or function where the logging request was issued
 Level: Level ("priority") of the logging event
 PID: PID of the current process
 Elapsed_Start: Number of seconds elapsed from program start to logging event
 Elapsed_Last: Number of seconds elapsed from last logging event to current
   logging event
 Stack_Trace: stack trace of functions called

Unknown special fields will cause the layouter to die.

=head2 delete_fields

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Layout-JSON>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Layout-JSON>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Layout-JSON>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Log::ger::Layout::Pattern>

L<Log::ger::Layout::LTSV>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
