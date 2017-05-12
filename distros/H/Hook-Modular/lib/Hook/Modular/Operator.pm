use 5.008;
use strict;
use warnings;

package Hook::Modular::Operator;
BEGIN {
  $Hook::Modular::Operator::VERSION = '1.101050';
}
# ABSTRACT: Boolean operators for plugins
use List::Util qw(reduce);
our %Ops     = (
    AND => [ sub { $_[0] && $_[1] } ],
    OR => [ sub { $_[0] || $_[1] } ],
    XOR  => [ sub { $_[0] xor $_[1] } ],
    NAND => [ sub { $_[0] && $_[1] }, 1 ],
    NOT  => [ sub { $_[0] && $_[1] }, 1 ],    # alias of NAND
    NOR  => [ sub { $_[0] || $_[1] }, 1 ],
);

sub is_valid_op {
    shift;   # we don't need the class
    my $op = shift;
    exists $Ops{$op};
}

sub call {
    shift;   # we don't need the class
    my ($op, @bool) = @_;
    my $bool = reduce { $Ops{$op}->[0]->($a, $b) } @bool;
    $bool = !$bool if $Ops{$op}->[1];
    $bool;
}
1;


__END__
=pod

=head1 NAME

Hook::Modular::Operator - Boolean operators for plugins

=head1 VERSION

version 1.101050

=head1 METHODS

=head2 call

FIXME

=head2 is_valid_op

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Hook-Modular>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Hook-Modular/>.

The development version lives at
L<http://github.com/hanekomu/Hook-Modular/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

  Marcel Gruenauer <marcel@cpan.org>
  Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

