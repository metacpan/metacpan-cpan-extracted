package Kwiki::UserPreferences;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.13';

const class_id => 'user_preferences';
const class_title => 'User Preferences';
field preference_objects => [];

sub register {
    my $registry = shift;
    $registry->add(action => 'user_preferences');
    $registry->add(toolbar => 'user_preferences_button', 
                   template => 'user_preferences_button.html',
                  );
}

sub user_preferences {
    $self->get_preference_objects;
    my $errors = 0;
    $errors = $self->save 
      if $self->cgi->button;
    return $self->render_screen(errors => $errors);
}

sub save {
    my %cgi = $self->cgi->vars;
    my $settings = {};
    my $errors = 0;
    for my $object (@{$self->preference_objects}) {
        $object->error('');
        my $class_id = $object->owner_id;
        for (sort keys %cgi) {
            my $setting = $cgi{$_};
            if (/^${class_id}__(.*)/) {
                my $pref = $1;
                $pref =~ s/-boolean$//;
                if (not exists $settings->{$pref}) {
                    $settings->{$pref} = $setting;
                    $object->new_value($setting);
                    if ($object->edit) {
                        my $method = $object->edit;
                        $self->hub->$class_id->$method($object);
                        $errors = 1, next if $object->error;
                    }
                    $object->value($setting);
                }
            }
        }
    }
    return 1 if $errors;
    $self->hub->cookie->jar->{preferences} = $settings;
    return 0;
}

sub get_preference_objects {
    my %class_map = reverse %{$self->hub->registry->lookup->classes};

    my @objects;
    my $objects_by_class = $self->users->current->preferences->objects_by_class;
    for (map $class_map{$_}, @{$self->hub->config->plugin_classes}) {
        push @objects, @{$objects_by_class->{$_}}
          if defined $objects_by_class->{$_};      
    }
    $self->preference_objects(\ @objects);
}
    
__DATA__

=head1 NAME 

Kwiki::UserPreferences - Kwiki User Preferences Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/user_preferences_button.html__
<a href="[% script_name %]?action=user_preferences" accesskey="u" title="User Preferences">
[% INCLUDE user_preferences_button_icon.html %]
</a>
__template/tt2/user_preferences_button_icon.html__
Preferences
__template/tt2/user_preferences_content.html__
[% screen_title = 'User Preferences' %]
<div class="user_preferences">
<form method="post">
<input type="submit" name="button" value="SAVE" />
[% IF errors %]
<span class="error">Errors in input. Values not saved.</span>
[% END %]
<br />
<br />
<table width="100%">
[% FOR pref = self.preference_objects %]
<tr>
<td align="right">
<table><tr><td>
<b>[% pref.query %]</b>
</td></tr></table>
</td>
<td>
&nbsp;
</td>
<td>
[% method = pref.type %]
[% pref.$method %]
</td>
</tr>
<tr colspan="3"><td>
[% IF pref.error %]
<span class="error">[% pref.error %]</span>
[% ELSE %]
&nbsp;
[% END %]
</td></tr>
[% END %]
</table>
<input type="hidden" name="action" value="user_preferences" />
</form>
