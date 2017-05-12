package Fennec::Finder;
use strict;
use warnings;

use base 'Fennec::Runner';

use File::Find qw/find/;
use Fennec::Util qw/accessors verbose_message/;
use List::Util qw/shuffle/;

accessors qw/test_files parallel/;

sub import {
    my $self = shift->new;
    $self->find_files(@_);
    $self->inject_run( scalar caller );
}

sub init {
    my $self = shift;
    my (%params) = @_;

    $self->test_files( [] );
    $self->parallel( defined $params{parallel} ? $params{parallel} : 2 );

    return $self;
}

sub find_files {
    my $self = shift;
    my @paths = @_ ? @_ : -d './t' ? ('./t') : ('./');

    find(
        {
            wanted => sub {
                my $file = $File::Find::name;
                return unless $self->validate_file($file);
                push @{$self->test_files} => $file;
            },
            no_chdir => 1,
        },
        @paths
    );
}

sub validate_file {
    my $self = shift;
    my ($file) = @_;
    return unless $file =~ m/\.(pm|ft)$/;
    return 1;
}

sub run {
    my $self = shift;
    my ($follow) = @_;

    $self->_ran(1);

    my $frunner = $self->prunner( $self->parallel );

    for my $file ( @{$self->test_files} ) {
        $frunner->run(
            sub {
                $self->load_file($file);

                for my $class ( shuffle @{$self->test_classes} ) {
                    next unless $class;
                    $self->run_test_class($class);
                }
            },
            1
        );

        $self->check_pid;
    }

    $frunner->finish();

    if ($follow) {
        $self->collector->collect;
        verbose_message("Entering final follow-up stage\n");
        eval { $follow->(); 1 } || $self->exception( 'done_testing', $@ );
    }

    $self->collector->collect;
    $self->collector->finish();
}

1;

__END__

=pod

=head1 NAME

Fennec::Finder - Create one .t file to find all .pm test files.

=head1 DESCRIPTION

Originally Fennec made use of a runner loaded in t/Fennec.t that sought out
test files (modules) to run. This modules provides similar, but greatly
simplified functionality.

=head1 SYNOPSIS

Fennec.t:

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Fennec::Finder;

    run();

This will find all .pm and .ft files under t/ and load them. Any that contain
Fennec tests will register themselves to be run once run() is called.

B<Warning, if you have .pm files in t/ that are not tests they will also be
loaded, if any of these have interactions with the packages you are testing you
must account for them.>

=head1 CUSTOMISATIONS

=head2 SEARCH PATHS

When you C<use Fennec::Finder;> the './t/' directory will be searched if it
exists, otherwise the './' directory will be used. You may optionally provide
alternate paths at use time: C<use Fennec::Finder './Fennec', './SomeDir';>

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Fennec::Finder './Fennec', './SomeDir';

    run();

=head2 FILE VALIDATION

If you wish to customize which files are loaded you may subclass
L<Fennec::Finder> and override the C<validate_file( $file )> method. This method takes
the filename to verify as an argument. Return true if the file should be
loaded, false if it should not. Currently the only check is that the filename
ends with a C<.pm>.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Fennec is free software; Standard perl license.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

=cut
