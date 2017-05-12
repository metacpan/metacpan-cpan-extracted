#!perl -T

use Test::More tests => 21;

use Log::Fine qw( :macros :masks );
use Log::Fine::Levels;

{

        # Test construction
        my $fine = Log::Fine->new();

        isa_ok($fine, "Log::Fine");
        can_ok($fine, "name");

        # All objects should have names
        ok($fine->name() =~ /\w\d+$/);

        # Test retrieving a logging object
        my $log = $fine->logger("com0");

        # Make sure we got a valid object
        isa_ok($log, "Log::Fine::Logger");

        # Make sure _error() and _fatal() are present
        ok($log->can("_error"));
        ok($log->can("_fatal"));

        # Check name
        ok($log->can("name"));
        ok($log->name() =~ /\w\d+$/);

        # See if the object supports getLevels
        ok($log->can("levelMap"));
        ok($log->levelMap and $log->levelMap->isa("Log::Fine::Levels"));

        # Check default level map
        ok(ref $log->levelMap eq "Log::Fine::Levels::" . Log::Fine::Levels->DEFAULT_LEVELMAP);

        # See if object supports listLoggers
        ok($log->can("listLoggers"));

        my @loggers = $log->listLoggers();

        ok(scalar @loggers > 0);
        ok(grep("com0", @loggers));

        # Test error callback
        my $counter = 0;
        my $cbname  = "with_callback";
        my $fine2 = Log::Fine->new(name         => $cbname,
                                   err_callback => sub { my $msg = shift; ++$counter });

        isa_ok($fine2, "Log::Fine");
        can_ok($fine2, "_error");
        ok($fine2->name() eq $cbname);
        ok(ref $fine2->{err_callback} eq "CODE");

        $fine2->_error("I threw an error");
        ok($counter == 1);
        $fine2->_error("And here's another");
        ok($counter == 2);

        # Make sure we cannot pass a non-code ref
        eval { my $fine3 = Log::Fine->new(name => "badcb", err_callback => $counter); };

        ok($@ =~ /must be a valid code ref/);

}
