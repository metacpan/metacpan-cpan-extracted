use strict;
use warnings;
use Test::More tests => 25;
use Scalar::Util qw(looks_like_number);
use Devel::CheckOS 2.01 qw(os_is);

BEGIN { use_ok('Linux::Info::SysInfo') }

my $obj     = new_ok('Linux::Info::SysInfo');
my @methods = (
    'get_raw_time',   'get_hostname',
    'get_domain',     'get_kernel',
    'get_release',    'get_version',
    'get_mem',        'get_swap',
    'get_pcpucount',  'get_tcpucount',
    'get_interfaces', 'get_arch',
    'get_proc_arch',  'get_cpu_flags',
    'get_uptime',     'get_idletime',
    'is_multithread', 'get_model',
    'get_mainline_version',
);
can_ok( $obj, @methods );

my @pf = qw(
  /proc/sys/kernel/hostname
  /proc/sys/kernel/domainname
  /proc/sys/kernel/ostype
  /proc/sys/kernel/osrelease
  /proc/sys/kernel/version
  /proc/cpuinfo
  /proc/meminfo
  /proc/uptime
);

foreach my $f (@pf) {
    if ( !-r $f ) {
        plan skip_all => "$f is not readable";
        exit(0);
    }
}

like( $obj->get_raw_time,   qr/^[01]$/, 'raw_time is boolean' );
like( $obj->is_multithread, qr/^[01]$/, 'multithread is boolean' );
note( 'Processor model is "' . $obj->get_model . '"' );
like( $obj->get_model, qr/\w+/, 'get_model returns some text' );

my @string_methods = (
    'get_hostname', 'get_domain', 'get_kernel', 'get_release',
    'get_version',  'get_mem',    'get_swap',   'get_arch',
    'get_uptime',   'get_idletime',
);

foreach my $method (@string_methods) {
    like( $obj->$method, qr/\w+/, "$method returns a string" );
}

ok(
    check_mainline_version( $obj->get_mainline_version ),
    'get_mainline_version can fetch a valid value'
);

SKIP: {
    skip 'Not available on Linux distributions not based on Ubuntu', 1
      unless ( os_is('Linux::Ubuntu') );
    ok( $obj->get_mainline_version(),
        'get_mainline_version returns a defined value on Ubuntu-like distros' );
}

note(
'tests implemented due report http://www.cpantesters.org/cpan/report/9ae1c364-7671-11e5-aad0-c5a10b3facc5'
);

SKIP: {

    skip 'ARM processors have a different interface on /proc/cpuinfo', 2
      if ( $obj->get_model =~ /arm/i );
    ok(
        looks_like_number( $obj->get_proc_arch ),
        "get_proc_arch returns a number"
    ) or diag( explain( check_cpuinfo() ) );
    is( ref( $obj->get_cpu_flags ),
        'ARRAY', "get_cpu_flags returns an array reference" )
      or diag( explain( check_cpuinfo() ) );

}

foreach my $method (qw(get_pcpucount get_tcpucount )) {
    ok( looks_like_number( $obj->$method ), "$method returns a number" )
      or diag( explain( check_cpuinfo() ) );
}

is( ref( $obj->get_interfaces ),
    'ARRAY', "get_interfaces returns an array reference" )
  or diag( explain( check_cpuinfo() ) );

my $obj2 = Linux::Info::SysInfo->new( { raw_time => 1 } );

note('Testing times returned by instance with raw_time attribute set to true');

foreach my $method (qw(get_uptime get_idletime)) {
    ok( looks_like_number( $obj2->$method ), "$method returns a number" );
}

sub check_cpuinfo {
    note('Looks like /proc/cpuinfo is missing the "flags" field');
    note(
'Detect issues with flags field as http://www.cpantesters.org/cpan/report/743cb560-6092-11e5-b084-8fcd0b3facc5'
    );

    my $file = '/proc/cpuinfo';
    local $/ = undef;
    open( my $in, '<', $file ) or die "cannot read $file: $!";
    my $all_lines = <$in>;
    close($in);
    return \$all_lines;
}

sub check_mainline_version {
    my $value = shift;

    # undef is valid
    return 1 unless ($value);
    return ( $value =~ /[\w\.\-]+/ );
}
