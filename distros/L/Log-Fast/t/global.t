use warnings;
use strict;
use Test::More;

use Log::Fast;


plan tests => 4;


my $LOG = Log::Fast->global();
like ref $LOG, qr/\ALog::Fast::_\d+\z/,             'global created';
is $LOG, Log::Fast->global(),                       'global is same';
like ref Log::Fast->new(), qr/\ALog::Fast::_\d+\z/, 'local created';
isnt $LOG, Log::Fast->new(),                        'global differ from local';

