CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART (marpaWrapper 1 0 56)

####################
# libmarpa sources #
####################
EXECUTE_PROCESS(
  COMMAND "${CMAKE_COMMAND}" -E copy_directory "${PROJECT_SOURCE_DIR}/3rdparty/github/Marpa--R2" "${3RDPARTY_OUTPUT_PATH}/Marpa--R2"
  WORKING_DIRECTORY "${3RDPARTY_OUTPUT_PATH}"
  )
SET (MARPA__R2_FOUND TRUE)
SET (MARPA__R2_DIR            "${3RDPARTY_OUTPUT_PATH}/Marpa--R2")
SET (MARPA__R2_INCLUDE_DIR    "${MARPA__R2_DIR}")
SET (MARPA__R2_LIBRARY_TARGET "marpa")

######################
# Library definition #
######################
FILE (GLOB lib_marpa_src "${MARPA__R2_DIR}/cpan/engine/read_only/*.c")
FILE (GLOB lib_src src/internal/*.c src/*.c)
MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/config.h.in
  ${INCLUDE_OUTPUT_PATH}/config.h
  ${lib_src} ${lib_marpa_src})
#
# Because of Marpa, the cmake framework does not know about it
#
FOREACH (_target ${PROJECT_NAME} ${PROJECT_NAME}_static)
  TARGET_INCLUDE_DIRECTORIES(${_target} PUBLIC ${MARPA__R2_DIR}/cpan/engine/read_only)
  FOREACH (_type MAJOR MICRO MINOR)
    TARGET_COMPILE_DEFINITIONS(${_target} PUBLIC -DMARPA_LIB_${_type}_VERSION=MARPA_${_type}_VERSION)
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
MYPACKAGEDEPENDENCY (genericStack       "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericStack" LIBS TESTS)
MYPACKAGEDEPENDENCY (genericLogger      "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericLogger" LIBS TESTS)
MYPACKAGEDEPENDENCY (genericHash        "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericHash" LIBS)
MYPACKAGEDEPENDENCY (genericSparseArray "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/github/genericSparseArray" LIBS)

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
