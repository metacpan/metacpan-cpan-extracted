package HTTPD::Log::Filter;

#------------------------------------------------------------------------------
#
# Standard pragmas
#
#------------------------------------------------------------------------------

use strict;
use warnings;

#------------------------------------------------------------------------------
#
# ModuleS
#
#------------------------------------------------------------------------------

use IO::File;
use IO::Zlib;

my $fields_order = {
    CLF => [ qw(
        host
        ident
        authexclude
        date
        request
        status
        bytes
    ) ],
    ELF => [ qw(
        host
        ident
        authexclude
        date
        request
        status
        bytes
        referer
        agent
    ) ],
    SQUID => [ qw(
        time 
        elapsed 
        remotehost 
        code_status 
        bytes 
        method 
        url 
        rfc931
        peerstatus_peerhost 
        type
    ) ],
    UNSPECIFIED => [ qw(
        host
        ident
        authexclude
        date
        request
        status
        bytes
        referer
        agent
        junk
    ) ],
    XLF => [ qw(
        host
        ident
        authexclude
        date
        request
        status
        bytes
        referer
        agent
        junk
    ) ],
};

my @format_options = grep !/^UNSPECIFIED$/, keys %{$fields_order};
my $format_options_re = '(' . join( '|', @format_options ) . ')';

my %in_braces = map { $_ => 1 } qw(
    date
);

my %in_quotes = map { $_ => 1 } qw(
    request
    referer
    agent
);

my $squid_status = '(?:' . join( '|', qw(
    TCP_HIT
    TCP_MISS
    TCP_REFRESH_HIT
    TCP_REF_FAIL_HIT
    TCP_REFRESH_MISS
    TCP_CLIENT_REFRESH_MISS
    TCP_IMS_HIT
    TCP_SWAPFAIL_MISS
    TCP_NEGATIVE_HIT
    TCP_MEM_HIT
    TCP_DENIED
    TCP_OFFLINE_HIT
    UDP_HIT
    UDP_MISS
    UDP_DENIED
    UDP_INVALID
    UDP_MISS_NOFETCH
    NONE
    ERR_.*?
    TCP_CLIENT_REFRESH
    TCP_SWAPFAIL
    TCP_IMS_MISS
    UDP_HIT_OBJ
    UDP_RELOADING
) ) . ')';

my @http_methods = qw(
    GET
    HEAD
    POST
    PUT
    DELETE
    TRACE
    OPTIONS
    CONNECT
);

my @rfc2518_methods = qw(
    PROPFIND
    PROPATCH
    MKCOL
    MOVE
    COPY
    LOCK
    UNLOCK
);

my $methods_re = '(?:' . join( '|', @http_methods, @rfc2518_methods ) . ')';

my @squid_methods = (
    'ICP_QUERY',
    'PURGE',
    @http_methods,
    @rfc2518_methods
);

my @heirarchy_codes = qw(
    NONE
    DIRECT
    SIBLING_HIT
    PARENT_HIT
    DEFAULT_PARENT
    SINGLE_PARENT
    FIRST_UP_PARENT
    NO_PARENT_DIRECT
    FIRST_PARENT_MISS
    CLOSEST_PARENT_MISS
    CLOSEST_PARENT
    CLOSEST_DIRECT
    NO_DIRECT_FAIL
    SOURCE_FASTEST
    ROUNDROBIN_PARENT
    CACHE_DIGEST_HIT
    CD_PARENT_HIT
    CD_SIBLING_HIT
    NO_CACHE_DIGEST_DIRECT
    CARP
    ANY_PARENT
    INVALID CODE
);

my $hierarchy_code_re = '(?:' . join( '|', @heirarchy_codes ) . ')';
my $squid_methods_re = '(?:' . join( '|', @squid_methods ) . ')';
my $url_re = '.*?';
my $host_re = '.*?';
my $mime_type_re = '(?:-|.*?/.*?)';
my $status_re = '\d{3}';

my %generic_fields_re = (
    host                => $host_re,
    ident               => '\S+',
    authexclude         => '\S+',
    date                => '\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2}\s[+-]\d{4}',
    request             => "$methods_re $url_re",
    status              => $status_re,
    bytes               => '(?:-|\d+)',
    referer             => '.*?',
    agent               => '.*?',
    junk                => '.*',
    'time'              => '\d+\.\d+',
    elapsed             => '\d+',
    remotehost          => '\S+',
    code_status         => "$squid_status/$status_re",
    method              => $squid_methods_re,
    url                 => $url_re,
    rfc931              => '.*?',
    peerstatus_peerhost => "$hierarchy_code_re/$host_re",
    type                => $mime_type_re,
);

my @options = qw(
    exclusions_file
    invert
);

use vars qw( $VERSION );

$VERSION = '1.08';

#------------------------------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------------------------------

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless {}, $class;
    $self->{exclusions_file} = delete $args{exclusions_file};
    if ( $self->{exclusions_file} )
    {
        $self->{efh} = new IO::File ">$self->{exclusions_file}";
        die "can't write to $self->{exclusions_file}: $!\n" unless $self->{efh};
    }
    $self->{invert} = delete $args{invert};
    die "format option should be $format_options_re\n" 
        if $args{format} and $args{format} !~ /^$format_options_re$/
    ;
    $self->{required_format} = delete $args{format} || 'UNSPECIFIED';
    $self->{format} = $self->{required_format};
    $self->{capture} = delete( $args{capture} );
    $self->{regexes} = \%args;
    $self->create_regexes( $self->{format} );
    return $self;
}

sub capture
{
    my $self = shift;
    my $capture = shift;

    if ( $capture )
    {
        $self->{capture} = $capture;
        $self->create_regexes( $self->{format} );
    }
    return $self->{capture};
}

sub format
{
    my $self = shift;
    my $format = shift;

    if ( $format )
    {
        $self->{format} = $format;
        $self->create_regexes( $self->{format} );
    }
    return $self->{format};
}

sub get_re_field
{
    my $field = shift;
    my $re = shift;
    my %capture = @_;

    $re = "($re)" if $capture{$field};
    $re = "\"$re\"" if $in_quotes{$field};
    $re = "\\[$re\\]" if $in_braces{$field};
    return $re;
}

sub create_regexes
{
    my $self = shift;
    my $format = shift;

    my @fields_order = @{$fields_order->{$format}};
    my %fields_order = map { $_ => 1 } @fields_order;
    my %valid_fields = map { $_  . '_re' => 1 }  @fields_order;
    for ( keys %{$self->{regexes}} )
    {
        die 
            "$_ is not a valid option; please use one of:\n",
            map { "\t$_\n" } keys( %valid_fields ), @options,
        unless $valid_fields{$_}
    }

    my %capture;

    if ( ref( $self->{capture} ) eq 'ARRAY' )
    {
        for ( @{$self->{capture}} )
        {
            die 
                "$_ is not a valid $format field name;",
                "should be one of\n", 
                map { "\t$_\n" } @fields_order
            unless $fields_order{$_};
        }
        %capture = map { $_ => 1 } @{$self->{capture}};
        $self->{capture_fields} = 
            [ grep { $capture{$_} } @fields_order ]
        ;
    }
    my @generic_fields_re = map
        {
            my $re = $generic_fields_re{$_};
            $re = get_re_field( $_, $re, %capture );
            $re;
        } 
        @fields_order
    ;
    $self->{generic_fields_re} = join( '\s', @generic_fields_re ); 
    my %exclude_fields_re = ( 
        %generic_fields_re,
        map { 
            my $re = $self->{regexes}{$_}; 
            s/_re$//;
            $_ => $re
        } 
        grep /_re$/,
        keys %{$self->{regexes}}
    );
    %exclude_fields_re = 
        map { $_ => get_re_field( $_, $exclude_fields_re{$_}, %capture ) } 
        keys %exclude_fields_re
    ;
    $self->{exclude_fields_re} = 
        join( '\s', map( { $exclude_fields_re{$_} } @fields_order ) )
    ;
}

sub generic_re
{
    my $self = shift;
    return $self->{generic_fields_re};
}

sub re
{
    my $self = shift;
    return $self->{exclude_fields_re};
}

sub check_generic_re
{
    my $self = shift;
    my $line = shift;
    return $line =~ m{^$self->{generic_fields_re}$};
}

sub detect_format
{
    my $self = shift;
    my %args = @_;

    if ( $args{filename} )
    {
        my $fh;
        if ( $args{filename} =~ /\.gz$/ )
        {
            $fh = IO::Zlib->new( $args{filename}, "rb" ) 
                or die "Can't open $args{filename}\n"
            ;
        }
        else
        {
            $fh = IO::File->new( $args{filename} ) 
                or die "Can't open $args{filename}\n"
            ;
        }
        $args{line} = <$fh>;
    }
    die "detect_format expects either a filename or a line from a logfile"
        unless $args{line}
    ;
    for ( @format_options )
    {
        eval { $self->create_regexes( $_ ) };
        next if $@;
        next unless $self->check_generic_re( $args{line} );
        $self->{format} = $_;
        return $self->{format};
    }
    die "Can't autodetect format\n";
}

sub filter
{
    my $self = shift;
    my $line = shift;

    my @captured;
    $self->detect_format( line => $line ) 
        if $self->{required_format} eq 'UNSPECIFIED'
    ;
    @captured = $self->check_generic_re( $line );
    return undef unless @captured;
    if ( $self->{capture} )
    {
        my @cfields = @{$self->{capture_fields}};
        my %captured;
        @captured{@cfields} = @captured;
        $self->{captured} = \%captured;
    }
    if ( $self->{invert} )
    {
        return $line if $line !~ m{^$self->{exclude_fields_re}$};
    }
    else
    {
        return $line if $line =~ m{^$self->{exclude_fields_re}$};
    }
    if ( $self->{efh} )
    {
        $self->{efh}->print( $line );
    }
    return '';
}

sub DESTROY {}

sub AUTOLOAD
{
    my $self = shift;
    use vars qw( $AUTOLOAD );
    my $field = $AUTOLOAD;
    $field =~ s/.*:://;
    die "$field method not defined\n" unless exists $self->{captured}{$field};
    return $self->{captured}{$field};
}

#------------------------------------------------------------------------------
#
# Start of POD
#
#------------------------------------------------------------------------------

=head1 NAME

HTTPD::Log::Filter - a module to filter entries out of an httpd log.

=head1 SYNOPSIS

    my $hlf = HTTPD::Log::Filter->new(
        exclusions_file     => $exclusions_file,
        agent_re            => '.*Mozilla.*',
        format              => 'ELF',
    );

    while( <> )
    {
        my $ret = $hlf->filter( $_ );
        die "Error at line $.: invalid log format\n" unless defined $ret;
        print $_ if $ret;
    }

    print grep { $hlf->filter( $_ ) } <>;

    $hlf = HTTPD::Log::Filter->new(
        capture => [ qw(
            host
            ident
            authexclude
            date
            request
            status
            bytes
        ) ];
    );

    while( <> )
    {
        next unless $hlf->filter( $_ );
        print $hlf->host, "\n";
    }

    print grep { $hlf->filter( $_ ) } <>;

=head1 DESCRIPTION

This module provide a simple interface to filter entries out of an httpd
logfile. The constructor can be passed regular expressions to match against
particular fields on the logfile.  It does its filtering line by line, using a
filter method that takes a line of a logfile as input, and returns true if it
matches, and false if it doesn't.

There are two possible non-matching (false) conditions; one is where the line
is a valid httpd logfile entry, but just doesn't happen to match the filter
(where "" is returned). The other is where it is an invalid entry according to
the format specified in the constructor.

=head1 CONSTRUCTOR

The constructor is passed a number of options as a hash. These are:

=over 4

=item exclusions_file

This option can be used to specify a filename for entries that don't match the
filter to be written to.

=item invert

This option, is set to true, will invert the logic of the fliter; i.e. will
return only non-matching lines.

=item format

This should be one of:

=over 4

=item CLF

Common Log Format (CLF):

"%h %l %u %t \"%r\" %>s %b" 

=item ELF

NCSA Extended/combined Log format:

"%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" 

=item XLF

Some bespoke format based on extended log format + some junk at the end:

"%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" %j

where %j is .* in regex-speak.

See L<http://httpd.apache.org/docs/mod/mod_log_config.html> for more
information on log file formats.

=item SQUID

Logging format for Squid (v1.1+) caching / proxy servers. This is of the form:

"%9d.%03d %6d %s %s/%03d %d %s %s %s %s%s/%s %s"

where the fields are:

    time 
    elapsed 
    remotehost 
    code_status 
    bytes 
    method 
    url 
    rfc931
    peerstatus_peerhost 
    type


(see L<http://www.squid-cache.org/Doc/FAQ/FAQ-6.html> for more info).

=back

=item (host|ident|authexclude|date|request|status|bytes|referer|agent)_re

This class of options specifies the regular expression or expressions which are
used to filter the logfile for httpd logs.

=item (time|elapsed|remotehost|code_status|method|url|rfc931|peerstatus_peerhost|type)_re

Ditto for Squid logs.

=item capture [ <fieldname1>, <fieldname2>, ... ]

This option requests the filter to capture the contents of given named fields
so that they can be examined if the filtering is successful. This is done by
simply putting capturing parentheses around the appropriate segment of the
filtering regex. Fields to be captured are passed as an array reference.
WARNING; do not try to insert your own capturing parentheses in the custom
field regexes, as this will have unpredictable results when combined with the
capture option.

Captured fields can be accessed after each call to filter using a method call
with the same name as the captured field; e.g.

    my $filter = HTTPD::Logs::Filter->new(
        capture => [ 'host', 'request' ]
    );
    while ( <> )
    {
        next unless $filter->filter( $_ );
        print $filter->host, " requested ", $filter->request, "\n";
    }

=back

=head1 METHODS

=head2 filter

Filters a line of a httpd logfile. returns true (the line) if it
matches, and false ("" or undef) if it doesn't.

There are two possible non-matching (false) conditions; one is where the line
is a valid httpd logfile entry, but just doesn't happen to match the filter
(where "" is returned). The other is where it is an invalid entry according to
the format specified in the constructor.

=head2 re

Returns the current filter regular expression.

=head2 format

Returns the current format.

=head2 (host|ident|authexclude|date|request|status|bytes|referer|agent|junk)

If the capture option has been specified, these methods return the captured
string for each field as a result of the previous call to filter.

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#
# True ...
#
#------------------------------------------------------------------------------

1;
