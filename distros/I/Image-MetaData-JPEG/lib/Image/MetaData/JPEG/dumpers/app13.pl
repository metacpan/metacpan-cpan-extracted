###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw(:TagsAPP13);
no  integer;
use strict;
use warnings;

###########################################################
# This routine dumps the Adobe identifier and then enters #
# a loop on the resource data block dumper, till the end. #
# TODO: implement dumping of multiple blocks!!!!          #
###########################################################
sub dump_app13 {
    my ($this) = @_;
    # get a reference to the segment record list
    my $records = $this->{records};
    # the segment always starts with an Adobe identifier
    $this->die('Identifier not found') unless
	my $id = $this->search_record_value('Identifier');
    $this->set_data($id);
    # version 2.5 (old) is followed by eight undocumented bytes
    # (maybe resolution info): output them if present and valid
    my $rec = $this->search_record('Resolution');
    $this->die('Header problem') unless (defined $rec) eq ($id =~ /2\.5/);
    $this->set_data($rec->get_value()) if $rec;
    # for each possible IPTC record number (remember that there can be
    # multiple IPTC subdirs, referring to different IPTC records), dump
    # the corresponding IPTC block, if present; the easiest solution is
    # to create a fake Record, which is then dumped as usual
    for my $r_number (1..9) {
	next unless my $record 
	    = $this->search_record("${APP13_IPTC_DIRNAME}_${r_number}");
	my $content = $record->get_value();
	my $block = dump_IPTC_datasets($r_number, $content);
	my $fake_record = new Image::MetaData::JPEG::Record
	    ($APP13_PHOTOSHOP_IPTC, $UNDEF, \ $block, length $block);
	$fake_record->{extra} = $record->{extra};
	$this->dump_resource_data_block($fake_record); }
    # do the same on all non-IPTC subdirs (remember that there can be
    # multiple non-IPTC subdirs, with type '8BIM', '8BPS', 'PHUT', ...)
    for my $type (@$APP13_PHOTOSHOP_TYPE) {
	next unless my $record 
	    = $this->search_record("${APP13_PHOTOSHOP_DIRNAME}_${type}");
	$this->dump_resource_data_block($_,$type) for @{$record->get_value()};}
    # return without errors
    return undef;
}

###########################################################
# TODO: implement dumping of multiple blocks!!!!          #
###########################################################
sub dump_resource_data_block {
    my ($this, $record, $type) = @_;
    # try to extract an optional name from the extra field
    my $name = $record->{extra} ? $record->{extra} : '';
    # provide a default type if $type is null
    $type = $$APP13_PHOTOSHOP_TYPE[0] unless $type;
    # dump the resource data block type
    $this->set_data($type);
    # dump the block identifier, which is the numeric tag
    # of the record (as a 2-byte unsigned integer).
    $this->set_data(pack "n", $record->{key});
    # the block name is usually "\000"; calculate its length,
    # then pad it so that storing the name length (1 byte) 
    # + $name + padding takes an even number of bytes
    my $name_length = length $name;
    my $padding = ($name_length % 2) == 0 ? "\000" : "";
    $this->set_data(pack("C", $name_length) . $name . $padding);
    # initialise $data with the record dump.
    my $data = $record->get();
    # the next four bytes encode the resource data size. Also in this
    # case the total size must be padded to an even number of bytes
    my $data_length = length $data;
    $data .= "\000" if ($data_length % 2) == 1;
    $this->set_data(pack("N", $data_length));
    $this->set_data($data);
}

###########################################################
# This auxiliary routine dumps all IPTC datasets in the   #
# @$record subdirectory, referring to the $r_number IPTC  #
# record, and concatenates them into a string, which is   #
# returned at the end. See parse_IPTC_dataset for details.#
###########################################################
sub dump_IPTC_datasets {
    my ($r_number, $record) = @_;
    # prepare the scalar to be returned at the end
    my $block = "";
    # Each IPTC record is a sequence of variable length data sets. Each
    # dataset begins with a "tag marker" (its value is fixed) followed
    # by the "record number" (given by $r_number), followed by the
    # dataset number, length and data.
    for (@$record) {
	my ($dnumber, $type, $count, $dataref) = $_->get();
	$block .= pack "CCCn", ($APP13_IPTC_TAGMARKER, $r_number,
				$dnumber, length $$dataref);
	$block .= $$dataref;
    }
    # return the encoded datasets
    return $block;
}

# successful load
1;
