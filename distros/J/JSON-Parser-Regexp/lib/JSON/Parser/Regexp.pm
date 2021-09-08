package JSON::Parser::Regexp;

use utf8;
use Regexp::Grammars;

our $VERSION = '0.19';

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub T::JSON::X {
    my ($self) = @_;
    return $self->{Hash}->X();
}

sub T::Hash::X {
    my ($self) = @_;
    my %hash = $self->{Key_Values}->X();
    return \%hash;
}

sub T::Key_Values::X {
    my ($self) = @_;
    my @kvs = ();
    for my $element ( @{ $self->{Key_Value} } ) {
        push @kvs, $element->X();
    }
    return @kvs;
}

sub T::Key_Value::X {
    my ($self) = @_;
    my $key    = $self->{Key}->X();
    my $sep    = $self->{Sep}->X();
    my $value  = $self->{Value}->X();

    if ( $sep eq ':' ) {
        my @kv = ( $key, $value );
        return @kv;
    }
}

sub T::Key::X {
    my ($self) = @_;
    return $self->{String_Value}->X();
}

sub T::Value::X {
    my ($self) = @_;
    return $self->{Any_Value}->X();
}

sub T::Any_Value::X {
    my ($self) = @_;
    (      $self->{String_Value}
        || $self->{Numeric_Value}
        || $self->{Null_Value}
        || $self->{Hash}
        || $self->{Array}
        || $self->{True}
        || $self->{False} )->X();
}

sub T::String_Value::X {
    my ($self) = @_;
    return $self->{Words}->X();
}

sub T::Words::X {
    my ($self) = @_;
    return $self->{''};
}

sub T::Numeric_Value::X {
    my ($self) = @_;
    return $self->{Number}->X();
}

sub T::Number::X {
    my ($self) = @_;
    return $self->{''};
}

sub T::Null_Value::X {
    my ($self) = @_;
    if ( $self->{''} eq 'null' ) {
        return undef;
    }
}

sub T::True::X {
    my ($self) = @_;
    if ( $self->{''} eq 'true' ) {
        my $TRUE = 1;
        my $class = "JSON::Parser::Regexp::Bool";
        return bless \$TRUE, $class;
    }
}

sub T::False::X {
    my ($self) = @_;
    if ( $self->{''} eq 'false' ) {
        my $FALSE = 0;
        my $class = "JSON::Parser::Regexp::Bool";
        return bless \$FALSE, $class;
    }
}

sub T::Array::X {
    my ($self) = @_;
    return $self->{Array_Elements}->X();
}

sub T::Array_Elements::X {
    my ($self) = @_;
    my @array = ();
    for my $element ( @{ $self->{Array_Element} } ) {
        push @array, $element->X();
    }
    return \@array;
}

sub T::Array_Element::X {
    my ($self) = @_;
    return $self->{Any_Value}->X();
}

sub T::Sep::X {
    my ($self) = @_;
    return $self->{''};
}

sub T::Comma::X {
    my ($self) = @_;
    return $self->{''};
}

my $Parser = qr {
    <nocontext:>

    <JSON>
    <objrule:  T::JSON>                <ws: (\s++)*>  <Hash>

    <objrule:  T::Any_Value>           <String_Value> | <Numeric_Value> | <Null_Value> | <Hash> | <Array> | <True> | <False>

    <objrule:  T::Hash>                \{ <Key_Values> \}

    <objrule:  T::Key_Values>          <[Key_Value]>+ % <Comma>
    <objrule:  T::Key_Value>           <Key> <Sep> <Value>
    <objrule:  T::Key>                 <String_Value>
    <objrule:  T::Value>               <Any_Value>

    <objrule:  T::Array>               \[ <Array_Elements> \]
    <objrule:  T::Array_Elements>      <[Array_Element]>+ % <Comma>
    <objrule:  T::Array_Element>       <Any_Value>

    <objtoken: T::String_Value>        \s*\"\s*<Words>\s*\"\s*
    <objtoken: T::Words>               (.)*?

    <objtoken: T::Numeric_Value>       \s*<Number>\s*
    <objtoken: T::Number>              [-]?[\d\.]*

    <objtoken: T::Null_Value>          null
    <objtoken: T::True>                true
    <objtoken: T::False>               false
    <objtoken: T::Sep>                 \:
    <objtoken: T::Comma>               \,

}xms;

sub decode {
    my ( $self, $String ) = @_;
    if ( $String =~ $Parser ) {
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

	my $json = JSON::Parser::Regexp->new();

  	my $hash = $json->decode('{ "false" : false, "null" : null, "true" : true, "foo" : [3, 4, ౮], "buz": "a string ఈ వారపు వ్యాసం with spaces", "more": {"3" : [8, 9]} , "1" : 41}');
  	print $hash->{"more"}->{3}->[0];

=head1 AUTHOR

Rajkumar Reddy, mesg.raj@outlook.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
