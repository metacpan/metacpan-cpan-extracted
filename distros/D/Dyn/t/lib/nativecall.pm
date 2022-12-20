package t::lib::nativecall {
    use strict;
    use warnings;
    use Test::More;
    use experimental 'signatures';
    use Exporter 'import';
    our @EXPORT = qw[compile_test_lib compile_cpp_test_lib is_approx];
    use Config;
    #
    my $OS = $^O;
    my @cleanup;
    #
    sub compile_test_lib ($name) {
        my $libname = $name . '.' . $Config{so};

        #warn $libname;
        my @cmds;

        #$VM;
        #my $cfg = $VM->{config};
        if ( $OS eq 'MSWin32' ) {
            @cmds = (
                "cl /LD /EHsc /Fe$libname t/src/$name.c",
                "gcc --shared -fPIC -DBUILD_LIB -o t/$libname t/src/$name.c"
            );
        }
        else {
            @cmds = (
                "gcc --shared -fPIC -DBUILD_LIB -o t/$libname t/src/$name.c",
                "clang -stdlib=libc --shared -fPIC -o t/$libname t/src/$name.c"
            );
        }
        my ( @fails, $succeeded );
        for my $cmd (@cmds) {

            #my $out = `$cmd 2>&1`;
            last if !system(qq[$cmd 2>&1]);

            #warn $out;
            #system (qq"$cmd 2>&1") == 0 or warn qq[system( $cmd ) failed: $?];
        }
        push @cleanup, $libname;
    }

    sub compile_cpp_test_lib ($name) {
        my $libname = $name . '.' . $Config{so};

        #warn $libname;
        my @cmds;

        #$VM;
        #my $cfg = $VM->{config};
        if ( $OS eq 'MSWin32' ) {
            @cmds = (
                "cl /LD /EHsc /Fe$libname t/src/$name.cpp",
                "g++ --shared -fPIC -DBUILD_LIB -o t/$libname t/src/$name.cpp"
            );
        }
        else {
            @cmds = (
                "g++ --shared -fPIC -DBUILD_LIB -o t/$libname t/src/$name.cpp",
                "clang++ -stdlib=libc++ --shared -fPIC -o t/$libname t/src/$name.cpp"
            );
        }
        my ( @fails, $succeeded );
        for my $cmd (@cmds) {

            #my $out = `$cmd 2>&1`;
            last if !system(qq[$cmd 2>&1]);

            #warn $out;
            #system (qq"$cmd 2>&1") == 0 or warn qq[system( $cmd ) failed: $?];
        }
        push @cleanup, $libname;
    }

    END {
        unlink $_ for @cleanup;
    }

    sub is_approx ( $actual, $expected, $desc ) {    # https://docs.raku.org/routine/is-approx
        ok abs( $actual - $expected ) < 1e-6, $desc;
    }
};
1;
