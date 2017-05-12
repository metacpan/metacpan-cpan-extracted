package Device::OUI;
use strict; use warnings;
our $VERSION = '1.04';
use IO::File ();
use Carp qw( croak carp );
use AnyDBM_File;
use overload (
    '<=>' => 'overload_cmp',
    'cmp' => 'overload_cmp',
    '""'  => 'normalized',
    fallback => 1,
);
use base qw( Class::Accessor::Grouped );
use Sub::Exporter -setup => {
    exports => [qw( normalize_oui oui_cmp parse_oui_entry oui_to_integers )],
};

__PACKAGE__->mk_group_accessors( inherited => qw(
    cache_db cache_file
    file_url search_url
) );
my $cache = $^O eq 'MSWin32' ? 'C:\device_oui' : '/var/cache/device_oui';
__PACKAGE__->cache_db( $cache );
__PACKAGE__->cache_file( $cache . '.txt' );
__PACKAGE__->search_url( 'http://standards.ieee.org/cgi-bin/ouisearch?%s' );
__PACKAGE__->file_url( 'http://standards.ieee.org/regauth/oui/oui.txt' );

sub cache_handle {
    my $self = shift;

    if ( @_ ) { $self->set_inherited( 'cache_handle', @_ ) }
    my $handle = $self->get_inherited( 'cache_handle' );
    if ( $handle ) { return $handle }
    $handle = {};
    if ( my $db = $self->cache_db ) {
        my $opts = Fcntl::O_RDWR | Fcntl::O_CREAT;
        my %cache;
        if ( tie( %cache, 'AnyDBM_File', $db, $opts, 0666 ) ) { ## no critic
            $handle = \%cache;
        }
    }
    $self->set_inherited( 'cache_handle', $handle );
    return $handle;
}

sub cache {
    my $self = shift;
    my $oui = ( @_ && not ref $_[0] ) ? shift : $self->norm;
        
    my $handle = $self->cache_handle;

    if ( @_ ) {
        my %hash = %{ shift() };
        for my $x ( keys %hash ) {
            if ( not defined $hash{ $x } ) { $hash{ $x } = '' }
        }
        return $handle->{ $oui } = join( "\0", %hash );
    } elsif ( my $x = $handle->{ $oui } ) {
        return { split( "\0", $x ) };
    }
    return;
}

sub new {
    my $self = bless( {}, shift );
    $self->oui( shift ) if @_;
    return $self;
}

sub oui {
    my $self = shift;

    if ( @_ ) {
        my $oui = shift;
        if ( my $norm = normalize_oui( $oui ) ) {
            $self->{ 'oui' } = $oui;
            $self->{ 'oui_norm' } = $norm;
            delete $self->{ 'lookup' };
        } else {
            croak "Invalid OUI format: $oui";
        }
    }

    if ( not $self->{ 'oui' } ) { croak "Object does not have an OUI" }

    return $self->{ 'oui' };
}

sub oui_to_integers {
    my $oui = shift || return;

    if ( ref $oui ) { return map { hex } split( '-', $oui->norm ) }

    # 00-06-2A or 0:6:2a, etc. any non-hex delimiter will do
    {
        my @parts = grep { length } split( /[^a-f0-9]+/i, $oui );
        if ( @parts == 3 ) { return map { hex } @parts }
    }

    # 00062a, requires exactly 6 hex characters
    {
        my @parts = ( $oui =~ /([a-f0-9])/ig );
        if ( @parts == 6 ) {
            return(
                hex( $parts[0].$parts[1] ),
                hex( $parts[2].$parts[3] ),
                hex( $parts[4].$parts[5] ),
            );
        }
    }
    return ();
}

sub normalize_oui {
    my $oui = shift;
    my @int = oui_to_integers( $oui ) or return;
    return sprintf( '%02X-%02X-%02X', @int );
}

sub normalized { return shift->{ 'oui_norm' } }
*norm = \&normalized;

sub organization { return shift->lookup->{ 'organization' } }
sub company_id { return shift->lookup->{ 'company_id' } }
sub address { return shift->lookup->{ 'address' } }

sub is_private {
    my $self = shift;

    return $self->organization eq 'PRIVATE' ? 1 : 0;
}

sub lookup {
    my $self = shift;

    my $x;
    if ( $x = $self->{ 'lookup' } ) { return $x }

    if ( $x = $self->cache ) { return $self->{ 'lookup' } = $x }
    if ( $x = $self->update_from_file ) { return $self->{ 'lookup' } = $x }
    if ( $x = $self->update_from_web ) { return $self->{ 'lookup' } = $x }
    if ( $self->mirror_file ) {
        if ( $x = $self->update_from_file ) {
            return $self->{ 'lookup' } = $x;
        }
    }

    return $self->{ 'lookup' } = {};
}

sub update_from_file {
    my $self = shift;
    my $oui = $self->norm;

    my $cf = $self->cache_file;
    if ( ! $cf ) { return }
    my $fh = IO::File->new( $cf, 'r' );
    if ( ! $fh ) { return }

    local $/ = "";
            
    while ( my $entry = $fh->getline ) {
        if ( substr( $entry, 0, 8 ) eq $oui ) {
            my $data = $self->parse_oui_entry( $entry );
            $self->cache( $data );
            return $data;
        }
    }
    return;
}

{
    my $HAVE_LWP_SIMPLE;
    sub have_lwp_simple {
        my $self = shift;
        if ( defined $HAVE_LWP_SIMPLE ) { return $HAVE_LWP_SIMPLE }
        eval "require LWP::Simple"; ## no critic
        if ( $@ ) {
            carp "Unable to load LWP::Simple, network access not available\n";
            $HAVE_LWP_SIMPLE = 0;
        } else {
            $HAVE_LWP_SIMPLE = 1;
        }
    }
}

sub mirror_file {
    my $self = shift;
    my $url  = shift || $self->file_url;
    if ( ! $url ) { return }
    my $file = shift || $self->cache_file;
    if ( ! $file ) { return }
    if ( ! $self->have_lwp_simple ) { return }

    my $res = LWP::Simple::mirror( $url, $file );
    if ( $res == LWP::Simple::RC_NOT_MODIFIED() ) { return 0 }
    if ( ! LWP::Simple::is_success( $res ) ) {
        carp "Failed to mirror $url to $file ($res)";
        return;
    }
    return 1;
}

sub get_url {
    my $self = shift;
    my $url = shift;
    if ( ! $url ) { return }

    return LWP::Simple::get( $url );
}

sub load_cache_from_web {
    my $self = shift;
    my $url  = shift || $self->file_url;
    if ( ! $url ) { return }
    my $file = shift || $self->cache_file;
    if ( ! $file ) { return }

    if ( $self->mirror_file( $url, $file ) ) {
        return $self->load_cache_from_file( $file );
    }
    return;
}

sub load_cache_from_file {
    my $self = shift;
    my $file = shift;
    if ( ! $file ) { $file = $self->cache_file }
    if ( ! $file ) { return }

    my $fh = IO::File->new( $file );
    local $/ = "";
    $fh->getline; # dump the header
    my $counter = 0;
    while ( my $entry = $fh->getline ) {
        my $data = $self->parse_oui_entry( $entry );
        $self->cache( $data->{ 'oui' } => $data );
        $counter++;
    }
    return $counter;
}

sub search_url_for {
    my $self = shift;
    my $oui = normalize_oui( shift );
    if ( ! $oui ) { $oui = $self->norm }

    my $url_format = $self->search_url;
    if ( ! $url_format ) { return }

    if ( $url_format =~ /%s/ ) {
        return sprintf( $url_format, $oui );
    } else {
        return $url_format.$oui;
    }
}

sub update_from_web {
    my $self = shift;

    if ( not ref $self ) { return }
    if ( not $self->have_lwp_simple ) { return }

    my $url = $self->search_url_for;
    if ( ! $url ) { return }

    if ( my $page = $self->get_url( $url ) ) {
        if ( $page =~ /listing contains no match/ ) { return }
        my @entries = ( $page =~ m{<pre>(.*?)</pre>}gs );
        if ( @entries > 1 ) { croak "Too many entries returned from $url\n" }
        my $data = $self->parse_oui_entry( shift( @entries ) );
        $self->cache( $data );
        return $data;
    }
    return;
}

sub parse_oui_entry {
    local $_ = pop( @_ ); # pop in case we get called as a class method
use Carp qw( confess );
    if ( ! $_ ) { confess "eh?" }
    s{</?b>}{}g;
    s/\r//g;

    s/\s*\(hex\)\s*/\n/gm;
    s/\s*\(base 16\).*$//gm;
    s/^\s*|\s*$//gsm;

    my %data = ();
    @data{ qw( oui organization company_id address ) } = split( "\n", $_, 4 );
    delete $data{ 'address' } unless $data{ 'address' };
    return \%data;
}

sub overload_cmp { return oui_cmp( pop( @_ ) ? reverse @_ : @_ ) }
sub oui_cmp {
    my @l = oui_to_integers( shift );
    my @r = oui_to_integers( shift );

    return ( $l[0] <=> $r[0] || $l[1] <=> $r[1] || $l[2] <=> $r[2] );
}

sub dump_cache {
    my $self = shift;

    my @lines = (
        "\n",
        "OUI\t\t\t\tOrganization\n",
        "company_id\t\t\tOrganization\n",
        "\t\t\t\tAddress\n",
        "\n", "\n",
    );

    my $db = $self->cache_handle;

    foreach my $oui ( sort { $a cmp $b } keys %{ $db } ) {
        my $d = { split( "\0", $db->{ $oui } ) };
        my $org = $d->{ 'organization' };

        push( @lines, 
            sprintf( "%-10s (hex)\t\t%s\n", $d->{ 'oui' }, $org ),
            sprintf(
                "%-10s (base 16)\t\t%s\n",
                $d->{ 'company_id' },
                $org eq 'PRIVATE' ? '' : $org,
            ),
        );
        if ( my $a = $d->{ 'address' } ) {
            for my $x ( split( "\n", $d->{ 'address' } ) ) {
                push( @lines, "\t\t\t\t$x\n" );
            }
            push( @lines, "\n" );
        } else {
            push( @lines, "\t\t\t\t\n" );
        }
    }

    return join( "", @lines );
}

1;

__END__

=head1 NAME

Device::OUI - Resolve an Organizationally Unique Identifier

=head1 SYNOPSIS

    use Device::OUI;
    
    my $oui = Device::OUI->new( '00:17:F2' );
    printf( "Organization: %s\n", $oui->organization );

=head1 DESCRIPTION

This module provides an interface to the IEEE OUI (Organizationally Unique
Identifier) registry.  The registry contains information on what company
an OUI is assigned to.  OUIs are used in various networking devices as part
of a unique ID method (network MAC addresses and Fiber Channel WWNs in
particular, see the L<Device::MAC> and L<Device::WWN> modules for more
information).

=head1 CONFIGURATION

This module has a handful of configuration options, mostly dealing with
where to get the source for the registry data, and where to store the cache.

These configuration options are inherited, and you can change them for the
main class, a subclass, or a specific object.  Note that changing a
configuration option for an object does not change it for other objects of
that class (see L<Class::Accessor::Grouped/get_inherited|get_inherited in
the Class::Accessor::Grouped docs>).

    use Device::OUI;
    Device::OUI->cache_db( '/tmp/oui_cache' );

=head2 Device::OUI->cache_db( $db )

Returns the filename where the cache database should be stored.  If given an
argument you can change the file to store the cache database in.

The default is C<C:\device_oui> on windows, and C</var/cache/device_oui> on
everything else.  Set this to undef to disable the cache database.
(C<< Device::OUI->cache_db( undef ) >>).

Note that L<AnyDBM_File|AnyDBM_File> may append an extension (usually '.db')
to whatever you use as the filename, depending on which C<*DBM_File> classes
are available on your machine.

=head2 Device::OUI->cache_file( $filename )

Returns the filename where the oui.txt file should be stored when downloaded
from the internet, or where the file can be found if you are downloading it
by some other means.

The default is C<C:\device_oui.txt> on windows, and
C</var/cache/device_oui.txt> on everything else.  Set this to undef to
disable the cache file.  (C<< Device::OUI->cache_file( undef ) >>).

=head2 Device::OUI->search_url( $url )

The URL for the OUI search page.  Normally you don't need to change this,
but it is provided as a configuration option in case the page is relocated.
You can also set this to undef to disable runtime searches.

This value is used by L</search_url_for|search_url_for> to create a search
url for a specific OUI.  The default implementation allows you to include
a '%s' token in the URL, in which case the URL will be formatted with
L<perlfunc/sprintf|sprintf>, using the OUI as an argument.  If the url
provided does not contain a '%s' token, then the OUI will simply be appended
to the end (in which case, the URL provided should probably end with
something like: C<?arg=>).

=head2 Device::OUI->file_url( $url );

The URL to download the entire oui.txt registry file.  Normally you don't need
to change this either, but you can set it to undef to disable registry
downloading.

=head1 CLASS METHODS

=head2 my $oui = Device::OUI->new( $oui );

Creates and returns a new Device::OUI object.  If an OUI is provided, it will
be passed to the oui method detailed below.  Creating an object without an
oui is not an error, but any method that should return data will croak when
you call it if no oui has been provided either at construction time or by
calling the L</oui|oui> method.

=head2 Device::OUI->load_cache_from_file( $file );

The L</load_cache_from_file|load_cache_from_file> method is used to load up
the cache database with data from an OUI registry file.  If no filename
is provided, then the value returned by L</cache_file|cache_file> will be
used.  If L</cache_file|cache_file> is not defined and you don't provide a
filename when you call this method, then it will simply return without
doing anything.

Returns the number of records processed into the cache database, if no cache
file can be located, then it will return.

=head2 Device::OUI->load_cache_from_web( $url, $file );

The L</load_cache_from_web|load_cache_from_web> method attempts to download
an updated version of the indicated file and load it into the cache database.
If no url is provided then the value returned by L</file_url|file_url> will
be used.  If L</file_url|file_url> is not defined, then either you must
provide a url when calling this method, or it will return without
doing anything.

This method uses the L<LWP::Simple/mirror|mirror> method from
L<LWP::Simple|LWP::Simple> to update the cache file, so it will not download
a new registry file if it already has the latest version.  This makes it
easy to have a cron job that updates the registry file using a command like:

    perl -MDevice::OUI -e 'Device::OUI->load_cache_from_web'

Returns undef if the update failed, or no update was necessary.  Returns the
number of records inserted into the cache database if successful.  This method
also will not update the cache database if a new file wasn't downloaded.  If
you want to update the cache database regardless of whether a new file was
downloaded or not, try this:

    use Device::OUI;
    if ( defined Device::OUI->mirror_file ) {
        Device::OUI->load_cache_from_file();
    }

=head2 cache_handle( $new );

Called with an argument, sets a new object for the cache handle.  This object
will be treated like a hash, so it either needs to be a hash reference, or
a tied hash reference, or something along those lines.

If called without an argument, returns the current cache handle, making a new
one if necessary.  If it's necessary to create a new handle and
L</cache_db|cache_db> is set, then a new hash will be created and tied to
L<AnyDBM_File|AnyDBM_File>.

If it's necessary to create a new handle and L</cache_db|cache_db> is not
defined (or the attempt to tie to L<AnyDBM_File|AnyDBM_File> fails), then
a new anonymous hash will be used to create an in-memory cache that only
lasts for the life of the program.

=head1 OBJECT METHODS

=head2 $oui->oui( $oui )

Called with no arguments, this returns the OUI that the object represents
(in the same format it was originally provided to the object).  If given an
argument of an OUI, sets or changes the OUI represented by this object.

Any reasonable OUI format should be accepted by this method.  The most common
formats (00:17:F2, 00-17-f2, 0017f2, 0:17:f2, etc) should be fine with any
delimiter between the bytes.  If no delimiter is provided (as in the case of
'08001B', the argument must be exactly 6 characters long.

=head2 $oui->normalized()

Returns a normalized form of the OUI, with upper-case hex bytes zero-padded and
separated with dashes (as in 00-17-F2).  Also available as C<< $oui->norm >>.

L<Device::OUI|Device::OUI> objects have stringification overloaded to return
this value.

=head2 $oui->norm()

This is an alias for L</normalized|normalized()>;

=head2 $oui->is_private()

Returns a true value if the OUI is privately registered (in this case no
information is available on the organization that owns it, they are simply
listed in the registry file as 'PRIVATE').

=head2 $oui->organization()

Returns the organization the OUI is registered to.  For private registrations,
the organization is set to 'PRIVATE'.

=head2 $oui->company_id()

Returns the 'company_id' from the registry file.  This is really just the OUI
in a slightly different format (0019E3 instead of 00-19-E3).

=head2 $oui->address()

Returns the organization address from the registry file as a multiline string.

=head1 FUNCTIONS / EXPORTS

Although this module is entirely object oriented, there are a handful of
utility functions that you can import from this module if you find a need
for them.  Nothing is exported by default, so if you want to import any of
these, you need to say so explicitly:

    use Device::OUI qw( ... );

You can get all of them by importing the ':all' tag:

    use Device::OUI ':all';

Exporting is handled by L<Sub::Exporter>, so you can rename the imported
methods if necessary.

=head2 my $oui = normalize_oui( $input );

Given an OUI, normalizes it into an upper-case, zero padded, dash separated
format and returns the normalized OUI.

=head2 oui_cmp( $oui, $oui );

This is a convenience method, given two Device::OUI objects, or two OUIs (in
any acceptable format) or one of each, will return -1, 0, or 1, depending on
whether the first OUI is less than, equal to, or greater than the second one.

L<Device::OUI> objects have C<cmp> and C<< <=> >> overloaded so that simply
comparing them will work as expected.

=head2 parse_oui_entry( $entry );

Given a text representation of a single entry from the OUI registry file,
this method extracts the information from it and returns a data structure
that looks like this:

    {
        oui          => '00-17-F2',
        company_id   => '0017F2',
        organization => 'Apple Computer',
        address      => [
            '1 Infinite Loop MS:35GPO',
            'Cupertino CA 95014',
            'UNITED STATES',
        ],
    }

=head2 my @parts = oui_to_integers( $oui );

Given an OUI in any acceptable format, returns an array of three integers
representing the values of the three bytes of the OUI.

=head1 INTERNAL METHODS

These are methods used internally, that you shouldn't need to mess with.

=head2 $oui->lookup();

Attempts to retireve information from the OUI registry.  If another lookup
method has already retrieved the information, then that saved structure will
simply be returned.  If not, then an attempt will be made to load the data from
the L</cache_db|cache_db>, from the L</cache_file|cache_file> or from the
internet, using the search interface indicated by L</search_url|search_url>.
As a last resort, if L</file_url|file_url> is defined, it will attempt to
download it and use it for searching.

Returns a hash reference of the data found, or an empty hash reference if all
these things failed.

=head2 Device::OUI->cache( $oui, $data )

This method is the main interface to the cache database.

If called with one argument, then it returns the cached data for the OUI
provided.  If called with two arguments it replaces the existing cached data
with the new data provided.

=head2 $oui->cache( $data )

If L</cache|cache> is called as an object method, you don't have to include
the OUI as an argument.  If there are no arguments, then the OUI of the
invocant will be used as the OUI.  If there is one argument and it is a
reference, then it will be assumed to be C<$data>.  If there is one argument
and it is not a reference, then it will be assumed to be an OUI.  If there
are two arguments, then it behaves the same as when called as a class method.

=head2 $oui->update_from_web()

This method searches the OUI registry (using the URL configured in
L</search_url|search_url>) for it's own OUI, and if successful,
updates the cache with the information found.

If a L</cache_db|cache_db> is in use, this method will update the cache
database.

If the search is successful, this method also returns the data that was
found.

=head2 $oui->update_from_file()

This method searches the OUI registry file, if you have one and it can be
located with L</cache_file|cache_file>.

If a L</cache_db|cache_db> is in use, this method will update the cache
database.

If the search is successful, this method also returns the data that was
found.

=head2 Device::OUI->dump_cache( $sort )

This method is mostly for debugging purposes.  When called, it will dump the
contents of the cache database in the same format as the entries appear in the
OUI registry file.

Takes one optional argument, if called with a true value, then the entries
will be dumped in order, sorted by their OUIs.  With sorting turned off, this
method runs much faster and returns sooner, but if you turn sorting on then
the output file should be round-trippable, meaning you can do this:

    # curl -O http://standards.ieee.org/regauth/oui/oui.txt
    ... Downloading ...
    # perl -MDevice::OUI -e 'Device::OUI->load_cache_from_file( "oui.txt" );'
    # perl -MDevice::OUI -e 'Device::OUI->dump_cache' > new-oui.txt
    # diff oui.txt new-oui.txt
    ( no differences )

=head2 $oui->search_url_for( $oui )

Fills in the URL indicated by L</search_url|search_url> with either the OUI
provided as an argument, or the invocants OUI, if called as an object method
and no argument is provided.

=head2 Device::OUI->have_lwp_simple()

This methods returns true if L<LWP::Simple|LWP::Simple> is available and
false if it is not available.  The first time this method is called, an
attempt will be made to C<require LWP::Simple>, and a warning will be issued
if the C<require> is not successful.  This method is used internally by the
web access features.

=head2 Device::OUI->mirror_file( $url, $file )

This method is a wrapper around
L<LWP::Simple/mirror|LWP::Simple's mirror method>.  It returns 1 if the file
was mirrored successfully, 0 if the file was not mirrored because the web
server reported that the version of the file already in L</cache_file> was
the latest version, and undef if no file was downloaded.

If C<$file> is not provided, then the value from L</cache_file|cache_file> will
be used.  If C<$url> is not provided, then the value from
L</file_url|file_url> will be used.

=head2 Device::OUI->get_url( $url )

This method is a wrapper around L<LWP::Simple/get|LWP::Simple's get method>.
It attempts to load the provided C<$url> and returns the contents of the page
if successful.  It returns undef if unsucessful or if no URL is provided

=head2 overload_cmp

This is just a little wrapper that calls L</oui_cmp|oui_cmp>, rearranging
the order of the arguments if necessary.

=head1 CACHING INFORMATION

=head2 LAZY CACHE LOADING

There are a couple of ways you can use the cache features in this module.  If
you are only going to lookup a handful of OUIs and don't want to download and
process the whole registry file at one time, you can simply let the module
create a cache database for you, and populate it with entries one at a time as
objects are created that are not already in the cache.

=head2 PRE-POPULATING THE CACHE

If you are going to be looking up a lot of OUIs (where a lot should probably
be defined as "more than 4 or 5") then you would probably be better off
pre-populating the cache, using either the
L</load_cache_from_web|load_cache_from_web> method or the
L</load_cache_from_file|load_cache_fom_file> method.  The first is the easiest,
assuming the machine you are running it on has web access, you can simply run:

    perl -MDevice::OUI -e 'Device::OUI->load_cache_from_web'

If you don't have web access, you can transfer the file in whatever manner
works for you, and then use it to populate the cache with:

    perl -MDevice::OUI -e 'Device::OUI->load_cache_file_file( "filename" )'

=head2 PREVENTING CACHING

To keep the module from creating a cache database, set L</cache_db|cache_db>
to undef before creating any Device::OUI objects:

    use Device::OUI;
    Device::OUI->cache_db( undef );

If you don't have a cache database, but you do have a cache file, then the
caching module will simply look each OUI up in the file every time.  This
is much slower than having a cache database, but may be necessary in some
situations.

=head2 PREVENTING NETWORK ACCESS

To keep Device::OUI from attempting to access the network, set the
URL configuration options to undef before creating any C<Device::OUI>
objects:

    use Device::OUI;
    Device::OUI->search_url( undef );
    Device::OUI->file_url( undef );

Even with these two values set to undef,
L</load_cache_from_web|load_cache_from_web> will still work (and still
attempt to access the internet) if you give it a URL as an argument when
you call it.

Network access will also be disabled if L<LWP::Simple|LWP::Simple> is not
available.

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/device-oui>.  This is where you can
always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<http://www.jasonkohles.com/software/device-oui>

L<http://en.wikipedia.org/wiki/Organizationally_Unique_Identifier>

L<http://standards.ieee.org/regauth/oui/index.shtml>

=head1 AUTHOR

Jason Kohles C<< <email@jasonkohles.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008, 2009 Jason Kohles

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

