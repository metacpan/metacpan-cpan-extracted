package Devel::Unwind;
use strict;
use XSLoader;
use Exporter;

our @ISA = qw(Exporter);
our $VERSION = '0.013';

XSLoader::load(__PACKAGE__, $VERSION);

=pod

=encoding utf8

=head1 NAME

Devel::Unwind - What if you could die to a labeled eval?

=head1 SYNOPSIS

    use Devel::Unwind;

    $SIG{__DIE__} = sub { print "I die: @_" };

    mark FOO {
        unwind FOO;
    };

    mark FOO {
        unwind FOO "foobar";
        1;
    } or do {
        print "or do: $@";
    };

    mark FOO {
        unwind FOO 1..5;
    };

    package BAR {
        sub PROPAGATE {print "I propagate: @_\n"; $_[0]->[0]}
    }
    mark FOO {
        $@ = bless ["baz"], "BAR";
        unwind FOO;
    }

=head1 DESCRIPTION

Imagine Perl had the ability to die to a labeled eval so that when
you write

  FOO: eval {...}

you could die to that labeled eval

  die FOO "bar";

That is essentially what Devel::Unwind gives you. Two custom keywords
'mark','unwind' are added allowing you two write

  use Devel::Unwind;

  mark FOO {...} or do {...}
  unwind FOO "bar";
  unwind FOO "bar","baz";
  unwind FOO (bless [], "Bar");
  unwind FOO;

Wherever you would put a block 'eval' an 'mark' expression can be
used.  And wherever you would 'die' you can 'unwind'. If a
$SIG{__DIE__} handler is installed then it gets called on
'unwind'. The arguments to 'unwind' are treated the same way as the
arguments to 'die'. Multiple arguments are joined to togeter, a single
argument is passed through untouched unless it is a object with
PROPAGATE method in which case $@ gets replaced by the return value of
that method. For details read the documentation of die.

=head1 AUTHORS

Andreas Guðmundsson C<< andreasg@cpan.org >>

=cut

1;
