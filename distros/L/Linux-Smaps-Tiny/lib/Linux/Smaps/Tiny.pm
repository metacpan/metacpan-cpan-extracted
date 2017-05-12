package Linux::Smaps::Tiny;
BEGIN {
  $Linux::Smaps::Tiny::AUTHORITY = 'cpan:AVAR';
}
{
  $Linux::Smaps::Tiny::VERSION = '0.10';
}
use strict;
use warnings FATAL => "all";

BEGIN {
    local ($@, $!);
    eval {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $Linux::Smaps::Tiny::VERSION || '0.01');
    };
}

use Exporter 'import';

our @EXPORT_OK = qw(get_smaps_summary);

=encoding utf8

=head1 NAME

Linux::Smaps::Tiny - A minimal and fast alternative to L<Linux::Smaps>

=head1 SYNOPSIS

    use Linux::Smaps::Tiny qw(get_smaps_summary);

    my $summary = get_smaps_summary();
    my $size = $summary->{Size};
    my $shared_clean = $summary->{Shared_Clean};
    my $shared_dirty = $summary->{Shared_Dirty};

    print "Size / Clean / Dirty = $size / $shared_clean / $shared_dirty\n";

=head1 DESCRIPTION

This module is a tiny interface to F</proc/PID/smaps> files. It was
written because when we rolled out L<Linux::Smaps> in some critical
code at a Big Internet Company we experienced slowdowns that were
solved by writing a more minimal version.

This module will try to use XS code to parse the smaps file, and if
that doesn't work it'll fall back on a pure-Perl version.

If something like that isn't your use case you should probably use
L<Linux::Smaps> instead. Also note that L<Linux::Smaps> itself L<has
been
optimized|http://mail-archives.apache.org/mod_mbox/perl-modperl/201103.mbox/browser>
since this module was initially written.

=head2 SPEED

The distribution comes with a F<contrib/benchmark.pl> script. As of
writing this is the speed of L<Linux::Smaps>
v.s. L<Linux::Smaps::Tiny>, both the XS and PP versions:

                             Rate Linux::Smaps Linux::Smaps::Tiny::PP Linux::Smaps::Tiny
    Linux::Smaps            810/s           --                   -22%               -61%
    Linux::Smaps::Tiny::PP 1033/s          28%                     --               -51%
    Linux::Smaps::Tiny     2101/s         159%                   103%                 --

=head1 FUNCTIONS

=head2 get_smaps_summary

Takes an optional process id (defaults to C<self>) returns a summary
of the smaps data for the given process. Dies if the process does not
exist.

Returns a hashref like this:

        {
          'MMUPageSize' => '184',
          'Private_Clean' => '976',
          'Swap' => '0',
          'KernelPageSize' => '184',
          'Pss' => '1755',
          'Private_Dirty' => '772',
          'Referenced' => '2492',
          'Size' => '5456',
          'Shared_Clean' => '744',
          'Shared_Dirty' => '0',
          'Rss' => '2492'
        };

Values are in kB.

=cut

unless (defined &get_smaps_summary) {
    require Linux::Smaps::Tiny::PP;
    *get_smaps_summary = \&Linux::Smaps::Tiny::PP::__get_smaps_summary;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Yves Orton <yves@cpan.org> and Ævar Arnfjörð Bjarmason
<avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
