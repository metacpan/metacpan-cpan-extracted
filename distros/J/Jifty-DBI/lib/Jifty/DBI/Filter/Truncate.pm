
use strict;
use warnings;

package Jifty::DBI::Filter::Truncate;
use base qw/Jifty::DBI::Filter/;
use Encode ();

=head1 NAME

Jifty::DBI::Filter::Truncate - Filter used to enforce max_length column trait

=head1 DESCRIPTION

You do not need to use this filter explicitly. This filter is used internally to enforce the L<Jifty::DBI::Schema/max_length> restrictions on columns:

  column name =>
      type is 'text',
      max_length is 10;

In this case, the filter would be automatically added to the column named C<name> and any value put into the column longer than 10 characters would be truncated to 10 characters.

=head1 METHODS

=head2 encode

This method performs the work of performing truncation, when necessary.

=cut

sub encode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return undef unless ( defined($$value_ref) );

    my $column = $self->column();

    my $truncate_to;
    if ( $column->max_length && !$column->is_numeric ) {
        $truncate_to = $column->max_length;
    } elsif ( $column->type && $column->type =~ /char\((\d+)\)/ ) {
        $truncate_to = $1;
    }

    return unless ($truncate_to);    # don't need to truncate

    my $utf8 = Encode::is_utf8($$value_ref);
    {
        use bytes;
        $$value_ref = substr( $$value_ref, 0, $truncate_to );
    }
    if ($utf8) {

        # return utf8 flag back, but use Encode::FB_QUIET because
        # we could broke tail char
        $$value_ref = Encode::decode_utf8( $$value_ref, Encode::FB_QUIET );
    }
}

=head1 LICENSE

Jifty::DBI is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty::DBI is distributed under the same terms as Perl itself.

=cut

1;
