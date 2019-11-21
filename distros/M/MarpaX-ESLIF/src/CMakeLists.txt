CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
#
# Usually the version here correspong to the NEXT version - it is git tagged
# when we do make marpaESLIFPerlRelease
#
# SET (MYPACKAGE_DEBUG TRUE)
MYPACKAGESTART (marpaESLIF 3 0 29)

###########
# Library #
###########
IF (MSVC)
  #
  # Some MSVC warnings are literally polluting the output, in particular in Visual Studio 2008
  #
  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /wd4305 /wd4309")
  SET(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} /wd4018 /wd4067 /wd4305 /wd4309")
ENDIF (MSVC)
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
# ... PCRE2 is always built-in, and it is built as an external project
#
INCLUDE(cmake/BuildPCRE2.cmake)
#
# ... Ok -;
#
MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/config.h.in
  ${INCLUDE_OUTPUT_PATH}/marpaESLIF/internal/config.h
  src/marpaESLIF.c)

#
# Since we embed marpaESLIFLua with a #include directive, we have to propagate the
# emebeded lua binding version, that are #define's usually generated with MYPACKAGELIBRARY()
#
FOREACH (_target ${PROJECT_NAME} ${PROJECT_NAME}_static)
  TARGET_COMPILE_DEFINITIONS(${_target}
    PRIVATE -DMARPAESLIFLUA_VERSION_MAJOR=${${PROJECT_NAME}_VERSION_MAJOR}
    PRIVATE -DMARPAESLIFLUA_VERSION_MINOR=${${PROJECT_NAME}_VERSION_MINOR}
    PRIVATE -DMARPAESLIFLUA_VERSION_PATCH=${${PROJECT_NAME}_VERSION_PATCH}
    PRIVATE -DMARPAESLIFLUA_VERSION="${${PROJECT_NAME}_VERSION}"
    )
ENDFOREACH ()

###############
# Executables #
###############
MYPACKAGETESTEXECUTABLE(marpaESLIFTester           test/marpaESLIFTester.c)
MYPACKAGETESTEXECUTABLE(adventTester               test/adventTester.c)
MYPACKAGETESTEXECUTABLE(jsonTester                 test/jsonTester.c)
MYPACKAGETESTEXECUTABLE(jsonTesterLua              test/jsonTesterLua.c)
MYPACKAGETESTEXECUTABLE(jsonTesterWithSharedStream test/jsonTesterWithSharedStream.c)
MYPACKAGETESTEXECUTABLE(selfTester                 test/selfTester.c)
MYPACKAGETESTEXECUTABLE(exceptionTester            test/exceptionTester.c)
MYPACKAGETESTEXECUTABLE(exceptionTester2           test/exceptionTester2.c)
MYPACKAGETESTEXECUTABLE(exceptionTester3           test/exceptionTester3.c)
MYPACKAGETESTEXECUTABLE(exceptionTester4           test/exceptionTester4.c)

################
# Dependencies #
################
MYPACKAGEDEPENDENCY (genericLogger "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericLogger" LIBS LOCAL)
MYPACKAGEDEPENDENCY (genericStack  "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericStack"  LIBS LOCAL STATIC)
MYPACKAGEDEPENDENCY (genericHash   "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericHash"   LIBS LOCAL STATIC)
MYPACKAGEDEPENDENCY (marpaWrapper  "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/marpaWrapper"  LIBS LOCAL STATIC)
MYPACKAGEDEPENDENCY (tconv         "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/tconv"         LIBS LOCAL STATIC)
MYPACKAGEDEPENDENCY (luaunpanic    "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/luaunpanic"    LIBS LOCAL STATIC)

#
# pcre2 is built as an external project: we have to explicitly give the include path.
# In addition:
# - Using pcre2 requires setting PCRE2_CODE_UNIT_WIDTH.
# - Embedded lua uses long double for the lua_Number
#
IF (HAVE_SIZEOF_LONG_LONG)
  SET (LUA_INT_TYPE 3)             # long long
ELSE ()
  SET (LUA_INT_TYPE 2)             # long
ENDIF ()
SET (LUA_FLOAT_TYPE 3)             # long double

FOREACH (_luatarget luaunpanic luaunpanic_static)
  #
  # luaunpanic is used internally by marpaESLIF, and setting
  # these compile definitions will make everything that depend on
  # luaunpanic to have them
  #
  TARGET_COMPILE_DEFINITIONS (${_luatarget} PUBLIC -DLUA_INT_TYPE=${LUA_INT_TYPE} -DLUA_FLOAT_TYPE=${LUA_FLOAT_TYPE})
ENDFOREACH ()
FOREACH (_target marpaESLIF marpaESLIF_static)
  ADD_DEPENDENCIES           (${_target} pcre2)
  TARGET_INCLUDE_DIRECTORIES (${_target} PRIVATE ${PCRE2_INCLUDE_DIRS} "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/luaunpanic/include/luaunpanic/lua" "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/luaunpanic/output/include/luaunpanic/lua" "${CMAKE_CURRENT_SOURCE_DIR}/src/bindings/lua/include")
  TARGET_COMPILE_DEFINITIONS (${_target} PRIVATE -DMARPAESLIF_BUFSIZ=${MARPAESLIF_BUFSIZ} -DPCRE2_CODE_UNIT_WIDTH=8 -DPCRE2_STATIC=1 -DMARPAESLIFLUA_EMBEDDED)
  TARGET_LINK_LIBRARIES      (${_target} PRIVATE ${PCRE2_LIBRARIES})
ENDFOREACH ()

#########
# Tests #
#########
MYPACKAGECHECK(marpaESLIFTester)
MYPACKAGECHECK(adventTester)
MYPACKAGECHECK(jsonTester)
MYPACKAGECHECK(jsonTesterLua)
MYPACKAGECHECK(jsonTesterWithSharedStream)
MYPACKAGECHECK(selfTester)
MYPACKAGECHECK(exceptionTester)
MYPACKAGECHECK(exceptionTester2)
MYPACKAGECHECK(exceptionTester3)
MYPACKAGECHECK(exceptionTester4)

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

# Lua bindings is in development phase
INCLUDE(FindLua)
IF (LUA_FOUND)
  ADD_SUBDIRECTORY(src/bindings/lua EXCLUDE_FROM_ALL)
ENDIF ()

#############
# Packaging #
#############
MYPACKAGEPACK ("" "Marpa Extended Scanless Interface")

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
