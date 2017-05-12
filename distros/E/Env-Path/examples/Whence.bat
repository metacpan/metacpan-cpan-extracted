@echo off

REM Wrapper bat script that calls the perl script of the same name with a .pl
REM extension (in the same directory). Can be easily reused by making a copy
REM and renaming the copy to be the same as your new .pl script, except with a
REM .bat extension. In a UNIX environment, symlinks could to the job even better
REM
REM Author: Taylor Jones <taylor.jones@raytheon.com>

REM Get the fully qualified path name of this script
set PLSCRIPT=%~f0
REM Strip off the '.bat' and replace it with nothing.
set PLSCRIPT=%PLSCRIPT:~0,-4%
REM Or replace it with something if preferred:
REM set PLSCRIPT=%PLSCRIPT:~0,-4%.pl

REM Run the resulting perl script.
perl %PLSCRIPT% %*
