package JBD::Parser::Token;
# ABSTRACT: expresses a (type, value) pair as an object
our $VERSION = '0.04'; # VERSION

# A token.
# @author Joel Dalley
# @version 2014/Feb/23

use JBD::Core::stern;
use JBD::Core::Exporter ':omni';
use JBD::Core::List 'flatmap';

use overload '""' => sub { 
    my $this = shift;
    my $v = defined $this->value ? $this->value : 'UNDEF';
    join ': ', $this->type, $v;
};

use constant {
    Nothing      => 'Nothing',
    End_of_Input => 'End_of_Input',
};

# @param string Token type.
# @param mixed [opt] Token value.
# @return JBD::Parser::Token
sub token($;$) { __PACKAGE__->new(@_) }

# @param string $class Object type.
# @param string Token type.
# @param mixed Token value, possibly undef.
# @return JBD::Parser::Token
sub new { 
    my $class = shift;
    bless [@_], $class;
}

# @param JBD::Parser::Token
# @return string Token type.
sub type { shift->[0] }

# @param JBD::Parser::Token
# @return array An array with the token's value or values.
sub value { 
    my $val = shift->[1];
    ref $val ? flatmap $val : ($val);
}

# @param JBD::Parser::Token $this
# @param arrayref $types Zero or more token types.
# @param arrayref $vals Zero or more token values.
# @return bool 1 if any type/value pair matches, or untrue.
sub anyof {
    my ($this, $types, $vals) = @_;
    $this->typeis(@$types) && grep $this->eq($_), @$vals;
}

# @param JBD::Parser::Token
# @param mixed A token value.
# @return bool 1 or untrue.
sub eq { !shift->ne(shift) }

# @param JBD::Parser::Token $this
# @param mixed $check A token value.
# @return bool 1 or untrue.
sub ne {
    my ($this, $check) = @_;
    my @check = ref $check ? flatmap @$check : ($check);
    "@{[$this->value]}" ne "@check";
}

# @param JBD::Parser::Token $this
# @param array Zero or more types to check.
# @return bool 1 or undef.
sub typeis { 
    my $t = shift->type;
    for (map ref $_ || $_, @_) { return 1 if $t eq $_ }
    undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Parser::Token - expresses a (type, value) pair as an object

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
