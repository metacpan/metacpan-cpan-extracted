use strict;
use warnings;
use Fl qw[:color :default :event];
$|++;

# Demo of Drag+Drop (DND) from red sender to green receiver
{

    package Sender;
    use SUPER;
    use Fl qw[:color :default :event :box];
    extends 'Fl::Box';

    sub new {
        my $s = super;
        $s->box(FL_FLAT_BOX);
        $s->color(9);
        $s->label("Drag\nfrom\nhere...");
        return $s;
    }

    # Sender event handler
    sub handle {
        my ($s, $event) = @_;

        #printf STDERR "Event a: %d\n", $event;
        if ($event == FL_PUSH) {

            # do 'copy/dnd' when someone clicks on box
            Fl::copy("message", 0);
            Fl::dnd();
            return 1;
        }
    }
}
{

    package Receiver;
    use SUPER;
    use Fl qw[:color :default :event :box];
    extends 'Fl::Box';

    sub new {
        my $s = super;
        $s->box(FL_FLAT_BOX);
        $s->color(10);
        $s->label("...to\nhere");
        return $s;
    }

    # Receiver event handler
    sub handle {
        my ($s, $event) = @_;

        #printf STDERR "Event b: %d\n", $event;
        return 1
            if $event == FL_DND_ENTER
            || $event == FL_DND_DRAG
            || $event == FL_DND_LEAVE
            || $event == FL_DND_RELEASE;
        if ($event == FL_PASTE) {
            $s->label(Fl::event_text);

            #printf STDERR "Dropped:'%s'\n", Fl::event_text();
            return 1;
        }
        return super;
    }
};

# Create sender window and widget
my $win_a = Fl::Window->new(0, 0, 200, 100, "Sender");
my $_a = Sender->new(0, 0, 100, 100);
$win_a->end();
$win_a->show();

#Create receiver window and widget
my $win_b = Fl::Window->new(400, 0, 200, 100, "Receiver");
my $_b = Receiver->new(100, 0, 100, 100);
$win_b->end();
$win_b->show();
exit Fl::run();
