#!/usr/bin/perl
# vim: set filetype=perl expandtab softtabstop=4 shiftwidth=4 :

use strict;
use warnings;
use Gtk2::TestHelper
  tests => 92,
  at_least_version => [2, 12, 0, 'GtkBuildable appeared in 2.12'];

my $builder = Gtk2::Builder->new ();

my $ui = <<EOD;
<interface>
    <object class="TestThing" id="thing1">
        <property name="a">7</property>
        <property name="b">ftang</property>
        <property name="c">left</property>
        <signal name="changed" handler="on_thing1_changed" />
    </object>

    <object class="TestThingView" id="view1">
        <property name="visible">FALSE</property>
        <property name="thing">thing1</property>
        <property name="color-string">purple</property>
    </object>

    <object class="TestComplexThing" id="fancy-thing">
        <option name="x">10</option>
        <option name="y" selected="TRUE">15</option>
        <option name="z">20</option>
    </object>

    <object class="TestComplexWidget" id="fancy-widget">
        <property name="shadow-type">in</property>
        <child type="label">
            <object class="GtkCheckButton" id="check-label">
                <property name="label">Woohoo</property>
            </object>
        </child>
        <child>
            <object class="GtkLabel" id="content-label">
                <property name="label">&lt;b&gt;Bold text&lt;/b&gt;</property>
                <property name="use-markup">TRUE</property>
            </object>
        </child>
    </object>
</interface>
EOD

$builder->add_from_string ($ui);
$builder->connect_signals ();


my $thing1 = $builder->get_object ('thing1');
isa_ok ($thing1, 'TestThing');
is ($thing1->get_name(), 'thing1');
is ($thing1->get ('a'), 7);
is ($thing1->get ('b'), 'ftang');
is ($thing1->get ('c'), 'left');
$thing1->changed ();

sub on_thing1_changed {
    my $thing = shift;
    ok (1, "on_thing1_changed connected correctly");
    isa_ok ($thing, 'TestThing');
}


my $view1 = $builder->get_object ('view1');
isa_ok ($view1, 'TestThingView');
# TestThingView doesn't directly implement Gtk2::Buildable, thus it's not first
# in the @ISA chain.  So get_name() alone actually resolves to
# Gtk2::Widget::get_name(), which breaks things as of gtk+ commit
# 46f5ee1d0c0f4601853ed57e99b1b513f1baa445.  So fully qualify the method.
is ($view1->Gtk2::Buildable::get_name (), 'view1');
ok (! $view1->get ('visible'));
is ($view1->get ('thing'), $thing1);
is ($view1->get ('color-string'), 'purple');


my $fancything = $builder->get_object ('fancy-thing');
isa_ok ($fancything, 'TestComplexThing');
is ($fancything->get_name (), 'fancy-thing');
use Data::Dumper;
print Dumper($fancything);
is ($fancything->{options}{x}, 10);
is ($fancything->{options}{y}, 15);
is ($fancything->{options}{z}, 20);
is ($fancything->{selected}, 'y');


my $fancywidget = $builder->get_object ('fancy-widget');
isa_ok ($fancywidget, 'TestComplexWidget');
is ($fancywidget->get_name (), 'fancy-widget');

package TestThing;

use strict;
use warnings;
use Gtk2;
use Test::More;
use Glib ':constants';

BEGIN {
Glib::Type->register_enum ('TestThing::Stuff', qw( left right top bottom ));
}

use Glib::Object::Subclass
    Glib::Object::,
    signals => {
        changed => {},
    },
    properties => [
        Glib::ParamSpec->int ('a', 'A', 'A', 1, 10, 5, G_PARAM_READWRITE),
        Glib::ParamSpec->string ('b', 'B', 'B', "whee", G_PARAM_READWRITE),
        Glib::ParamSpec->enum ('c', 'C', 'C', 'TestThing::Stuff', 'top',
                               G_PARAM_READWRITE),
    ],
    interfaces => [
    	Gtk2::Buildable::,
    ],
    ;

sub changed {
    my $self = shift;
    $self->signal_emit ('changed');
}

package TestThingView;

use strict;
use warnings;
use Gtk2;
use Test::More;
use Glib ':constants';

use Glib::Object::Subclass
    Gtk2::Table::,
    signals => {
    },
    properties => [
        Glib::ParamSpec->object ('thing', 'Thing', 'The Thing',
                                 TestThing::, G_PARAM_READWRITE),
        Glib::ParamSpec->string ('color-string', 'Color String', 'duh',
                                 "red", G_PARAM_READWRITE),
    ],
    # NOTE: we DON't implement Buildable here, we inherit it from Gtk2::Widget
    ;

package TestComplexThing;

use strict;
use warnings;
use Gtk2;
use Test::More;
use Glib ':constants';

use Glib::Object::Subclass
    Glib::Object::,
    signals => {
    },
    properties => [
    ],
    # Here we'll override some of the interface methods directly
    interfaces => [
    	Gtk2::Buildable::,
    ],
    ;

sub SET_NAME {
    my ($self, $name) = @_;
    $self->{name} = $name;
}

sub GET_NAME {
    my $self = shift;
    return $self->{name};
}

sub ADD_CHILD {
    my ($self, $builder, $child, $type) = @_;
    print "ADD_CHILD $child\n";
}

sub SET_BUILDABLE_PROPERTY {
    print "SET_BUILDABLE_PROPERTY\n";
}

{
    package TestComplexThing::OptionParser;

    use strict;
    use warnings;

    sub new {
        my $class = shift;
        return bless { @_ }, $class;
    }

    sub START_ELEMENT {
        my ($self, $context, $tagname, $attributes) = @_;

        print "START_ELEMENT $tagname name=\"$attributes->{name}\"\n";
        print "  ".$context->get_element."\n";
        print "  ".join(":", $context->get_position)."\n";
        print "  ".join("/", reverse $context->get_element_stack)."\n"
            if $context->can ('get_element_stack');

        $self->{tagname} = $tagname;
        $self->{attributes} = $attributes;
    }

    sub TEXT {
        my ($self, $context, $text) = @_;

        print "TEXT ".$self->{tagname}."\n";

        $self->{text} = '' if not defined $self->{text};
        $self->{text} .= $text;
    }

    sub END_ELEMENT {
        print "END_ELEMENT ".$_[0]{tagname}."\n";
    }

    sub DESTROY {
        print "DESTROY ".$_[0]{tagname}."\n";
    }
}

sub CUSTOM_TAG_START {
    my ($self, $builder, $child, $tagname) = @_;

    print "CUSTOM_TAG_START $tagname\n";

    isa_ok ($self, TestComplexThing::);
    isa_ok ($self, Gtk2::Buildable::);
    isa_ok ($self, Glib::Object::);

    isa_ok ($builder, Gtk2::Builder::);

    ok (not defined $child);

    is ($tagname, 'option');

    return TestComplexThing::OptionParser->new ();
}

sub CUSTOM_TAG_END {
    my ($self, $builder, $child, $tagname, $parser) = @_;

    print "CUSTOM_TAG_END $tagname\n";

    isa_ok ($self, TestComplexThing::);
    isa_ok ($builder, Gtk2::Builder::);
    ok (not defined $child);
    is ($tagname, 'option');
    isa_ok ($parser, TestComplexThing::OptionParser::);

    $self->{options}{$parser->{attributes}{name}} = $parser->{text};
    $self->{selected} = $parser->{attributes}{name}
        if $parser->{attributes}{selected};
}

sub CUSTOM_FINISHED {
    my ($self, $builder, $child, $tagname, $parser) = @_;

    print "CUSTOM_FINISHED $tagname\n";

    isa_ok ($self, TestComplexThing::);
    isa_ok ($builder, Gtk2::Builder::);
    ok (not defined $child);
    is ($tagname, 'option');
    isa_ok ($parser, TestComplexThing::OptionParser::);
}

sub PARSER_FINISHED {
    my ($self, $builder) = @_;

    print "PARSER_FINISHED\n";
}

sub GET_INTERNAL_CHILD {
    my ($self, $builder, $childname) = @_;

    print "GET_INTERNAL_CHILD $childname\n";

    return undef;
}


package TestComplexWidget;

use strict;
use warnings;
use Gtk2;
use Test::More;
use Glib ':constants';

use Glib::Object::Subclass
    Gtk2::Frame::,
    signals => {
    },
    properties => [
    ],
    # Here we'll override some of the interface methods directly
    interfaces => [
    	Gtk2::Buildable::,
    ],
    ;

sub SET_NAME {
    my ($self, $name) = @_;

    isa_ok ($self, TestComplexWidget::);
    isa_ok ($self, Gtk2::Buildable::);
    isa_ok ($self, Gtk2::Frame::);

    $self->{name} = $name;
}

sub GET_NAME {
    my $self = shift;

    isa_ok ($self, TestComplexWidget::);
    isa_ok ($self, Gtk2::Buildable::);
    isa_ok ($self, Gtk2::Frame::);

    return $self->{name};
}

sub ADD_CHILD {
    my ($self, $builder, $child, $type) = @_;

    isa_ok ($self, TestComplexWidget::);
    isa_ok ($self, Gtk2::Buildable::);
    isa_ok ($self, Gtk2::Frame::);

    isa_ok ($builder, Gtk2::Builder::);

    isa_ok ($child, Gtk2::Widget::);

    if (defined ($type)) {
        if ($type eq 'label') {
            $self->set_label_widget ($child);
        } else {
            ok (0, "Unknown internal child type");
        }
    } else {
        $self->add ($child);
    }
}

sub SET_BUILDABLE_PROPERTY {
    my ($self, $builder, $name, $value) = @_;

    isa_ok ($self, TestComplexWidget::);
    isa_ok ($self, Gtk2::Buildable::);
    isa_ok ($self, Gtk2::Frame::);

    isa_ok ($builder, Gtk2::Builder::);

    ok (defined $name);

    $self->set ($name, $value);
}

# --------------------------------------------------------------------------- #
# GET_INTERNAL_CHILD() returning undef for no such internal child
{
  my $get_internal_child = 0;
  {
    package MyWidget;
    use Glib::Object::Subclass 'Gtk2::Widget',
      interfaces => [ 'Gtk2::Buildable' ];
    sub GET_INTERNAL_CHILD {
      $get_internal_child = 1;
      return undef;
    }
  }

  my $builder = Gtk2::Builder->new;
  eval {
    $builder->add_from_string (<<'HERE');
<interface>
  <object class="MyWidget" id="mywidget">
    <child internal-child="foo">
      <object class="GObject" id="in-foo"/>
    </child>
  <object>
</interface>
HERE
  };
  my $err = $@;
  is ($get_internal_child, 1,
      'GET_INTERNAL_CHILD returning undef - iface func called');
  isnt ($@, '',
	'GET_INTERNAL_CHILD returning undef - builder throws an error');
  isa_ok ($err, 'Glib::Error',
	  'GET_INTERNAL_CHILD returning undef - builder error is a GError');
}
