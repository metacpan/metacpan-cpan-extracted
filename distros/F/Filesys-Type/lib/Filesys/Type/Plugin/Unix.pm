package Filesys::Type::Plugin::Unix;
use strict;

our $VERSION = 0.02;
our ($df,$mounted,$err);

sub new {
    my $pkg = shift;

#Check we really are on a Unix type operating system
    return undef unless -d '/etc';

    bless {}, $pkg;
}

sub fstype {
    my ($self,$path) = @_;
    $err = '';

    $df = `df $path 2>/dev/null`;
    $err = 'df command failed' unless $df;
    $mounted = `mount 2>/dev/null`;   # Does not need root
    $err = 'mount command failed' unless $df;
    return undef if $err;

    my ($mounted_fs) = $df =~ /\d\%\s(\S+)/;
    $err = 'df output did not parse' unless $mounted_fs;
    return undef if $err;
    
    my ($fstype) = $mounted =~ /on\s$mounted_fs\stype\s(\w+)/;
    $fstype;
}

sub diagnose {
    $df ||= 'undef';
    $mounted ||= 'undef';
    <<END;
$err

df command returned: $df

mount command returned: $mounted

END
}
1;

