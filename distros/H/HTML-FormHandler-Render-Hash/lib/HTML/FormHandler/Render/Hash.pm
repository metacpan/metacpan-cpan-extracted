package HTML::FormHandler::Render::Hash;

use Moose::Role;

with 'HTML::FormHandler::Render::Simple' => {
    excludes => [qw(
        render          render_field_struct render_text
        render_password render_hidden       render_select
        render_checkbox render_radio_group  render_textarea
        render_compound render_submit
    )]
};

=head1 NAME

HTML::FormHandler::Render::Hash - render a form to a raw hash

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

To render a form as a hash, use this in a form:

    package My::Form::User;
    with 'HTML::FormHandler::Render::Hash';

then, to render it to a template:

    my $data = $form->render();
    ...

=cut

sub render
{
    my $self = shift;
    
    my %output = (
        field => []
    );
    $output{action} = $self->action      if $self->action;
    $output{name}   = $self->name        if $self->name;
    $output{method} = $self->http_method if $self->http_method;

    foreach my $field ($self->sorted_fields) {
        push @{ $output{field} }, $self->render_field($field);
    }
    return \%output;
}

sub render_field_struct
{
    my ($self, $field, $rendered_field, $class) = @_;

    my %output = (
        id         => $field->id,
        widget     => $field->widget,
        label      => $field->label,
        name       => $field->html_name,
        %{ $rendered_field },
    );

    my $l_type = defined $self->get_label_type( $field->widget )
        ? $self->get_label_type( $field->widget )
        : '';
    $class =~ s/^ class="//;
    $class =~ s/"$//;
    $output{class}      = $class  if $class;
    $output{label_type} = $l_type if $l_type;

    if ($field->has_errors) {
        $output{errors} = { error => [] };
        push @{ $output{errors}{error} }, $_ for $field->errors;
    }
 
    return \%output;
}

sub render_text
{
    my ( $self, $field ) = @_;
    my %output = (
        value => $field->fif
    );
    $output{size}      = $field->size      if $field->size;
    $output{maxlength} = $field->maxlength if $field->maxlength;
 
    return \%output;
}

sub render_password
{
    my ( $self, $field ) = @_;
    return $self->render_text($field);
}

sub render_hidden
{
    my ( $self, $field ) = @_;
    return {
        value => $field->fif
    };
}

sub render_select
{
    my ( $self, $field ) = @_;

    my %output = (
        options => { option => [] }
    );
    $output{size}     = $field->size      if $field->size;
    $output{multiple} = $field->multiple == 1;

    my $index = 0;
    foreach my $opt ( $field->options )
    {
        my %option = (
            id    => $field->id . ".$index",
            value => $opt->{value},
            label => $opt->{label},
        );
        if ($field->fif)
        {
            if ( $field->multiple == 1 )
            {
                my @fif;
                if( ref $field->fif ){
                    @fif = @{ $field->fif };
                }
                else{
                    @fif = ( $field->fif );
                }
                foreach my $optval ( @fif )
                {
                    if ($optval == $opt->{value}) {
                        $option{selected} = 1;
                        last;
                    }
                }
            }
            else
            {
                $option{selected} = 1
                    if $opt->{value} eq $field->fif;
            }
        }
        push @{ $output{options}{option} }, \%option;
        $index++;
    }
    return \%output;
}

sub render_checkbox
{
    my ( $self, $field ) = @_;

    my %output = (
        value => $field->fif
    );
    $output{checkbox_value} = $field->checkbox_value if $field->checkbox_value;
    $output{checked} = 1 if $field->fif eq $field->checkbox_value;
 
    return \%output;
}


sub render_radio_group
{
    my ( $self, $field ) = @_;

    my %output = (
        options => { option => [] },
        value   => $field->fif,
    );

    my $index = 0;
    foreach my $opt ( $field->options )
    {
        my %option = (
            id    => $field->id . ".$index",
            value => $opt->{value},
            label => $opt->{label},
        );
        $option{checked} = 1 if $opt->{value} eq $field->fif;
        $index++;
    }
    return \%output;
}

sub render_textarea
{
   my ( $self, $field ) = @_;
   return {
       value => $field->fif || '',
       cols  => $field->cols || 10,
       rows  => $field->rows || 5,
   };
}

sub render_compound
{
   my ( $self, $field ) = @_;

   my %output = (
       field => []
   );
   foreach my $subfield ($field->sorted_fields)
   {
       push @{ $output{field} }, $self->render_field($subfield);
   }
   return \%output;
}

sub render_submit
{
   my ( $self, $field ) = @_;
   return {
       value => $field->fif || $field->value || '',
   };
}

=head1 AUTHOR

Michael Nachbaur, C<< <mike at nachbaur.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-formhandler-render-hash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-FormHandler-Render-Hash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::FormHandler::Render::Hash

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-FormHandler-Render-Hash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-FormHandler-Render-Hash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-FormHandler-Render-Hash>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-FormHandler-Render-Hash/>

=item * Source code access

L<http://github.com/NachoMan/HTML-FormHandler-Render-Hash/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Nachbaur.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HTML::FormHandler::Render::Hash
