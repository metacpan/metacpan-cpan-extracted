package JSON::Parser::Regexp;

use Mouse;
use utf8;
use Kavorka;
use Regexp::Grammars;

our $VERSION = '0.03';


method AST::JSON::X() {
    return $self->{Hash}->X();
}

method AST::Hash::X() {
    my %hash = $self->{Key_Values}->X();
    return \%hash;
}

method AST::Key_Values::X() {
    my @kvs = ();
    for my $element ( @{ $self->{Key_Value} } ) {
        push @kvs, $element->X();
    }
    return @kvs;
}

method AST::Key_Value::X() {
    my $key   = $self->{Key}->X();
    my $sep   = $self->{Sep}->X();
    my $value = $self->{Value}->X();

    if( $sep eq ':' ) {
        my @kv = ($key, $value);
        return @kv;
    }
}

method AST::Key::X() {
    return $self->{Any_Value}->X();
}

method AST::Value::X() {
    return $self->{Any_Value}->X();
}

method AST::Any_Value::X() {
    ($self->{String_Value} || $self->{Numeric_Value} || $self->{Null_Value} || $self->{Hash} || $self->{Array})->X();
}

method AST::String_Value::X() {
    return $self->{Words}->X();
}

method AST::Words::X() {
    return $self->{''};
}

method AST::Numeric_Value::X() {
    return $self->{Number}->X();
}

method AST::Number::X() {
    return $self->{''};
}

method AST::Null_Value::X() {
    return $self->{''};
}

method AST::Array::X() {
    return $self->{Array_Elements}->X();
}

method AST::Array_Elements::X() {
    my @array = ();
    for my $element ( @{ $self->{Array_Element} } ) {
        push @array, $element->X();
    }
    return \@array;
}

method AST::Array_Element::X() {
    return $self->{Any_Value}->X();
}

method AST::Sep::X() {
    return $self->{''};
}

method AST::Comma::X() {
    return $self->{''};
}


my $Parser = qr {
    <nocontext:>

    <JSON>
    <objrule:  AST::JSON>                <ws: (\s++)*>  <Hash>

    <objrule:  AST::Any_Value>           <String_Value> | <Numeric_Value> | <Null_Value> | <Hash> | <Array>

    <objrule:  AST::Hash>                \{ <Key_Values> \}

    <objrule:  AST::Key_Values>          <[Key_Value]>+ % <Comma>
    <objrule:  AST::Key_Value>           <Key> <Sep> <Value>
    <objrule:  AST::Key>                 <Any_Value>
    <objrule:  AST::Value>               <Any_Value>

    <objrule:  AST::Array>               \[ <Array_Elements> \]
    <objrule:  AST::Array_Elements>      <[Array_Element]>+ % <Comma>
    <objrule:  AST::Array_Element>       <Any_Value>

    <objtoken: AST::String_Value>        \s*\"\s*<Words>\s*\"\s*
    <objtoken: AST::Words>               (.)*?

    <objtoken: AST::Numeric_Value>       \s*<Number>\s*
    <objtoken: AST::Number>              [-]?[\d\.]*

    <objtoken: Null_Value>               null
    <objtoken: AST::Sep>                 \:
    <objtoken: AST::Comma>               \,
}xms;


method Json_Parse( $String ) {
    if( $String =~ $Parser ) {
        $/{JSON}->X();
    }
}



1;
__END__
=encoding utf-8

=head1 NAME

JSON::Parser::Regexp - Json parser

=head1 SYNOPSIS

	use utf8;
  	use JSON::Parser::Regexp;

	my $json = Json::Parser::Regexp->new();

  	my $hash = $json->Json_Parse('{"foo" : [-1.2, -2, 3, 4, ౮], "buz": "a string ఈ వారపు వ్యాసం with spaces", "more": {3 : [8, 9]} , 1 : 41, "array": [1, 23]}');
  	print $hash->{"more"}->{3}->[0];

=head1 AUTHOR

Rajkumar Reddy, mesg.raj@outlook.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
