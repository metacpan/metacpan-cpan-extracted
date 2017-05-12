package MyTestEmail;

use strict;
use warnings;

use Test::More;

use parent 'Exporter';

our @EXPORT = qw/ test_email test_email_header /;

sub test_email {
    my( $email, $tests, $msg ) = @_;
    $msg ||= 'testing email';

    subtest $msg => sub {
        while( my($header,$t) = each %$tests ) {
            test_email_header( $email, $header, $t );
        }
    };
}

sub test_email_header {
    my( $email, $header, $test, $msg ) = @_;
    $msg ||= $header;

    my @heads = $email->header($header);
    my $value = join ' ', @heads;

    if ( ref $test eq 'RegEx' ) {
        like $value => $test, $header;
    }
    elsif ( ref $test eq 'CODE' ) {
        ok $test->(@heads), $header;
    }
    else {
        is $value => $test, $header;
    }
}

1;
