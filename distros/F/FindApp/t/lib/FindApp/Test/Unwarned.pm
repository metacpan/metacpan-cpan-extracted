package FindApp::Test::Unwarned;

use v5.10;
use utf8;
use strict;
use warnings;

use Carp;

sub fatalize_warning {
    my($msg) = @_;
    confess "$0: Warnings are not allowed in tests, but found this one:\n\t$msg";
}

my $Was_Warned;

sub import {
    $SIG{__WARN__} = \&fatalize_warning;
    $Was_Warned = $^W;
    $^W = 1;
}

sub unimport {
    $SIG{__WARN__} = undef;
    $^W = $Was_Warned;
    $Was_Warned = 0;
}

1;

__END__

=head1 NAME

FindApp::Test::Unwarned - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

=head1 LICENCE AND COPYRIGHT
