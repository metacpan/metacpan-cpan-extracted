package Kwiki::Pane;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';

sub order { () }
sub pane_unit { $self->class_id }

sub register {
    my $registry = shift;
    $registry->add(preload => $self->class_id);
}

sub html {
    return $self->{html} if defined $self->{html};

    my @all = $self->pages->current->all;
    my $pane_info = $self->pane_info; 
    my $params_method = $self->class_id . '_params';
    my @units = grep {
        defined $_ and do {
            my $button = $_;
            $button =~ s/<!--.*?-->//gs;
            $button =~ /\S/;
        }
    } map {
        $self->show($_)
          ? $self->template->process(
              $_->{template},
              @all,
              $_->{params_class}
                ? do {
                    my $class_id = $_->{params_class};
                    $self->hub->$class_id->$params_method
                }
                : ()
          )
          : undef
    } map {
        $pane_info->{$_};
    } $self->ordered_unit_ids;
    
    $self->{html} = $self->template->process($self->pane_template,
        units => \ @units,
    );
}

sub pane_info {
    my $units = $self->hub->registry->lookup->{$self->pane_unit}
      or return {};
    my $info;
    for my $unit_id (keys %$units) {
        my $array = $units->{$unit_id};
        $info->{$unit_id} = {@{$array}[1..$#{$array}]};
    }
    return $info;
}

sub ordered_unit_ids {
    my $lookup = $self->hub->registry->lookup;
    my @unit_ids = map {
        @{$lookup->{add_order}{$_->{id}}{$self->pane_unit} || []};
    } @{$lookup->plugins};
    my @ordered_unit_ids;
    for my $unit_id ($self->order) {
        for (my $i = 0; $i < @unit_ids; $i++) {
            if ($unit_id eq $unit_ids[$i]) {
                push @ordered_unit_ids, splice @unit_ids, $i, 1;
                last;
            }
        }
    }
    (@ordered_unit_ids, @unit_ids);
}

sub show {
    my $unit = shift;
    my $action = $self->hub->action;
    my $show = $unit->{show_for};
    if (defined $show) {
        for (ref($show) ? (@$show) : ($show)) {
            return 1 if $_ eq $action;
        }
        return 0;
    }
    my $omit = $unit->{omit_for};
    if (defined $omit) {
        for (ref($omit) ? (@$omit) : ($omit)) {
            return 0 if $_ eq $action;
        }
        return 1;
    }
    my $pref = $unit->{show_if_preference};
    if (defined $pref) {
        return $self->preferences->$pref->value;
    }
    
    return 1;
}
