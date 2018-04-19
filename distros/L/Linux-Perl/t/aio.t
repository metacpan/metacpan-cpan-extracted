#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;
use Test::SharedFork;

use File::Temp;
use File::Slurp;
use Module::Load;

use FindBin;
use lib "$FindBin::Bin/lib";
use LP_EnsureArch;

my $arch = LP_EnsureArch::ensure_support('aio');

plan 'skip_all' if !$arch;

my $base_class = 'Linux::Perl::aio';

for my $class ( $base_class, "$base_class\::$arch" ) {
    note "===== $class";

    fork or do {
        Module::Load::load($class);

        eval {
            my $aio = $class->new(1024);
            isa_ok( $aio, $class, 'return from new()' );

            my $dir = File::Temp::tempdir( CLEANUP => 1 );

            {
                note "simple read";

                File::Slurp::write_file( "$dir/abc", "abcdef" );

                open my $rfh, '<', "$dir/abc";

                my $buf = "\0" x 25;

                my $control = $aio->create_control(
                    $rfh,
                    \$buf,
                    lio_opcode => 'PREAD',
                );

                my $submitted = $aio->submit($control);

                is( $submitted, 1, 'submit() worked' );

                my @events = $aio->getevents( 1, 1, 10 );

                cmp_deeply(
                    \@events,
                    [
                        superhashof( {
                        obj => $control->id(),
                        } ),
                    ],
                    'getevents() return',
                );

                is(
                    ${ $control->buffer_sr() },
                    'abcdef' . ( "\0" x 19 ),
                    'did read',
                );
            }

            {
                note 'partial read';

                File::Slurp::write_file( "$dir/abc", "abcdef" );

                open my $rfh, '<', "$dir/abc";

                my $aio = $class->new(1);

                my $buf = "\0" x 25;

                my $submitted = $aio->submit(
                    $aio->create_control(
                        $rfh,
                        \$buf,
                        lio_opcode    => 'PREAD',
                        buffer_offset => 2,
                        nbytes        => 2,
                    ),
                );

                is( $submitted, 1, 'submit() worked' );

                my @events = $aio->getevents( 1, 1, 10 );

                is(
                    $buf,
                    "\0\0" . 'ab' . ( "\0" x 21 ),
                    'did read',
                ) or diag explain sprintf "%v.02x", $buf;
            }

            {
                note 'multi read';

                File::Slurp::write_file( "$dir/abc", "abcdef" );
                File::Slurp::write_file( "$dir/123", "123456789" );

                open my $rfh,  '<', "$dir/abc";
                open my $rfh2, '<', "$dir/123";

                my $aio = $class->new(10);

                my $buf = "\0" x 25;

                my $first = $aio->create_control(
                    $rfh,
                    \$buf,
                    lio_opcode => 'PREAD',
                    nbytes     => 6,
                );

                my $second = $aio->create_control(
                    $rfh2,
                    \$buf,
                    lio_opcode    => 'PREAD',
                    buffer_offset => 6,
                );

                my $submitted = $aio->submit( $first, $second );

                is( $submitted, 2, 'submit() worked' );

                my @events = $aio->getevents( 2, 2, 10 );

                is(
                    $buf,
                    'abcdef123456789' . ( "\0" x 10 ),
                    'did read',
                );
            }

            {
                note 'eventfd';

                require Linux::Perl::eventfd;

                File::Slurp::write_file( "$dir/abc", "abcdef" );

                open my $rfh, '<', "$dir/abc";

                my $buf = "\0" x 25;

                my $eventfd = Linux::Perl::eventfd->new();

                my $control = $aio->create_control(
                    $rfh,
                    \$buf,
                    lio_opcode => 'PREAD',
                    eventfd => $eventfd->fileno(),

                    #Unsupported on too many kernels.
                    #rw_flags => ['HIPRI'],
                );

                my $submitted = $aio->submit($control);

                is( $submitted, 1, 'submit() worked' );

                my $efd_read = $eventfd->read();

                my @events = $aio->getevents( 1, 1, 0 );

                cmp_deeply(
                    \@events,
                    [
                        superhashof( {
                            obj => $control->id(),
                        } ),
                    ],
                    'getevents() return',
                );

                is(
                    ${ $control->buffer_sr() },
                    'abcdef' . ( "\0" x 19 ),
                    'did read',
                );
            }

            {
                note 'eventfd on write';

                require Linux::Perl::eventfd;

                open my $wfh, '>', "$dir/abc";

                my $buf = 'This is my buffer!';

                my $eventfd = Linux::Perl::eventfd->new();

                my $control = $aio->create_control(
                    $wfh,
                    \$buf,
                    lio_opcode => 'PWRITE',
                    eventfd => $eventfd->fileno(),
                );

                my $submitted = $aio->submit($control);

                is( $submitted, 1, 'submit() worked' );

                my $efd_read = $eventfd->read();

                my @events = $aio->getevents( 1, 1, 0 );

                cmp_deeply(
                    \@events,
                    [
                        superhashof( {
                            obj => $control->id(),
                        } ),
                    ],
                    'getevents() return',
                );

                my $contents = File::Slurp::read_file("$dir/abc");

                is(
                    $contents,
                    $buf,
                    'did write',
                );
            }
        };
        die if $@;
        exit;
    };

    wait;
    ok( !$?, $class );
}

done_testing() if $arch;
