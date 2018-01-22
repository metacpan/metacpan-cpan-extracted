package MVC::Neaf::Util;

use strict;
use warnings;
our $VERSION = 0.2202;

=head1 NAME

MVC::Neaf::Util - Some static functions for Not Even A Framework

=head1 DESCRIPTION

This module is probably of no use by itself. See L<MVC::Neaf>.

=head1 EXPORT

This module optionally exports anything it has.

=cut

use parent qw(Exporter);
our @EXPORT_OK = qw(
    canonize_path http_date path_prefixes rex run_all run_all_nodie
    JSON encode_json decode_json
);

# use JSON::MaybeXS; # not now, see JSON() below

=head2 http_date

Return a date in format required by HTTP standard for cookies
and cache expiration.

    Expires=Wed, 13 Jan 2021 22:23:01 GMT;

=cut

# Yay premature optimization - use ad-hoc weekdays because locale is so botched
my @week = qw( Sun Mon Tue Wed Thu Fri Sat );
my @month = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
sub http_date {
    my $t = shift;
    my @date = gmtime($t);
    return sprintf( "%s, %02d %s %04d %02d:%02d:%02d GMT"
        , $week[$date[6]], $date[3], $month[$date[4]], 1900+$date[5], @date[2,1,0]);
};

=head2 canonize_path( path, want_slash )

Convert '////fooo//bar/' to '/foo/bar' and '//////' to either '' or '/'.

=cut

# Search for CANONIZE for ad-hoc implementations of this (for speed etc)
sub canonize_path {
    my ($path, $want_slash) = @_;

    $path =~ s#/+#/#g;
    if ($want_slash) {
        $path =~ s#/$##;
        $path =~ s#^/*#/#;
    } else {
        $path =~ s#^/*#/#;
        $path =~ s#/$##;
    };

    return $path;
};

=head2 path_prefixes ($path)

List ('', '/foo', '/foo/bar') for '/foo/bar'

=cut

sub path_prefixes {
    my ($str, $rev) = @_;

    $str =~ s#^/*##;
    $str =~ s#/+$##;
    my @dir = split qr#/+#, $str;
    my @ret = ('');
    my $temp = '';

    push @ret, $temp .= "/$_" for @dir;

    return @ret;
};

=head2 rex( $string || qr/r.e.g.e.x/ )

Convert string or regex to an I<anchored> regex.

=cut

sub rex ($) { ## no critic
    my $in = shift;
    $in = '' unless defined $in;
    return qr/^$in$/;
};

=head2 run_all( [CODE, ...], @args )

Run all subroutines in array. Exceptions not handled. Return nothing.

=cut

sub run_all {
    my $list = shift;

    foreach my $sub (@$list) {
        $sub->(@_);
    };
    return;
};

=head2 run_all_nodie( [CODE, ...], $on_error, @args )

Run all subroutines in array, even if some die.

Execute on_error in such cases.

Return number of failed callbacks.

=cut

sub run_all_nodie {
    my ($list, $on_error, @args) = @_;

    my $dead = 0;
    foreach my $sub (@$list) {
        eval { $sub->(@args); 1; } and next;
        $dead++;
        $on_error->( $@ );
    };

    return $dead;
};

=head2 JSON()

Because JSON::MaybeXS is not available on all systems, try to load it
or emulate it.

=head2 encode_json

=head2 decode_json

These two are reexported from whatever JSON module we were lucky enough
to load.

=cut

sub JSON(); ## no critic

my $luck = eval "use JSON::MaybeXS; 1"; ## no critic
my $err = $@;

if (!$luck) {
    require JSON::PP;
    JSON::PP->import;
    *JSON = sub () { "JSON::PP" };
};

=head1 LICENSE AND COPYRIGHT

This module is part of the L<MVC::Neaf> suite.

Copyright 2016-2017 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
