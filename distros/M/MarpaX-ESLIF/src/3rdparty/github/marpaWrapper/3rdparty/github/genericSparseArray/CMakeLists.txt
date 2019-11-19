CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART (genericSparseArray 1 0 33)

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
