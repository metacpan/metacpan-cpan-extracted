# File::Copy::Recursive round 2


I have gotten much love from this module but it has suffered from neglect. Partly because I am busy and partly that the code is crusty (it was done back when package globals were all the rage–those of you with CGI tatoos know what I am talking about ;)).

So I am finally making a plan to give this the attention it deserves.

## Goals

1. Fix the [RTs](https://rt.cpan.org/Dist/Display.html?Queue=File-Copy-Recursive) and write tests (Issue #3) (pull requests welcome!)
2. Modernize the code and interface–Issue #2
3. Do not break existing consumers of the legacy interface–Issue #1
