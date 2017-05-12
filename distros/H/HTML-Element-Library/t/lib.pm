package t::lib;
use strict;
use warnings;

use File::Slurp qw/read_file/;
use HTML::TreeBuilder;
use HTML::Element::Library;
use Test::More ();
use Test::XML;

use parent qw/Exporter/;
our @EXPORT = qw/is is_deeply is_xml slurp mktree isxml/;
our $VERSION = '0.001'; # Exporter needs a $VERSION

sub import {
	my ($self, @args) = @_;
	strict->import;
	warnings->import;
	Test::More->import(@args);

	$self->export_to_level(1, $self);
}

sub slurp { scalar read_file @_ }

sub mktree {
	my ($file) = @_;
	HTML::TreeBuilder->new_from_file($file)->disembowel;
}

sub isxml {
	my ($tree, $file, $name) = @_;
	my $res = ref $tree eq 'SCALAR' ? $$tree : $tree->as_XML;
	my $exp = ref $file eq 'SCALAR' ? $$file : slurp $file;
	is_xml $res, $exp, $name
}
