CMAKE_MINIMUM_REQUIRED (VERSION 3.0.0 FATAL_ERROR)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  INCLUDE ("3rdparty/github/cmake-utils/cmake/MyPackageBootstrap.cmake")
ENDIF ()
MYPACKAGESTART (genericStack 1 0 53)

###############
# Executables #
###############
MYPACKAGETESTEXECUTABLE (genericStackTester                    test/genericStack.c)
MYPACKAGETESTEXECUTABLE (genericStackTesterDefaultInitialStack test/genericStack_defaultinitialstack.c)
MYPACKAGETESTEXECUTABLE (genericStackTesterSmallInitialStack   test/genericStack_smallinitialstack.c)
MYPACKAGETESTEXECUTABLE (genericStackTesterNoInitialStack      test/genericStack_noinitialstack.c)

#########
# Tests #
#########
MYPACKAGECHECK(genericStackTester)
MYPACKAGECHECK(genericStackTesterDefaultInitialStack)
MYPACKAGECHECK(genericStackTesterSmallInitialStack)
MYPACKAGECHECK(genericStackTesterNoInitialStack)

#############
# Packaging #
#############
MYPACKAGEPACK("" "Generic Stack")

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
