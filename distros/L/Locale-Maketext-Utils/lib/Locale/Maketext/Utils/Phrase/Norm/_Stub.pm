package Locale::Maketext::Utils::Phrase::Norm::_Stub;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    # if (${$string_sr} =~ s/X/Y/g) {
    #      $filter->add_warning('X might be invalid might wanna check that');
    #         or
    #      $filter->add_violation('Text of violation here');
    # }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

=head2 Rationale

=head1 possible violations

=over 4

=item Text of violation here

Description here

=back 

=head1 possible warnings

None

I<Optional: For use when the entire filter only runs under extra filter mode:>

    =head1 Entire filter only runs under extra filter mode.
    
    See L<Locale::Maketext::Utils::Phrase::Norm/extra filters> for more details.

I<Optional: For use when one or more, but not all, checks in a filter only run under extra filter mode:>

    =head1 Checks only run under extra filter mode:
    
    =over 4
    
    =item violation/warning one text here
    
    =item violation/warning two text here
    
    =back
    
    See L<Locale::Maketext::Utils::Phrase::Norm/extra filters> for more details.
