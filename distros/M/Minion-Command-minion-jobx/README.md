# Minion-Command-minion-jobx

This module will work the same as Minion::Command::minion::job but with some differences.

## Features

* Display timestamps instead of epoch times.

	    $./script/app minion jobx 1853
	    {
	         "args" => [
	            "/some/path/to/some/file",
	            "/some/other/path/to/some/file"
	          ],
	          "attempts" => 1,
	          "children" => [],
	          "created" => "Wed Aug  3 15:05:00 2016",
	          "delayed" => "Wed Aug  3 15:05:00 2016",
	          "finished" => "Wed Aug  3 15:05:26 2016",
	          "id" => 1853,
	          "parents" => [
	             1852
	           ],
	           "priority" => 0,
	           "queue" => "default",
	           "result" => {
	              "output" => "done"
	           },
	           "retried" => undef,
	           "retries" => 0,
	           "started" => "Wed Aug  3 15:05:05 2016",
	           "state" => "finished",
	           "task" => "task_a",
	           "worker" => 108
	    }
      
* Add the "created", "started" and "finished" times to the list of jobs.  Also display column headings.

	    $./script/app minion jobx -l 5
	    id    state     queue    created                     started                     finished                    task
	    2507  finished  default  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:32 2016]  [Thu Aug 18 16:23:38 2016]  some_task
	    2506  finished  default  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:31 2016]  [Thu Aug 18 16:23:34 2016]  some_task
	    2505  finished  default  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:30 2016]  [Thu Aug 18 16:23:41 2016]  some_task
	    2504  finished  default  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:30 2016]  [Thu Aug 18 16:23:36 2016]  some_task
	    2503  finished  default  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:33 2016]  some_task

## USAGE

  Usage: APPLICATION minion jobx [OPTIONS] [ID]

      ./myapp.pl minion jobx
      ./myapp.pl minion jobx 10023
      ./myapp.pl minion jobx -w
      ./myapp.pl minion jobx -w 23
      ./myapp.pl minion jobx -s
      ./myapp.pl minion jobx -q important -t foo -S inactive
      ./myapp.pl minion jobx -e foo -a '[23, "bar"]'
      ./myapp.pl minion jobx -e foo -P 10023 -P 10024 -p 5 -q important
      ./myapp.pl minion jobx -R -d 10 10023
      ./myapp.pl minion jobx -r 10023

    Options:
      -A, --attempts <number>   Number of times performing this new job will be
                                attempted, defaults to 1
      -a, --args <JSON array>   Arguments for new job in JSON format
      -d, --delay <seconds>     Delay new job for this many seconds
      -e, --enqueue <name>      New job to be enqueued
      -h, --help                Show this summary of available options
      --home <path>             Path to home directory of your application,
                                defaults to the value of MOJO_HOME or
                                auto-detection
      -l, --limit <number>      Number of jobs/workers to show when listing them,
                                defaults to 100
      -m, --mode <name>         Operating mode for your application, defaults to
                                the value of MOJO_MODE/PLACK_ENV or "development"
      -o, --offset <number>     Number of jobs/workers to skip when listing them,
                                defaults to 0
      -P, --parent <id>         One or more jobs the new job depends on
      -p, --priority <number>   Priority of new job, defaults to 0
      -q, --queue <name>        Queue to put new job in, defaults to "default", or
                                list only jobs in this queue
      -R, --retry               Retry job
      -r, --remove              Remove job
      -S, --state <state>       List only jobs in this state
      -s, --stats               Show queue statistics
      -t, --task <name>         List only jobs for this task
      -w, --workers             List workers instead of jobs, or show information
                                for a specific worker


# INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Minion::Command::minion::jobx


# LICENSE AND COPYRIGHT

Copyright (C) 2016 Bob Faist

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

(http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
