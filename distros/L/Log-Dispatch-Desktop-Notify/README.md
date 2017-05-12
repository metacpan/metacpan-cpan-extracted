Log::Dispatch::Desktop::Notify - Log::Dispatch notification backend using Desktop::Notify
=========================================================================================

[![Build Status](https://travis-ci.org/mmitch/log-dispatch-desktop-notify.svg?branch=master)](https://travis-ci.org/mmitch/log-dispatch-desktop-notify)
[![Coverage Status](https://codecov.io/github/mmitch/log-dispatch-desktop-notify/coverage.svg?branch=master)](https://codecov.io/github/mmitch/log-dispatch-desktop-notify?branch=master)
[![GPL 2+](https://img.shields.io/badge/license-GPL%202%2B-blue.svg)](http://www.gnu.org/licenses/gpl-2.0-standalone.html)


what
----

Log::Dispatch::Desktop::Notify a backend for
[Log::Dispatch](https://metacpan.org/pod/Log::Dispatch) that displays
messages via the Desktop Notification Framework (think `libnotify`)
using [Desktop::Notify](https://metacpan.org/pod/Desktop::Notify).


example
-------

```perl
use Log::Dispatch;
use Log::Dispatch::Desktop::Notify;

my $log = Log::Dispatch->new();

$log->add( Log::Dispatch::Desktop::Notify->new(
             min_level => 'warning'
           ));

$log->log( level => 'warning', message => 'a problem!' );
```


installation
------------

The latest release of Log::Dispatch::Desktop::Notify can be installed
directly from CPAN, eg. via

    $ cpan -i Log::Dispatch::Desktop::Notify

or

    $ cpanm Log::Dispatch::Desktop::Notify


building
--------

To build and install the current development version of
Log::Dispatch::Desktop::Notify, you need to have Dist::Zilla
installed.  Run the ``dzil`` command - if it is available, Dist::Zilla
should be installed.

To install or upgrade Dist::Zilla use

    $ cpan -i Dist::Zilla

or

    $ cpanm Dist::Zilla

Then clone this repository, enter it and start the install process:

    $ git clone https://github.com/mmitch/log-dispatch-desktop-notify.git
    $ cd log-dispatch-desktop-notify
    $ dzil install

Any missing dependencies should be reported automatically and can be
installed by

    $ dzil authordeps --missing | cpanm
    $ dzil listdeps --missing | cpanm

Afterwards, try the installation again with

    $ dzil install


where to get it
---------------

Log::Dispatch::Desktop::Notify source is hosted at
https://github.com/mmitch/log-dispatch-desktop-notify  
The latest released version is available on CPAN at
https://metacpan.org/release/Log-Dispatch-Desktop-Notify


copyright
---------

Copyright (C) 2017  Christian Garbs <mitch@cgarbs.de>  
Licensed under GNU GPL v2 or later.
