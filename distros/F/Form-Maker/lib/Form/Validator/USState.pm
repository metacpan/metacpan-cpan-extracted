package Form::Validator::USState;
use base 'Form::Validator';
my $us_state = qr/(?:A[LKSZREAEEEP]|
   C[AOT]|D[EC]|F[ML]|G[AU]|HI|I[DLNA]|K[SY]|LA|M[EHDAINSOTP]|N[EVHJMYCD]|
      O[HKR]|P[WAR]|RI|S[CD]|T[NX]|UT|V[TIA]|W[AVIY])/;

sub validate {
    my ($self, $field) = @_;
    {
        javascript => '^[A-Z][A-Z]$',
        perl => qr/^$us_state$/,
    }
}

=head1 NAME

Form::Validator::USState - Canned validator for US State abbreviations

=head1 SYNOPSIS

    $form->add_validation(username => 'Form::Validator::USState');

=head1 DESCRIPTION

Checks for a field containing precisely two letters, and further checks
(in Perl-space) that these two letters are a valid abbreviation for a US
state.

=cut

1;
