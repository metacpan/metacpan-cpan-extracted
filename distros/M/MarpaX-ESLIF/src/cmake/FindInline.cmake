# Inspired from /usr/share/autoconf/autoconf/c.m4
#
# Note: __forceinline also exist, but is not recommended if the C compiler
#       think it is not worth inlining
#
MACRO (FINDINLINE)
  FOREACH (KEYWORD "inline" "__inline__" "inline__" "__inline")
    MESSAGE(STATUS "Looking for ${KEYWORD}")
    TRY_COMPILE (C_HAS_${KEYWORD} ${CMAKE_CURRENT_BINARY_DIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/cmake/inline.c
      COMPILE_DEFINITIONS "-DC_INLINE=${KEYWORD}")
    IF (C_HAS_${KEYWORD})
      MESSAGE(STATUS "Looking for ${KEYWORD} - found")
      SET (C_INLINE ${KEYWORD})
      BREAK ()
    ENDIF ()
  ENDFOREACH ()
ENDMACRO()
IF (NOT C_INLINE)
  FINDINLINE ()
  SET (C_INLINE "${C_INLINE}" CACHE STRING "C inline")
  MARK_AS_ADVANCED (C_INLINE)
  IF ("${C_INLINE}" STREQUAL "inline")
    MESSAGE (STATUS "  C_INLINE_IS_INLINE is true")
    SET (C_INLINE_IS_INLINE "true" CACHE STRING "C inline is inline")
  ELSE ()
    MESSAGE (STATUS "  C_INLINE_IS_INLINE is false")
    SET (C_INLINE_IS_INLINE FALSE CACHE BOOL "C inline is inline")
  ENDIF ()
  MARK_AS_ADVANCED (C_INLINE_IS_INLINE)
  MESSAGE (STATUS "  C inlining is done with ${C_INLINE}")
ENDIF (NOT C_INLINE)
