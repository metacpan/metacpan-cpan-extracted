# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 77 }
use HTML::Scrubber;
ok(1);    # If we made it this far, we're ok.              # test 1

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $html = q[
    <script>//blah</script>
    <HR Align="left">
    <B> bold <
        <U> underlined
            <I>
                <A href='#"'>  LINK    </A>
            </I>
        </U>
    </B>
    <!-- comments -->
];

my $scrubber = HTML::Scrubber->new();

ok($scrubber);                                   # test 2
ok( !$scrubber->default() );                     # test 3
ok( !$scrubber->comment() );                     # test 4
ok( !$scrubber->process() );                     # test 5
ok( !$scrubber->allow(qw[ p b i u hr br ]) );    # test 6

$scrubber = $scrubber->scrub($html);

ok($scrubber);                                   # test 7
ok( $scrubber !~ /href/i );                      # test 8
ok( $scrubber !~ /Align/i );                     # test 9
ok( $scrubber !~ /\Q<!--\E/ );                   # test 10
ok( $scrubber =~ /bold &lt;/ );                  # test 11

$scrubber = HTML::Scrubber->new( deny => [qw[ p b i u hr br ]] );

ok($scrubber);                                   # test 12
ok( !$scrubber->default() );                     # test 13
ok( !$scrubber->comment() );                     # test 14
ok( !$scrubber->process() );                     # test 15

$scrubber = $scrubber->scrub($html);

ok($scrubber);                                   # test 16
ok( $scrubber !~ /[><]/ );                       # test 17
ok( $scrubber !~ /href/i );                      # test 18
ok( $scrubber !~ /Align/i );                     # test 19
ok( $scrubber !~ /\Q<!--\E/ );                   # test 20
ok( $scrubber =~ /bold &lt;/ );                  # test 21

$scrubber = HTML::Scrubber->new( default => [0] );

ok($scrubber);                                   # test 22
ok( !$scrubber->default() );                     # test 23
ok( !$scrubber->comment() );                     # test 24
ok( !$scrubber->process() );                     # test 25

$scrubber = $scrubber->scrub($html);

ok($scrubber);                                   # test 26
ok( $scrubber !~ /[><]/ );                       # test 27
ok( $scrubber !~ /href/i );                      # test 28
ok( $scrubber !~ /Align/i );                     # test 29
ok( $scrubber !~ /\Q<!--\E/ );                   # test 30
ok( $scrubber =~ /bold &lt;/ );                  # test 31

$scrubber = HTML::Scrubber->new( default => [1] );

ok($scrubber);                                   # test 32
ok( $scrubber->default() );                      # test 33
ok( !$scrubber->comment() );                     # test 34
ok( !$scrubber->process() );                     # test 35

#use Data::Dumper;die Dumper( [ $scrubber, $scrubber->scrub($html) ]);

$scrubber = $scrubber->scrub($html);

ok($scrubber);                                   # test 36
ok( $scrubber =~ /[><]/ );                       # test 37
ok( $scrubber !~ /href/i );                      # test 38
ok( $scrubber !~ /Align/i );                     # test 39
ok( $scrubber !~ /\Q<!--\E/ );                   # test 40
ok( $scrubber =~ /bold &lt;/ );                  # test 41

$scrubber = HTML::Scrubber->new( default => [1] );

ok($scrubber);                                   # test 42
ok( $scrubber->default() );                      # test 43
ok( !$scrubber->comment() );                     # test 44
ok( !$scrubber->process() );                     # test 45
ok( !$scrubber->comment(1) );                    # test 46

$scrubber = $scrubber->scrub($html);

ok($scrubber);                                   # test 47
ok( $scrubber =~ /[><]/ );                       # test 48
ok( $scrubber !~ /href/i );                      # test 49
ok( $scrubber !~ /Align/i );                     # test 50
ok( $scrubber =~ /\Q<!--\E/ );                   # test 51
ok( $scrubber =~ /bold &lt;/ );                  # test 52

$scrubber = HTML::Scrubber->new( default => [ 1 => { align => 1, '*' => 0 } ] );

ok($scrubber);                                   # test 53
ok( $scrubber->default() );                      # test 54
ok( !$scrubber->comment() );                     # test 55
ok( !$scrubber->process() );                     # test 56
ok( !$scrubber->comment(1) );                    # test 57

$scrubber = $scrubber->scrub($html);

ok($scrubber);                                   # test 58
ok( $scrubber =~ /[><]/ );                       # test 59
ok( $scrubber !~ /href/i );                      # test 60
ok( $scrubber =~ /Align/i );                     # test 61
ok( $scrubber =~ /\Q<!--\E/ );                   # test 62
ok( $scrubber =~ /"left"/ );                     # test 63
ok( $scrubber =~ /bold &lt;/ );                  # test 64

$scrubber = HTML::Scrubber->new( default => [ 1 => { align => 0, '*' => 1 } ] );

ok($scrubber);                                   # test 65
ok( $scrubber->default() );                      # test 66
ok( !$scrubber->comment() );                     # test 67
ok( !$scrubber->process() );                     # test 68
ok( !$scrubber->comment(1) );                    # test 69
$scrubber = $scrubber->scrub($html);

ok($scrubber);                                   # test 70
ok( $scrubber =~ /[><]/ );                       # test 71
ok( $scrubber =~ /href/i );                      # test 72
ok( $scrubber !~ /Align/i );                     # test 73
ok( $scrubber =~ /\Q<!--\E/ );                   # test 74
ok( $scrubber =~ /\Q&quot\E/ );                  # test 75
ok( $scrubber =~ /\#/ );                         # test 76
ok( $scrubber =~ /bold &lt;/ );                  # test 77
