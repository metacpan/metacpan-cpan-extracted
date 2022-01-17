#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use DateTime;
    use File::Spec;
    use utf8;
    use constant {
        T_SECOND    => 0,
        T_MINUTE    => 1,
        T_HOUR      => 2,
        T_DAY       => 3,
        T_MONTH     => 4,
        T_YEAR      => 5,
        T_WEEKDAY   => 6,
        T_YEARDAY   => 7,
        T_ISDST     => 8,
    };
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM' );
    use_ok( 'HTML::Object::DOM::File' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::File' );
};

can_ok( 'HTML::Object::DOM::File', 'lastModified' );
can_ok( 'HTML::Object::DOM::File', 'lastModifiedDate' );
can_ok( 'HTML::Object::DOM::File', 'name' );
can_ok( 'HTML::Object::DOM::File', 'webkitRelativePath' );
can_ok( 'HTML::Object::DOM::File', 'size' );
can_ok( 'HTML::Object::DOM::File', 'type' );
can_ok( 'HTML::Object::DOM::File', 'slice' );
can_ok( 'HTML::Object::DOM::File', 'stream' );
can_ok( 'HTML::Object::DOM::File', 'text' );
can_ok( 'HTML::Object::DOM::File', 'arrayBuffer' );

my $file = HTML::Object::DOM::File->new( __FILE__ );
my $mtime = [stat(__FILE__)]->[9];
is( $mtime, $file->lastModified, 'lastModified' );
my $dt = $file->lastModifiedDate;
$mtime = [stat(__FILE__)]->[9];
my $dt2 = DateTime->from_epoch( epoch => $mtime );
isa_ok( $dt => 'Module::Generic::DateTime' );
ok( $dt == $dt2, 'lastModifiedDate' );
is( $file->name, [File::Spec->splitpath(__FILE__)]->[2], 'name' );
is( $file->webkitRelativePath, 't/' . [File::Spec->splitpath(__FILE__)]->[2], 'lastModifiedDate' );
is( $file->size, [stat(__FILE__)]->[7], 'size' );
like( $file->type, qr/\w+\/\w+/, 'type' );
# $file->debug( $DEBUG );
is( $file->slice( 7, 12 ), 'BEGIN', 'slice' );
my $fh = $file->stream || diag( $file->error );
# isa_ok( $file->stream, 'IO:Handle', 'stream' );
isa_ok( $fh, 'IO::Handle', 'stream' );
my $text = $file->text;
like( $text, qr/^\#\!perl\nBEGIN/, 'text' );
my $data = $file->arrayBuffer;
ok( !utf8::is_utf8( $data ), 'arrayBuffer' );

done_testing();

__END__

