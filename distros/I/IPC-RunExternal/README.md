ipc-runexternal
===============

PC::RunExternal is a Perl module for executing external operating system programs more conveniently than with \`\` (backticks) or exec/system, and without all the hassle of IPC::Open3.

IPC::RunExternal allows:

    1) Capture STDOUT and STDERR in scalar variables.
    2) Capture both STDOUT and STDERR in one scalar variable, in the correct order.
    3) Use timeout to break the execution of a program running too long.
    4) Keep user happy by printing something (e.g. '.' or '#') every second.
    5) Not happy with simply printing something? Then execute your own code (function) at every second while the program is running.

Compatible only with Unix family of operating systems.

