CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("../../../3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()

MYPACKAGESTART (pcre2 10 23 0)

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

INCLUDE(CheckFunctionExists)
CHECK_FUNCTION_EXISTS(bcopy     HAVE_BCOPY)
CHECK_FUNCTION_EXISTS(memmove   HAVE_MEMMOVE)
CHECK_FUNCTION_EXISTS(strerror  HAVE_STRERROR)

OPTION(PCRE2_BUILD_PCRE2_8 "Build 8 bit PCRE2 library" ON)
OPTION(PCRE2_BUILD_PCRE2_16 "Build 16 bit PCRE2 library" OFF)
OPTION(PCRE2_BUILD_PCRE2_32 "Build 32 bit PCRE2 library" OFF)
OPTION(PCRE2_DEBUG "Include debugging code" OFF)
SET(PCRE2_EBCDIC ${EBCDIC} CACHE BOOL "Use EBCDIC coding instead of ASCII. (This is rarely used outside of mainframe systems.)")
SET(PCRE2_EBCDIC_NL25 OFF CACHE BOOL "Use 0x25 as EBCDIC NL character instead of 0x15; implies EBCDIC.")
SET(PCRE2_LINK_SIZE "2" CACHE STRING "Internal link size (2, 3 or 4 allowed). See LINK_SIZE in config.h.in for details.")
SET(PCRE2_PARENS_NEST_LIMIT "250" CACHE STRING "Default nested parentheses limit. See PARENS_NEST_LIMIT in config.h.in for details.")
SET(PCRE2_MATCH_LIMIT "10000000" CACHE STRING "Default limit on internal looping. See MATCH_LIMIT in config.h.in for details.")
SET(PCRE2_MATCH_LIMIT_RECURSION "MATCH_LIMIT" CACHE STRING "Default limit on internal recursion. See MATCH_LIMIT_RECURSION in config.h.in for details.")
SET(PCRE2GREP_BUFSIZE "20480" CACHE STRING "Buffer starting size parameter for pcre2grep. See PCRE2GREP_BUFSIZE in config.h.in for details.")
SET(PCRE2GREP_MAX_BUFSIZE "1048576" CACHE STRING "Buffer maximum size parameter for pcre2grep. See PCRE2GREP_MAX_BUFSIZE in config.h.in for details.")
SET(PCRE2_NEWLINE "LF" CACHE STRING "What to recognize as a newline (one of CR, LF, CRLF, ANY, ANYCRLF).")
SET(PCRE2_HEAP_MATCH_RECURSE OFF CACHE BOOL "If ON, then don't use stack recursion when matching. See HEAP_MATCH_RECURSE in config.h.in for details.")
SET(PCRE2_SUPPORT_JIT ON CACHE BOOL "Enable support for Just-in-time compiling.")
SET(PCRE2_SUPPORT_PCRE2GREP_JIT ON CACHE BOOL "Enable use of Just-in-time compiling in pcre2grep.")
SET(PCRE2_SUPPORT_PCRE2GREP_CALLOUT ON CACHE BOOL "Enable callout string support in pcre2grep.")
IF (EBCDIC)
  SET(PCRE2_SUPPORT_UNICODE OFF CACHE BOOL "Enable support for Unicode and UTF-8/UTF-16/UTF-32 encoding.")
ELSE ()
  SET(PCRE2_SUPPORT_UNICODE ON CACHE BOOL "Enable support for Unicode and UTF-8/UTF-16/UTF-32 encoding.")
ENDIF ()
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

IF(PCRE2_SUPPORT_BSR_ANYCRLF)
  SET(BSR_ANYCRLF 1)
ENDIF(PCRE2_SUPPORT_BSR_ANYCRLF)

IF(PCRE2_NEVER_BACKSLASH_C)
  SET(NEVER_BACKSLASH_C 1)
ENDIF(PCRE2_NEVER_BACKSLASH_C)

IF(PCRE2_SUPPORT_UNICODE)
  SET(SUPPORT_UNICODE 1)
ENDIF(PCRE2_SUPPORT_UNICODE)

IF(PCRE2_SUPPORT_JIT)
  SET(SUPPORT_JIT 1)
ENDIF(PCRE2_SUPPORT_JIT)

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

IF(PCRE2_HEAP_MATCH_RECURSE)
  SET(HEAP_MATCH_RECURSE 1)
ENDIF(PCRE2_HEAP_MATCH_RECURSE)

# Parse version numbers and date out of configure.ac
FILE(STRINGS ${PROJECT_SOURCE_DIR}/configure.ac
  configure_lines
  LIMIT_COUNT 50 # Read only the first 50 lines of the file
  )

SET(SEARCHED_VARIABLES "pcre2_major" "pcre2_minor" "pcre2_prerelease" "pcre2_date")
FOREACH(configure_line ${configure_lines})
  FOREACH(_substitution_variable ${SEARCHED_VARIABLES})
    STRING(TOUPPER ${_substitution_variable} _substitution_variable_upper)
    IF (NOT ${_substitution_variable_upper})
      STRING(REGEX MATCH "m4_define\\(${_substitution_variable}, \\[(.*)\\]" MACTHED_STRING ${configure_line})
      IF (CMAKE_MATCH_1)
        SET(${_substitution_variable_upper} ${CMAKE_MATCH_1})
      ENDIF()
    ENDIF()
  ENDFOREACH()
ENDFOREACH()

CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/src/pcre2.h.in
  ${INCLUDE_OUTPUT_PATH}/pcre2.h
  @ONLY)

OPTION(PCRE2_REBUILD_CHARTABLES "Rebuild char tables" OFF)
IF(PCRE2_REBUILD_CHARTABLES)
  ADD_EXECUTABLE(dftables src/dftables.c)
  ADD_CUSTOM_COMMAND(
    COMMENT "Generating character tables (pcre2_chartables.c) for current locale"
    DEPENDS dftables
    COMMAND dftables
    ARGS        ${CMAKE_CURRENT_BINARY_DIR}/pcre2_chartables.c
    OUTPUT      ${CMAKE_CURRENT_BINARY_DIR}/pcre2_chartables.c
    )
ELSE(PCRE2_REBUILD_CHARTABLES)
  CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/src/pcre2_chartables.c.dist
    ${CMAKE_CURRENT_BINARY_DIR}/pcre2_chartables.c
    COPYONLY)
ENDIF(PCRE2_REBUILD_CHARTABLES)

SET(PCRE2_HEADERS ${INCLUDE_OUTPUT_PATH}/pcre2.h)

MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/config-cmake.h.in
  ${INCLUDE_OUTPUT_PATH}/config.h
  src/pcre2_auto_possess.c
  ${CMAKE_CURRENT_SOURCE_DIR}/pcre2_chartables.c
  src/pcre2_compile.c
  src/pcre2_config.c
  src/pcre2_context.c
  src/pcre2_dfa_match.c
  src/pcre2_error.c
  src/pcre2_find_bracket.c
  src/pcre2_jit_compile.c
  src/pcre2_maketables.c
  src/pcre2_match.c
  src/pcre2_match_data.c
  src/pcre2_newline.c
  src/pcre2_ord2utf.c
  src/pcre2_pattern_info.c
  src/pcre2_serialize.c
  src/pcre2_string_utils.c
  src/pcre2_study.c
  src/pcre2_substitute.c
  src/pcre2_substring.c
  src/pcre2_tables.c
  src/pcre2_ucd.c
  src/pcre2_valid_utf.c
  src/pcre2_xclass.c)

IF(MSVC AND PCRE2_STATIC_RUNTIME)
  MESSAGE(STATUS "** MSVC and PCRE2_STATIC_RUNTIME: modifying compiler flags to use static runtime library")
  foreach(flag_var
      CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
      CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO)
    string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
  endforeach()
ENDIF(MSVC AND PCRE2_STATIC_RUNTIME)

ADD_DEFINITIONS(-DHAVE_CONFIG_H)

IF(MSVC)
  ADD_DEFINITIONS(-D_CRT_SECURE_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS)
ENDIF(MSVC)

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
