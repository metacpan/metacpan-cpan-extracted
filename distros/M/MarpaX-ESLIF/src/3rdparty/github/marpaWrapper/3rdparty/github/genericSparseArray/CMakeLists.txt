CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
PROJECT(genericSparseArray VERSION 1.0.50 LANGUAGES C)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART ()

###############
# Executables #
###############
MYPACKAGETESTEXECUTABLE(genericSparseArrayTester test/genericSparseArray.c)

################
# Dependencies #
################
MYPACKAGEDEPENDENCY (genericHash   "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericHash" LOCAL)
MYPACKAGEDEPENDENCY (genericLogger "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericLogger" TESTS STATIC LOCAL)

#########
# Tests #
#########
MYPACKAGECHECK(genericSparseArrayTester)

#############
# Packaging #
#############
MYPACKAGEPACK("" "Generic Sparse Array")

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
