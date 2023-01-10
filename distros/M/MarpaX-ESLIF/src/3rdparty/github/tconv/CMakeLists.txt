CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
PROJECT(tconv VERSION 1.0.80 LANGUAGES C CXX)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART ()

####################
# Specific options #
####################
OPTION(TCONV_USE_ICU   "Enable ICU plugin if found" ON)
OPTION(TCONV_USE_ICONV "Enable ICONV plugin plugin" ON)

###########
# Library #
###########
SET (libtconv_src src/tconv.c src/tconv/charset/tconv_charset_cchardet.c)
SET (libtconv_inc)

SET (TCONV_ICONV_VERSION 1.16)

IF (TCONV_USE_ICONV)
  # ------------------------------------
  # iconv sources: libiconv-${TCONV_ICONV_VERSION} builtin
  # ------------------------------------
  MESSAGE (STATUS "Unpacking libiconv")
  EXECUTE_PROCESS(
    COMMAND "${CMAKE_COMMAND}" -E tar xzf ${PROJECT_SOURCE_DIR}/3rdparty/tar/libiconv-${TCONV_ICONV_VERSION}.tar.gz
    WORKING_DIRECTORY "${3RDPARTY_OUTPUT_PATH}"
    )
  #
  # iconv uses config.h, we are using tconv_config.h, so there is no clash luckily
  #
  FILE (WRITE
    ${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/include/config.h
"
/* Generated file */
/* localcharset.c will play itself with WIN32_LEAN_AND_MEAN... */
#undef WIN32_LEAN_AND_MEAN
"
  )
  FUNCTION (CREATE_ICONV_H src dst)
    SET (DLL_VARIABLE "") # Just to be sure
    SET (EILSEQ 134679) # Fallback value if any
    SET (ICONV_CONST "")
    SET (USE_MBSTATE_T "0")
    SET (HAVE_WCHAR_T "0")
    MESSAGE (STATUS "Configuring ${dst}")
    CONFIGURE_FILE (${src} ${dst})
  ENDFUNCTION ()
  FUNCTION (CREATE_LOCALCHARSET_H src dst)
    MESSAGE (STATUS "Configuring ${dst}")
    CONFIGURE_FILE (${src} ${dst})
  ENDFUNCTION ()

  CREATE_ICONV_H(${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/include/iconv.h.in ${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/include/iconv.h @ONLY)
  CREATE_LOCALCHARSET_H(${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/libcharset/include/localcharset.h.in ${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/libcharset/include/localcharset.h @ONLY)
  INCLUDE (CheckCSourceCompiles)
  CHECK_C_SOURCE_COMPILES("
  #include <stdlib.h>
  #include <langinfo.h>
  int main(int ac, char **av)
  {
    char *cs = nl_langinfo(CODESET);
    exit(0);
  }"
    HAVE_LANGINFO_CODESET)

  INCLUDE ( CheckSymbolExists )
  CHECK_SYMBOL_EXISTS ( getc_unlocked "stdio.h" HAVE_DECL_GETC_UNLOCKED )
  SET (ENABLE_EXTRA TRUE)

  INCLUDE (TestBigEndian)
  TEST_BIG_ENDIAN(IS_BIG_ENDIAN)
  IF (NOT IS_BIG_ENDIAN)
    SET (WORDS_LITTLEENDIAN TRUE)
  ENDIF ()

  LIST (APPEND libtconv_iconv_src
    ${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/libcharset/lib/localcharset.c
    ${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/lib/relocatable.c
    ${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/lib/iconv.c
    )
  FOREACH (_iconv_src ${libtconv_iconv_src})
    SET_PROPERTY(
      SOURCE ${_iconv_src}
      PROPERTY COMPILE_FLAGS
      " -I${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/include -I${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/libcharset/include"
      )
    #
    # Remove the const thingy
    #
    SET_PROPERTY(
      SOURCE ${_iconv_src}
      APPEND
      PROPERTY COMPILE_DEFINITIONS
      ICONV_CONST=
      )
    SET_PROPERTY(
      SOURCE ${_iconv_src}
      APPEND
      PROPERTY COMPILE_DEFINITIONS
      LIBDIR=""
      )
    SET_PROPERTY(
      SOURCE ${_iconv_src}
      APPEND
      PROPERTY COMPILE_DEFINITIONS
      HAVE_WORKING_O_NOFOLLOW=0
      )
    IF (WORDS_LITTLEENDIAN)
      SET_PROPERTY(
        SOURCE ${_iconv_src}
        APPEND
        PROPERTY COMPILE_DEFINITIONS
        WORDS_LITTLEENDIAN=1
        )
    ENDIF ()
    IF (HAVE_DECL_GETC_UNLOCKED)
      SET_PROPERTY(
        SOURCE ${_iconv_src}
        APPEND
        PROPERTY COMPILE_DEFINITIONS
        HAVE_DECL_GETC_UNLOCKED=1
        )
    ENDIF ()
    IF (HAVE_LANGINFO_CODESET)
      SET_PROPERTY(
        SOURCE ${_iconv_src}
        APPEND
        PROPERTY COMPILE_DEFINITIONS
        HAVE_LANGINFO_CODESET=1
        )
    ENDIF ()
    #
    # Flags that are always turned on
    #
    FOREACH (_have ENABLE_EXTRA)
      IF (${${_have}})
        SET_PROPERTY(
	  SOURCE ${_iconv_src}
	  APPEND
	  PROPERTY COMPILE_DEFINITIONS
	  ${_have}=1
	  )
      ENDIF ()
    ENDFOREACH ()
  ENDFOREACH ()

  LIST (APPEND libtconv_src ${libtconv_iconv_src})
ENDIF ()

# ----------------
# ccharset sources
# ----------------
MESSAGE (STATUS "Unpacking cchardet")
EXECUTE_PROCESS(
  COMMAND "${CMAKE_COMMAND}" -E tar xzf ${PROJECT_SOURCE_DIR}/3rdparty/tar/cchardet-1.0.0.tar.gz
  WORKING_DIRECTORY "${3RDPARTY_OUTPUT_PATH}"
  )
#
# nspr-emu mess revisit
# We will need common includes and sizes now - so let's call the macro doing that
#
MYPACKAGECHECKCOMMONINCLUDEFILES()
MYPACKAGECHECKCOMMONSIZES()
MESSAGE(STATUS "Suppress directory cchardet-1.0.0/src/ext/libcharsetdetect/nspr-emu")
EXECUTE_PROCESS(
  COMMAND "${CMAKE_COMMAND}" -E remove_directory ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect/nspr-emu
  )
MESSAGE(STATUS "Generate directory cchardet-1.0.0/src/ext/libcharsetdetect/nspr-emu")
EXECUTE_PROCESS(
  COMMAND "${CMAKE_COMMAND}" -E make_directory ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect/nspr-emu
  )
MESSAGE(STATUS "Copying file cchardet-1.0.0/src/ext/libcharsetdetect/nspr-emu/nsDebug.h")
EXECUTE_PROCESS(
  COMMAND "${CMAKE_COMMAND}" -E copy ${CMAKE_CURRENT_SOURCE_DIR}/include/nsDebug.h.in ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect/nspr-emu/nsDebug.h
  )
MESSAGE(STATUS "Copying file cchardet-1.0.0/src/ext/libcharsetdetect/nspr-emu/prmem.h")
EXECUTE_PROCESS(
  COMMAND "${CMAKE_COMMAND}" -E copy ${CMAKE_CURRENT_SOURCE_DIR}/include/prmem.h.in ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect/nspr-emu/prmem.h
  )
MESSAGE(STATUS "Suppress file cchardet-1.0.0/src/ext/libcharsetdetect/nscore.h")
EXECUTE_PROCESS(
  COMMAND "${CMAKE_COMMAND}" -E remove -f ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect/nscore.h
  )
MESSAGE(STATUS "Generate file cchardet-1.0.0/src/ext/libcharsetdetect/nscore.h")
CONFIGURE_FILE(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/nscore.h.in
  ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect/nscore.h
  )
FILE (GLOB ccharset_src
  ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect/mozilla/extensions/universalchardet/src/base/*.cpp
  ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect/charsetdetect.cpp
  )
LIST (APPEND libtconv_src ${ccharset_src})
LIST (APPEND libtconv_inc
    ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect/mozilla/extensions/universalchardet/src/base
    ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect/nspr-emu
    ${3RDPARTY_OUTPUT_PATH}/cchardet-1.0.0/src/ext/libcharsetdetect
  )

# ---------------
# portable dlopen
# ---------------
IF (WIN32 AND NOT CYGWIN)
  EXECUTE_PROCESS(
    COMMAND "${CMAKE_COMMAND}" -E copy_directory "${PROJECT_SOURCE_DIR}/3rdparty/github/dlfcn-win32" "${3RDPARTY_OUTPUT_PATH}/dlfcn-win32"
    WORKING_DIRECTORY "${3RDPARTY_OUTPUT_PATH}"
    )
  SET (dlfcn_src "${3RDPARTY_OUTPUT_PATH}/dlfcn-win32/src/dlfcn.c")
  LIST (APPEND libtconv_src ${dlfcn_src})
  LIST (APPEND libtconv_inc ${3RDPARTY_OUTPUT_PATH}/dlfcn-win32/src)
  SET (DLFCNWIN32_FOUND TRUE)
ELSE ()
  SET (DLFCNWIN32_FOUND FALSE)
ENDIF ()

###################
# Default Plugins #
###################

# ---
# ICU
# ---
IF (NOT TCONV_USE_ICU)
  MESSAGE (STATUS "ICU plugin is disabled")
  SET (ICU_FOUND FALSE)
ELSE ()
  FIND_PACKAGE (ICU COMPONENTS uc i18n)
ENDIF ()
IF (ICU_FOUND)
  SET (TCONV_HAVE_ICU 1)
  SET (icu_src src/tconv/charset/tconv_charset_ICU.c src/tconv/convert/tconv_convert_ICU.c)
  LIST (APPEND libtconv_src ${icu_src})
ENDIF ()

# -----
# ICONV
# -----
IF (NOT TCONV_USE_ICONV)
  MESSAGE (STATUS "ICONV plugin is disabled")
  SET (ICONV_FOUND FALSE)
ELSE ()
  SET (ICONV_FOUND TRUE)
ENDIF ()
IF (ICONV_FOUND)
  SET (TCONV_HAVE_ICONV 1)
  SET (ICONV_SECOND_ARGUMENT_IS_CONST FALSE)
  SET (ICONV_CAN_TRANSLIT TRUE)
  SET (ICONV_CAN_IGNORE TRUE)
  LIST (APPEND libtconv_src src/tconv/convert/tconv_convert_iconv.c)
  LIST (APPEND libtconv_inc ${3RDPARTY_OUTPUT_PATH}/libiconv-${TCONV_ICONV_VERSION}/include)
ENDIF ()

MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/tconv_config.h.in
  ${INCLUDE_OUTPUT_PATH}/tconv_config.h
  ${libtconv_src})

LIST (LENGTH libtconv_inc libtconv_inc_length)
FOREACH (_target tconv tconv_static)
  IF (${libtconv_inc_length} GREATER 0)
    TARGET_INCLUDE_DIRECTORIES(${_target} PRIVATE ${libtconv_inc})
  ENDIF ()
  IF (ICU_FOUND)
    TARGET_LINK_LIBRARIES(${_target} PUBLIC ICU::ICU)
  ENDIF ()
  IF (NOT ("${CMAKE_DL_LIBS}" STREQUAL ""))
    TARGET_LINK_LIBRARIES(${_target} PUBLIC ${CMAKE_DL_LIBS})
  ENDIF ()
  IF (DLFCNWIN32_FOUND)
    TARGET_LINK_LIBRARIES(${_target} PUBLIC "psapi")
  ENDIF ()
ENDFOREACH ()

###############
# Executables #
###############

# --------
# optparse
# --------
EXECUTE_PROCESS(
  COMMAND "${CMAKE_COMMAND}" -E copy_directory "${PROJECT_SOURCE_DIR}/3rdparty/github/optparse" "${3RDPARTY_OUTPUT_PATH}/optparse"
  WORKING_DIRECTORY "${3RDPARTY_OUTPUT_PATH}"
  )
MYPACKAGEEXECUTABLE(tconvExe bin/tconv.c)
MYPACKAGEADDEXECUTABLESTOTESTS(tconvExe)
FOREACH (_target tconvExe tconvExe_static)
  TARGET_COMPILE_DEFINITIONS(${_target} PRIVATE -DOPTPARSE_IMPLEMENTATION -DOPTPARSE_API=static -DTCONV_VERSION="${${PROJECT_NAME}_VERSION}")
  TARGET_INCLUDE_DIRECTORIES(${_target} PRIVATE ${3RDPARTY_OUTPUT_PATH}/optparse)
  IF (${_target} STREQUAL "tconvExe")
    SET_TARGET_PROPERTIES(${_target} PROPERTIES OUTPUT_NAME tconv)
  ELSE ()
    SET_TARGET_PROPERTIES(${_target} PROPERTIES OUTPUT_NAME tconv_static)
  ENDIF ()
  IF (CMAKE_C_COMPILER_ID STREQUAL SunPro)
    TARGET_LINK_LIBRARIES(${_target} PUBLIC Crun)
  ENDIF ()
ENDFOREACH ()

MYPACKAGETESTEXECUTABLE(tconvExample test/example.c)
FOREACH (_target tconvExample tconvExample_static)
  TARGET_COMPILE_DEFINITIONS(${_target} PRIVATE -DOPTPARSE_IMPLEMENTATION -DOPTPARSE_API=static)
  TARGET_INCLUDE_DIRECTORIES(${_target} PRIVATE ${3RDPARTY_OUTPUT_PATH}/optparse)
  IF (CMAKE_C_COMPILER_ID STREQUAL SunPro)
    TARGET_LINK_LIBRARIES(${_target} PUBLIC Crun)
  ENDIF ()
ENDFOREACH ()

#########
# Tests #
#########
MYPACKAGECHECK(tconvExe -t UTF-16 -o tconv.tconv-UTF-16.c "${PROJECT_SOURCE_DIR}/src/tconv.c")
MYPACKAGECHECK(tconvExample)

################
# Dependencies #
################
MYPACKAGEDEPENDENCY (genericLogger "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericLogger" LIBS STATIC LOCAL)

###########
# Install #
###########
MYPACKAGEMAN("include/README.pod"       "TCONV"     "3" "${TCONV_VERSION}")
MYPACKAGEMAN("include/tconv/README.pod" "TCONV_EXT" "3" "${TCONV_VERSION}")

#############
# Packaging #
#############
MYPACKAGEPACK ("" "Portable Iconv-like interface")

###########
# Codecov #
###########
SET (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/3rdparty/github/CMake-codecov/cmake")
FIND_PACKAGE(codecov)
FOREACH (_target tconv tconv_static tconvExe tconvExe_static tconvExample tconvExample_static)
  add_coverage(${_target})
ENDFOREACH ()
coverage_evaluate()

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
