package builder::MyBuilder;
use strict;
use warnings FATAL => 'all';
use 5.008005;
use base 'Module::Build::XSUtil';
use Config;
use File::Which qw(which);
use EV::MakeMaker '$installsitearch';

sub new {
    my ( $class, %args ) = @_;
    my $self = $class->SUPER::new(
        %args,
        generate_ppport_h    => 'src/ppport.h',
        c_source             => 'src',
        xs_files             => { 'src/EV__Hiredis.xs' => 'lib/EV/Hiredis.xs' },
        include_dirs         => ['src', 'deps/hiredis', "${installsitearch}/EV", $installsitearch],
        extra_linker_flags   => ["deps/hiredis/libhiredis$Config{lib_ext}"],
    );

    my $make;
    if ($^O =~ m/bsd$/ && $^O !~ m/gnukfreebsd$/) {
        my $gmake = which('gmake');
        unless (defined $gmake) {
            print "'gmake' is necessary for BSD platform.\n";
            exit 0;
        }
        $make = $gmake;
    } else {
        $make = $Config{make};
    }

    $self->do_system($make, '-C', 'deps/hiredis', 'static');
    return $self;
}

1;
