== Running valgrind

This distro ships with a valgrind suppressions file that suppresses leaks that
occur from inside the Perl core as well as leaks from other modules.

You can valgrind with a command like this:

    ./Build && \
    valgrind --leak-check=full --num-callers=50 --suppressions=./valgrind.supp \
        -- perl -Mblib -I ../MaxMind-DB-Reader-perl/lib/ t/MaxMind/DB/Reader.t

This assumes you have the MaxMind-DB-Reader-perl repo checked out in the
parent directory.
