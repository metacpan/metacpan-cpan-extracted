use strict;
use warnings;
use Test::More;

use File::Basename;
use File::Find;

BEGIN {
    require lib;
    my $lib_path = dirname(__FILE__) . '/../lib';
    if ( -d $lib_path ) {
        lib->import($lib_path);
    }
}
our %PATH_OF = (
    t    => dirname(__FILE__),
    libs => [
        dirname(__FILE__) . '/../lib',
    ],
);

my %LIST;
find(
    sub {
        return if -d $_ || $_ !~ m{\.pm$}xms;
        open my $file, '<', $_ or die "can't open >$_<";

        my $is_pod = 0;
        FIND_USE:
        while ( my $line = <$file> ) {
            if ( $line =~ m{\A__END__}xms ) {
                last FIND_USE;
            }
            elsif ( $is_pod && $line =~ m{\A=cut}xmsi ) {
                $is_pod = 0;
                next FIND_USE;
            }
            elsif ( $line =~ m{\A=pod}xmsi ) {
                $is_pod = 1;
                next FIND_USE;
            }
            elsif ( $line =~ m{package\s+([A-Za-z0-9_:]+)\s*;}xms ) {
                $LIST{$1} = $File::Find::name; # value is used for debugging
            }
        }
        close $file;
    },
    $PATH_OF{libs}->[-1],
);

plan tests => scalar keys %LIST;
for my $module (sort keys %LIST) {
    my $file = $LIST{$module};
    local $SIG{ __WARN__ } = sub {};
    use_ok($module);
}

