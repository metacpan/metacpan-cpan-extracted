#!/usr/bin/perl -w
# vim: set ft=perl :
#
# Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the 
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
# Boston, MA  02110-1301  USA.
#
# $Id$
#

use strict;
use Gtk2::TestHelper
  tests => 46,
  at_least_version => [2, 10, 0, "GtkTextBufferRichText is new in 2.10"];

sub dump_formats {
        for (my $i = 0 ; $i < @_ ; $i++) {
                print "  $i   ".$_[0]->name."\n";
        }
}

sub serialize_func {
    my ($register_buffer, $content_buffer, $start_iter, $end_iter, $user_data) = @_;

    isa_ok ($register_buffer, 'Gtk2::TextBuffer');
    isa_ok ($content_buffer, 'Gtk2::TextBuffer');
    isa_ok ($start_iter, 'Gtk2::TextIter');
    isa_ok ($end_iter, 'Gtk2::TextIter');

    # should return a string.  we'll do something silly like wrap the whole
    # text string in curly braces.
    return "{".$content_buffer->get_text ($start_iter, $end_iter, FALSE)."}";
}

sub deserialize_func {
    my ($register_buffer, $content_buffer, $iter, $data, $create_tags, $user_data) = @_;

    isa_ok ($register_buffer, 'Gtk2::TextBuffer');
    isa_ok ($content_buffer, 'Gtk2::TextBuffer');
    isa_ok ($iter, 'Gtk2::TextIter');
    ok ($data);
    ok (defined $create_tags);

    # our serialize func wrapped curly braces around the text.  remove them.
    $data =~ s/^{//;
    $data =~ s/}$//;
    $content_buffer->insert ($iter, $data);

    # can croak on error, we should be able to trap it.
}


my $buffer = Gtk2::TextBuffer->new;
my $content_buffer = Gtk2::TextBuffer->new;
isa_ok ($buffer, 'Gtk2::TextBuffer');
isa_ok ($content_buffer, 'Gtk2::TextBuffer');

my $mime_type = "application/funky";
my $tagset_name = "funky";


# don't know if there are any preregistered formats, so let's register the
# built-in gtk rich text one first.  With no tagset_name, we get the full set.
my $serialize_tagset_atom =
        $buffer->register_serialize_tagset (undef);
ok ($serialize_tagset_atom);
is ($serialize_tagset_atom->name, 'application/x-gtk-text-buffer-rich-text');


# check.
my @serialize_formats = $buffer->get_serialize_formats ();
is (scalar (@serialize_formats), 1);
is ($serialize_formats[0]->name, $serialize_tagset_atom->name);


# now register a custom serialization format...
my $serialize_format_atom =
        $buffer->register_serialize_format ($mime_type, \&serialize_func);
ok ($serialize_format_atom);
@serialize_formats = $buffer->get_serialize_formats;
is (scalar (@serialize_formats), 2);
ok (scalar (grep { $_ == $serialize_format_atom }
                $buffer->get_serialize_formats));


# now the same for the deserialization formats.

# With no tagset_name, we get the full set.
my $deserialize_tagset_atom =
        $buffer->register_deserialize_tagset (undef);
ok ($deserialize_tagset_atom);
is ($deserialize_tagset_atom->name, 'application/x-gtk-text-buffer-rich-text');

my @deserialize_formats = $buffer->get_deserialize_formats ();
is (scalar (@deserialize_formats), 1);

# register a custom serialization format...
my $deserialize_format_atom =
        $buffer->register_deserialize_format ($mime_type, \&deserialize_func);
ok ($deserialize_format_atom);
@deserialize_formats = $buffer->get_deserialize_formats;
is (scalar (@deserialize_formats), 2);
ok (scalar (grep { $_ == $deserialize_format_atom }
                $buffer->get_deserialize_formats));


#
# misc.
#

$buffer->deserialize_set_can_create_tags ($deserialize_format_atom, FALSE);
ok (!$buffer->deserialize_get_can_create_tags ($deserialize_format_atom));

$buffer->deserialize_set_can_create_tags ($deserialize_format_atom, TRUE);
ok ($buffer->deserialize_get_can_create_tags ($deserialize_format_atom));


#
# now the actual work.
#
my $text;
{
        local $/ = undef;
        $text = <DATA>;
}

$content_buffer->insert ($content_buffer->get_start_iter, $text);


# first, let's serialize to the gtk rich text stuff.
my ($start, $end) = $content_buffer->get_bounds;
my $data = $buffer->serialize ($content_buffer, $serialize_tagset_atom,
                               $start, $end);
ok ($data);

# clear it out and try to deserialize.
$content_buffer->delete ($content_buffer->get_bounds);
ok (!$content_buffer->get_text ($content_buffer->get_bounds, FALSE));

$buffer->deserialize ($content_buffer, $deserialize_tagset_atom,
                      $content_buffer->get_end_iter, $data);
is ($content_buffer->get_text ($content_buffer->get_bounds, FALSE), $text);



# fair enough.  now try with our custom format.

# first, let's serialize to the gtk rich text stuff.
$data = $buffer->serialize ($content_buffer, $serialize_format_atom,
                            $content_buffer->get_bounds);
ok ($data);

# clear it out and try to deserialize.
$content_buffer->delete ($content_buffer->get_bounds);
ok (!$content_buffer->get_text ($content_buffer->get_bounds, FALSE));

$buffer->deserialize ($content_buffer, $deserialize_format_atom,
                      $content_buffer->get_end_iter, $data);
is ($content_buffer->get_text ($content_buffer->get_bounds, FALSE), $text);



#
# now unregister.
#

$buffer->unregister_serialize_format ($serialize_format_atom);
@serialize_formats = $buffer->get_serialize_formats ();
is (scalar (@serialize_formats), 1);

$buffer->unregister_deserialize_format ($deserialize_format_atom);
@deserialize_formats = $buffer->get_deserialize_formats ();
is (scalar (@deserialize_formats), 1);



#
# now let's make sure we handle exceptions in the deserialize callback.
# for good measure, we'll check the user data passing, too.
#
my $format = $buffer->register_deserialize_format
                        ("text/something-broken",
                         sub {
                                my ($register_buffer,
                                    $content_buffer,
                                    $iter,
                                    $data,
                                    $create_tags,
                                    $user_data) = @_;
                                isa_ok ($user_data, 'HASH');
                                is ($user_data->{foo}, 'bar');
                                die "ouch";
                         },
                         { foo => 'bar' });
ok ($format);
eval {
        $buffer->deserialize ($content_buffer, $format,
                              $content_buffer->get_end_iter, $data);
};
ok ($@);
isa_ok ($@, 'Glib::Error');
like ($@->message, qr/ouch/);
$buffer->unregister_deserialize_format ($format);

# and, since we also have code to support passing Glib::Errors through
# this machinery...
$format = $buffer->register_deserialize_format
                        ("text/something-else-broken",
                         sub { Glib::File::Error->throw ('noent', 'ugh') });
ok ($format);
eval {
        $buffer->deserialize ($content_buffer, $format,
                              $content_buffer->get_end_iter, $data);
};
ok ($@);
isa_ok ($@, 'Glib::Error');
isa_ok ($@, 'Glib::File::Error');
is ($@->value, 'noent');
is ($@->message, 'ugh');
$buffer->unregister_deserialize_format ($format);


# today's random input selection is "Bike", by Pink Floyd.
__DATA__
I've got a bike 
You can ride it if you like 
It's got a basket 
A bell that rings 
And things to make it look good 
I'd give it to you if I could 
But I borrowed it 

You're the kind of girl that fits in with my world 
I'll give you anything 
Everything if you want things 

I've got a cloak 
It's a bit of a joke 
There's a tear up the front 
It's red and black 
I've had it for months 
If you think it could look good 
Then I guess it should 

You're the kind of girl that fits in with my world 
I'll give you anything 
Everything if you want things 

I know a mouse 
And he hasn't got a house 
I don't know why 
I call him Gerald 
He's getting rather old 
But he's a good mouse 

You're the kind of girl that fits in with my world 
I'll give you anything 
Everything if you want things 

I've got a clan of gingerbread men 
Here a man 
There a man 
Lots of gingerbread men 
Take a couple if you wish 
They're on the dish 

You're the kind of girl that fits in with my world 
I'll give you anything 
Everything if you want things 

I know a room full of musical tunes 
Some rhyme 
Some ching 
Most of them are clockwork 
Let's go into the other room and make them work 
