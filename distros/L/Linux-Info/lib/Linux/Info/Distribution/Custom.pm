package Linux::Info::Distribution::Custom;

use strict;
use warnings;
use Carp       qw(confess);
use Hash::Util qw(lock_hash unlock_hash);
use parent 'Linux::Info::Distribution';
use Class::XSAccessor getters =>
  { get_source => 'source', get_regex => 'regex' };

our $VERSION = '2.11'; # VERSION

# ABSTRACT: custom files data of a Linux distribution


sub _set_regex {
    confess 'Must be implemented by subclasses of ' . ref(shift);
}

sub _set_others {
    confess 'Must be implemented by subclasses of ' . ref(shift);
}

sub _parse_source {
    my $self = shift;
    $self->_set_regex;
    my %match_result;
    my $source_file = $self->{source};

    open( my $in, '<', $source_file )
      or confess("Cannot read $source_file: $!");

    while (<$in>) {
        chomp;
        if ( $_ =~ $self->{regex} ) {
            map { $match_result{$_} = $+{$_} } keys %+;
            last;
        }
    }

    close($in)
      or confess("Cannot close $source_file: $!");
    confess "Failed to parse the content of $source_file"
      unless ( scalar( keys %match_result ) > 0 );
    $self->{source} = $source_file;
    $self->_set_others( \%match_result );
}


sub new {
    my ( $class, $attribs_ref ) = @_;

    confess 'The hash reference is missing the "file_to_parse" key'
      unless ( exists $attribs_ref->{file_to_parse} );

    # delaying definition until the file is parsed
    $attribs_ref->{version}    = undef;
    $attribs_ref->{version_id} = undef;
    $attribs_ref->{name}       = $attribs_ref->{id};

    my $self = $class->SUPER::new($attribs_ref);
    unlock_hash( %{$self} );
    $self->{source} = $attribs_ref->{file_to_parse};
    $self->_parse_source;
    lock_hash( %{$self} );
    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::Distribution::Custom - custom files data of a Linux distribution

=head1 VERSION

version 2.11

=head1 DESCRIPTION

This class is a subclass of L<Linux::Info::Distribution>.

It will provide basic interfaces for subclasses of it to handle the different
variations of text file containing the distribution informations.

Subclasses are required to override two "private" methods in order to inherit
from this class:

=over

=item *

C<_set_regex> sets the C<regex> attribute with the regular expression required
to parse the file content (usually a single line). This expression must use
named match groups to extract available information that is relevant.

=item *

C<_set_others> sets all other fields available on the subclass, which will have
their values extracted from the match groups.

This method will receive as a parameter a hash reference, which will contain the
extract values using the regular expression groups, and such information should
be used to build or be directly used in the subclass attributes.

=back

Both of those methods are invoked during the execution of C<new>.

=head1 METHODS

=head2 new

Creates and returns a new instance of this class.

Expects as parameter a hash reference containing one single key which is
C<file_to_parse>, which will be used to read the file that contains the
expected information to be extracted from.

=head2 get_source

Returns a string with the complete path to the file that provided the
distribution information.

=head2 get_regex

Returns the compiled regular expression created to parse this instance source
file.

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
