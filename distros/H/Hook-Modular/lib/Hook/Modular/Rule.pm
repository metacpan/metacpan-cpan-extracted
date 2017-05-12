use 5.008;
use strict;
use warnings;

package Hook::Modular::Rule;
BEGIN {
  $Hook::Modular::Rule::VERSION = '1.101050';
}
# ABSTRACT: A Workflow rule
use UNIVERSAL::require;

sub new {
    shift;   # we don't need the class
    my $config = shift;
    if (my $exp = $config->{expression}) {
        $config->{module} = 'Expression';
    }
    my $module_suffix = delete $config->{module};
    my $module;
    my $found = 0;
    my @tried;
    for my $ns (Hook::Modular->rule_namespaces) {
        $module = $ns . '::' . $module_suffix;
        push @tried => $module;
        if ($module->require) {
            $found++;
            last;
        }
    }
    $found or die sprintf "can't find any of %s", join(', ' => @tried);
    my $self = bless {%$config}, $module;
    $self->init;
    $self;
}
sub init { }
use constant id       => 'xxx';
use constant as_title => 'xxx';
1;


__END__
=pod

=head1 NAME

Hook::Modular::Rule - A Workflow rule

=head1 VERSION

version 1.101050

=head1 METHODS

=head2 new

FIXME

=head2 init

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

