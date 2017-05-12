CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
CMAKE_POLICY(SET CMP0003 NEW)
SET(CMAKE_MACOSX_RPATH 1)

PROJECT(geohex3 C)
ADD_SUBDIRECTORY(t EXCLUDE_FROM_ALL)

SET(CMAKE_C_FLAGS "-g -std=gnu99 -O2 -Wall -fPIC -Wno-unused-function ${CMAKE_C_FLAGS}")
SET(CMAKE_EXE_LINKER_FLAGS    "-lm ${CMAKE_EXE_LINKER_FLAGS}")
SET(CMAKE_MODULE_LINKER_FLAGS "-lm ${CMAKE_MODULE_LINKER_FLAGS}")
SET(CMAKE_SHARED_LINKER_FLAGS "-lm ${CMAKE_SHARED_LINKER_FLAGS}")

INCLUDE_DIRECTORIES(include lib/include)

ADD_LIBRARY(geohex3 STATIC lib/geohex3.c)
TARGET_LINK_LIBRARIES(geohex3 m)

ADD_EXECUTABLE(examples-get-zone-by-code examples/get-zone-by-code.c)
TARGET_LINK_LIBRARIES(examples-get-zone-by-code geohex3)
SET_TARGET_PROPERTIES(examples-get-zone-by-code PROPERTIES EXCLUDE_FROM_ALL 1)

ADD_EXECUTABLE(examples-get-zone-by-latlng examples/get-zone-by-latlng.c)
TARGET_LINK_LIBRARIES(examples-get-zone-by-latlng geohex3)
SET_TARGET_PROPERTIES(examples-get-zone-by-latlng PROPERTIES EXCLUDE_FROM_ALL 1)

ADD_EXECUTABLE(examples-get-hex-polygon-by-code examples/get-hex-polygon-by-code.c)
TARGET_LINK_LIBRARIES(examples-get-hex-polygon-by-code geohex3)
SET_TARGET_PROPERTIES(examples-get-hex-polygon-by-code PROPERTIES EXCLUDE_FROM_ALL 1)

CMAKE_POLICY(PUSH)
IF(POLICY CMP0037)
    CMAKE_POLICY(SET CMP0037 OLD)
ENDIF()
ADD_CUSTOM_TARGET(test prove t
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS geohex3 official.t)
CMAKE_POLICY(POP)

INSTALL(TARGETS geohex3 DESTINATION lib)
INSTALL(DIRECTORY include/ DESTINATION include FILES_MATCHING PATTERN "*.h")
