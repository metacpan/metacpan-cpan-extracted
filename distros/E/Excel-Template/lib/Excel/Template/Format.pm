package Excel::Template::Format;

use strict;

# This is the format repository. Spreadsheet::WriteExcel does not cache the
# known formats. So, it is very possible to continually add the same format
# over and over until you run out of RAM or addressability in the XLS file. In
# real life, less than 10-20 formats are used, and they're re-used in various
# places in the file. This provides a way of keeping track of already-allocated
# formats and making new formats based on old ones.

sub new { bless {}, shift }

sub _assign { $_[0]{$_[1]} = $_[2]; $_[0]{$_[2]} = $_[1] }
#    my $self = shift;
#    my ($key, $format) = @_;
#    $self->{$key} = $format;
#    $self->{$format} = $key;
#}

sub _retrieve_key { $_[0]{ $_[1] } }
#    my $self = shift;
#    my ($format) = @_;
#    return $self->{$format};
#}

*_retrieve_format = \&_retrieve_key;
#sub _retrieve_format {
#    my $self = shift;
#    my ($key) = @_;
#    return $self->{$key};
#}

{
    my @_boolean_formats = qw(
        bold italic locked hidden font_outline font_shadow font_strikeout
        text_wrap text_justlast shrink is_merged
    );

    my @_integer_formats = qw(
        size underline rotation indent pattern border
        bottom top left right
    );

    my @_string_formats = qw(
        num_format font color align valign bg_color fg_color border_color
        bottom_color top_color left_color right_color
    );

    my @_fake_slots = qw(
        is_merged
    );

    sub _params_to_key
    {
        my %params = @_;
        $params{lc $_} = delete $params{$_} for keys %params;

        # force fake slots to be zero if not set
        $params{$_} ||= 0 for @_fake_slots;

        my @parts = (
            (map { $params{$_} ? 1 : '' } @_boolean_formats),
            (map { $params{$_} ? $params{$_} + 0 : '' } @_integer_formats),
            (map { $params{$_} || '' } @_string_formats),
        );

        return join( "\n", @parts );
    }

    sub _key_to_params
    {
        my ($key) = @_;

        my @key_parts = split /\n/, $key;

        my @boolean_parts = splice @key_parts, 0, scalar( @_boolean_formats );
        my @integer_parts = splice @key_parts, 0, scalar( @_integer_formats );
        my @string_parts  = splice @key_parts, 0, scalar( @_string_formats );

        my %params;
        $params{ $_boolean_formats[$_] } = ~~1
            for grep { $boolean_parts[$_] } 0 .. $#_boolean_formats;

        $params{ $_integer_formats[$_] } = $integer_parts[$_]
            for grep { defined $integer_parts[$_] && length $integer_parts[$_] } 0 .. $#_integer_formats;

        $params{ $_string_formats[$_] } = $string_parts[$_]
            for grep { $string_parts[$_] } 0 .. $#_string_formats;

        return %params;
    }

    sub copy
    {
        my $self = shift;
        my ($context, $old_fmt, %properties) = @_;

        # This is a key used for non-format book-keeping.
        delete $properties{ ELEMENTS };

        defined(my $key = _retrieve_key($self, $old_fmt))
            || die "Internal Error: Cannot find key for format '$old_fmt'!\n";

        my %params = _key_to_params($key);
        PROPERTY:
        while ( my ($prop, $value) = each %properties )
        {
            $prop = lc $prop;
            foreach (@_boolean_formats)
            {
                if ($prop eq $_) {
                    $params{$_} = ($value && $value !~ /false/i);
                    next PROPERTY;
                }
            }
            foreach (@_integer_formats, @_string_formats)
            {
                if ($prop eq $_) {
                    $params{$_} = $value;
                    next PROPERTY;
                }
            }

            warn "Property '$prop' is unrecognized\n" if $^W;
        }

        my $new_key = _params_to_key(%params);

        my $format = _retrieve_format($self, $new_key);
        return $format if $format;

        delete $params{$_} for @_fake_slots;

        $format = $context->{XLS}->add_format(%params);
        _assign($self, $new_key, $format);
        return $format;
    }
}

sub blank_format
{
    my $self = shift;
    my ($context) = @_;

    my $blank_key = _params_to_key();

    my $format = _retrieve_format($self, $blank_key);
    return $format if $format;

    $format = $context->{XLS}->add_format;
    _assign($self, $blank_key, $format);
    return $format;
}

1;
__END__

=head1 NAME

Excel::Template::Format - Excel::Template::Format

=head1 PURPOSE

Helper class for FORMAT

=head1 NODE NAME

None

=head1 INHERITANCE

None

=head1 ATTRIBUTES

None

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

None

=head1 METHODS

=head2 blank_format

Provides a blank format for use

=head2 copy

Clones an existing format, so that a new format can be built from it

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

FORMAT

=cut
