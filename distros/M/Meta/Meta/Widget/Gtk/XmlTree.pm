#!/bin/echo This is a perl module and should not be run

package Meta::Widget::Gtk::XmlTree;

use strict qw(vars refs subs);
use Gtk qw();
use Meta::Baseline::Aegis qw();
use XML::DOM qw();
use XML::DOM::ValParser qw();

our($VERSION,@ISA);
$VERSION="0.14";
@ISA=qw(Gtk::Tree);

#sub new($);
#sub set_dom($$);
#sub set_file($$);
#sub set_deve_file($$);
#sub get_vali($);
#sub set_vali($$);
#sub get_skip($);
#sub set_skip($$);
#sub get_full($);
#sub set_full($$);
#sub node_add($$$);
#sub node_del($$$);
#sub tree_expand($$$);
#sub tree_collapse($$$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Gtk::Tree->new();
	$self->{DOMX}=defined;
	$self->{VALI}=1;
	$self->{SKIP}=1;
	$self->{FULL}=1;
	bless($self,$class);
	return($self);
}

sub set_dom($$) {
	my($self,$domx)=@_;
	$self->{DOMX}=$domx;

	#lets add the root
	my($node)=$domx->getDocumentElement();
	$self->node_add($node,$self,$self);
}

sub set_file($$) {
	my($self,$file)=@_;
	my($parser);
	if($self->get_vali()) {
		my(@list);
		my($search_path)=Meta::Baseline::Aegis::search_path_list();
		for(my($i)=0;$i<=$#$search_path;$i++) {
			push(@list,$search_path->[$i]."/dtdx");
		}
		XML::Checker::Parser::set_sgml_search_path(@list);
		$parser=XML::DOM::ValParser->new(SkipInsignifWS=>$self->get_skip());
	} else {
		$parser=XML::DOM::Parser->new(SkipInsignifWS=>$self->get_skip());
	}
	my($doc)=$parser->parsefile($file);
	$self->set_dom($doc);
}

sub set_deve_file($$) {
	my($self,$file)=@_;
	$self->set_file(Meta::Baseline::Aegis::which($file));
}

sub get_vali($) {
	my($self)=@_;
	return($self->{VALI});
}

sub set_vali($$) {
	my($self,$val)=@_;
	$self->{VALI}=$val;
}

sub get_skip($) {
	my($self)=@_;
	return($self->{SKIP});
}

sub set_skip($$) {
	my($self,$val)=@_;
	$self->{SKIP}=$val;
}

sub get_full($) {
	my($self)=@_;
	return($self->{FULL});
}

sub set_full($$) {
	my($self,$val)=@_;
	$self->{FULL}=$val;
}

sub node_add($$$) {
	my($self,$node,$tree)=@_;
#	Meta::Utils::Output::print("in node_add\n");
	my($text);
	if($node->getNodeType()==XML::DOM::TEXT_NODE()) {
		my($data)=$node->getData();
		$text=$node->getData();
	} else {
		$text=$node->getNodeName();
	}
	my($leaf)=Gtk::TreeItem->new_with_label($text);
	$leaf->set_user_data($node);
	$leaf->show();
	$tree->append($leaf);
	if($node->hasChildNodes())
	{
		my($subtree)=Gtk::Tree->new();
		$leaf->set_subtree($subtree);
		if($self->get_full()) {
			my($child)=$node->getFirstChild();
			while(defined($child)) {
				$self->node_add($child,$subtree);
				$child=$child->getNextSibling();
			}
		} else {
			$leaf->signal_connect('expand',\&tree_expand,$subtree,$self);
			$leaf->signal_connect('collapse',\&tree_collapse,$subtree,$self);
		}
	}
}

sub node_del($$$) {
	my($self,$node,$subtree)=@_;
#	Meta::Utils::Output::print("in node_del\n");
	if($self->get_full()) {
	} else {
		Meta::Utils::Output::print("in here\n");
		my($new_subtree)=Gtk::Tree->new();
		$subtree->remove_subtree();
		$subtree->set_subtree($new_subtree);
		$subtree->signal_connect('expand',\&tree_expand,$new_subtree,$self);
		$subtree->signal_connect('collapse',\&tree_expand,$new_subtree,$self);
	}
}

sub tree_expand($$$) {
	my($item,$subtree,$self)=@_;
#	Meta::Utils::Output::print("in tree_expand\n");
	my($node)=$item->get_user_data();
	$self->node_add($node,$subtree);
}

sub tree_collapse($$$) {
	my($item,$subtree,$self)=@_;
#	Meta::Utils::Output::print("in tree_collapse\n");
	my($node)=$item->get_user_data();
	$self->node_del($node,$subtree);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Widget::Gtk::XmlTree - widget to show/edit XML::DOM objects.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: XmlTree.pm
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	package foo;
	use Meta::Widget::Gtk::XmlTree qw();
	my($object)=Meta::Widget::Gtk::XmlTree->new();
	my($result)=$object->set_dom($dom);

=head1 DESCRIPTION

This is a widget which is derived from the Gtk::Tree widget and which displays
an XML::DOM object in it.
The object has several options:
0. vali - if this is turned on then a validating parser will be used to parse
	the document. This has more overhead but is more secure.
1. skip - if this is turned on then junk whitespace will be skipped and not
	presented as nodes. It is usually a good thing to keep this on.
2. full - if this is turned on then the entire DOM object will be scanned
	at the beginnig and all the visual elements created at that time.
	This has more overhead at begining but afterwards is much faster.
	If this option is turned off then only the root will be created and
	elements will be created as requested by the user. This has less
	overhead at the begining, uses less memory but is a little slower
	at run time. Please remmember that in either case the entire XML
	is already in memory because you are using DOM...:)

=head1 FUNCTIONS

	new($)
	set_dom($$)
	set_file($$)
	set_deve_file($$)
	get_vali($)
	set_vali($$)
	get_skip($)
	set_skip($$)
	get_full($)
	set_full($$)
	node_add($$$)
	node_del($$$)
	tree_expand($$$)
	tree_collapse($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Widget::Gtk::XmlTree object.

=item B<set_dom($$)>

This will add a dom object to this tree.

=item B<set_file($$)>

This method gets a file name, parses it and uses it as the display of
the widget.

=item B<set_deve_file($$)>

This method will do the same as set_file except it assumes that the file given
to it is in a development system and will ask the development system locator
for the files actual location before invoking set_file.

=item B<get_vali($)>

This method will retrieve the validate attribute.

=item B<set_vali($$)>

This method will set the validate attribute.

=item B<get_skip($)>

This method will retrieve the skip attribute.

=item B<set_skip($$)>

This method will set the skip attribute.

=item B<get_full($)>

This method will retrieve the full attribute.

=item B<set_full($$)>

This method will set the full attribute.

=item B<node_add($$$)>

This will add a node.

=item B<node_del($$$)>

This method deletes a node.

=item B<tree_expand($$$)>

This will handle tree expansions.

=item B<tree_collapse($$$)>

This will handle tree expansions.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Gtk::Tree(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV perl reorganization
	0.01 MV get imdb ids of directors and movies
	0.02 MV todo items in XML
	0.03 MV perl packaging
	0.04 MV PDMT
	0.05 MV md5 project
	0.06 MV database
	0.07 MV perl module versions in files
	0.08 MV movies and small fixes
	0.09 MV thumbnail user interface
	0.10 MV more thumbnail issues
	0.11 MV website construction
	0.12 MV web site automation
	0.13 MV SEE ALSO section fix
	0.14 MV md5 issues

=head1 SEE ALSO

Gtk(3), Meta::Baseline::Aegis(3), XML::DOM(3), XML::DOM::ValParser(3), strict(3)

=head1 TODO

Nothing.
