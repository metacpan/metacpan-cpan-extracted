package JBD::Parser::State;
# ABSTRACT: embodies the state of an in-progress parse
our $VERSION = '0.04'; # VERSION

# Encloses an array of lexed JBD::Parser::Tokens, embodies
# the state of a parse in progress, & provides related subs.
# @author Joel Dalley
# @version 2014/Mar/11

use JBD::Core::stern;
use JBD::Core::Exporter ':omni';
use JBD::Parser::Token 'token';

BEGIN {
    no strict 'refs';
    my %h = (lexed_tokens => 0, 
             lexed_count  => 1,
             parsed_count => 2, 
             parse_frame  => 3);
    while (my ($s, $i) = each %h) {
        *$s = sub :lvalue {$_[0]->[$i]};
    }
}

# @param arrayref Array of JBD::Parser::Tokens.
# @return JBD::Parser::State
sub parser_state($) { __PACKAGE__->new(shift) }

# @param string $type Object type.
# @param arrayref $lexed_tokens Array of JBD::Parser::Tokens.
# @return JBD::Parser::State
sub new {
    my ($type, $lexed_tokens) = @_;
    my $this = bless [$lexed_tokens, 0, 0, {}], $type;
    $this->lexed_count = @{$this->lexed_tokens};
    $this;
}

# @param JBD::Parser::State $this
# @return JBD::Parser::Token The token at the cursor position.
sub current_lexed_token {
    my $this = shift;
    $this->lexed_tokens->[$this->parse_frame->{cursor}];
}

# @param JBD::Parser::State $this
# @param string $type A JBD::Parser::Token type.
# @param mixed [opt] $value Optional token value.
# @return hashref New parse frame.
sub begin_parse_frame {
    my ($this, $type, $value) = @_;
    my $token = token $type, $value;
    $this->parse_frame = {
        cursor => $this->parsed_count,
        token  => $token, error  => ''
        };
}

# @param JBD::Parser::State $this
# @return The number of lexed tokens that are now parsed.
sub parse_frame_success {
    my $this = shift;
    $this->parsed_count = ++$this->parse_frame->{cursor};
}

# @param JBD::Parser::State $this
# @param string $msg An error message.
# @return string The given message, $msg.
sub parse_frame_error {
    my ($this, $msg) = @_;
    $this->parse_frame->{error} = $msg;
}

# @param JBD::Parser::State $this
# @return string A basic description of the parse error.
sub error_string {
    my $this = shift;
    my $err  = $this->parse_frame->{error};
    my $tok  = $this->parse_frame->{token};
    my $curr = $this->current_lexed_token 
            || token 'INPUT MISSING';
    my $cnt  = $this->parsed_count;
    return qq|Parsed $cnt tokens before error. |
         . qq|Could not parse token "$curr" |
         . qq|when expecting "$tok".\n$err\n\n|;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Parser::State - embodies the state of an in-progress parse

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
