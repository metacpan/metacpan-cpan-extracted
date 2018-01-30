CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
#
# Usually the version here correspong to the NEXT version - it is git tagged
# when we do make marpaESLIFPerlRelease
#
MYPACKAGESTART (marpaESLIF 2 0 34)

###########
# Library #
###########
#
# We have some specifics -;
#
# ... Stream buffer size
#
IF (NOT MARPAESLIF_BUFSIZ)
  SET (MARPAESLIF_BUFSIZ "1048576")
ENDIF ()
#
# ... Portable uint32 type
#
IF (NOT HAVE_MYPACKAGE_UINT32)
  MESSAGE (FATAL_ERROR "Could not detect a valid unsigned 32-bit integer type")
ELSE ()
  MESSAGE (STATUS ".. unsigned 32-bit integer type is ${MYPACKAGE_UINT32_TYPEDEF}")
ENDIF ()
SET (MARPAESLIF_UINT32_T ${MYPACKAGE_UINT32_TYPEDEF})
#
# ... PCRE2 dependency
#
FIND_PACKAGE (PCRE2)
IF (NOT PCRE2_FOUND)
  INCLUDE(cmake/BuildPCRE2.cmake)
ENDIF ()
#
# ... Ok -;
#
MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/config.h.in
  ${INCLUDE_OUTPUT_PATH}/marpaESLIF/internal/config.h
  src/marpaESLIF.c)
#
# ... Add our specifics
#
FOREACH (_target marpaESLIF marpaESLIF_static)
  TARGET_COMPILE_DEFINITIONS(${_target} PUBLIC -DMARPAESLIF_BUFSIZ=${MARPAESLIF_BUFSIZ} -DPCRE2_CODE_UNIT_WIDTH=8)
  TARGET_INCLUDE_DIRECTORIES(${_target} PUBLIC ${PCRE2_INCLUDE_DIRS})
  TARGET_LINK_LIBRARIES     (${_target} PUBLIC ${PCRE2_LIBRARIES})
  IF (NOT PCRE2_FOUND)
    ADD_DEPENDENCIES        (${_target} pcre2)
  ENDIF ()
ENDFOREACH ()

###############
# Executables #
###############
MYPACKAGETESTEXECUTABLE(marpaESLIFTester     test/marpaESLIFTester.c)
MYPACKAGETESTEXECUTABLE(adventTester         test/adventTester.c)
MYPACKAGETESTEXECUTABLE(jsonTester           test/jsonTester.c)
MYPACKAGETESTEXECUTABLE(selfTester           test/selfTester.c)
MYPACKAGETESTEXECUTABLE(exceptionTester      test/exceptionTester.c)
MYPACKAGETESTEXECUTABLE(exceptionTester2     test/exceptionTester2.c)
MYPACKAGETESTEXECUTABLE(exceptionTester3     test/exceptionTester3.c)

################
# Dependencies #
################
MYPACKAGEDEPENDENCY (genericLogger "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericLogger" LIBS)
MYPACKAGEDEPENDENCY (genericStack  "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericStack"  LIBS)
MYPACKAGEDEPENDENCY (genericHash   "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericHash"   LIBS)
MYPACKAGEDEPENDENCY (marpaWrapper  "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/marpaWrapper"  LIBS)
MYPACKAGEDEPENDENCY (tconv         "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/tconv"         LIBS)

#########
# Tests #
#########
MYPACKAGECHECK(marpaESLIFTester)
MYPACKAGECHECK(adventTester)
MYPACKAGECHECK(jsonTester)
MYPACKAGECHECK(selfTester)
MYPACKAGECHECK(exceptionTester)
MYPACKAGECHECK(exceptionTester2)
MYPACKAGECHECK(exceptionTester3)

###########
# Install #
###########
MYPACKAGEMAN("doc/Tutorial/Calculator/README.pod" "MARPAESLIF_CALCULATOR" "3" "${MARPAESLIF_VERSION}")
MYPACKAGEMAN("doc/BNF/README.pod"                 "MARPAESLIF_BNF"        "3" "${MARPAESLIF_VERSION}")
MYPACKAGEMAN("doc/API/README.pod"                 "MARPAESLIF_API"        "3" "${MARPAESLIF_VERSION}")

############
# Bindings #
############
FIND_PACKAGE(Java)
FIND_PACKAGE(JNI)
IF (JNI_FOUND AND JAVA_FOUND)
  MESSAGE(STATUS "")
  MESSAGE(STATUS "JAVA Setup:")
  MESSAGE(STATUS "----------")
  MESSAGE(STATUS "Path to javac    : " ${Java_JAVAC_EXECUTABLE})
  MESSAGE(STATUS "Path to javadoc  : " ${Java_JAVADOC_EXECUTABLE})
  MESSAGE(STATUS "Path to jar      : " ${Java_JAR_EXECUTABLE})
  MESSAGE(STATUS "")
  MESSAGE(STATUS "JNI Setup:")
  MESSAGE(STATUS "----------")
  MESSAGE(STATUS "Path to jni.h    : " ${JAVA_INCLUDE_PATH})
  MESSAGE(STATUS "Path to jni_md.h : " ${JAVA_INCLUDE_PATH2})
  ADD_SUBDIRECTORY(src/bindings/java EXCLUDE_FROM_ALL)
ENDIF ()

INCLUDE(FindPerl)
IF (PERL_FOUND)
  EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -MDist::Zilla::App -e "Dist::Zilla::App->run" -- version
    OUTPUT_VARIABLE PERL_OUTPUT_VARIABLE
    ERROR_VARIABLE PERL_ERROR_VARIABLE
    RESULT_VARIABLE PERL_RETURN_VALUE )
  IF (NOT PERL_RETURN_VALUE)
    #
    # dzil command available or not, we will NOT use the "dzil" command, because on Windows,
    # at least, doing a FIND_EXECUTABLE on dzil would return a DZIL_EXECUTABLE that is
    # the PERL SCRIPT version of dzil, not the one with the .bat extension...
    # This is fatal for at least CTest.
    #
    # So let's remain independant on configuration, environment, etc... by using explicitly THIS
    # perl that we have found and nothing else
    #
    MESSAGE(STATUS "")
    MESSAGE(STATUS "PERL Executable located at ${PERL_EXECUTABLE}")
    MESSAGE(STATUS "PERL Packaging will be done with Dist::Zilla::App package")
    MESSAGE(STATUS "Asking for Dist::Zilla version said: ${PERL_OUTPUT_VARIABLE}")
    ADD_SUBDIRECTORY(src/bindings/perl EXCLUDE_FROM_ALL)
  ELSE ()
    MESSAGE(STATUS "")
    MESSAGE(STATUS "PERL Executable located at ${PERL_EXECUTABLE}")
    MESSAGE(STATUS "PERL Packaging cannot be done without the Dist::Zilla package")
    MESSAGE(STATUS "Asking for Dist::Zilla version said: ${PERL_ERROR_VARIABLE}")
  ENDIF ()
ELSE ()
  MESSAGE(STATUS "")
  MESSAGE(STATUS "PERL Packaging cannot be done without perl -;")
ENDIF ()

#############
# Packaging #
#############
MYPACKAGEPACK ("" "Marpa Extended Scanless Interface")

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
