#!/run/bin/perl

use strict;
use warnings;
use feature 'say';
use Carp;

use lib qw{
          lib
       ../lib
    ../../lib
          run/t
       ../run/t
    ../../run/t
};

use Test::More 0.94;
use Test::Deep;
use Try::Tiny;

use IO::Capture::Stdout::Extended;
use IO::Capture::Stderr::Extended;
use IO::Capture::Sayfix;
use IO::Capture::Tellfix;



# passed to done_testing() after all subtests are run
my $test_counter    = 0;

# temp for actual calls to Test::More, Test::Deep, and friends
my $regex           ;
my $got             ;
my $expected        ;
my $subname         ;

# setup Test::Hump-ish
my $name            = 'dc-check-th';

my $self    = {
    
    
    };

$self->{-capture}{-stdout}  = IO::Capture::Stdout::Extended->new();
$self->{-capture}{-stderr}  = IO::Capture::Stderr::Extended->new();


# execute code within Test::Hump-ish box
$self->{-capture}{-stdout}->start();        # STDOUT captured
$self->{-capture}{-stderr}->start();        # STDERR captured
{
    try {
        my $outfh   = *STDERR;
        say $outfh '#-1';
        use Devel::Comments;
        say $outfh '#-2';
        ### check: 0 == 1
        say $outfh '#-3';
        no Devel::Comments;
    }
    catch {
        $self->{-got}{-evalerr} = $_;
    };
    
}
$self->{-capture}{-stdout}->stop();         # not captured
$self->{-capture}{-stderr}->stop();         # not captured

#~ # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#~ # DEBUG ONLY CODE
#~ 
#~ my $deb_filename    = '/home/xiong/projects/smartlog/file/simple-for-compare/LOG';
#~ open my $deb_fh, '>', $deb_filename
#~     or die qq{Couldn't open $deb_filename to write }, $!;
#~ 
#~ # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#~ # Account for tests run inside the box
#~ $test_counter   += 3;       # (1..3)

# Test for and report any eval error
$subname        = join q{}, $name, q{-evalerr};
$test_counter++;
ok( !$self->{-got}{-evalerr}, $subname );
diag("Eval error: $self->{-got}{-evalerr}") if $self->{-got}{-evalerr};

# define Test::Hump-ish subtests
my $do_cap_string   = sub {             # exact string eq STD*
    my $stdwhat     = shift;            # '-stdout' or '-stderr'
    $got            = $self->{-got}{$stdwhat}{-string}
                    = join q{}, $self->{-capture}{$stdwhat}->read;
    $expected       = $self->{-want}{$stdwhat}{-string};
#~ say {$deb_fh} "$stdwhat Got:      --|", $got, '|--';
#~ say {$deb_fh} "$stdwhat Lenth Got:      --|", length $got, '|--';
#~ say {$deb_fh} "$stdwhat Expected: --|", $expected, '|--';
#~ say {$deb_fh} "$stdwhat Length Expected: --|", length $expected, '|--';
    $subname        = join q{}, $name, $stdwhat, q{-string};
    $test_counter++;
    is( $got, $expected, $subname );
};

#~ # Simulate erase bar
#~ my $maxwidth            = 69;   # Maximum width of display
#~ my $erase_bar = join q{},
#~             qq{\r}, 
#~              q{ } x $maxwidth,
#~             qq{\r}, 
#~ ;
#~ my $close_bar = join q{},
#~             qq{\r}, 
#~              q{ } x $maxwidth,
#~             qq{\n}, 
#~ ;


# do subtests
my $subwhat         ;

$subwhat            = q{-stdout};
$self->{-want}{$subwhat}{-string}   
    = q{};          # exactly empty, thank you

&$do_cap_string($subwhat);

$subwhat            = q{-stderr};
$self->{-want}{$subwhat}{-string}   
    = q{#-1}        . qq{\n}
                                        # use
    . q{#-2}        . qq{\n}
        . qq{\n}
                                        # check
    . q{### 0 == 1 was not true at t/0200-dcr/31-check-th.t line 58.}
        . qq{\n}
        . qq{\n}
        . qq{\n}
    . qq{\n}
    . q{#-3}        . qq{\n}
                                        # no
    ;


&$do_cap_string($subwhat);

#   # character-by-character testing
#   my $obtained    = $self->{-got}{$subwhat}{-string};
#   my $want        = $self->{-want}{$subwhat}{-string};
#   my $length      = length $want;
#   foreach my $i (0..$length) {
#       $got            = substr $obtained, $i, 1;
#       $expected       = substr $want,     $i, 1;
#       $subname        = join q{}, $name, $subwhat, , q{-}, $i;
#       $test_counter++;
#       is( $got, $expected, $subname );
#   };


done_testing($test_counter);


#~ like $STDERR, qr/Simple for loop:|                   done\r/
#~                                             => 'First iteration';
#~ 
#~ like $STDERR, qr/Simple for loop:=========|          done\r/
#~                                             => 'Second iteration';

