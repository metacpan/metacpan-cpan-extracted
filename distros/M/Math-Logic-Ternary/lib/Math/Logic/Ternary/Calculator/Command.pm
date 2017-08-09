# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Calculator::Command;

use 5.008;
use strict;
use warnings;
use Carp qw(croak);
use Math::Logic::Ternary::Calculator::Version;
use Math::Logic::Ternary::Calculator::Operator;

use constant OP => Math::Logic::Ternary::Calculator::Operator::;

use constant TC_MIN_ARGS    => 0;
use constant TC_VAR_ARGS    => 1;
use constant TC_CODE        => 2;
use constant TC_DESCRIPTION => 3;

our $VERSION = '0.004';

my %tool_commands     = ();     # name  => [min_args, var_args, code, descr]
my @initial_commands  = ();     # index => [rank, code]
my $license = _read_own_license();

_define_builtins();

# ----- private subroutines -----

sub _version {
    print Math::Logic::Ternary::Calculator::Version->long_name, "\n";
    return 1;
}

sub _greeting {
    _version();
    print
        qq{type "?" to get help, "/license" to display },
        qq{license and copyright notice\n};
    return 1;
}

sub _quit { 0 }

sub _license {
    print $license;
    return 1;
}

sub _help {
    my ($session, $topic) = @_;
    if (!defined $topic) {
        print
            qq{Type "? <command>" or "? <operator>" },
            qq{to get help about a command or operator.\n},
            qq{Available commands:\n},
            join(q[ ], sort keys %tool_commands), "\n";
        return 1;
    }
    if (exists $tool_commands{$topic}) {
        my $descr = $tool_commands{$topic}->[TC_DESCRIPTION];
        if (!defined $descr) {
            $descr = "$topic (description not available)\n";
        }
        print $descr;
        return 1;
    }
    if ('/' eq substr $topic, 0, 1) {
        print "$topic: unknown command\n";
        return 1;
    }
    my $mode = $session->state->mode;
    my $op = OP->find($topic, $mode);           # TODO: abstraction
    if (!ref $op) {
        print "$topic: $op\n";
        return 1;
    }
    print $op->description($mode);
    return 1;
}

sub _read_own_license {
    local $/ = q[];
    my $text = q[];
    my $copy = 0;
    while (defined(my $par = <DATA>)) {
        if ($copy) {
            $par =~ s/^=head1 (?=DISCLAIMER)//;
            $par =~ s/\blibrary\b/application/g;
            last if $par =~ /^=/;
            $text .= $par;
        }
        elsif ($par =~ s/^=head1 (?=COPYRIGHT)//) {
            $copy = 1;
            $text = $par;
        }
    }
    close DATA;
    die "assertion failed: missing copyright notice" if !$copy;
    return $text;
}

sub _define_builtins {
    my $class = caller;
    $class->def_initial_command(0,             \&_greeting);
    $class->def_tool_command('/version', 0, 0, \&_version , <<'EOT');
/version
display software version
EOT
    $class->def_tool_command('/quit',    0, 0, \&_quit    , <<'EOT');
/quit
quit calculator session
EOT
    $class->def_tool_command('/license', 0, 0, \&_license , <<'EOT');
/license
display license and copyright notice
EOT
    $class->def_tool_command('?',        0, 1, \&_help    , <<'EOT');
? [command|operator]
show general help text or describe a command or operator
EOT
}

# ----- class methods -----

sub def_initial_command {
    my ($class, $rank, $code, @args) = @_;
    my $pos = @initial_commands;
    while ($pos && $initial_commands[$pos-1]->[0] > $rank) {
        --$pos;
    }
    my $cmd = $class->custom_command($code, @args);
    splice @initial_commands, $pos, 0, [$rank, $cmd];
    return;
}

sub get_initial_commands {
    my ($class) = @_;
    return map { $_->[1] } @initial_commands;
}

sub def_tool_command {
    my ($class, $name, $min_args, $var_args, $code, $descr) = @_;
    $tool_commands{$name} = [$min_args, $var_args, $code, $descr];
    return;
}

sub greeting_command {
    my ($class) = @_;
    my $cmd = \&_greeting;
    return bless $cmd, $class;
}

sub unknown_command {
    my ($class, $name) = @_;
    return bless sub {
        print "unknown command: $name\n";
        return 1;
    }, $class;
}

sub unknown_operator {
    my ($class, $name, $comment) = @_;
    return bless sub {
        print "unknown operator: $name: $comment\n";
        return 1;
    }, $class;
}

sub not_implemented {
    my ($class, $name) = @_;
    return bless sub {
        print "internal error: method not implemented: $name\n";
        return 1;
    }, $class;
}

sub wrong_usage {
    my ($class, $reason) = @_;
    return bless sub {
        print "wrong usage: $reason\n";
        return 1;
    }, $class;
}

sub bad_value {
    my ($class, $reason) = @_;
    return bless sub {
        print "bad value: $reason\n";
        return 1;
    }, $class;
}

sub _WRONG_ARGC {
    my ($min_args, $var_args, $act_args) = @_;
    return
        $act_args < $min_args ||
        0 <= $var_args && $min_args + $var_args < $act_args;
}

sub check_argc {
    my ($class, $name, $min_args, $var_args, $act_args) = @_;
    my $max_args = $min_args + $var_args;
    if ($min_args <= $act_args && ($var_args < 0 || $act_args <= $max_args)) {
        return q[];
    }
    my $n =
        1 <  $var_args? "$min_args .. $max_args":
        1 == $var_args? "$min_args or $max_args":
        0 >  $var_args? "at least $min_args":
        $min_args? "exactly $min_args" : 'no';
    my $s = 1 == $max_args? '': 's';
    return qq{$name takes $n argument$s};
}

sub tool_command {
    my ($class, $name, @args) = @_;
    if ($name =~ s{^\?([/?\w].*)}{?}s) {
        unshift @args, $1;              # treat "?foo" as ("?", "foo")
    }
    return $class->unknown_command($name) if !exists $tool_commands{$name};
    my ($min_args, $var_args, $code) = @{$tool_commands{$name}};
    if (my $error = $class->check_argc($name, $min_args, $var_args, 0+@args)) {
        return $class->wrong_usage($error);
    }
    return bless sub { $code->($_[0], @args) }, $class;
}

sub custom_command {
    my ($class, $code, @args) = @_;
    return bless sub { $code->($_[0], @args) }, $class;
}

# ----- object methods -----

sub execute { my $cmd = shift; $cmd->(@_) }

1;
__DATA__
=head1 NAME

Math::Logic::Ternary::Calculator::Command - ternary calculator commands

=head1 VERSION

This documentation refers to version 0.004 of
Math::Logic::Ternary::Calculator::Command.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Calculator::Command;
  use constant CMD => Math::Logic::Ternary::Calculator::Command::;

  CMD->def_tool_command('/myfunc', 2, 1, \&myfunc, <<'EOT');
  /myfunc foo bar [baz]
  frobnicate foo with bar and optional baz
  EOT

  sub myfunc {
      my ($session, $foo, $bar, $baz) = @_;
      if ($bar < 0) {
          CMD->bad_value("bar = $bar < 0")->execute($session);
      }
      elsif ($foo !~ /^\w+\z/) {
          CMD->wrong_usage("$foo: not an identifier")->execute($session);
      }
      else {
          ...
      }
      return 1;   # continue session
  }

  CMD->tool_command('/myfunc', 'beep', 32);

=head1 DESCRIPTION

TODO

=head2 Exports

None.

=head1 SEE ALSO

=over 4

=item L<Math::Logic::Ternary::Calculator>

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
