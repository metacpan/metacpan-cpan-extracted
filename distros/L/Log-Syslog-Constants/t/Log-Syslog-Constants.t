use strict;
use warnings;

use Test::More tests => 59;

BEGIN { use_ok('Log::Syslog::Constants', ':all') };

# priority constants
is(LOG_EMERG,    0,  'LOG_EMERG');
is(LOG_ALERT,    1,  'LOG_ALERT');
is(LOG_CRIT,     2,  'LOG_CRIT');
is(LOG_ERR,      3,  'LOG_ERR');
is(LOG_WARNING,  4,  'LOG_WARNING');
is(LOG_NOTICE,   5,  'LOG_NOTICE');
is(LOG_INFO,     6,  'LOG_INFO');
is(LOG_DEBUG,    7,  'LOG_DEBUG');

is(LOG_KERN,     0,  'LOG_KERN');
is(LOG_USER,     1,  'LOG_USER');
is(LOG_MAIL,     2,  'LOG_MAIL');
is(LOG_DAEMON,   3,  'LOG_DAEMON');
is(LOG_AUTH,     4,  'LOG_AUTH');
is(LOG_SYSLOG,   5,  'LOG_SYSLOG');
is(LOG_LPR,      6,  'LOG_LPR');
is(LOG_NEWS,     7,  'LOG_NEWS');
is(LOG_UUCP,     8,  'LOG_UUCP');
is(LOG_CRON,     9,  'LOG_CRON');
is(LOG_AUTHPRIV, 10, 'LOG_AUTHPRIV');
is(LOG_FTP,      11, 'LOG_FTP');
is(LOG_LOCAL0,   16, 'LOG_LOCAL0');
is(LOG_LOCAL1,   17, 'LOG_LOCAL1');
is(LOG_LOCAL2,   18, 'LOG_LOCAL2');
is(LOG_LOCAL3,   19, 'LOG_LOCAL3');
is(LOG_LOCAL4,   20, 'LOG_LOCAL4');
is(LOG_LOCAL5,   21, 'LOG_LOCAL5');
is(LOG_LOCAL6,   22, 'LOG_LOCAL6');
is(LOG_LOCAL7,   23, 'LOG_LOCAL7');

# priority constants by name
is(get_severity('emerg'),    LOG_EMERG,    'named LOG_EMERG');
is(get_severity('alert'),    LOG_ALERT,    'named LOG_ALERT');
is(get_severity('crit'),     LOG_CRIT,     'named LOG_CRIT');
is(get_severity('err'),      LOG_ERR,      'named LOG_ERR');
is(get_severity('warning'),  LOG_WARNING,  'named LOG_WARNING');
is(get_severity('notice'),   LOG_NOTICE,   'named LOG_NOTICE');
is(get_severity('info'),     LOG_INFO,     'named LOG_INFO');
is(get_severity('debug'),    LOG_DEBUG,    'named LOG_DEBUG');

is(get_facility('kern'),     LOG_KERN,     'named LOG_KERN');
is(get_facility('user'),     LOG_USER,     'named LOG_USER');
is(get_facility('mail'),     LOG_MAIL,     'named LOG_MAIL');
is(get_facility('daemon'),   LOG_DAEMON,   'named LOG_DAEMON');
is(get_facility('auth'),     LOG_AUTH,     'named LOG_AUTH');
is(get_facility('syslog'),   LOG_SYSLOG,   'named LOG_SYSLOG');
is(get_facility('lpr'),      LOG_LPR,      'named LOG_LPR');
is(get_facility('news'),     LOG_NEWS,     'named LOG_NEWS');
is(get_facility('uucp'),     LOG_UUCP,     'named LOG_UUCP');
is(get_facility('cron'),     LOG_CRON,     'named LOG_CRON');
is(get_facility('authpriv'), LOG_AUTHPRIV, 'named LOG_AUTHPRIV');
is(get_facility('ftp'),      LOG_FTP,      'named LOG_FTP');
is(get_facility('local0'),   LOG_LOCAL0,   'named LOG_LOCAL0');
is(get_facility('local1'),   LOG_LOCAL1,   'named LOG_LOCAL1');
is(get_facility('local2'),   LOG_LOCAL2,   'named LOG_LOCAL2');
is(get_facility('local3'),   LOG_LOCAL3,   'named LOG_LOCAL3');
is(get_facility('local4'),   LOG_LOCAL4,   'named LOG_LOCAL4');
is(get_facility('local5'),   LOG_LOCAL5,   'named LOG_LOCAL5');
is(get_facility('local6'),   LOG_LOCAL6,   'named LOG_LOCAL6');
is(get_facility('local7'),   LOG_LOCAL7,   'named LOG_LOCAL7');

is(get_severity('WARNING'),  LOG_WARNING,  'get_severity is case insensitive');
is(get_facility('SYSLOG'),   LOG_SYSLOG,   'get_facility is case insensitive');
