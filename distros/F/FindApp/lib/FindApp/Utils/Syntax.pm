package FindApp::Utils::Syntax;

use v5.10;
use strict;
use warnings;

use Sub::Name    qw(subname);

use FindApp::Utils::Assert   qw(:all);
use FindApp::Utils::Foreign  qw(reftype);

#################################################################

sub case             ( &  ) ;
sub case_fallthrough ( &  ) ;
sub function         ( $$ ) ;

#################################################################

use Exporter     qw(import);
our $VERSION = v1.0;
our @EXPORT_OK = qw(
    case
    case_fallthrough
    function
);
our %EXPORT_TAGS = ( 
    all => \@EXPORT_OK,
);

#################################################################

sub function($$) {
    my($name, $code) = @_;
    good_args(@_ == 2);
    reftype($code) eq "CODE"    || panic "wrong code type $code";

    for ($name) { 
        /^\w+(::\w+)*$/         || panic "bad function name $name";
        s/^/caller() . "::"/e 
            unless   /::/;
    }

    ##print "$name\n";

    no strict   "refs";
    no warnings "redefine";

    subname( $name => $code);
            *$name =  $code;
    return \&$name;
}

sub case(&) {
    &case_fallthrough;
    no warnings "exiting";
    next SWITCH;
}

sub case_fallthrough(&) {
    my($case) = @_;
    &$case;
}

1;

=encoding utf8

=head1 NAME

FindApp::Utils::Syntax - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::Syntax;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item FIXME

=back

=head2 Exports

=over

=item case

=item case_fallthrough

=item function

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

