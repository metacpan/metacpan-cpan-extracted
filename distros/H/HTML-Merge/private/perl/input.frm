Direcotries||S||
Template path|TEMPLATE_PATH|D||@CGI_BIN@/template
Cache path|CACHE_PATH|D||@CGI_BIN@/cache
Precompiled template path|PRECOMPILED_PATH|D||@CGI_BIN@/pl
Default template|DEF_TEMPLATE|T||@DEF_TEMPLATE@
Merge path|MERGE_PATH|T||@URL@
Merge absolute path|MERGE_ABSOLUTE_PATH|D|W|@CGI_BIN@
Support site|SUPPORT_SITE|T||http://www.raz.co.il
Development||S||
Development|DEVELOPMENT|B||1
Development extension|DEV_EXTENSION|T||html, htm
Logs||S||
Debug|DEBUG|C|ERROR,WARN,INFO|ERROR,INFO
Log path|MERGE_ERROR_LOG_PATH|T||logs
Error message|ERROR_MESSAGE|T||
Log list size|LOG_LIST_SIZE|T||20
Stop on error|STOP_ON_ERROR|B||1
Check ranges of values|VALUE_CHECKING|B||0
Database||S||
Database type|DB_TYPE|X|DBI|@DRIVER@
Database name|DB_DATABASE|X|DB|@DB@
Database host|DB_HOST|T||
Database port|DB_PORT|T||
Database username|DB_USER|T||@DB_USER@
Database password|DB_PASSWORD|P||
Auto commit|AUTO_COMMIT|B||1
Session and security||S||
Session and security database|SESSION_DB|X|DB|@MERGE_DB@
Session timeout|SESSION_TIMEOUT|T||60
Session timeout template|SESSION_TIME_OUT_TEMPLATE|T||
Session method|SESSION_METHOD|L|C:Cookies,I:IP Tracking,U:URL Filter|C
Session cookie|SESSION_COOKIE|T||RZCKMRGSSN
Sticky session cookie|STICKY_COOKIE|B||0
Use security|USE_SECURITY|B||0
Access denied template|SECURITY_ACCESS_DENIED_TEMPLATE|T||
Root user|ROOT_USER|H||@ROOT_USER@
Root password|ROOT_PASSWORD|H||@ROOT_PASSWORD@
Allow easy passwords|ALLOW_EASY_PASSWORDS|B||1
Network||S||
LWP present|WEB|B||1
Mail server|SMTP_SERVER|T||127.0.0.1
Internal||S||
Always compile pages|ALWAYS_COMPILE|B||0
Content Type|CONTENT_TYPE|T||
Thousand seperator|THOUSAND_SEPARATOR|O||,
Decimal separator|DECIMAL_SEPARATOR|O||.
