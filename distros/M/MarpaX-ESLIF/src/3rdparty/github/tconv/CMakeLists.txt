CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART (tconv 1 0 27)

###########
# Library #
###########
SET (libtconv_src src/tconv.c src/tconv/charset/cchardet.c)
SET (libtconv_inc)

# ----------------
# ccharset sources
# ----------------
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
  SET (dlfcn_src "${3RDPARTY_OUTPUT_PATH}/dlfcn-win32/dlfcn.c")
  LIST (APPEND libtconv_src ${dlfcn_src})
  LIST (APPEND libtconv_inc ${3RDPARTY_OUTPUT_PATH}/dlfcn-win32)
  SET (DLFCNWIN32_FOUND TRUE)
ELSE ()
  SET (DLFCNWIN32_FOUND FALSE)
ENDIF ()

# ---
# ICU
# ---
FIND_PACKAGE (ICU)
IF (ICU_FOUND)
  SET (TCONV_HAVE_ICU 1)
  SET (icu_src src/tconv/charset/ICU.c src/tconv/convert/ICU.c)
  LIST (APPEND libtconv_src ${icu_src})
  IF (NOT ("${ICU_INCLUDE_DIRS}" STREQUAL ""))
    LIST (APPEND libtconv_inc ${ICU_INCLUDE_DIRS})
  ENDIF ()
  SET_SOURCE_FILES_PROPERTIES(${icu_src}
    PROPERTIES
    COMPILE_FLAGS ${ICU_C_FLAGS_SHARED}
    )
ENDIF ()

# -----
# ICONV
# -----
FIND_PACKAGE (Iconv)
IF (NOT ICONV_FOUND)
  IF (WIN32 AND NOT CYGWIN)
    EXECUTE_PROCESS(
      COMMAND "${CMAKE_COMMAND}" -E copy_directory "${PROJECT_SOURCE_DIR}/3rdparty/github/winiconv" "${3RDPARTY_OUTPUT_PATH}/winiconv"
      WORKING_DIRECTORY "${3RDPARTY_OUTPUT_PATH}"
      )
    SET (ICONV_FOUND TRUE)
    SET (TCONV_HAVE_ICONV 1)
    LIST (APPEND libtconv_src "${3RDPARTY_OUTPUT_PATH}/winiconv/win_iconv.c")
    LIST (APPEND libtconv_inc "${3RDPARTY_OUTPUT_PATH}/winiconv")
    SET (ICONV_SECOND_ARGUMENT_IS_CONST TRUE)
  ENDIF ()
ELSE ()
  SET (TCONV_HAVE_ICONV 1)
ENDIF ()
IF (ICONV_FOUND)
  SET (iconv_src src/tconv/convert/iconv.c)
  LIST (APPEND libtconv_src ${iconv_src})
  IF (NOT ("${ICONV_INCLUDE_DIRS}" STREQUAL ""))
    LIST (APPEND libtconv_inc ${ICONV_INCLUDE_DIRS})
  ENDIF ()
ENDIF ()

MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/tconv_config.h.in
  ${INCLUDE_OUTPUT_PATH}/tconv_config.h
  ${libtconv_src})

LIST (LENGTH libtconv_inc libtconv_inc_length)
FOREACH (_target tconv tconv_static)
  IF (${libtconv_inc_length} GREATER 0)
    TARGET_INCLUDE_DIRECTORIES(${_target} PUBLIC ${libtconv_inc})
  ENDIF ()
  IF (ICU_FOUND AND (NOT ("${ICU_LINK_FLAGS}" STREQUAL "")))
    TARGET_LINK_LIBRARIES(${_target} PUBLIC ${ICU_LINK_FLAGS})
  ENDIF ()
  IF (ICONV_FOUND AND (NOT ("${ICONV_LINK_FLAGS}" STREQUAL "")))
    TARGET_LINK_LIBRARIES(${_target} PUBLIC ${ICONV_LINK_FLAGS})
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
  TARGET_COMPILE_DEFINITIONS(${_target} PRIVATE -DOPTPARSE_IMPLEMENTATION -DOPTPARSE_API=static -DTCONV_VERSION="${TCONV_VERSION}")
  TARGET_INCLUDE_DIRECTORIES(${_target} PRIVATE ${3RDPARTY_OUTPUT_PATH}/optparse)
  IF (${_target} STREQUAL "tconvExe")
    SET_TARGET_PROPERTIES(${_target} PROPERTIES OUTPUT_NAME tconv)
  ELSE ()
    SET_TARGET_PROPERTIES(${_target} PROPERTIES OUTPUT_NAME tconv_static)
  ENDIF ()
ENDFOREACH ()

################
# Dependencies #
################
MYPACKAGEDEPENDENCY (genericLogger "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericLogger" LIBS)

#########
# Tests #
#########
MYPACKAGECHECK(tconvExe -t UTF-16 -o tconv.tconv-UTF-16.c "${PROJECT_SOURCE_DIR}/src/tconv.c")

###########
# Install #
###########
INSTALL (TARGETS tconv tconvExe ARCHIVE DESTINATION lib LIBRARY DESTINATION lib RUNTIME DESTINATION bin)
MYPACKAGEMAN("include/README.pod"       "TCONV"     "3" "${TCONV_VERSION}")
MYPACKAGEMAN("include/tconv/README.pod" "TCONV_EXT" "3" "${TCONV_VERSION}")
