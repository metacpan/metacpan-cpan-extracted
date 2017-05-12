use Test::More tests => 34;
BEGIN { require 't/test_setup.pl'; }

my $tphoto = 't/test_photo.jpg';
my ($image, $hash, $bighash, $date);

#=======================================
diag "Testing APP13 IPTC format checker";
#=======================================

BEGIN { use_ok ($::pkgname) or exit; }

#########################
$image = newimage($tphoto);
$hash = $image->set_app13_data({ 80 => "ciao" }); # ByLine
is( scalar keys %$hash, 0, "regular tag" );

#########################
$hash = $image->set_app13_data({ 1 => "ciao" });
is( scalar keys %$hash, 1, "unknown numeric tag" );

#########################
$hash = $image->set_app13_data({ -3 => "ciao" });
is( scalar keys %$hash, 1, "negative tag" );

#########################
$hash = $image->set_app13_data({ 313 => "ciao" });
is( scalar keys %$hash, 1, "tag larger than 255" );

#########################
$hash = $image->set_app13_data({ "XYZ" => "ciao" });
is( scalar keys %$hash, 1, "unkwnon textual tag" );

#########################
$hash = $image->set_app13_data({ 80 => [] });
is( scalar keys %$hash, 1, "value array with zero elements" );

#########################
$hash = $image->set_app13_data({ 90 => ["Milano", "Roma"] }); # City
is( scalar keys %$hash, 1, "non repeateable tag (1)" );

#########################
$hash = $image->set_app13_data({ 90 => "Roma" });
is( scalar keys %$hash, 0, "non repeateable tag (2)" );

#########################
$hash = $image->set_app13_data({ 45 => "ciao" }); # RefereceService
is( scalar keys %$hash, 1, "invalid tag" );

#########################
$hash = $image->set_app13_data({ 125 => "\001\377\013" }); # RasterizedCaption
is( scalar keys %$hash, 1, "binary tag not passing because of length" );

#########################
$hash = $image->set_app13_data({ 125 => "z" x 7360 });
is( scalar keys %$hash, 0, "binary tag now passing" );

#########################
$hash = $image->set_app13_data({ 135 => 'I' }); # LanguageIdentifier
is( scalar keys %$hash, 1, "length too small" );

#########################
$hash = $image->set_app13_data({ 135 => "IT" });
is( scalar keys %$hash, 0, "length OK (1)" );

#########################
$hash = $image->set_app13_data({ 135 => "ITA" });
is( scalar keys %$hash, 0, "length OK (2)" );

#########################
$hash = $image->set_app13_data({ 135 => "ITAL" });
is( scalar keys %$hash, 1, "length too large" );

#########################
$hash = $image->set_app13_data({ 3 => "ciao:ate" }); # ObjectTypeReference
is( scalar keys %$hash, 1, "invalid regex (1)" );

#########################
$hash = $image->set_app13_data({ 3 => "riga\nacapo" }); # ObjectName
is( scalar keys %$hash, 1, "invalid regex (2)" );

#########################
$hash = $image->set_app13_data({ 10 => 9 }); # Urgency
is( scalar keys %$hash, 1, "invalid regex (3)" );

#########################
$hash = $image->set_app13_data({ 120 => "uno\fdue" }); # Caption/Abstract
is( scalar keys %$hash, 1, "form feed not allowed in 'paragraph'" );

#########################
$date = "19920223";
$hash = $image->set_app13_data({'ReleaseDate' => $date,
				'ExpirationDate' => $date,
				'DigitalCreationDate' => $date,
				'DateCreated' => $date}, 'ADD', 'IPTC');
is( scalar keys %$hash, 0, "Dates in the 20th century accepted" );

#########################
$date = "18620223";
$hash = $image->set_app13_data({'ReleaseDate' => $date,
				'ExpirationDate' => $date,
				'DigitalCreationDate' => $date,
				'DateCreated' => $date}, 'ADD', 'IPTC');
is( scalar keys %$hash, 0, "Dates in the 19th century accepted" );

#########################
$date = "17500223";
$hash = $image->set_app13_data({'ExpirationDate' => $date,
				'DigitalCreationDate' => $date,
				'ReleaseDate' => $date}, 'ADD', 'IPTC');
is( scalar keys %$hash, 3, "Dates in the 18th century not accepted" );

#########################
$hash = $image->set_app13_data({'DateCreated' => $date}, 'ADD', 'IPTC');
is( scalar keys %$hash, 0, "... except in DateCreated" );

#########################
$date = "07500223";
$hash = $image->set_app13_data({'DateCreated' => $date}, 'ADD', 'IPTC');
is( scalar keys %$hash, 0, "DateCreated accepts also the 1st millennium" );

#########################
$date = "00750223";
$hash = $image->set_app13_data({'DateCreated' => $date}, 'ADD', 'IPTC');
is( scalar keys %$hash, 0, "... and the 1st century" );

#########################
$date = "00000101";
$hash = $image->set_app13_data({'DateCreated' => $date}, 'ADD', 'IPTC');
is( scalar keys %$hash, 0, "... and the very early days" );

#########################
$bighash = {
    'RecordVersion'               => "\000\002",
    'ObjectTypeReference'         => "23:ciao a te",
    'ObjectAttributeReference'    => "234:ciao a te",
    'ObjectName'                  => "nome",
    'EditorialUpdate'             => "01",
    'Urgency'                     => 3,
    'SubjectReference'            => "IPTC:12345678:alpha:beta:gamma",
    'Category'                    => "ao",
    'SupplementalCategory'        => [ "alci", "daini", "capri oli" ],
    'FixtureIdentifier'           => "paperino",
    'ContentLocationCode'         => "ABC",
    'ReleaseDate'                 => "19341230",
    'ReleaseTime'                 => "130612+0100",
    'ActionAdvised'               => "03",
    'ObjectCycle'                 => 'p',
    'Country/PrimaryLocationCode' => "ITA",
    'Caption/Abstract'            => "line 1\nline 2\n\rline 3",
    'RasterizedCaption'           => "\013" x 7360,
    'ImageType'                   => "9R",
    'ImageOrientation'            => 'L',
    'LanguageIdentifier'          => "it",
    'AudioType'                   => "1M",
    'AudioSamplingRate'           => 928346,
    'AudioSamplingResolution'     => 20,
    'AudioDuration'               => 121325 };
$hash = $image->set_app13_data($bighash);
is( scalar keys %$hash, 0, "a group of valid tags" );

#########################
$image->provide_app13_segment('IPTC_1');
$hash = $image->set_app13_data({5 => "Paperopoli"}, 'ADD', 'IPTC_1'); 
is( scalar keys %$hash, 0, "regular tag (IPTC_1)" ); # Destination

#########################
$hash = $image->set_app13_data({30 => ["Fax", "Tel"]}, 'ADD', 'IPTC_1');
is( scalar keys %$hash, 1, "non repeateable tag (IPTC_1)" ); # ServIdent

#########################
$hash = $image->set_app13_data({60 => 8}, 'ADD', 'IPTC_1');
is( scalar keys %$hash, 1, "invalid tag (IPTC_1)" ); # Envelope priority

#########################
$hash = $image->set_app13_data({3 => "some where"}, 'ADD', 'IPTC_1'); # Dest.
is( scalar keys %$hash, 1, "invalid regex (1, IPTC_1), no spaces allowed" );

#########################
$hash = $image->set_app13_data({90 => "ABC"}, 'ADD', 'IPTC_1');
is( scalar keys %$hash, 1, "invalid regex (2, IPTC_1)" ); # Character set

#########################
$bighash = {'ModelVersion'      => "\000\007",
	    'Destination'       => [ 'Reggio_Emilia', 'Roma' ],
	    'ServiceIdentifier' => 'Telephone',
	    'ProductID'         => [ 'beautiful', 'wonderful' ],
	    'CodedCharacterSet' => "\033\045G" };
$hash = $image->set_app13_data($bighash, 'ADD', 'IPTC_1');
is( scalar keys %$hash, 0, "a group of valid tags (IPTC_1)" );

### Local Variables: ***
### mode:perl ***
### End: ***
