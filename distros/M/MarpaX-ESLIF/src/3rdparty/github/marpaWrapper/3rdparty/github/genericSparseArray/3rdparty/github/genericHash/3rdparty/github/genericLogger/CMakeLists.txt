CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
PROJECT(genericLogger VERSION 1.0.45 LANGUAGES C)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART ()

######################
# Library definition #
######################
FILE (GLOB lib_src src/*.c)
MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/genericLogger_config.h.in
  ${INCLUDE_OUTPUT_PATH}/genericLogger/config.h
  ${lib_src})

###############
# Executables #
###############
MYPACKAGETESTEXECUTABLE(genericLoggerTester test/genericLoggerTester.c)

#########
# Tests #
#########
MYPACKAGECHECK(genericLoggerTester)

#############
# Packaging #
#############
MYPACKAGEPACK("" "Generic Logger")

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
