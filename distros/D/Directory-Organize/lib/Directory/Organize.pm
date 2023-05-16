# vim: set ts=4 sw=4 tw=78 et si:

package Directory::Organize;

use strict;
use warnings;
use version; our $VERSION = qv('v1.0.2');

sub new {
    my $self = shift;
    my $type = ref($self) || $self;

    $self = bless {}, $type;
    $self->{basedir} = shift;
    $self->set_today();

    return $self;
} # new();

sub get_descriptions {
    my $self = shift;

    if (!exists $self->{descriptions}) {
        $self->_read_descriptions();
    }
    return wantarray ? @{$self->{descriptions}} : $self->{descriptions};
} # get_descriptions()

sub new_dir {
    my ($self,$descr) = @_;
    my $daydir = sprintf "%4.4d/%2.2d/%2.2d", $self->{tyear}, $self->{tmonth}
                                            , $self->{tday};
    my $dirprefix = qq($self->{basedir}/$daydir);
    my $suffix = q();
    if (-d $dirprefix) {
        $suffix = 'a';
        while (-d qq($dirprefix$suffix)) {
            $suffix++;
        }
    }
    my $path = qq($dirprefix$suffix/);
    my $dir = q();
    while ($path =~ s{^([^/]*)/}{}) {
        if ($1) {
            $dir .= $1;
            (-d $dir) || mkdir($dir,0777) || return undef;
            $dir .= '/';
        }
        else {
            $dir = '/' unless ($dir);
        }
    }
    my $project = qq($dirprefix$suffix/.project);
    if ($descr and open (my $PROJ,'>',$project)) {
        print $PROJ qq($descr\n);
        close $PROJ;
    }
    return qq($dirprefix$suffix);
} # new_dir()

sub set_pattern {
    my ($self,$pattern) = @_;

    # do nothing with unchanged pattern
    if ($pattern
        && defined $self->{pattern}
        && $self->{pattern} eq $pattern) {
        return;
    }
    if (!$pattern and !defined $self->{pattern}) {
        return;
    }
    delete $self->{descriptions};
    if (!$pattern) {
        delete $self->{pattern};
    }
    else {
        $self->{pattern} = $pattern;
    }
} # set_pattern()

sub set_time_constraint {
    my ($self,$op,$year,$month,$day) = @_;
    if (defined $year and $op =~ /^[=<>]$/) {
        $self->{tc}->{op}    = $op;
        $self->{tc}->{year}  = sprintf "%04d",$year;
        $self->{tc}->{month} = sprintf "%02d",$month    if (defined $month);
        $self->{tc}->{day}   = sprintf "%02d",$day      if (defined $day);
        delete $self->{descriptions};
    }
    else {
        if ($self->{tc}) {
            delete $self->{descriptions};
            delete $self->{tc};
        }
    }
} # set_time_constraint()

sub set_today {
    my $self = shift;
    my ($tday,$tmonth,$tyear) = @_;
    if (defined $tyear) {
        $self->{tday}   = $tday;
        $self->{tmonth} = $tmonth;
        $self->{tyear}  = $tyear;
        return;
    }
    my ($day,$month,$year) = (localtime)[3,4,5];
    $year  += 1900;
    $month += 1;
    if (defined $tmonth) {
        $self->{tday}   = $tday;
        $self->{tmonth} = $tmonth;
        $self->{tyear}  = $year;
    }
    elsif (defined $tday) {
        $self->{tday}   = $tday;
        $self->{tmonth} = $month;
        $self->{tyear}  = $year;
    }
    else {
        $self->{tday}   = $day;
        $self->{tmonth} = $month;
        $self->{tyear}  = $year;
    }
    return;
} # set_today()

sub _not_in_tc {
    my ($self,$year,$month,$day) = @_;
    my ($tc,$tc_date,$date,$result);

    $tc = $self->{tc};

    if (defined $day) {
        if (defined $tc->{day}) {
            $tc_date = $tc->{year} . $tc->{month} . $tc->{day};
            $date    = $year . $month . substr($day,0,2);
        }
        elsif (defined $tc->{month}) {
            $tc_date = $tc->{year} . $tc->{month};
            $date    = $year . $month;
        }
        else {
            $tc_date = $tc->{year};
            $date    = $year;
        }
    }
    elsif (defined $month) {
        if (defined $tc->{day}) {
            $tc_date = $tc->{year} . $tc->{month};
            $date    = $year . $month;
            $date++ if ('>' eq $tc->{op});
            $date-- if ('<' eq $tc->{op});
        }
        elsif (defined $tc->{month}) {
            $tc_date = $tc->{year} . $tc->{month};
            $date    = $year . $month;
        }
        else {
            $tc_date = $tc->{year};
            $date    = $year;
        }
    }
    else {
        if (defined $tc->{month}) {
            $tc_date = $tc->{year};
            $date    = $year;
            $date++ if ('>' eq $tc->{op});
            $date-- if ('<' eq $tc->{op});
        }
        else {
            $tc_date = $tc->{year};
            $date    = $year;
        }
    }
    $result = '<' eq $tc->{op} ? $date ge $tc_date
            : '>' eq $tc->{op} ? $date le $tc_date
            :                    $date ne $tc_date
            ;
    return $result;
} # _not_in_tc()

sub _read_descriptions {
    my $self = shift;
    my $base = $self->{basedir};
    $self->{descriptions} = [];

    if (opendir my $BASEDIR, $base) {

        my %dirs = map  { ("$_" => {}) }
                   grep { m/^       # match names with
                            \d{4}   # four digits
                            $       # exactly
                           /x }
                   readdir( $BASEDIR );
        closedir $BASEDIR;

        YEAR:
        for my $year (reverse sort keys %dirs) {
            next if ($self->{tc} && $self->_not_in_tc($year));
            if (opendir my $YEARDIR, qq($base/$year)) {
                my %mdirs = map  { ("$_" => {}) }
                            grep { m/^      # match names with
                                     \d{2}  # two digits
                                     $      # exactly
                                    /x }
                            readdir( $YEARDIR );
                $dirs{$year} = \%mdirs;
                closedir $YEARDIR;
            }

            MONTH:
            for my $month (reverse sort keys %{$dirs{$year}}) {
                next if ($self->{tc} && $self->_not_in_tc($year,$month));
                if (opendir my $MONTHDIR, qq($base/$year/$month)) {
                    my %ddirs = map  { ("$_" => {}) }
                                grep { m/^      # match names that start
                                         \d{2}  # with two digits
                                        /x
                                     && -d qq($base/$year/$month/$_) }
                                readdir($MONTHDIR);
                    $dirs{$year}->{$month} = \%ddirs;
                    close $MONTHDIR;
                }

                DAY:
                for my $day (reverse sort keys %{$dirs{$year}->{$month}}) {
                    next if ($self->{tc}
                            && $self->_not_in_tc($year,$month,$day));
                    my $path = qq($year/$month/$day);
                    my $desc = "";
                    if (-f qq($base/$path/.project)
                        and open my $PROJECT, '<', qq($base/$path/.project)) {
                        $desc = <$PROJECT>;
                        close $PROJECT;
                        chomp $desc;
                    }
                    if ($self->{pattern} && $desc !~ /$self->{pattern}/i) {
                        next;
                    } 
                    push @{$self->{descriptions}}, [ $path, $desc ];
                }
            }
        }
    }
    return;
} # _read_descriptions();

1;

__END__

=head1 NAME

Directory::Organize - create and find directories organized by date

=head1 VERSION

This documentation refers to Directory::Organize version v1.0.2.

=head1 SYNOPSIS

  use Directory::Organize;

  $do = new Directory::Organize($basedir);

  @directories = $do->get_descriptions(\%constraints);

  $path = $do->new_dir($description);

  $do->set_pattern($pattern);

  $do->set_time_constraint('<',$year,$month,$day);

  $do->set_today($day,$month,$year);

=head1 METHODS

=head2 new()

  use Directory::Organize;

  $do = new Directory::Organize($basedir);

=head2 get_descriptions()

This functions returns an array of arrays of the form

  ([ path1, description1 ],
   ...
   [ pathn, descriptionn ],
  )

It searches all subdirectories three levels below C<$basedir> for a file
named I<.project>. The returned array contains the relative path from the
base directory and the first line of the I<.project> file as
description. This array is sorted descending by I<path>.

  @directories = $do->get_descriptions();

=head2 new_dir()

This function creates a new directory according to the current date or the
date given with C<set_doday()> and creates a file named I<.project> in the
newly created directory containing the given description.

If there already exists a directory for the given date, it will add a suffix
to the day. Therefore if you call this functions three times with the date
2009-05-25, the first directory created will be 2009/05/25, the second will be
2009/05/25a and the third 2009/05/25b.

The function returns the path of the created directory.

  $path = $do->new_dir($description);

=head2 set_pattern()

This function sets a pattern to constrain the list of subdirectories returned
by the next call of get_descriptions().

  $do->set_pattern($pattern);

=head2 set_time_constraint()

This function sets a constraint for the time of creation of the project
directories returned with get_descriptions();

  $do->set_time_constraint($op,$year,$month,$day);
  $do->set_time_constraint($op,$year,$month);
  $do->set_time_constraint($op,$year);

The argument C<$op> specifies the operator and may be one of '=', '<' or '>'
depending on whether the time constraint should be in, before or after the
given time. C<$year> denotes the year, C<$month> the month (1..12) and C<$day>
the day (1..31) that the operator should be applied to. If C<$day> or
C<$month> are omitted, the operator applies to the whole month or year.

=head2 set_today()

Specifies the date to be used the next time when creating a new directory with
new_dir(). Arguments may be

=over 4

=item I<none>

to set the current date

  $do->set_today();

=item a I<day>

to set another day in this month and year.

  $do->set_today($day);

=item a I<day> and a I<month>

to set another day and month in this year.

  $do->set_today($day,$month);

=item a I<day>, a I<month> and a I<year>

to set an arbitrary date.

  $do->set_today($day,$month,$year);

=back

=head1 AUTHOR

Mathias Weidner

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009-2018 Mathias Weidner (mamawe@cpan.org).
All rights reserved.

This module is free software; you can redistribute and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
