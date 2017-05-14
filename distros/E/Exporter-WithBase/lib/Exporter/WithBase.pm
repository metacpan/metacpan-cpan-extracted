use strict qw<vars subs>; # no refs
use warnings;

package Exporter::WithBase;
# ABSTRACT: Like Exporter, but add a '-base' flag to declare a class as a child
$Exporter::WithBase::VERSION = '1.00';
use Exporter 5.57 ();

sub import
{
    my $caller = caller;
    # If -base, inherit from Exporter
    if (@_ >= 2 && $_[1] eq '-base') {
	splice @_, 1, 1;
	push @{"${caller}::ISA"}, $_[0] eq __PACKAGE__ ? 'Exporter' : $_[0];
    }
    # Inject _import as import
    *{"${caller}::import"} = \&_import;
    # No symbols to export
}

sub _import
{
    if (@_ >= 2 && $_[1] eq '-base') {
	splice @_, 1, 1;
	my $caller = caller;
	push @{"${caller}::ISA"}, $_[0];
    }
    goto &Exporter::import;
}

1;
__END__

=head1 NAME

Exporter::WithBase - Like Exporter, but add '-base' to declare a child class

=head1 SYNOPSIS

    # file Mother.pm
    package Mother;
    use Exporter::WithBase;
    our @EXPORT = qw<ONE>;
    use constant ONE => 1;
    ...


    # file Child.pm
    package Child;
    # instead of: use parent 'Mother'
    use Mother -base;
    print ONE, "\n";

=head1 DESCRIPTION

Does the same things as L<Exporter>, but also supports a C<-base> flag. That
flag can be used in the C<use> statement of a class to push the class into
C<@ISA>.

=head1 SEE ALSO

L<import::Base>, L<parent>, L<Mojo::Base>.

=head1 AUTHOR

Olivier MenguE<eacute>, E<lt>L<dolmen@cpan.org|mailto:dolmen@cpan.org>E<gt>.

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2012 Olivier MenguE<eacute>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
