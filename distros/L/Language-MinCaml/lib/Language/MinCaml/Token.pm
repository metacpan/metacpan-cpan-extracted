package Language::MinCaml::Token;
use strict;
use base qw(Class::Accessor::Fast Exporter);

__PACKAGE__->mk_accessors(qw(kind value line column));

our @EXPORT =
    qw(Token_BOOL Token_FLOAT Token_INT Token_IDENT Token_LPAREN Token_RPAREN
       Token_PLUS Token_PLUS_DOT Token_MINUS Token_MINUS_DOT Token_AST_DOT
       Token_SLASH_DOT Token_EQUAL Token_LESS_GREATER Token_LESS_EQUAL
       Token_LESS_MINUS Token_LESS Token_GREATER_EQUAL Token_GREATER Token_COMMA
       Token_DOT Token_SEMICOLON Token_ARRAY_CREATE Token_NOT Token_IF
       Token_THEN Token_ELSE Token_LET Token_IN Token_REC Token_EOF);

for my $routine_name (@EXPORT){
    my $kind = $routine_name;
    $kind =~ s/^Token_//;
    my $routine = sub { my $value = shift; __PACKAGE__->new($kind, $value); };
    no strict 'refs';
    *{$routine_name} = $routine;
}

sub new {
    my($class, $kind, $value) = @_;
    return bless {kind => $kind, value => $value}, $class;
}

sub to_str {
    my $self = shift;
    return "$self->{kind}\[$self->{value}\]";
}

1;
