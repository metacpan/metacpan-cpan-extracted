#
# $Id$
#

use Gtk2::TestHelper
	at_least_version => [2, 4, 0, "GtkFileChooser is new in 2.4"],
	tests => 4, noinit => 1;

my $filter_info = {
	contains     => ['display-name'],
	#filename     => '',
	#uri          => '',
	display_name => 'Frobnicated files',
	mime_type    => 'text/html',
};

#$filter_info->{contains}
#$filter_info->{filename}
#$filter_info->{uri}
#$filter_info->{display_name}
#$filter_info->{mime_type}

sub filter_func {
	my ($info, $data) = @_;
	isa_ok ($info, 'HASH');
	return TRUE;
}


my $file_filter = Gtk2::FileFilter->new;
isa_ok ($file_filter, 'Gtk2::FileFilter');
$file_filter->set_name ('fred');
is ($file_filter->get_name, 'fred');

$file_filter->add_mime_type ('text/plain');
$file_filter->add_pattern ('*.pl');

$file_filter->add_custom (['filename', 'mime-type'], \&filter_func);

ok ($file_filter->get_needed >= ['filename', 'mime-type']);

ok (!$file_filter->filter ($filter_info));

SKIP: {
	skip 'add_pixbuf_formats is new in 2.6', 0
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	$file_filter->add_pixbuf_formats;
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
