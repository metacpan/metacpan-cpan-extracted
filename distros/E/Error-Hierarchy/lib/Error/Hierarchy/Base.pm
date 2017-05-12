use 5.008;
use strict;
use warnings;

package Error::Hierarchy::Base;
BEGIN {
  $Error::Hierarchy::Base::VERSION = '1.103530';
}
# ABSTRACT: Base class for hierarchical exception classes
use parent qw(
  Error
  Data::Inherited
  Class::Accessor::Complex
);
__PACKAGE__->mk_new;    # so we don't get Error::new()
use overload
  '""'     => 'stringify',
  'cmp'    => sub { "$_[0]" cmp "$_[1]" },
  fallback => 1;
sub stringify { }

sub dump_raw {
    my $self = shift;
    require Data::Dumper;
    local $Data::Dumper::Indent = 1;
    Data::Dumper::Dumper($self);
}

sub dump_as_yaml {
    my $self = shift;
    require YAML;
    YAML::Dump($self);
}
1;


__END__
=pod

=head1 NAME

Error::Hierarchy::Base - Base class for hierarchical exception classes

=head1 VERSION

version 1.103530

=head1 DESCRIPTION

This class is internal, so you're not supposed to use it.

=head1 METHODS

=head2 new

    my $obj = Error::Hierarchy::Base->new;
    my $obj = Error::Hierarchy::Base->new(%args);

Creates and returns a new object. The constructor will accept as arguments a
list of pairs, from component name to initial value. For each pair, the named
component is initialized by calling the method of the same name with the given
value. If called with a single hash reference, it is dereferenced and its
key/value pairs are set as described before.

=head2 stringify

This class overloads C<""> to call this method. It defines how an exception
should look like if it is used in a string. In this class this method returns
an undefined value, so subclasses should override it. For example,
L<Error::Hierarchy> does so.

=head2 dump_raw

Dumps the exception using C<Data::Dumper>.

=head2 dump_as_yaml

Dumps the exception using C<YAML>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Error-Hierarchy>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Error-Hierarchy/>.

The development version lives at L<http://github.com/hanekomu/Error-Hierarchy>
and may be cloned from L<git://github.com/hanekomu/Error-Hierarchy>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

