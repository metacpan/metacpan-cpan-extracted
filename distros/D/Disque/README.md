perl-disque
===
Perl client for Disque, an in-memory, distributed job queue

Fast usage:
---
For those who want to see the things working ***right now***.

Open new terminal and do:

```
$ perl examples/producer.pl
```
Open another terminal and do:
```
$ perl examples/consumer.pl
```
You will start sawing the new jobs comming at 'consumer' terminal.
Also you can setup multiple instances of disque cluster and shutdown 
some of them and you will see how the clients will automatic reconnect 
to any available disque server.

Usage
---

Connection:

perl-disque will try to connect to any available server in the order is have been set,
if there is any disque instance available, the client will generate a connection error and will abort.

if you not spicify any server in conection `new()` by default will only connect to '127.0.0.1:7711'.

```perl
use Disque;
my $disque = Disque->new();
```

To send new job just do

```perl
$disque->add_job('test','job_1', 0);
```


Documentation
---

You can use this library with single or multi-node clusters.

#### Connection:

When you invoke "new()" you can choose in which method you will connect to the cluster,
of course, this only will happen if ther is more than 1 node spicified.

By default, as Salvatore [specified](https://github.com/antirez/disque#client-libraries)
in the doc, the lib will try to connect to any available server in a randomly way.

But also if you won't to connect to the server randomly you can specify 
the param "disable_random_connect => 1" in new() sub, for example: 
```perl
my $disque = Disque->new(
	servers => ['localhost:7711', 'localhost:7712', 'localhost:7713'],
	disable_random_connect => 1
);
```
So you will connect into the cluster in the order that you have set the nodes.

#### Debugging:
You can set global environment variable:
$ export DISQUE_DEBUG=1

Or you can specify debug at connection:
```perl
my $disque = Disque->new(debug => 1);
```

Status
---
The commands that are allready available are:
`add_job` `get_job` `ack_job` `fast_ack` `qlen` `qpeek` `enqueue`
`dequeue` `del_job` `show` `jscan` `qstat` `qscan`


Installation
---

```
$ cpan install Disque
```

TODO
---
* Create tests
* Add more documentation in pm module


License
---
See [LICENSE](https://github.com/lovelle/perl-disque/blob/master/LICENSE).

Thanks
---
* Big thanks to Salvatore Sanfilippo aka [antirez](http://antirez.com/) for share his work.
* The people who contributed and did [perl-redis](https://github.com/PerlRedis/perl-redis) module.
