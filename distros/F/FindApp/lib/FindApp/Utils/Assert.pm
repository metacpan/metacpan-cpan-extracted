package FindApp::Utils::Assert;

use v5.10;
use strict;
use warnings;

use FindApp::Utils::Carp;

#################################################################

sub all_args_defined ;
sub bad_args         ;
sub good_args        ;
sub panic            ;
sub subcroak         ;
sub subcroak_N       ;
sub validate_args    ;

#################################################################

use Exporter     qw(import);
our $VERSION = v1.0;
our @EXPORT_OK = qw(
    all_args_defined
    bad_args
    good_args
    panic
    subcroak
    subcroak_N
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#################################################################

sub subcroak {
    my($package, $filename, $line, $sub) = caller(1);
    my $subname = $sub;
    my $proto = prototype($sub);
    $subname .= "($proto)" if defined $proto;

    croak "$subname: @_";
}

sub subcroak_N {
    my $frames = shift;
    my($package, $filename, $line, $sub) = caller($frames);
    croak "$sub(): @_";
}


sub panic {
    confess "panic: @_";
}

sub validate_args {
    my($good_condition) = @_;
    return if $good_condition;
    my($package, $file, $line, $sub) = caller(2);
    panic "invalid arguments given to $sub" unless $good_condition;
}

sub bad_args {
    my($condition) = @_;
    validate_args !$condition;
}

sub good_args {
    &validate_args;
}

sub all_args_defined {
    unless (@_ == grep {defined} @_) {
        subcroak_N(2, "undefined arguments forbidden");
    }
}


1;

=encoding utf8

=head1 NAME

FindApp::Utils::Assert - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::Assert;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item FIXME

=back

=head2 Exports

=over

=item all_args_defined

=item bad_args

=item good_args

=item panic

=item subcroak

=item subcroak_N

=item validate_args

=item FIXME

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

