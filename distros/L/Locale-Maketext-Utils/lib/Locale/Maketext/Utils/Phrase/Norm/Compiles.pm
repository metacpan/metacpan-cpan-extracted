package Locale::Maketext::Utils::Phrase::Norm::Compiles;

use strict;
use warnings;
use Locale::Maketext::Utils         ();
use Locale::Maketext::Utils::Phrase ();

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string    = $filter->get_orig_str();
    my $mt_obj    = $filter->get_maketext_object();
    my $bn_regexp = Locale::Maketext::Utils::Phrase::get_bn_var_regexp();

    local $SIG{'__DIE__'};    # cpanel specific: ensure a benign eval does not trigger cpsrvd's DIE handler (may be made moot by internal case 50857)
    eval {

        # TODO: when we have a phrase class we can pass in proper args to each BN method, for now pass in a bunch of numbers tpo avoid warnings
        my $n = 0;
        my @args = map { $n++ } ( $string =~ m/($bn_regexp)/g );

        $mt_obj->makethis( $string, @args );
    };

    if ($@) {
        my $error = $@;

        $error =~ s/([\[\]])/~$1/g;
        $error =~ s/[\n\r]+/ /g;

        $string =~ s/([\[\]])/~$1/g;
        $error =~ s/\Q$string\E.*$/$string/;
        my $string_sr = $filter->get_string_sr();
        if ( $error =~ m/Can't locate object method "(.*)" via package "(.*)"/i ) {
            $error = "“$2” does not have a method “$1” in: $string";
        }
        elsif ( $error =~ m/Undefined subroutine (\S+)/i ) {    # odd but theoretically possible
            my $full_func = $1;
            my ( $f, @c ) = reverse( split( /::/, $full_func ) );
            my $c = join( '::', reverse(@c) );
            $error = "“$2” does not have a function “$1” in: $string";
        }

        ${$string_sr} = "[comment,Bracket Notation Error: $error]";

        $filter->add_violation('Bracket Notation Error');
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

Check that the string compiles.

=head2 Rationale

If the source phrase is broken, we have to die at run time. If the target phrase is broken, we do not get the translation.

Conceivably there could also be more subtle problems it could cause.

=head1 possible violations

=over 4

=item Bracket Notation Error

There was a problem compiling the string.

The string is replaced with a comment that details the problem, typically including an escaped verison of the problematic string: [comment,Bracket Notation Error: DETAILS_GO_HERE]

=back

=head1 possible warnings

None
