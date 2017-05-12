package Gtk2::ImageView;
use Gtk2;
require DynaLoader;
our @ISA = qw(DynaLoader);
our $VERSION = '0.05';
sub dl_load_flags {0x01};
bootstrap Gtk2::ImageView $VERSION;
1;
__END__

=head1 NAME

Gtk2::ImageView - Perl bindings to the GtkImageView image viewer widget

=head1 SYNOPSIS

 use Gtk2::ImageView;
 Gtk2->init;

 $window = Gtk2::Window->new();

 $view = Gtk2::ImageView->new;
 $view->set_pixbuf($pixbuf, TRUE);
 $window->add($view);

 $window->show_all;

=head1 ABSTRACT

Perl bindings to the GtkImageView image viewer widget
Find out more about GtkImageView at http://trac.bjourne.webfactional.com/.

The Perl bindings follow the C API very closely, and the C reference
should be considered the canonical documentation.

Be sure to check out the example programs in the "examples" directory.

=head1 DESCRIPTION

The Gtk2::ImageView module allows a Perl developer to use the GtkImageView
image viewer widget.  Find out more about GtkImageView at
http://trac.bjourne.webfactional.com/.

To discuss Gtk2::ImageView or gtk2-perl, ask questions and flame/praise the
authors, join gtk-perl-list@gnome.org at lists.gnome.org.

