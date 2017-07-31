package Email::MIME::RFC2047::Parser;
$Email::MIME::RFC2047::Parser::VERSION = '0.96';
use strict;
use warnings;

# ABSTRACT: Base class for parsers

sub _parse_error {
    my ($class, $string_ref, $what) = @_;

    my $text;
    my $pos = pos($$string_ref);
    $pos = 0 if !defined($pos);

    if ($pos < length($$string_ref)) {
        my $char = substr($$string_ref, $pos, 1);
        $text = defined($what) ?
            "invalid $what at character '$char', pos $pos in string" :
            "unexpected character '$char' at pos $pos in string";
    }
    else {
        $text = defined($what) ?
            "incomplete or missing $what at end of string" :
            "unexpected end of string";
    }

    die("Parse error in MIME header: $text $$string_ref\n");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::RFC2047::Parser - Base class for parsers

=head1 VERSION

version 0.96

=head1 DESCRIPTION

This is a base class for the packages parsing address headers.

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
