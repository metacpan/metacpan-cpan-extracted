use strict;
use warnings;

use Test::More;
use JSON ();

use_ok('Email::Address::List');

foreach my $file (qw(t/data/RFC5233.single.valid.json t/data/RFC5233.single.obs.json)) {
    my $obsolete = $file =~ /\bobs\b/? 1 : 0;

    open my $fh, '<', $file;
    my $tests = JSON->new->decode( do { local $/; <$fh> } );
    close $fh;

    foreach my $test ( @$tests ) {
        note $test->{'description'};
        my @list = Email::Address::List->parse( $test->{'mailbox'} );
        is scalar @list, 1, "one entry in result set" or do { use Data::Dumper; diag Dumper \@list };
        is $list[0]{'type'}, 'mailbox', 'one mailbox';
        my $v = $list[0]{'value'};
        is $v->phrase, $test->{'display-name'}, 'correct value';
        is $v->address, $test->{'address'}, 'correct value';
        is $v->comment, join( ' ', @{$test->{'comments'}} ), 'correct value';
    }
}

done_testing();
