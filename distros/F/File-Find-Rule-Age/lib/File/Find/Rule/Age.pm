package File::Find::Rule::Age;

use strict;
use warnings;

our $VERSION = "0.302";

use base "File::Find::Rule";

use Carp 'carp';
use DateTime;
use File::stat;
use Params::Util qw(_STRING _NONNEGINT _INSTANCE);

my %mapping = (
    "D" => "days",
    "W" => "weeks",
    "M" => "months",
    "Y" => "years",
    "h" => "hours",
    "m" => "minutes",
    "s" => "seconds",
);

my %criteria = (
    older => 1,
    newer => 1,
);

sub File::Find::Rule::age
{
    my ( $me, $criterion, $age ) = @_;
    my ( $interval, $unit ) = ( $age =~ m/^(\d+)([DWMYhms])$/ );
    return carp "Duration or Unit missing" unless ( $interval and $unit );

    $criterion = lc($criterion);
    defined $criteria{$criterion} or return carp "Invalid criterion: $criterion";

    my $self     = $me->_force_object;
    my $sub2exec = $criterion eq "older"
      ? sub {
        my $dt = DateTime->now;
        $dt->subtract( $mapping{$unit} => $interval );
        stat($_)->mtime < $dt->epoch;
      }
      : sub {
        my $dt = DateTime->now;
        $dt->subtract( $mapping{$unit} => $interval );
        stat($_)->mtime > $dt->epoch;
      };
    $self->exec($sub2exec);
}

sub File::Find::Rule::modified_before
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->mtime < stat($ts)->mtime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->mtime < $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->mtime < $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->mtime < $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

sub File::Find::Rule::modified_until
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->mtime <= stat($ts)->mtime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->mtime <= $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->mtime <= $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->mtime <= $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

sub File::Find::Rule::modified_since
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->mtime >= stat($ts)->mtime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->mtime >= $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->mtime >= $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->mtime >= $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

sub File::Find::Rule::modified_after
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->mtime > stat($ts)->mtime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->mtime > $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->mtime > $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->mtime > $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

#############################################################################

sub File::Find::Rule::accessed_before
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->atime < stat($ts)->atime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->atime < $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->atime < $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->atime < $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

sub File::Find::Rule::accessed_until
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->atime <= stat($ts)->atime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->atime <= $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->atime <= $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->atime <= $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

sub File::Find::Rule::accessed_since
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->atime >= stat($ts)->atime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->atime >= $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->atime >= $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->atime >= $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

sub File::Find::Rule::accessed_after
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->atime > stat($ts)->atime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->atime > $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->atime > $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->atime > $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

#############################################################################

sub File::Find::Rule::created_before
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->ctime < stat($ts)->ctime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->ctime < $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->ctime < $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->ctime < $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

sub File::Find::Rule::created_until
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->ctime <= stat($ts)->ctime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->ctime <= $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->ctime <= $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->ctime <= $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

sub File::Find::Rule::created_since
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->ctime >= stat($ts)->ctime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->ctime >= $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->ctime >= $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->ctime >= $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

sub File::Find::Rule::created_after
{
    my ( $me, $ts ) = @_;

    my $self = $me->_force_object;
    _STRING($ts) and -e $ts and return $self->exec(
        sub {
            stat($_)->ctime > stat($ts)->ctime;
        }
    );

    _NONNEGINT($ts) and return $self->exec(
        sub {
            stat($_)->ctime > $ts;
        }
    );
    _INSTANCE( $ts, "DateTime" ) and return $self->exec(
        sub {
            stat($_)->ctime > $ts->epoch;
        }
    );
    _INSTANCE( $ts, "DateTime::Duration" ) and return $self->exec(
        sub {
            my $dt = DateTime->now() - $ts;
            stat($_)->ctime > $dt->epoch;
        }
    );
    carp "Cannot parse reference";
}

#############################################################################

1;
__END__

=head1 NAME

File::Find::Rule::Age - rule to match on file age

=head1 SYNOPSIS

    # Legacy API
    use File::Find::Rule::Age;
    my @old_files = find( file   => age => [ older => '1M' ], in => '.' );
    my @today     = find( exists => age => [ newer => '1D' ], in => '.' );

=head1 DESCRIPTION

File::Find::Rule::Age makes it easy to search for files based on their age.
DateTime and File::stat are used to do the behind the scenes work, with
File::Find::Rule doing the Heavy Lifting.

=head1 FUNCTIONS

=head2 Legacy Interface

    age( [ $criterion => $age ] )

=over 4

=item $criterion

must be one of "older" or "newer", respectively.

=item $age

must match /^(\d+)([DWMYhms])$/ where D, W, M, Y, h, m and s are "day(s)",
"week(s)", "month(s)", "year(s)", "hour(s)", "minute(s)"  and "second(s)",
respectively - I bet you weren't expecting that.

The given interval is subtracted from C<now> for every file which is checked
to ensure search rules instantiated once and executed several times in
process lifetime.

=back

By 'age' I mean 'time elapsed after mtime' (the last time the file was
modified) - without the equal timestamp.

    # now is 2014-05-01T00:00:00, start of this years workers day
    # let's see what has been worked last week
    my @old_files = find( file => age => [ older => "1W" ], in => $ENV{HOME} );
    # @old_files will now contain all files changed 2014-04-24T00:00:01 or later,
    # 2014-04-24T00:00:00 is ignored

=head2 Modern API

The modern API provides 12 functions to match timestamps:

             | before  | until    | since    | after
   ----------+---------+----------+----------+---------
    modfied  | mtime < | mtime <= | mtime >= | mtime >
   ----------+---------+----------+----------+---------
    accessed | atime < | atime <= | atime >= | atime >
   ----------+---------+----------+----------+---------
    created  | ctime < | ctime <= | ctime >= | ctime >
   ----------+---------+----------+----------+---------

Each function takes one argument - the referring timestamp. Following
representations are supported (in order of check):

=over 4

=item File name

The corresponding C<mtime>, C<atime> or C<ctime> or the specified file is
used to do the appropriate equation, respectively.

If a relative path name is specified and the current working directory is
changed since rule instantiation, the result is undefined.

=item seconds since epoch

Each's file C<mtime>, C<atime> or C<ctime> is compared as requested to
given number.

=item DateTime object

Each's file C<mtime>, C<atime> or C<ctime> is compared as requested to
given DateTime.

=item DateTime::Duration object

Each's file C<mtime>, C<atime> or C<ctime> is compared as requested to
given C<< now - $duration >>. C<now> is determined at each check again,
for same reasons as in legacy API.

=back

=head3 Examples

    use File::Find::Rule;
    use File::Fine::Rule::Age;

    my $today = DateTime->now->truncate( to => "today" );
    my @today = find( owned => modified_since => $today, in => $ENV{PROJECT_ROOT} );

    my @updated = find( file => mofified_after => $self->get_cache_timestamp,
                        in => $self->inbox );

=head1 AUTHOR

Pedro Figueiredo, C<< <pedro period figueiredo at sns dot bskyb dotty com> >>

Jens Rehsack, C << rehsack at cpan dot org

=head1 BUGS

Please report any bugs or feature requests to
C<bug-find-find-rule-age at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Find-Find-Rule-Age>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Find::Find::Rule::Age

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Find-Find-Rule-Age>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Find-Find-Rule-Age>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Find-Find-Rule-Age>

=item * Search CPAN

L<http://search.cpan.org/dist/Find-Find-Rule-Age>

=back

=head1 ACKNOWLEDGEMENTS

Richard Clamp, the author of File::Find::Rule, for putting up with me.

=head1 COPYRIGHT

Copyright (C) 2008 Sky Network Services. All Rights Reserved.

Copyright (C) 2013-2014 Jens Rehsack. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Find::Rule>, L<DateTime>, L<File::stat>

=cut
