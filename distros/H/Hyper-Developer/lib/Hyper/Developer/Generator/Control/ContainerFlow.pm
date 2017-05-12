package Hyper::Developer::Generator::Control::ContainerFlow;

use strict;
use warnings;
use version; our $VERSION = qv('0.01');

use base qw(Hyper::Developer::Generator::Control);
use Class::Std;
use Parse::RecDescent;
use Hyper::Error;

sub _get_data_ref_of_steps {
    my $self     = shift;
    my $step_ref = shift;

    return {
        map {
            my $name = $_;
               $name =~ s{[^\w]}{_}xmsg;
            $name => {
                control => $step_ref->{$_}->get_controls(),
                action  => $self->_create_action_code($step_ref->{$_}->get_action()),
                transitions => [
                    map {
                        my $destination = $_->get_destination();
                           $destination =~ s{[^\w]}{_}xmsg;
                        $destination => $self->_create_condition_code($_->get_condition());
                    } @{$step_ref->{$_}->get_transitions()}
                ],
            };
        } keys %{$step_ref}
    };
}

sub _get_default_parser :PRIVATE {
    return Parse::RecDescent->new(q{
        line      : expr
                  | { die '__ERROR__'; }
        expr      : { die '__REPLACE_ME__'; }
        mixed     : method
                  | ident
                  | { die '__ERROR__' }
        method    : variables '()'
                    { if ( $item[1]->[0] eq 'this') {
                          shift @{$item[1]};
                      }
                      my $method = pop @{$item[1]};
                      '$self'
                      . (
                          @{$item[1]}
                              ? '->get_value_recursive([qw('
                                . ( join q{ }, @{$item[1]} ) . ')])'
                              : q{}
                      ) . "->$method()";
                    }
        constant  : m{[-]?\d[\d_]*(?: \.(?: \d[\d_])*)?}xms
                  | m{'(?: \\\\' | [^'] )* '}xms
                  | m{"(?: \\\\" | [^"] )* "}xms
        variable  : m{[a-z_][a-z0-9_]*}xmsi
        variables : variable(s /\./)
        ident     : constant
                  | variables
                    { if ( $item[1]->[0] eq 'this') {
                         shift @{$item[1]};
                      }
                      '$self'
                      . (
                          @{$item[1]}
                              ? '->get_value_recursive([qw('
                                . ( join q{ }, @{$item[1]} ) . ')])'
                              : q{}
                      );
                    }
    });
}

sub _create_action_code :RESTRICTED {
    my $self   = shift;
    my $param  = shift;

    return q{} if ! defined $param;

    my $parser = $self->_get_default_parser();

    $parser->Extend(q{
        terminator : m{ \s* ;* \s* (\#.*)? \z }xms
                     { return q{} }
    });
    $parser->Replace(q{
        expr : variables '=' mixed terminator
               { chomp $item{mixed};
                 $item{mixed} =~ s{\s*\;$}{};
                 "\$self->set_value_recursive("
                  . '[qw('
                  . ( join q{ }, @{$item{variables}} )
                  . ")], $item{mixed});"
               }
             | method
               { "$item{method};" }
    });

    # return input converted to grammar
    my $result = eval {
        join "\n", map { $parser->line($_) } split m{\n}, $param;
    };

    throw("$@ Error generating action code near\n$param") if $@;

    return $result;
}

sub _create_condition_code :RESTRICTED {
    my $self   = shift;
    my $param  = shift;

    return q{} if ! defined $param;

    my $parser = $self->_get_default_parser();

    $parser->Extend(q{
        logop : 'eq' | 'ne' | '==' | '!=' | '||' | '&&' | 'or' | 'and'
    });

    $parser->Replace(q{
        expr  : mixed logop expr
                { join q{ }, @item[1..3] }
              | mixed
    });

    # return input converted to grammar
    my $result = eval {
        join "\n", map { $parser->line($_); } split m{\n}, $param;
    };

    throw("$@ Error generating condition code near\n $param") if $@;

    return $result;
}

1;
__END__

=pod

=head1 NAME

Hyper::Developer::Generator::Control::ContainerFlow - Abstract Base class with
code generation features

=head1 VERSION

This document describes Hyper::Developer::Generator::Control::ContainerFlow 0.01

=head1 DESCRIPTION

This class can handle two different Grammars.
See pod of Hyper::Control::Flow for more details.

=head2 Action grammar

The abstract action grammar in something like BNF notation looks like this.
Comments are perl style.

 # lines have (optionsl) ; ends
 <line> ::= <line_content> ";"

 # line contains one of
 <line_content> ::= <@identifier> "=" <constant>     #  a.b.c = "Foo";
    | <@identifier>=<@identifier>                    #  a.b.c = a;
    | <method>                                       #  a.b = a.method();

 # id trees may be used with . (like hashref trees in TT or HTC)
 <@identifier> ::= <identifier> ( "." <identifier>)*

 # single ids are alphanumeric
 <identifier> ::= /\b[A-z0-9_]+\b/

 # constants start with ', " or numbers
 constant ::= ['"0-9].*

 # methods are suffixed with ()
 <method> ::= <@identifier> "()"

Examples:

 # <@identifier> = <@identifier>
 cSelectPerson.mRole = mInitiatorRole;
 cSelectPerson = mInitiatorData.mInitiator;

 # <@identifier> = <constant>
 cSelectPerson.mRole = 'Superuser';
 cSelectPerson.mRole = "Superuser";
 cSelectPerson.mRole = 42;

 # method
 this.testMethod();
 testMethod();

=head2 Condition grammar

 # lines consist of one expression or an operand
 <line>     ::= <expr>          # 1 < 2 || 1 > 2
                | <operand>     # test()

 # expressions consist of operand, cmp operator, operand, and optionally
 # a logical operator and another exception
 <expr>     :== <operand> <cmpop> <operand> (<logop> <expr>)?

 # operands are either a constant, a method or an identifier
 <operand>  :==  <constant>
                | <method>
                | <identifier>

 # methods end with ()
 <method>   :== <@identifier> "()"

 # id trees may be used with . (like hashref trees in TT or HTC)
 <@identifier> ::= <identifier> ( "." <identifier>)*

 # single ids are alphanumeric, but must start with a character
 <identifier> ::= /\b[A-z][A-z0-9_]+\b/

 # compare operators are eq, ne, ==, !=
 <cmpop>    :== 'eq' | 'ne' | '==' | '!='

 # Logical operators are || && or and
 <logop>    :==  '||' | '&&' | 'or' | 'and'

Operator precedence is standard perl.

Examples:

 mGroovyMovie.mOscar eq 'true'
 mGroovyMovie.mOscar ne 'grrzwrrz("drrrz")'
 mGroovyMovie.mOscar == 123
 mGroovyMovie.mOscar != 10e30

 mGroovyMovie.mOscar == 1 && mGroovyMovie.mHimbeere == 30

 mGroovyMovie.mOscar == Get_Value() || mHimbeere == mOscar.himbeere.value()
 mGroovyMovie.mOscar == mGroovyMovie.mHimbeere

=head1 SUBROUTINES/METHODS

=head2 ####

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item *

version

=item *

Hyper::Developer::Generator::Control

=item *

Class::Std

=item *

Parse::RecDescent

=item *

Hyper::Error

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 RCS INFORMATIONS

=over

=item Last changed by

$Author: ac0v $

=item Id

$Id: ContainerFlow.pm 333 2008-02-18 22:59:27Z ac0v $

=item Revision

$Revision: 333 $

=item Date

$Date: 2008-02-18 23:59:27 +0100 (Mon, 18 Feb 2008) $

=item HeadURL

$HeadURL: http://svn.hyper-framework.org/Hyper/Hyper-Developer/branches/0.07/lib/Hyper/Developer/Generator/Control/ContainerFlow.pm $

=back

=head1 AUTHOR

Andreas Specht  C<< <ACID@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Andreas Specht C<< <ACID@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
