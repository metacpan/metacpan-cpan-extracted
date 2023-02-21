use strict;
use warnings;
use Test::More;
use HTML::Form;

my ( $form, $input );

sub new_form_and_input {
    $form = HTML::Form->new( 'POST', '/', 'multipart/form-data' );
    $form->push_input( 'file', { name => 'document' } );
    ($input) = $form->inputs;
    return $form, $input;
}

my $file     = 't/file_upload.txt';
my $filename = 'the_uploaded_file.txt';

# Using [$file, $filename] as argument

# $input->value and array refs
( $form, $input ) = new_form_and_input;
$input->value( [ $file, $filename ] );
like(
    $form->make_request->as_string, qr! filename="$filename" !x,
    'Upload: using $input->value([$file, $filename])'
);

# $input->file and array refs
( $form, $input ) = new_form_and_input;
$input->file( [ $file, $filename ] );
like(
    $form->make_request->as_string, qr! filename="$filename" !x,
    'Upload: using $input->file([$file, $filename])'
);

# $form->value and array refs
( $form, $input ) = new_form_and_input;
$form->value( 'document', [ $file, $filename ] );
like(
    $form->make_request->as_string, qr! filename="$filename" !x,
    q/Upload: using $form->value('document', [$file, $filename])/
);

# Using [$file, $filename, Content => 'inline content'] as argument

# $input->value and array refs
( $form, $input ) = new_form_and_input;
$input->value( [ $file, $filename, Content => 'inline content' ] );
like(
    $form->make_request->as_string, qr! filename="$filename" !x,
    q/Upload: using $input->value([$file, $filename, Content => '?'])/
);

# $input->file and array refs
( $form, $input ) = new_form_and_input;
$input->file( [ $file, $filename, Content => 'inline content' ] );
like(
    $form->make_request->as_string, qr! filename="$filename" !x,
    q/Upload: using $input->file([$file, $filename, Content => '?'])/
);

# $input->file and array refs and undef
( $form, $input ) = new_form_and_input;
$input->file( [ undef, $filename, Content => 'inline content' ] );
like(
    $form->make_request->as_string, qr! filename="$filename" !x,
    q/Upload: using $input->file([undef, $filename, Content => '?'])/
);

# $form->value and array refs
( $form, $input ) = new_form_and_input;
$form->value( 'document', [ $file, $filename, Content => 'inline content' ] );
like(
    $form->make_request->as_string, qr! filename="$filename" !x,
    q/Upload: using $form->value('document', [$file, $filename, Content => '?'])/
);

# Using methods (file, filename, content) directly

# 'file' informed directly
( $form, $input ) = new_form_and_input;
$input->file($file);
like(
    $form->make_request->as_string, qr! filename="$file" !x,
    "Upload: 'file' informed directly and used as 'filename'"
);

# 'file' and 'filename' informed directly
( $form, $input ) = new_form_and_input;
$input->file($file);
$input->filename($filename);
like(
    $form->make_request->as_string, qr! filename="$filename" !x,
    "Upload: 'file' and 'filename' informed directly"
);

# 'file', 'filename' and 'content' informed directly
( $form, $input ) = new_form_and_input;
$input->file($file);
$input->filename($filename);
$input->content('inline content');
like(
    $form->make_request->as_string, qr! filename="$filename" !x,
    "Upload: 'file', 'filename' and 'content' informed directly"
);

# undef, 'filename' and 'content' informed directly
( $form, $input ) = new_form_and_input;
$input->filename($filename);
$input->content('inline content');
like(
    $form->make_request->as_string, qr! filename="$filename" !x,
    "Upload: undef, 'filename' and 'content' informed directly"
);

done_testing;
