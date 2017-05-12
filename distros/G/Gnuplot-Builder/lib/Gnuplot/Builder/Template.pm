package Gnuplot::Builder::Template;
use strict;
use warnings;
use Exporter 5.57 qw(import);
use Carp;
use Gnuplot::Builder::JoinDict;

our @EXPORT_OK = qw(gusing gevery);

sub _create_hyphen_validator {
    my ($allowed_keys_arrayref) = @_;
    my %allowed_keys = map { $_ => 1 } @$allowed_keys_arrayref;
    return sub {
        my ($dict) = @_;
        foreach my $hyphen_key (grep { substr($_, 0, 1) eq "-" } $dict->get_all_keys) {
            croak "Unknown key: $hyphen_key" if !$allowed_keys{$hyphen_key};
        }
    };
}

our $USING;

{
    my @using_keys = grep { substr($_, 0, 1) eq "-" }
        qw(
    USE CASES       | KEYS
    ================+==============================================
                    | -x -y
    filledcurves    | -y1 -y2
                    | -z
    polar           | -t
    image           | -value
    smooth kdensity | -weight -bandwidth
    rgbalpha        | -r -g -b -a
    labels          | -string -label
    vectors         | -xdelta -ydelta -zdelta
    xerrorbars      | -xlow -xhigh
    yerrorbars      | -ylow -yhigh
    financebars     | -date -open -low -high -close
    candlesticks    | -box_min -whisker_min -whisker_high -box_high
    boxes           | -x_width
    boxplot         | -boxplot_factor
    circles         | -radius -start_angle -end_angle
    ellipses        | -major_diam -minor_diam -angle
    variable style  | -pointsize -arrowstyle -linecolor
      );
    
    $USING = Gnuplot::Builder::JoinDict->new(
        separator => ":",
        content => [map { $_ => undef } @using_keys],
        validator => _create_hyphen_validator(\@using_keys),
    );
}

our $EVERY;

{
    my @every_keys =
        qw(
    -point_incr
    -block_incr
    -start_point
    -start_block
    -end_point
    -end_block
      );
    $EVERY = Gnuplot::Builder::JoinDict->new(
        separator => ":",
        content => [$every_keys[0] => 1, map { $_ => undef } @every_keys[1 .. $#every_keys]],
        validator => _create_hyphen_validator(\@every_keys),
        filter => sub {
            my ($dict) = @_;
            my @values = $dict->get_all_values;
            my ($first_def_index, $last_def_index);
            foreach my $front_i (0 .. $#values) {
                my $rear_i = $#values - $front_i;
                if(!defined($first_def_index) && defined($values[$front_i])) {
                    $first_def_index = $front_i;
                }
                if(!defined($last_def_index) && defined($values[$rear_i])) {
                    $last_def_index = $rear_i;
                }
                if(defined($first_def_index) && defined($last_def_index)) {
                    last;
                }
            }
            return () if !defined($first_def_index) || !defined($last_def_index);
            return map {
                defined($_) ? $_ : ""
            } @values[$first_def_index .. $last_def_index];
        }
    );
}

sub gusing {
    return $USING->set(@_);
}

sub gevery {
    return $EVERY->set(@_);
}

1;
__END__

=pod

=head1 NAME

Gnuplot::Builder::Template - predefined Gnuplot::Builder objects as templates

=head1 SYNOPSIS

    use Gnuplot::Builder::Dataset;
    use Gnuplot::Builder::Template qw(gusing gevery);
        
    my $dataset = Gnuplot::Builder::Dataset->new_file("sample.dat");
    $dataset->set(
        using => gusing(
            -x => 1, -xlow => 2, -xhigh => 3,
            -y => 4, -ylow => 5, -yhigh => 6
        ),
        every => gevery(
            -start_point => 1, -end_point => 50
        ),
        with => "xyerrorbars",
    );
    "$dataset";  ## => 'sample.dat' using 1:4:2:3:5:6 every 1::1::50 with xyerrorbars
    
    $dataset->get_option("using")->get("-xlow");        ## => 2
    $dataset->get_option("every")->get("-start_point"); ## => 1

=head1 DESCRIPTION

B<< This module is in alpha state. API and object specification may be changed in the future. >>

L<Gnuplot::Builder::Template> provides template objects useful to build some gnuplot script elements.
These objects are structured, so you can modify their parameters partially.

=head1 EXPORTABLE FUNCTIONS

The following functions are exported only by request.

=head2 $using_joindict = gusing(@key_value_pairs)

Create and return a L<Gnuplot::Builder::JoinDict> object useful for "using" parameters.
Actually it's just a short for C<< $Gnuplot::Builder::Template::USING->set(@key_value_pairs) >>.

The L<Gnuplot::Builder::JoinDict> object returned by this function has predifined keys.
By default, values for the predefined keys are all C<undef>.

The predefined keys are listed in the right column of the following table.
Typical use cases for the keys are listed in the left column.

    USE CASES       | KEYS
    ================+==============================================
                    | -x -y
    filledcurves    | -y1 -y2
                    | -z
    polar           | -t
    image           | -value
    smooth kdensity | -weight -bandwidth
    rgbalpha        | -r -g -b -a
    labels          | -string -label
    vectors         | -xdelta -ydelta -zdelta
    xerrorbars      | -xlow -xhigh
    yerrorbars      | -ylow -yhigh
    financebars     | -date -open -low -high -close
    candlesticks    | -box_min -whisker_min -whisker_high -box_high
    boxes           | -x_width
    boxplot         | -boxplot_factor
    circles         | -radius -start_angle -end_angle
    ellipses        | -major_diam -minor_diam -angle
    variable style  | -pointsize -arrowstyle -linecolor

Note that these keys are in the same order as shown in the table,
so you would always get the "using" parameter in the correct order.

For example,

    my $using = gusing(-y => 5, -x => 3);
    "$using"  ## => 3:5

OK, that doesn't seem very useful, but how about this?

    my $using = gusing(-x => 1,
                       -whisker_min => 2, -box_min => 3,
                       -box_high => 4, -whisker_high => 5);
    "$using";  ## 1:3:2:5:4

Now you don't have to remember the complicated "using" spec of "candlesticks" style.
Just give the parameters with the keys,
and the L<Gnuplot::Builder::JoinDict> object arranges them in the correct order.

You can add your own key-value pairs to the parameters. For example,

    my $using = gusing(-x => 1, -y => 2, -x_width => "(0.7)", tics => "xticlabels(3)");
    "$using";  ## 1:2:(0.7):xticlabels(3)

Keys that start with C<"-"> are preserved.
If you add a key that starts with C<"-"> but is not listed in the above table,
this function dies.

C<gusing()> function uses C<$Gnuplot::Builder::Template::USING> package variable as the template.
You can customize it.

Some keys may be added to the template in the future. See L</COMPATIBILITY> for detail.

=head2 $every_joindict = gevery(@key_value_pairs)

Like C<gusing()>, it creates and returns a L<Gnuplot::Builder::JoinDict> object useful for "every" parameters.
Actually it's just a short for C<< $Gnuplot::Builder::Template::EVERY->set(@key_value_pairs) >>.

The L<Gnuplot::Builder::JoinDict> object returned by this function has the following predifined keys.

    -point_incr
    -block_incr
    -start_point
    -start_block
    -end_point
    -end_block

By default, C<-point_incr> is 1 and everything else is C<undef>.
This makes it possible to casually pass C<gevery()> for "every" parameter
and alter it afterward.

    my $dataset = Gnuplot::Builder::Dataset->new_file(
        "data", every => gevery
    );
    "$dataset";  ## => 'data' every 1
    $dataset->set(
        every => $dataset->get_option("every")->set(-start_point => 5)
    );
    "$dataset";  ## => 'data' every 1::5

Like C<gusing()>, keys that start with C<"-"> are preserved.
If you add a key that starts with C<"-"> but is not listed in the above list,
this function dies.

C<gevery()> function uses C<$Gnuplot::Builder::Template::EVERY> package variable as the template.
You can customize it.

Some keys may be added to the template in the future. See L</COMPATIBILITY> for detail.

=head1 PACKAGE VARIABLES

=head2 $USING

The template L<Gnuplot::Builder::JoinDict> object for C<gusing()> function.

=head2 $EVERY

The template L<Gnuplot::Builder::JoinDict> object for C<gevery()> function.

=head1 COMPATIBILITY

B<< This module is still in alpha, so any part of this module (including this section) may be changed in the future. For now you can think of this section as a draft of our compatibility policy. >>

This section describes what part of this module may be changed in the future releases and what part is NOT gonna be changed.

=head2 gusing() and gevery()

=over

=item *

No predefined key will be removed. (although some of them may get deprecated)

=item *

Predefined keys may be added/inserted at any part in the current list of predefined keys.

=item *

All predefined keys start with C<"-">.

=item *

The relative order of predefined keys will always be preserved.

=back

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
