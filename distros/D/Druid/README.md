# NAME

Druid - Perl client to Druid.io (http://druid.io)

# VERSION

version 0.003

Table of Contents:

- [Installation & Introductory Examples](#installation)
- [USAGE](#usage)
- [TODO](#todo)
- [License](#license)

Installation
------------

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install


Usage
------------

```perl
my $druid = Druid->new(
	api_url =>"https://druid-broker-hostname-goes-here/druid/v2/?pretty"
);

my $filter_factory          = Druid::Factory::FilterFactory->new();
my $post_aggregator_factory = Druid::Factory::PostAggregatorFactory->new();

my $query = Druid::Query::Timeseries->new( data_source => "cs-tickets-v1") ;

$query = $query
            ->granularity(DAY)
            ->interval('2017-04-02 00:00:00', '2017-04-05 00:00:00')
            ->filter($filter_factory->and([
                $filter_factory->selector('channel', 'phone'),
                $filter_factory->selector('source', 'guest')
            ]))
            ->aggregation(LONG_SUM, 'count', 'count')
            ->aggregation(COUNT, 'rows', 'rows')
            ->post_aggregation($post_aggregator_factory->arithmetic("sample_divide",DIVIDE,[
                $post_aggregator_factory->fieldAccess("count","count"),
                $post_aggregator_factory->fieldAccess('rows','rows')
            ]))
            ->context(SKIP_EMPTY_BUCKETS,"true")
            ->context(TIMEOUT,100)
            ->context(PRIORITY,100)
            ->descending();

my $result = $druid->send($query);

if(!$druid->{error}){
    print STDOUT Dumper $result;
}else{
    print STDOUT Dumper $druid->{error};
}
```

Sample GroupBy Query
```
$query = Druid::Query::GroupBy->new( data_source => "cs-tickets-v1") ;

$query = $query
            ->granularity(ALL)
            ->interval('2017-04-02 00:00:00', '2017-04-05 00:00:00')
            ->group_by_dimensions(['channel', 'source'])
            ->threshold('category')
            ->threshold(5)
            ->metric('count')
            ->aggregation(LONG_SUM, 'count', 'count')
            ->aggregation(COUNT, 'rows', 'rows');

```

Sample TopN Query

```
 $query = $query
             ->granularity(ALL)
             ->interval('2017-04-02 00:00:00', '2017-04-05 00:00:00')
             ->dimension('category')
             ->threshold(5)
             ->metric('count')
             ->aggregation(LONG_SUM, 'count', 'count');

$result = $druid->send($query);
```

Todo
------------
* Testing
* Metadata Queries
* Search Queries
* Query Cancellation
* Admin tasks

License And Copyright
------------

Copyright (C) 2017 Gaurav Kohli

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

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
