# vi:syntax=perl:

# NOTE: I'm intending to one day split this module out into something like
# Gtk2::Ex::SimpleOnePageForm It's not finished-enough to release that way, so
# I'm just storing it here until I get further with it.  If you'd like to use
# this elsewhere, lemme know and I'll finish it.
#
# -Paul

package Games::RolePlay::MapGen::Editor::_MForm;

use common::sense;
use Gtk2;
use Gtk2::SimpleList;
use Glib qw(TRUE FALSE);
use Data::Dump qw(dump);

use parent 'Exporter';
our @EXPORT_OK = qw(make_form $default_restore_defaults);
our $default_restore_defaults = sub {
        my ($button, $reref) = @_;

        $button->signal_connect( clicked => sub {
            for my $k (keys %$reref) {
                my ($item, $widget) = @{ $reref->{$k} };

                next unless exists $item->{default} or exists $item->{defaults};

                my $type = $item->{type};
                if( $type eq "choice" or $type eq "bool" ) {
                    my ($d_i) = grep {$item->{choices}[$_] eq $item->{default}} 0 .. $#{ $item->{choices} };
                    $widget->set_active( $d_i );

                } elsif( $type eq "text" ) {
                    $widget->set_text( $item->{default} );

                } elsif( $type eq "choices" ) {
                    my $def = {map {($_=>1)} @{ $item->{defaults} }};
                    my $d = $item->{choices};
                    my @s = grep {$def->{$d->[$_]}} 0 .. $#$d;

                    $widget->get_selection->unselect_all;
                    $widget->select( @s );

                } else { die "no handler for default of type $type" }
            }
        });
    };

sub make_form {
    my ($parent_window, $i, $options, $title, $extra_buttons) = @_;

    my $table = Gtk2::Table->new(scalar @{$options->[0]}*2, scalar @$options, FALSE);
    my $dialog = new Gtk2::Dialog(($title||"Data Required"), $parent_window, [], 'gtk-cancel' => "cancel", 'gtk-ok' => "ok");
       $dialog->set_default_response('ok');

    my $reref = {};

    my $c_n = 0;
    my @req;
    for my $column (@$options) {
        my $y = 0;

        for my $item (@$column) {
            my $x = 2*$c_n;

            my $label = Gtk2::Label->new_with_mnemonic($item->{mnemonic} || die "no mnemonic?");
               $label->set_alignment(1, 0.5);
               $label->set_tooltip_text( $item->{desc} ) if exists $item->{desc};

            my $my_req = @req;

            my ($widget, $attach);
            my $z = 1;
            my $IT = $item->{type};
            if( $IT eq "text" ) {
                my $d = exists $i->{$item->{name}} ? $i->{$item->{name}} : $item->{default};
                   $d = $item->{trevnoc}->($d) if ref $d and exists $item->{trevnoc};

                $attach = $widget = new Gtk2::Entry;
                $widget->set_text($d);
                $widget->set_activates_default(TRUE);

                $widget->set_tooltip_text( $item->{desc} ) if exists $item->{desc};
                $widget->signal_connect(changed => sub {
                    my $text = $widget->get_text;
                    my $chg = 0;
                    for my $fix (@{ $item->{fixes} }) {
                        $chg ++ if $fix->($text);
                    }
                    $widget->set_text($text) if $chg;
                    $req[$my_req] = 1;
                    for my $match (@{ $item->{matches} }) {
                        my $r = ref $match;
                        if( $r eq "CODE" ) {
                            $req[$my_req] = 0 unless $match->($text);

                        } elsif( $r eq "Regexp" ) {
                            $req[$my_req] = 0 unless $text =~ $match;

                        } else {
                            warn "bad match element for $item->{name}: $match";
                        }
                    }

                    $dialog->set_response_sensitive( ok => (@req == grep {$_} @req) );
                });

                if( $item->{convert} ) {
                    $item->{extract} = sub { $item->{convert}->( $widget->get_text ) };

                } else {
                    $item->{extract} = sub { $widget->get_text };
                }

              # $widget->signal_connect(changed => sub { warn "test!"; }); # [WORKS FINE]

            } elsif( $IT eq "color" ) {
                my $d = exists $i->{$item->{name}} ? $i->{$item->{name}} : $item->{default};
                   $d = $item->{trevnoc}->($d) if ref $d and exists $item->{trevnoc};
                my @c = map {(hex $_)*257} $d =~ m/([a-fA-F\d]{2})/g;

                $attach = $widget = Gtk2::ColorButton->new_with_color(Gtk2::Gdk::Color->new(@c));
                $widget->set_tooltip_text( $item->{desc} ) if exists $item->{desc};

                my $color = sub {
                    my $c   = $widget->get_color;
                    my @rgb = map {int( $c->$_() / 257 )} qw(red green blue);

                    sprintf '#%02x%02x%02x', @rgb;
                };

                if( $item->{convert} ) {
                    $item->{extract} = sub { $item->{convert}->( $color->() ) };

                } else {
                    $item->{extract} = sub { $color->() };
                }

            } elsif( $IT eq "choice" ) {
                $attach = $widget = Gtk2::ComboBox->new_text;
                my $d = $i->{$item->{name}} || $item->{default} || $item->{choices}[0];
                   $d = $item->{trevnoc}->($d) if ref $d and exists $item->{trevnoc};

                my $i = 0;
                my $d_i;
                for(@{$item->{choices}}) {
                    $widget->append_text($_);
                    $d_i = $i if $_ eq $d;
                    $i++;
                }
                $widget->set_active($d_i) if defined $d_i;
                $widget->set_tooltip_text( $item->{desc} ) if exists $item->{desc};

                if( $item->{convert} ) {
                    $item->{extract} = sub { $item->{convert}->( $widget->get_active_text ) };

                } else {
                    $item->{extract} = sub { $widget->get_active_text };
                }

              # $widget->signal_connect(changed => sub { warn "test!"; }); # [WORKS FINE]

                if( exists $item->{descs} and exists $item->{desc} ) {
                    $widget->signal_connect(changed => my $si = sub {
                        if( exists $item->{descs}{ my $at = $widget->get_active_text } ) {
                            $widget->set_tooltip_text( "$at - $item->{descs}{$at}" );

                        } else {
                            $widget->set_tooltip_text( $item->{desc} );
                        }
                    });

                    $si->();
                }

            } elsif( $IT eq "choices" ) {
                my $def = $i->{$item->{name}};
                   $def = $item->{trevnoc}->($def) if ref $def and exists $item->{trevnoc};
                   $def = $item->{defaults} unless $def;
                   $def = {map {($_=>1)} @$def};

                my $d = $item->{choices};
                my @s = grep {$def->{$d->[$_]}} 0 .. $#$d;

                $widget = Gtk2::SimpleList->new( plugin_name_unseen => "text" );
                $widget->set_headers_visible(FALSE);
                $widget->set_data_array($d);
                $widget->get_selection->set_mode('multiple');
                $widget->select( @s );

                # NOTE: $widget->{data} = $d -- doesn't work !!!! fuckers you
                # have to use @{$widget->{data}} = @$d, so I chose to just use
                # the set_data_array() why even bother trying to do the scope
                # hack... pfft.

                $widget->set_has_tooltip(TRUE);
                $widget->signal_connect (query_tooltip => sub {
                    my ($widget, $x, $y, $keyboard_mode, $tooltip) = @_;

                    # First, find out where the pointer is:
                    my $path = $widget->get_path_at_pos($x, $y);

                    # If we're not pointed at a row, then return FALSE to say
                    # "don't show a tip".
                    return FALSE unless $path;

                    # Otherwise, ask the TreeView to set up the tip's area according
                    # to the row's rectangle.
                    $widget->set_tooltip_row($tooltip, $path);

                    $tooltip->set_text($item->{descs}{$d->[($path->get_indices)[0]]});

                    # Return true to say "show the tip".
                    return TRUE;
                });

                $attach = Gtk2::ScrolledWindow->new;

                my $vp  = Gtk2::Viewport->new;
                $attach->set_policy('automatic', 'automatic');
                $attach->add($vp);
                $vp->add($widget);

                $z = (exists $item->{z} ? $item->{z} : 2);

                if( $item->{convert} ) {
                    $item->{extract} = sub { $item->{convert}->( [map {$d->[$_]} $widget->get_selected_indices] ) };

                } else {
                    $item->{extract} = sub { [map {$d->[$_]} $widget->get_selected_indices] };
                }

              # $widget->get_selection->signal_connect(changed => sub { warn "test!"; }); # [WORKS FINE]

            } elsif( $IT eq "bool" ) {
                $attach = $widget = new Gtk2::CheckButton;
                $widget->set_active(exists $i->{$item->{name}} ? $i->{$item->{name}} : $item->{default})
                    if exists $item->{default} or exists $i->{$item->{name}};

                $widget->set_tooltip_text( $item->{desc} ) if exists $item->{desc};
                $item->{extract} = sub { $widget->get_active ? 1:0 };
              # $widget->signal_connect(toggled => sub { warn "test!"; }); # [WORKS FINE]
            }

            else { die "unknown form type: $item->{type}" }

            $reref->{$item->{name}} = [ $item, $widget ];

            $label->set_mnemonic_widget($widget);
            $table->attach_defaults($label,  $x, $x+1, $y, $y+1);  $x ++;
            $table->attach_defaults($attach, $x, $x+1, $y, $y+$z); $y += $z;
        }

        $c_n ++;
    }

    for my $column (@$options) {
        for my $item (@$column) {
            if( my $d = $item->{disable} ) {
                my $this_e = $reref->{$item->{name}};
                my $this_type = $this_e->[0]{type};

                if( $this_type eq "choices" ) {
                    my %disabled; # It appears treviews don't have a row-sensitive function, so we're going to hook
                                  # the changed signal and play some pretend.

                    my @d = @{ $item->{choices} };
                    my $LOOPER = 0;

                    $this_e->[1]->get_selection->signal_connect(changed => my $changed = sub {
                        unless( $LOOPER ) {
                            $LOOPER = 1;
                            my @s = grep {!$disabled{$d[$_]}} $this_e->[1]->get_selected_indices;
                            $this_e->[1]->get_selection->unselect_all;
                            $this_e->[1]->select(@s);
                            $LOOPER = 0;
                        }
                    });

                    for my $row_name (keys %$d) { my $row = $d->{$row_name};
                    for my $k (keys %$row) {
                        my $that_e = $reref->{$k};
                        my $that_type = $that_e->[0]{type};

                        if( $that_type eq "choice" or $that_type eq "text") {
                            $that_e->[1]->signal_connect( changed => my $f = sub {
                                my $sensitive = ($row->{$k}->( $that_e->[0]{extract}->() ) ? FALSE : TRUE);
                                 
                                $disabled{$row_name} = not $sensitive;
                                $changed->();
                            });

                            $f->();

                        } elsif( $that_type eq "choices" ) {
                            $that_e->[1]->get_selection->signal_connect( changed => my $f = sub {
                                my $sensitive = ($row->{$k}->( $that_e->[0]{extract}->() ) ? FALSE : TRUE);
                                 
                                $disabled{$row_name} = not $sensitive;
                                $changed->();
                            });

                            $f->();
                        }
                        
                        else { die "unhandled disabler: $k/$that_type" }
                    }}

                } else {
                    for my $k (keys %$d) {
                        my $that_e = $reref->{$k};
                        my $that_type = $that_e->[0]{type};

                        if( $that_type eq "choice" or $that_type eq "text") {
                            $that_e->[1]->signal_connect( changed => my $f = sub {
                                my $sensitive = ($d->{$k}->( $that_e->[0]{extract}->() ) ? FALSE : TRUE);
                                 
                                $this_e->[1]->set_sensitive($sensitive)
                            });

                            $f->();

                        } elsif( $that_type eq "choices" ) {
                            $that_e->[1]->get_selection->signal_connect( changed => my $f = sub {
                                my $sensitive = ($d->{$k}->( $that_e->[0]{extract}->() ) ? FALSE : TRUE);
                                 
                                $this_e->[1]->set_sensitive($sensitive)
                            });

                            $f->();
                        }
                        
                        else { die "unhandled disabler: $k/$that_type" }
                    }
                }
            }
    }}

    if( ref $extra_buttons ) {
        for my $eba (@$extra_buttons) {
            my $aa = $dialog->action_area;
            my $button = new Gtk2::Button($eba->[0]);
               $button->set_tooltip_text($eba->[2]) if defined $eba->[2];

            $aa->add( $button );
            $aa->set_child_secondary( $button, TRUE );

            if( ref (my $cb = $eba->[1]) eq "CODE" ) {
                $cb->( $button, $reref );
            }
        }
    }

    $dialog->vbox->pack_start($table,0,0,4);
    $dialog->set_response_sensitive( ok => TRUE );
    $dialog->show_all;

    my ($ok_button) = grep {$_->can("get_label") and $_->get_label =~ m/ok/} $dialog->action_area->get_children;

    # This is better than nothing if we can't find the ok button with the grep...
    # It makes it so OK is selected when we tab to the action area.
    # (We're likely to always find the ok button, but for edification purposes,
    #  this is what we'd do if we didn't...)
    # Second thought, let's just set this anyway...
    $dialog->set_default_response('ok');

    if( $ok_button )  {
        # set_default_response() doesn't seem to be enough oomph...
        # It sets the ok button default, but lets the first entry in the Table get the actual focus
        $ok_button->grab_focus;
    }

    my $o = {};
    my $r = $dialog->run;

    if( $r eq "ok" ) {
        for my $c (@$options) {
            for my $e (@$c) {
                if( $reref->{$e->{name}}[1]->is_sensitive() ) {

                    $o->{$e->{name}} = $e->{extract}->();
                }
            }
        }
    }

    ## DEBUG ## warn dump($r, $o);

    $dialog->destroy;
    return ($r,$o);
}
