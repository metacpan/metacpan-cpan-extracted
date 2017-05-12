package JBD::Javascript;
# ABSTRACT: provides Javascript parsing subs
our $VERSION = '0.04'; # VERSION

# Javascript parsing subs.
# @author Joel Dalley
# @version 2014/Apr/13

use JBD::Core::Exporter ':omni';

use JBD::Parser::DSL;
use JBD::Javascript::Lexers;

# @param string $parser A JBD::Parser sub name.
# @param scalar/ref $text Javascript text.
# @return arrayref Array of JBD::Parser::Tokens.
sub std_parse(@) {
    my ($parser, $text) = @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Javascript - provides Javascript parsing subs

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
