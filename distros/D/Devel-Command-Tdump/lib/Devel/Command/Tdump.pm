package Devel::Command::Tdump;
use strict;
use base qw(Devel::Command);

$Devel::Command::Tdump::VERSION = "1.1";
my %test_names = map { $_ => 1 } get_test_names();

# Preload Test::More
sub afterinit {
  push @DB::typeahead, "use Test::More qw(no_plan)";
}

# Dump just the tests
sub command {
  my ($cmd) = @_;
  my @tests; 
  my $tfh;

  my(undef, $outfile) = split(/\s+/,$cmd);
  $outfile = "unnamed_test.t" unless defined $outfile;;

  my $first_test = $DB::_first_test || 0;

  print DB::OUT "Recording tests for this session in $outfile ...";
  unless (open $tfh, ">$outfile") {
     print DB::OUT " can't write history: $!\n";
  }
  else {
    my @output;
    my $test_count = 0;
    my @lines = @DB::hist;

    while (@lines) {
      my $line = shift @lines;
      my $forced_capture = 0;
      # Following lines are comments?
      if (@lines) { 
        while ($lines[0] =~ /^\s*#/) {
          # Yes. Print and discard.
          push @output, $lines[0],"\n";
          $forced_capture = 1;
          shift @lines;
        }
      }
      # skip this one unless we are supposed to keep it
      # or it's a test
      my $is_test;
      next unless $forced_capture or 
        ($is_test = is_a_test($line, \%test_names)); 
      $test_count++ if $is_test;
      $line = "$line;" unless $line =~ /;$/;
      push @output, "$line\n";
    }
    unshift @output, "use Test::More tests=>$test_count;\n";
    print $tfh @output;
    close $tfh;
    my $s = ($test_count == 1 ? "" : "s");
    print DB::OUT " done ($test_count test$s).\n";
    $DB::_first_test = $#DB::hist;
  }
}

# Get the names defined in Test::More that are the names of tests
# and save them in a debugger global.
sub get_test_names {
  my @names = keys %Test::More::;
  grep { is_a_sub($_) } @names;
}


# Returns true if this is a sub in Test::More, false otherwise
sub is_a_sub {
  local $_ = shift;
  (!/^_/) and eval "defined &Test::More::$_";
}

# Returns true if this line of history is a Test::More test.
sub is_a_test {
  local $_    = shift;
  my    $map  = shift;
  if (my($possible, $paren) = /^\s*(\w+)\(/) {
    return $map->{$possible};
  }
}

1;

__END__

=cut

=head1 NAME

Devel::TestEmbed - extend the debugger with Test::More

=head1 SYNOPSIS

  # We assume that the supplied perldb.sample has been
  # copied to the appropriate place.
  $ perl -demo
  Loading DB routines from perl5db.pl version 1.27
  Editor support available.

  Enter h or `h h' for help, or `man perldebug' for more help.

  main::(-e:1):   mo
  auto(-1)  DB<1> use Test::More qw(no_plan)

    DB<2> use_ok("CGI");

    DB<3> $obj = new CGI;

    DB<4> # Keep 'new CGI' in our test

    DB<5> isa_ok($obj, "CGI")
  ok 2 - The object isa CGI

    DB<6> tdump "our.t"
  Recording tests for this session in our.t ... done (2 tests).

    DB<7> q
  1..2
  $ cat our.t
  use Test::More tests=>2;
  use_ok("CGI");
  # Keep 'new CGI' in our test
  $obj = new CGI;
  isa_ok($obj, "CGI");

=head1 DESCRIPTION

The C<Devel::TestEmbed> module loads C<Test::More> for you, allowing you to
use its functions to test code; you may then save the tests you used in this
debugger session via the C<tdump> function. 

If needed, you may save "setup" code in the test as well by entering a 
comment at the debugger prompt after each line of such code.

The module defines an C<afterinit> and C<watchfunction>; you will need to take this into account if you wish to defined either of these yourself while using this function. See C<perldoc perl5db.pl> for more informaton on these routines.

=head1 BUGS

Package switching is not captured at the moment.

=head1 AUTHOR

Joe McMahon F<E<lt>mcmahon@perl.comE<gt>>.
