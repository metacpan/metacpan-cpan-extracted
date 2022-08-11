CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART (genericLogger 1 0 42)

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
