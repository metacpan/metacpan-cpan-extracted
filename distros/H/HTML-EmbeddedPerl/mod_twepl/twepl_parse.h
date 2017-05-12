#ifndef __TWEPL_PARSE_H__
#define __TWEPL_PARSE_H__

  #define PERLIO_NOT_STDIO 0
  #define USE_PERLIO

  #include "EXTERN.h"
  #include "perl.h"
  #include "perliol.h"
  #include "XSUB.h"
  #include "ppport.h"

  #ifdef _MSC_VER
    #include <windows.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #define strcasecmp _stricmp
    #define strncasecmp _strnicmp
  #endif

  #pragma pack(1)

  #ifndef TRUE
    #define TRUE  1
  #endif
  #ifndef FALSE
    #define FALSE 0
  #endif

  #define EPL_XS_FLAG_RES 2
  #define EPL_XS_FLAG_DEL 2

  #define EPL_MK_VAR_FLAG GV_ADD|GV_ADDMULTI

  #define EPL_CRLF "\x0d\x0a\0"

  #define HEAD_DM ": \0"

  #define HTML_PS "print \"\0"
  #define HTML_PE "\";\0"
  #define HTML_LA 9
  #define HTML_LS 7
  #define HTML_LE 2

  typedef struct{
    int ParserFlag;
    int SendLength;
    int MyApplePie;
  } TWEPL_CONFIG, *PTWEPL_CONFIG;

  enum TWEPL_STATE{
    TWEPL_OKEY_NOERR,
    TWEPL_FAIL_FOPEN,
    TWEPL_FAIL_FSEEK,
    TWEPL_FAIL_FTELL,
    TWEPL_FAIL_FREAD,
    TWEPL_FAIL_SLENG,
    TWEPL_FAIL_MALOC,
    TWEPL_FAIL_TAGOP,
    TWEPL_FAIL_TAGED
  };

  const char *TWEPL_ERROR_STRING[] = {
    "complete parsing with no error. okey XD\0",
    "encountered error at fopen().\0",
    "encountered error at fseek().\0",
    "encountered error at ftell().\0",
    "encountered error at fread().\0",
    "encountered error at strlen()\0",
    "encountered error at malloc(). failure in malloc.\0",
    "could not starting parse twepl opening tag. failure in somewhere.\0",
    "could not find twepl end tag. please check in the twepl code.\0",
    NULL
  };

  static PerlInterpreter *tweps;

  #define EPL_XS_NAME "twepl"
  #define EPL_PM_NAME "HTML::EmbeddedPerl"

  #define EPL_VV_NAME "main::ep\0"
  #define EPL_VERSION "0.91"

  #define OPT_TAG_NON 0x0000
  #define OPT_TAG_EPL 0x0001
  #define OPT_TAG_DOL 0x0010
  #define OPT_TAG_PHP 0x0100
  #define OPT_TAG_ASP 0x1000
  #define OPT_TAG_ALL 0x1111

  /* Plan 1 - Option */
  #define EPL_TAG_DEF "&\0"
  #define EPL_TAG_EPL ":\0"
  #define EPL_TAG_DOL "$\0"
  #define EPL_TAG_PHP "?\0"
  #define EPL_TAG_ASP "%\0"

  /* Plan 2 - All */
  #define EPL_TAG_ALL "|:$?%\0"

  #define is_EPL(f) (f & OPT_TAG_EPL)
  #define is_DOL(f) (f & OPT_TAG_DOL)
  #define is_PHP(f) (f & OPT_TAG_PHP)
  #define is_ASP(f) (f & OPT_TAG_ASP)

  #define EPL_FIM "+<:scalar\0"
  #define EPL_FOM "+<:scalar\0"

  #define EPL_FIF O_RDWR
  #define EPL_FOF O_RDWR

  #define EPL_CONTYPE "text/html\0"
  #define EPL_POW_KEY "X-Powered-By\0"
  #define EPL_POW_VAL EPL_XS_NAME "/" EPL_VERSION "\0"

  #define EPL_CRIGHTS \
    "Copyright (C)2013 Twinkle Computing All rights reserved.\n" \
    "\n" \
    "Report bugs to <twepl@twinkle.tk>\n\0"

  #define EPC_APPNAME "twepc"
  #define EPP_APPNAME "twepl"

  #define EPL_EMBP "       .-. .  . .-. .-. .-. .-. .-. .-.   .-. .-. .-. .      \n" \
                   "       |-  |\/| |(  |-  |  )|  )|-  |  )  |-' |-  |(  |      \n" \
                   "       `-' '  ` `-' `-' `-' `-' `-' `-'   '   `-' ' ' `-'    \0"

  #define EPL_FAPS "                          for Apache2                        \0"

  #define EPL_LOGO "          ,----,                                      ,--,   \n" \
                   "        ,/   .`|                        ,-.----.   ,---.'|   \n" \
                   "      ,`   .'  :         .---.    ,---,.|    /  `  |   | :   \n" \
                   "    ;    ;     /        /. ./|  ,'  .' ||   :    ` :   : |   \n" \
                   "  .'___,/    ,'     .--'.  ' ;,---.'   ||   |  .` :|   ' :   \n" \
                   "  |    :     |     /__./ ` : ||   |   .'.   :  |: |;   ; '   \n" \
                   "  ;    |.';  ; .--'.  '   `' .:   :  |-,|   |   ` :'   | |__ \n" \
                   "  `----'  |  |/___/ ` |    ' ':   |  ;/||   : .   /|   | :.'|\n" \
                   "      '   :  ;;   `  `;      :|   :   .';   | |`-' '   :    ;\n" \
                   "      |   |  ' `   ;  `      ||   |  |-,|   | ;    |   |  ./ \n" \
                   "      '   :  |  .   `    .`  ;'   :  ;/|:   ' |    ;   : ;   \n" \
                   "      ;   |.'    `   `   ' ` ||   |    |:   : :    |   ,/    \n" \
                   "      '---'       :   '  |--' |   :   .'|   | :    '---'     \n" \
                   "                   `   ` ;    |   | ,'  `---'.|              \n" \
                   "                    '---'     `----'      `---`              \0"


  #define EPC_OPTIONS \
    EPC_APPNAME " [OPTION(FEATURE)S] file\n\n" \
    "  [OPTIONS]\n" \
    "    -o    output filename, default is stdout.\n\n\0"

  #define EPC_VERSION \
    EPC_APPNAME " (twinkle-utils) " EPL_VERSION "\n" \
    "\n" EPL_CRIGHTS

  #define EPP_OPTIONS \
    EPP_APPNAME " [OPTION(FEATURE)S] file\n\n" \
    "  [OPTIONS]\n" \
    "    -c    convert-mode: output converted code.\n" \
    "    -o    output filename, default is stdout.\n\n\0"

  #define EPP_VERSION \
    EPP_APPNAME " (twinkle-utils) " EPL_VERSION "\n" \
    "\n" EPL_CRIGHTS

  char strnchr(char src, char *cmp);
  long twepl_serach_optag(char *src, long ssz, long idx, char *tmc, char *fmc);
  long twepl_serach_edtag(char *src, long ssz, long idx, char *emc);
  int twepl_optagstr_skip(char *src, int idx);
  long count_quote(char *src, long stp, long edp);
  enum TWEPL_STATE twepl_lint(char *src, long ssz, long *nsz, int opf);
  int twepl_quote(char *src, char *cnv, long stp, long edp);
  enum TWEPL_STATE twepl_parse(char *src, char *cnv, long ssz, int opf);

  enum TWEPL_STATE twepl_file(char *flp, char **cnv, int opf);
  enum TWEPL_STATE twepl_code(char *src, char **cnv, int opf);

  const char *twepl_strerr(enum TWEPL_STATE state);

#endif
