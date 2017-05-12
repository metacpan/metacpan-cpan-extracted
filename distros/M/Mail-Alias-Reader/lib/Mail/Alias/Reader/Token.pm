# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Mail::Alias::Reader::Token;

use strict;
use warnings;

use Carp;

=head1 NAME

Mail::Alias::Reader::Token

=head1 DESCRIPTION

Mail::Alias::Reader::Token is not only the class represents an aliases(5) parser
token, but also itself is returned by L<Mail::Alias::Reader> as a representation
of a mail alias destination.  For the purposes of this documentation, only the
public-facing methods which facilitate the usage of instances of this class
shall be discussed.

=cut

my @TOKEN_TYPES = (
    [ 'T_COMMENT'    => qr/#\s*(.*)$/ ],
    [ 'T_STRING'     => qr/("(?:\\.|[^"\\]+)*")/ ],
    [ 'T_COMMA'      => qr/,/ ],
    [ 'T_DIRECTIVE'  => qr/:([^\:\s]+):([^\:\s,]*)/ ],
    [ 'T_COMMAND'    => qr/\|(\S+)/ ],
    [ 'T_ADDRESS'    => qr/([a-z0-9_\-@\.*]+)/i ],
    [ 'T_COLON'      => qr/\:/ ],
    [ 'T_FILE'       => qr/(\S+)/ ],
    [ 'T_WHITESPACE' => qr/\s+/ ],
);

my @TOKEN_STRING_TYPES = (
    [ 'T_DIRECTIVE' => qr/:([^\:\s]+):\s*(.*)/s ],
    [ 'T_COMMAND'   => qr/\|(.*)/s ],
    [ 'T_ADDRESS'   => qr/([^\/]+)/s ],
    [ 'T_FILE'      => qr/(.*)/s ]
);

#
# Mail::Alias::Reader::Token->new($type)
#
# Create a new mail alias parser token of the given type.  This method isn't
# actually meant to be called publically; rather, it is simply a shortcut to
# create symbolic parser tokens that contain no data, but refer to a piece of
# punctuation, or similar.
#
sub new {
    my ( $class, $type ) = @_;

    return bless { 'type' => $type }, $class;
}

#
# $token->isa(@types)
#
# Return true if the current token is of any of the types passed as an
# argument.
#
sub isa {
    my ( $self, @types ) = @_;

    foreach my $type (@types) {
        return 1 if $self->{'type'} eq $type;
    }

    return 0;
}

#
# $token->is_punct()
#
# Returns true if the current token represents a piece of punctuation, or
# something that separates values, clauses, or declarations from one another.
#
sub is_punct {
    return shift->isa(qw/T_BEGIN T_END T_COLON T_COMMA/);
}

#
# $token->is_value()
#
# Returns true if the current token represents a meaningful value recorded in
# text, such as a mail transfer agent directive, a command to pass message to,
# a local or remote mailing address, or a file to append messages to.
#
sub is_value {
    return shift->isa(qw/T_DIRECTIVE T_COMMAND T_ADDRESS T_FILE/);
}

=head1 DETERMINING MAIL DESTINATION TYPE

A variety of methods are provided to allow one to infer the type of a mail
alias (parser token) returned.

=over

=item $destination->is_address()

Returns true if the mail destination described by the current token is a local
part or fully qualified mail address.

=cut

sub is_address {
    return shift->isa('T_ADDRESS');
}

=item $destination->is_directive()

Returns true if the mail destination described by the current token is a
mail transfer agent directive.

=cut

sub is_directive {
    return shift->isa('T_DIRECTIVE');
}

=item $destination->is_command()

Returns true if the mail destination described by the current token is a
command to which mail messages should be piped.

=cut

sub is_command {
    return shift->isa('T_COMMAND');
}

=item $destination->is_file()

Returns true if the mail destination described by the current token is a file
to which mail messages should be appended.

=back

=cut

sub is_file {
    return shift->isa('T_FILE');
}

=head1 CONVERTING THE MAIL DESTINATION TO A STRING

=over

=item $destination->value()

Returns a parsed and unescaped logical representation of the mail alias
destination that was originally parsed to yield the current token object.

=cut

sub value {
    return shift->{'value'};
}

=item $destination->to_string()

Returns a string representation of the mail alias destination that was
originally parsed to yield the current token object.

=back

=cut

sub to_string {
    my ($self) = @_;

    my %SUBSTITUTIONS = (
        "\r" => '\r',
        "\n" => '\n',
        "\t" => '\t',
        '"'  => '\"'
    );

    my $value = $self->{'value'};

    if ($value) {
        foreach my $search ( keys %SUBSTITUTIONS ) {
            $value =~ s/$search/$SUBSTITUTIONS{$search}/g;
        }
    }

    #
    # Since not every token type has a "value", per se, lazy evaluation is
    # necessary to prevent a Perl runtime warning when evaluating the 'T_COMMENT'
    # part of this hash when dealing with tokens that are anything other than a
    # comment.
    #
    my %FORMATTERS = (
        'T_COMMENT'    => sub { "# $value" },
        'T_COMMA'      => sub { ',' },
        'T_COLON'      => sub { ':' },
        'T_WHITESPACE' => sub { ' ' }
    );

    return $FORMATTERS{ $self->{'type'} }->() if exists $FORMATTERS{ $self->{'type'} };

    my $ret;

    if ( $self->is_directive ) {
        $ret = ":$self->{'name'}:$value";
    }
    elsif ( $self->is_command ) {
        $ret = "|$value";
    }
    else {
        $ret = $value;
    }

    #
    # If the data to be returned contains spaces, then wrap it with double quotes
    # before returning it to the user.
    #
    $ret =~ s/^(.*)$/"$1"/ if $ret =~ /\s/;

    return $ret;
}

#
# Mail::Alias::Reader::Token->tokenize_for_types($buf, @types)
#
# Transform the given text buffer, $buf, into a series of tokens, based on the
# rules passed in @types (defined near the top of this file).  Returns an ARRAY
# of tokens that were matched based on the rules in @types versus the input
# buffer.
#
# As the token types are associated with their parsing rules, and are given in
# an ordered manner, proper precedence can be followed and ambiguity in lexing
# can be overcome.
#
# This method does not provide the main tokenizing interface; rather, it only
# facilitates for the easy access of a single pass of tokenizing, and is called
# by the Mail::Alias::Reader::Token->tokenize() method.
#
sub tokenize_for_types {
    my ( $class, $buf, @types ) = @_;
    my @tokens;

  match: while ($buf) {
        foreach my $type (@types) {
            next unless $buf =~ s/^$type->[1]//;

            my $token = bless {
                'type' => $type->[0],
            }, $class;

            if ( $type->[0] eq 'T_DIRECTIVE' ) {
                @{$token}{qw(name value)} = ( $1, $2 );
            }
            else {
                $token->{'value'} = $1;
            }

            push @tokens, $token;

            next match;
        }
    }

    return \@tokens;
}

#
# Mail::Alias::Reader::Token->tokenize($buf)
#
# Returns an ARRAY of tokens parsed from the given text buffer.
#
# This method tokenizes in two stages; first, it performs a high-level sweep of
# any statements not inside double quotes, though while grabbing double-quoted
# statements and holding onto them for a later second pass.  During this second
# tokenization pass, performed for each double-quoted statement found and in the
# order of first-stage tokenization, statements containing spaces are parsed.
#
# Since this method is intended to be used on a single line of input, a T_BEGIN
# and T_END token comes as the first and the last token returned, respectively.
#
sub tokenize {
    my ( $class, $buf ) = @_;

    #
    # When parsing token data contained within double quotes, the following
    # escape sequence patterns and substitutions are iterated over for each
    # double quoted expression, performing unescaping where necessary.
    #
    my %WHITESPACE = (
        'r' => "\r",
        'n' => "\n",
        't' => "\t"
    );

    my @STRING_ESCAPE_SEQUENCES = (
        [ qr/\\(0\d*)/       => sub { pack 'W', oct($1) } ],
        [ qr/\\(x[0-9a-f]+)/ => sub { pack 'W', hex("0$1") } ],
        [ qr/\\([rnt])/      => sub { $WHITESPACE{$1} } ],
        [ qr/\\([^rnt])/     => sub { $1 } ]
    );

    #
    # Perform first stage tokenization on the input.
    #
    my $tokens = $class->tokenize_for_types( $buf, @TOKEN_TYPES );

    foreach my $token ( @{$tokens} ) {

        #
        # Perform second stage tokenization on any T_STRING tokens found.  As the aliases(5)
        # format lacks a string literal type, a second pass is required to parse the quote
        # delimited string out for a more specific type.
        #
        if ( $token->isa('T_STRING') ) {
            $token->{'value'} =~ s/^"(.*)"$/$1/s;

            #
            # Parse for any escape sequences that may be present.
            #
            foreach my $sequence (@STRING_ESCAPE_SEQUENCES) {
                my ( $pattern, $subst ) = @{$sequence};

                $token->{'value'} =~ s/$pattern/$subst->()/seg;
            }

            #
            # Create a new token from the second pass parsing step for the string
            # contents, copying the data directly into the existing token (so as to
            # not lose the previous reference).
            #
            %{$token} = %{ $class->tokenize_for_types( $token->{'value'}, @TOKEN_STRING_TYPES )->[0] };
        }
    }

    return [
        $class->new('T_BEGIN'),
        @{$tokens},
        $class->new('T_END')
    ];
}

1;

__END__

=head1 AUTHOR

Erin Schoenhals E<lt>erin@cpanel.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2012, cPanel, Inc.
All rights reserved.
http://cpanel.net/

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.  See the LICENSE file for further details.
