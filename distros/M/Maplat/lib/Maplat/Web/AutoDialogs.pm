# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::AutoDialogs;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::Translator;
use Sys::Hostname;

our $VERSION = 0.995;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
     
    return $self;
}

sub makeForms {
    my ($self) = @_;

    # Generate simple dialogs
    $self->{forms}->{markup} = "";
    $self->{forms}->{js} = "\nvar autodialogs_form = '';var autodialogs_elem = '';";
    $self->{forms}->{jqueryinit} = "";
    
    my %forms = %{$self->{forms}->{fields}};
    foreach my $key (sort keys %forms) {
        $self->addFormsMarkup($key, $forms{$key}->{title},
                         $forms{$key}->{text}, $forms{$key}->{icon},
                         $forms{$key}->{action});
    }

    # Generate Mode-change forms
    %forms = %{$self->{modechangeforms}->{fields}};
    foreach my $key (sort keys %forms) {
        $self->addModeChangeFormsMarkup($key, $forms{$key}->{title},
                         $forms{$key}->{text}, $forms{$key}->{icon},
                         $forms{$key}->{action}, $forms{$key}->{mode});
    }

    return;    
}

sub addFormsMarkup {
    my ($self, $name, $title, $text, $icon, $action) = @_;
    
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    
    $title = tr_translate($dbh, $memh, $self->{lang}, $title);
    $text = tr_translate($dbh, $memh, $self->{lang}, $text);
    $action = tr_translate($dbh, $memh, $self->{lang}, $action);
    my $cancel = tr_translate($dbh, $memh, $self->{lang}, "Cancel");
    
    my $markup = <<"ENDMARKUP";
<!-- AutoDialog markup for $name -->
<div id="dialog-$name" title="$title">
    <p><span class="ui-icon ui-icon-$icon" style="float:left; margin:0 7px 20px 0;"></span>$text</p>
</div>

ENDMARKUP

    my $js = <<"ENDJS";
// AutoDialog wrapper
function $name(formname) {
    if(!formname) {
        alert("No formname given in call to " + $name);
        return false;
    }
    autodialogs_form = formname;
    \$( "#dialog-$name" ).dialog("open");
    return false;
}

ENDJS

    my $jquery = <<"ENDJQUERY";
// AutoDialog initializer    
\$( "#dialog-$name" ).dialog({
        autoOpen: false,
        resizable: false,
        modal: true,
        width: 400,
        height: 600,
        buttons: {
            "$action": function() {
                \$( this ).dialog( "close" );
                document.forms[autodialogs_form].submit();
            },
            "$cancel": function() {
                autodialogs_form = "";
                \$( this ).dialog( "close" );
            }
        }
    });

ENDJQUERY

    $self->{forms}->{markup} .= $markup;
    $self->{forms}->{js} .= $js;
    $self->{forms}->{jqueryinit} .= $jquery;
    
    return;
}

sub addModeChangeFormsMarkup {
    my ($self, $name, $title, $text, $icon, $action, $mode) = @_;
    
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    
    $title = tr_translate($dbh, $memh, $self->{lang}, $title);
    $text = tr_translate($dbh, $memh, $self->{lang}, $text);
    $action = tr_translate($dbh, $memh, $self->{lang}, $action);
    my $cancel = tr_translate($dbh, $memh, $self->{lang}, "Cancel");
    
    my $markup = <<"ENDMCMARKUP";
<!-- AutoDialog modechange markup for $name -->
<div id="dialog-$name" title="$title">
    <p><span class="ui-icon ui-icon-$icon" style="float:left; margin:0 7px 20px 0;"></span>$text</p>
</div>

ENDMCMARKUP

    my $js = <<"ENDMCJS";
// AutoDialog modechange wrapper
function $name(formname, elemid) {
    if(!formname) {
        alert("No formname given in call to " + $name);
        return false;
    }
    if(!elemid) {
        alert("No elemid given in call to " + $name);
        return false;
    }
    autodialogs_form = formname;
    autodialogs_elem = elemid;
    \$( "#dialog-$name" ).dialog("open");
    return false;
}

ENDMCJS

    my $jquery = <<"ENDMCJQUERY";
// AutoDialog initializer    
\$( "#dialog-$name" ).dialog({
        autoOpen: false,
        resizable: false,
        modal: true,
        width: 400,
        height: 600,
        buttons: {
            "$action": function() {
                \$( this ).dialog( "close" );
                var modeElem = document.getElementById(autodialogs_elem);
                modeElem.value = "$mode";
                document.forms[autodialogs_form].submit();
            },
            "$cancel": function() {
                autodialogs_form = "";
                autodialogs_elem = "";
                \$( this ).dialog( "close" );
            }
        }
    });

ENDMCJQUERY

    $self->{forms}->{markup} .= $markup;
    $self->{forms}->{js} .= $js;
    $self->{forms}->{jqueryinit} .= $jquery;
    
    return;
}


sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    $self->register_prerender("get_prerender");
    return;
}

sub get_prerender {
    my ($self, $webdata) = @_;
    
    $self->{lang} = $webdata->{UserLanguage} || "eng";
    $self->makeForms();
    
    $webdata->{AutoForms}->{Markup} = $self->{forms}->{markup};
    $webdata->{AutoForms}->{JS} = $self->{forms}->{js};
    $webdata->{AutoForms}->{JQueryInit} = $self->{forms}->{jqueryinit};
    
    return;
}

1;
__END__

=head1 NAME

Maplat::Web::AutoDialogs - Auto-generate jquery dialogs

=head1 SYNOPSIS

This module provides pre-calculated jquery dialogs

=head1 DESCRIPTION

With this module, you can easely create jquery dialogs

=head1 Configuration

    <module>
        <modname>autodialogs</modname>
        <pm>AutoDialogs</pm>
        <options>
            <forms>
                <fields>
                    <confirmDeleteUser>
                        <title>Delete User</title>
                        <text>Do you really want to delete this user?</text>
                        <icon>alert</icon>
                        <action>Delete</action>
                    </confirmDeleteUser>
                    <confirmChangeUser>
                        <title>Change User</title>
                        <text>Do you really want to change this users settings?</text>
                        <icon>help</icon>
                        <action>Change</action>
                    </confirmChangeUser>
                </fields>
            </forms>
            <modechangeforms>
                <fields>
                    <confirmDeleteFilter>
                        <title>Delete Filter</title>
                        <text>Do you really want to delete this filter?</text>
                        <icon>help</icon>
                        <action>Delete</action>
                        <mode>deletefilter</mode>
                    </confirmDeleteFilter>
                    <confirmDeleteUnmapped>
                        <title>Delete Signals</title>
                        <text>DELETING THIS SIGNALS CAN NOT BE UNDONE! Are you sure you really, really, REALLY want to permanently delete this signals?</text>
                        <icon>alert</icon>
                        <action>I know what i'm doing!</action>
                        <mode>deleteunmapped</mode>
                    </confirmDeleteUnmapped>
                </fields>
            </modechangeforms>
        </options>
    </module>

=head2 get_prerender

Add the forms to webdata

=head2 addFormsMarkup

Internal function, create markup and javascript for simple OK/Cancel jquery dialogs

=head2 addModeChangeFormsMarkup

Internal function, create markup and javascript dialogs for modechange forms

=head2 makeForms

Internal function, wrapper for the above generation functions

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
