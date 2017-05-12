package FormValidator::LazyWay::Utils;

use strict;
use warnings;
use Scalar::Util;
use Perl6::Junction qw/any/;

sub check_profile_syntax {
    my $profile = shift;

    ( ref $profile eq 'HASH' )
        or die "Invalid input profile: needs to be a hash reference\n";

    my @invalid;
    {
        my @valid_profile_keys = (
            qw/
                required
                optional
                defaults
                want_array
                stash
                lang
                level
                dependency_groups 
                dependencies
                use_fixed_method
                /
        );

        for my $key ( keys %$profile ) {
            next if $key =~ m/^use_/;
            push @invalid, $key unless ( $key eq any(@valid_profile_keys) );
        }

        local $" = ', ';
        if (@invalid) {
            die "Invalid input profile: keys not recognised [@invalid]\n";
        }
    }

    return 1;
}

sub remove_empty_fields {
    my $valid = shift;

    for my $field ( keys %{$valid} ) {
        if ( ref $valid->{$field} ) {
            next if ref $valid->{$field} ne 'ARRAY';
            for ( my $i = 0; $i < scalar @{ $valid->{$field} }; $i++ ) {
                $valid->{$field}->[$i] = undef
                    unless ( defined $valid->{$field}->[$i]
                    and length $valid->{$field}->[$i]
                    and $valid->{$field}->[$i] !~ /^\x00$/ );
            }

            my @tmp_valid = ();
            for my $item( @{ $valid->{$field} } ) {
                push @tmp_valid , $item if defined $item;
            }
            $valid->{$field} = \@tmp_valid;

            # If all fields are empty, we delete it.
            delete $valid->{$field}
                unless grep { defined $_ } @{ $valid->{$field} };
        }
        else {
            delete $valid->{$field}
                unless ( defined $valid->{$field}
                and length $valid->{$field}
                and $valid->{$field} !~ /^\x00$/ );
        }
    }

    $valid;
}

sub arrayify {

    # if the input is undefined, return an empty list
    my $val = shift;
    defined $val or return ();

# if it's a reference, return an array unless it points to an empty array. -mls
    if ( ref $val eq 'ARRAY' ) {
        $^W = 0;    # turn off warnings about undef
        return ( any(@$val) ne undef ) ? @$val : ();
    }

# if it's a string, return an array unless the string is missing or empty. -mls
    else {
        return ( length $val ) ? ($val) : ();
    }
}

# Figure out whether the data is a hash reference of a param-capable object and return it has a hash
sub get_input_as_hash {
    my $data = shift;
    require Scalar::Util;

    # This checks whether we have an object that supports param
    if ( Scalar::Util::blessed($data) && $data->can('param') ) {
        my %return;
        for my $k ( $data->param() ) {

            # we expect param to return an array if there are multiple values
            my @v;

          # CGI::Simple requires us to call 'upload()' to get upload data,
          # while CGI/Apache::Request return it on calling 'param()'.
          #
          # This seems quirky, but there isn't a way for us to easily check if
          # "this field contains a file upload" or not.
            if ( $data->isa('CGI::Simple') ) {
                @v = $data->upload($k) || $data->param($k);
            }
            else {
                @v = $data->param($k);
            }

            # we expect param to return an array if there are multiple values
            $return{$k} = scalar(@v) > 1 ? \@v : $v[0];
        }
        return \%return;
    }

    # otherwise, it's already a hash reference
    elsif ( ref $data eq 'HASH' ) {

        # be careful to actually copy array references
        my %copy = %$data;
        for ( grep { ref $data->{$_} eq 'ARRAY' } keys %$data ) {
            my @array_copy = @{ $data->{$_} };
            $copy{$_} = \@array_copy;
        }

        return \%copy;
    }
    else {
        die
            "FormValidator::LazyWay->validate() or check() called with invalid input data structure.";
    }
}
1;

=head1 NAME

FormValidator::LazyWay::Util - FormValidator::LazyWay Util functions

=head1 AUTHOR

Tomohiro Teranishi<tomohiro.teranishi@gmail.com>

=cut
