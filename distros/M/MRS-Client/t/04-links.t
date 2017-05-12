#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 2;

#-----------------------------------------------------------------
# Return a fully qualified name of the given file in the test
# directory "t/data" - if such file really exists. With no arguments,
# it returns the path of the test directory itself.
# -----------------------------------------------------------------
use FindBin qw( $Bin );
use File::Spec;
sub test_file {
    my $file = File::Spec->catfile ('t', 'data', @_);
    return $file if -e $file;
    $file = File::Spec->catfile ($Bin, 'data', @_);
    return $file if -e $file;
    return File::Spec->catfile (@_);
}

ok(1);
use MRS::Client;
diag( "Manipulation of hyperlinks" );

my $input = test_file ('DNP_DENAN.html');
my $db = MRS::Client->db ('anything');
isnt ($db, undef, 'dummy databank');

#
# _xformat()
#
my $html;
{
    open $FILE, "<", $input
        or die "Can't open '$input': $!\n";
    undef $/;
    $html = <$FILE>;
}
my $xformat = {css_class =>'mrslink'};

$db->_xformat ($xformat, $html);


__END__

my $output = CBRC::Links::Families->new ( family_files => $input );
is (ref $output->{family_files}, 'ARRAY',       'new: fam.files scalar');
is ($output->{family_files}->[0], $input,       'new: fam.files scalar [0]');
$output = CBRC::Links::Families->new ( family_files => [$input, $input] );
is (ref $output->{family_files}, 'ARRAY',       'new: fam.files arrayref');
is ($output->{family_files}->[0], $input,       'new: fam.files arrayref [0]');
is ($output->{family_files}->[1], $input,       'new: fam.files arrayref [1]');
eval {
    $output = CBRC::Links::Families->new ( family_files => {no => 'yes'} );
};
diag ($@);
ok ($@ =~ /Argument 'family_files'/,            'new: error');

#
# families()
#
my $f = CBRC::Links::Families->new (family_files => $input)->families();
ok ($f,                                  'get_families: non-empty');
ok ($f->{CBRC::Links::Families->BY_FAMILY()}, 'get_families: non-empty families');
ok ($f->{CBRC::Links::Families->BY_SOURCE()}, 'get_families: non-empty sources');
my $by_f = $f->{CBRC::Links::Families->BY_FAMILY()};
my $by_s = $f->{CBRC::Links::Families->BY_SOURCE()};
is ($by_f->{'Organism-specific'}->[1], 'agd',    'get_families: by family');
is ($by_s->{'2dbase-ecoli'}->[0],      '2D gel', 'get_families: by source');

__END__
