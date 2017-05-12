package Devel::EvalContext;

{ package main; sub Devel::EvalContext::_hygenic_eval { eval $_[0] } }

use strict;
use warnings;

use PadWalker qw(peek_sub);
use Carp;
use Data::Alias qw(alias);
use B ();

our $VERSION = "0.09";

our $TRACING = 0;

# public interface needs:
#
#   create an empty context
#   create an empty context from here (is this possible?)
#   clone a context
#   evaluate in a context and get new context
#   inspect hints and variables

# global vars allowing bits to talk without using closures or lexicals
our $_new_context;

sub _warn {
  warn @_ if $TRACING;
}
sub _warnblock {
  _warn "  | $_\n" for split /\n/, $_[0];
}
sub _warndump {
  require YAML;
  _warnblock(YAML::Dump($_[0]));
}

sub _magic_code {
  qq{
#line 1 "_magic_code"
    sub {
      $_[0]
#line 3 "_magic_code"
      eval \$_[0];
    }
  };
}

sub _save_context {
  my $evalcv = delete $_new_context->{evalcv};
  _warn "saving context for ", $evalcv->object_2svref, "\n";

  $_new_context->{saved}++; # this confirms that the code has been compiled

  # should I do my own pp version?
  my $v = peek_sub $evalcv->object_2svref;
  $_new_context->{vars} = {};
  while (my ($key, $val) = each %$v) {
    next if $key =~ /^.__repl_/;
    _warn "  processing: $key => $val\n";
    $_new_context->{vars}{$key} = $val;
  }

  # save hints
  # hrm I'm getting the wrong values
  $_new_context->{hints}->{'$^H'} = $^H & ~(256);
  $_new_context->{hints}->{'%^H'} = \%^H;
  $_new_context->{hints}->{'$^W'} = $^W;
  $_new_context->{hints}->{'${^WARNING_BITS}'} = ${^WARNING_BITS};
}

# New context
sub new { return bless \{}, $_[0] }

sub trace {
  my ($s, $t) = @_;
  if ($t) {
    $$s->{trace} = $t;
  }
  return $$s->{trace};
}

# Run a context
sub run {
  my ($cxt, $code) = @_;
  local $TRACING = $$cxt->{trace};
  _warn "+", ("-" x 71), "\n";
  _warn "context_eval: {", $code, "} using ", $cxt, "/", $$cxt, "\n";

  local $_new_context = undef;

  # I bet I could write a PP version of this using B
  my $recreate_context = qq[\n#line 1 "<recreate_context>"\n];
  for my $var_name (qw($^H $^W ${^WARNING_BITS})) {
    my $val = $$cxt->{hints}{$var_name} || 0;
    $recreate_context .=
      qq[BEGIN { $var_name = $val; }\n];
  }
  $recreate_context .=
    q[BEGIN { %^H = %{$$cxt->{hints}{'%^H'} || {}}; }] . "\n";
  for my $var_name (keys %{$$cxt->{vars}}) {
    my $sigil = substr $var_name, 0, 1;
    $recreate_context .=
      qq[my $var_name; Data::Alias::alias $var_name = ] .
      qq[$sigil\{\$\$cxt->{vars}->{'$var_name'}};\n];
  }
  $recreate_context .= qq[package main;\n];
  $recreate_context .= q[
    BEGIN {
      local *^H = \do{my$x=$^H};
#      local *^H = {%^H};
      local *^W = \do{my$x=$^W};
      local *{^WARNING_BITS} = \do{my$x=${^WARNING_BITS}};
    }
  ] if 0;

  my $prologue = q[
#line 1 "<prologue>"
    Devel::EvalContext::_save_context();
    BEGIN {
      $Devel::EvalContext::_new_context->{evalcv} =
        B::svref_2object(sub{})->OUTSIDE->OUTSIDE;
    }
  ];
  $prologue .= "{ no warnings; " .
    join(" ", map "$_;", keys %{$$cxt->{vars}}) . " }\n";

  # TODO: make this eval hygenic
  my $evaluator = eval do {
    my $m = _magic_code($recreate_context);
    _warn "magic_code:\n"; _warnblock $m;
    $m
  };
  if ($@) {
    croak "Devel::EvalContext::run: internal error: $@";
  }

  if ($TRACING) {
    require B::Deparse;
    _warn "evaluator:\n"; _warnblock(B::Deparse->new->coderef2text($evaluator));
  }

  $code = qq[$prologue\n#line 1 "<interactive>"\n$code\n];
  _warn "code:\n"; _warnblock($code);

  my $user_retval = $evaluator->($code);
  my $user_error = $@;

  # A = $user_error
  # B = $_new_context->{saved}
  # 0  : we're screwed, compiled but not run, but no errors reported
  # A  : compile error, retval invalid, not run
  # B  : retval okay, compile & run ok
  # AB : runtime error, retval invalid, compile ok

  if ($_new_context->{saved}) {
    # frob it to make sure we keep the variables
    # This does the same thing as the variable mentioning in the prologue
    $_new_context->{vars} = {%{$$cxt->{vars}}, %{$_new_context->{vars}}};

    _warn "new context:\n";
    _warndump($_new_context);
  }

  $_new_context->{trace} = $TRACING;

  if (ref($user_error) or $user_error ne '') {
    if ($_new_context->{saved}) { # runtime error
      $$cxt = $_new_context;
      return ($user_error, undef);
    } else { # compile error
      die $user_error;
    }
    return;
  }
  # success below here

  # no error so we expect the save to have worked
  croak "Devel::EvalContext::run: internal error: not saved but no error"
    unless $_new_context->{saved};

  _warn "retval: ", $user_retval, "\n";

  $$cxt = $_new_context;
  return (undef, $user_retval);
}

1;

__END__

=head1 NAME

Devel::EvalContext - Save lexicals and hints between calls to eval

=head1 SYNOPSIS

  use Devel::EvalContext;
  my $cxt = Devel::EvalContext->new;
  $cxt->run(q{ my $a = 5; });
  $cxt->run(q{ print $a; });

=head1 DESCRIPTION

Sometimes it's necessary to run some code that creates lexicals and then
run I<more> code that uses the same ones.  Perhaps it's in an interactive
development environment.

However, unlike Scheme, perl's eval primitive doesn't take an extra
parameter to specify the environment to evaluate inside of.  This module
corrects this deficit.

=head1 METHODS

=head2 new

Create a new, empty context.  It has no lexicals and hints are set to zero.

=head2 run

Equivalent to eval but with a context specified.

=head1 SUPPORT

Please send bugs, queries or encouragement to
E<lt>bug-Devel-EvalContext@rt.cpan.orgE<gt> or E<lt>bsmith@cpan.orgE<gt>.

=head1 SEE ALSO

L<perlfunc>

=head1 AUTHOR

Benjamin Smith E<lt>bsmith@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Benjamin Smith.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
