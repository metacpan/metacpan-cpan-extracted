#undef SEPARATOR
#ifdef WIN32
#define SEPARATOR ";"
#else
#define SEPARATOR ":;"
#endif



#ifdef EPCFG_COMPONENT
/* tComponentConfig */

EPCFG_STR (ComponentConfig,     char *,      sPackage,      PACKAGE) 
EPCFG_INTOPT (ComponentConfig,     unsigned,    bDebug,        DEBUG) 
EPCFG_INTOPT (ComponentConfig,     unsigned,    bOptions,      OPTIONS) 
EPCFG_INTOPT (ComponentConfig,     int   ,      nEscMode,      ESCMODE) 
EPCFG_INTOPT (ComponentConfig,     int   ,      nInputEscMode, INPUT_ESCMODE) 
EPCFG_STR (ComponentConfig,     char *,      sInputCharset, INPUT_CHARSET) 
EPCFG_STR (ComponentConfig,     char *,      sCacheKey,     CACHE_KEY) 
EPCFG_INT (ComponentConfig,     unsigned,    bCacheKeyOptions, CACHE_KEY_OPTIONS)
EPCFG_CV  (ComponentConfig,     CV *  ,      pExpiredFunc,  EXPIRES_FUNC) 
EPCFG_CV  (ComponentConfig,     CV *  ,      pCacheKeyFunc, CACHE_KEY_FUNC)
EPCFG_INT (ComponentConfig,     int   ,      nExpiresIn,    EXPIRES_IN) 
EPCFG_STR (ComponentConfig,     char *,      sExpiresFilename, EXPIRES_FILENAME) 
EPCFG_STR (ComponentConfig,     char *,      sSyntax,       SYNTAX) 
EPCFG_SV  (ComponentConfig,     SV *,        pRecipe,       RECIPE) 
EPCFG_STR (ComponentConfig,     char *,      sXsltstylesheet, XSLTSTYLESHEET) 
EPCFG_STR (ComponentConfig,     char *,      sXsltproc,     XSLTPROC) 
EPCFG_STR (ComponentConfig,     char *,      sCompartment,  COMPARTMENT)
EPCFG_STR (ComponentConfig,     char *,      sTopInclude,  TOP_INCLUDE)
#endif

#ifdef EPCFG_REQ
/* tReqConfig */

EPCFG_REGEX(ReqConfig,     CV *,      pAllow,         ALLOW) 
EPCFG_REGEX(ReqConfig,     CV *,      pUriMatch,      URIMATCH) 
EPCFG_CHAR(ReqConfig,     char  ,     cMultFieldSep, MULTFIELDSEP ) 
EPCFG_AV  (ReqConfig,     AV *,       pPathAV,         PATH, SEPARATOR) 
EPCFG_INTOPT (ReqConfig,     unsigned,    bDebug,        DEBUG) 
EPCFG_INTOPT (ReqConfig,     unsigned,    bOptions,      OPTIONS) 
EPCFG_INTOPT (ReqConfig,     int   ,  nSessionMode,     SESSION_MODE) 
EPCFG_INTOPT (ReqConfig,     int   ,      nOutputMode,   OUTPUT_MODE) 
EPCFG_INTOPT (ReqConfig,     int   ,      nOutputEscCharset,   OUTPUT_ESC_CHARSET) 
#endif


#ifdef EPCFG_APP
/* tAppConfig */

EPCFG_STR(AppConfig,     char *,  sAppName,         APPNAME) 
EPCFG_STR(AppConfig,     char *,  sAppHandlerClass,     APP_HANDLER_CLASS)
EPCFG_STR(AppConfig,     char *,  sSessionHandlerClass, SESSION_HANDLER_CLASS)
EPCFG_HV (AppConfig,     HV *,    pSessionArgs,     SESSION_ARGS) 
EPCFG_AV (AppConfig,     AV *,    pSessionClasses,  SESSION_CLASSES, " ,")
EPCFG_STR(AppConfig,     char *,  sSessionConfig,   SESSION_CONFIG) 
EPCFG_STR(AppConfig,     char *,  sCookieName,      COOKIE_NAME) 
EPCFG_STR(AppConfig,     char *,  sCookieDomain,    COOKIE_DOMAIN)
EPCFG_STR(AppConfig,     char *,  sCookiePath,      COOKIE_PATH) 
EPCFG_EXPIRES(AppConfig,     char *,  sCookieExpires,   COOKIE_EXPIRES) 
EPCFG_BOOL(AppConfig,     bool,    bCookieSecure,    COOKIE_SECURE) 
EPCFG_STR(AppConfig,     char *,  sLog,             LOG) 
EPCFG_INTOPT(AppConfig,     unsigned,bDebug,           DEBUG) 
EPCFG_BOOL(AppConfig,     bool,    bMaildebug,       MAILDEBUG) 
EPCFG_STR(AppConfig,     char *,  sMailhost,        MAILHOST) 
EPCFG_STR(AppConfig,     char *,  sMailhelo,        MAILHELO) 
EPCFG_STR(AppConfig,     char *,  sMailfrom,        MAILFROM) 
EPCFG_STR(AppConfig,     char *,  sMailErrorsTo,    MAIL_ERRORS_TO) 
EPCFG_INT(AppConfig,     int,     nMailErrorsLimit,    MAIL_ERRORS_LIMIT) 
EPCFG_INT(AppConfig,     int,     nMailErrorsResetTime,    MAIL_ERRORS_RESET_TIME) 
EPCFG_INT(AppConfig,     int,     nMailErrorsResendTime,    MAIL_ERRORS_RESEND_TIME) 
EPCFG_STR(AppConfig,     char *,  sObjectBase,      OBJECT_BASE)
EPCFG_STR(AppConfig,     char *,  sObjectApp,       OBJECT_APP)
EPCFG_AV (AppConfig,     AV *,    pObjectAddpathAV, OBJECT_ADDPATH, SEPARATOR)
EPCFG_AV (AppConfig,     AV *,    pObjectReqpathAV, OBJECT_REQPATH, SEPARATOR)
EPCFG_STR(AppConfig,     char *,  sObjectStopdir,   OBJECT_STOPDIR)
EPCFG_STR(AppConfig,     char *,  sObjectFallback,  OBJECT_FALLBACK)
EPCFG_STR(AppConfig,     char *,  sObjectHandlerClass, OBJECT_HANDLER_CLASS)

#endif



