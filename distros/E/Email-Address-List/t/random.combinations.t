use strict;
use warnings;

use Test::More;
use JSON ();

use_ok('Email::Address::List');

my @data;
foreach my $file (qw(t/data/RFC5233.single.valid.json t/data/RFC5233.single.obs.json)) {
    my $obsolete = $file =~ /\bobs\b/? 1 : 0;

    open my $fh, '<', $file;
    push @data, @{ JSON->new->decode( do { local $/; <$fh> } ) };
    close $fh;
}

diag "srand is ". (my $seed = int rand( 2**16-1 ));
srand($seed);

for (1..100) {
    my @list;
    push @list, $data[ rand @data ] for 1..3;

    my $line = join ', ', map $_->{'mailbox'}, @list;
    note $line;

    my @res = Email::Address::List->parse( $line );
    is scalar @res, scalar @list;

    for (my $i = 0; $i < @list; $i++) {
        my $test = $list[$i];
        my $v = $res[$i]{'value'};
        is $v->phrase, $test->{'display-name'}, 'correct value';
        is $v->address, $test->{'address'}, 'correct value';
        is $v->comment, join( ' ', @{$test->{'comments'}} ), 'correct value';
    }
}

for (1..100) {
    my @list;
    push @list, $data[ rand @data ] for 1..3;

    my $line = join ",\n ,", '', (map $_->{'mailbox'}, @list), '';
    note $line;

    my @res = Email::Address::List->parse( $line );
    is scalar @res, scalar @list;

    for (my $i = 0; $i < @list; $i++) {
        my $test = $list[$i];
        my $v = $res[$i]{'value'};
        is $v->phrase, $test->{'display-name'}, 'correct value';
        is $v->address, $test->{'address'}, 'correct value';
        is $v->comment, join( ' ', @{$test->{'comments'}} ), 'correct value';
    }
}

done_testing;

