package JBD::JSON;
# ABSTRACT: provides JSON parsing subs
our $VERSION = '0.04'; # VERSION

# JSON parsing subs.
# @author Joel Dalley
# @version 2014/Mar/22

use JBD::Core::Exporter ':omni';

use JBD::Parser::DSL;
use JBD::JSON::Lexers;
use JBD::JSON::Grammar;
use JBD::JSON::Transformers 'remove_novalue';

# @param string $parser A JBD::Parser sub name.
# @param scalar/ref $text JSON text.
# @return arrayref Array of JBD::Parser::Tokens.
sub std_parse(@) {
    my ($parser, $text) = @_;

    init json_array  => \&remove_novalue,
         json_object => \&remove_novalue;

    my $st = parser_state tokens $text, [
        JsonNum,        JsonQuote,      JsonComma,
        JsonColon,      JsonCurlyBrace, JsonSquareBracket,
        JsonEscapeSeq,  JsonBool,       JsonNull,
        JsonStringChar, JsonSpace,
    ];

    no strict 'refs';
    remove_novalue &$parser->($st) or die $st->error_string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::JSON - provides JSON parsing subs

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
