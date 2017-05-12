use 5.008;
use strict;
use warnings;

package Hook::Modular::Rules;
BEGIN {
  $Hook::Modular::Rules::VERSION = '1.101050';
}
# ABSTRACT: Workflow rules
use Hook::Modular::Operator;

sub new {
    my ($class, $op, @rules) = @_;
    Hook::Modular::Operator->is_valid_op(uc($op))
      or Hook::Modular->context->error("operator $op not supported");
    bless {
        op    => uc($op),
        rules => [ map Hook::Modular::Rule->new($_), @rules ],
    }, $class;
}

sub dispatch {
    my ($self, $plugin, $hook, $args) = @_;
    return 1 unless $plugin->dispatch_rule_on($hook);
    my @bool;
    for my $rule (@{ $self->{rules} }) {
        push @bool, ($rule->dispatch($args) ? 1 : 0);
    }

    # can't find rules for this phase: execute it
    return 1 unless @bool;
    Hook::Modular::Operator->call($self->{op}, @bool);
}

sub id {
    my $self = shift;
    join '|', map $_->id, @{ $self->{rules} };
}

sub as_title {
    my $self = shift;
    join " $self->{op} ", map $_->as_title, @{ $self->{rules} };
}
1;


__END__
=pod

=head1 NAME

Hook::Modular::Rules - Workflow rules

=head1 VERSION

version 1.101050

=head1 METHODS

=head2 as_title

FIXME

=head2 dispatch

FIXME

=head2 id

FIXME

=head2 new

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

