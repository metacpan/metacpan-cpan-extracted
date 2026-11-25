package Developer::Dashboard::System::Menu;

use strict;
use warnings;

use Exporter 'import';
use Encode ();
use JSON::XS ();
use Developer::Dashboard::Version ();

our $VERSION = '6.31';
our @EXPORT  = qw(menu);

require Developer::Dashboard::HtmlEscape;
die "Developer::Dashboard XS bundle lacks System::Menu support\n"
    unless $Developer::Dashboard::HtmlEscape::XS_LOADED
        && __PACKAGE__->can('_start');

my $DEFAULT;
my $NEXT_ID = 1;
my %RUNTIME;

sub menu {
    if (!$DEFAULT) {
        my $id = join('-', $$, $NEXT_ID++);
        $DEFAULT = bless { id => $id }, __PACKAGE__;
    }
    return $DEFAULT;
}

sub _id {
    my ($self) = @_;
    die "invalid System::Menu object\n"
        unless ref($self) && defined($self->{id}) && length("$self->{id}");
    return "$self->{id}";
}

sub _runtime {
    my ($self) = @_;
    return $RUNTIME{ $self->_id };
}

sub _text {
    my ($value, $what) = @_;
    die "$what must be a plain scalar\n" if !defined($value) || ref($value);

    my $text = "$value";
    return $text if utf8::is_utf8($text) || $text !~ /[\x80-\xFF]/;

    my $decoded = eval {
        Encode::decode('UTF-8', $text, Encode::FB_CROAK());
    };
    return $decoded if !$@;
    return $text;
}

sub _json_command {
    my ($payload) = @_;
    my $json = JSON::XS->new->canonical->utf8->encode($payload);
    _command_json($json);
    return 1;
}

sub run {
    my ($self, $settings) = @_;
    die "run() requires an arrayref\n" unless ref($settings) eq 'ARRAY';

    my $id = $self->_id;
    die "run() is already active for this menu\n"
        if $RUNTIME{$id} && $RUNTIME{$id}{active};

    my %seen;
    my %items;
    my @roots;
    my @wire;

    for my $spec (@$settings) {
        my ($item, $native) = $self->_build_item(
            $spec, undef, \%seen, \%items, 0
        );
        push @roots, $item;
        push @wire,  $native;
    }

    my $rt = $RUNTIME{$id} = {
        active       => 1,
        root         => $self,
        items        => \%items,
        roots        => \@roots,
        event_buffer => '',
    };

    my $ok = eval {
        _start();
        _json_command({ op => 'run', items => \@wire });

        while ($rt->{active} && _running()) {
            _dispatch_events($self, $rt);
            select undef, undef, undef, 0.02;
        }

        _dispatch_events($self, $rt) if _running();
        1;
    };
    my $error = $@;

    $rt->{active} = 0;
    $_->{removed} = 1 for values %{ $rt->{items} };
    delete $RUNTIME{$id};

    if (!$ok) {
        eval { _stop() if _running() };
        die $error;
    }

    return $self;
}

sub _click_stay {
    my ($value, $what) = @_;
    die "$what must be 0 or 1\n"
        if !defined($value) || ref($value) || "$value" !~ /\A[01]\z/;
    return $value ? 1 : 0;
}

sub _menu_spec {
    my ($menu, $what) = @_;

    if (ref($menu) eq 'ARRAY') {
        return (0, $menu);
    }

    die "$what must be an arrayref or hashref\n" unless ref($menu) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(click_stay items);
    for my $key (keys %$menu) {
        die "$what: unknown option '$key'\n" unless $allowed{$key};
    }

    die "$what requires items => [...]\n"
        unless exists($menu->{items}) && ref($menu->{items}) eq 'ARRAY';

    my $default = exists($menu->{click_stay})
        ? _click_stay($menu->{click_stay}, "$what click_stay")
        : 0;

    return ($default, $menu->{items});
}

sub _build_item {
    my ($self, $spec, $parent, $seen, $items, $default_click_stay) = @_;

    die "each menu setting must be a hashref\n" unless ref($spec) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(name icon click menu click_stay);
    for my $key (keys %$spec) {
        die "unknown menu setting '$key'\n" unless $allowed{$key};
    }

    die "menu setting requires name\n" unless exists $spec->{name};
    die "menu setting requires icon\n" unless exists $spec->{icon};

    my $name = _text($spec->{name}, 'name');
    my $icon = _text($spec->{icon}, "menu setting '$name' icon");
    die "menu setting requires non-empty name\n" unless length $name;
    die "duplicate menu name '$name'\n" if $seen->{$name}++;

    if (exists($spec->{menu}) && exists($spec->{click})) {
        die "menu setting '$name' cannot have both menu and click\n";
    }

    if (exists($spec->{menu})
        && ref($spec->{menu}) ne 'ARRAY'
        && ref($spec->{menu}) ne 'HASH') {
        die "menu setting '$name' menu must be an arrayref or hashref\n";
    }

    my $click_stay = exists($spec->{click_stay})
        ? _click_stay($spec->{click_stay}, "menu setting '$name' click_stay")
        : ($default_click_stay ? 1 : 0);

    if (exists($spec->{click})
        && ref($spec->{click})
        && ref($spec->{click}) ne 'CODE') {
        die "menu setting '$name' click must be a subref or plain scalar text\n";
    }

    my $click = exists($spec->{click}) && !ref($spec->{click})
        ? _text($spec->{click}, "menu setting '$name' click")
        : $spec->{click};

    my $item = bless {
        root       => $self,
        parent     => $parent,
        name       => $name,
        icon       => $icon,
        click      => $click,
        click_stay => $click_stay,
        children   => [],
        removed    => 0,
    }, 'Developer::Dashboard::System::Menu::Item';

    $items->{$name} = $item;

    my %native = (
        name       => $name,
        icon       => $icon,
        click_stay => $click_stay ? JSON::XS::true : JSON::XS::false,
    );

    if (exists $spec->{click}) {
        $native{click} = ref($spec->{click}) eq 'CODE'
            ? 'callback'
            : 'text';
    }

    if (exists $spec->{menu}) {
        my ($menu_click_stay, $menu_items) = _menu_spec(
            $spec->{menu},
            "menu setting '$name' menu"
        );

        my @children;
        my @native_children;

        for my $child_spec (@$menu_items) {
            my ($child, $child_wire) = $self->_build_item(
                $child_spec,
                $item,
                $seen,
                $items,
                $menu_click_stay,
            );
            push @children,        $child;
            push @native_children, $child_wire;
        }

        $item->{children} = \@children;
        $native{menu} = \@native_children;
    }

    return ($item, \%native);
}

sub remove {
    my ($self, $name) = @_;
    $name = _text($name, 'remove() name');
    die "remove() requires a non-empty name\n" unless length $name;

    if (my $rt = $self->_runtime) {
        if (my $item = $rt->{items}{$name}) {
            _forget_item($rt, $item);
        }
    }

    _json_command({ op => 'remove', name => $name }) if _running();
    return $self;
}

sub _forget_item {
    my ($rt, $item) = @_;

    _forget_item($rt, $_) for @{ $item->{children} || [] };
    delete $rt->{items}{ $item->{name} };
    $item->{removed} = 1;

    if (my $parent = $item->{parent}) {
        @{ $parent->{children} } = grep { $_ != $item } @{ $parent->{children} };
    }
    else {
        @{ $rt->{roots} } = grep { $_ != $item } @{ $rt->{roots} };
    }

    return;
}

sub stop {
    my ($self) = @_;

    if (my $rt = $self->_runtime) {
        $rt->{active} = 0;
    }

    _stop() if _running();
    return $self;
}

sub _set_icon {
    my ($self, $item, $icon) = @_;
    die "cannot update removed menu item '$item->{name}'\n" if $item->{removed};

    $icon = _text($icon, 'icon');
    $item->{icon} = $icon;

    _json_command({
        op   => 'icon',
        name => $item->{name},
        icon => $icon,
    });

    return $item;
}

sub _dispatch_events {
    my ($self, $rt) = @_;
    return unless $rt && $rt->{active};

    my $chunk = _read_events();
    return if !defined($chunk) || $chunk eq '';

    $rt->{event_buffer} .= $chunk;

    while ($rt->{event_buffer} =~ s/\A([^\n]*)\n//) {
        my $line = $1;
        $line =~ s/\r\z//;
        next unless length $line;

        my $event = eval { JSON::XS->new->utf8->decode($line) };
        if (!$event || ref($event) ne 'HASH') {
            warn "Developer::Dashboard::System::Menu: invalid helper event\n";
            next;
        }

        next unless ($event->{event} // '') eq 'click';
        my $name = $event->{name};
        next unless defined $name;

        my $item = $rt->{items}{$name};
        next unless $item && !$item->{removed};

        my $click = $item->{click};
        next unless defined $click;

        if (ref($click) eq 'CODE') {
            my $ok = eval { $click->($item); 1 };
            warn "Developer::Dashboard::System::Menu: click '$name' failed: $@"
                unless $ok;
        }
        else {
            my $ok = eval { $item->icon($click); 1 };
            warn "Developer::Dashboard::System::Menu: click '$name' update failed: $@"
                unless $ok;
        }

        last unless $rt->{active};
    }

    return 1;
}

# Purpose: stop the native helper when Perl exits with a menu runtime still active.
# Input: none; reads the module's active runtime registry and native helper state.
# Output: true when active-runtime cleanup was attempted, otherwise false.
sub _shutdown_active_helpers {
    return 0 if !grep { $_->{active} } values %RUNTIME;

    my $ok = eval {
        _stop() if _running();
        1;
    };
    warn "Developer::Dashboard::System::Menu: shutdown cleanup failed: $@"
        if !$ok;
    return 1;
}

END {
    _shutdown_active_helpers();
}

package Developer::Dashboard::System::Menu::Item;

use strict;
use warnings;

sub name { return $_[0]{name} }

sub icon {
    my ($self, @args) = @_;
    return $self->{icon} unless @args;
    die "icon() takes exactly one value\n" unless @args == 1;
    return $self->{root}->_set_icon($self, $args[0]);
}

sub menu { return $_[0]{root} }

sub remove {
    my ($self) = @_;
    $self->{root}->remove($self->{name});
    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Developer::Dashboard::System::Menu - native system-menu adapter

=head1 PURPOSE

Provides the Perl-facing API for creating and controlling a native operating
system menu through the Developer Dashboard XS bundle and its platform helper.

=head1 WHY IT EXISTS

Dashboard indicators need a persistent native menu on supported desktop
platforms. This module validates menu definitions, projects callbacks and
icons into a platform-neutral JSON protocol, dispatches native click events
back to Perl, and owns the menu run-loop lifecycle without introducing a
second extension or an external Perl package dependency.

=head1 WHEN TO USE

Use this module when an application already has a graphical desktop session
and needs a native system-menu surface. It is not a browser widget and does not
provide a useful visible interface in a headless process. Higher-level
Dashboard code should normally use the C<Developer::Dashboard::SystemMenu>
adapter and its runner rather than constructing this low-level menu directly.

=head1 HOW TO USE

Load the module after the Dashboard XS bundle is built. Call C<menu> to obtain
the process-local menu object, then call C<run> with an array reference of menu
item definitions. Each item is a hash reference with required C<name> and
C<icon> scalar values and optional C<click>, C<click_stay>, or nested C<menu>
items. A nested C<menu> may be an array reference or a hash reference with
C<items> and an optional default C<click_stay> value. Names must be unique in
the complete menu tree. A menu entry cannot define both C<menu> and C<click>.

C<run> owns the native event loop until C<stop> is requested or the helper
terminates. A C<click> code reference is called with its item object. A plain
scalar C<click> value is treated as the replacement icon name on activation.
Callback errors are reported as Perl warnings and do not silently disappear.
Item C<icon> reads the current icon with no arguments and updates it with one
scalar argument. C<remove> deletes a named item, and item C<remove> removes
that item by name. Invalid settings, duplicate names, helper failures, and
invalid item operations raise explicit errors.

=head1 WHAT USES IT

C<Developer::Dashboard::SystemMenu> builds menu data from configured
indicators. C<Developer::Dashboard::SystemMenu::Runner> starts this menu in a
controlled GoRoutine worker and requests shutdown when the Dashboard runtime
stops. The XSUBs are registered in the existing Dashboard XS bundle.

=head1 EXAMPLES

Create a basic menu with a callback and a nested entry:

    use Developer::Dashboard::System::Menu;

    my $menu = menu();
    $menu->run([
        {
            name  => 'build',
            icon  => '✅',
            click => sub {
                my ($item) = @_;
                $item->icon('⏳');
            },
        },
        {
            name => 'project',
            icon => '📁',
            menu => [
                { name => 'tests', icon => '🧪', click => '🔄' },
            ],
        },
    ]);

Request shutdown from another active control path while C<run> is blocked:

    my $menu = menu();
    # The menu has already entered run() on its owning control path.
    # A shutdown callback or supervisor then calls:
    $menu->stop();
    $menu->remove('sync');

Read or change an item icon from a callback:

    my $current_icon = $item->icon();
    $item->icon('✅');

=head1 INPUTS AND OUTPUTS

C<menu> takes no arguments and returns the process-local menu object.
C<run> takes an array reference of menu definitions and returns the menu
object after its run loop exits. C<remove> takes a non-empty item name and
returns the menu object. C<stop> takes no arguments and returns the menu
object. Item C<name>, C<menu>, C<remove>, and C<icon> methods return the item
name, root menu object, item object, and current or updated icon respectively.
Mutating methods report invalid input or native transport failures by dying.

=cut
