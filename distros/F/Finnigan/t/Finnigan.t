# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finnigan.t'

#########################

use Test::More tests => 239;

BEGIN { use_ok('Finnigan') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# set-up

sub num_equal {
  my( $float1, $float2, $diff ) = @_;
  abs( $float1 - $float2 ) < ($diff or 0.00001);
}

my $file = "t/100225.raw";
open INPUT, "<$file" or die "can't open '$file': $!";
binmode INPUT;

# The following objects will be tested in the order they occur
# in the input file, unless a look-ahead is necessary.

# FileHeader
my $header = Finnigan::FileHeader->decode(\*INPUT);
is( $header->version, 63, "FileHeader->version" );
is( $header->size, 1356, "FileHeader->size" );
is( $header->audit_start->time, "Thu Feb 25 09:02:27 2010", "AuditTag->time" );

# SeqRow / InjectionData -- sample data
my $seq_row = Finnigan::SeqRow->decode(\*INPUT, $header->version);
is( $seq_row->size, 260, "SeqRow->size" );
is( $seq_row->file_name, 'C:\Xcalibur\calsolution\100225.raw', "SeqRow->file_name" );
is( $seq_row->path, '', "SeqRow->path" );
is( $seq_row->injection->size, 64, "InjectionData->size" );
is( $seq_row->injection->n, 1, "InjectionData->n" );
# untested in SeqRow::InjectionData: volume, injected volume, internal standard amount, dilution factor, the unknowns

# CASInfo / CASInfoPreamble -- autosampler data
my $cas_info = Finnigan::CASInfo->decode(\*INPUT);
is( $cas_info->size, 28, "CasInfo->size" );
is( $cas_info->preamble->size, 24, "CasInfoPreamble->size" );
# untested in CASInfo: text
# untested in CASInfo::Preamble: number of wells; the unknowns

# RawFileInfo / RawFileInfoPreamble -- the root index structure; interesting information is all in the preamble
my $rfi = Finnigan::RawFileInfo->decode(\*INPUT, $header->version);
is( $rfi->stringify, "Thu Feb 25 2010 9:2:27.781; data addr: 24950; RunHeader addr: 777542", "RawFileInfo->stringify" );
is( $rfi->preamble->xmlTimestamp, '2010-02-25T09:02:28Z', "RawFileInfoPreamble->xmlTimestamp" );
is( $rfi->size, 844, "RawFileInfo->size" );
is( $rfi->preamble->size, 804, "RawFileInfoPreamble->size" );
my $data_addr = $rfi->preamble->data_addr;
is( $data_addr, 24950, "RawFileInfoPreamble->data_addr" );
is( $rfi->preamble->run_header_addr, 777542, "RawFileInfoPreamble->run_header_addr" );
is( $rfi->{data}->{"unknown text"}->{value}, 'DB23HPD1', "RawFileInfo->{unknown text}" );
my $run_header_addr = $rfi->preamble->run_header_addr;
is( $run_header_addr, 777542, "RawFileInfoPreamble->run_header_addr" );

# MethodFile / OLE2File
my $mf = Finnigan::MethodFile->decode(\*INPUT);
is( $mf->size, 3646, "MethodFile->size" );
is( $mf->file_size, 20992, "MethodFile->file_size" );
# the entire translation table
is( $mf->translation_table->[0], 'LTQ Orbitrap XL MS', 'MethodFile->translation_table (key)' );
is( $mf->translation_table->[1], 'LTQ', 'MethodFile->translation_table (value)');
# name translation for the first instrument
is( ($mf->instrument_name(1))[0], 'LTQ Orbitrap XL MS', 'MethodFile->instrument_name(1) (key)' );
is( ($mf->instrument_name(1))[1], 'LTQ', 'MethodFile->instrument_name(1) (value)');
# container functions
is( $mf->container->stringify, "Windows Compound Binary File: 5 nodes", "OLE2File->stringify");
is( $mf->container->header->stringify, "Version 3.62; block(s) in FAT chain: 1; in mini-FAT chain: 1; in DIF chain: 0", "OLE2Header->stringify" );
is( $mf->container->dif->stringify, "Double-Indirect FAT; 1/109 entries used", "OLE2DIF->stringify" );
is( $mf->container->dif->sect->[0], 0, "OLE2DIF->sect used" );
isnt( $mf->container->dif->sect->[1], 0, "OLE2DIF->sect vacant" );
is( $mf->container->data->{"fat[0]"}->{value}->sect->[1], 35, "OLE2FAT->sect (big fat)" );
is( $mf->container->data->{"minifat[36]"}->{value}->sect->[20], 21, "OLE2FAT->sect (minifat)" );
is( join(' ', $mf->container->get_chain(37, "big")), "37 38 39", "OLE2File->get_chain(n, 'big')" );
is( $mf->container->data->{"property[1][1]"}->{value}->name, "Root Entry", "OLE2Property->name (test 1)" );
is( $mf->container->data->{"property[35][1]"}->{value}->name, "Header", "OLE2Property->name (test 2)" );
my $text_node = $mf->container->find("LTQ/Text");
ok($text_node, "OLE2File->find");
is( $text_node->name, "Text", "OLE2DirectoryEntry->name" );
is( length $text_node->data, 9722, "OLE2DirectoryEntry->data length" );
like($text_node->data, qr/S\0e\0g\0m\0e\0n\0t\0 \0001\0 \0I\0n\0f\0o\0r\0m\0a\0t\0i\0o\0n\0/m, 'OLE2DirectoryEntry->data'); # it is UTF-16

# this test does not work; reading stopst 2560 bytes short of $data_addr (probably because of unused blocks)
#is( tell INPUT, $data_addr, "should have arrived at the data section after reading the method file");

#---------------------------------------------------------------------------------
#  S K I P    F O R W A R D
#---------------------------------------------------------------------------------

# This is where the sequence breaks. The file pointer is now near the start of
# scan data, but any operation with the scan data involving conversion to M/z
# will require a trip to the ScanEvent stream, whose address is stored in 
# RunHeader, also downstream from the scan data.

# fast-forward to RunHeader
seek INPUT, $run_header_addr, 0;
is( tell INPUT, $run_header_addr, "seek to run header address" );

# RunHeader / SampleInfo
my $run_header = Finnigan::RunHeader->decode( \*INPUT, $header->version );
is( $run_header->self_addr, $run_header_addr, "RunHeader->self_addr" );
my $trailer_addr = $run_header->trailer_addr;
is( $trailer_addr, 832082, "RunHeader->trailer_addr" );
my $params_addr = $run_header->params_addr;
is( $params_addr, 838794, "RunHeader->params_addr" );
is( $run_header->ntrailer, 33, "RunHeader->ntrailer" );
is( $run_header->nparams, 33, "RunHeader->nparams" );
is( $run_header->nsegs, 1, "RunHeader->nsegs" );
my $scan_index_addr = $run_header->scan_index_addr;
is( $scan_index_addr, 829706, "RunHeader->scan_index_addr" );
is( $run_header->data_addr, $data_addr, "RunHeader->data_addr" );
my $inst_log_addr = $run_header->inst_log_addr;
is( $inst_log_addr, 792726, "RunHeader->inst_log_addr" );
my $error_log_addr = $run_header->error_log_addr;
is( $error_log_addr, 803810, "RunHeader->ERROR>_log_addr" );
my $sample_info = $run_header->sample_info;

# SampleInfo
my $first_scan = $sample_info->first_scan;
is( $first_scan, 1, "SampleInfo->first_scan" );
my $last_scan  = $sample_info->last_scan;
is( $last_scan, 33, "SampleInfo->last_scan" );
ok( num_equal($sample_info->max_ion_current, 11508917, 0.1), "SampleInfo->max_ion_current" );
ok( num_equal($sample_info->low_mz, 100), "SampleInfo->low_mz" );
ok( num_equal($sample_info->high_mz, 2000), "SampleInfo->high_mz" );
ok( num_equal($sample_info->start_time, 0.00581833333333333), "SampleInfo->start_time" );
ok( num_equal($sample_info->end_time, 0.242753333333333), "SampleInfo->end_time" );
my $inst_log_length = $sample_info->inst_log_length;
is( $inst_log_length, 17, "SampleInfo->inst_log_length" );

# -------------------------------------------------------------------------------
# With all pointers now on hand, we could go ahead and read the ScanEvent stream 
# and return to the data, but for consistency of testing, it is better to keep
# trudging along in the same direction until the end of file is reached, then
# return to the data. Smart programs will know which prats of the file are
# worth reading for their particular purpose.

# InstID
my $inst_id         = Finnigan::InstID->decode( \*INPUT );
is( $inst_id->model, 'LTQ Orbitrap XL', "InstID->model");

# Instrument Log -- use generic decoders.
# The only way to reach the instrument log header is to read
# RunHeader and InstID prior to it, because there is no pointer
# to it anywhere in the file. The instrument log address in
# SampleInfo points at the first instrument log record following
# the header.
my $inst_log_header = Finnigan::GenericDataHeader->decode(\*INPUT);
is( $inst_log_header->n, 158, "GenericDataHeader->n (Instrument Log)" );
# only types 0, 3, 4, 6, 9, 10, 13 in this file
is( $inst_log_header->fields->[0]->type, 0, "GenericDataHeader->fields, GenericDataDescriptor->type 0" );
is( $inst_log_header->fields->[0]->length, 0, "GenericDataHeader->fields, GenericDataDescriptor->lenth 0" );
is( $inst_log_header->fields->[0]->label, "API SOURCE", "GenericDataHeader->fields, GenericDataDescriptor->label 0" );
is( $inst_log_header->fields->[3]->type, 3, "GenericDataHeader->fields, GenericDataDescriptor->type 3" );
is( $inst_log_header->fields->[3]->length, 0, "GenericDataHeader->fields, GenericDataDescriptor->lenth 3" );
is( $inst_log_header->fields->[3]->label, "Vaporizer Thermocouple OK:", "GenericDataHeader->fields, GenericDataDescriptor->label 3" );
is( $inst_log_header->fields->[16]->type, 4, "GenericDataHeader->fields, GenericDataDescriptor->type 4" );
is( $inst_log_header->fields->[16]->length, 0, "GenericDataHeader->fields, GenericDataDescriptor->lenth 4" );
is( $inst_log_header->fields->[16]->label, "Ion Gauge Status:", "GenericDataHeader->fields, GenericDataDescriptor->label 4" );
is( $inst_log_header->fields->[31]->type, 6, "GenericDataHeader->fields, GenericDataDescriptor->type 6" );
is( $inst_log_header->fields->[31]->length, 0, "GenericDataHeader->fields, GenericDataDescriptor->lenth 6" );
is( $inst_log_header->fields->[31]->label, "Power (Watts):", "GenericDataHeader->fields, GenericDataDescriptor->label 6" );
is( $inst_log_header->fields->[29]->type, 9, "GenericDataHeader->fields, GenericDataDescriptor->type 9" );
is( $inst_log_header->fields->[29]->length, 0, "GenericDataHeader->fields, GenericDataDescriptor->lenth 9" );
is( $inst_log_header->fields->[29]->label, "Life (hours):", "GenericDataHeader->fields, GenericDataDescriptor->label 9" );
is( $inst_log_header->fields->[53]->type, 10, "GenericDataHeader->fields, GenericDataDescriptor->type 10" );
is( $inst_log_header->fields->[53]->length, 2, "GenericDataHeader->fields, GenericDataDescriptor->lenth 10" );
is( $inst_log_header->fields->[53]->label, "Multipole 00 Offset (V):", "GenericDataHeader->fields, GenericDataDescriptor->label 10" );
is( $inst_log_header->fields->[28]->type, 13, "GenericDataHeader->fields, GenericDataDescriptor->type 13" );
is( $inst_log_header->fields->[28]->length, 14, "GenericDataHeader->fields, GenericDataDescriptor->lenth 13" );
is( $inst_log_header->fields->[28]->label, "Status:", "GenericDataHeader->fields, GenericDataDescriptor->label 13" );
is( tell INPUT, $inst_log_addr, "should have arrived at the start of the instrument log" );
# read the last log record (almost a guarantee that all prior records are intact)
my $inst_log_record;
foreach my $i (0 .. $inst_log_length - 1) {
  $inst_log_record = Finnigan::InstrumentLogRecord->decode(\*INPUT, $inst_log_header->ordered_field_templates);
}
ok( num_equal($inst_log_record->time, 0.269295006990433), "InstrumentLogRecord->time (Instrument Log, 17.0, type 11)" );
is( $inst_log_record->data->{"1|API SOURCE"}->{value}, "", "InstrumentLogRecord->decode (Instrument Log, 17.1, type 0)" );
is( $inst_log_record->data->{"4|Vaporizer Thermocouple OK:"}->{value}, 0, "InstrumentLogRecord->decode (Instrument Log, 17.4, type 3)" );
is( $inst_log_record->data->{"17|Ion Gauge Status:"}->{value}, 1, "InstrumentLogRecord->decode (Instrument Log, 17.17, type 4)" );
is( $inst_log_record->data->{"32|Power (Watts):"}->{value}, 69, "InstrumentLogRecord->decode (Instrument Log, 17.32, type 6)" );
is( $inst_log_record->data->{"30|Life (hours):"}->{value}, 18398, "InstrumentLogRecord->decode (Instrument Log, 17.30, type 9)" );
ok( num_equal($inst_log_record->data->{"54|Multipole 00 Offset (V):"}->{value}, -2.0935959815979), "InstrumentLogRecord->decode (Instrument Log, 17.54, type 10)" );
is( $inst_log_record->data->{"29|Status:"}->{value}, "Running", "InstrumentLogRecord->decode (Instrument Log, 17.29, type 13)" );
is( $inst_log_record->data->{"158|Divert/Inject valve:"}->{value}, "Inject", "InstrumentLogRecord->decode (Instrument Log, 17.158, last item)" );
# foreach my $key (sort {(split /\|/, $a)[0] <=> (split /\|/, $b)[0]} keys %{$inst_log_record->data}) {
#   print STDERR "$key -> " . $inst_log_record->data->{$key}->{value} . "\n";
# }

# Error log (null in the test file);
is( tell INPUT, $error_log_addr, "should have arrived at the start of the error log" );
my $error_log_length = Finnigan::Decoder->read(\*INPUT, ['length' => ['V', 'UInt32']])->{data}->{length}->{value};
is( $error_log_length, 0, "Error log length" );

# ScanEventHierarchy
my $nsegs = Finnigan::Decoder->read(\*INPUT, ['nsegs' => ['V', 'UInt32']])->{data}->{nsegs}->{value};
is( $nsegs, 1, "Number of scan segments" );
my $nev = Finnigan::Decoder->read(\*INPUT, ['nev' => ['V', 'UInt32']])->{data}->{nev}->{value};
is( $nev, 4, "Number of scan event types in the first segment" );
# read the first scan event template
my $et = Finnigan::ScanEventTemplate->decode(\*INPUT, $header->version);
is( join('', $et->preamble->list), "1121111011030000000000004000255255255255000020004222111000000000100000000000000022000000000000002000000000000000200000000000000002140000", "ScanEventTemplate->ScanEventPreamble->list (1)" );
is( join(' ', $et->preamble->list('decode')), "1 1 undefined undefined positive profile MS1 Full 1 1 False ESI 0 0 0 0 0 0 0 0 0 0 0 0 4 0 0 0 255 255 255 255 Off 0 0 0 2 0 0 0 FTMS 2 2 2 1 1 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1 4 0 0 0 0", "ScanEventTemplate->ScanEventPreamble->list(decode) (1)" );
is( $et->preamble->corona('decode'), "undefined", "ScanEventTemplate->ScanEventPreamble->corona(decode) (1)" );
is( $et->preamble->detector('decode'), "undefined", "ScanEventTemplate->ScanEventPreamble->detector(decode) (1)" );
is( $et->preamble->polarity('decode'), "positive", "ScanEventTemplate->ScanEventPreamble->polarity(decode) (1)" );
is( $et->preamble->scan_mode('decode'), "profile", "ScanEventTemplate->ScanEventPreamble->scan_mode(decode) (1)" );
is( $et->preamble->ms_power('decode'), "MS1", "ScanEventTemplate->ScanEventPreamble->ms_power(decode) (1)" );
is( $et->preamble->scan_type('decode'), "Full", "ScanEventTemplate->ScanEventPreamble->scan_type(decode) (1)" );
is( $et->preamble->dependent, 0, "ScanEventTemplate->ScanEventPreamble->dependent (1)" );
is( $et->preamble->ionization('decode'), "ESI", "ScanEventTemplate->ScanEventPreamble->ionization(decode) (1)" );
is( $et->preamble->ionization('decode'), "ESI", "ScanEventTemplate->ScanEventPreamble->ionization(decode) (1)" );
is( $et->preamble->analyzer('decode'), "FTMS", "ScanEventTemplate->ScanEventPreamble->analyzer(decode) (1)" );
is( $et->preamble->stringify, "FTMS + p ESI Full ms", "ScanEventTemplate->ScanEventPreamble->stringify (1)" );
is( $et->controllerType, 0, "ScanEventTemplate->controllerType; Assumption - not verified!");
is( $et->controllerNumber, 1, "ScanEventTemplate->controllerNumber; Assumption - not verified!");
ok( num_equal($et->fraction_collector->low, 400), "ScanEventTemplate->FractionCollector->low (1)" );
ok( num_equal($et->fraction_collector->high, 2000), "ScanEventTemplate->FractionCollector->high (1)" );
is( $et->fraction_collector->stringify, "[400.00-2000.00]", "ScanEventTemplate->FractionCollector->stringify (1)" );
# the second scan event template
$et = Finnigan::ScanEventTemplate->decode(\*INPUT, $header->version);
is( join(' ', $et->preamble->list('decode')), "1 0 undefined undefined positive profile MS2 Full 1 1 True ESI 0 0 0 0 0 0 0 0 0 0 0 0 4 0 0 0 255 255 255 255 Off 0 0 0 2 0 0 0 ITMS 2 2 2 1 1 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1 4 0 0 0 0", "ScanEventTemplate->ScanEventPreamble->list(decode) (2)" );
is ($et->preamble->stringify, "ITMS + p ESI d Full ms2", "ScanEventTemplate->ScanEventPreamble->stringify (2)" );
# the third scan event template
$et = Finnigan::ScanEventTemplate->decode(\*INPUT, $header->version);
is( join(' ', $et->preamble->list('decode')), "1 0 undefined undefined positive profile MS2 Full 1 1 True ESI 0 0 0 0 0 0 0 0 0 0 0 0 4 0 0 0 255 255 255 255 Off 0 0 0 2 0 0 0 ITMS 2 2 2 1 1 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1 4 0 0 0 0", "ScanEventTemplate->ScanEventPreamble->list(decode) (3)" );
is ($et->preamble->stringify, "ITMS + p ESI d Full ms2", "ScanEventTemplate->ScanEventPreamble->stringify (3)" );
# the fourth scan event template
$et = Finnigan::ScanEventTemplate->decode(\*INPUT, $header->version);
is( join(' ', $et->preamble->list('decode')), "1 0 undefined undefined positive profile MS2 Full 1 1 True ESI 0 0 0 0 0 0 0 0 0 0 0 0 4 0 0 0 255 255 255 255 Off 0 0 0 2 0 0 0 ITMS 2 2 2 1 1 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1 4 0 0 0 0", "ScanEventTemplate->ScanEventPreamble->list(decode) (3)" );
is ($et->preamble->stringify, "ITMS + p ESI d Full ms2", "ScanEventTemplate->ScanEventPreamble->stringify (3)" );

#-------------------------------------------------------------------------
#
# This is where things become convoluted. The following GenericDataHeader 
# decodes the ScanParameters stream that sits at the end of the file.
#
# The next ojbect after this will be the tune file, followed by the
# ScanIndex stream, then ScanEvent stream, and finally ScanParameters.
#
#-------------------------------------------------------------------------
my $scan_parameters_header = Finnigan::GenericDataHeader->decode(\*INPUT);
is( $scan_parameters_header->n, 29, "GenericDataHeader->n (ScanParameters stream)" );

# Tune file, a GenericRecord -- no special decoder is necessary
my $tune_file_header = Finnigan::GenericDataHeader->decode(\*INPUT);
is( $tune_file_header->n, 421, "GenericDataHeader->n (Tune File)" );
my $tune_file = Finnigan::GenericRecord->decode(\*INPUT, $tune_file_header->ordered_field_templates);
is( $tune_file->{data}->{"2|Source Type:"}->{value}, "ESI", "GenericRecord->decode (2), type 13" );
ok( num_equal($tune_file->{data}->{"3|Capillary Temp (C):"}->{value}, 275), "GenericRecord->decode (3), type 11" );
ok( num_equal($tune_file->{data}->{"421|FT Cal. Item 250:"}->{value}, 0), "GenericRecord->decode (421), type 11" );

# ScanIndex
is( tell INPUT, $scan_index_addr, "should have arrived at the start of scan index" );
my $index_entry       = Finnigan::ScanIndexEntry->decode( \*INPUT, $header->version );
# measure scan index record size
my $record_size = $index_entry->size;
is( $index_entry->size, 72, "ScanIndexEntry->size" );
# check that the index record stream is of the right size
my $stream_size = $trailer_addr - $scan_index_addr;
my $nrecords = $stream_size / $record_size;
is( $stream_size % $record_size, 0, "scan index record stream should contain a whole number of $record_size\-byte records");
# look inside this index entry
is( $index_entry->offset, 0, "ScanIndexEntry->offset (0)" );
is( $index_entry->index, 0, "ScanIndexEntry->index (0)" );
is( $index_entry->scan_event, 0, "ScanIndexEntry->scan_event (0)" );
is( $index_entry->scan_segment, 0, "ScanIndexEntry->scan_segment (0)" );
is( $index_entry->next, 1, "ScanIndexEntry->next (0)" );
is( $index_entry->unknown, 21, "ScanIndexEntry->unknown (0)" );
is( $index_entry->data_size, 31932, "ScanIndexEntry->data_size (0)" );
ok( num_equal($index_entry->start_time, 0.00581833333333333), "ScanIndexEntry->start_time (0)" );
ok( num_equal($index_entry->total_current, 10851256), "ScanIndexEntry->total_current (0)" );
ok( num_equal($index_entry->base_mz, 1521.9716796875), "ScanIndexEntry->base_mz (0)" );
ok( num_equal($index_entry->base_intensity, 796088), "ScanIndexEntry->base_intensity (0)" );
ok( num_equal($index_entry->low_mz, 400), "ScanIndexEntry->low_mz (0)" );
ok( num_equal($index_entry->high_mz, 2000), "ScanIndexEntry->high_mz (0)" );
for my $i (2 .. $nrecords) { # skip to the last index entry
  $index_entry = Finnigan::ScanIndexEntry->decode( \*INPUT, $header->version );
}
is( $index_entry->offset, 721572, "ScanIndexEntry->offset (32)" );
is( $index_entry->index, 32, "ScanIndexEntry->index (32)" );
is( $index_entry->scan_event, 0, "ScanIndexEntry->scan_event (32)" );
is( $index_entry->scan_segment, 0, "ScanIndexEntry->scan_segment (32)" );
is( $index_entry->next, 33, "ScanIndexEntry->next (32)" );
is( $index_entry->unknown, 21, "ScanIndexEntry->unknown (32)" );
is( $index_entry->data_size, 31020, "ScanIndexEntry->data_size (32)" );
ok( num_equal($index_entry->start_time, 0.242753333333333), "ScanIndexEntry->start_time (32)" );
ok( num_equal($index_entry->total_current, 11508917), "ScanIndexEntry->total_current (32)" );
ok( num_equal($index_entry->base_mz, 445.120635986328), "ScanIndexEntry->base_mz (32)" );
ok( num_equal($index_entry->base_intensity, 861951.8125), "ScanIndexEntry->base_intensity (32)" );
ok( num_equal($index_entry->low_mz, 400), "ScanIndexEntry->low_mz (32)" );
ok( num_equal($index_entry->high_mz, 2000), "ScanIndexEntry->high_mz (32)" );
is( tell INPUT, $trailer_addr, "should have arrived at the start of ScanEvents stream" );

# read the ScanEvent stream (the "trailer")
my $trailer_length = Finnigan::Decoder->read(\*INPUT, ['length' => ['V', 'UInt32']])->{data}->{length}->{value};
is( $trailer_length, 33, "the trailer events count should be 33");
# read the first ScanEvent record
my $scan_event = Finnigan::ScanEvent->decode( \*INPUT, $header->version );
is( $scan_event->preamble->corona('decode'), "undefined", "ScanEvent->preamble->corona" );
is( $scan_event->preamble->analyzer('decode'), "FTMS", "ScanEvent->preamble->analyzer" );
is( $scan_event->preamble->polarity('decode'), "positive", "ScanEvent->preamble->polarity" );
is( $scan_event->preamble->scan_mode('decode'), "profile", "ScanEvent->preamble->scan_mode" );
is( $scan_event->preamble->ionization('decode'), "ESI", "ScanEvent->preamble->ionization" );
is( $scan_event->preamble->dependent, 0, "ScanEvent->preamble->dependent" );
is( $scan_event->preamble->scan_type('decode'), "Full", "ScanEvent->preamble->scan_type" );
is( $scan_event->preamble->ms_power('decode'), "MS1", "ScanEvent->preamble->ms_power" );
is( "$scan_event", "FTMS + p ESI Full ms [400.00-2000.00]", "ScanEvent->preamble->stringify" );
is( $scan_event->preamble->wideband('decode'), "Off", "ScanEvent->preamble->wideband" );
is( $scan_event->fraction_collector->stringify, "[400.00-2000.00]", "ScanEvent->fraction_collector->stringify" );
is( $scan_event->np, 0, "ScanEvent->np" );
is( $scan_event->precursors, undef, "ScanEvent->precursors" );
my $converter = $scan_event->converter;
ok( num_equal(&$converter(1), 38518081.414831), "ScanEvent->converter");
my $inverse_converter = $scan_event->inverse_converter;
ok( num_equal(&$inverse_converter(325.24), 382.095239027303), "ScanEvent->converter");
ok( num_equal(&$converter(382.095239027303), 325.24), "ScanEvent->converter");

# read the second ScanEvent record
$scan_event = Finnigan::ScanEvent->decode( \*INPUT, $header->version );
is( $scan_event->preamble->analyzer('decode'), "ITMS", "ScanEvent->preamble->analyzer (2)" );
is( $scan_event->preamble->polarity('decode'), "positive", "ScanEvent->preamble->polarity (2)" );
is( $scan_event->preamble->scan_mode('decode'), "profile", "ScanEvent->preamble->scan_mode (2)" );
is( $scan_event->preamble->dependent, 1, "ScanEvent->preamble->dependent (2)" );
is( $scan_event->preamble->scan_type('decode'), "Full", "ScanEvent->preamble->scan_type (2)" );
is( $scan_event->preamble->ms_power('decode'), "MS2", "ScanEvent->preamble->ms_power (2)" );
is( "$scan_event", 'ITMS + p ESI d Full ms2 445.12@cid35.00 [110.00-460.00]', "ScanEvent->preamble->stringify (2)" );
is( $scan_event->preamble->corona('decode'), "undefined", "ScanEvent->preamble->corona (2)" );
is( $scan_event->preamble->wideband('decode'), "Off", "ScanEvent->preamble->wideband (2)" );
is( $scan_event->fraction_collector->stringify, "[110.00-460.00]", "ScanEvent->fraction_collector->stringify (2)" );
is( $scan_event->np, 1, "ScanEvent->np" );
my $pr = join ", ", map {"$_"} @{$scan_event->precursors};
is( $pr, '445.12@cid35.00', "ScanEvent->precursors (2)" );
$Finnigan::activationMethod = 'ecd'; # cos we don't know where to look for it
$pr = $scan_event->reaction->stringify;
is( $pr, '445.12@ecd35.00', "ScanEvent->precursors (2): setting the activation method)" );
ok( num_equal( $scan_event->reaction->precursor, 445.121063232422), "ScanEvent->reaction, Reaction->precursor" );
ok( num_equal($scan_event->reaction(0)->precursor, 445.121063232422), "ScanEvent->reaction(0), Reaction->precursor" );
is( $scan_event->reaction->energy, 35, "ScanEvent->reaction, Reaction->energy" );
for my $i (3 .. $nrecords) { # skip to the last ScanEvent
  $scan_event = Finnigan::ScanEvent->decode( \*INPUT, $header->version );
}
is( tell INPUT, $params_addr, "should have arrived at the start of ScanParameters stream" );

# Finally reach ScanParameters. Test these, then return to scan data.
my $p = Finnigan::ScanParameters->decode(\*INPUT, $scan_parameters_header->field_templates);
is( $p->charge_state, 1, "ScanParameters->charge_state (type 6)" );
ok( num_equal($p->injection_time, 200.0), "ScanParameters->injection_time (type 10)" );
# skip to the MS2 scan
$p = Finnigan::ScanParameters->decode(\*INPUT, $scan_parameters_header->field_templates);
ok( num_equal($p->monoisotopic_mz, 445.121063232), "ScanParameters->monoisotopic_mz (type 11)" );
for my $i (3 .. $nrecords) { # skip to the end of file
  my $p = Finnigan::ScanParameters->decode(\*INPUT, $scan_parameters_header->field_templates);
}
is( $p->charge_state, 1, "ScanParameters->charge_state (type 6)" );
is( $p->scan_segment, 1, "ScanParameters->scan_segment (type 6)" );
is( $p->scan_event, 2, "ScanParameters->scan_event (type 6)" );
is( tell INPUT, 848001, "should have arrived at the null stream near the end of the file" );

# Read the null stream
my $length = Finnigan::Decoder->read(\*INPUT, ['length' => ['V', 'UInt32']])->{data}->{length}->{value};
is( $length, 0, "the stream at the end of the file should have zero size" );
is( eof INPUT, 1, "should get EOF on the stream handle" );


# ----------------------------------------------------------------------
#
#  Now back to the data stream
# 
# ----------------------------------------------------------------------
# the first ScanDataPacket
seek INPUT, $data_addr, 0;
is( tell INPUT, 24950, "seek to scan data address" );

# PacketHeader
my $ph = Finnigan::PacketHeader->decode( \*INPUT );
is( $ph->{data}->{"unknown long[1]"}->{value}, 1, "PacketHeader->{unknown long[1]}" );
is( $ph->profile_size, 5624, "PacketHeader->profile_size" );
is( $ph->peak_list_size, 1161, "PacketHeader->peak_list_size" );
is( $ph->layout, 128, "PacketHeader->layout" );
is( $ph->descriptor_list_size, 580, "PacketHeader->descriptor_list_size" );
is( $ph->size_of_unknown_stream, 581, "PacketHeader->size_of_unkonwn_stream" );
is( $ph->size_of_triplet_stream, 27, "PacketHeader->size_of_triplet_stream" );
is( $ph->{data}->{"unknown long[2]"}->{value}, 0, "PacketHeader->{unknown long[2]}" );
ok( num_equal($ph->low_mz, 400.0), "PacketHeader->low_mz" );
ok( num_equal($ph->high_mz, 2000.0), "PacketHeader->high_mz" );

# Profile
my $profile = Finnigan::Profile->decode( \*INPUT, $ph->layout );
is( $profile->nchunks, 580, "Profile->nchunks");
is( $profile->nbins, 293046, "Profile->nbins");
ok( num_equal($profile->first_value, 344.543619791667), "Profile->first_value");
ok( num_equal($profile->step, -0.000651041666666667), "Profile->first_value");
# ProfileChunk
is( ref $profile->chunk->[0], "Finnigan::ProfileChunk", "ref Profile->chunk->[0]" );
is( $profile->chunk->[0]->nbins, 5, "ProfileChunk->nbins" );
is( $profile->chunk->[0]->first_bin, 139, "ProfileChunk->first_bin" );
ok( num_equal($profile->chunk->[0]->fudge, 0.000183502677828074), "ProfileChunk->fudge" );
ok( num_equal($profile->chunk->[0]->signal->[4], 627.37109375), "ProfileChunk->signal" );
# Profile again
$profile->set_converter( $converter ); # from ScanEvent 1 above
my $bins = $profile->bins;
ok( num_equal($bins->[0]->[0], 400.209152455266), "Profile->bins->[0] (Mz)" );
ok( num_equal($bins->[0]->[1], 447.530578613281), "Profile->bins->[0] (signal)" );
ok( num_equal($bins->[-1]->[0], 1993.75819323833), "Profile->bins->[-1] (Mz)" );
ok( num_equal($bins->[-1]->[1], 590.111206054688), "Profile->bins->[-1] (signal)" );
# Peaks
my $c = Finnigan::Peaks->decode(\*INPUT);
is( $c->count, 580, "Peaks->count" );
ok( num_equal($c->peak->[0]->mz, 400.212463378906), "first Peak->mz" );
ok( num_equal($c->peak->[0]->abundance, 1629.47326660156), "first Peak->abundance" );
ok( num_equal($c->peak->[-1]->mz, 1993.72521972656), "last Peak->mz" );
ok( num_equal($c->peak->[-1]->abundance, 1015.48522949219), "last Peak->abundance" );

# Go back to the first scan and re-read with the compound decoder
seek INPUT, $data_addr, 0;
is( tell INPUT, 24950, "seek to scan data address (2)" );

my $scan = Finnigan::Scan->decode( \*INPUT );
is( $scan->header->profile_size, 5624, "Scan->header->profile_size" );
$profile = $scan->profile;
$profile->set_converter( $converter ); # from ScanEvent 1 above
$bins = $profile->bins;
ok( num_equal($bins->[0]->[0], 400.209152455266), "Scan->profile->bins; Mz" );
ok( num_equal($bins->[0]->[1], 447.530578613281), "Scan->profile->bins; signal" );
# $bins = $profile->bins(undef, 'add zeroes');
# use Data::Dumper;
# diag(Dumper($bins));
# ok( num_equal($bins->[0]->[0], 400.209152455266), "Scan->profile->bins; Mz" );

$c = $scan->centroids;
$c->{'scan number'} = 1; # to support scan number reporting inside Scan::find_peak_intensity()
$c->{'dependent scan number'} = 2;
is( $c->count, 580, "Scan->centroids->count" );
ok( num_equal($c->list->[0]->[0], 400.212463378906), "Scan->centroids->list (Mz)" );
ok( num_equal($c->list->[0]->[1], 1629.47326660156), "Scan->centroids->list (abundance)" );
is( ($c->find_peak(1622.96887207031))[0], 538, "Scan->find_peak, exact match" );
is( ($c->find_peak(1622.968))[0], 538, "Scan->find_peak, off a bit" );
is( ($c->find_peak(1622.6))[0], undef, "Scan->find_peak, far off" );
ok( num_equal($c->find_peak_intensity(1622.968), 232378.640625), "Scan->find_peak_intensity, off a bit" );
is( $c->find_peak_intensity(1622.6), 0, "Scan->find_peak_intensity, far off" );

# fast-forward to ScanIndex
seek INPUT, $scan_index_addr, 0;
is( tell INPUT, 829706, "seek to scan index address" );
