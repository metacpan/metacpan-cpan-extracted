# $Id: DateTest.pm,v 1.8 2003/05/16 08:11:47 joezespak Exp $
package HTTP::WebTest::Plugin::DateTest;
use strict;
use Date::Parse;
use Date::Language::English;
use base qw(HTTP::WebTest::Plugin);

use vars qw($VERSION);
$VERSION = '1.01';

=head1 NAME

HTTP::WebTest::Plugin::DateTest - Evaluate the "age" of embedded date strings in response body

=head1 VERSION

 Version 1.01 - $Revision: 1.8 $

Compatible with L<HTTP::WebTest|HTTP::WebTest> 2.x API

=head1 SYNOPSIS

Not Applicable - see HTTP::WEBTEST


=head1 DESCRIPTION

This plugin provides a test for the age of a date string
inside the response body. It supports anything C<Date::Parse>
can parse.
There is limited support for other locales for which a
C<Date::Language::*> module exist.
The C<Date::Languge> and L<Date::Parse|Date::Parse> modules are
part of the C<TimeDate> distribution, available from a
CPAN near you.

=head1 TEST PARAMETERS


NOTE: The following parameters C<date_start>, C<date_end>
and C<date_maxage> are lists, so they should be specified
in order for multiple date tests.

=head2 date_start

Text string which marks the start of a date string
in the returned page.
The date string should look like anything that L<Date::Parse|Date::Parse> is
able to understand.
Leading/trailing whitespace is no problem

=head2 date_end

Text string which marks the end of a date string
in the returned page.
The date string should look like anything that L<Date::Parse|Date::Parse> is
able to understand.
Leading/trailing whitespace is no problem

=head2 date_maxage

Maximum age of the parsed date string in seconds.
This is evaluated against the current time at
runtime.

Format:
 N [units]

where C<N> is a (floating point-) number, followed by
one of these unit specifiers (case insensitive):

  s(econds) - default
  m(inutes)
  h(ours)
  d(ays)
  w(eeks)

The default is seconds.
Only the first character is relevant, any leading text is
ignored. An unknown unit specifier defaults to seconds.

=head2 date_locale

Global parameter for all date tests.

Specify the language in which the date string is written.
Locales are taken from C<Date::Language::(Locale)> modules (part
of L<Date::Parse|Date::Parse>). The value of C<date_locale> is normalized to
Capitalized notation, so this parameter is not case sensitive.

WARNING: this works by literally translating the date string
components to their English names. This fails if the notational
conventions are very different (order of day, month, year etc.)

There are languages where abbreviated day- and month names are
the same, notably I<Mar>di and I<Mar>s in French, and
I<Maa>ndag and I<Maa>rt in Dutch.

To work around the resulting ambiguity, all non-numerical components
are stripped from the left side of the date string. This works for
the common case where a weekday starts the string, but doesn't in
some other cases.

Example (this will work):

 date_locale = 'French'

 "Mar 19 Mars 2002, 17:25"
   => "19 Mars 2002, 17:25"
   => "19 Mar 2002, 17:25"

Example (this will fail for languages other than English):

 "Mar 19, 2002 17:25"
   => "19, 2002 17:25"
   => (not parsable)

Note: the last notation is very uncommon in Dutch,
so this assumption is generally no problem for this locale. YMMV!

=cut

sub param_types {
    return q(
             date_start    list
             date_end      list
             date_maxage   list
             date_locale   scalar
             );
}

sub check_response {
    my $self = shift;

    # response content
    my $content = $self->webtest->current_response->content;

    $self->validate_params(qw(date_start date_end date_maxage date_locale));

    # test results
    my @results = ();
    my @ret = ();

    # store current time
    my $now = time();

    # check for date strings
    my @tests = @{$self->test_param('date_start', [])};
    my $locale = $self->test_param('date_locale', '');
    for (my $i=0; $i < @tests; $i++) {
        my $maxage = ${$self->test_param('date_maxage', [])}[$i];
        my $start = $tests[$i];
        my $end = ${$self->test_param('date_end', [])}[$i];
        my $pgdate;
        my $datestr = 'unknown';
	if ($content =~ /\Q$start\E\s*(.+?)\s*\Q$end\E/) {
            $datestr = $1;
            $pgdate = &_str2time_locale($datestr, $locale);
        }
        my $age = ($pgdate) ? $now - $pgdate : 'unknown';
        my ($maxsecs, $units) = &_str2seconds($maxage);
        my $ok = ($age ne 'unknown') && ($age < $maxsecs);

	push @results,
          $self->test_result($ok,
            sprintf("Wanted max %s and got %s (%s)",
                    $maxage, &_seconds2str($age, $units), $datestr)
          );
    }

    push @ret, ['Max. age of date string', @results] if @results;
    return @ret;
}

sub TIMETAB {
  my $units = shift || '';
  my $tt = {
      s => 1,
      m => 60,
      h => 3600,
      d => 86400,
      w => 604800,
  };
  return $tt->{$units};
}

# look for trailing characters and interprete them as time unit
sub _str2seconds {
    my $date = shift;
    my $units = '';
    if ($date =~ /^\s*([\-+0-9.]+)\s*([smhdwSMHDW]).*/) {
       $units = lc($2);
       $date = $1 * &TIMETAB($units);
    } else { 
      $date =~ s/^\s*([\-+0-9.]+)\s*.*$/$1/g;
    }
    $date = 0 unless ($date =~ /^[\-+0-9.]/);
    return wantarray ? ($date, $units) : $date;
}

# convert seconds into time string
sub _seconds2str {
    my ($date, $units) = @_;
    return 'unknown' unless ($date =~ /^[+-]?[\d\.]+$/);
    if (&TIMETAB($units)) {
      return ($units eq 's') ? "$date s"
                             : sprintf("%4.2f %s", $date/&TIMETAB($units), $units);
    }
    my $str = '';
    my $frag = 0;
    if ($frag = int($date / &TIMETAB('w'))) {
      $str .= "${frag}w ";
      $date -= $frag * &TIMETAB('w');
    }
    if ($frag = int($date / &TIMETAB('d'))) {
      $str .= "${frag}d ";
      $date -= $frag * &TIMETAB('d');
    }
    $frag = int($date / &TIMETAB('h'));
    $str .= sprintf "%02d:", $frag;
    $date -= $frag * &TIMETAB('h');
    $frag = int($date / &TIMETAB('m'));
    $str .= sprintf "%02d:", $frag;
    $date -= $frag * &TIMETAB('m');
    $str .= sprintf "%02d", $date;
    return $str;
}

sub _str2time_locale {
  my $date = shift;
  my $locale = ucfirst(lc(shift)) || 'English';
  # return if date is, well, empty...
  return if ($date =~ /^\s*$/sg);
  return str2time $date if ($locale eq 'English');

  # normalize spaces, incl. multiple lines
  $date =~ s/\s+/ /sg;

  # NOTE: "mar" (Mardi) and "mars" (French) would break.
  # Assume we have a weekday name prefix if
  # date string does not start with digits.
  # Strip up to 1st digit:
  $date =~ s/^[^0-9]+//g;

  # strip leading/trailing spaces
  $date =~ s/^\s*(.+)\s*$/$1/g;

  eval "require Date::Language::$locale";
  warn $@ if $@;
  my @MoY = eval "\@Date::Language::${locale}::MoY";
  my $MoY_EN = \@Date::Language::English::MoY;

  my $nwdate = '';
  foreach my $token (split(/(\s|-|:|\/)/, $date)) {
    if ($token =~ /^[0-9,-:\/\s]+$/) {
      $nwdate .= $token;
    } else {
      # match token with full month name.
      for (my $i = 0; $i < @MoY; $i++) {
        if ($MoY[$i] =~ /^\Q$token\E.*/i) {
          $nwdate .= $MoY_EN->[$i];
        }
      }
    }
  }
  # explicitly return for empty or '0' date string
  return unless $nwdate;
  return str2time $nwdate;
}

=head1 COPYRIGHT

Copyright (c) 2002,2003 Johannes la Poutre. All rights reserved.

This module is free software. It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<Date::Parse|Date::Parse>

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
