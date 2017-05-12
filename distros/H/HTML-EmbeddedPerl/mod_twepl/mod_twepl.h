#ifndef __TWINKLE_PERL_APMOD_H__
#define __TWINKLE_PERL_APMOD_H__

  #include "httpd.h"
  #include "http_config.h"
  #include "http_core.h"
  #include "http_main.h"
  #include "http_protocol.h"
  #include "http_request.h"
  #include "http_log.h"
  #include "ap_compat.h"
  #include "ap_config.h"
  #include "apr_strings.h"
  #include "util_filter.h"
  #include "util_script.h"
  #include "mpm_common.h"

  #define __MOD_TWEPL__

  #include "twepl_parse.h"

  #pragma pack(1)

  module AP_MODULE_DECLARE_DATA twepl_module;

#endif
