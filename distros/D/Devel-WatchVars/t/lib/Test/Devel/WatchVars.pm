package # hide from PAUSE indexer / CPAN indexing
    Test::Devel::WatchVars;

use utf8;
use strict;
use warnings;
use feature qw(say);
no indirect "fatal";

our $VERSION = v0.0.1;

use Capture::Tiny qw(:all);
use Carp;
use Test::More (); # To use the local $Test::Builder::Level cheat
use Test::Warn;
use Test2::V0;

our $DOT_Carp = Carp->VERSION ge "1.25" ? "." : "";

our $MAIN_PKG = 
    __PACKAGE__ =~ /^Test::(\S+)\z/ 
        ? $1 
        : confess "bad package: " . __PACKAGE__;

our $TIE_PKG  = $MAIN_PKG . "::Tie::Scalar";

{
    die unless eval "use $MAIN_PKG; 1";
    no strict "refs";
    no warnings "once";
    push @{ $MAIN_PKG . "::CARP_NOT" }, __PACKAGE__, qw[Capture::Tiny];
}

sub banner             (     ) ;
sub deQ                ( $   ) ;
sub deQQ               ( $   ) ;
sub dies_compiling     ( $   ) ;
sub is_lines           ( $$$ ) ;
sub lines              ( _   ) ;
sub run_eponymous_test (     ) ;
sub strip_leader       ( $$  ) ;
sub stutter            ( _   ) ;

use Exporter qw(import);
our @EXPORT = qw(
    $DOT_Carp
    $MAIN_PKG
    $TIE_PKG

    banner
    deQ
    deQQ
    dies_compiling
    is_lines
    lines
    run_eponymous_test
    stutter
);

#################################################

sub run_eponymous_test() {
    my($pkg, $file, $line) = caller;
    my($test_sub) = $file =~ /(\w+)[.]t\z/;

    $test_sub =~ s/^/test_/;

    my $it  = "eponymous test";
    my $its = $it . "'s";

    warnings_are {
        local $@;
        (ok lives { $pkg->$test_sub }, "$it doesn't die")
            || diag "$its exception was: $@";
    } [], "no untrapped warnings in $it";

    done_testing;
}

sub is_lines($$$) {
    my($have, $want, $message) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $ok = is lines $have, lines $want, $message;
    diag "Failing test had these lines:\n$have\nBut it wanted these lines:\n$want\n" unless $ok;
    return $ok;
}

sub dies_compiling($) {
    my($codestr) = @_;
    my(undef, $file, $line) = caller;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is eval(deQQ<<"END_OF_EVAL_STRING"), undef, "compiling { $codestr } dies during compilation";
        |QQ| #line $line "$file"
        |QQ| use warnings FATAL => 'all';
        |QQ| sub { $codestr };
        |QQ| 1;
END_OF_EVAL_STRING

    return $@;
}

#################################################

sub stutter(_) {
    my($line) = @_;
    my $count = 1;
    $count++ if $^V lt v5.14;
    return $line x $count;
}

sub strip_leader($$) {
    my($leader, $body) = @_;
    for ($body) {
        s/^\s*\Q$leader\E ?//gm;
        # discard any trailing white space:
        s/ \h+ $//xgm;
        # guarnatee no blank line at start or end
        s/ \A (?:\R\h*)+    //x;
        s/    (?:\R\h*)+ \z /\n/x;
    }
    return $body;
}
sub deQ ($) { my($text) = @_; return strip_leader  q<|Q|>,  $text }
sub deQQ($) { my($text) = @_; return strip_leader qq<|QQ|>, $text }

sub banner() {
    (my $sub  = (caller 1)[3]) =~ s/.*:://;
    my $note = "Testing sub $sub";
    #print STDERR "$note" . (" " x 70) . "\r";
    my $bar = "-" x (4 + length $note);
    note "$bar\n  $note\n$bar\n";
}

sub lines(_) { [split /\n/, shift, -1] }

1;
