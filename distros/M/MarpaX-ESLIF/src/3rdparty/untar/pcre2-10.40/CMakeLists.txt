CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("../../../3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()

#
# Policies common to all our files
#
FOREACH (_policy CMP0018 CMP0063 CMP0075)
  IF (POLICY ${_policy})
    CMAKE_POLICY (SET ${_policy} NEW)
  ENDIF ()
ENDFOREACH ()

MYPACKAGESTART (pcre2 10 40 0)

IF (FIXME_CMAKE_ABSOLUTE)
  INCLUDE(${FIXME_CMAKE_ABSOLUTE})
ENDIF ()

INCLUDE(CheckIncludeFile)
CHECK_INCLUDE_FILE(dirent.h     HAVE_DIRENT_H)
CHECK_INCLUDE_FILE(stdint.h     HAVE_STDINT_H)
CHECK_INCLUDE_FILE(inttypes.h   HAVE_INTTYPES_H)
CHECK_INCLUDE_FILE(sys/stat.h   HAVE_SYS_STAT_H)
CHECK_INCLUDE_FILE(sys/types.h  HAVE_SYS_TYPES_H)
CHECK_INCLUDE_FILE(unistd.h     HAVE_UNISTD_H)
CHECK_INCLUDE_FILE(windows.h    HAVE_WINDOWS_H)

INCLUDE(CheckSymbolExists)
CHECK_SYMBOL_EXISTS(bcopy         "strings.h"  HAVE_BCOPY)
CHECK_SYMBOL_EXISTS(memfd_create  "sys/mman.h" HAVE_MEMFD_CREATE) # Needs _GNU_SOURCE
CHECK_SYMBOL_EXISTS(memmove       "string.h"   HAVE_MEMMOVE)
CHECK_SYMBOL_EXISTS(secure_getenv "stdlib.h"   HAVE_SECURE_GETENV) # Needs _GNU_SOURCE
CHECK_SYMBOL_EXISTS(strerror      "string.h"   HAVE_STRERROR)

INCLUDE(CheckCSourceCompiles)
CHECK_C_SOURCE_COMPILES(
  "#include <stdlib.h>
   #include <limits.h>
   int main(int c, char *v[]) { char buf[PATH_MAX]; realpath(v[1], buf); return 0; }"
  HAVE_REALPATH
)

SET(ORIG_CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS})
SET(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} -Werror")
CHECK_C_SOURCE_COMPILES(
  "int main() { char buf[128] __attribute__((uninitialized)); (void)buf; return 0; }"
  HAVE_ATTRIBUTE_UNINITIALIZED
)
SET(CMAKE_REQUIRED_FLAGS ${ORIG_CMAKE_REQUIRED_FLAGS})

# Check whether Intel CET is enabled, and if so, adjust compiler flags. This
# code was written by PH, trying to imitate the logic from the autotools
# configuration.

CHECK_C_SOURCE_COMPILES(
  "#ifndef __CET__
   #error CET is not enabled
   #endif
   int main() { return 0; }"
  INTEL_CET_ENABLED
)

IF (INTEL_CET_ENABLED)
  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mshstk")
ENDIF(INTEL_CET_ENABLED)

OPTION(PCRE2_BUILD_PCRE2_8 "Build 8 bit PCRE2 library" ON)
OPTION(PCRE2_BUILD_PCRE2_16 "Build 16 bit PCRE2 library" OFF)
OPTION(PCRE2_BUILD_PCRE2_32 "Build 32 bit PCRE2 library" OFF)
OPTION(PCRE2_DEBUG "Include debugging code" OFF)
OPTION(PCRE2_DISABLE_PERCENT_ZT "Disable the use of %zu and %td (rarely needed)" ON)
SET(PCRE2_EBCDIC ${EBCDIC} CACHE BOOL "Use EBCDIC coding instead of ASCII. (This is rarely used outside of mainframe systems.)")
SET(PCRE2_EBCDIC_NL25 OFF CACHE BOOL "Use 0x25 as EBCDIC NL character instead of 0x15; implies EBCDIC.")
SET(PCRE2_LINK_SIZE "2" CACHE STRING "Internal link size (2, 3 or 4 allowed). See LINK_SIZE in config.h.in for details.")
SET(PCRE2_PARENS_NEST_LIMIT "250" CACHE STRING "Default nested parentheses limit. See PARENS_NEST_LIMIT in config.h.in for details.")
SET(PCRE2_HEAP_LIMIT "20000000" CACHE STRING "Default limit on heap memory (kibibytes). See HEAP_LIMIT in config.h.in for details.")
SET(PCRE2_MATCH_LIMIT "10000000" CACHE STRING "Default limit on internal looping. See MATCH_LIMIT in config.h.in for details.")
SET(PCRE2_MATCH_LIMIT_DEPTH "MATCH_LIMIT" CACHE STRING "Default limit on internal depth of search. See MATCH_LIMIT_DEPTH in config.h.in for details.")
SET(PCRE2GREP_BUFSIZE "20480" CACHE STRING "Buffer starting size parameter for pcre2grep. See PCRE2GREP_BUFSIZE in config.h.in for details.")
SET(PCRE2GREP_MAX_BUFSIZE "1048576" CACHE STRING "Buffer maximum size parameter for pcre2grep. See PCRE2GREP_MAX_BUFSIZE in config.h.in for details.")
SET(PCRE2_NEWLINE "LF" CACHE STRING "What to recognize as a newline (one of CR, LF, CRLF, ANY, ANYCRLF, NUL).")
SET(PCRE2_HEAP_MATCH_RECURSE OFF CACHE BOOL "Obsolete option: do not use")
SET(PCRE2_SUPPORT_JIT ON CACHE BOOL "Enable support for Just-in-time compiling.")
IF (${CMAKE_SYSTEM_NAME} MATCHES Linux|NetBSD)
  SET(PCRE2_SUPPORT_JIT_SEALLOC OFF CACHE BOOL "Enable SELinux compatible execmem allocator in JIT (experimental).")
ELSE (${CMAKE_SYSTEM_NAME} MATCHES Linux|NetBSD)
  SET(PCRE2_SUPPORT_JIT_SEALLOC IGNORE)
ENDIF (${CMAKE_SYSTEM_NAME} MATCHES Linux|NetBSD)
SET(PCRE2GREP_SUPPORT_JIT ON CACHE BOOL "Enable use of Just-in-time compiling in pcre2grep.")
SET(PCRE2GREP_SUPPORT_CALLOUT ON CACHE BOOL "Enable callout string support in pcre2grep.")
SET(PCRE2GREP_SUPPORT_CALLOUT_FORK ON CACHE BOOL "Enable callout string fork support in pcre2grep.")
SET(PCRE2_SUPPORT_UNICODE ON CACHE BOOL "Enable support for Unicode and UTF-8/UTF-16/UTF-32 encoding.")
SET(PCRE2_SUPPORT_BSR_ANYCRLF OFF CACHE BOOL "ON=Backslash-R matches only LF CR and CRLF, OFF=Backslash-R matches all Unicode Linebreaks")
SET(PCRE2_NEVER_BACKSLASH_C OFF CACHE BOOL "If ON, backslash-C (upper case C) is locked out.")
SET(PCRE2_SUPPORT_VALGRIND OFF CACHE BOOL "Enable Valgrind support.")

OPTION(PCRE2_SHOW_REPORT     "Show the final configuration report" ON)
OPTION(PCRE2_BUILD_PCRE2GREP "Build pcre2grep" ON)
OPTION(PCRE2_BUILD_TESTS     "Build the tests" ON)

IF(PCRE2_BUILD_PCRE2_8)
        SET(SUPPORT_PCRE2_8 1)
ENDIF(PCRE2_BUILD_PCRE2_8)

IF(PCRE2_BUILD_PCRE2_16)
        SET(SUPPORT_PCRE2_16 1)
ENDIF(PCRE2_BUILD_PCRE2_16)

IF(PCRE2_BUILD_PCRE2_32)
        SET(SUPPORT_PCRE2_32 1)
ENDIF(PCRE2_BUILD_PCRE2_32)

IF(PCRE2_NEVER_BACKSLASH_C)
        SET(NEVER_BACKSLASH_C 1)
ENDIF(PCRE2_NEVER_BACKSLASH_C)

IF(PCRE2_SUPPORT_UNICODE)
        SET(SUPPORT_UNICODE 1)
ENDIF(PCRE2_SUPPORT_UNICODE)

IF(PCRE2_SUPPORT_JIT)
        SET(SUPPORT_JIT 1)
ENDIF(PCRE2_SUPPORT_JIT)

IF(PCRE2_SUPPORT_JIT_SEALLOC)
  SET(CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE)
  CHECK_SYMBOL_EXISTS(mkostemp stdlib.h REQUIRED)
  UNSET(CMAKE_REQUIRED_DEFINITIONS)
  IF(${REQUIRED})
    IF(${CMAKE_SYSTEM_NAME} MATCHES Linux|NetBSD)
      ADD_DEFINITIONS(-D_GNU_SOURCE)
      SET(SLJIT_PROT_EXECUTABLE_ALLOCATOR 1)
    ELSE(${CMAKE_SYSTEM_NAME} MATCHES Linux|NetBSD)
      MESSAGE(FATAL_ERROR "Your configuration is not supported")
    ENDIF(${CMAKE_SYSTEM_NAME} MATCHES Linux|NetBSD)
  ELSE(${REQUIRED})
    SET(PCRE2_SUPPORT_JIT_SEALLOC OFF)
  ENDIF(${REQUIRED})
ENDIF(PCRE2_SUPPORT_JIT_SEALLOC)

IF(PCRE2_DISABLE_PERCENT_ZT)
        SET(DISABLE_PERCENT_ZT 1)
ENDIF(PCRE2_DISABLE_PERCENT_ZT)

SET(NEWLINE_DEFAULT "")
IF(PCRE2_NEWLINE STREQUAL "CR")
        SET(NEWLINE_DEFAULT "1")
ENDIF(PCRE2_NEWLINE STREQUAL "CR")
IF(PCRE2_NEWLINE STREQUAL "LF")
        SET(NEWLINE_DEFAULT "2")
ENDIF(PCRE2_NEWLINE STREQUAL "LF")
IF(PCRE2_NEWLINE STREQUAL "CRLF")
        SET(NEWLINE_DEFAULT "3")
ENDIF(PCRE2_NEWLINE STREQUAL "CRLF")
IF(PCRE2_NEWLINE STREQUAL "ANY")
        SET(NEWLINE_DEFAULT "4")
ENDIF(PCRE2_NEWLINE STREQUAL "ANY")
IF(PCRE2_NEWLINE STREQUAL "ANYCRLF")
        SET(NEWLINE_DEFAULT "5")
ENDIF(PCRE2_NEWLINE STREQUAL "ANYCRLF")
IF(PCRE2_NEWLINE STREQUAL "NUL")
        SET(NEWLINE_DEFAULT "6")
ENDIF(PCRE2_NEWLINE STREQUAL "NUL")

IF(NEWLINE_DEFAULT STREQUAL "")
        MESSAGE(FATAL_ERROR "The PCRE2_NEWLINE variable must be set to one of the following values: \"LF\", \"CR\", \"CRLF\", \"ANY\", \"ANYCRLF\".")
ENDIF(NEWLINE_DEFAULT STREQUAL "")

IF(PCRE2_EBCDIC)
        SET(EBCDIC 1)
ENDIF(PCRE2_EBCDIC)

IF(PCRE2_EBCDIC_NL25)
        SET(EBCDIC 1)
        SET(EBCDIC_NL25 1)
ENDIF(PCRE2_EBCDIC_NL25)

IF(PCRE2_SUPPORT_VALGRIND)
        SET(SUPPORT_VALGRIND 1)
ENDIF(PCRE2_SUPPORT_VALGRIND)

# Parse version numbers and date out of configure.ac

file(STRINGS ${PROJECT_SOURCE_DIR}/configure.ac
  configure_lines
  LIMIT_COUNT 50 # Read only the first 50 lines of the file
)

set(SEARCHED_VARIABLES "pcre2_major" "pcre2_minor" "pcre2_prerelease" "pcre2_date")
foreach(configure_line ${configure_lines})
    foreach(_substitution_variable ${SEARCHED_VARIABLES})
        string(TOUPPER ${_substitution_variable} _substitution_variable_upper)
        if (NOT ${_substitution_variable_upper})
            string(REGEX MATCH "m4_define\\(${_substitution_variable}, \\[(.*)\\]" MATCHED_STRING ${configure_line})
            if (CMAKE_MATCH_1)
                set(${_substitution_variable_upper} ${CMAKE_MATCH_1})
            endif()
        endif()
    endforeach()
endforeach()

CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/src/pcre2.h.in
  ${INCLUDE_OUTPUT_PATH}/pcre2.h
  @ONLY)

# Character table generation

OPTION(PCRE2_REBUILD_CHARTABLES "Rebuild char tables" OFF)
IF(PCRE2_REBUILD_CHARTABLES)
  ADD_EXECUTABLE(pcre2_dftables src/pcre2_dftables.c)
  ADD_CUSTOM_COMMAND(
    COMMENT "Generating character tables (pcre2_chartables.c) for current locale"
    DEPENDS pcre2_dftables
    COMMAND pcre2_dftables
    ARGS        ${CMAKE_CURRENT_BINARY_DIR}/pcre2_chartables.c
    OUTPUT      ${CMAKE_CURRENT_BINARY_DIR}/pcre2_chartables.c
  )
ELSE(PCRE2_REBUILD_CHARTABLES)
  CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/src/pcre2_chartables.c.dist
                    ${CMAKE_CURRENT_BINARY_DIR}/pcre2_chartables.c
                    COPYONLY)
ENDIF(PCRE2_REBUILD_CHARTABLES)

# Source code

SET(PCRE2_HEADERS ${INCLUDE_OUTPUT_PATH}/pcre2.h)

MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/config-cmake.h.in
  ${INCLUDE_OUTPUT_PATH}/config.h
  src/pcre2_auto_possess.c
  ${CMAKE_CURRENT_SOURCE_DIR}/pcre2_chartables.c
  src/pcre2_compile.c
  src/pcre2_config.c
  src/pcre2_context.c
  src/pcre2_convert.c
  src/pcre2_dfa_match.c
  src/pcre2_error.c
  src/pcre2_extuni.c
  src/pcre2_find_bracket.c
  src/pcre2_jit_compile.c
  src/pcre2_maketables.c
  src/pcre2_match.c
  src/pcre2_match_data.c
  src/pcre2_newline.c
  src/pcre2_ord2utf.c
  src/pcre2_pattern_info.c
  src/pcre2_script_run.c
  src/pcre2_serialize.c
  src/pcre2_string_utils.c
  src/pcre2_study.c
  src/pcre2_substitute.c
  src/pcre2_substring.c
  src/pcre2_tables.c
  src/pcre2_ucd.c
  src/pcre2_valid_utf.c
  src/pcre2_xclass.c
)

SET(PCRE2POSIX_HEADERS src/pcre2posix.h)
SET(PCRE2POSIX_SOURCES src/pcre2posix.c)

# Fix static compilation with MSVC: https://bugs.exim.org/show_bug.cgi?id=1681
# This code was taken from the CMake wiki, not from WebM.

IF(MSVC AND PCRE2_STATIC_RUNTIME)
  MESSAGE(STATUS "** MSVC and PCRE2_STATIC_RUNTIME: modifying compiler flags to use static runtime library")
  foreach(flag_var
          CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
          CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO)
    string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
  endforeach()
ENDIF(MSVC AND PCRE2_STATIC_RUNTIME)

# Build setup

ADD_DEFINITIONS(-DHAVE_CONFIG_H)

SET(CMAKE_INCLUDE_CURRENT_DIR 1)

FOREACH (_target ${PROJECT_NAME} ${PROJECT_NAME}_static)
  TARGET_INCLUDE_DIRECTORIES (${_target} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
  IF(PCRE2_BUILD_PCRE2_8)
    SET_PROPERTY(TARGET ${_target} PROPERTY COMPILE_DEFINITIONS PCRE2_CODE_UNIT_WIDTH=8)
  ENDIF(PCRE2_BUILD_PCRE2_8)
  IF(PCRE2_BUILD_PCRE2_16)
    SET_PROPERTY(TARGET ${_target} PROPERTY COMPILE_DEFINITIONS PCRE2_CODE_UNIT_WIDTH=16)
  ENDIF(PCRE2_BUILD_PCRE2_16)
  IF(PCRE2_BUILD_PCRE2_32)
    SET_PROPERTY(TARGET ${_target} PROPERTY COMPILE_DEFINITIONS PCRE2_CODE_UNIT_WIDTH=32)
  ENDIF(PCRE2_BUILD_PCRE2_32)
ENDFOREACH ()

#############
# Packaging #
#############
MYPACKAGEPACK ("" "PCRE2")

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
