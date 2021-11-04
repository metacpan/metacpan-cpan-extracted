package FindApp::Utils::Misc;

use v5.10;
use strict;
use warnings;

use FindApp::Utils::Assert   ":all";
use FindApp::Utils::Foreign  ":Scalar::Util";

#################################################################

sub is_csh  (   ) ;
sub n_times ( _ ) ;

#################################################################

use Exporter     qw(import);
our $VERSION   = v1.0;
our @EXPORT_OK = qw(
    is_csh    
    n_times
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#################################################################

sub is_csh() {
    state $is_csh = do {
        my  $parent  =  getppid();
       `ps c$parent` =~ /t?[c-]sh\b/;
    };
    return $is_csh;
}

sub n_times(_) { 
    good_args(@_ == 1); 
    my($n) = @_; 
    looks_like_number($n)               || croak("n_times argument should be a number, not $n");
    return    "never"   unless $n; 
    return    "once"    if $n == 1;
    return    "twice"   if $n == 2;
    return    "thrice"  if $n == 3;
    return "$n times";
}

1;

=encoding utf8

=head1 NAME

FindApp::Utils::Misc - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::Misc;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item FIXME

=back

=head2 Exports

=over

=item FIXME

=item is_csh

=item n_times

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

