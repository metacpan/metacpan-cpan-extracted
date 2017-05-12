use Test::More tests => 63;
BEGIN { require 't/test_setup.pl'; }

my $soi   = "\377\330";
my $eoi   = "\377\331";
my $sos   = "\377\332";
my $com   = "\377\376";
my $len   = "\000\010";
my $first = "\001";
my $last  = "\077";
my $esel  = "\111";
my $forged_sos = "${first}\011${esel}\277\321${last}";
my $name  = "fancydir";
my $data  = "xyz";
my ($segment, $record, $handle, $mem, $result, $dirrec, $problem);
my $trim = sub { join '\n', map { s/^.*\"(.*)\".*$/$1/; $_ }
		 grep { /0:/ } split '\n', $_[0] };
sub reset_mem { close $handle if $handle; open($handle, '>', \$mem); }
sub trap_warn { local $SIG{'__WARN__'} = sub { $problem = shift }; 
		$problem = undef; eval($_[0]); }
	       
#=======================================
diag "Testing [Image::MetaData::JPEG::Segment]";
#=======================================

BEGIN { use_ok ($::tabname, qw(:RecordTypes :TagsAPP0)) or exit; }
BEGIN { use_ok ($::segname) or exit; } # this must be loaded second!

#########################
$segment = newsegment('APP1', \ $forged_sos);
ok( $segment, "APP1 segment created" );

#########################
isa_ok( $segment, $::segname );

#########################
ok( $segment->{error}, "... with error flag set" );

#########################
eval { $segment->update() };
isnt( $@, '', "a faulty segment cannot be updated" );

eval { newsegment(undef, 'COM', undef) };
isnt( $@, '', "Error OK: " . &$trim($@));

#########################
eval { newsegment('COM', undef) };
is( $@, '', "ctor survives to undef data" );

#########################
$segment = newsegment('COM', \ $forged_sos);
ok( $segment, "Comment segment created" );

#########################
ok( ! $segment->{error}, "... with error flag unset" );

#########################
ok( exists $segment->{records}, "the 'records' container exists" );

#########################
ok( exists $segment->{name}, "the 'name' member exists" );

#########################
$record = $segment->search_record('Comment');
ok( $record, "'Comment' record found" );

#########################
isa_ok( $record, "${main::pkgname}::Record" );

#########################
$segment = newsegment('SOS', \ $forged_sos);
ok( $segment, "Forged SOS segment created" );
# This is the structure of the segment:
# [           ScanComponents]<......> = [     BYTE]  1
# [        ComponentSelector]<......> = [     BYTE]  1
# [          EntropySelector]<......> = [  NIBBLES]  0 0
# [   SpectralSelectionStart]<......> = [     BYTE]  0
# [     SpectralSelectionEnd]<......> = [     BYTE]  63
# [ SuccessiveAp...tPosition]<......> = [  NIBBLES]  0 0

#########################
ok( ! $segment->{error}, "... with error flag unset" );

#########################
is( scalar $segment->search_record('EntropySelector')->get(), $esel,
    "search_record with tag works" );

#########################
is( scalar $segment->search_record('FIRST_RECORD')->get(), $first,
    "search_record with 'FIRST_RECORD' works" );

#########################
is( scalar $segment->search_record('LAST_RECORD')->get(),  $last,
    "search_record with 'LAST_RECORD' works" );

#########################
$result = $segment->search_record();
is( $result->get_value(), $segment->{records},
    "search_record() without args gives a fake root record" );

#########################
$result = $segment->search_record_value();
is( $result, $segment->{records},
    "search_record_value() without args gives root" );

#########################
trap_warn('$segment->update()');
like( $problem, qr/[Rr]everting/, "you cannot 'update' this yet" );

#########################
$segment->reparse_as('COM');
ok( ! $segment->{error}, "a SOS can be reparsed as a COM" );

#########################
$segment->reparse_as('APP2');
ok( $segment->{error}, "... but not as an APP2" );

#########################
$segment->reparse_as('SOS'); reset_mem(); 
$result = $segment->output_segment_data($handle);
ok( $result, "output_segment_data does not fail" );

#########################
is( $mem, "${sos}${len}${forged_sos}",
    "... and its return value is correct" );

#########################
isnt( $segment->get_description(), undef, "get_description gives non-undef" );

#########################
$segment = newsegment('APP1', \ $forged_sos, 'NOPARSE');
ok( ! $segment->{error}, "NOPARSE actually avoids parsing" );

#########################
eval { $segment->update() };
isnt( $@, '', "... but then you cannot update" );

#########################
$segment = newsegment('COM');
reset_mem(); $result = $segment->output_segment_data($handle);
is( $mem, "$com\000\002", "output_segment_data works with empty comments" );

#########################
$segment->search_record('Comment')->set_value('*' x 2**16);
trap_warn('$segment->update()');
like( $problem, qr/[Rr]everting/, "size check works in forged comment" );

#########################
$segment = newsegment('COM', \ '');
$segment->search_record('Comment')->set_value('*' x 2**16);
trap_warn('$segment->update()');
like( $problem, qr/[Rr]everting/, "size check works in forged comment (2)" );

#########################
$segment = newsegment('ECS', \ $forged_sos);
reset_mem(); $segment->output_segment_data($handle);
is( $mem, $forged_sos, "Raw output for raw data" );

#########################
$segment = newsegment('Post-EOI', \ $forged_sos);
reset_mem(); $segment->output_segment_data($handle);
is( $mem, $forged_sos, "Raw output for Post-EOI data" );

#########################
$segment = newsegment('SOI');
reset_mem(); $segment->output_segment_data($handle);
is( $mem, $soi, "Correct output for SOI" );

#########################
$segment = newsegment('EOI');
reset_mem(); $segment->output_segment_data($handle);
is( $mem, $eoi, "Correct output for EOI" );

#########################
$segment->provide_subdirectory($name);
$dirrec = $segment->search_record($name);
isnt( $dirrec, undef, "'$name' creation ok" );

#########################
is_deeply( $dirrec->get_value(), [], "... it is an empty array" );

#########################
$dirrec = $segment->search_record_value($name);
$segment->provide_subdirectory($name.$name, $dirrec);
$dirrec = $segment->search_record_value($name.$name, $dirrec);
is_deeply( $dirrec, [], "'$name$name' creation ok" );

#########################
$dirrec = $segment->search_record($name.$name);
is( $dirrec, undef, "... it is not in the root dir" );

#########################
$dirrec = $segment->search_record_value($name);
$segment->provide_subdirectory($name, $dirrec);
$dirrec = $segment->search_record_value($name.'@'.$name);
is_deeply( $dirrec, [], "'$name\@$name' creation ok" );

#########################
$result = $segment->search_record_value($name, $name);
is_deeply( $dirrec, $result, "... search_record alternative syntax OK" );

#########################
$segment = newsegment('APP8', \ '', 'NOPARSE');
$dirrec = $segment->provide_subdirectory('A@B@C');
$record = $segment->search_record_value('A', '', 'B@', '@', '@C');
is( $dirrec, $record, "Spurious args in search_record_value() ignored" );

#########################
$dirrec = $segment->provide_subdirectory('AA@@', 'BB@CC', undef, 'DD');
$record = $segment->search_record_value('AA@BB@CC@DD');
is( $dirrec, $record, "Spurious args in provide_subdirectory() ignored" );

#########################
$dirrec = $segment->provide_subdirectory('a@b@c');
$record = $segment->search_record_value(undef, 'a', '', 'b@', '@c', undef);
is( $dirrec, $record, "search_record_value() resists to undef's" );

#########################
$dirrec = $segment->provide_subdirectory(undef, 'aa@', '@bb@cc', undef);
$record = $segment->search_record_value('aa@bb@cc');
is( $dirrec, $record, "provide_subdirectory() resists to undef's" );

#########################
$record = $segment->create_record('uno', $ASCII, \ $data);
is( $record->get_value(), $data, "create_record ok [ref]" );

#########################
$segment = newsegment('COM', \ $data);
$record = $segment->create_record('uno', $ASCII, 0, length $data);
is( $record->get_value(), $data, "create_record ok [offset]" );

#########################
$result = $segment->read_record($ASCII, \ $data);
is( $result, $data, "read_record   ok [ref]" );

#########################
$result = $segment->read_record($ASCII, 0, length $data);
is( $result, $data, "read_record   ok [offset]" );

#########################
$dirrec = $segment->provide_subdirectory($name);
$result = $segment->store_record($dirrec, 'due', $ASCII, 0, length $data);
is( $result->get_value(), $data, "store_record  ok [ref]" );

#########################
$segment->store_record($dirrec, 'tre', $ASCII, \ $data);
$result = $segment->search_record_value('tre', $dirrec);
is( $result, $data, "store_record  ok [offset]" );

#########################
$segment = newsegment('APP0', \ ($APP0_JFXX_TAG . chr($APP0_JFXX_1B).
				    "\100\040". 'x' x ($APP0_JFXX_PAL+2048)) );
is( $segment->{error}, undef, "The faboulous 1B-JFXX APP0 segment" );

######################### Patent-covered, impossible-to-find segments
$segment = newsegment('DAC', \ "\012\345\274\333");
is( $segment->{error}, undef, "A fake DAC segment" );

#########################
$segment = newsegment('DAC', \ "\012\345\274");
isnt( $segment->{error}, undef, "An invalid DAC segment" );

#########################
$segment = newsegment('EXP', \ "\345");
is( $segment->{error}, undef, "A fake EXP segment" );

#########################
$segment = newsegment('EXP', \ "\012\345");
isnt( $segment->{error}, undef, "An invalid EXP segment" );

#########################
$segment = newsegment('DNL', \ "\012\345");
is( $segment->{error}, undef, "A fake DNL segment" );

#########################
$segment = newsegment('DNL', \ "\012\345\274");
isnt( $segment->{error}, undef, "An invalid DNL segment" );

#########################
{ local $SIG{'__WARN__'} = sub { $problem = shift; };
  $problem = undef; $segment->warn('Fake warning'); }
ok( $problem, "Generation of warning reports works" );

#########################
{ local $SIG{'__WARN__'} = sub { $problem = shift; };
  eval '$'."$::pkgname".'::show_warnings = undef';
  $problem = undef; $segment->warn('Fake warning');
  eval '$'."$::pkgname".'::show_warnings = 1'; }
ok( ! $problem, "Generation of warnings can be inhibited" );

#########################
$segment = newsegment('DNL', \ "\012\345\274");
{ local $SIG{'__DIE__'} = sub { $problem = shift; };
  $problem = undef; eval{$segment->update()}; }
ok( $problem, "Generation of error reports works" );

#########################
{ local $SIG{'__DIE__'} = sub { $problem = shift; };
  eval '$'."$::segname".'::show_warnings = undef';
  $problem = undef; eval{$segment->update()};
  eval '$'."$::segname".'::show_warnings = 1'; }
ok( $problem, "Generation of errors cannot be inhibited" );

### Local Variables: ***
### mode:perl ***
### End: ***
