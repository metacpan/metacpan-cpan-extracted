CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART (luaunpanic 5 3 4)

OPTION (LUA_32BITS "Use 32-bit integers and 32-bit floats" OFF)
OPTION (LUA_USE_C89 "Avoid the use of few C99 feature" OFF)

###########
# Library #
###########
SET (libluaunpanic_src
  src/lapi.c
  src/lauxlib.c
  src/lbaselib.c
  src/lbitlib.c
  src/lcode.c
  src/lcorolib.c
  src/lctype.c
  src/ldblib.c
  src/ldebug.c
  src/ldo.c
  src/ldump.c
  src/lfunc.c
  src/lgc.c
  src/linit.c
  src/liolib.c
  src/llex.c
  src/lmathlib.c
  src/lmem.c
  src/loadlib.c
  src/lobject.c
  src/lopcodes.c
  src/loslib.c
  src/lparser.c
  src/lstate.c
  src/lstring.c
  src/lstrlib.c
  src/ltable.c
  src/ltablib.c
  src/ltm.c
  src/lundump.c
  src/lutf8lib.c
  src/lvm.c
  src/lzio.c
  src/luaunpanic.c
  )
#
# OS-specifics
#
IF (WIN32 AND NOT CYGWIN)
  ADD_DEFINITIONS(-DLUA_DL_DLL)
ELSE ()
  ADD_DEFINITIONS(-DLUA_USE_DLOPEN)
  ADD_DEFINITIONS(-DLUA_USE_POSIX)
  SET (CMAKE_MATH_LIBS m)
ENDIF ()

MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/luaunpanic/internal/luaconf.h.in
  ${INCLUDE_OUTPUT_PATH}/luaunpanic/lua/luaconf.h
  ${libluaunpanic_src})
#
# We moved lua headers to include/luaunpanic/lua
# We generate luaconf.h in ${INCLUDE_OUTPUT_PATH}/luaunpanic/lua
#
INCLUDE_DIRECTORIES("${CMAKE_CURRENT_SOURCE_DIR}/include/luaunpanic/lua" "${INCLUDE_OUTPUT_PATH}/luaunpanic/lua")
#
# Add lua/luaconf.h to installed files
#
INSTALL(FILES ${INCLUDE_OUTPUT_PATH}/luaunpanic/lua/luaconf.h DESTINATION include/luaunpanic/lua COMPONENT HeaderComponent)
#
# dl and m dependency
#
IF (   (NOT ("${CMAKE_DL_LIBS}" STREQUAL ""))
    OR (NOT ("${CMAKE_MATH_LIBS}" STREQUAL "")))
  FOREACH (_target luaunpanic luaunpanic_static)
    TARGET_LINK_LIBRARIES(${_target} PUBLIC ${CMAKE_DL_LIBS} ${CMAKE_MATH_LIBS})
  ENDFOREACH ()
ENDIF ()
#
# Those definitions have to propagate to those using the library
#
SET (LUA_PUBLIC_CFLAGS)
IF (LUA_32BITS)
  LIST (APPEND LUA_PUBLIC_CFLAGS "-DLUA_32BITS")
ENDIF ()
IF (LUA_USE_C89)
  LIST (APPEND LUA_PUBLIC_CFLAGS "-DLUA_USE_C89")
ENDIF ()

LIST(LENGTH LUA_PUBLIC_CFLAGS LUA_PUBLIC_CFLAGS_LENGTH)
IF (LUA_PUBLIC_CFLAGS_LENGTH GREATER 0)
  FOREACH (_target luaunpanic luaunpanic_static)
    TARGET_COMPILE_DEFINITIONS(${_target} PUBLIC ${LUA_PUBLIC_CFLAGS})
  ENDFOREACH ()
ENDIF ()

#
# Those definitions are private
#
SET (LUA_PRIVATE_C_FLAGS)
IF (CMAKE_C_COMPILER_ID STREQUAL SunPro)
  SET (LUA_PRIVATE_C_FLAGS "-xc99")
ENDIF ()

IF (NOT "x${LUA_PRIVATE_C_FLAGS}" STREQUAL x)
  #
  # Fortunately this will remain local to this CMakeLists.txt -;
  #
  SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${LUA_PRIVATE_C_FLAGS}")
ENDIF ()

###############
# Executables #
###############
MYPACKAGEEXECUTABLE(luaunpanicExe src/lua.c)
MYPACKAGEADDEXECUTABLESTOTESTS(luaunpanicExe)
FOREACH (_target luaunpanicExe luaunpanicExe_static)
  IF (${_target} STREQUAL "luaunpanicExe")
    SET_TARGET_PROPERTIES(${_target} PROPERTIES OUTPUT_NAME luaunpanic)
  ELSE ()
    SET_TARGET_PROPERTIES(${_target} PROPERTIES OUTPUT_NAME luaunpanic_static)
  ENDIF ()
ENDFOREACH ()

MYPACKAGEEXECUTABLE(luaunpanicCompilerExe src/luac.c)
MYPACKAGEADDEXECUTABLESTOTESTS(luaunpanicCompilerExe)
FOREACH (_target luaunpanicCompilerExe luaunpanicCompilerExe_static)
  IF (${_target} STREQUAL "luaunpanicCompilerExe")
    SET_TARGET_PROPERTIES(${_target} PROPERTIES OUTPUT_NAME luaunpanicc)
  ELSE ()
    SET_TARGET_PROPERTIES(${_target} PROPERTIES OUTPUT_NAME luaunpanicc_static)
  ENDIF ()
ENDFOREACH ()

MYPACKAGETESTEXECUTABLE(luaunpanicwrapperTester test/luawrapperTester.c)
MYPACKAGETESTEXECUTABLE(luaunpanicwrapperTester2 test/luawrapperTester2.c)

#########
# Tests #
#########
MYPACKAGECHECK(luaunpanicwrapperTester ${CMAKE_CURRENT_SOURCE_DIR}/test/luawrapperTester.lua)
MYPACKAGECHECK(luaunpanicwrapperTester2 ${CMAKE_CURRENT_SOURCE_DIR}/test/luawrapperTester2.lua)

#############
# Packaging #
#############
MYPACKAGEPACK ("" "Lua 5.3.4 with unpanic support")

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
