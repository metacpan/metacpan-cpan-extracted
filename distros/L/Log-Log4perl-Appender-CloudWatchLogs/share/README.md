# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [DEPENDENCIES](#dependencies)
* [CONFIGURATION](#configuration)
  * [Options](#options)
* [CAVEATS](#caveats)
* [NON-CPAN DEPENDENCIES](#non-cpan-dependencies)
  * [Installing with cpm](#installing-with-cpm)
  * [Installing with cpanm](#installing-with-cpanm)
  * [Provenance and Verification](#provenance-and-verification)
* [SEE ALSO](#see-also)
* [AUTHOR](#author)
* [LICENSE](#license)
# NAME

Log::Log4perl::Appender::CloudWatchLogs - Appender to send logs to CloudWatch

**IMPORTANT:** This distribution depends on one or more [Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI)
service modules published outside CPAN. You must install those modules
before proceeding.

- See [Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI) for the rationale behind publishing these
modules outside CPAN.
- See ["NON-CPAN DEPENDENCIES"](#non-cpan-dependencies) for instructions on how to install
these modules.

# SYNOPSIS

    use Log::Log4perl;

    my $log4perl_conf =<<'END_OF_TEXT';
    log4perl.rootLogger=DEBUG, CLOUDWATCH
    log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
    log4perl.appender.CLOUDWATCH.group=/test-log-group
    log4perl.appender.CLOUDWATCH.stream=stream-prefix
    log4perl.appender.CLOUDWATCH.buffer_size=1
    log4perl.appender.CLOUDWATCH.layout=PatternLayout
    log4perl.appender.CLOUDWATCH.layout.ConversionPattern=%d [%r] %F %L %c - %m
    END_OF_TEXT

    Log::Log4perl::init(\$log4perl_conf);

    my $logger = Log::Log4perl->get_logger('');

# DESCRIPTION

Appender to send logs to AWS CloudWatch. Events are buffered and sent
when the buffer is full or when the appender is destroyed.

# DEPENDENCIES

`Amazon::API::CloudWatchLogs`, [Class::Accessor::Fast](https://metacpan.org/pod/Class%3A%3AAccessor%3A%3AFast),
[Data::UUID](https://metacpan.org/pod/Data%3A%3AUUID), [Log::Log4perl::Appender](https://metacpan.org/pod/Log%3A%3ALog4perl%3A%3AAppender)

# CONFIGURATION

The appender supports several configuration attributes for logging to
CloudWatch described below.

Example Log::Log4perl configuration:

    ############################################################
    # A simple root logger with a Log::Log4perl::Appender::CloudWatchLogs
    ############################################################
    log4perl.rootLogger=DEBUG, CLOUDWATCH

    log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
    log4perl.appender.CLOUDWATCH.group=/test-log-group
    log4perl.appender.CLOUDWATCH.stream=foobar

    log4perl.appender.CLOUDWATCH.layout=PatternLayout
    log4perl.appender.CLOUDWATCH.layout.ConversionPattern=%d [%r] %F %L %c - %m

## Options

- group (required)
    - name

        Name of the log group where log streams will be written

    - mode

        Determines if the log group should be created if it does not exist. By
        default, the group must already exist. Set `mode` to `create` to
        create it when necessary.  valid values: create

        _Note: You can use the dot notation or just set `group` to the group name._

            log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
            log4perl.appender.CLOUDWATCH.group.name=/ecs/myapp
            log4perl.appender.CLOUDWATCH.stream.name=ecs/myapp/2026-04-06
            log4perl.appender.CLOUDWATCH.group.mode=create
- stream (optional)
    - name

        Name of the stream. The name of the stream is used as a prefix unless
        the `mode` option is set to 'append'.  If no stream name is given,
        then a unique stream name will be created composed of the log group
        name and a unique suffix.

    - mode

        If mode is set to 'append' the appender will append logs to the
        group/stream provided.  If no mode is provided or the mode is set to
        'create' then a new stream will be created. The appender will use the
        stream name as a prefix with a suffix consisting of the MD5 hash of a
        UUID in order to create a unique stream name.

        Example:

            log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
            log4perl.appender.CLOUDWATCH.group=/ecs/myapp
            log4perl.appender.CLOUDWATCH.stream=

            stream name = ecs/myapp/f974195a83b143a68672b62457a313ca

        valid values: append|create

        _Note: You can use the dot notation or just set `stream` to the stream name._

            log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
            log4perl.appender.CLOUDWATCH.group.name=/ecs/myapp
            log4perl.appender.CLOUDWATCH.stream.name=ecs/myapp/2026-04-06
            log4perl.appender.CLOUDWATCH.stream.mode=create
- buffer\_size

    The number of events to buffer before sending the events to
    CloudWatch. The maximum number of events that can sent in one payload
    is 10K. The maximum size of the payload is 1,048,576 bytes.

    _Note: `flush_buffer()` partitions buffered events into batches
    satisfying the CloudWatch Logs limits on event count, payload size,
    and 24-hour timestamp span._

    default: 1000

    See
    [https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API\_PutLogEvents.html](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html)
    for more details.

- max\_retries

    The maximum number of attempts to make for a PutLogEvents operation
    when an `Amazon::API::Error` exception is thrown.

    default: 5

- retry\_delay

    The amount of time, in seconds, to wait between attempts. The value
    must be greater than zero.

    default: 1

- endpoint\_url

    The API endpoint - leave blank for AWS, http://localhost:4566 for
    LocalStack (or where you have installed LocalStack).

# CAVEATS

The appender internally uses a null logger to prevent re-entrant
logging calls. Any debugging of the CloudWatch API calls made
internally by the appender should be done outside the context of
this appender - for example, in a standalone test script that
invokes `Amazon::API::CloudWatchLogs` directly rather than through
Log::Log4perl configuration.

# NON-CPAN DEPENDENCIES

This distribution depends on one or more modules that are published on the
OpenBedrock CPAN-compatible repository rather than on CPAN.

These dependencies are declared normally in the distribution metadata.
However, an installer must know where to obtain distributions that are not
available from CPAN.

The OpenBedrock repository is available at:

    https://cpan.openbedrock.net/orepan2

Distributions like this one that depend on OpenBedrock modules may
include `cpanfile.darkpan` and/or `cpanm.darkpan` which identify
only the dependencies that must be obtained from the OpenBedrock
repository.

If [DarkPAN::Resolver::SQLite](https://metacpan.org/pod/DarkPAN%3A%3AResolver%3A%3ASQLite) is installed, its `cpan-distfile`
utility can retrieve these files directly from the CPAN distribution
without installing or manually unpacking them:

    cpan-distfile Log::Log4perl::Appender::CloudWatchLogs cpanfile.darkpan \
      > cpanfile.darkpan

`cpanfile.darkpan` is primarily useful when installing this
distribution with `cpm` or `carton`. `cpanm.darkpan` is used when
installing with `cpanm`. See detailed notes for each installer below.

## Installing with cpm

[cpm](https://metacpan.org/pod/cpm) is the preferred installer for distributions that depend on
OpenBedrock modules because its resolver model allows dependencies to be
resolved from both CPAN and the OpenBedrock repository as part of the same
installation.

The OpenBedrock repository provides [DarkPAN::Resolver::SQLite](https://metacpan.org/pod/DarkPAN%3A%3AResolver%3A%3ASQLite), which
uses the repository's multi-version index and can resolve both the latest
available release and specific historical versions.

For example:

    cpm install \
      --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
      Log::Log4perl::Appender::CloudWatchLogs

The resolver is consulted for dependencies available from the OpenBedrock
repository. Dependencies it cannot satisfy continue through `cpm`'s
normal resolver chain.

Unlike the standard `02packages` resolver, the SQLite resolver retains
information about multiple versions of each module. This allows normal
version requirements, including exact historical versions, to be resolved
from the OpenBedrock repository when those releases are available.

For example:

    cpm install \
      --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
      'Amazon::API@2.8.0'

The standard `02packages` resolver may also be used when only the currently
indexed release is required:

    cpm install \
      --resolver 02packages,https://cpan.openbedrock.net/orepan2 \
    Log::Log4perl::Appender::CloudWatchLogs  

## Installing with cpanm

[cpanm](https://metacpan.org/pod/cpanm) may also be used, but its mirror-oriented dependency
resolution makes mixed CPAN and non-CPAN dependency trees potentially
fragile.

With `cpanm`, using the `--mirror` option without `--mirror-only`
causes `cpanm` to use its default resolution method (CPAN
MetaDB/MetaCPAN). Distributions not indexed there, like the ones
specified in our `*.darkpan` files, will not be found.

However, adding the `--mirror-only` flag tells `cpanm` to use the
`02packages.details.txt.gz` index from **each** configured mirror
(including its default) for resolution. Those indexes contain only one
distribution for each module. `cpanm` is therefore only able to resolve
the version represented by that entry, even though other versions of
the distribution may still exist on the mirror or on BackPAN.

This becomes a problem when an `*.darkpan` file pins a module to a
version other than the one represented in `02packages.details.txt.gz`.
In that case, `cpanm` will fail to install that module because it
cannot resolve the pinned version through the index, even if the
corresponding distribution tarball still exists in the repository.

To use `cpanm` you can try:

    cpanm --mirror https://cpan.openbedrock.net/orepan2 --mirror-only \
      < cpanm.darkpan

## Provenance and Verification

[Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI) service distributions published on the OpenBedrock repository
include provenance information describing how each distribution was
produced and the source metadata from which it was generated.

Generated service classes are intentionally published outside CPAN so
that AWS service models can be updated independently without requiring
hundreds of generated distributions to be uploaded to CPAN.

Instructions for verifying distribution signatures and examining
provenance records are maintained at:

    https://cpan.openbedrock.net/signature

Users who wish to verify an OpenBedrock distribution should follow the
instructions provided on that site.

Provenance records may also be inspected using the tools provided by
[Amazon::API::Provenance](https://metacpan.org/pod/Amazon%3A%3AAPI%3A%3AProvenance).

# SEE ALSO

`Amazon::API::CloudWatchLogs` is an Amazon AWS service implemented by `Amazon::API`.

For help with `Amazon::API` service classes see [Amazon::API::Help](https://metacpan.org/pod/Amazon%3A%3AAPI%3A%3AHelp)

[Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI), [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials), [Amazon::API::Help](https://metacpan.org/pod/Amazon%3A%3AAPI%3A%3AHelp)

# AUTHOR

Rob Lauer - <rlauer6@comcast.net>

# LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
