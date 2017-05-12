package JSON::Pointer::Syntax;

use 5.008_001;
use strict;
use warnings;

use Exporter qw(import);
use JSON::Pointer::Context;
use JSON::Pointer::Exception qw(:all);

our $VERSION = '0.07';
our @EXPORT_OK = qw(
    escape_reference_token
    unescape_reference_token
    is_array_numeric_index
);

our $REGEX_ESCAPED         = qr{~[01]};
our $REGEX_UNESCAPED       = qr{[\x{00}-\x{2E}\x{30}-\x{7D}\x{7F}-\x{10FFFF}]};
our $REGEX_REFERENCE_TOKEN = qr{(?:$REGEX_ESCAPED|$REGEX_UNESCAPED)*};
our $REGEX_ARRAY_INDEX     = qr{(?:0|[1-9][0-9]*)};

sub escape_reference_token {
    my $unescaped_reference_token = shift;

    $unescaped_reference_token =~ s/~/~0/g;
    $unescaped_reference_token =~ s/\x2F/~1/g;

    return $unescaped_reference_token;
}

sub unescape_reference_token {
    my $escaped_reference_token = shift;

    $escaped_reference_token =~ s/~1/\x2F/g;
    $escaped_reference_token =~ s/~0/~/g;

    return $escaped_reference_token;
}

sub tokenize {
    my ($class, $pointer) = @_;
    my @tokens;

    my $orig_pointer = $pointer;

    while ($pointer =~ s{/($REGEX_REFERENCE_TOKEN)}{}) {
        my $token = $1;
        push @tokens => unescape_reference_token($token);
    }

    unless ($orig_pointer eq "" || $pointer eq "") {
        JSON::Pointer::Exception->throw(
            code    => ERROR_INVALID_POINTER_SYNTAX,
            context => JSON::Pointer::Context->new(
                pointer => $orig_pointer,
            ),
        );
    }

    return wantarray ? @tokens : [ @tokens ];
}

sub as_pointer {
    my $class = shift;
    my @tokens = (ref $_[0] eq "ARRAY") ? @{$_[0]} : @_;

    return @tokens > 0 ? "/" . join(
        "/", 
        map { escape_reference_token($_) }
        @tokens
    ) : "";
}

sub is_array_numeric_index {
    my $token = shift;
    return $token =~ m/^$REGEX_ARRAY_INDEX$/ ? 1 : 0;
}

1;

__END__

=head1 NAME

JSON::Pointer::Syntax - JSON Pointer syntax functions

=head1 VERSION

This document describes JSON::Pointer::Syntax version 0.07.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is internal only.

=head1 FUNCTIONS

=head2 escape_reference_token($unescaped_reference_token :Str) :Str

=head2 unescape_reference_token($escaped_reference_token :Str) :Str

=head2 tokenize($pointer :Str) : Array/ArrayRef

=head2 as_pointer(\@tokens) :Str

=head2 is_array_numeric_index($token) :Int

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

=over

=item L<perl>

=item L<Class::Accessor::Lite>

=back

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou at cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Toru Yamaguchi. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
