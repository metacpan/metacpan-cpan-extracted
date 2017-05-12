use Test::More tests => 46;
BEGIN { require 't/test_setup.pl'; }

my $cphoto = 't/test_photo_copy.jpg';
my $ref    = '\[REFERENCE\].*-->.*$';
my ($image, $image2, $warning, $error, $fname, $hash,
    $seg, $dir, $format, @desc1, @desc2);
sub trap_errors { local $SIG{'__DIE__'} = sub { $error .= shift; }; 
		  local $SIG{'__WARN__'} = sub { $warning .= shift; };
		  $warning = $error = undef; eval $_[0]; }

# A: non-IFD MakerNote (e.g., Kodak)
# B: MakerNote with an unknown or not supported format
# C: MakerNote with its own TIFF header
# D: MakerNote basing offsets at the beginning of the note itself
# E: MakerNote with IFD format without a next_link field
# F: endianness different from that of the main TIFF header
# G: MakerNote with repeated records (placeholders)
# H: prediction mechanism used (and solving the problem)
# I: prediction mechanism used (not solving the problem)
my %table =
    # filename (partial)    n.tags  format   predictions # A B C D E F G H I
    ('Kodak_DX3900.jpg'    => [44, 'Kodak'   , 'ok'  ],  # x
     'Toshiba_PDRM70.jpg'  => [ 0, 'unknown' , 'ok'  ],  #   x
     'Nikon_D70.jpg'       => [42, 'Nikon_3' , 'ok'  ],  #     x
     'Pentax_Optio430.jpg' => [27, 'Pentax_1', 'pred'],  #       x       x
     'Canon_PShotS330.jpg' => [11, 'Canon'   , 'ok'  ],  #           x x
     'Sony_MVC-CD500.jpg'  => [ 8, 'Sony'    , 'bad' ],  #         x       x
);

#=======================================
diag "Testing APP1 MakerNote parse / dump";
#=======================================

BEGIN { use_ok ($::tabname, qw(:Lookups)) or exit; }
BEGIN { use_ok ($::pkgname) or exit; } # this must be loaded second!

###########################
for $fname (keys %table) {

    #########################
    trap_errors('$image = newimage("t/mknt_$fname")');
    ok( $image, "($fname)" );
    
    #########################
    $hash = $image->get_Exif_data('MAKERNOTE_DATA');
    is( scalar keys %$hash, $table{$fname}->[0], " |  number of records" );

    #########################
    like( $$hash{'PrintIM_Data'}[0], qr/^PrintIM/, " |  PrintIM tag OK" )
	if exists $$hash{'PrintIM_Data'};

    #########################
    $seg = $image->retrieve_app1_Exif_segment();
    $dir = $seg->search_record_value('IFD0@SubIFD');
    $dir = (grep { $_->{key} =~ /^MakerNoteData/ } @$dir)[0]->get_value();
    $format = $seg->search_record_value('special@FORMAT', $dir);
    is( $format, $table{$fname}->[1], " |  detection of format ($format)" );

    #########################
    $error = $seg->search_record_value('special@ERROR', $dir);
    $table{$fname}->[2] =~ /bad/ ?
	isnt( $error, undef, " |  this is a corrupted MakerNote" ) :
	is( $error, undef, " |  no error detected" );

    #########################
    like( $warning, qr/Using predictions/, " |  prediction mech. used" )
	if $table{$fname}->[2] =~ /pred|bad/;
    like( $warning, qr/Predictions failed/, " |  but failed to mend MkNote" )
	if $table{$fname}->[2] eq 'bad';
    is( $warning, undef, " |  prediction mech. not used" )
	if $table{$fname}->[2] eq 'ok';

    #########################
    $seg->update();
    trap_errors('$image->save($cphoto)');
    is( $error, undef, " |  no errors while saving" );

    #########################
    trap_errors('$image2 = newimage($cphoto)');
    @desc1 = map { s/$ref//; $_ } split /\n/, $image->get_description();
    @desc2 = map { s/$ref//; $_ } split /\n/, $image2->get_description();
    is( @desc1, @desc2, " `- description OK after saving" );

    unlink $cphoto;

}

### Local Variables: ***
### mode:perl ***
### End: ***
