package Finance::SE::IDX::Any;

our $DATE = '2018-09-08'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Finance::SE::IDX ();

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       list_idx_boards
                       list_idx_firms
                       list_idx_sectors
               );

our %SPEC = %Finance::SE::IDX::SPEC;

our $FALLBACK_PERIOD = 4*3600;

my $warned_static_age;
my $last_fail_time;

sub _doit {
    my $which = shift;

    my $now = time();
    unless ($last_fail_time &&
                ($now-$last_fail_time) <= $FALLBACK_PERIOD) {
        my $res = &{"Finance::SE::IDX::$which"}(@_);
        if ($res->[0] == 200) {
            undef $last_fail_time;
            return $res;
        } else {
            log_warn "Finance::SE::IDX::$which() failed, falling back to ".
                "Finance::SE::IDX::Static version ...";
            $last_fail_time = $now;
        }
    }
    require Finance::SE::IDX::Static;
    unless ($warned_static_age) {
        my $mtime = ${"Finance::SE::IDX::Static::data_mtime"};
        if (($now - $mtime) > 2*30*86400) {
            log_warn "Finance::SE::IDX::Static version is older than 60 days, ".
                "data might be out of date, please consider updating to a ".
                "new version of Finance::SE::IDX::Static";
        }
        $warned_static_age++;
    }
    return &{"Finance::SE::IDX::Static::$which"}(@_);
}

sub list_idx_boards  { _doit("list_idx_boards", @_) }

sub list_idx_firms   { _doit("list_idx_firms", @_) }

sub list_idx_sectors { _doit("list_idx_sectors", @_) }

1;
# ABSTRACT: Get information from Indonesian Stock Exchange

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::SE::IDX::Any - Get information from Indonesian Stock Exchange

=head1 VERSION

This document describes version 0.001 of Finance::SE::IDX::Any (from Perl distribution Finance-SE-IDX-Any), released on 2018-09-08.

=head1 SYNOPSIS

Use like you would use L<Finance::SE::IDX>.

=head1 DESCRIPTION

This module provides the same functions as L<Finance::SE::IDX>, e.g.
C<list_idx_firms> and will call the Finance::SE::IDX version but will fallback
for a while (default: 4 hours) to the L<Finance::SE::IDX::Static> version when
the functions fail.

=head1 VARIABLES

=head2 $FALLBACK_PERIOD

Specify, in seconds, how long should the fallback (static) version be used after
a failure. Default is 4*3600 (4 hours).

=head1 FUNCTIONS


=head2 list_idx_boards

Usage:

 list_idx_boards() -> [status, msg, result, meta]

List boards.

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_idx_firms

Usage:

 list_idx_firms(%args) -> [status, msg, result, meta]

List firms.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<board> => I<str>

=item * B<sector> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_idx_sectors

Usage:

 list_idx_sectors() -> [status, msg, result, meta]

List sectors.

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-SE-IDX-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-SE-IDX-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-SE-IDX-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Finance::SE::IDX>

L<Finance::SE::IDX::Static>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
