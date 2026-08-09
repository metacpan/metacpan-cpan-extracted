#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Ereshkigal::LogDrek qw( log_drek );

my @openlog_got;
my @syslog_got;
my $closelog_calls = 0;
{
	no warnings 'redefine';
	*Ereshkigal::LogDrek::openlog  = sub { @openlog_got = @_; };
	*Ereshkigal::LogDrek::syslog   = sub { @syslog_got  = @_; };
	*Ereshkigal::LogDrek::closelog = sub { $closelog_calls++; };
}

# defaults
log_drek( undef, 'hello' );
is( $openlog_got[0], 'ereshkigal', 'ident defaults to ereshkigal' );
is( $openlog_got[1], 'cons,pid',   'openlog options' );
is( $openlog_got[2], 'daemon',     'openlog facility' );
is( $syslog_got[0],  'info',       'level defaults to info' );
is( $syslog_got[2],  'hello',      'message passed through' );
is( $closelog_calls, 1,            'closelog called' );

# everything specified
log_drek( 'err', 'broke', 42, 'kur-foo' );
is( $openlog_got[0], 'kur-foo',    'passed ident used' );
is( $syslog_got[0],  'err',        'passed level used' );
is( $syslog_got[2],  '42 : broke', 'tracking int prepended' );

# tracking int of 0 is still defined and should be prepended
log_drek( 'info', 'zero', 0 );
is( $syslog_got[2], '0 : zero', 'tracking int of 0 prepended' );

# undef message does not die
my $lived = eval {
	log_drek('info');
	1;
};
ok( $lived, 'undef message does not die' );
is( $syslog_got[2], '', 'undef message logged as empty string' );

# returns nothing
my @returned = log_drek( 'info', 'x' );
is_deeply( \@returned, [], 'returns an empty list' );

done_testing;
