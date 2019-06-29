use strict;
use Test::More 0.98;
use Test::Mock::Guard qw(mock_guard);

use Devel::KYTProf;
use AWS::CLIWrapper;

local $ENV{ANSI_COLORS_DISABLED} = 1;

my $aws_cli = AWS::CLIWrapper->new;
my $g = mock_guard 'AWS::CLIWrapper' => { _execute => sub { 1 } };

Devel::KYTProf->apply_prof('AWS::CLIWrapper');

my $buffer = '';
open my $fh, '>', \$buffer or die "Could not open in-memory buffer";
*STDERR = $fh;

$aws_cli->s3('list-geo-locations');

like $buffer, qr/\[AWS::CLIWrapper\]  s3 list-geo-locations  \|/;

close $fh;

done_testing;
