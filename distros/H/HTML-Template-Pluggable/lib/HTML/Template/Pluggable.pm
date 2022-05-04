package HTML::Template::Pluggable;
use base 'HTML::Template';
use Class::Trigger;
use vars (qw/$VERSION/);
$VERSION = '0.20';
use warnings;
use strict;
use Carp;

=head1 NAME

HTML::Template::Pluggable - Extends HTML::Template with plugin support

=cut

=head1 SYNOPSIS

Just use this module instead of HTML::Template, then use any plugins,
and go on with life. 

 use HTML::Template::Pluggable;
 use HTML::Template::Plugin::Dot;

 # Everything works the same, except for functionality that plugins add. 
 my $t = HTML::Template::Pluggable->new();

=head1 THE GOAL

Ideally we'd like to see this functionality merged into HTML::Template,
and turn this into a null sub-class. 

=head1 STATUS

The design of the plugin system is still in progress. Right now we have just
two triggers, in param and output. The name and function of this may change,
and we would like to add triggers in new() and other methods when the need
arises. 

All we promise for now is to keep L<HTML::Template::Plugin::Dot> compatible.
Please get in touch if you have suggestions with feedback on designing the
plugin system if you would like to contribute. 

=cut

sub param {
  my $self = shift;
  my $options = $self->{options};
  my $param_map = $self->{param_map};

  # the no-parameter case - return list of parameters in the template.
  return keys(%$param_map) unless scalar(@_);
  
  my $first = shift;
  my $type = ref $first;

  # the one-parameter case - could be a parameter value request or a
  # hash-ref.
  if (!scalar(@_) and !length($type)) {
    my $param = $options->{case_sensitive} ? $first : lc $first;
    
    # check for parameter existence 
    $options->{die_on_bad_params} and !exists($param_map->{$param}) and
      croak("HTML::Template : Attempt to get nonexistent parameter '$param' - this parameter name doesn't match any declarations in the template file : (die_on_bad_params set => 1)");
    
    return undef unless (exists($param_map->{$param}) and
                         defined($param_map->{$param}));

    return ${$param_map->{$param}} if 
      (ref($param_map->{$param}) eq 'HTML::Template::VAR');
    return $param_map->{$param}[HTML::Template::LOOP::PARAM_SET];
  } 

  if (!scalar(@_)) {
    croak("HTML::Template->param() : Single reference arg to param() must be a hash-ref!  You gave me a $type.")
      unless $type eq 'HASH' or 
        (ref($first) and UNIVERSAL::isa($first, 'HASH'));  
    push(@_, %$first);
  } else {
    unshift(@_, $first);
  }
  
  croak("HTML::Template->param() : You gave me an odd number of parameters to param()!")
    unless ((@_ % 2) == 0);

  $self->call_trigger('middle_param', @_);

  # strangely, changing this to a "while(@_) { shift, shift }" type
  # loop causes perl 5.004_04 to die with some nonsense about a
  # read-only value.
  for (my $x = 0; $x <= $#_; $x += 2) {
    my $param = $options->{case_sensitive} ? $_[$x] : lc $_[$x];
    my $value = $_[($x + 1)];

     # necessary to cooperate with plugin system
     next if $self->{param_map_done}{$param};
    
    # check that this param exists in the template
    $options->{die_on_bad_params} and !exists($param_map->{$param}) and
      croak("HTML::Template : Attempt to set nonexistent parameter '$param' - this parameter name doesn't match any declarations in the template file : (die_on_bad_params => 1)");
    
    # if we're not going to die from bad param names, we need to ignore
    # them...
    next unless (exists($param_map->{$param}));
    
    # figure out what we've got, taking special care to allow for
    # objects that are compatible underneath.
    my $value_type = ref($value);
    if (defined($value_type) and length($value_type) and ($value_type eq 'ARRAY' or ((ref($value) !~ /^(CODE)|(HASH)|(SCALAR)$/) and $value->isa('ARRAY')))) {
      (ref($param_map->{$param}) eq 'HTML::Template::LOOP') or
        croak("HTML::Template::param() : attempt to set parameter '$param' with an array ref - parameter is not a TMPL_LOOP!");
      $param_map->{$param}[HTML::Template::LOOP::PARAM_SET] = [@{$value}];
    } else {
      (ref($param_map->{$param}) eq 'HTML::Template::VAR') or
        croak("HTML::Template::param() : attempt to set parameter '$param' with a scalar - parameter is not a TMPL_VAR!");
      ${$param_map->{$param}} = $value;
    }
  }
}


sub output
{
    my $self = shift;
    $self->call_trigger('before_output', @_);

    $self->SUPER::output(@_);
}


=head1 WRITING PLUGINS

HTML::Template offers a plugin system which allows developers to extend the
functionality in significant ways without creating a creating a sub-class,
which might be impossible to use in combination with another sub-class
extension.

Currently, two triggers have been made available to alter how the values of
TMPL_VARs are set. If more hooks are needed to implement your own plugin idea,
it may be feasible to add them-- check the FAQ then ask about it on the list.

L<Class::Trigger> is used to provide plugins. Basically, you can just: 

    HTML::Template->add_trigger('middle_param', \&trigger);

A good place to add one is in your plugin's C<import> subroutine:

    package HTML::Template::Plugin::MyPlugin;
    use base 'Exporter';
    sub import {
        HTML::Template->add_trigger('middle_param', \&dot_notation);
        goto &Exporter::import;
    }

=head2 TRIGGER LOCATIONS

=over 4

=item param

We have added one trigger location to this method, named C<middle_param>.

   # in a Plugin's import() routine. 
   HTML::Template->add_trigger('middle_param',   \&_set_tmpl_var_with_dot  );

This sets a callback which is executed in param() with all of the same
arguments. It is only useful for altering how /setting/ params works. 
The logic to read a param is unaffected. 

It can set any TMPL_VAR values before the normal param logic kicks in. To do
this, C<$self-E<gt>{param_map}> is modified as can be seen from source in
HTML::Template::param(). However, it must obey the following convention of
setting $self->{param_map_done}{$param_name} for each param that is set.
C<$param_name> would be a key from C<$self-E<gt>{param_map}>.  This notifies the
other plugins and the core param() routine to skip trying to set this value.
$self->{param_map_done} is reset with each call to param(), so that like with a
hash, you have the option to reset a param later with the same name.

=item output

One trigger location here: C<before_output>.

   HTML::Template->add_trigger('before_output',   \&_last_chance_params  );

This sets a callback which is executed right before output is generated.

=back

=head1 SEE ALSO

=over 4

=item o

L<HTML::Template::Plugin::Dot> - Add Template Toolkit's magic dot notation to
HTML::Template.

=back

=head1 AUTHOR

Mark Stosberg, C<< <mark@summersault.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-template-pluggable@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 Copyright & License

Copyright 2006 Mark Stosberg, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::Template::Pluggable
