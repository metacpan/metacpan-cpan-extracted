use 5.008;
use strict;
use warnings;

package Hook::Modular::Cache::Null;
BEGIN {
  $Hook::Modular::Cache::Null::VERSION = '1.101050';
}
# ABSTRACT: Null cache

sub new {
    bless {}, shift;
}

sub get {
    my ($self, $key) = @_;
    $self->{$key};
}

sub set {
    my ($self, $key, $value) = @_;
    $self->{$key} = $value;
}

sub remove {
    my ($self, $key) = @_;
    delete $self->{$key};
}
1;


__END__
=pod

=head1 NAME

Hook::Modular::Cache::Null - Null cache

=head1 VERSION

version 1.101050

=head1 DESCRIPTION

This class implements a basic, hash-based cache.

=head1 METHODS

=head2 new

This is a basic constructor; it doesn't take any arguments.

=head2 get

Takes a key argument and returns the value stored for this hash key.

=head2 set

Takes a key and a value and sets that hash key to that value.

=head2 remove

Takes a key argument and deletes the hash entry for this key.

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

