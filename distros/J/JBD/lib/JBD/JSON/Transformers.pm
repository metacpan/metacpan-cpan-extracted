package JBD::JSON::Transformers;
# ABSTRACT: JSON parser token transformers
our $VERSION = '0.04'; # VERSION

# JSON parser token transformers.
# @author Joel Dalley
# @version 2014/Mar/22

use JBD::Core::Exporter ':omni';
use JBD::Parser::DSL;
use JBD::JSON::Lexers;

# @param arrayref Array of JBD::Parser::Tokens.
# @return arrayref Same array, minus Nothing-type tokens.
sub remove_novalue { 
    [grep !$_->typeis(Nothing), @{$_[0]}];
}

# @param arrayref Array of JBD::Parser::Tokens.
# @return arrayref A single JsonString-typed token array.
sub reduce_JsonString {
    my $tokens = remove_novalue shift;
    [token 'JsonString', join '', map $_->value, @$tokens];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::JSON::Transformers - JSON parser token transformers

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
