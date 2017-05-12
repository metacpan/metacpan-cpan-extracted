package LWP::UserAgent::ProgressAny;

our $DATE = '2015-01-23'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

use Number::Format::Metric qw(format_metric);
use Progress::Any;
use Scalar::Util qw(refaddr);

use parent 'LWP::UserAgent';

sub __get_task_name {
    my $resp = shift;

    # each response object has its own task, so we don't have problem with
    # parallel downloads
    my $task = __PACKAGE__; $task =~ s/::/./g;
    $task .= ".R" . refaddr($resp);
    $task;
}

sub __add_handlers {
    my $ua = shift;

    $ua->add_handler(response_data => sub {
        my ($resp, $ua, $h, $data) = @_;

        my $task = __get_task_name($resp);

        my $progress = Progress::Any->get_indicator(task=>$task);
        unless ($ua->{_pa_data}{set_target}{"$resp"}++) {
            $progress->pos(0);
            if (my $cl = $resp->content_length) {
                $progress->target($cl);
            }
        }
        my $new_pos = $progress->pos + length($data);
        my $target  = $progress->target;

        if ($target && $new_pos >= $target) {
            $progress->finish;

            # cleanup so the number of tasks can be kept low. XXX we should do
            # this via API.
            no warnings 'once';
            delete $Progress::Any::indicators{$task};
            delete $ua->{_pa_data}{set_target}{"$resp"};
        } else {
            $progress->update(
                pos => $new_pos,
                message => sub {
                    my @msg = (
                        "<elspan prio=2>Downloading </elspan>",

                        "<elspan prio=3 truncate=middle>",
                        $resp->{_request}{_uri},
                        " </elspan>",

                        format_metric($new_pos),
                    );
                    if ($progress->target) {
                        push @msg, "/", format_metric($progress->target);
                    }
                    # XXX show speed
                    join "", @msg;
                },
            );
        }

        # so we are called again for the next chunk
        1;
    });
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    __add_handlers($self);
    $self;
}

1;
# ABSTRACT: See progress for your LWP::UserAgent requests

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::ProgressAny - See progress for your LWP::UserAgent requests

=head1 VERSION

This document describes version 0.06 of LWP::UserAgent::ProgressAny (from Perl distribution LWP-UserAgent-ProgressAny), released on 2015-01-23.

=head1 SYNOPSIS

Use as L<LWP::UserAgent> subclass:

 use LWP::UserAgent::ProgressAny;
 use Progress::Any::Output;

 my $ua = LWP::UserAgent::ProgressAny->new;
 Progress::Any::Output->set("TermProgressBarColor");
 my $resp = $ua->get("http://example.com/some-big-file");
 # you will see a progress bar in your terminal

Use with standard LWP::UserAgent or other subclasses:

 use LWP::UserAgent;
 use LWP::UserAgent::ProgressAny;
 use Progress::Any::Output;

 my $ua = LWP::UserAgent->new;
 LWP::UserAgent::ProgressAny::__add_handlers($ua);
 Progress::Any::Output->set("TermProgressBarColor");
 my $resp = $ua->get("http://example.com/some-big-file");

=head1 DESCRIPTION

This module lets you see progress indicators when you are doing requests with
L<LWP::UserAgent>.

This module uses L<Progress::Any> framework.

Sample output:

=for HTML <img src="https://perlancar.files.wordpress.com/2015/01/screenshot-lwp-ua-progany-12.jpg" />

=head1 SEE ALSO

L<LWP::UserAgent::ProgressBar> (LU::PB) is a similar module. It uses
L<Term::ProgressBar> to display progress bar and introduces two new methods:
C<get_with_progress> and C<post_with_progress>. Compared to
LWP::UserAgent::ProgressAny (LU::PA): LU::PA uses L<Progress::Any> so you can
get progress notification via means other than terminal progress bar simply by
choosing another progress output. LU::PA is also more transparent, you don't
have to use a different method to do requests. Lastly, LU::PA can be used with
standard LWP::UserAgent or its other subclasses.

L<HTTP::Tiny::ProgressAny>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-UserAgent-ProgressAny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-LWP-UserAgent-ProgressAny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-ProgressAny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
