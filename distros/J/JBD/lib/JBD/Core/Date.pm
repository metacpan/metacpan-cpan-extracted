package JBD::Core::Date;
# ABSTRACT: date functions
our $VERSION = '0.04'; # VERSION

#/ Date functions.
#/ @author Joel Dalley
#/ @version 2013/Oct/26

use JBD::Core::stern;
use Time::Local;

sub EPOCH {0}
sub LOCAL {1}


#////////////////////////////////////////////////////////////////
#/ Constructors /////////////////////////////////////////////////

#/ @param string $type    object type
#/ @param int [optional] $time    an epoch time, or undef
#/ @return JBD::Core::Date    blessed arrayref
sub new {
    my ($type, $time) = (shift, shift || time);
    bless [$time, [localtime $time]], $type;
}

#/ @param string $type    object type
#/ @param string $Ymd    a YYYY-mm-dd
#/ @return JBD::Core::Date    blessed arrayref
sub new_from_Ymd($) {
    my ($type, $Ymd) = @_;
    my ($Y, $m, $d) = split '-', $Ymd;
    $type->new(timelocal(0, 0, 0, $d, $m-1, $Y));
}


#////////////////////////////////////////////////////////////////
#/ Object Interface /////////////////////////////////////////////

#/ @param JBD::Core::Date $this
#/ @param string $format    date format, e.g., '%Y-%m-%d'
#/ @return string    formatted date
sub formatted {
    my $this = shift;
    my $format = shift or die 'Format required';
    my @specs = ($format =~ /(%[A-Za-z]{1})/go);

    #/ For each recognized format specifier, place 
    #/ its corresponding value into the array, @v.
    my @v; for (@specs) {
        SPEC: {
            #/ expand
            $_ eq '%F' && do {
                push @v, join '-', $this->Y, $this->m, $this->d; 
                last SPEC
            };
            $_ eq '%T' && do {
                push @v, join ':', $this->H, $this->M, $this->S; 
                last SPEC
            };
            $_ eq '%D' && do {
                push @v, join '/', $this->m, $this->d, $this->y;
                last SPEC
            };

            #/ simple
            $_ eq '%Y' && do { push @v, $this->Y; last SPEC };
            $_ eq '%y' && do { push @v, $this->y; last SPEC };
            $_ eq '%m' && do { push @v, $this->m; last SPEC };
            $_ eq '%d' && do { push @v, $this->d; last SPEC };
            $_ eq '%H' && do { push @v, $this->H; last SPEC };
            $_ eq '%M' && do { push @v, $this->M; last SPEC };
            $_ eq '%S' && do { push @v, $this->S; last SPEC };
            $_ eq '%a' && do { push @v, $this->weekday_abbr; last SPEC };
            $_ eq '%b' && do { push @v, $this->month_abbr; last SPEC };
            $_ eq '%o' && do { push @v, $this->ordinal_day; last SPEC };

            #/ what?
            die "Unrecognized format spec `$_`";
        }
    }

    #/ replace
    while (@specs) {
        my $spec = shift @specs;
        my $value = shift @v;
        $format =~ s/$spec/$value/;
    }

    $format;
}

#/ Simple value getters.
sub Y { shift->[LOCAL]->[5] + 1900 }
sub y { substr shift->Y, 2, 2 }
sub m { sprintf '%02d', shift->[LOCAL]->[4] + 1 }
sub d { sprintf '%02d', shift->[LOCAL]->[3] }
sub H { sprintf '%02d', shift->[LOCAL]->[2] }
sub M { sprintf '%02d', shift->[LOCAL]->[1] }
sub S { sprintf '%02d', shift->[LOCAL]->[0] }

#/ @param JBD::Core::Date
#/ @return string    one of Sun, Mon, Tue, ...
sub weekday_abbr { 
    (qw(Sun Mon Tue Wed Thu Fri Sat))[shift->[LOCAL]->[6]]
}

#/ @param JBD::Core::Date
#/ @return string    one of Jan, Feb, Mar, ...
sub month_abbr {
    (qw(0 Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[shift->m]
}

#/ @param JBD::Core::Date
#/ @return string    ordinal number, such as 1st, 23rd, ...
sub ordinal_day { 
    my $d = sprintf '%0d', shift->d;
    $d . (qw/th st nd rd/)[$d =~ /(?<!1)([123])$/o ? $1 : 0];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Core::Date - date functions

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
