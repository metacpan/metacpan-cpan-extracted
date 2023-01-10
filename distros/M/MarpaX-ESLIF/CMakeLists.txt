CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
# marpaESLIFPerl version is synced with marpaESLIF
PROJECT(marpaESLIFPerl VERSION ${marpaESLIF_VERSION} LANGUAGES C CXX)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("../../../3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART ()

FILE (GLOB_RECURSE MARPAESLIFPERL_SRC_PM src "lib/*.pm")
SET  (             MARPAESLIFPERL_SRC_XS     "ESLIF.xs")
FILE (GLOB_RECURSE MARPAESLIFPERL_SRC_T  src "t/*.t")
SET  (ETC_COPYDIRS_PL etc/copyDirs.PL)

ADD_CUSTOM_TARGET (marpaESLIFPerlCopy ${CMAKE_COMMAND} -E echo "${PERL_EXECUTABLE} etc/copyDirs.PL"
  COMMAND ${PERL_EXECUTABLE} etc/copyDirs.PL
  DEPENDS ${ETC_COPYDIRS_PL} ${MARPAESLIFPERL_SRC_PM} ${MARPAESLIFPERL_SRC_XS} ${MARPAESLIFPERL_SRC_T} dist.ini
  )

SET (DIST_ZILLA_APP_RUN "\"Dist::Zilla::App->run\"")
#
# On windows, saying dzil goes to the perl "script" within ADD_TEST !
# For coherency, we replace everywhere
# dzil
# by
# ${PERL_EXECUTABLE} -MDist::Zilla::App -e ${DIST_ZILLA_APP_RUN} --
#

# -----
# Clean
# -----
ADD_CUSTOM_TARGET (marpaESLIFPerlClean ${CMAKE_COMMAND} -E echo "... ${PERL_EXECUTABLE} -MDist::Zilla::App -e ${DIST_ZILLA_APP_RUN} -- clean --verbose"
  COMMAND ${PERL_EXECUTABLE} -MDist::Zilla::App -e ${DIST_ZILLA_APP_RUN} -- clean --verbose
  COMMAND ${CMAKE_COMMAND} -E echo "${CMAKE_COMMAND} -E remove_directory src"
  COMMAND ${CMAKE_COMMAND} -E remove_directory src
  )

# -------
# Package
# -------
ADD_CUSTOM_TARGET (marpaESLIFPerlPackage ALL ${CMAKE_COMMAND} -E echo "... ${PERL_EXECUTABLE} -MDist::Zilla::App -e ${DIST_ZILLA_APP_RUN} -- build --verbose"
  COMMAND ${PERL_EXECUTABLE} -MDist::Zilla::App -e "${DIST_ZILLA_APP_RUN}" -- build --verbose
  DEPENDS marpaESLIFPerlCopy
  )

# -------------
# Trial Release
# -------------
ADD_CUSTOM_TARGET (marpaESLIFPerlReleaseTrial ${CMAKE_COMMAND} -E echo "${PERL_EXECUTABLE} -MDist::Zilla::App -e ${DIST_ZILLA_APP_RUN} -- release --trial --verbose"
  COMMAND ${PERL_EXECUTABLE} -MDist::Zilla::App -e "${DIST_ZILLA_APP_RUN}" -- release --trial --verbose
  DEPENDS marpaESLIFPerlCopy
  )

# -------
# Release
# -------
ADD_CUSTOM_TARGET (marpaESLIFPerlRelease ${CMAKE_COMMAND} -E echo "${PERL_EXECUTABLE} -MDist::Zilla::App -e ${DIST_ZILLA_APP_RUN} -- release --verbose"
  COMMAND ${PERL_EXECUTABLE} -MDist::Zilla::App -e "${DIST_ZILLA_APP_RUN}" -- release --verbose
  DEPENDS marpaESLIFPerlCopy
  )

# -------
# Test
# -------
ADD_CUSTOM_TARGET (marpaESLIFPerlTest ${CMAKE_COMMAND} -E echo "${PERL_EXECUTABLE} -MDist::Zilla::App -e ${DIST_ZILLA_APP_RUN} -- test --verbose"
  COMMAND ${PERL_EXECUTABLE} -MDist::Zilla::App -e "${DIST_ZILLA_APP_RUN}" -- test --verbose
  DEPENDS marpaESLIFPerlCopy
  )

# -------
# Xtest
# -------
ADD_CUSTOM_TARGET (marpaESLIFPerlXtest ${CMAKE_COMMAND} -E echo "${PERL_EXECUTABLE} -MDist::Zilla::App -e ${DIST_ZILLA_APP_RUN} -- xtest --verbose"
  COMMAND ${PERL_EXECUTABLE} -MDist::Zilla::App -e "${DIST_ZILLA_APP_RUN}" -- xtest --verbose
  DEPENDS marpaESLIFPerlCopy
  )

# -----
# Check
# -----
# Quite painful but apparently CTest revisit all parameters differently v.s. the OS...
ADD_TEST (marpaESLIFPerlTest ${PERL_EXECUTABLE} -MDist::Zilla::App -e "Dist::Zilla::App->run" -- test --verbose)
ADD_DEPENDENCIES (check marpaESLIFPerlCopy)
