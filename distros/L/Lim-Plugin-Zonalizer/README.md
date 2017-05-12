# API v1

This describes the API version 1 for Zonalizer.  The URLs in this description
assumes that Lim operates without any prefixes and all structure examples are
in JSON.

## Data Model Overview

The data model is structured with a top level object called `analyze` which
contains information about the DNS tests that has been performed for a fully
qualified domain name (FQDN).

An analyze is kept in memory while its queued or analyzing then it's store into
a database for future access and long term storage.

All analysis are kept in spaces for seperation, see Spaces for more information.

## Data Types

The following data types are used:

* `uuid`: A version 4 UUID.
* `string`: An UTF8 string.
* `integer`: A signed big integer.
* `float`: A float.
* `href`: An URL pointing to another object or objects as according to HATEOAS.
* `datetime`: An UTC Unix Timestamp integer.

## HATEOAS

By default all URLs are HATEOAS but it can be disable via configuration or by
setting `base_url` to false (0) in the request for any call that returns objects
with URLs.

Example:

```
GET /zonalizer/1/analysis?base_url=0
```

## Pagination

All calls returning a list of objects will have the capabilities to return
paginated result using cursors.

The following URI query string options can be used:

* `limit`: This is the number of individual objects that are returned in each
  page, default and max limit is configurable.
* `before`: This is the cursor that points to the start of the page of data that
  has been returned.
* `after`: This is the cursor that points to the end of the page of data that
  has been returned.
* `sort`: The field name in the corresponding objects being returned that the
  result should be sorted on.
* `direction`: The direction of the result in conjunction with `sort`, can be
  `ascending` or `descending`.  Default is ascending.

Example:

```
GET /zonalizer/1/analysis?limit=100&after=cursor
GET /zonalizer/1/analysis?limit=10&sort=created&direction=descending
```

For each paginated result the following object is also included:

```
{
  ...
  "paging": {
    "cursors": {
      "after": "string",
      "before": "string"
    },
    "previous": "href",
    "next": "href"
  }
}
```

* `before`: This is the cursor that points to the start of the page of data that
  has been returned.
* `after`: This is the cursor that points to the end of the page of data that
  has been returned.
* `next`: The full API query that will return the next page of data.  If not
  included, this is the last page of data.
* `previous`: The full API query that will return the previous page of data.
  If not included, this is the first page of data.

## Configuration

Following configuration parameters exists and can be configured via Lim's YAML
config files.

### zonalizer

The following paramters can be configured below the root entry `zonalizer`.

#### base_url

A bool that controls if the base URL is included in the HATEOAS output.

#### custom_base_url

A string with a custom base URL that will be used if `base_url` is true, this
is helpful if Zonalizer is run behind load balancer or session divider.

#### db_driver

A string with the database driver to use.

#### db_conf

A hash this the database driver configuration, see Database Configuration.

#### default_limit

An integer with the default number of objects to return for calls that return
a list of objects.

#### max_limit

An integer with the maximum number of objects to return for calls that return
a list of objects, the given `limit` may not be larger then this and if it is
then the limit will be `max_limit`.

#### allow_ipv4

An integer which determines whether (1) or not (0) IPv4 is allowed to be used
for analyzing.

#### allow_ipv6

An integer which determines whether (1) or not (0) IPv6 is allowed to be used
for analyzing.

#### test_ipv4

An integer which determines whether (1) or not (0) to use IPv4 for analyzing if
not specified by the request.  Will be forced off (0) if IPv4 analyzing is not
allowed (`allow_ipv4`).

#### test_ipv6

An integer which determines whether (1) or not (0) to use IPv6 for analyzing if
not specified by the request.  Will be forced off (0) if IPv6 analyzing is not
allowed (`allow_ipv6`).

#### max_ongoing

The maximum number of ongoing analysis that can exist at the same time.  If this
is higher then the number of threads in the collector then the collector will
queue work.

#### allow_undelegated

An integer which determines whether (1) or not (0) undelegated analysis are
allowed to be run.

#### force_undelegated

An integer which determines whether (1) or not (0) undelegated information must
be giving in other to run any analysis.

#### max_undelegated_ns

An integer with the maximum number of `ns` objects that can be given in an
analysis request.

#### max_undelegated_ds

An integer with the maximum number of `ds` objects that can be given in an
analysis request.

#### allow_meta_data

An integer which determines whether (1) or not (0) meta data is allowed to be
added to an analysis.

#### max_meta_data_entries

A positive integer with the maximum number of meta data entries that can be
added to an analysis.

#### max_meta_data_entry_size

A positive integer with the maximum size of a meta data entry, this is both
`key` and `value` combined.

#### collector

The following parameters are available to configure the collector.

##### exec

The path to the Zonalizer collector (zonalizer-collector).

##### config

Path to the Zonemaster configuration file to use.

##### policy

Path to the Zonemaster policy file to use.

##### sourceaddr

Local IP address that the test engine should try to send its requests from.

##### threads

Number of threads to start.

##### policies

An array of different policies that can be used, each policy starts its own
collector. For the optional options that are not given, if they are specified in
the global collector configuration then that value will be used.

Per hash in array the following options can be used:

* `name`: An unique name for the policy, must match Perl regexp [\w-]+.
* `display`: A display friendly name for the policy.
* `description`: A description what the policy would be used for.  (optional)
* `exec`: The path to the Zonalizer collector (zonalizer-collector).  (optional)
* `config`: Path to the Zonemaster configuration file to use.  (optional)
* `policy`: Path to the Zonemaster policy file to use.
* `sourceaddr`: Local IP address that the test engine should try to send its
  requests from.  (optional)
* `threads`: Number of threads to start.  (optional)

Example configuration:

```
---
zonalizer:
  collector:
    policies:
      - name: iana
        display: IANA Policy
        description: A policy specific for TLDs
        policy: /usr/share/perl5/auto/share/dist/Zonemaster/iana-profile.json
```

### Configuration example with defaults

```
---
zonalizer:
  base_url: 1
  db_driver: Memory
  default_limit: 10
  max_limit: 10
  allow_ipv4: 1
  allow_ipv6: 1
  test_ipv4: 1
  test_ipv6: 1
  max_ongoing: 5
  allow_undelegated: 1
  force_undelegated: 0
  max_undelegated_ns: 10
  max_undelegated_ds: 20
  allow_meta_data: 0
  max_meta_data_entries: 42
  max_meta_data_entry_size: 512
  collector:
    exec: zonalizer-collector
    threads: 5
```

## Spaces

A space is used as a seperation of analysis and is given as an optional option
to most calls, see Calls.

If given, calls will only create or return analysis for that corresponding
space.

If not given, calls will use the default configurable space or the "null" space.

The `id` of an analyze is unique within the corresponding space.

The "null" space is a reference to an unset space which, depending on the
database backend, can be `null`, `undef`, empty string or otherwise an unset
variable.

As an example; To separate a web app from a batch script, the web app may set
the space to "web" while the batch script sets it to "batch".  In this way they
will not pollute each other spaces.

## Undelegated Analyzing

Undelegated analyzing are done by manually giving the nameserver (see `ns`
object) and delegation signer (optional, see `ds` object) information that will
override DNS information looked up during analyzing.

Example senario taken from the Zonemaster project:

> An undelegated domain test is a test performed on a domain that may, or may
> not, be fully published in the DNS. This can be quite useful if one is going
> to move one's domain from one registrar to another. For example, if you want
> to move your zone example.com from the nameserver "ns.example.com" to the
> nameserver "ns.example.org". In this scenario one could perform an undelegated
> domain test providing the zone (example.com) and the nameserver you are moving
> to (ns.example.org) BEFORE you move your domain. When the results of the test
> are colour coded in green one can be fairly certain that the domain's new
> location is supposed to be replying to queries . However there might still be
> other problems in the zone data itself that this test is unaware of.

## Calls

### GET /zonalizer/1/version

Get the version of Zonalizer, Zonemaster and all Zonemaster test modules.

```
{
  "version": "string",
  "zonemaster": {
    "version": "string",
    "tests": [
      { "name": "string", "version": "string" },
      { "name": "string", "version": "string" },
      { "name": "string", "version": "string" },
      ...
    ]
  }
}
```

### GET /zonalizer/1/status

Get status about API and analysis.

```
{
   "api" : {
      "requests" : 501,
      "errors" : 0
   },
   "analysis" : {
      "ongoing" : 0,
      "completed" : 5,
      "failed" : 0
   }
}
```

* `api.requests`: The number of API requests processed, this includes any kind
  of API call.
* `api.errors`: The number of API errors.
* `analysis.ongoing`: Number of currently ongoing analysis.
* `analysis.completed`: Number of completed analysis.
* `analysis.failed`: Number of failed analysis.

### GET /zonalizer/1/analysis[?ongoing=bool&results=bool&lang=string&search=string&space=string]

Get a list of all analysis that ongoing or in the database for Zonalizer.
See `analyze` under Objects for description of the analyze object.

When showing ongoing analysis:
- Following options are ignored: `before`, `after`, `sort`, `direction` and
  `search`.
- Pagination does not work.
- Sorting of analysis is fixed on `updated` in a descending order.

The following fields are sortable: `fqdn`, `created` and `updated`.

```
{
  "analysis": [
    analyze,
    analyze,
    ...
  ],
  "paging": ...
}
```

* `ongoing`: If true (1), show only ongoing analysis.  Default false (0).
* `results`: If true (1), include `results` in the `analyze` objects in the
  response.  Default false (0).
* `lang`: Specify the language (cc_CC) to use when generating the `message` in
  the `result` object and in the `error` object, default en_US.
* `search`: A string with the "FQDN" to search/filter on.  See Search for more
  information.
* `space`: A string that identifies a unique space for analysis, see Spaces for
  more information.  (optional)

### DELETE /zonalizer/1/analysis[?space=string]

Delete all analysis.  Returns HTTP Status 2xx on success and 4xx/5xx on error.

* `space`: A string that identifies a unique space for analysis, see Spaces for
  more information.  (optional)

### POST /zonalizer/1/analysis?fqdn=string[&options...]

Initiate a new analysis for a given zone.  See `analyze` under Objects for
description of the analyze object.

* `fqdn`: A string with the FQDN to analyze.  (required)
* `policy`: The policy to use for the analyze.  (optional)
* `ipv4`: If true (1), run the analysis over IPv4.  If false (0), do not run
  the analysis over IPv4.  (optional)
* `ipv6`: If true (1), run the analysis over IPv6.  If false (0), do not run
  the analysis over IPv6.  (optional)
* `space`: A string that identifies a unique space for analysis, see Spaces for
  more information.  (optional)
* `ns`: An array of nameserver objects, see `ns` object and Undelegated
  Analyzing for more information.
* `ds`: An array of delegation signer objects, see `ds` object and Undelegated
  Analyzing for more information.
* `meta_data`: An array of meta data objects, see `meta_data` object for more
  information.

### GET /zonalizer/1/analysis/:id[?results=bool&lang=string&space=string]

Get information about an analyze.  See `analyze` under Objects for description
of the analyze object.

* `id`: The ID of the analyze.
* `results`: If true (1), include `results` in the `analyze` objects in the
  response. Default true (1).
* `lang`: Specify the language (cc_CC) to use when generating the `message` in
  the `result` object and in the `error` object, default en_US.
* `space`: A string that identifies a unique space for analysis, see Spaces for
  more information.  (optional)

### GET /zonalizer/1/analysis/:id[?last_results=bool&lang=string&space=string]

Get information about an analyze and include a set of the last results.
See `analyze` under Objects for description of the analyze object.

* `id`: The ID of the analyze.
* `last_results`: An integer with the number of results to include.
* `lang`: Specify the language (cc_CC) to use when generating the `message` in
  the `result` object and in the `error` object, default en_US.
* `space`: A string that identifies a unique space for analysis, see Spaces for
  more information.  (optional)

### GET /zonalizer/1/analysis/:id/status[&space=string]

Only get status information about an analyze, this call is optimal for polling.

* `id`: The ID of the analyze.
* `space`: A string that identifies a unique space for analysis, see Spaces for
  more information.  (optional)

Returns the following:

```
{
  "status": "string",
  "progress": integer,
  "updated": datetime
}
```

* `status`: The status of the check, see Check Statuses.
* `progress`: The progress of the check as an integer with the percent of
  completion.

### DELETE /zonalizer/1/analysis/:id[&space=string]

Delete an analyze.  Returns HTTP Status 2xx on success and 4xx/5xx on error.

* `id`: The ID of the analyze.
* `space`: A string that identifies a unique space for analysis, see Spaces for
  more information.  (optional)

### GET /zonalizer/1/policies

Get a list of all policies that are configured. See `policy` under Objects for
description of the policy object.

```
{
  "policies": [
    policy,
    policy,
    policy,
    ...
  ]
}
```

### GET /zonalizer/1/policy/:name

Get information about a policy. See `policy` under Objects for description of
the policy object.

* `name`: The name of the policy.

## Search

The search string work in two different ways.

### Search by FQDN

If the string is a FQDN (`example.com`, `com.`) then the list of
analysis returned will only be for that FQDN.

### Search by domain

If the string is a FQDN but includes a leading dot (`.example.com`, `.com.`)
then the list of analysis returned will be for that FQDN and any other analysis
that includes the domain.

As an example; `.com` will return all FQDNs that ends with `.com` including
`com.` itself.

## Objects

### analyze

The main analyze object which may include all results from Zonemaster.

```
{
  "id": "uuid",
  "fqdn": "string",
  "policy": policy,
  "url": "href",
  "status": "string",
  "error": error,
  "progress": integer,
  "created": datetime,
  "updated": datetime,
  "results": [
    result,
    result,
    ...
  ],
  "summary": {
    "notice": integer,
    "warning": integer,
    "error": integer,
    "critical": integer
  },
  "ipv4": integer,
  "ipv6": integer,
  "ns": [
    ns,
    ns,
    ...
  ],
  "ds": [
    ds,
    ds,
    ...
  ],
  "meta_data": [
    meta_data,
    meta_data,
    ...
  ]
}
```

* `id`: The UUID of the analyze.
* `fqdn`: The FQDN of the analyze.
* `policy`: The policy used for the analyze, see `policy` under Objects.
  (optional)
* `url`: The URL to this object.
* `status`: The status of the check, see Check Statuses.
* `error`: An object describing an error, see `error` under Objects.  (optional)
* `progress`: The progress of the check as an integer with the percent of
  completion.
* `created`: The date and time of when the object was created.
* `updated`: The date and time of when the object was last updated.
* `results`: An array containing `result` objects.  (optional)
* `summary.notice`: The number of NOTICE results in `results`.
* `summary.warning`: The number of WARNING results in `results`.
* `summary.error`: The number of ERROR results in `results`.
* `summary.critical`: The number of CRITICAL results in `results`.
* `ipv4`: If true (1), the analysis ran over IPv4.
* `ipv6`: If true (1), the analysis ran over IPv6.
* `ns`: An array of nameserver objects, see `ns` object and Undelegated
  Analyzing for more information.  (optional)
* `ds`: An array of delegation signer objects, see `ds` object and Undelegated
  Analyzing for more information.  (optional)
* `meta_data`: An array of meta data objects, see `meta_data` under Objects.
  (optional)

### error

An object describing an error.

```
{
  "code": "string",
  "message": "string"
}
```

* `code`: A string with the error code, see Analyze Errors.
* `message`: A textual description of the error.

### result

A result object which is taken unprocessed from Zonemaster, description here may
vary depending on the version of Zonemaster you are running.

This documentation corresponds to version 1.0.7 of Zonemaster.

```
{
  "_id": integer,
  "args": {
    ...
  },
  "level": "string",
  "module": "string",
  "tag": "string",
  "timestamp": float,
  "message": "string"
}
```

* `_id`: A basic counter for each result object in the set, starts at zero (0).
  This is an additional paramter which is added by Zonalizer.
* `args`: An object with the arguments used for the specific result.
* `level`: The serverity of the result, see Result Levels.
* `module`: The Zonemaster module that produced the result.
* `tag`: A describing tag of the result, this is used by Zonemaster to generate
  the message.
* `timestamp`: A timestamp for when the result was generated, this is a float
  value of the number of seconds since the start of the analysis.
* `message`: A describing message of the result.

### ns

A nameserver object that is used for undelegated analysis.

```
{
  "fqdn": "string",
  "ip": "string"
}
```

* `fqdn`: The nameserver's FQDN.
* `ip`: An IP-address to use instead of doing a lookup of the nameserver's FQDN.
  (optional)

### ds

A delegation signer records that is used for undelegated analysis.  The four
pieces of data should be in the same format they would have in a zone file.

For a description of the object properties below please see section 5 in
RFC 4034.

```
{
  "keytag": "string",
  "algorithm": "string",
  "type": "string",
  "digest": "string"
}
```

### meta_data

A meta data object. The number of object that can exist per analyze is determend
by `max_meta_data_entries` and the total length of the `key` and `value`
together is determend by `max_meta_data_entry_size`.

```
{
  "key": "string",
  "value": "string"
}
```

* `key`: A string with the key of the meta data.
* `value`: A string with the value of the meta data.

### policy

A policy object that can describe what the policy is for.

```
{
  "name": "string",
  "display": "string",
  "description": "string"
}
```

* `name`: An unique name of the policy.
* `display`: A display friendly name of the policy.
* `description`: A description what the policy would be used for.  (optional)

## Analyze Statuses

* `reserved`: indicates that the analyze has been reserved in the database and
  is ongoing.
* `queued`: indicates that the analyze has been queued and waiting on a worker
  to start processing it.
* `analyzing`: indicates that the analyze has been taken up by a worker and its
  processing it.
* `done`: indicates that the analyze is done and results are available.
* `failed`: indicates that the analyze failed, check `error` and `results` for
  an `error` why it failed.
* `stopped`: indicates that the analyze was stopped, check `error` and `results`
  for an `error` why it was stopped.
* `unknown`: indicates that the analyze may not have any results.

## Result Levels

The following result levels can be given by Zonemaster, please see Zonemaster
documentation for more details.

- DEBUG3
- DEBUG2
- DEBUG
- INFO
- NOTICE
- WARNING
- ERROR
- CRITICAL

## Errors

Errors that are related to the communication with the API are returned as JSON
in a `Lim::Error` format and other errors which are related to the processing
of analysis are set in the `error` object.

For example this is a internal server error (500):

```
{
  "Lim::Error" : {
    "module" : "Lim::Plugin::Zonalizer::Server",
    "code" : 500,
    "message" : null
  }
}
```

### API Errors

These errors are returned as a string in the `message` value or in logs.

#### duplicate_id_found

A duplicated id was found.

#### id_not_found

The requested id was not found.

#### revision_missmatch

The revision of the object missmatched, the object was most likely updated
out of scope.

#### invalid_limit

An invalid limit was supplied, limit may not be less then 0 and more the
`max_limit`.

#### invalid_sort_field

An invalid field was supplied in the `sort` parameter.

#### internal_database_error

An internal database error, see logs for more information.

#### invalid_after

An invalid `after` parameter was supplied.

#### invalid_before

An invalid `before` parameter was supplied.

#### invalid_fqdn

An invalid `fqdn` or `search` parameter was supplied.

#### queue_full

The queue is full so the request has been dropped.

#### invalid_lang

An invalid `lang` parameter was supplied.

#### ipv4_not_allowed

The requested analysis over IPv4 is not allowed.

#### ipv6_not_allowed

The requested analysis over IPv6 is not allowed.

#### no_ip_protocol

The requested analysis has both IPv4 and IPv6 disabled, one must be enabled.

#### invalid_ns

Any of all of the `ns` objects supplied are invalid or too many.

#### invalid_ds

Any of all of the `ds` objects supplied are invalid or too many.

#### undelegated_not_allowed

An undelegated analysis was requested but is not allowed.

#### undelegated_forced

An analysis was requested without delegation information which must be supplied.

#### meta_data_not_allowed

Meta data was supplied but is not allowed.

#### invalid_meta_data

Meta data supplied is invalid.

#### policy_not_found

The requested policy was not found.

#### invalid_api_version

The API version given is invalid.

### HTTP Errors

These are the HTTP status errors returned, additional errors may be returned
from the framework.

#### 400 BAD REQUEST

Indicates that some fields in the request are invalid.  See `message` for the
corresponding API error.

#### 404 NOT FOUND

Indicates that the requested id was not found, see `message` for the
corresponding API error.

#### 409 CONFLICT

Indicates that an id conflict happen when trying to create database objects,
this is a temporarly error and the request can be retried.

#### 415 UNSUPPORTED MEDIA TYPE

Indicates that requested media type or languages are unsupported, see `message`
for the corresponding API error.

#### 500 INTERNAL SERVER ERROR

Indicates that an internal error occurred, more detailed information can be
found in the logs.

This error also occurs when the framework's input and output data validation
checks fail, see logs for detailed information.

#### 501 NOT IMPLEMENTED

Indicates that the call used has not been implemented yet.

#### 503 SERVICE UNAVAILABLE

Indicates that the service is temporarly unavailable, see `message` for the
corresponding API error.

### Analyze Errors

TODO

# LICENSE AND COPYRIGHT

Copyright 2015-2016 Jerry Lundström

Copyright 2015-2016 IIS (The Internet Foundation in Sweden)

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
