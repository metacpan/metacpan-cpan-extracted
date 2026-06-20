#!/usr/bin/perl

package ErrorTester;
use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Warn;
use Test::More tests => 13;

my $error_module = 'Graphics::Toolkit::Color::Error';
my $main_module = 'Graphics::Toolkit::Color';
my $eval = eval "require $error_module";
is( not($@), 1, "could load the module $error_module"); # say $@;
$eval = eval "require $main_module";
is( not($@), 1, "could load the module $main_module"); # say $@;
Graphics::Toolkit::Color::Error->import('error');
warning_like {error('nachricht 1')}     {carped => qr/nachricht 1/}, 'could import "error" routine and "carp" is default mode';
Graphics::Toolkit::Color->import();
warning_like {error('nachricht 2')}     {carped => qr/nachricht 2/}, '"carp" is also GTC default error mode';
Graphics::Toolkit::Color->import('error', 'carp');
warning_like {error('nachricht 3')}     {carped => qr/nachricht 3/}, 'selected "carp" mode';
warning_like {routine('nachricht 4')}   {carped => qr/ErrorTester::routine:/}, 'error called by an routine';
{
    local $SIG{__WARN__} = sub {};   # verschluckt alle Warnungen in diesem Block
    eval { routine('nachricht 5') };
}
is( $@,         '',   'carp does not call exception');

Graphics::Toolkit::Color->import( 'error', 'croak');
eval { error('nachricht 6') };
like( $@,         qr/nachricht 6/, 'select "croak" mode');

Graphics::Toolkit::Color->import( 'error', 'die');
eval { error('nachricht 7') };
like( $@,         qr/nachricht 7/, 'select "die" mode');

Graphics::Toolkit::Color->import( 'error', 'say');
my ($output);
{
    local $SIG{__WARN__} = sub {};   # verschluckt alle Warnungen in diesem Block
    local *STDOUT;
    open STDOUT, '>', \$output;
    eval { routine('nachricht 8') };
}
like( $output, qr/nachricht 8/, 'select "say" mode');
is( $@,                     '', '"say" mode does not call exception');

Graphics::Toolkit::Color->import('error', 'quiet');
my ($output2);
{
    local $SIG{__WARN__} = sub {};   # verschluckt alle Warnungen in diesem Block
    local *STDOUT;
    open STDOUT, '>', \$output2;
    eval { routine('nachricht 9') };
}
is( $output2, undef, 'select "quiet" mode');
is( $@,          '', '"quiet" mode does not call exception');


sub routine { error($_[0]) }

exit 0;
 
