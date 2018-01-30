package Devel::GlobalPhase;
use strict;
use warnings;

our $VERSION = '0.003003';
$VERSION = eval $VERSION;

use base 'Exporter';

our @EXPORT = qw(global_phase);

BEGIN {
  *_CALLER_CAN_SEGFAULT = ("$]" >= 5.008009 && "$]" < 5.018000) ? sub(){1} : sub(){0};
  *_NATIVE_GLOBAL_PHASE = "$]" >= 5.014000 ? sub(){1} : sub(){0};
}

sub global_phase ();
sub tie_global_phase;
sub _refresh_END ();

sub import {
  my $class = shift;
  my $var;
  my @imports = map {
    ($_ && $_ eq '-var') ? do {
      $var = 1;
      ();
    } : $_;
  } @_;
  if (@imports || !$var) {
    Exporter::export_to_level($class, 1, @imports);
  }
  _refresh_END;
  if ($var) {
    tie_global_phase;
  }
}

BEGIN {
  if (_NATIVE_GLOBAL_PHASE) {
    eval <<'END_CODE' or die $@;

sub global_phase () {
  return ${^GLOBAL_PHASE};
}

sub tie_global_phase { 1 }

sub _refresh_END () { 1 }

1;

END_CODE
  }
  else {
    eval <<'END_CODE' or die $@;

use B ();

my $global_phase = 'START';
if (B::main_start()->isa('B::NULL')) {
  # loaded during initial compile
  eval <<'END_EVAL' or die $@;

    CHECK { $global_phase = 'CHECK' }
    # try to install an END block as late as possible so it will run first.
    INIT  { my $capture = $global_phase; eval q( END { $global_phase = 'END' } ) }
    # INIT is FIFO so we can force our sub to be first
    unshift @{ B::init_av()->object_2svref }, sub { $global_phase = 'INIT' };

    1;

END_EVAL
}
else {
  # loaded during runtime
  $global_phase = 'RUN';
}
END { $global_phase = 'END' }

sub _refresh_END () {
  my $capture = $global_phase;
  eval q[ END { $global_phase = 'END' } ];
}

sub global_phase () {
  if ($global_phase eq 'DESTRUCT') {
    # no need for extra checks at this point
  }
  elsif ($global_phase eq 'START') {
    # we use a CHECK block to set this as well, but we can't force
    # ours to run before other CHECKS
    if (!B::main_root()->isa('B::NULL') && B::main_cv()->DEPTH == 0) {
      $global_phase = 'CHECK';
    }
  }
  elsif (${B::main_cv()} == 0) {
    $global_phase = 'DESTRUCT';
  }
  elsif ($global_phase eq 'INIT' && B::main_cv()->DEPTH > 0) {
    _refresh_END;
    $global_phase = 'RUN';
  }

  # this is slow and can segfault, so skip it
  if (!_CALLER_CAN_SEGFAULT && $global_phase eq 'RUN' && $^S) {
    # END blocks are FILO so we can't install one to run first.
    # only way to detect END reliably seems to be by using caller.
    # I hate this but it seems to be the best available option.
    # The top two frames will be an eval and the END block.
    my $i = 0;
    $i++ while defined CORE::caller($i + 1);
    if ($i < 1) {
      # there should always be the sub call and an eval frame ($^S is true).
      # this will only happen if we're in END, but the outer frames are broken.
      $global_phase = 'END';
    }
    elsif ($i > 1) {
      my $top = CORE::caller($i);
      my $next = CORE::caller($i - 1);
      if (!$top || !$next) {
        $global_phase = 'END';
      }
      elsif ($top eq 'main' && $next eq 'main') {
        # If we're ENDing due to an exit or die in a sub generated in an eval,
        # these caller calls can cause a segfault.  I can't find a way to detect
        # this.
        my @top = CORE::caller($i);
        my @next = CORE::caller($i - 1);
        if (
          $top[3] eq '(eval)'
          && $next[3] =~ /::END$/
          && $top[2] == $next[2]
          && $top[1] eq $next[1]
        ) {
          $global_phase = 'END';
        }
      }
    }
  }

  return $global_phase;
}

{
  package # hide
    Devel::GlobalPhase::_Tie;

  sub TIESCALAR { bless \(my $s), $_[0]; }
  sub STORE {
    die sprintf "Modification of a read-only value attempted at %s line %s.\n", (caller(0))[1,2];
  }
  sub FETCH {
    return undef
      if caller eq 'Devel::GlobalDestruction';
    Devel::GlobalPhase::global_phase;
  }
  sub DESTROY {
    my $tied = tied ${^GLOBAL_PHASE};
    if ($tied && $tied == $_[0]) {
      untie ${^GLOBAL_PHASE};
      my $phase = Devel::GlobalPhase::global_phase;
      Internals::SvREADONLY($phase, 1) if defined &Internals::SvREADONLY;
      *{^GLOBAL_PHASE} = \$phase;
    }
  }
}

sub tie_global_phase {
  unless ('Devel::GlobalPhase::_Tie' eq ref tied ${^GLOBAL_PHASE}) {
    tie ${^GLOBAL_PHASE}, 'Devel::GlobalPhase::_Tie';
  }
  1;
}

1;
END_CODE
  }
}

1;

__END__

=head1 NAME

Devel::GlobalPhase - Detect perl's global phase on older perls.

=head1 SYNOPSIS

    use Devel::GlobalPhase;
    print global_phase; # RUN

    use Devel::GlobalPhase -var;
    print ${^GLOBAL_PHASE}; # RUN

=head1 DESCRIPTION

This gives access to L<${^GLOBAL_PHASE}|perlvar/${^GLOBAL_PHASE}>
in versions of perl that don't provide it. The built in variable will be
used if it is available.

If all that is needed is detecting global destruction,
L<Devel::GlobalDestruction> should be used instead of this module.

=head1 EXPORTS

=head2 global_phase

Returns the global phase either from C<${^GLOBAL_PHASE}> or by calculating it.

=head1 OPTIONS

=head2 -var

If this option is specified on import, the global variable
C<${^GLOBAL_PHASE}> will be created if it doesn't exist, emulating the
built in variable from newer perls.

=head1 BUGS

=over 4

=item *

There are tricks that can be played with L<B> or XS that would fool this
module for the INIT and END phase.

=item *

During an C<END {}> block created at runtime after this module is loaded, the
phase may be reported as C<RUN>.  While this could be made more accurate, it
would slow down the module significantly during the RUN phase, and has the
potential to segfault perl.

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

Uses some code taken from L<Devel::GlobalDestruction>.

=head1 COPYRIGHT

Copyright (c) 2013 the Devel::GlobalPhase L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
