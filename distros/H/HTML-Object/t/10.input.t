#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM' );
    use_ok( 'HTML::Object::DOM::Element::Input' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::Element::Input' );
};

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

# time
subtest 'time' => sub
{
    my $html = q{<input type="time" max="17:00" step="900" />};
    my $p = HTML::Object::DOM->new;
    my $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
    my $input = $doc->getElementsByTagName('input')->first;
    # $input->debug( $DEBUG );
    # $input->debug( $DEBUG );
    isa_ok( $input => 'HTML::Object::DOM::Element::Input' );
    is( $input->value, undef, 'initial value' );
    my $rv = $input->stepDown;
    my $val = $input->value;
    # diag( "Possibly error: ", $input->error ) if( !defined( $val ) && $DEBUG );
    is( $val, '17:00:00', 'input->stepDown -> 17:00:00' );
    $rv = $input->stepDown;
    $val = $input->value;
    # diag( "Possibly error: ", $input->error ) if( !defined( $val ) && $DEBUG );
    is( $val, '16:45:00', 'input->stepDown -> 16:45:00' );
    
    # Checking when exceeding maximum
    $rv = $input->stepUp(10);
    $val = $input->value;
    is( $val, '16:45:00', 'input->stepUp beyond max -> unchanged' );

    $html = q{<input type="time" min="17:00" step="900" />};
    $p = HTML::Object::DOM->new;
    $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
    $input = $doc->getElementsByTagName('input')->first;
    # $input->debug( $DEBUG );
    isa_ok( $input => 'HTML::Object::DOM::Element::Input' );
    is( $input->value, undef, 'initial value' );
    $input->stepUp;
    $val = $input->value;
    # diag( "Possibly error: ", $input->error ) if( !defined( $val ) && $DEBUG );
    is( $val, '17:00:00', 'input->stepUp -> 17:00:00' );
    $input->stepUp;
    $val = $input->value;
    # diag( "Possibly error: ", $input->error ) if( !defined( $val ) && $DEBUG );
    is( $val, '17:15:00', 'input->stepUp -> 17:15:00' );
    
    # Checking when exceeding minimum
    $rv = $input->stepDown(10);
    $val = $input->value;
    is( $val, '17:15:00', 'input->stepDown beyond min -> unchanged' );
};

subtest 'date' => sub
{
    my $html = q{<input type="date" max="2019-12-25" step="1" />};
    my $p = HTML::Object::DOM->new;
    my $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
    my $input = $doc->getElementsByTagName('input')->first;
    is( $input->value, undef, 'initial value' );
    $input->stepDown;
    my $val = $input->value;
    is( $val, '2019-12-25', 'input->stepDown -> 2019-12-25' );
    $input->stepDown;
    $val = $input->value;
    is( $val, '2019-12-24', 'input->stepDown -> 2019-12-24' );

    # Checking when exceeding maximum
    $rv = $input->stepUp(10);
    $val = $input->value;
    is( $val, '2019-12-24', 'input->stepUp beyond max -> unchanged' );

    my $html = q{<input type="date" min="2019-12-25" step="1" />};
    $p = HTML::Object::DOM->new;
    $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
    $input = $doc->getElementsByTagName('input')->first;
    isa_ok( $input => 'HTML::Object::DOM::Element::Input' );
    is( $input->value, undef, 'initial value' );
    $input->stepUp;
    $val = $input->value;
    is( $val, '2019-12-25', 'input->stepUp -> 2019-12-25' );
    $input->stepUp;
    $val = $input->value;
    is( $val, '2019-12-26', 'input->stepUp -> 2019-12-26' );
    
    # Checking when exceeding minimum
    $rv = $input->stepDown(10);
    $val = $input->value;
    is( $val, '2019-12-26', 'input->stepDown beyond min -> unchanged' );
};

subtest 'month' => sub
{
    my $html = q{<input type="month" max="2019-12" step="3" />};
    my $p = HTML::Object::DOM->new;
    my $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
    my $input = $doc->getElementsByTagName('input')->first;
    is( $input->value, undef, 'initial value' );
    $input->stepDown;
    my $val = $input->value;
    is( $val, '2019-12', 'input->stepDown -> 2019-12' );
    $input->stepDown;
    $val = $input->value;
    is( $val, '2019-09', 'input->stepDown -> 2019-09' );

    # Checking when exceeding maximum
    $rv = $input->stepUp(10);
    $val = $input->value;
    is( $val, '2019-09', 'input->stepUp beyond max -> unchanged' );

    my $html = q{<input type="month" min="2019-12" step="3" />};
    $p = HTML::Object::DOM->new;
    $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
    $input = $doc->getElementsByTagName('input')->first;
    isa_ok( $input => 'HTML::Object::DOM::Element::Input' );
    is( $input->value, undef, 'initial value' );
    # $input->debug( $DEBUG );
    $input->stepUp;
    $val = $input->value;
    is( $val, '2019-12', 'input->stepUp -> 2019-12' );
    $input->stepUp;
    $val = $input->value;
    is( $val, '2020-03', 'input->stepUp -> 2020-03' );
    
    # Checking when exceeding minimum
    $rv = $input->stepDown(10);
    $val = $input->value;
    is( $val, '2020-03', 'input->stepDown beyond min -> unchanged' );
};

subtest 'week' => sub
{
    my $html = q{<input type="week" max="2019-W23" step="2" />};
    my $p = HTML::Object::DOM->new;
    my $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
    my $input = $doc->getElementsByTagName('input')->first;
    is( $input->value, undef, 'initial value' );
    my $rv = $input->stepDown;
    diag( "Error: ", $input->error ) if( !defined( $rv ) && $DEBUG );
    my $val = $input->value;
    is( $val, '2019-W23', 'input->stepDown -> 2019-W23' );
    $rv = $input->stepDown;
    diag( "Error: ", $input->error ) if( !defined( $rv ) && $DEBUG );
    $val = $input->value;
    is( $val, '2019-W21', 'input->stepDown -> 2019-W21' );
    # Reducing by more than 2 years
    $rv = $input->stepDown( 72 );
    diag( "Error: ", $input->error ) if( !defined( $rv ) && $DEBUG );
    $val = $input->value;
    is( $val, '2016-W34', 'input->stepDown -> 2016-W34' );
    
    # Test if trying to decrease below the minimum value is silently rejected
    $input->setAttribute( min => '2016-W33' );
    $rv = $input->stepDown;
    diag( "Error: ", $input->error ) if( !defined( $rv ) && $DEBUG );
    $val = $input->value;
    is( $val, '2016-W34', 'input->stepDown below min -> unchanged' );

    my $html = q{<input type="week" min="2019-W23" step="2" />};
    $p = HTML::Object::DOM->new;
    $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
    $input = $doc->getElementsByTagName('input')->first;
    isa_ok( $input => 'HTML::Object::DOM::Element::Input' );
    is( $input->value, undef, 'initial value' );
    # $input->debug( $DEBUG );
    $rv = $input->stepUp;
    diag( "Error: ", $input->error ) if( !defined( $rv ) && $DEBUG );
    $val = $input->value;
    is( $val, '2019-W23', 'input->stepUp -> 2019-W23' );
    $rv = $input->stepUp;
    diag( "Error: ", $input->error ) if( !defined( $rv ) && $DEBUG );
    $val = $input->value;
    is( $val, '2019-W25', 'input->stepUp -> 2019-W25' );
    
    # Increasing by more than 2 years
    $rv = $input->stepUp( 72 );
    diag( "Error: ", $input->error ) if( !defined( $rv ) && $DEBUG );
    $val = $input->value;
    is( $val, '2022-W13', 'input->stepUp -> 2022-W13' );
    $input->value = '';
};

subtest 'datetime-local' => sub
{
    my $html = q{<input type="datetime-local" max="2019-12-25T19:30:20" step="10" />};
    my $p = HTML::Object::DOM->new;
    my $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
    my $input = $doc->getElementsByTagName('input')->first;
    is( $input->value, undef, 'initial value' );
    my $rv = $input->stepDown;
    diag( "Error: ", $input->error ) if( !defined( $rv ) && $DEBUG );
    my $val = $input->value;
    is( $val, '2019-12-25T19:30:20', 'input->stepDown -> 2019-12-25T19:30:20' );
    
    # With format YYYY-MM-DDTHH:MM only
    $input->value = '2019-12-25T19:30';
    $val = $input->value;
    is( $val, '2019-12-25T19:30', 'input->value set to 2019-12-25T19:30' );
    my $rv = $input->stepDown;
    $val = $input->value;
    is( $val, '2019-12-25T19:29:50', 'input->stepDown -> 2019-12-25T19:29:50' );
    
    # With format YYYY-MM-DDTHH only
    $input->value = '2019-12-25T19';
    $val = $input->value;
    is( $val, '2019-12-25T19', 'input->value set to 2019-12-25T19' );
    my $rv = $input->stepDown;
    $val = $input->value;
    is( $val, '2019-12-25T18:59:50', 'input->stepDown -> 2019-12-25T18:59:50' );
    
    $rv = $input->stepDown;
    diag( "Error: ", $input->error ) if( !defined( $rv ) && $DEBUG );
    $val = $input->value;
    is( $val, '2019-12-25T18:59:40', 'input->stepDown -> 2019-12-25T18:59:40' );
};

subtest 'number' => sub
{
    my $html = q{<input type="number" min="0" step="0.1" max="10" />};
    my $p = HTML::Object::DOM->new;
    my $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
    my $input = $doc->getElementsByTagName('input')->first;
    is( $input->value, undef, 'initial value' );
    my $rv = $input->stepDown;
    my $val = $input->value;
    is( $val, 10, 'input->stepDown -> 10' );
    $rv = $input->stepDown(10);
    $val = $input->value;
    is( $val, 9, 'input->stepDown -> 9' );
    $rv = $input->stepDown(100);
    $val = $input->value;
    is( $val, 9, 'input->stepDown below min -> unchanged' );
    $rv = $input->stepDown;
    $val = $input->value;
    is( $val, 8.9, 'input->stepDown -> 8.9' );
    
    $rv = $input->stepUp(11);
    $val = $input->value;
    is( $val, 10, 'input->stepDown -> 10' );
    $rv = $input->stepUp;
    $val = $input->value;
    is( $val, 10, 'input->stepUp beyond max -> unchanged' );
};

done_testing();

__END__

