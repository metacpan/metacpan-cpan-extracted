package FormValidator::Nested::Validator::Email;
use strict;
use warnings;
use utf8;


# http://www.din.or.jp/~ohzaki/mail_regex.htm#Simplify
my $mail_regex =
    q{(?:[-!#-'*+/-9=?A-Z^-~]+(?:\.[-!#-'*+/-9=?A-Z^-~]+)*|"(?:[!#-\[\]-} .
    q{~]|\\\\[\x09 -~])*")@[-!#-'*+/-9=?A-Z^-~]+(?:\.[-!#-'*+/-9=?A-Z^-~]+} .
    q{)*};

sub email {
    my ( $value, $options, $req ) = @_;

    if ( $value =~ m/\A$mail_regex\z/o ) {
        return 1;
    }
    return 0;
}


1;
