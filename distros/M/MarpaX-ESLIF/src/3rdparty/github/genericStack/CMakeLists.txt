CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
PROJECT(genericStack VERSION 1.1.9 LANGUAGES C)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART ()

MYPACKAGECONFIG(test/config.h.in test/config.h)

###############
# Executables #
###############
MYPACKAGETESTEXECUTABLE (genericStackTester                          test/genericStack.c)
MYPACKAGETESTEXECUTABLE (genericStackTesterDefaultInitialStack       test/genericStack_defaultinitialstack.c)
MYPACKAGETESTEXECUTABLE (genericStackTesterSmallInitialStack         test/genericStack_smallinitialstack.c)
MYPACKAGETESTEXECUTABLE (genericStackTesterNoInitialStack            test/genericStack_noinitialstack.c)
MYPACKAGETESTEXECUTABLE (genericStackTesterMemset                    test/genericStackMemset.c)
MYPACKAGETESTEXECUTABLE (genericStackTesterDefaultInitialStackMemset test/genericStack_defaultinitialstackMemset.c)
MYPACKAGETESTEXECUTABLE (genericStackTesterSmallInitialStackMemset   test/genericStack_smallinitialstackMemset.c)
MYPACKAGETESTEXECUTABLE (genericStackTesterNoInitialStackMemset      test/genericStack_noinitialstackMemset.c)

#########
# Tests #
#########
MYPACKAGECHECK(genericStackTester)
MYPACKAGECHECK(genericStackTesterDefaultInitialStack)
MYPACKAGECHECK(genericStackTesterSmallInitialStack)
MYPACKAGECHECK(genericStackTesterNoInitialStack)
MYPACKAGECHECK(genericStackTesterMemset)
MYPACKAGECHECK(genericStackTesterDefaultInitialStackMemset)
MYPACKAGECHECK(genericStackTesterSmallInitialStackMemset)
MYPACKAGECHECK(genericStackTesterNoInitialStackMemset)

#############
# Packaging #
#############
MYPACKAGEPACK("" "Generic Stack")

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
