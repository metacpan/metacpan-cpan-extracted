package Fennec::EndRunner;
use strict;
use warnings;

my $RUNNER;
my $PID;

sub set_runner {
    $RUNNER = pop if @_;
    return $RUNNER;
}

sub set_pid {
    $PID = pop if @_;
    return $PID;
}

END {
    return unless $PID && $PID == $$;
    return if $?;
    return unless $RUNNER;
    return if $RUNNER->_skip_all;
    return if $^C; # Do not print this message if perl is called with -c

    print STDERR <<"    EOT";

###############################################################################
#      **** It does not look like done_testing() was ever called! ****        #
#                                                                             #
#   As of Fennec 2 automatically-running standalone fennect tests are         #
#   deprecated. This descision was made because all run after run-time        #
#   methods are hacky and/or qwerky.                                          #
#                                                                             #
#   Since there are so many legacy Fennec tests that relied on this behavior  #
#   it has been carried forward in this deprecated form. An END block has     #
#   been used to display this message, and will next run your tests.          #
#                                                                             #
#   For most legacy tests this should work fine, however it may cause issues  #
#   with any tests that relied on other END blocks, or various hacky things.  #
#                                                                             #
#   DO NOT RELY ON THIS BEHAVIOR - It may go away in the near future.         #
###############################################################################

    EOT

    $RUNNER->run();

    my $failed = $RUNNER->collector->test_failed;
    return unless $failed;
    $? = $failed;
}

1;

__END__

=head1 NAME

Fennec::EndRunner - Used to run Fennec test when legacy code does not call
done_testing().

=head1 DESCRIPTION

Fennec::EndRunner - Used to run Fennec test when legacy code does not call
done_testing(). Basically a big ugly deprecated END block.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Fennec is free software; Standard perl license.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
