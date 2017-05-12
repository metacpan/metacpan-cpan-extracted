use Test::More tests => 71;

use Mail::GcalReminder;
use Test::Exception;
use Test::Warn;

diag("Testing Mail::GcalReminder $Mail::GcalReminder::VERSION");

throws_ok {
    Mail::GcalReminder->new( gmail_pass => "this_is_a_terrible_password" );
}
qr/gmail_user/, 'gmail_user required';    # simplified regex in case Moo changes: Missing required arguments: gmail_user

throws_ok {
    Mail::GcalReminder->new( gmail_user => 'me@example.com' );
}
qr/gmail_pass/, 'gmail_pass required';    # simplified regex in case Moo changes:Missing required arguments: gmail_pass

my $gcr = Mail::GcalReminder->new( gmail_user => 'me@example.com', gmail_pass => "this_is_a_terrible_password" );

# has methods
ok( defined &Mail::GcalReminder::gmail_user, 'has gmail_user()' );
is( $gcr->gmail_user,                    'me@example.com',  'gmail_user() get' );
is( $gcr->gmail_user('you@example.com'), 'you@example.com', 'gmail_user() set' );

ok( defined &Mail::GcalReminder::gmail_pass, 'has gmail_pass()' );
is( $gcr->gmail_pass,                                     'this_is_a_terrible_password',      'gmail_pass() get' );
is( $gcr->gmail_pass('this_is_also_a_terrible_password'), 'this_is_also_a_terrible_password', 'gmail_pass() set' );

ok( defined &Mail::GcalReminder::app_name, 'has app_name()' );
is( $gcr->app_name, 'you@example.com (Mail::GcalReminder)', 'app_name get default' );
is( $gcr->app_name('my app'), 'my app', 'app_name set' );

ok( defined &Mail::GcalReminder::time_zone, 'has time_zone()' );
is( $gcr->time_zone,            'UTC',     'time_zone get default' );
is( $gcr->time_zone('CST6CDT'), 'CST6CDT', 'time_zone set' );

ok( defined &Mail::GcalReminder::include_event_dt_obj, 'has include_event_dt_obj()' );
is( $gcr->include_event_dt_obj,      '0', 'include_event_dt_obj get default' );
is( $gcr->include_event_dt_obj('1'), '1', 'include_event_dt_obj set' );

eval { $gcr->time_zone(undef) };
like( $@, qr/DateTime::TimeZone does not recognize the given name/, 'time_zone undef fatal' );
is( $gcr->time_zone, 'CST6CDT', 'time_zone (undef) still set' );

eval { $gcr->time_zone('') };
like( $@, qr/DateTime::TimeZone does not recognize the given name/, 'time_zone empty fatal' );
is( $gcr->time_zone, 'CST6CDT', 'time_zone (empty) still set' );

eval { $gcr->time_zone('Foo') };
like( $@, qr/DateTime::TimeZone does not recognize the given name/, 'time_zone invalid fatal' );
is( $gcr->time_zone, 'CST6CDT', 'time_zone (invalid) still set' );

ok( defined &Mail::GcalReminder::cc_self, 'has cc_self()' );
is( $gcr->cc_self,    1, 'cc_self get default' );
is( $gcr->cc_self(0), 0, 'cc_self set' );

ok( defined &Mail::GcalReminder::try_receipts, 'has try_receipts()' );
is( $gcr->try_receipts,    1, 'try_receipts get default' );
is( $gcr->try_receipts(0), 0, 'try_receipts set' );

ok( defined &Mail::GcalReminder::try_priority, 'has try_priority()' );
is( $gcr->try_priority,    1, 'try_priority get default' );
is( $gcr->try_priority(0), 0, 'try_priority set' );

ok( defined &Mail::GcalReminder::no_guests_is_ok, 'has no_guests_is_ok()' );
is( $gcr->no_guests_is_ok,    1, 'no_guests_is_ok get default' );
is( $gcr->no_guests_is_ok(0), 0, 'no_guests_is_ok set' );

ok( defined &Mail::GcalReminder::base_date, 'has base_date()' );
is( ref( $gcr->base_date ), 'DateTime', 'base_date get default' );
require DateTime;    # should already be loaded via base_date()
my $base = DateTime->now();
is( $gcr->base_date($base), $base, 'base_date set valid' );
throws_ok { $gcr->base_date('whatever') } qr/only DateTime objects are supported/, 'base_date set invalid';

ok( defined &Mail::GcalReminder::no_guests_is_ok, 'has no_guests_is_ok()' );
is( $gcr->essg_hax_ver,       0.88, 'essg_hax_ver get default' );
is( $gcr->essg_hax_ver(0.42), 0.42, 'essg_hax_ver set' );

ok( defined &Mail::GcalReminder::warning,      'sub  warning()' );
ok( defined &Mail::GcalReminder::warning_code, 'has warning_code' );

my $code = $gcr->warning_code;
is( ref($code), 'CODE', 'warning_code get default' );
warnings_like {
    $gcr->warning("booo");
}
qr/booo at \Q$0\E line @{[ __LINE__-2]}/, 'warnings() directly has caller at-line';
warnings_like {
    $gcr->warning("fooo\n");
}
qr/fooo$/, 'warnings() directly w/ \n no at-line';
is( $gcr->warning_code, $code, "string does not reset def coderef" );

my $warn;
my $new_code = $gcr->warning_code( sub { shift; $warn = shift; } );
isnt( $new_code, $code, 'warning_code coderef set' );
$gcr->warning("string");
is( $warn,              "string",  "string calls coderef" );
is( $gcr->warning_code, $new_code, "string does not reset coderef" );

ok( defined &Mail::GcalReminder::date_format_obj, 'has date_format_obj()' );
warning_like {
    is( ref( $gcr->date_format_obj ), 'DateTime::Format::ISO8601', 'date_format_obj get default' );
}
qr/date_format_obj\(\) is deprecated/, 'date_format_obj() warns about deprecation';
throws_ok { $gcr->date_format_obj('boo') } qr//, 'date_format_obj set';

ok( defined &Mail::GcalReminder::signature, 'has signature()' );
my $sig = q{

--
my app

Note: Please ensure mail from “you@example.com” is not being filtered out of your inbox.};

is( $gcr->signature,           $sig,     'signature get default' );
is( $gcr->signature('my sig'), 'my sig', 'signature set' );

ok( defined &Mail::GcalReminder::debug, 'has debug()' );
is( $gcr->debug,    0, 'debug get default' );
is( $gcr->debug(1), 1, 'debug set' );

ok( defined &Mail::GcalReminder::gcal_cache, 'has gcal_cache()' );
is_deeply( $gcr->gcal_cache, {}, 'gcal_cache get default' );
my %x = ( 'foo' => {} );
is_deeply( $gcr->gcal_cache( \%x ), \%x, 'gcal_cache set' );

# builder methods
ok( defined &Mail::GcalReminder::_build_app_name, 'builder _build_app_name()' );
is( $gcr->_build_app_name(), 'you@example.com (Mail::GcalReminder)', '_build_app_name RV' );

ok( defined &Mail::GcalReminder::_build_signature, 'builder _build_signature()' );
is( $gcr->_build_signature(), $sig, '_build_signature RV' );

# object methods
ok( defined &Mail::GcalReminder::get_gcal,       'sub get_gcal()' );
ok( defined &Mail::GcalReminder::send_reminders, 'sub send_reminders()' );
ok( defined &Mail::GcalReminder::send_gmail,     'sub send_gmail()' );
