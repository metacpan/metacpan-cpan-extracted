#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM' );
    use_ok( 'HTML::Object::DOM::Element::Input' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::Element::Input' );
};

use strict;
use warnings;

can_ok( 'HTML::Object::DOM::Element::Input', 'accept' );
can_ok( 'HTML::Object::DOM::Element::Input', 'accept' );
can_ok( 'HTML::Object::DOM::Element::Input', 'align' );
can_ok( 'HTML::Object::DOM::Element::Input', 'allowdirs' );
can_ok( 'HTML::Object::DOM::Element::Input', 'alt' );
can_ok( 'HTML::Object::DOM::Element::Input', 'autocapitalize' );
can_ok( 'HTML::Object::DOM::Element::Input', 'autocomplete' );
can_ok( 'HTML::Object::DOM::Element::Input', 'autofocus' );
can_ok( 'HTML::Object::DOM::Element::Input', 'checked' );
can_ok( 'HTML::Object::DOM::Element::Input', 'defaultChecked' );
can_ok( 'HTML::Object::DOM::Element::Input', 'defaultValue' );
can_ok( 'HTML::Object::DOM::Element::Input', 'dirName' );
can_ok( 'HTML::Object::DOM::Element::Input', 'disabled' );
can_ok( 'HTML::Object::DOM::Element::Input', 'files' );
can_ok( 'HTML::Object::DOM::Element::Input', 'form' );
can_ok( 'HTML::Object::DOM::Element::Input', 'formAction' );
can_ok( 'HTML::Object::DOM::Element::Input', 'formEnctype' );
can_ok( 'HTML::Object::DOM::Element::Input', 'formMethod' );
can_ok( 'HTML::Object::DOM::Element::Input', 'formNoValidate' );
can_ok( 'HTML::Object::DOM::Element::Input', 'formTarget' );
can_ok( 'HTML::Object::DOM::Element::Input', 'height' );
can_ok( 'HTML::Object::DOM::Element::Input', 'indeterminate' );
can_ok( 'HTML::Object::DOM::Element::Input', 'inputmode' );
can_ok( 'HTML::Object::DOM::Element::Input', 'labels' );
can_ok( 'HTML::Object::DOM::Element::Input', 'list' );
can_ok( 'HTML::Object::DOM::Element::Input', 'max' );
can_ok( 'HTML::Object::DOM::Element::Input', 'maxLength' );
can_ok( 'HTML::Object::DOM::Element::Input', 'min' );
can_ok( 'HTML::Object::DOM::Element::Input', 'minLength' );
can_ok( 'HTML::Object::DOM::Element::Input', 'mozGetFileNameArray' );
can_ok( 'HTML::Object::DOM::Element::Input', 'mozSetFileArray' );
can_ok( 'HTML::Object::DOM::Element::Input', 'multiple' );
can_ok( 'HTML::Object::DOM::Element::Input', 'name' );
can_ok( 'HTML::Object::DOM::Element::Input', 'pattern' );
can_ok( 'HTML::Object::DOM::Element::Input', 'placeholder' );
can_ok( 'HTML::Object::DOM::Element::Input', 'readOnly' );
can_ok( 'HTML::Object::DOM::Element::Input', 'required' );
can_ok( 'HTML::Object::DOM::Element::Input', 'selectionDirection' );
can_ok( 'HTML::Object::DOM::Element::Input', 'selectionEnd' );
can_ok( 'HTML::Object::DOM::Element::Input', 'selectionStart' );
can_ok( 'HTML::Object::DOM::Element::Input', 'size' );
can_ok( 'HTML::Object::DOM::Element::Input', 'src' );
can_ok( 'HTML::Object::DOM::Element::Input', 'step' );
can_ok( 'HTML::Object::DOM::Element::Input', 'stepDown' );
can_ok( 'HTML::Object::DOM::Element::Input', 'stepUp' );
can_ok( 'HTML::Object::DOM::Element::Input', 'type' );
can_ok( 'HTML::Object::DOM::Element::Input', 'useMap' );
can_ok( 'HTML::Object::DOM::Element::Input', 'validationMessage' );
can_ok( 'HTML::Object::DOM::Element::Input', 'validity' );
can_ok( 'HTML::Object::DOM::Element::Input', 'value' );
can_ok( 'HTML::Object::DOM::Element::Input', 'valueAsDate' );
can_ok( 'HTML::Object::DOM::Element::Input', 'valueAsNumber' );
can_ok( 'HTML::Object::DOM::Element::Input', 'webkitdirectory' );
can_ok( 'HTML::Object::DOM::Element::Input', 'webkitEntries' );
can_ok( 'HTML::Object::DOM::Element::Input', 'width' );
can_ok( 'HTML::Object::DOM::Element::Input', 'willValidate' );

done_testing();

__END__
