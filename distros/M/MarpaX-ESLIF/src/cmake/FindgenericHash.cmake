# Module for locating genericHash, based on ICU module.
#
# Cutomizable variables:
#   GENERICHASH_ROOT_DIR
#     This variable points to the genericHash root directory. On Windows the
#     library location typically will have to be provided explicitly using the
#     -D command-line option. Alternatively, an environment variable can be set.
#
# Read-Only variables:
#   GENERICHASH_FOUND
#     Indicates whether the library has been found.
#
#   GENERICHASH_INCLUDE_DIRS
#     Points to the genericHash include directory.
#
INCLUDE (CMakeParseArguments)
INCLUDE (FindPackageHandleStandardArgs)

SET (_PF86 "ProgramFiles(x86)")
SET (_GENERICHASH_POSSIBLE_DIRS
  ${GENERICHASH_ROOT_DIR}
  "$ENV{GENERICHASH_ROOT_DIR}"
  "C:/genericHash"
  "$ENV{PROGRAMFILES}/genericHash"
  "$ENV{${_PF86}}/genericHash")

SET (_GENERICHASH_POSSIBLE_INCLUDE_SUFFIXES include)

IF (CMAKE_SIZEOF_VOID_P EQUAL 8)
  SET (_GENERICHASH_POSSIBLE_LIB_SUFFIXES lib64)
  SET (_GENERICHASH_POSSIBLE_BIN_SUFFIXES bin64)

  IF (NOT WIN32)
    LIST (APPEND _GENERICHASH_POSSIBLE_LIB_SUFFIXES lib)
    LIST (APPEND _GENERICHASH_POSSIBLE_BIN_SUFFIXES bin)
  ENDIF (NOT WIN32)
ELSE (CMAKE_SIZEOF_VOID_P EQUAL 8)
  SET (_GENERICHASH_POSSIBLE_LIB_SUFFIXES lib)
  SET (_GENERICHASH_POSSIBLE_BIN_SUFFIXES bin)
ENDIF (CMAKE_SIZEOF_VOID_P EQUAL 8)

FIND_PATH (GENERICHASH_ROOT_DIR
  NAMES include/genericHash.h
  PATHS ${_GENERICHASH_POSSIBLE_DIRS}
  DOC "genericHash root directory")

IF (GENERICHASH_ROOT_DIR)
  # Re-use the previous path:
  FIND_PATH (GENERICHASH_INCLUDE_DIR
    NAMES genericHash.h
    PATHS ${GENERICHASH_ROOT_DIR}
    PATH_SUFFIXES ${_GENERICHASH_POSSIBLE_INCLUDE_SUFFIXES}
    DOC "genericHash include directory"
    NO_DEFAULT_PATH)
ELSE (GENERICHASH_ROOT_DIR)
  # Use default path search
  FIND_PATH (GENERICHASH_INCLUDE_DIR
    NAMES genericHash.h
    DOC "genericHash include directory"
    )
ENDIF (GENERICHASH_ROOT_DIR)

IF (GENERICHASH_INCLUDE_DIR)
    SET (GENERICHASH_INCLUDE_DIRS "${GENERICHASH_INCLUDE_DIR}")
ENDIF (GENERICHASH_INCLUDE_DIR)

MARK_AS_ADVANCED (GENERICHASH_ROOT_DIR GENERICHASH_INCLUDE_DIR)

FIND_PACKAGE_HANDLE_STANDARD_ARGS (GENERICHASH
  REQUIRED_VARS
  GENERICHASH_INCLUDE_DIR
  )

IF(GENERICHASH_FOUND)
  MESSAGE(STATUS "-----------------------------------------")
  MESSAGE(STATUS "Setup GENERICHASH:")
  MESSAGE(STATUS "")
  MESSAGE(STATUS "           ROOT_DIR: ${GENERICHASH_ROOT_DIR}")
  MESSAGE(STATUS "        INCLUDE_DIR: ${GENERICHASH_INCLUDE_DIR}")
  MESSAGE(STATUS "-----------------------------------------")
ENDIF()

MARK_AS_ADVANCED (GENERICHASH_FOUND)
