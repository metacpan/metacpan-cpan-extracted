package Kwiki::Preferences;
use Kwiki::Base -Base;

field class_id => 'preferences';
const preference_class => 'Kwiki::Preference';
field objects_by_class => {};

sub load {
    my $values = shift;
    my $prefs = $self->hub->registry->lookup->preference;
    for (sort keys %$prefs) {
        my $array = $prefs->{$_};
        my $class_id = $array->[0];
        my $hash = {@{$array}[1..$#{$array}]}
          or next;
        next unless $hash->{object};
        my $object = $hash->{object}->clone;
        $object->value($values->{$_});
        push @{$self->objects_by_class->{$class_id}}, $object;
        field($_);
        $self->$_($object);
    }
    return $self;
}

sub new_preferences {
    my $values = shift;
    my $new = bless {}, ref $self;
    $new->load($values);
    return $new;
}

sub new_preference {
    $self->preference_class->new(@_);
}

#------------------------------------------------------------------------------#
package Kwiki::Preference;
use Kwiki::Base '-base';

field 'id';
field 'name';
field 'description';
field 'query';
field 'type';
field 'choices';
field 'default';
field 'handler';
field 'owner_id';
field 'size' => 20;
field 'edit';
field 'new_value';
field 'error';

sub new() {
    my $class = shift;
    my $owner = shift;
    my $self = bless {}, $class;
    my $id = shift || '';
    $self->id($id);
    my $name = $id;
    $name =~ s/_/ /g;
    $name =~ s/\b(.)/\u$1/g;
    $self->name($name);
    $self->query("$name?");
    $self->type('boolean');
    $self->default(0);
    $self->handler("${id}_handler");
    $self->owner_id($owner->class_id);
    return $self;
}

sub value {
    return $self->{value} = shift
      if @_;
    return defined $self->{value} 
      ? $self->{value}
      : $self->default;
}

sub value_label {
    my $choices = $self->choices
      or return '';
    return ${{@$choices}}{$self->value} || '';
}
    
sub form_element {
    my $type = $self->type;
    return $self->$type;
}

sub input {
    my $name = $self->owner_id . '__' . $self->id;
    my $value = $self->value;
    my $size = $self->size;
    return <<END
<input type="text" name="$name" value="$value" size="$size" />
END
}

sub boolean {
    my $name = $self->owner_id . '__' . $self->id;
    my $value = $self->value;
    my $checked = $value ? 'checked="checked"' : '';
    return <<END
<input type="checkbox" name="$name" value="1" $checked />
<input type="hidden" name="$name-boolean" value="0" $checked />
END
}

sub radio {
    my $i = 1;
    my @choices = @{$self->choices};
    my @values = grep {$i++ % 2} @choices;
    my $value = $self->value;

    join "\n", 
        '<table bgcolor="#e0e0e0"><tr><td align="left">', 
        CGI::radio_group(
            -name => $self->owner_id . '__' . $self->id,
            -values => \@values,
            -default => $value,
            -labels => { @choices },
            -override => 1,
            -linebreak=>'true',
        ),
        '</td></tr></table>';
}

sub pulldown {
    my $i = 1;
    my @choices = @{$self->choices};
    my @values = grep {$i++ % 2} @choices;
    my $value = $self->value;
    CGI::popup_menu(
        -name => $self->owner_id . '__' . $self->id,
        -values => \@values,
        -default => $value,
        -labels => { @choices },
        -override => 1,
    );
}

__DATA__

=head1 NAME

Kwiki::Preferences - Kwiki Preferences Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
