package Discord::Client::UI;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use Exporter 'import';
use JSON::PP ();

our $VERSION = '0.001';
our @EXPORT_OK = qw(row button text_input modal);

sub _text {
    my ( $value, $maximum, $name ) = @_;

    # Validate character length before coercing a Perl scalar into a JSON string.
    croak "$name must be a string of 1 to $maximum characters"
        unless defined($value)
        && !ref($value)
        && length($value) >= 1
        && length($value) <= $maximum;
    return "$value";
}

sub button {
    my ( $custom_id, %options ) = @_;

    # Named styles keep numeric Discord component values out of application code.
    my %styles = ( primary => 1, secondary => 2, success => 3, danger => 4 );
    my $style = delete( $options{style} ) // 'primary';
    croak 'Unknown button style' unless !ref($style) && exists $styles{$style};
    croak 'Use native JSON for link or premium buttons'
        if exists( $options{url} ) || exists( $options{sku_id} );

    # Normalize optional wire fields before constructing the component payload.
    $options{label} = _text( $options{label}, 80, 'Button label' );
    $options{disabled} = $options{disabled} ? JSON::PP::true : JSON::PP::false
        if exists $options{disabled};
    return {
        %options,
        type => 2,
        style => $styles{$style},
        custom_id => _text( $custom_id, 100, 'Button ID' ),
    };
}

sub row {
    my (@components) = @_;

    # Message Action Rows contain up to five buttons or exactly one select menu.
    croak 'An action row requires one to five components' unless @components >= 1 && @components <= 5;
    for my $component (@components) {
        croak 'Invalid action row component'
            unless ref($component) eq 'HASH'
            && ( $component->{type} // '' ) =~ /\A[235678]\z/;
        croak 'A select menu must occupy its own action row'
            if $component->{type} != 2 && @components != 1;
    }
    return { type => 1, components => \@components };
}

sub text_input {
    my ( $custom_id, %options ) = @_;

    # Modal Text Inputs belong inside Labels; callers describe only the field.
    my $label = _text( delete( $options{label} ), 45, 'Input label' );
    my $description = delete $options{description};
    my %styles = ( short => 1, paragraph => 2 );
    my $style = delete( $options{style} ) // 'short';
    croak 'Unknown text input style' unless !ref($style) && exists $styles{$style};

    # Normalize optional bounds before assembling the nested Label and Text Input.
    for my $name (qw(min_length max_length)) {
        next unless exists $options{$name};
        my $minimum = $name eq 'min_length' ? 0 : 1;
        my $value = $options{$name};
        croak "Invalid $name"
            unless defined($value)
            && !ref($value)
            && $value =~ /\A\d+\z/
            && $value >= $minimum
            && $value <= 4000;
        $options{$name} = 0 + $value;
    }
    croak 'min_length exceeds max_length'
        if ( $options{min_length} // 0 ) > ( $options{max_length} // 4000 );
    $options{required} = $options{required} ? JSON::PP::true : JSON::PP::false
        if exists $options{required};

    # Keep Label metadata separate from the nested input properties.
    my $field = {
        type => 18,
        label => $label,
        component => {
            %options,
            type => 4,
            style => $styles{$style},
            custom_id => _text( $custom_id, 100, 'Input ID' ),
        },
    };
    $field->{description} = _text( $description, 100, 'Input description' ) if defined $description;
    return $field;
}

sub modal {
    my ( $custom_id, %options ) = @_;
    my $fields = delete $options{fields};

    # Build the native payload expected by Interaction->modal without sending it.
    croak 'A modal requires one to five fields'
        unless ref($fields) eq 'ARRAY' && @$fields >= 1 && @$fields <= 5;

    # Reject duplicate input IDs so field lookup identifies exactly one submitted value.
    my %ids;
    for my $field (@$fields) {
        croak 'A modal field must be a Label'
            unless ref($field) eq 'HASH'
            && ( $field->{type} // 0 ) == 18
            && ref( $field->{component} ) eq 'HASH';
        my $id = _text( $field->{component}{custom_id}, 100, 'Input ID' );
        croak 'Duplicate modal field ID' if $ids{$id};
        $ids{$id} = 1;
    }
    return {
        %options,
        custom_id => _text( $custom_id, 100, 'Modal ID' ),
        title => _text( $options{title}, 45, 'Modal title' ),
        components => $fields,
    };
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::UI - Hashref helpers for buttons and modal inputs

=head1 SYNOPSIS

    use Discord::Client::UI qw(row button text_input modal);

    # Build message controls without I/O.
    my $controls = [row(button('open_form', label => 'Open form'))];

    # Build a modal for $interaction->modal($form).
    my $form = modal(
        'feedback_form', title => 'Feedback',
        fields => [text_input('note', label => 'Your note', style => 'paragraph')],
    );

=head1 DESCRIPTION

Optional functions that return Discord hashrefs without I/O.
Invalid supported arguments throw. Use native JSON for
L<additional component types and fields|https://docs.discord.com/developers/components/reference>.
Register handlers with L<Discord::Client/component>; read submitted text with
L<Discord::Client::Interaction/field>.

=head1 FUNCTIONS

=head2 button

C<button(custom_id, label =E<gt> ..., style =E<gt> ...)> returns an interactive
button hashref. Styles are C<primary> (default), C<secondary>, C<success> and
C<danger>. A label is required. C<disabled> becomes a JSON boolean;
additional fields such as C<emoji> are preserved. Use native JSON for
emoji-only, link or premium buttons.

=head2 row

C<row(components...)> returns a message Action Row with one to five buttons
or one native select menu. These rows work with C<content> and do not set the
Components V2 flag.

=head2 text_input

C<text_input(custom_id, label =E<gt> ..., style =E<gt> ...)> returns a Label
containing a Text Input. Styles are C<short> (default) and C<paragraph>.
C<description> belongs to the Label; C<required>, C<min_length>, C<max_length>,
C<placeholder> and C<value> belong to the input. C<required> becomes a JSON
boolean. Omitting it uses Discord's default.

=head2 modal

C<modal(custom_id, title =E<gt> ..., fields =E<gt> [...])> returns a modal hashref
with one to five Labels and unique field IDs. Send it explicitly with
C<< $interaction->modal($form) >>.

=head1 LICENSE

Apache License 2.0.

=cut
