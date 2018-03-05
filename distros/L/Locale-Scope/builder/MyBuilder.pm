package builder::MyBuilder;
use strict;
use warnings;
use parent qw/Module::Build/;

sub new {
    my ($self, %args) = @_;

    # SEE ALSO: https://metacpan.org/pod/release/RENEEB/perl-5.27.9/pod/perldelta.pod#New-read-only-predefined-variable-${^SAFE_LOCALES}
    if ($] ge '5.027009' && !${^SAFE_LOCALES}) {
        die "This module is unsafe if the perl dosen't support safe locales.\n";
    }

    return $self->SUPER::new(%args);
}

1;

