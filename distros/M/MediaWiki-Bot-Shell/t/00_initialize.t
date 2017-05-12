use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    my $bail_diagnostic = <<'end';
There was a problem use-ing the module. Typically,
this means you have not installed the prerequisites.

Please check the documentation for installation
instructions, or ask for help from the developer.

The test suite will bail out now; doing more testing is
pointless since everything will fail.
end
    use_ok('MediaWiki::Bot::Shell') or BAIL_OUT($bail_diagnostic);
};

# Simple initialization
my $opts = {
    norc    => 1,

};
my $shell = new_ok('MediaWiki::Bot::Shell' => );
isa_ok($shell, 'MediaWiki::Bot::Shell');

my @methods = qw(new cmdloop);
can_ok($shell, @methods);

