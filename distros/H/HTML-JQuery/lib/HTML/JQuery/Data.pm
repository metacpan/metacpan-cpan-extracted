package HTML::JQuery::Data;

$HTML::JQuery::Data::JQuery = [];
$HTML::JQuery::Data::Inline = [];
$HTML::JQuery::Data::Keystrokes = 0;
my $CLASS = __PACKAGE__;

sub jquery_add {
    my ($class, $add) = @_;
    if ($HTML::JQuery::Inline == 1) { push @{$HTML::JQuery::Data::Inline}, "$add\n"; }
    else { push @{$HTML::JQuery::Data::JQuery}, "$add\n"; }
}

sub jquery_onclick {
    my ($self, $name) = @_;
    return "\$('$name').click(function() {";
}

sub jquery_end {
    return "});";
}

sub jquery_fade {
    my $self = shift;
    my $type = shift;
    my ($sel, $duration, $after) = @_;

    $sel = "\$('$sel')";
    $sel = '$(this)'  
        if $sel eq "\$('this')";
    $duration = $duration ? $duration : 'undefined';
    $after = $after ? $after : 'undefined';
    $CLASS->jquery_add( "$sel.fade$type($duration, function() { $after });");
}

sub jquery_slidetoggle {
    my $self = shift;
    my ($sel, $duration, $after) = @_;
    $sel = "\$('$sel')";
    $sel = '$(this)'  
        if $sel eq "\$('this')";
    $duration = $duration ? "\"$duration\"" : 'undefined';
    $after = $after ? $after : 'undefined';
    $CLASS->jquery_add( "$sel.slideToggle($duration, function() { $after });");
}

sub jquery_keystrokes {
    my $self = shift;
    my ($sel, $args) = @_;

    if (! exists $args->{keys}) {
        $CLASS->js_alert("Please don't forget to include 'keys' in keystrokes.");
        return ;
    }
    $HTML::JQuery::Data::Keystrokes++;
    #my $keys = join q{, }, $args->{keys};
    my $keys;
    map { $keys .= qq{'$_',} } @{$args->{keys}};
    my $bind = "\$('$sel').bind('keystrokes.$HTML::JQuery::Data::Keystrokes', {\n";
    $bind   .= "keys : [ $keys ] },\n";
    $bind   .= "function(event) { $args->{event} } );";
    $CLASS->jquery_add($bind);
}

sub jquery_datepicker {
    my ($self, $sel, $args) = @_;
    my $p = "";
    foreach my $key (keys %$args) {
        next if $key eq 'auto';
        $args->{$key} = 'false'
            if $args->{$key} == 0;
        $args->{$key} = 'true'
            if $args->{$key} == 1;
        $p .= "$key : $args->{$key},\n";
    }
    if ($args->{auto}) { $CLASS->jquery_add( "\$('$sel').datepicker({dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true, $p});\n" ); }
    else { $CLASS->jquery_add( "\$('$sel').datepicker({ $p });\n" ); }
}

sub jquery_dialog {
    my $self = shift;
    my $sel = shift;
    my $args = shift;
    my $p = "";
    my $selector = $sel;
    foreach my $key (keys %$args) {
        unless ($key eq 'id' or $key eq 'body' or $key eq 'buttons' or $key eq 'modal' or $key eq 'autoOpen' or $key eq 'open' or $key eq 'close') {
            if ($args->{$key} eq 'true' or $args->{$key} eq 'false') {
                $p .= "$key : $args->{$key},\n";
            }
            else { $p .= "$key : '$args->{$key}',\n"; }
        }
        if ($key eq 'open') {
                $CLASS->jquery_add( "\$('$sel').dialog('open');");
                return;
        }
        if ($key eq 'close') {
                $CLASS->jquery_add( "\$('$sel').dialog('close');");
                return;
        }
        if ($key eq 'buttons') {
            $p .= "buttons : {\n";
            foreach my $button (keys %{$args->{buttons}}) {
                $p .= "$button : function() { $args->{buttons}->{$button} },\n"
            }
            $p .= "},\n";
        }
        if ($key eq 'modal') {
            if ($args->{$key} == 0) { $p .= "modal : false,\n"; }
            else { $p .= "modal : true,\n"; }
        }
        if ($key eq 'autoOpen') {
            if ($args->{$key} == 0) { $p .= "autoOpen : false,\n"; }
            else { $p .= "autoOpen : true,\n"; }
        }
        if ($key eq 'body') {
            my $title = $args->{title};
            my $body = $args->{body};
            $body =~ s/"/\\"/g;
            $body =~ s/\n//g;
            if (substr($sel, 0, 1) eq '.') { $sel = 'class="' . substr($sel, 1) . '"'; }
            elsif (substr($sel, 0, 1) eq '#') { $sel = 'id="' . substr($sel, 1) . '"'; }
            my $build_dialog = qq{
                var div = '<div $sel title="$title" style="display:none">$body</div>';
                \$(div).appendTo("body");
            };
            $CLASS->jquery_add($build_dialog);
        }
    }
    $CLASS->jquery_add("\$('$selector').dialog({$p});");
}

sub js_alert {
    my ($self, $message) = @_;
    $CLASS->jquery_add( "alert(\"$message\");");
}

sub js_callfunc {
    my ($self, $func) = @_;
    #$CLASS->jquery_add( "if (typeof $func == 'function') { $func(); }" );
    $CLASS->jquery_add( "$func();" );
}

sub jquery_rel {
    my ($self, $rel) = @_;

    $rel = "\$('$rel')";
    $rel = '$(this)'  
        if $rel eq "\$('this')";
    $CLASS->jquery_add( "$rel.attr('rel');\n" );
}

sub jquery_hide {
    my $self = shift;
    my ($sel, $duration, $after) = @_;
    $sel = "\$('$sel')";
    $sel = '$(this)'  
        if $sel eq "\$('this')";
    $duration = $duration ? "\"$duration\"" : 'undefined';
    $after = $after ? $after : 'undefined';
    $CLASS->jquery_add( "$sel.hide($duration, function() { $after });");
}

sub jquery_show {
    my $self = shift;
    my ($sel, $duration, $after) = @_;
    $sel = "\$('$sel')";
    $sel = '$(this)'  
        if $sel eq "\$('this')";
    $duration = $duration ? "\"$duration\"" : 'undefined';
    $after = $after ? $after : 'undefined';
    $CLASS->jquery_add( "$sel.show($duration, function() { $after });");
}

sub jquery_remove {
    my ($self, $sel) = @_;
    $sel = "\$('$sel')";
    $sel = '$(this)'  
        if $sel eq "\$('this')";
    $CLASS->jquery_add( "$sel.remove();" );
}

sub jquery_innerhtml {
    my ($self, $sel, $text) = @_;
    #my $append;
    #$append = 1 if substr($text, 0, 1) eq '+';
    #
    #if ($append) {
    #    $CLASS->jquery_add( "$sel.innerHtml
    $text =~ s/"/\\"/g;
    $text =~ s/\n//g;
    $CLASS->jquery_add( "\$('$sel').append(\"$text\");" );
}

1;
