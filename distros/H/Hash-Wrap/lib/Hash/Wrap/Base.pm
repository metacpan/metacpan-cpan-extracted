package Hash::Wrap::Base;

# ABSTRACT: Hash::Wrap  base class

use 5.008009;

use strict;
use warnings;

our $VERSION = '0.05';

our $AUTOLOAD;

use Hash::Wrap ();
use Scalar::Util;

our $generate_signature = sub { '' };
our $generate_validate = sub { 'exists $self->{<<KEY>>}' };

#pod =begin pod_coverage
#pod
#pod =head3 can
#pod
#pod =end pod_coverage
#pod
#pod =cut

sub can {

    my ( $self, $key ) = @_;

    my $class = Scalar::Util::blessed( $self );
    return if !defined $class;

    return unless exists $self->{$key};

    my $method = "${class}::$key";

    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    return *{$method}{CODE}
      || Hash::Wrap::_generate_accessor( $self, $method, $key );
}

sub DESTROY { }

sub AUTOLOAD {

    goto &{ &Hash::Wrap::_autoload( $AUTOLOAD, $_[0] ) };
}

1;

__END__

=pod

=head1 NAME

Hash::Wrap::Base - Hash::Wrap  base class

=head1 VERSION

version 0.05

=begin pod_coverage

=head3 can

=end pod_coverage

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hash-Wrap> or by email
to L<bug-Hash-Wrap@rt.cpan.org|mailto:bug-Hash-Wrap@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/hash-wrap>
and may be cloned from L<git://github.com/djerius/hash-wrap.git>

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
