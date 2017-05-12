# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN {
    plan(
        tests => 12,
        onfail => sub { exit @_ },
    );
}
use HTML::LinkExtractor;
ok(1); # If we made it this far, we're ok.

my $output = `$^X $INC{'HTML/LinkExtractor.pm'}`;

#use Data::Dumper;die Dumper $output;

ok( $output =~ m{9 we GOT}  or 0 );
ok( $output =~ m{\Q'cite' => 'http://www.stonehenge.com/merlyn/'} or 0 );
ok( $output =~ m{\Q'url' => 'http://www.foo.com/foo.html'} or 0 );

my $LX = HTML::LinkExtractor::->new(undef,undef,1);

ok( $LX->strip or 0 );
ok( $LX->strip(1) && $LX->strip or 0 );

$LX->parse(\ q{ <a href="http://slashdot.org">stuff that matters</a> } );

#use Data::Dumper;warn Dumper( scalar $LX->links );
ok( $LX->links->[0]->{_TEXT} eq "stuff that matters" or 0);

$LX = HTML::LinkExtractor::->new(
    sub {
        my( $lx, $link ) = @_;
        $output = $link->{_TEXT};
    },
    'http://use.perl.org', 1
);

ok(1);

$LX->parse(\ q{
<a href="http://use.perl.org/search.pl?op=stories&author=4">perl guy</a>
} );

ok( $output eq 'perl guy' or 0 );
ok( @{ $LX->links } == 0 ? 1 : 0 );

# bug#5470

$output = [];
$LX = HTML::LinkExtractor::->new(
    sub {
        my( $lx, $link ) = @_;
        push @$output,$link;
    },
    'http://use.perl.org', 1
);


$LX->parse(\ q{
<a href="http://www.foo.com"><img src="http://www.bar.com/img.gif"></a>
} );


ok( @$output == 2  );


$LX = HTML::LinkExtractor::->new(undef, 'http://use.perl.org', 1 );

$LX->parse(\ q{
<a href="http://www.foo.com"><img src="http://www.bar.com/img.gif" alt="fooger"></a>
} );

ok( @{ $LX->links } == 2 );