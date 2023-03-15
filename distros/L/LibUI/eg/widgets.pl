use lib '../lib';
use LibUI;
use LibUI::Menu;
use LibUI::Window;
use LibUI::VBox;
use LibUI::HBox;
use LibUI::Group;
use LibUI::Button;
use LibUI::Checkbox;
use LibUI::Entry;
use LibUI::Label;
use LibUI::HSeparator;
use LibUI::DatePicker;
use LibUI::TimePicker;
use LibUI::DateTimePicker;
use LibUI::FontButton;
use LibUI::ColorButton;
use LibUI::Spinbox;
use LibUI::Slider;
use LibUI::ProgressBar;
use LibUI::Combobox;
use LibUI::EditableCombobox;
use LibUI::RadioButtons;
use LibUI::Tab;
#
LibUI::Init();
my $file = LibUI::Menu->new("File");
#
my $open = $file->appendItem("Open");
my $save = $file->appendItem("Save");
my $quit = $file->appendQuitItem;
#
my $edit      = LibUI::Menu->new("Edit");
my $checkable = $edit->appendCheckItem("Checkable Item");
$edit->appendSeparator;
#
my $disabled = $edit->appendItem("Disabled");
$disabled->disable;
my $preferences = $edit->appendPreferencesItem;
#
my $help      = LibUI::Menu->new("Help");
my $help_item = $help->appendItem("Help");
my $about     = $help->appendAboutItem;
#
my $window = LibUI::Window->new( 'LibUI Control Gallery', 640, 480, 1 );
$window->onClosing(
    sub {
        LibUI::Quit();
        1;
    },
    undef
);
LibUI::onShouldQuit(
    sub {
        return 1;
    },
    undef
);
$window->setMargined(1);
$open->onClicked(
    sub {
        my $filename = $window->openFile();
        if ($filename) {
            $window->msgBox( 'File selected', $filename );
        }
        else {
            $window->msgBoxError( 'No file selected', "Don't be alarmed" );
        }
    },
    undef
);
$save->onClicked(
    sub {
        my $filename = $window->saveFile();
        if ($filename) {
            $window->msgBox( "File selected (don't worry, it's still there)", $filename );
        }
        else {
            $window->msgBoxError( 'No file selected', "Don't be alarmed" );
        }
    },
    undef
);
#
my $box = LibUI::VBox->new;
$box->setPadded(1);
$window->setChild($box);
#
my $hbox = LibUI::HBox->new;
$hbox->setPadded(1);
$box->append( $hbox, 1 );
#
my $group = LibUI::Group->new("Basic Controls");
$group->setMargined(1);
$hbox->append( $group, 0 );
#
my $inner = LibUI::VBox->new;
$inner->setPadded(1);
$group->setChild($inner);
#
$inner->append( LibUI::Button->new("Button"),     0 );
$inner->append( LibUI::Checkbox->new("Checkbox"), 0 );
#
my $entry = LibUI::Entry->new;
$entry->setText("Entry");
$inner->append( $entry,                     0 );
$inner->append( LibUI::Label->new("Label"), 0 );
#
$inner->append( LibUI::HSeparator->new, 0 );
#
$inner->append( LibUI::DatePicker->new,     0 );
$inner->append( LibUI::TimePicker->new,     0 );
$inner->append( LibUI::DateTimePicker->new, 0 );
#
$inner->append( LibUI::FontButton->new, 0 );
#
$inner->append( LibUI::ColorButton->new, 0 );
#
my $inner2 = LibUI::VBox->new;
$inner2->setPadded(1);
$hbox->append( $inner2, 1 );
#
$group = LibUI::Group->new("Numbers");
$group->setMargined(1);
$inner2->append( $group, 0 );
#
$inner = LibUI::VBox->new;
$inner->setPadded(1);
$group->setChild($inner);
#
my $spinbox     = LibUI::Spinbox->new( 0, 100 );
my $slider      = LibUI::Slider->new( 0, 100 );
my $progressbar = LibUI::ProgressBar->new;
#
$spinbox->onChanged(
    sub {
        $slider->setValue( $spinbox->value );
        $progressbar->setValue( $spinbox->value );
    },
    undef
);
$slider->onChanged(
    sub {
        $spinbox->setValue( $slider->value );
        $progressbar->setValue( $slider->value );
    },
    undef
);
#
$inner->append( $spinbox,     0 );
$inner->append( $slider,      0 );
$inner->append( $progressbar, 0 );
#
$group = LibUI::Group->new("Lists");
$group->setMargined(1);
$inner2->append( $group, 0 );
#
$inner = LibUI::VBox->new;
$inner->setPadded(1);
$group->setChild($inner);
#
my $cbox = LibUI::Combobox->new;
$cbox->append("Combobox Item 1");
$cbox->append("Combobox Item 2");
$cbox->append("Combobox Item 3");
$inner->append( $cbox, 0 );
#
my $ecbox = LibUI::EditableCombobox->new;
$ecbox->append("Editable Item 1");
$ecbox->append("Editable Item 2");
$ecbox->append("Editable Item 3");
$inner->append( $ecbox, 0 );
#
my $rb = LibUI::RadioButtons->new;
$rb->append("Radio Button 1");
$rb->append("Radio Button 2");
$rb->append("Radio Button 3");
$inner->append( $rb, 0 );
#
my $tab = LibUI::Tab->new;
$tab->append( "Page 1", LibUI::HBox->new );
$tab->append( "Page 2", LibUI::HBox->new );
$tab->append( "Page 3", LibUI::HBox->new );
$inner2->append( $tab, 1 );
#
$window->show;
LibUI::Main;
