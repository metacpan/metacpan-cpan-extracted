# Github

Pull requests to Github repository of this module are welcome

https://github.com/pavelsr/devel-tray

Here you can also report bugs and issues

# Some notes about module arch and methods

## Auto splice childs

If we filter some frame from trace we should also filter all its childs

## Public module detection

To detect is module public or no *_is_cpan_published* method used

Detection is not trivial so I added *$severity* parameter

Some examples:

There is no distro Sub::Defer but it's part of Sub-Quote distro

Method::Generate::Constructor is part of Moo package

main - all root script sub calls will be shown with main:: namespace, but main module is part of Nagios-Plugin-POP3

distro

Session - published on CPAN, but each project can have package with same name

# TO-DO

To distinguish is module public or it's better to base on cpanfile and @INC location if no cpanfile
 
Also good idea is to check config of popular package managers - cpan, cpanm and cpm