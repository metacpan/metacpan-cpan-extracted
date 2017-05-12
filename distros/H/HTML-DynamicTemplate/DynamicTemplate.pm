#==================================================================
# DynamicTemplate.pm

package HTML::DynamicTemplate;
use strict;

use vars qw($VERSION);
$VERSION = "0.94";



#==================================================================

=head1 NAME

HTML::DynamicTemplate - HTML template class.

=head1 SYNOPSIS

  use HTML::DynamicTemplate;
  my $template = new HTML::DynamicTemplate 'path/to/template';
  $template->set_recursion_limit($integer);
  $template->set(NAME => $value);
  $template->set(NAME_1 => $value_1,
                 NAME_2 => $value_2,
                 NAME_3 => $value_3);

  $template->clear();
  $template->render();
  $template->render(@variables);

  path/to/template
  ----------------
  <html>
  <body>
  <h1>$HEADING</h1>

  <p><font color="$HIGHLIGHT_COLOR">This is standard HTML with
  arbitrary embedded variable references which are substituted
  with actual values when the template is rendered.</font></p>

  <p>Template variables may be set within the template itself
  with the special $SET directive. This is useful when setting
  variables for use by included templates. Example:
  $SET(PAGE_TITLE, "What's New"). Note: Be sure to escape
  quotes (&quot;) and closing parantheses (&#41;) as HTML
  entities.</p>

  <p>Additionally, templates may be recursively included by
  specifying a template with the special $INCLUDE directive.
  Example: $INCLUDE(templates/example.tmpl). Template paths may
  be variable references as in $INCLUDE($EXAMPLE_FILE). Note:
  Any variable references found in included templates will be
  substituted as in the original template.

  <p>Usage note: variable and directive names are always
  specified in uppercase.</p>

  </body>
  </html>

=head1 DESCRIPTION

The C<HTML::DynamicTemplate> is a class implementing a HTML
template in perl. Significant features include the ability to set
template variables from within the template itself, the ability to
recursively include other templates, and the ability to selectively
render a specified subset of variables.

=head1 METHODS

=over 4

=cut

#==================================================================

=item $template = new HTML::DynamicTemplate $template_filename;

Constructor for the template. Returns a reference to a
HTML::DynamicTemplate object based on the specified template file.

=cut

sub new {
    my($class, $template) = @_;

    my $self = {};
    bless $self, $class;

    $self->{'vars'} = {};
    $self->{'source'} = '';
    $self->{'recursion_level'} = 0;
    $self->{'recursion_limit'} = 10;
    $self->{'template'} = $template;

    open TEMPLATE, $template or die $!;
    while(<TEMPLATE>) { $self->{'source'} .= $_ }
    close TEMPLATE;

    return $self;
}



#==================================================================

=item $template->set_recursion_limit($integer);

A default recursion limit for template includes is implemented to
prevent infinite recursions. Use this method to override the
default value (10).

=cut

sub set_recursion_limit {
    my($self, $limit) = @_;

    $self->{'recursion_limit'} = $limit
        unless $limit !~ m/^\d+$/;

    return;
}

#==================================================================

=item $template->set(NAME => $value);

Sets template variable to given value.

=cut

sub set {
    my($self, @arguments) = @_;

    while(my $name = shift @arguments) {
        my $value = shift @arguments;
        $value = '' unless defined $value;
        $self->{'vars'}{uc $name} = $value;
    }

    return;
}

#==================================================================

=item $template->clear();

Clears template variables. Useful when processing table row
templates.

=cut

sub clear {
    my($self) = @_;

    $self->{'vars'} = {};

    return;
}

#==================================================================

=item $template->render();

Renders template by performing variable substitutions.

=cut

=item $template->render(@variables);

Renders template by performing variable substitutions on only those
variable names specified in @variables.

=cut

sub render {
    my($self, @variables) = @_;

    $self->{'recursion_level'} = 0;
    return $self->_substitute($self->{'source'}, @variables);
}



#==================================================================

sub _substitute {
    my($self, $source, @variables) = @_;

    $source =~ s/\$([0-9_A-Z]+)(\(([^)]+)\))?(\n?)/
        if($1 eq 'SET' and defined $2) {
            if($3 =~ m%^([0-9_A-Z]+)\s*,\s*"([^"]+)"$%) {
                $self->{'vars'}{$1} = $2
            }
            "";
        } elsif($1 eq 'INCLUDE' and defined $2) {
            if($self->{'recursion_level'} < $self->{'recursion_limit'}) {
                $self->_include($self->_substitute($3), @variables).$4
            } else {
                "[ include recursion limit exceeded ]$4"
            }
        } elsif($#variables > 0) {
            if($self->_is_in_array($1, @variables)) {
                $self->{'vars'}{$1}.$4
            } else {
                $4
            }
        } else {
            $self->{'vars'}{$1}.$4
        }
    /egm;

    return $source;
}

#==================================================================

sub _include {
    my($self, $template, @variables) = @_;

    my $source;
    open TEMPLATE, $template or return "[ $template: $! ]";
    while(<TEMPLATE>) { $source .= $_ }
    close TEMPLATE;
    chomp $source;

    $self->{'recursion_level'}++;
    $source = $self->_substitute($source, @variables);
    $self->{'recursion_level'}--;

    return $source;
}

#==================================================================

sub _is_in_array {
    my($self, $element, @array) = @_;

    for my $index (0..$#array) {
        return 1 unless $element ne $array[$index];
    }

    return 0;
}



1;
__END__



=back

=head1 AUTHOR

Copyright (c) 1999 Brian Ng. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

Created May 10, 1999 by Brian Ng <brian@m80.org>.

Based on original work by Brian Slesinsky.

=cut
