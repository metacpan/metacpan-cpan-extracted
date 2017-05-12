use strict;
use warnings;
use Fl qw[:event :label :box :font];

# Custom widget!
{

    package Fl::DemoBox;
    use Fl qw[:color :default :event];
    extends 'Fl::Button';
    use SUPER;
    use Data::Dump;

    sub handle {
        my ($s, $event) = @_;
        CORE::state $click = 0;
        return super if $event != FL_RELEASE;
        warn 'double click!' if (time == $click); # You'd do something more...
        $click = time;
        return super;
    }
    1;
}
#
my $window = Fl::Window->new(100, 100, 300, 180);
my $box = Fl::DemoBox->new(20, 40, 260, 100, 'Hello, World');
$box->labelfont(FL_BOLD + FL_ITALIC);
$box->labelsize(36);
$box->labeltype(FL_SHADOW_LABEL);
$window->end();
$window->show();
exit run();
