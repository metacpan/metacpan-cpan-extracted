use strict;
use warnings;
use Test::More;
use Scalar::Util qw(looks_like_number);

BEGIN { use_ok('Linux::Info::SysInfo') }

my $obj     = new_ok('Linux::Info::SysInfo');
my @methods = (
    'get_raw_time',   'get_hostname',
    'get_domain',     'get_kernel',
    'get_release',    'get_version',
    'get_mem',        'get_swap',
    'get_pcpucount',  'get_tcpucount',
    'get_interfaces', 'get_proc_arch',
    'get_cpu_flags',  'get_uptime',
    'get_idletime',   'is_multithread',
    'get_model',      'has_multithread',
    'get_detailed_kernel',
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
    unless ( -r $f ) {
        plan skip_all => "$f is not readable";
        exit(0);
    }
}

like( $obj->get_raw_time,   qr/^[01]$/, 'raw_time is boolean' );
like( $obj->is_multithread, qr/^[01]$/, 'multithread is boolean' );

my @string_methods = (
    'get_hostname', 'get_domain', 'get_kernel', 'get_release',
    'get_version',  'get_mem',    'get_swap',   'get_uptime',
    'get_idletime', 'get_model'
);

my $string_regex = qr/\w+/;

foreach my $method (@string_methods) {
    like( $obj->$method, $string_regex, "$method returns a string" )
      or diag( explain( $obj->{cpu} ) );
}

my $kernel = $obj->get_detailed_kernel;
isa_ok( $kernel, 'Linux::Info::KernelRelease' );

is( ref( $obj->get_interfaces ),
    'ARRAY', "get_interfaces returns an array reference" )
  or diag( explain( check_cpuinfo() ) );

note(
'tests implemented due report http://www.cpantesters.org/cpan/report/9ae1c364-7671-11e5-aad0-c5a10b3facc5'
);

my @cpu_methods = qw(get_pcpucount get_tcpucount );

SKIP: {
    skip 'ARM processors have a different interface on /proc/cpuinfo',
      ( 2 + scalar(@cpu_methods) )
      if ( $obj->get_model =~ /arm/i );
    note('Testing with /proc/cpuinfo');
    ok(
        looks_like_number( $obj->get_proc_arch ),
        'get_proc_arch returns a number'
    ) or diag( explain( check_cpuinfo() ) );
    is( ref( $obj->get_cpu_flags ),
        'ARRAY', "get_cpu_flags returns an array reference" )
      or diag( explain( check_cpuinfo() ) );

    foreach my $method (@cpu_methods) {
        ok( looks_like_number( $obj->$method ), "$method returns a number" )
          or diag( explain $obj->$method );
    }
}

foreach my $cpuinfo_sample ( @{ cpuinfo_samples() } ) {
    note("Testing with sample $cpuinfo_sample");
    my $instance = Linux::Info::SysInfo->new( { cpuinfo => $cpuinfo_sample } );
    like( $obj->get_model, qr/\w+/, 'get_model returns some text' )
      or diag( explain($instance) );

    ok( looks_like_number( $instance->get_proc_arch ),
        "get_proc_arch returns a number" )
      or diag( explain( check_cpuinfo($cpuinfo_sample) ) );

    is( ref( $instance->get_cpu_flags ),
        'ARRAY', "get_cpu_flags returns an array reference" )
      or diag( explain( check_cpuinfo($cpuinfo_sample) ) );

    foreach my $method (qw(get_pcpucount get_tcpucount )) {
        ok( looks_like_number( $instance->$method ),
            "$method returns a number" )
          or diag( explain( check_cpuinfo($cpuinfo_sample) ) );
    }
}

my $obj2 = Linux::Info::SysInfo->new( { raw_time => 1 } );

note('Testing times returned by instance with raw_time attribute set to true');

foreach my $method (qw(get_uptime get_idletime)) {
    ok( looks_like_number( $obj2->$method ), "$method returns a number" );
}

done_testing;

sub check_cpuinfo {
    my $file = shift || '/proc/cpuinfo';
    local $/ = undef;
    my $all_lines = "\nFailed to properly parse information below:\n";
    open( my $in, '<', $file ) or die "cannot read $file: $!";
    $all_lines .= <$in>;
    close($in);
    return $all_lines;
}

sub check_mainline_version {
    my $value = shift;

    # undef is valid
    return 1 unless ($value);
    return ( $value =~ /[\w\.\-]+/ );
}

sub cpuinfo_samples {
    my $dir = 't/samples/cpu';
    opendir( my $in, $dir ) or die "Cannot read $dir: $!";
    my @samples;

    while ( readdir $in ) {
        next if ( ( $_ eq '.' ) or ( $_ eq '..' ) );
        push( @samples, "$dir/$_" );
    }

    closedir $in;

    return \@samples;
}
