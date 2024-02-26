#
# This file is adapted from Marpa::R2's t/sl_advent.t
#
package MyRecognizerInterface;
use strict;
use diagnostics;
use Log::Any qw/$log/;

sub new                    { my ($pkg, $string, %actions) = @_; bless { string => $string, actions => \%actions }, $pkg }
sub read                   { 1 }
sub isEof                  { 1 }
sub isCharacterStream      { 1 }
sub encoding               { }
sub data                   { $_[0]->{string} }
sub isWithDisableThreshold { 0 }
sub isWithExhaustion       { 0 }
sub isWithNewline          { 1 }
sub isWithTrack            { 1 }
sub resolver {
    my ($self, $action) = @_;

    my $stub;
    if ($action eq 'do_lexeme_regex') {
        #
        # Internal counter to check we can switch between dynamic and static
        #
        $self->{actions}->{do_lexeme_regex_count} = 0 unless defined $self->{actions}->{do_lexeme_regex_count};
        if (! $self->{actions}->{do_lexeme_regex_count}++) {
            $stub = sub {
                my ($self, @args) = @_;
                $log->infof('%s: %s[%d]: \@args=%s', ref($self) || $self, 'dynamic do_lexeme', $self->{actions}->{do_lexeme_regex_count}, \@args);
                return 0 # PCRE2 formalism, 0 means continue
            }
        }
    }
    $stub //= $self->{actions}->{$action}; # Can be undef
    $log->infof('%s: Trying to resolve recognizer action %s: %s', ref($self), $action, $stub);
    return $stub
}

sub do_lexeme_regex {
    my ($self, @args) = @_;

    $log->infof('%s: %s[%d]: \@args=%s', ref($self) || $self, 'static do_lexeme', $self->{actions}->{do_lexeme_regex_count}, \@args);
    0
}

package MyValueInterface;
use strict;
use diagnostics;
use Log::Any qw/$log/;

sub new                { my ($pkg, %actions) = @_; bless { result => undef, actions => \%actions }, $pkg }
sub isWithHighRankOnly { 1 }
sub isWithOrderByRank  { 1 }
sub isWithAmbiguous    { 0 }
sub isWithNull         { 0 }
sub maxParses          { 0 }
sub getResult          { $_[0]->{result} }
sub setResult          { $_[0]->{result} = $_[1] }
sub resolver {
    my ($self, $action) = @_;

    my $stub //= $self->{actions}->{$action}; # Can be undef
    $log->infof('%s: Trying to resolve recognizer action %s: %s', ref($self), $action, $stub);
    return $stub
}

sub do_shift {
    my ($self, @args) = @_;

    $log->infof('%s: %s: "$args[0]"="%s", @args=%s', ref($self) || $self, 'static do_shift', "$args[0]", \@args);
    return shift @args
}

package main;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::More::UTF8;
use Log::Any qw/$log/;
use Log::Any::Adapter 'Stdout';
use Encode qw/decode encode/;
use utf8;
use open ':std', ':encoding(utf8)';

BEGIN { require_ok('MarpaX::ESLIF') };

my @strings = (
    "(((3 * 4) + 2 * 7) / 2 - 1)/* This is a\n comment \n */** 3",
    "5 / (2 * 3)",
    "5 / 2 * 3",
    "(5 ** 2) ** 3",
    "5 * (2 * 3)",
    "5 ** (2 ** 3)",
    "5 ** (2 / 3)",
    "1 + ( 2 + ( 3 + ( 4 + 5) )",
    "1 + ( 2 + ( 3 + ( 4 + 50) ) )   /* comment after */",
    " 100    "
    );

my $eslif = MarpaX::ESLIF->new($log);
isa_ok($eslif, 'MarpaX::ESLIF');
my $grammar = MarpaX::ESLIF::Grammar->new($eslif, do { local $/; <DATA> } );
isa_ok($grammar, 'MarpaX::ESLIF::Grammar');

my $log_args = sub {
    my ($self, $action, @args) = @_;
    $log->infof('%s: %s: \@args=%s', ref($self) || $self, $action, \@args);
};

for (my $i = 0; $i <= $#strings; $i++) {
  my $string = $strings[$i];

  $log->infof("Testing parse() on %s", $string);
  my $recognizerInterfaceCount = 0;
  my $recognizerInterface = MyRecognizerInterface->new(
      $string,
      do_regex => sub { my ($self, @args) = @_; $self->$log_args('do_regex', @args); return 0 }, # PCRE2 formalism, 0 means continue
      );
  my $valueInterfaceCount = 0;
  my $valueInterface = MyValueInterface->new(
      do_symbol => sub { my ($self, @args) = @_; $self->$log_args('do_symbol', @args); return $args[0]                 },
      do_int    => sub { my ($self, @args) = @_; $self->$log_args('do_int',    @args); return int($args[0])            },
      do_mul    => sub { my ($self, @args) = @_; $self->$log_args('do_mul',    @args); return $args[0]      * $args[2] },
      do_group  => sub { my ($self, @args) = @_; $self->$log_args('do_group',  @args); return $args[1]                 },
      do_add    => sub { my ($self, @args) = @_; $self->$log_args('do_add',    @args); return $args[0]      + $args[2] },
      do_div    => sub { my ($self, @args) = @_; $self->$log_args('do_div',    @args); return $args[0]      / $args[2] },
      do_sub    => sub { my ($self, @args) = @_; $self->$log_args('do_sub',    @args); return $args[0]      - $args[2] },
      do_exp    => sub { my ($self, @args) = @_; $self->$log_args('do_exp',    @args); return $args[0]     ** $args[2] },
      );

  if ($grammar->parse($recognizerInterface, $valueInterface)) {
      $log->infof('===========> %s', $valueInterface->getResult);
  } else {
      $log->info('===========> ?');
  }
}

done_testing();

__DATA__
:start   ::= Expression
:default ::=             symbol-action         => do_symbol
                         default-encoding      => ASCII
                         fallback-encoding     => UTF-8
                         regex-action          => do_regex
:discard ::= /[\s]+/
:discard ::= /(?:(?:(?:\/\/)(?:[^\n]*)(?:\n|\z))|(?:(?:\/\*)(?:(?:[^\*]+|\*(?!\/))*)(?:\*\/)))/u

Number   ::= NUMBER                                  action => do_shift

Expression ::=
    Number                                           action => do_int
    | /\((?C"LParen")/ Expression ')' assoc => group action => do_group
   ||     Expression '**' Expression  assoc => right action => do_exp
   ||     Expression  '*' Expression                 action => do_mul
    |     Expression  '/' Expression                 action => do_div
   ||     Expression  '+' Expression                 action => do_add
    |     Expression  '-' Expression                 action => do_sub

:default   ~ regex-action => do_lexeme_regex
NUMBER     ~ /[\d]+(?C"NUMBER")/
