package TestJS;
use Test::Base -Base;
use JS;

package TestJS::Filter;
use Test::Base::Filter -Base;
require Win32 if $^O eq 'MSWin32'; #for Cwd

my $t = -d 't' ? 't' : 'test';

sub run_js {
    my $command = shift;
    @INC = ("$t/testlib");
    $command =~ s{^js-cpan\s+}{};
    return "JS->new->run(qw($command))";
}

sub fix_t {
    my $path = shift;
    $path =~ s/^t/$t/gm;
    return $path;
}
