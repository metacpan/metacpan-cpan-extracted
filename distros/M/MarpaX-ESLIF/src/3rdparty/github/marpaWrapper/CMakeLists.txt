CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
PROJECT(marpaWrapper VERSION 1.0.101 LANGUAGES C)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART ()

##############################################################################################
# For performance reason (compiler optimization of unit) we want everything in a single file #
##############################################################################################

MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/config.h.in
  ${INCLUDE_OUTPUT_PATH}/config.h
  amalgamation/marpaWrapper.c)
#
# Because of Marpa, the cmake framework does not know about it
#
FOREACH (_target ${PROJECT_NAME} ${PROJECT_NAME}_static)
  TARGET_INCLUDE_DIRECTORIES(${_target} PRIVATE libmarpa/work/stage)
  FOREACH (_type MAJOR MICRO MINOR)
    TARGET_COMPILE_DEFINITIONS(${_target} PRIVATE -DMARPA_LIB_${_type}_VERSION=MARPA_${_type}_VERSION)
  ENDFOREACH ()
ENDFOREACH ()

###############
# Executables #
###############
MYPACKAGETESTEXECUTABLE(marpaWrapperTester             test/marpaWrapperTester.c)
MYPACKAGETESTEXECUTABLE(marpaWrapperAsfTester          test/marpaWrapperAsfTester.c)
MYPACKAGETESTEXECUTABLE(marpaWrapperAsfValueTester     test/marpaWrapperAsfValueTester.c)
MYPACKAGETESTEXECUTABLE(marpaWrapperAsfAmbiguousTester test/marpaWrapperAsfAmbiguousTester.c)

################
# Dependencies #
################
MYPACKAGEDEPENDENCY (genericStack       "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericStack" LIBS LOCAL)              # present in public API
MYPACKAGEDEPENDENCY (genericLogger      "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericLogger" LIBS LOCAL)             # present in public API
MYPACKAGEDEPENDENCY (genericHash        "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericHash" LIBS LOCAL STATIC)        # not present in public API
MYPACKAGEDEPENDENCY (genericSparseArray "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericSparseArray" LIBS LOCAL STATIC) # not present in public API

#########
# Tests #
#########
MYPACKAGECHECK(marpaWrapperTester)
MYPACKAGECHECK(marpaWrapperAsfTester)
MYPACKAGECHECK(marpaWrapperAsfValueTester)
MYPACKAGECHECK(marpaWrapperAsfAmbiguousTester)

#############
# Packaging #
#############
MYPACKAGEPACK("" "Generic Logger")

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
