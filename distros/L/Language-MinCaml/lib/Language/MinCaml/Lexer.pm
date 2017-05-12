package Language::MinCaml::Lexer;
use strict;
use Carp;
use IO::File;
use Readonly;
use Language::MinCaml::Token;
use Language::MinCaml::Type;
use Language::MinCaml::Util;

Readonly my %keywords
    => (true => \&Token_BOOL, false => \&Token_BOOL, not => \&Token_NOT,
        if => \&Token_IF, then => \&Token_THEN, else => \&Token_ELSE,
        let => \&Token_LET, in => \&Token_IN, rec => \&Token_REC);

sub new {
    my($class, $code) = @_;
    bless { code => $code }, $class;
}

sub next_token {
    my $self = shift;
    my $buffer = $self->{code}->buffer;
    my $token;
    my $value;

    while ($buffer =~ /^\s+/) {
        $self->{code}->forward(length($&));
        $buffer = $self->{code}->buffer;
    }

    if ($buffer =~ /^\d+(\.\d*)?([eE][+\-]?\d+)?/) {
        $value = $&;
        $token = $value =~ /[.eE]/ ? Token_FLOAT($value) : Token_INT($value);
    }
    elsif ($buffer =~ /^\(/) {
        $value = '(';
        $token = Token_LPAREN();
    }
    elsif ($buffer =~ /^\)/) {
        $value = ')';
        $token = Token_RPAREN();
    }
    elsif ($buffer =~ /^\+\.?/) {
        $value = $&;
        $token = $value eq '+.' ? Token_PLUS_DOT() : Token_PLUS();
    }
    elsif ($buffer =~ /^-\.?/) {
        $value = $&;
        $token = $value eq '-.' ? Token_MINUS_DOT() : Token_MINUS();
    }
    elsif ($buffer =~ /^\*\./) {
        $value = '*.';
        $token = Token_AST_DOT();
    }
    elsif ($buffer =~ /^\/\./) {
        $value = '/.';
        $token = Token_SLASH_DOT();
    }
    elsif ($buffer =~ /^=/) {
        $value = '=';
        $token = Token_EQUAL();
    }
    elsif ($buffer =~ /^<[>=\-]?/) {
        $value = $&;
        if ($value eq '<>') {
            $token = Token_LESS_GREATER();
        }
        elsif ($value eq '<=') {
            $token = Token_LESS_EQUAL();
        }
        elsif ($value eq '<-') {
            $token = Token_LESS_MINUS();
        }
        else {
            $token = Token_LESS();
        }
    }
    elsif ($buffer =~ /^>=?/) {
        $value = $&;
        $token = $value eq '>=' ? Token_GREATER_EQUAL() : Token_GREATER();
    }
    elsif ($buffer =~ /^,/) {
        $value = ',';
        $token = Token_COMMA();
    }
    elsif ($buffer =~ /^_/) {
        $value = '_';
        $token = Token_IDENT(create_temp_ident_name(Type_Unit()));
    }
    elsif ($buffer =~ /^\./) {
        $value = '.';
        $token = Token_DOT();
    }
    elsif ($buffer =~ /^;/) {
        $value = ';';
        $token = Token_SEMICOLON();
    }
    elsif ($buffer =~ /^[a-z][0-9a-zA-Z_]*/) {
        $value = $&;
        if (exists $keywords{$value}) {
            $token = &{$keywords{$value}}($value);
        }
        else {
            $token = Token_IDENT($value);
        }
    }
    elsif ($buffer =~ /^Array\.create/) {
        $value = 'Array.create';
        $token = Token_ARRAY_CREATE();
    }
    elsif ($buffer eq q{}) {
        $value = q{};
        $token = Token_EOF();
    }
    else {
        croak "Unknown token at line $self->{code}->{line}, column $self->{code}->{column} in input.";
    }

    $token->line($self->{code}->line);
    $token->column($self->{code}->column);
    $self->{code}->forward(length($value));
    $token;
}

1;
