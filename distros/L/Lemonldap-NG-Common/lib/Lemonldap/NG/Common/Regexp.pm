## @file
# Common regexp issued from Regexp::Common

package Lemonldap::NG::Common::Regexp;

use AutoLoader 'AUTOLOAD';

1;

__END__

sub HOST {
qr{^(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z])[.]?)|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)|.{0})$};
}

sub HOSTNAME {
qr{^(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z])[.]?|.{0})$};
}

sub HTTP_URI {
qr{^(?:https?://(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z])[.]?)|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]*)))?(?:/(?:(?:(?:(?:(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:;(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*)(?:/(?:(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:;(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+\$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*))*))(?:[?](?:(?:(?:[;/?:@&=+\$,a-zA-Z0-9\-_.!~*'()]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)))?))?|.{0})$};
}

sub reDomainsToHost {
    my $list = shift;
    return qr/^$/ unless ($list);
    $list =~ s/^\./\\\./g;
    $list = join( '|', split( /\s+/, $list ) );
    return qr/^(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:$list)$/;
}

sub GOOGLEAXATTR {
    return qr/^(?:(?:la(?:nguag|stnam)|firstnam)e|country|email)$/;
}

sub OPENIDSREGATTR {
    return
qr/^(?:(?:(?:full|nick)nam|languag|postcod|timezon)e|country|gender|email|dob)$/;
}
