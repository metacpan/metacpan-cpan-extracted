package Java::JCR::JavaUtils;

use strict;
use warnings;

our $VERSION = '0.07';

=head1 NAME

Java::JCR::JavaUtils - Helper utiltiies for going from Perl-to-Java

=head1 DESCRIPTION

This contains some internal utitlies used for dealing with special cases in the Perl-to-Java mapping.

=cut

use Inline (
    Java => <<'END_OF_JAVA',
import java.io.InputStream;
import java.io.IOException;
    
import org.perl.inline.java.InlineJavaPerlCaller;
import org.perl.inline.java.InlineJavaException;
import org.perl.inline.java.InlineJavaPerlException;

class GlobCaller extends InlineJavaPerlCaller {
    private String glob;

    public GlobCaller(String glob) throws InlineJavaException {
        this.glob = glob;
    }

    public int read() throws InlineJavaException, InlineJavaPerlException {
        String ch = (String) CallPerlSub(
                "Java::JCR::JavaUtils::read_one_byte", new Object[] {
                    this.glob
                });
        return ch != null ? ch.charAt(0) : -1;
    }
}

class GlobInputStream extends InputStream {
    private GlobCaller glob;

    public GlobInputStream(GlobCaller glob) {
        this.glob = glob;
    }

    public int read() throws IOException {
        try {
            return this.glob.read();
        }

        catch (InlineJavaException e) {
            throw new IOException("Error reading Perl file handle: " + 
                    e.getMessage());
        }

        catch (InlineJavaPerlException e) {
            throw new IOException("Error reading Perl file handle: " +
                    e.getMessage());
        }
    }
}

END_OF_JAVA
    STUDY => [ qw(
        java.io.InputStream
        java.util.Calendar 
        java.util.TimeZone
        java.util.Locale
    ) ],
    PACKAGE => 'Java::JCR',
);
use Inline::Java qw( cast );

sub read_one_byte {
    my $glob = shift;
    my $c = getc $glob;
    return $c;
}

sub input_stream {
    my $glob = shift;
    my $glob_val = $$glob;
    $glob_val =~ s/^\*//;
    my $glob_caller = Java::JCR::GlobCaller->new($glob_val);
    return Java::JCR::GlobInputStream->new($glob_caller);
}

sub calendar_to_hash {
    my ($calendar) = @_;

    $calendar    = cast('java.util.Calendar', $calendar);
    my $timezone = cast('java.util.TimeZone', $calendar->getTimeZone());

    my $tz_offset = $timezone;

    return {
        year       => $calendar->get($Java::JCR::java::util::Calendar::YEAR),
        month      => $calendar->get($Java::JCR::java::util::Calendar::MONTH),
        day        => $calendar->get(
                          $Java::JCR::java::util::Calendar::DAY_OF_MONTH),
        hour       => $calendar->get(
                          $Java::JCR::java::util::Calendar::HOUR_OF_DAY),
        minute     => $calendar->get($Java::JCR::java::util::Calendar::MINUTE),
        second     => $calendar->get($Java::JCR::java::util::Calendar::SECOND),
        nanosecond => $calendar->get(
                          $Java::JCR::java::util::Calendar::MILLISECOND) 
                          * 1_000_000,
        timezone   => $timezone->getID(),
        lenient    => 0,
    };
}

sub hash_to_calendar {
    my ($hash) = @_;

    my $calendar;
    if (defined $hash->{timezone} && defined $hash->{locale}) {
        my ($language, $country, $variant) = split /_/, $hash->{locale};
        $calendar = Java::JCR::java::util::Calendar->getInstance(
            Java::JCR::java::util::TimeZone->getTimeZone($hash->{timezone}),
            Java::JCR::java::util::Locale->new($language, $country, $variant),
        );
    }

    elsif (defined $hash->{timezone}) {
        $calendar = Java::JCR::java::util::Calendar->getInstance(
            Java::JCR::java::util::TimeZone->getTimeZone($hash->{timezone}),
        );
    }

    elsif (defined $hash->{locale}) {
        my ($language, $country, $variant) = split /_/, $hash->{locale};
        $calendar = Java::JCR::java::util::Calendar->getInstance(
            Java::JCR::java::util::Locale->new($language, $country, $variant),
        );
    }

    else {
        $calendar = Java::JCR::java::util::Calendar->getInstance();
    }

    $calendar = cast('java.util.Calendar', $calendar);

    $calendar->setLenient($hash->{lenient}) if defined $hash->{lenient};

    $calendar->set($Java::JCR::java::util::Calendar::YEAR, $hash->{year});
    $calendar->set($Java::JCR::java::util::Calendar::MONTH, $hash->{month});
    $calendar->set($Java::JCR::java::util::Calendar::DAY_OF_MONTH, 
        $hash->{day});
    $calendar->set($Java::JCR::java::util::Calendar::HOUR_OF_DAY, 
        $hash->{hour});
    $calendar->set($Java::JCR::java::util::Calendar::MINUTE, $hash->{minute});
    $calendar->set($Java::JCR::java::util::Calendar::SECOND, $hash->{second});

    return $calendar;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
