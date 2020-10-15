package IP::World;

# World.pm - the Perl part of the IP::World module
#   this module maps from IP addresses to country codes, using the free
#   WorldIP (wipmania.com) and GeoLite Country (maxmind.com) databases

use strict;
use warnings;
use Carp;
use File::ShareDir qw(module_dir);
use Exporter qw(import);

require DynaLoader;
our @ISA = qw(DynaLoader);

our $VERSION = '0.42';

our @EXPORT_OK = qw(IP_WORLD_FAST IP_WORLD_MMAP IP_WORLD_TINY IP_WORLD_TINY_PERL);

sub new {
    my ($pkg, $mode) = @_;
    if(!defined($mode)) { $mode = 0 }

    my $dd = module_dir('IP::World');
    if (!$dd) {croak "Can't locate directory containing database file"}
    my $filepath = "$dd/ipworld.dat";
    my $fileLen;

    if (!-e $filepath
     || !($fileLen = -s $filepath)) {
        croak "$filepath doesn't exist or has 0 length\n";
    }
    # call the C (XS) part of new to read the file into memory
    my $self = allocNew ($filepath, $fileLen, $mode);
    
    # bless the value from allocNew to be an object, and return it
    bless (\$self, $pkg);
    return \$self;
}

sub IP_WORLD_FAST { 0 }
sub IP_WORLD_MMAP { 1 }
sub IP_WORLD_TINY { 2 }
sub IP_WORLD_TINY_PERL { 3 }

# 'getcc' and 'DESTROY' are implemented in the IP/World.xs file.

bootstrap IP::World $VERSION;
1;  # shows package is OK
