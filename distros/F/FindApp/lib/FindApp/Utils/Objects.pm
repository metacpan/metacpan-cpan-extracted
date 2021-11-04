package FindApp::Utils::Objects;

use v5.10;
use strict;
use warnings;

use FindApp::Vars           qw( :all );
use FindApp::Utils::Foreign qw( 
    blessed 
    pp
    reftype 
    refaddr
);

#################################################################

sub as_number    ( $   ) ;
sub as_string    ( $   ) ;
sub class_prune  ( _   ) ;
sub myself               ;
sub op_equals    ( $$$ ) ;
sub op_notequals ( $$$ ) ;
sub pkg_abbr     ( $   ) ;

#################################################################

use Exporter     qw(import);
our $VERSION = v1.0;
our @EXPORT_OK = qw(
    as_number
    as_string
    class_prune
    myself
    op_equals
    op_notequals
    pkg_abbr

);
our %EXPORT_TAGS = (
    all      => \@EXPORT_OK,
    overload => [ grep /^(?:as|op)_/, @EXPORT_OK ],
);

#################################################################

# Have to do this the hard way instead of just calling 
# PACKAGE($1)->abbreviate because of load-order issues.
sub pkg_abbr($) {
    my $long_pack = shift;
    require FindApp::Utils::Package::Object;
    FindApp::Utils::Package::Object->new($long_pack)->abbreviate(1);
}

sub class_prune(_) {
    my($string) = @_;
    return $string unless $FINDAPP_DEBUG_SHORTEN;
    my @lines = split "\n", $string, -1;
    for (@lines) {
        s/\b(FindApp(?:::\w+)+)(?=::)/pkg_abbr($1)/ge;
        s/^                                           / /;
        s/^                                    / /;
        s/^             //;
        s/        (?==)// || s/      (?==)//;  # this may not be a good idea
    }
    $string = join "\n", @lines;
    return $string;
}

sub as_string($) {
    my $self = shift;
    my $pretty = pp($self) . ";\n";
    $pretty = class_prune($pretty);
    my $string = sprintf "%s=%s(%#x)", map { (ref, reftype, refaddr) } $self;
    $pretty =~ s/.*\K/ # $string/;
    return $pretty;
}

sub as_number($) {
    my($self) = @_;
    no overloading;
    return refaddr($self);
}

sub op_equals($$$) {
    my($this, $that, $swapped) = @_;
    no overloading;
    return $this == $that;
}

sub op_notequals($$$) { !&op_equals }


# So that if you call an instance method on a class, you 
# deliberately get the current singleton object instead.
sub myself {
    my $self = shift;
    return $self if blessed $self;
    return $self->old;
}

1;

=encoding utf8

=head1 NAME

FindApp::Utils::Objects - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::Objects;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item FIXME

=back

=head2 Exports

=over

=item as_number

=item as_string

=item class_prune

=item myself

Highly magical function that allows instance methods to act on a cached
class singleton when invoked as a class method not an instance

=item op_equals

=item op_notequals

=item pkg_abbr

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

