use strict;
use warnings;
use Test::More tests => 12;
BEGIN { use_ok('Exception::Class::DBI') }

SUBCLASSES: {
    package MyApp::Ex::DBI;
    use base 'Exception::Class::DBI';

    package MyApp::Ex::DBI::H;
    use base 'MyApp::Ex::DBI', 'Exception::Class::DBI::H';

    package MyApp::Ex::DBI::DRH;
    use base 'MyApp::Ex::DBI', 'Exception::Class::DBI::DRH';

    package MyApp::Ex::DBI::DBH;
    use base 'MyApp::Ex::DBI', 'Exception::Class::DBI::DBH';

    package MyApp::Ex::DBI::STH;
    use base 'MyApp::Ex::DBI', 'Exception::Class::DBI::STH';

    package MyApp::Ex::DBI::Unknown;
    use base 'MyApp::Ex::DBI', 'Exception::Class::DBI::Unknown';
}

use DBI;

# Make sure that the same handler is used every time.
is +MyApp::Ex::DBI->handler, MyApp::Ex::DBI->handler,
    'The handler code ref should always be the same for the subclass';
is +Exception::Class::DBI->handler, Exception::Class::DBI->handler,
    'The base class handler should always be the same code ref';
isnt +MyApp::Ex::DBI->handler, Exception::Class::DBI->handler,
    'The subclass handler should be different from the base class handler';

ok my $dbh = DBI->connect('dbi:ExampleP:dummy', '', '', {
    PrintError  => 0,
    RaiseError  => 0,
    HandleError => MyApp::Ex::DBI->handler,
}), 'Connect to database';

END { $dbh->disconnect if $dbh };

# Check that the error_handler has been installed.
isa_ok $dbh->{HandleError}, 'CODE', 'The HandleError attribute';

# Trigger an exception.
eval {
    my $sth = $dbh->prepare('select * from foo');
    $sth->execute;
};

# Make sure we got the proper exception.
ok my $err = $@, 'Catch exception';
isa_ok $err, 'Exception::Class::DBI', 'The exception';
isa_ok $err, 'Exception::Class::DBI::H', 'The exception';
isa_ok $err, 'Exception::Class::DBI::STH', 'The exception';
isa_ok $err, 'MyApp::Ex::DBI::STH', 'The exception';
isa_ok $err, 'MyApp::Ex::DBI', 'The exception';

# This keeps Perl 5.6.2 from trying to run tests again. I've no idea why it
# does that. :-(
exit;
