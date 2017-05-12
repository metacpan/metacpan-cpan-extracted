use ExtUtils::MakeMaker;
use Config;
use Cwd;
use 5.006;

require DynaLoader;

$geoip_libpath = '';
$geoip_incpath = '';

my @replacement_args;

my %config;

while ( $_ = shift ) {
    my ( $key, $val ) = split( /=/, $_, 2 );
    $config{$key} = $val;
}

unless ( $config{LIBS} ) {

    # currently we check only for the C Library version if it is in a
    # standard place
    my $geoip_version = 0;
    my $clib          = DynaLoader::dl_findfile('GeoIP');
    my $found         = $clib ? 1 : 0;
    if ($clib) {
        $geoip_version = 10000;    # V 1.0.0 ( means, we have something )

        # a GeoIP lib is found, just check the version, we need 1.4.5 now
        my $lib = DynaLoader::dl_load_file( $clib, 0 );
        if ($lib) {
            for (
                [ 10403, 'GeoIP_last_netmask' ],               # V 1.4.3
                [ 10405, 'GeoIP_range_by_ip' ],                # V 1.4.5
                [ 10405, 'GeoIP_code_by_id' ],                 # V 1.4.5
                [ 10407, 'GeoIP_country_code_by_addr_v6' ],    # V 1.4.7
                [ 10407, 'GeoIP_record_by_addr_v6' ],    # V 1.4.7 or 1.4.8?
                [ 10500, 'GeoIP_country_code_by_ipnum_v6_gl' ],    # V1.5.0
                ) {
                $geoip_version = $_->[0]
                    if DynaLoader::dl_find_symbol( $lib, $_->[1] );
            }

            # to bad we can not distinguish between 1.4.7 and 1.4.8 here
            # I add a test to t/20_min_capi_version.t.
            if ( $geoip_version < 10500 ) {
                print STDERR <<__ERR__;
Your installed version of libgeoip is outdated! Please update to at least
version to 1.5.0 and reinstall this module.

http://dev.maxmind.com/geoip/downloadable

__ERR__
                exit(0);
            }
        }
    }

=pod

  # Test for existence of libGeoIP
  my $found = 0;
  foreach (split(/\s+/, $Config{libpth})) {
    if (-f "$_/libGeoIP." . $Config{so}) {
      $found = 1;
      last;
    }
  }

=cut

    if ( !$found and !$config{PP} ) {
        print STDERR <<'GeoIP_Not_Installed;';

The GeoIP CAPI is not installed you should do that NOW. Otherwise the slow
pure Perl API is used.

GeoIP must be installed prior to building Geo::IP and I can't find
it in the standard library directories. You can download GeoIP C API from:

http://dev.maxmind.com/geoip/downloadable

If GeoIP is installed, but in a non-standard directory, then use the
following options to Makefile.PL:

    perl Makefile.PL LIBS='-L/home/me/lib' INC='-I/home/me/include'

Note that if you build against a shareable library in a non-standard location
you may (on some platforms) also have to set your LD_LIBRARY_PATH environment
variable at run time for perl to find the library.

If you installed the GeoIP C libraries to the /usr/local/lib directory,
then you may need to add /usr/local/lib to /etc/ld.so.conf then run
/sbin/ldconfig /etc/ld.so.conf

GeoIP_Not_Installed;
        $config{PP} = 1;
    }
}

if ( $config{LIBS} !~ /\-lGeoIP\b/ ) {
    $config{LIBS} .= ' -lGeoIP';
}

@extras = ();

push( @extras, CAPI => 'TRUE' )
    if ($PERL_VERSION >= 5.005
    and $OSNAME eq 'MSWin32'
    and $Config{archname} =~ /-object\b/i );

push(
    @extras,
    ABSTRACT_FROM => 'lib/Geo/IP.pm',
    AUTHOR        => 'T.J. Mather (tjmather@tjmather.com)'
) if ( $ExtUtils::MakeMaker::VERSION >= 5.4301 );

push(
    @extras,
    LICENSE => 'perl_5',
) if ( $ExtUtils::MakeMaker::VERSION >= 6.31 );

push(
    @extras,
    META_MERGE     => {
        resources => {
            bugtracker => 'https://github.com/maxmind/geoip-api-perl/issues',
            repository => 'https://github.com/maxmind/geoip-api-perl',
        },
    },
) if ( $ExtUtils::MakeMaker::VERSION >= 6.46 );

my $pp = delete $config{PP};

WriteMakefile(
    NAME         => 'Geo::IP',
    dist         => { COMPRESS => 'gzip', SUFFIX => '.gz' },
    VERSION_FROM => 'lib/Geo/IP.pm',
    LIBS => $pp ? [] : ['-lGeoIP'],
    DEFINE => '-DPERL_EXT',    # otherwise 'cxinc' isn't defined

    CONFIGURE => sub { @{ $_[1] }{qw/XS C/} = ( {}, [] ) if $pp; $_[1] },
    @extras,
    %config
);
