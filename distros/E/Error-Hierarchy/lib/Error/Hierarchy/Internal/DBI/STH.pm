use 5.008;
use strict;
use warnings;

package Error::Hierarchy::Internal::DBI::STH;
BEGIN {
  $Error::Hierarchy::Internal::DBI::STH::VERSION = '1.103530';
}
# ABSTRACT: DBI statement-related exception
use Error::Hierarchy::Util 'load_class';
use parent 'Error::Hierarchy::Internal::DBI::H';

# DBI exceptions store extra values, but don't use them in the message string.
# They are marked as properties, however, so generic exception handling code
# can introspect them.
__PACKAGE__->mk_accessors(
    qw(
      num_of_fields num_of_params field_names type precision scale
      nullable cursor_name param_values statement rows_in_cache
      )
);
use constant PROPERTIES => (
    qw(num_of_fields num_of_params field_names type precision scale nullable
      cursor_name param_values statement rows_in_cache)
);
sub TRANSMUTED_EXCEPTION { () }

sub transmute_exception {
    my $self      = shift;
    my $transmute = $self->every_hash('TRANSMUTED_EXCEPTION');
    my $found_class;
    if (exists $transmute->{ $self->err }) {
        my $spec = $transmute->{ $self->err };
        if (ref $spec eq 'HASH') {
            while (my ($errstr_regex, $exception_class) = each %$spec) {
                next unless $self->errstr =~ qr/$errstr_regex/;
                load_class $exception_class, 1;
                $found_class = $exception_class;

                # Don't just
                #
                #   return bless $self, $exception_class;
                #
                # because there seems to be some perl bug; when another object
                # of this package is created and this method is called again,
                # the subhash - the one we're iterating over with each() right
                # now - is empty. But when we dump the $transmute hash with
                # Data::Dumper, it's back. Maybe there's some problem with
                # reblessing things we're iterating over.
                #
                # Well, the manpage for each() does say: There is a single
                # iterator for each hash, shared by all "each", "keys", and
                # "values" function calls in the program; it can be reset by
                # reading all the elements from the hash, or by evaluating
                # "keys HASH" or "values HASH".
            }
        } else {

            # if it's just a scalar, then it doesn't depend on the errstr,
            # just the err number.
            load_class $spec, 1;
            $found_class = $spec;

            # Can't just
            #
            #   return bless $self, $spec;
            #
            # because of the reasons mentioned above
        }
    }

    # no match found_class; don't transmute
    return $self unless $found_class;
    bless $self, $found_class;
}
1;


__END__
=pod

=head1 NAME

Error::Hierarchy::Internal::DBI::STH - DBI statement-related exception

=head1 VERSION

version 1.103530

=head1 DESCRIPTION

This class is part of the DBI-related exceptions. It is internal and you're
not supposed to use it.

=head1 METHODS

=head2 transmute_exception

Transmute the exception according to a two-level hash where the keys are DBI
exception's C<err> and C<errstr> and the value is an exception class name.

If no match is found, the exception is not changed. If a match is found, the
exception is blessed to the new package and returned.

=head2 TRANSMUTED_EXCEPTION

An inherited hash - see C<every_hash()> in L<Data::Inherited> - that defines
the mappings for C<transmute_exception()>.

=head1 PROPERTIES

This exception class inherits all properties of
L<Error::Hierarchy::Internal::DBI::H>.

It has the following additional properties.

=over 4

=item C<num_of_fields>

=item C<num_of_params>

=item C<field_names>

=item C<type>

=item C<precision>

=item C<scale>

=item C<nullable>

=item C<cursor_name>

=item C<param_values>

=item C<statement>

=item C<rows_in_cache>

=back

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

