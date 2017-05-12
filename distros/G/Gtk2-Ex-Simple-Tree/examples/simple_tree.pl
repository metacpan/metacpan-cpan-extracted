#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use constant TRUE => 1;
use constant FALSE => !TRUE;

use Gtk2 '-init';
use Gtk2::Ex::Simple::Tree;

my $win = Gtk2::Window->new;
$win->signal_connect (destroy => sub { Gtk2->main_quit; });
$win->set_default_size (640, 480);

my $vbox = Gtk2::VBox->new (FALSE, 6);
$win->add ($vbox);

my $scwin = Gtk2::ScrolledWindow->new;
$vbox->pack_start ($scwin, TRUE, TRUE, 0);

my $stree = Gtk2::Ex::Simple::Tree->new (
			'Text Field'    => 'text',
			'Int Field'     => 'int',
			'Double Field'  => 'double',
			'Bool Field'    => 'bool',
			'Scalar Field'  => 'scalar',
			'Pixbuf Field'  => 'pixbuf',
	);
$scwin->add ($stree);

my $quit = Gtk2::Button->new_from_stock ('gtk-quit');
$vbox->pack_start ($quit, FALSE, FALSE, 0);
$quit->signal_connect (clicked => sub { Gtk2->main_quit; });

my $dump = Gtk2::Button->new_from_stock ('gtk-ok');
$vbox->pack_start ($dump, FALSE, FALSE, 0);
$dump->signal_connect (clicked => sub { 
		print 'indc: '.Dumper ($stree->get_selected_indices);
		$stree->get_selection->set_mode ('multiple');
	});
			

$win->show_all;

@{$stree->{data}} = (
	{
		value => [ 'one', 1, 1.1, 1, 'uno', undef, ],
		children => 
		[
			{
				value => [ 'one-c', 1, 1.11, 1, 'uno', undef, ],
			},
		]
	},
	{
		value => [ 'two', 2, 2.2, 0, 'dos', undef, ],
		children => 
		[
			{
				value => [ 'two-c', 2, 2.22, 2, 'dos', undef, ],
			},
		]
	},
	{
		value => [ 'three', 3, 3.3, 1, 'tres', undef, ],
	},
	{
		value => [ 'four', 4, 4.4, 0, 'quatro', undef, ],
		children => 
		[
			{
				value => [ 'two-c', 2, 2.22, 2, 'dos', undef, ],
				children => 
				[
					{
						value => [ 'two-c', 2, 2.22, 2, 'dos', undef, ],
					},
					{
						value => [ 'two-c', 2, 2.22, 2, 'dos', undef, ],
					},
				]
			},
			{
				value => [ 'two-c', 2, 2.22, 2, 'dos', undef, ],
			},
		]
	}
);

$win->show_all;
Gtk2->main;

print STDERR "pushed\n";
push @{$stree->{data}}, {
				value => [ 'pushed', 3, 3.23, 3, 'dos', undef, ],
			};

Gtk2->main;

print STDERR "deleted\n";
print Dumper (delete $stree->{data}[3]);

Gtk2->main;

print STDERR "pop\n";
print Dumper (pop @{$stree->{data}});

Gtk2->main;

print STDERR "shift\n";
print Dumper (shift @{$stree->{data}});

Gtk2->main;

print STDERR "splice\n";
print Dumper (splice @{$stree->{data}}, 1, 0, 
	{
		value => [ 'splice', 2, 2.2, 0, 'dos', undef, ],
		children => 
		[
			{
				value => [ 'two-c', 2, 2.22, 2, 'dos', undef, ],
			},
		]
	},
	{
		value => [ 'splice', 3, 3.3, 1, 'tres', undef, ],
	},
	);

Gtk2->main;

print Dumper ($stree->{data});
