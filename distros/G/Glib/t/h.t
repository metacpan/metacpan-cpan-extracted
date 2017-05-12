#
# BookmarkFile
#
use strict;
use warnings;
use Glib ':constants';
use Test::More tests => 30;

our $str = <<__EOB__
<?xml version="1.0" encoding="UTF-8"?>
<xbel version="1.0"
      xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks"
      xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info"
>
  <bookmark href="file:///tmp/test-file.txt" added="2006-03-22T18:54:00Z" modified="2006-03-22T18:54:00Z" visited="2006-03-22T18:54:00Z">
    <title>Test File</title>
    <desc>Some test file</desc>
    <info>
      <metadata owner="http://freedesktop.org">
        <mime:mime-type type="text/plain"/>
        <bookmark:applications>
          <bookmark:application name="Gedit" exec="gedit %u" timestamp="1143053640" count="1"/>
        </bookmark:applications>
      </metadata>
    </info>
  </bookmark>
</xbel>
__EOB__
;

SKIP: {
	skip "Glib::BookmarkFile is new in glib 2.12.0", 30
		unless Glib->CHECK_VERSION (2, 12, 0);
	
	ok (defined Glib::BookmarkFile->new (), 'test constructor');

	my $bookmark_file = Glib::BookmarkFile->new;
	isa_ok ($bookmark_file, 'Glib::BookmarkFile', 'test ISA');

	my $size;
	$size = $bookmark_file->get_size;
	is ($size, 0, 'we have no bookmarks');

	$bookmark_file->load_from_data ($str);

	$size = $bookmark_file->get_size;
	is ($size, 1, 'we have one bookmark');
	
	my @uris = $bookmark_file->get_uris;
	is (@uris, $size, 'check size');
	eq_array (\@uris, [ 'file:///tmp/test-file.txt' ]);

	ok ($bookmark_file->has_item($uris[0]),
	    'check has item');
	
	is ($bookmark_file->get_title($uris[0]), 'Test File',
	    'check get_title');
	$bookmark_file->set_title($uris[0], 'Test file');
	is ($bookmark_file->get_title($uris[0]), 'Test file',
	    'check set_title');

	is ($bookmark_file->get_description($uris[0]), 'Some test file',
	    'check get_description');
	$bookmark_file->set_description($uris[0], 'Foo');
	is ($bookmark_file->get_description($uris[0]), 'Foo',
	    'check set_description');

	is ($bookmark_file->get_mime_type($uris[0]), 'text/plain',
	    'check get_mime_type');
	$bookmark_file->set_mime_type($uris[0], 'image/png');
	is ($bookmark_file->get_mime_type($uris[0]), 'image/png',
	    'check set_mime_type');
	
	my $uri = 'file:///tmp/another-file.txt';
	$bookmark_file->set_title($uri, 'Another file');
	$bookmark_file->set_description($uri, 'Yet another test file');

	$bookmark_file->add_group($uri, 'Editors');
	$bookmark_file->add_group($uri, 'Stuff');
	
	my @groups = $bookmark_file->get_groups($uri);
	is (@groups, 2, 'check add group');

	$bookmark_file->remove_group($uri, 'Stuff');
	ok (!$bookmark_file->has_group($uri, 'Stuff'), 'check has_group');
	
	$bookmark_file->add_application($uri, 'Gedit', 'gedit %u');
	ok ($bookmark_file->has_application($uri, 'Gedit'), 'check add_application');
	ok (!$bookmark_file->has_application($uri, 'Vim'), 'check has_application');

	$bookmark_file->add_application($uri, 'Vim', 'gvim %f');
	$bookmark_file->add_application($uri, 'Gedit', 'gedit %u');

	my ($exec, $count, $stamp) = $bookmark_file->get_app_info($uri, 'Gedit');
	is ($exec, "gedit $uri", 'check get_app_info/1');
	is ($count, '2', 'check get_app_info/2');
	
	my $now = time ();
	$bookmark_file->set_app_info($uri, 'Vim', 'gvim %f', 42, $now);
	is ($now, $bookmark_file->get_modified($uri),
	    'check set_app_info/1');

	(undef, $count, $stamp) = $bookmark_file->get_app_info($uri, 'Vim');
	is ($count, 42, 'check set_app_info/2');
	is ($stamp, $now, 'check set_app_info/3');

	$bookmark_file->set_app_info($uri, 'Gedit', '', 0, 1);
	ok (!$bookmark_file->has_application($uri, 'Gedit'),
	    'check set_app_info/4');

	$bookmark_file->remove_application($uri, 'Vim');
	ok (!$bookmark_file->has_application($uri, 'Vim'),
	    'check remove_application');

	my $new_uri =  'file:///tmp/some-other-test.txt';
	$bookmark_file->move_item($uri, $new_uri);
	ok ($bookmark_file->has_item($new_uri), 'check move_item/1');
	ok (!$bookmark_file->has_item($uri), 'check move_item/2');
	
	$bookmark_file->move_item($new_uri, undef);
	ok (!$bookmark_file->has_item($new_uri), 'check move_item/3');

	$bookmark_file->remove_item($uris[0]);
	is ($bookmark_file->get_size, 0, 'check_remove_item');

	$bookmark_file->set_added($uri, $now);
	is ($bookmark_file->get_added($uri), $now, 'check added accessors');

	$bookmark_file->set_modified($uri, $now);
	is ($bookmark_file->get_modified($uri), $now, 'check modified accessors');

	$bookmark_file->set_visited($uri, $now);
	is ($bookmark_file->get_visited($uri), $now, 'check visited accessors');
}

__END__

Copyright (C) 2006 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
