package Math::Util::CalculatedValue::Validatable;

use Moose;

use MooseX::NonMoose;
extends 'Math::Util::CalculatedValue';
with 'MooseX::Role::Validatable';

=head1 NAME

Math::Util::CalculatedValue::Validatable - math adjustment, which can containe another adjustments with validation

=head1 DESCRIPTION

Represents an adjustment to a value (which can contain additional adjustments) with validation.

=cut

our $VERSION = '0.07';    ## VERSION

=head1 SYNOPSIS

    my $tid = Math::Util::CalculatedValue::Validatable->new({
        name        => 'time_in_days',
        description => 'Duration in days',
        set_by      => 'Contract',
        base_amount => 0,
    });

    my $tiy = Math::Util::CalculatedValue::Validatable->new({
        name        => 'time_in_years',
        description => 'Duration in years',
        set_by      => 'Contract',
        base_amount => 1,
    });

    my $dpy = Math::Util::CalculatedValue::Validatable->new({
        name        => 'days_per_year',
        description => 'days in a year',
        set_by      => 'Contract',
        base_amount => 365,
    });

    $tid->include_adjustment('reset', $tiy);
    $tid->include_adjustment('multiply', $dpy);

    print $tid->amount;


=head2 BUILD

Bulder args to add validation method

=cut

sub BUILD {
    my $self = shift;
    $self->{validation_methods} = [qw(_validate_all_sub_adjustments)];
    return;
}

sub _validate_all_sub_adjustments {
    my $self = shift;

    my @errors;
    foreach my $cv (map { $_->[1] } @{$self->adjustments}) {
        push @errors, $cv->all_errors unless ($cv->confirm_validity);
    }

    return @errors;
}

=head1 AUTHOR

binary.com, C<< <rakesh at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-util-calculatedvalue at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Util-CalculatedValue>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Util::CalculatedValue


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Util-CalculatedValue>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Util-CalculatedValue>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Util-CalculatedValue>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Util-CalculatedValue/>

=back


=head1 ACKNOWLEDGEMENTS

=cut

no Moose;

__PACKAGE__->meta->make_immutable;

1;    # End of Math::Util::CalculatedValue::Validatable
