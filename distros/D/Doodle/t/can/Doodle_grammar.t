use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

grammar

=usage

  my $grammar = $self->grammar('sqlite');

=description

Returns a new Grammar object.

=signature

grammar(Str $name) : Grammar

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle", "grammar";

my $d = Doodle->new;

isa_ok $d->grammar('mssql'), 'Doodle::Grammar::Mssql';
isa_ok $d->grammar('mysql'), 'Doodle::Grammar::Mysql';
isa_ok $d->grammar('postgres'), 'Doodle::Grammar::Postgres';
isa_ok $d->grammar('sqlite'), 'Doodle::Grammar::Sqlite';

ok 1 and done_testing;
