CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("../../../3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
# marpaESLIFLua version is synced with marpaESLIF
MYPACKAGESTART (marpaESLIFLua ${marpaESLIF_VERSION_MAJOR} ${marpaESLIF_VERSION_MINOR} ${marpaESLIF_VERSION_PATCH})

INCLUDE (FindLua)
MESSAGE(STATUS "LUA_LIBRARIES     : ${LUA_LIBRARIES}")
MESSAGE(STATUS "LUA_INCLUDE_DIR   : ${LUA_INCLUDE_DIR}")
MESSAGE(STATUS "LUA_VERSION_STRING: ${LUA_VERSION_STRING}")
MESSAGE(STATUS "LUA_VERSION_MAJOR : ${LUA_VERSION_MAJOR}")
MESSAGE(STATUS "LUA_VERSION_MINOR : ${LUA_VERSION_MINOR}")
MESSAGE(STATUS "LUA_VERSION_PATCH : ${LUA_VERSION_PATCH}")
INCLUDE_DIRECTORIES (${LUA_INCLUDE_DIR})

###########
# Library #
###########
MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/config.h.in
  ${INCLUDE_OUTPUT_PATH}/marpaESLIFLua/internal/config.h
  src/marpaESLIFLua.c)

#
# Lua recommended specifics on the shared library: no prefix, no versioning
#
SET_TARGET_PROPERTIES (marpaESLIFLua
  PROPERTIES
  PREFIX ""
  NO_SONAME TRUE
  )

################
# Dependencies #
################
MYPACKAGEDEPENDENCY (marpaESLIF "${CMAKE_SOURCE_DIR}" LIBS)
MYPACKAGEDEPENDENCY (genericStack "${CMAKE_SOURCE_DIR}/3rdparty/github/genericStack" LIBS LOCAL STATIC)
FOREACH (_target marpaESLIFLua marpaESLIFLua_static)
  TARGET_LINK_LIBRARIES(${_target} PUBLIC ${LUA_LIBRARIES})
ENDFOREACH ()

########
# Test #
########
IF (${CMAKE_COMPILER_IS_GNUCC})
  #
  # Work only compiles having rdynamic-path
  #
  FIND_PROGRAM(LUA_EXECUTABLE NAMES lua${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR} lua)
  IF (LUA_EXECUTABLE)
    MESSAGE (STATUS "Found lua executable: ${LUA_EXECUTABLE}")
    GET_PROPERTY(_test_path GLOBAL PROPERTY MYPACKAGE_TEST_PATH)
    GET_FILENAME_COMPONENT(_absolute_library_output_path ${LIBRARY_OUTPUT_PATH} ABSOLUTE)
    IF ("${CMAKE_HOST_SYSTEM}" MATCHES ".*Windows.*")
      SET (SEP "\\;")
    ELSE ()
      SET (SEP ":")
    ENDIF ()
    ADD_TEST (
      NAME marpaESLIFLuaTest
      COMMAND ${CMAKE_COMMAND} -E env "PATH=.${SEP}${_test_path}" "${LUA_EXECUTABLE}" ../../test/marpaESLIFLuaTest.lua
      WORKING_DIRECTORY ${_absolute_library_output_path}
      )
    ADD_DEPENDENCIES(check marpaESLIFLua)
  ENDIF ()
ENDIF ()
