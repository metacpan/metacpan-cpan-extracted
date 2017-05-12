package Karel::Parser;

=head1 NAME

Karel::Parser

=head1 METHODS

=over 4

=cut

use warnings;
use strict;

use Moo;
use Marpa::R2;
use namespace::clean;

{   package # Hide from CPAN.
        Karel::Parser::Actions;

    use parent 'Exporter';
    our @EXPORT_OK = qw{ def concat left forward pick drop stop repeat
                         While If first_ch negate call list defs run };

    sub def      { [ $_[1], $_[2] ] }
    sub concat   { $_[1] . $_[2] }
    sub left     { [ l => $_[1] ] }
    sub forward  { [ f => $_[1] ] }
    sub pick     { [ p => $_[1] ] }
    sub drop     { [ d => $_[1] ] }
    sub stop     { [ q => $_[1] ] }
    sub repeat   { complex_command( r => @_ ) }
    sub While    { complex_command( w => @_ ) }
    sub If       { [ i => @{ $_[1] }[ 0, 1 ],
                     ref $_[1][2] ? $_[1][2] : [['x']], # else
                     [ @{ $_[1] }[ -2, -1 ] ] ] }
    sub first_ch { substr $_[1], 0, 1 }
    sub negate   { '!' . $_[1] }
    sub call     { $_[0]{ $_[1][0] } = 1;
                   [ 'c', $_[1][0], [ @{ $_[1] }[ 1, 2 ] ] ] }
    sub list     { [ grep defined, @_[ 1 .. $#_ ] ] }

    sub defs {
        my $unknown = shift;
        my %h;
        for my $command (@_) {
            $h{ $command->[0][0] } = [ $command->[0][1], @{ $command }[ 1, 2 ] ];
        }
        return [ \%h, $unknown ]
    }

    sub run {
        shift;
        $_[0][-1][0] -= length 'run ';
        [ @_ ]
    }

    sub complex_command {
        my $cmd = shift;
        [ $cmd => @{ $_[1] }[ 0, 1 ],  [ @{ $_[1] }[ 2, 3 ] ] ]
    }

}

my %terminals = (
    octothorpe => '#',
    drop_mark  => 'drop-mark',
    pick_mark  => 'pick-mark',
);

$terminals{$_} = $_
    for qw( command left forward stop repeat while if else end done
            wall mark there a facing not North East South West x times
            s is isn t no );


my $dsl = << '__DSL__';

:default ::= action => ::undef
lexeme default = latm => 1

START      ::= Defs                       action => ::first
             | (Run SC) Command           action => run
Run        ::= 'run'                      action => [ values, start, length ]

Defs       ::= Def+  separator => SC      action => defs
Def        ::= Def2                       action => [ values, start, length ]
Def2       ::= (SCMaybe) (command) (SC) CommandDef (SC) Prog (SC) (end)
                                          action => def
NewCommand ::= CommandDef                 action => [ values, start, length ]
CommandDef ::= alpha valid_name           action => concat
Prog       ::= Commands                   action => ::first
Commands   ::= Command+  separator => SC  action => list
Command    ::= Left                       action => left
             | Forward                    action => forward
             | Drop_mark                  action => drop
             | Pick_mark                  action => pick
             | Stop                       action => stop
             | Repeat                     action => repeat
             | While                      action => While
             | If                         action => If
             | NewCommand                 action => call
Left       ::= left                       action => [ start, length ]
Forward    ::= forward                    action => [ start, length ]
Drop_mark  ::= drop_mark                  action => [ start, length ]
Pick_mark  ::= pick_mark                  action => [ start, length ]
Stop       ::= stop                       action => [ start, length ]
Repeat     ::= (repeat SC) Num (SC Times SC) Prog (SC done)
                                          action => [ values, start, length ]
While      ::= (while SC) Condition (SC) Prog (done)
                                          action => [ values, start, length ]
If         ::= (if SC) Condition (SC) Prog (done)
                                          action => [ values, start, length ]
             | (if SC) Condition (SC) Prog (SC else SC) Prog (done)
                                          action => [ values, start, length ]
Condition  ::= (there quote s SC a SC) Covering
                                          action => ::first
             | (there SC is SC a SC) Covering
                                          action => ::first
             | (Negation SC) Covering     action => negate
             | (facing SC) Wind           action => ::first
             | (not SC facing SC) Wind    action => negate
Negation   ::= (there SC isn quote t SC a)
             | (there SC is SC no)
             | (there quote s SC no)
Covering   ::= mark                       action => first_ch
             | wall                       action => first_ch
Wind       ::= North                      action => first_ch
             | East                       action => first_ch
             | South                      action => first_ch
             | West                       action => first_ch
Num        ::= non_zero                   action => ::first
             | non_zero digits            action => concat
Times      ::= times
             | x
Comment    ::= (octothorpe non_lf lf)
SC         ::= SpComm+
SCMaybe    ::= SpComm*
SpComm     ::= Comment
            || space

alpha      ~ [a-z]
valid_name ~ [-a-z_0-9]+
non_zero   ~ [1-9]
digits     ~ [0-9]+
space      ~ [\s]+
quote      ~ [']
non_lf     ~ [^\n]*
lf         ~ [\n]

__DSL__
$dsl .= join "\n", map "$_ ~ '$terminals{$_}'", keys %terminals;


has parser => ( is => 'ro' );

has _grammar => ( is => 'lazy' );

sub _dsl { $dsl }

sub _action_class { 'Karel::Parser::Actions' }

sub _terminals { \%terminals }

=item my @terminal_strings = $self->terminals(@terminals)

Returns the strings correscponding to the given terminal symbols.
E.g., C<< $self->terminals('octothorpe') >> returns C<#>.

=cut

sub terminals {
    my $self = shift;
    return map $self->_terminals->{$_} // $_, @_
}

sub _build__grammar {
    my ($self) = @_;
    my $g = 'Marpa::R2::Scanless::G'->new({ source => \$self->_dsl });
    return $g
}

=item my ($new_commands, $unknown) = $parser->parse($definition)

C<$new_commands> is a hash that you can use to teach the robot:

  $robot->_learn($_, $new_commands->{$_}, $definition) for keys %$new_commands;

C<$unknwon> is a hash whose keys are all the non-basic commands needed
to run the parsed programs.

When the input starts with C<run >, it should contain just one
command. The robot's C<run> function uses it to parse commands you
run, as simple C<[[ 'c', $command ]]> doesn't work for core commands
(C<left>, C<forward>, etc.).

If there's an error, an exception is thrown. It's a hash ref with the
following keys:

=over 4

=item -

B<expected>: lists the available terminals. There are several special
values: C<space> (white space), C<alpha> (letter starting a word),
C<lf> newline, C<non_lf> (anything but a newline), C<valid_name>
(character that can occur in a command name starting from the 2nd
position: a letter, digit, underscore, or a dash), C<quote> (single
quote), C<non_zero> (1-9).

=item -

B<last_completed>: the last successfully parsed command.

=item -

B<pos>: position (line, column) where the parsing stopped.

=back

=cut

sub parse {
    my ($self, $input) = @_;
    my $recce = 'Marpa::R2::Scanless::R'
                ->new({ grammar           => $self->_grammar,
                        semantics_package => $self->_action_class,
                      });

    my ($line, $column);
    eval {
        $recce->read(\$input);
    1 } or do {
        my $exception = $@;
        ($line, $column) = $recce->line_column;
    };

    my $value = $recce->value;
    if ($line || ! $value) {
        my ($from, $length) = $recce->last_completed('Command');
        my @expected = $self->terminals(@{ $recce->terminals_expected });
        my $E = bless { expected => \@expected }, ref($self) . '::Exception';
        my $last = $recce->substring($from, $length) if defined $from;
        $E->{last_completed} = $last if $last;
        if ($line) {
            $E->{pos} = [ $line, $column ];
        } else {
            $E->{pos} = [ $recce->line_column ];
        }
        die $E
    }
    return $input =~ /^run / ? $value : @$$value
}


{   package
        Karel::Parser::Exception;

    use overload '""' => sub { use Data::Dumper; Dumper \@_ };

}

=back

=cut

__PACKAGE__
