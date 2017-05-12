package Devel::Mutator::Command::Test;

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Text::Diff;
use File::Path qw(remove_tree);
use File::Copy qw(copy move);
use File::Spec;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{verbose} = $params{verbose} || 0;
    $self->{remove}  = $params{remove}  || 0;
    $self->{timeout} = $params{timeout} || 10;
    $self->{root}    = $params{root}    || '.';
    $self->{command} = $params{command} || 'prove -l t';

    return $self;
}

sub run {
    my $self = shift;

    my $mutants_dir = File::Spec->catfile($self->{root}, 'mutants');
    my @mutants = $self->_read_dir($mutants_dir);

    my $total   = @mutants;
    my $current = 1;
    my $failed  = 0;
    foreach my $mutant (@mutants) {
        print "($current/$total) $mutant ... ";
        $current++;

        my ($mutant_id, $orig_file) = $mutant =~ m{^\Q$mutants_dir\E/(.*?)/(.*$)};
        $orig_file = File::Spec->catfile($self->{root}, $orig_file);
        move($orig_file, "$orig_file.bak");

        copy($mutant, $orig_file);

        my $rv = $self->_run_command;

        if ($rv == 0) {
            $failed++;
            print "not ok\n";

            print diff($mutant, "$orig_file.bak");
        }
        elsif ($rv == -1) {
            print "n/a (timeout $self->{timeout}s)\n";

            print diff($mutant, "$orig_file.bak");
        }
        else {
            if ($self->{remove}) {
                remove_tree("$mutants_dir/$mutant_id");
            }

            print "ok\n";
        }

        move("$orig_file.bak", $orig_file);
    }

    if ($failed) {
        print "Result: FAIL ($failed/$total)\n";

        return 255;
    }
    else {
        print "Result: PASS\n";

        return 0;
    }
}

sub _run_command {
    my $self = shift;

    my $ALARM_EXCEPTION = "alarm timeout";

    my $pid = fork;
    if ($pid == 0) {
        setpgrp(0, 0);

        capture {
            exec $self->{command};
        };

        exit 0;
    }

    eval {
        local $SIG{ALRM} = sub { die $ALARM_EXCEPTION };
        alarm $self->{timeout};

        waitpid($pid, 0);

        alarm 0;
    };

    my $rv = $?;

    if ($@) {
        alarm 0;

        if ($@ =~ quotemeta($ALARM_EXCEPTION)) {
            kill -9, $pid;
            $rv = -1;
        }
        else { die; }
    }

    return $rv;
}

sub _read_dir {
    my $self = shift;
    my ($dir) = @_;

    opendir(my $dh, $dir) || die "Can't open directory '$dir'";
    my @files;
    while ($_ = readdir $dh) { #using without explicit assign requires perl 5.12
        next if /^\./;

        my $file = "$dir/$_";

        if (-d $file) {
            push @files, $self->_read_dir($file);
        }
        else {
            push @files, $file;
        }
    }
    closedir $dh;

    return @files;
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Devel::Mutator::Command::Test - Module

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new>

=head2 C<run>

=head1 AUTHOR

Viacheslav Tykhanovskyi, E<lt>viacheslav.t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
