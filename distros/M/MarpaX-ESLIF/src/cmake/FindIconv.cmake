# - Try to find Iconv 
# Once done this will define 
# 
#  ICONV_FOUND - system has Iconv 
#  ICONV_INCLUDE_DIR - the Iconv include directory 
#  ICONV_LIBRARIES - Link these to use Iconv 
#  ICONV_SECOND_ARGUMENT_IS_CONST - the second argument for iconv() is const
# 
include(CheckCXXSourceCompiles)

IF (ICONV_INCLUDE_DIR AND ICONV_LIBRARIES)
  # Already in cache, be silent
  SET(ICONV_FIND_QUIETLY TRUE)
ENDIF (ICONV_INCLUDE_DIR AND ICONV_LIBRARIES)

FIND_PATH(ICONV_INCLUDE_DIR iconv.h) 
 
FIND_LIBRARY(ICONV_LIBRARIES NAMES iconv libiconv libiconv-2 c)
 
IF(ICONV_INCLUDE_DIR AND ICONV_LIBRARIES) 
   SET(ICONV_FOUND TRUE) 
ENDIF(ICONV_INCLUDE_DIR AND ICONV_LIBRARIES) 

set(CMAKE_REQUIRED_INCLUDES ${ICONV_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${ICONV_LIBRARIES})
IF(ICONV_FOUND)
  check_cxx_source_compiles("
  #include <iconv.h>
  int main(){
    iconv_t conv = 0;
    const char* in = 0;
    size_t ilen = 0;
    char* out = 0;
    size_t olen = 0;
    iconv(conv, &in, &ilen, &out, &olen);
    return 0;
  }
" ICONV_SECOND_ARGUMENT_IS_CONST )
ENDIF(ICONV_FOUND)
set(CMAKE_REQUIRED_INCLUDES)
set(CMAKE_REQUIRED_LIBRARIES)

IF(ICONV_FOUND) 
  IF(NOT ICONV_FIND_QUIETLY) 
    MESSAGE(STATUS "Found Iconv: ${ICONV_LIBRARIES}") 
  ENDIF(NOT ICONV_FIND_QUIETLY) 
ELSE(ICONV_FOUND) 
  IF(Iconv_FIND_REQUIRED) 
    MESSAGE(FATAL_ERROR "Could not find Iconv") 
  ENDIF(Iconv_FIND_REQUIRED) 
ENDIF(ICONV_FOUND)

IF (NOT _ICONV_LINK_FLAGS)
  SET (_ICONV_LINK_FLAGS ${ICONV_LIBRARIES})
ENDIF ()

SET (_ICONV_LDFLAGS " ")
FOREACH (_iconv_link_flag ${_ICONV_LINK_FLAGS})
  SET (_ICONV_LDFLAGS "${_ICONV_LDFLAGS} ${_iconv_link_flag}")
ENDFOREACH ()

SET (ICONV_LDFLAGS "${_ICONV_LDFLAGS}" CACHE STRING "Linker flags when linking against Iconv")

IF(ICONV_FOUND)
  MESSAGE(STATUS "-----------------------------------------")
  MESSAGE(STATUS "Setup Iconv:")
  MESSAGE(STATUS "")
  MESSAGE(STATUS "              INCLUDE_DIR: ${ICONV_INCLUDE_DIR}")
  MESSAGE(STATUS "              LINK_FLAGS : ${ICONV_LINK_FLAGS}")
  MESSAGE(STATUS "                LD_FLAGS : ${ICONV_LD_FLAGS}")
  MESSAGE(STATUS " SECOND_ARGUMENT_IS_CONST: ${ICONV_SECOND_ARGUMENT_IS_CONST}")
  MESSAGE(STATUS "-----------------------------------------")
ENDIF()

MARK_AS_ADVANCED(
  ICONV_FOUND
  ICONV_INCLUDE_DIR
  ICONV_LIBRARIES
  ICONV_LINK_FLAGS
  ICONV_LDFLAGS
  ICONV_SECOND_ARGUMENT_IS_CONST
  )
