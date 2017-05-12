package # hide from PAUSE
    Getopt::Trait::Handler;
use strict;
use warnings;

use Getopt::Long ();

sub get_options {
    my ($class) = @_;

    my $spec = {};
    my $meta = Scalar::Util::blessed( $class ) ? $class : MOP::Class->new( $class );

    foreach my $method ( $meta->all_methods ) {
        foreach my $trait ( grep $_->name eq 'Opt', Method::Traits->get_traits_for( $method ) ) {

            my ($opt_spec) = @{ $trait->args };
            # the opt_spec defaults to the method-name
            $opt_spec ||= $method->name;

            # split by | and assume last item will be slot name
            my $slot_name = (split /\|/ => $opt_spec)[-1];
            # strip off any getopt::long type info as well
            $slot_name =~ s/\=\w$//;

            my $slot = $meta->get_slot( $slot_name )
                    || $meta->get_slot_alias( $slot_name );

            die 'Cannot find slot ('.$slot_name.') for Opt('.$opt_spec.') on `' . $method->name . '`'
                unless $slot;

            $spec->{ $opt_spec } = $slot->name;
        }
    }

    my %opts = map { $_ => \(my $x) } keys %$spec;
    Getopt::Long::GetOptions( %opts );

    #use Data::Dumper;
    #warn Dumper $spec;
    #warn Dumper \%opts;

    return map {
        $spec->{ $_ },           # the spec key maps to the slot_name
        ${$opts{ $_ }}           # de-ref the scalar from Getopt::Long
    } grep defined ${$opts{$_}}, keys %opts;
}

1;
