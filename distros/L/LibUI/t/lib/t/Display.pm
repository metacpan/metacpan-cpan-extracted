package    #
    t::Display {
    use Test::More;

    sub needs_display {    # Taken from Test::NeedsDisplay but without Test::More

        # Get rid of Win32 and existing DISPLAY cases
        return 1 if $^O eq 'MSWin32';
        return 1 if $ENV{DISPLAY};

        # The quick way is to use the xvfb-run script
        diag 'No DISPLAY. Looking for xvfb-run...';
        my @PATHS = split $Config::Config{path_sep}, $ENV{PATH};
        foreach my $path (@PATHS) {
            my $xvfb_run = File::Spec->catfile( $path, 'xvfb-run' );
            next unless -e $xvfb_run;
            next unless -x $xvfb_run;
            diag 'Restarting with xvfb-run...';
            exec( $xvfb_run, $^X,
                ( $INC{'blib.pm'} ? '-Mblib' : () ),
                ( $INC{'perl5db.pl'} ? '-d' : () ), $0,
            );
        }

        # If provided with the :skip_all, abort the run
        if ( $_[1] and $_[1] eq ':skip_all' ) {
            plan( skip_all => 'Test needs a DISPLAY' );
            exit(0);
        }
        diag 'Failed to find xvfb-run.';
        diag 'Running anyway, but will probably fail...';
    }
}
1;
