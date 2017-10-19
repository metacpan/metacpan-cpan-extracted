package DateTimeX::Tiny::Compact;

our $DATE = '2017-10-19'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use overload 'bool' => sub () { 1 };
use overload '""'   => 'as_string';
use overload 'eq'   => sub { "$_[0]" eq "$_[1]" };
use overload 'ne'   => sub { "$_[0]" ne "$_[1]" };

use Class::Accessor::PackedString::Set +{
    constructor => '_new',
    accessors  => [
        year   => "s",
        month  => "c",
        day    => "c",
        hour   => "c",
        minute => "c",
        second => "f",
    ],
};

sub new {
    my $class = shift;
    my $self = $class->_new;
    while (my ($k, $v) = splice(@_, 0, 2)) {
        $self->$k($v);
    }
    $self;
}

sub now {
    my @t = localtime time;
    shift->new(
        year   => $t[5] + 1900,
        month  => $t[4] + 1,
        day    => $t[3],
        hour   => $t[2],
        minute => $t[1],
        second => $t[0],
    );
}

sub ymdhms {
    sprintf(
        "%04u-%02u-%02uT%02u:%02u:%02u",
        $_[0]->year,
        $_[0]->month,
        $_[0]->day,
        $_[0]->hour,
        $_[0]->minute,
        $_[0]->second,
    );
}

sub from_string {
    my $string = $_[1];
    unless ( defined $string and ! ref $string ) {
        require Carp;
        Carp::croak("Did not provide a string to from_string");
    }
    unless ( $string =~ /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)$/ ) {
        require Carp;
        Carp::croak("Invalid time format (does not match ISO 8601)");
    }
    $_[0]->new(
        year   => $1 + 0,
        month  => $2 + 0,
        day    => $3 + 0,
        hour   => $4 + 0,
        minute => $5 + 0,
        second => $6 + 0,
    );
}

sub as_string {
    $_[0]->ymdhms;
}

sub DateTime {
    require DateTime;
    my $self = shift;
    DateTime->new(
        day       => $self->day,
        month     => $self->month,
        year      => $self->year,
        hour      => $self->hour,
        minute    => $self->minute,
        second    => $self->second,
        locale    => 'C',
        time_zone => 'floating',
        @_,
    );
}

1;
# ABSTRACT: DateTime::Tiny but uses less space

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTimeX::Tiny::Compact - DateTime::Tiny but uses less space

=head1 VERSION

This document describes version 0.002 of DateTimeX::Tiny::Compact (from Perl distribution DateTimeX-Tiny-Compact), released on 2017-10-19.

=head1 SYNOPSIS

  # Create a date manually
  $christmas = DateTimeX::Tiny::Compact->new(
      year   => 2006,
      month  => 12,
      day    => 25,
      hour   => 10,
      minute => 45,
      second => 0,
      );

  # Show the current date
  my $now = DateTimeX::Tiny::Compact->now;
  print "Year   : " . $now->year   . "\n";
  print "Month  : " . $now->month  . "\n";
  print "Day    : " . $now->day    . "\n";
  print "Hour   : " . $now->hour   . "\n";
  print "Minute : " . $now->minute . "\n";
  print "Second : " . $now->second . "\n";

=head1 DESCRIPTION

B<EXPERIMENTAL.>

B<DateTimeX::Tiny::Compact> is a fork of L<DateTime::Tiny>. It uses
L<Class::Accessor::PackedString::Set> to create objects based on C<pack()>-ed
string which is compact.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DateTimeX-Tiny-Compact>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DateTimeX-Tiny-Compact>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTimeX-Tiny-Compact>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DateTime::Tiny>

L<Class::Accessor::PackedString::Set>

L<DateTimeX::Duration::Lite>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
