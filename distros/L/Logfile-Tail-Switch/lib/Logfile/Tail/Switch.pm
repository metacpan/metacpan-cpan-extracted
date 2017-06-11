package Logfile::Tail::Switch;

our $DATE = '2017-06-09'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Time::HiRes 'time';

sub new {
    my ($class, %args) = @_;

    my $self = {
        _cur_file  => {},
        _cur_fh    => {},
        _pending   => {},
        check_freq => 2,
        tail_new   => 0,
    };

    if (defined(my $globs = delete $args{globs})) {
        ref($globs) eq 'ARRAY' or die "globs must be arrayref";
        $self->{globs} = $globs;
    } else {
        die "Please specify globs";
    }
    if (defined(my $check_freq = delete $args{check_freq})) {
        $self->{check_freq} = $check_freq;
    }
    if (defined(my $tail_new = delete $args{tail_new})) {
        $self->{tail_new} = $tail_new;
    }
    die "Unknown arguments: ".join(", ", keys %args) if keys %args;

    bless $self, $class;
}

sub _switch {
    my ($self, $glob, $filename, $seek_end) = @_;

    #say "D: opening $filename";
    $self->{_cur_file}{$glob} = $filename;
    open my $fh, "<", $filename or die "Can't open $filename: $!";
    seek $fh, 0, 2 if $seek_end;
    $self->{_cur_fh}{$glob} = $fh;
}

sub _getline {
    my ($self, $fh) = @_;

    my $size = -s $fh;
    my $pos = tell $fh;
    #say "D:size=<$size>, pos=<$pos>";
    if ($pos == $size) {
        # we are still at the end of file, return empty string
        return '';
    } elsif ($pos > $size) {
        # file reduced in size, it probably means it has been rotated, start
        # from the beginning
        seek $fh, 0, 0;
    } else {
        # there are new content to read after our position
    }
    return(<$fh> // '');
}

sub getline {
    my $self = shift;

    my $now = time();

  CHECK_NEWER_FILES:
    {
        last if $self->{_last_check_time} &&
            $self->{_last_check_time} >= $now - $self->{check_freq};
        $self->{_last_check_time} = $now;
        #say "D: checking for newer file";
        for my $glob (@{ $self->{globs} }) {
            my @files = sort glob($glob);
            #say "D: files matching glob: ".join(", ", @files);
            unless (@files) {
                warn "No files matched '$glob'";
                next;
            }
            if (defined $self->{_cur_fh}{$glob}) {
                for (@files) {
                    # there is a newer file than the current one, add to the
                    # pending list of files to be read after the current one say
                    if ($_ gt $self->{_cur_file}{$glob}) {
                        #say "D: there is a newer file: $_";
                        $self->{_pending}{$glob}{$_} = 1;
                    }
                }
            } else {
                # this is our first time, pick the newest file in the pattern
                # and tail it.
                $self->_switch($glob, $files[-1], 1);
            }
        }
    }

    my $line = '';
    for my $glob (@{ $self->{globs} }) {
        my $fh = $self->{_cur_fh}{$glob};
        next unless $fh;
        $line = $self->_getline($fh);
        if (length $line) {
            last;
        } elsif (keys %{$self->{_pending}{$glob}}) {
            # switch to a newer named file
            my @files = sort keys %{$self->{_pending}{$glob}};
            $self->_switch($glob, $files[0], $self->{tail_new});
            delete $self->{_pending}{$glob}{$files[0]};
            $line = $self->_getline($self->{_cur_fh}{$glob});
            last if length $line;
        }
    }
    $line;
}

1;
# ABSTRACT: Tail a file, but switch when another file with newer name appears

__END__

=pod

=encoding UTF-8

=head1 NAME

Logfile::Tail::Switch - Tail a file, but switch when another file with newer name appears

=head1 VERSION

This document describes version 0.003 of Logfile::Tail::Switch (from Perl distribution Logfile-Tail-Switch), released on 2017-06-09.

=head1 SYNOPSIS

 use Logfile::Tail::Switch;
 use Time::HiRes 'sleep'; # for subsecond sleep

 my $tail = Logfile::Tail::Switch->new(
     globs => ["/s/example.com/syslog/http_access.*.log"],
     # check_freq => 2,
     # tail_new => 0,
 );

 # tail
 while (1) {
     my $line = $tail->getline;
     if (length $line) {
         print $line;
     } else {
        sleep 0.1;
     }
 }

=head1 DESCRIPTION

This class can be used to tail a file, but switch when a file of a newer name
appears. For example, on an Spanel server, the webserver is configured to write
to daily log files:

 /s/<SITE-NAME>/syslog/http_access.<YYYY>-<MM>-<DD>.log
 /s/<SITE-NAME>/syslog/https_access.<YYYY>-<MM>-<DD>.log

So, when tailing you will need to switch to a new log file if you cross day
boundary.

When using this class, you specify a glob pattern of files, e.g.
C</s/example.com/syslog/http_access.*.log>. Then you call the C<getline> method.

This class will first select the newest file (via asciibetical sorting) from the
glob pattern and tail it. Then, periodically (by default at most every 2
seconds) the glob pattern will be checked again. If there is one or more newer
files, they will be read in full and then tail-ed, until an even newer file
comes along. For example, this is the list of files in C</s/example.com/syslog>
at time I<t1>:

 http_access.2017-06-05.log.gz
 http_access.2017-06-06.log
 http_access.2017-06-07.log

C<http_access.2017-06-07.log> will first be tail-ed. When
C<http_access.2017-06-08.log> appears at time I<t2>, this file will be read from
start to finish then tail'ed. When C<http_access.2017-06-09.log> appears the
next day, that file will be read then tail'ed. And so on.

=for Pod::Coverage ^(DESTROY)$

=head1 METHODS

=head2 Logfile::Tail::Switch->new(%args) => obj

Constructor.

Known arguments:

=over

=item * globs => array

Glob patterns.

=item * check_freq => posint (default: 2)

=item * tail_new => bool

If set to true, then new file that appears will be tail'ed instead of read from
the beginning.

=back

=head2 $tail->getline() => str

Will return the next line or empty string if no new line is available.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Logfile-Tail-Switch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Logfile-Tail-Switch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Logfile-Tail-Switch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Tail>, L<File::Tail::Dir>, L<IO::Tail>

L<Tie::Handle::TailSwitch>

L<tailswitch> from L<App::tailswitch>

Spanel, L<http://spanel.info>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
