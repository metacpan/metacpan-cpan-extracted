#!perl -T
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Form::Toolkit::Test;
use Form::Toolkit::Clerk::Hash;

use DateTime;

ok( my $f = Form::Toolkit::Test->new() );
ok( scalar( @{$f->fields()} ) , "Ok form has fields");
# foreach my $field ( @{$f->fields() }){
#   diag($field->name().' '.join(',' , $field->meta->linearized_isa()));
# }


$f->clear();
ok( my $clerk = Form::Toolkit::Clerk::Hash->new( source => { field_String => 'Blabla' , field_Date => '2011-10-10',
                                                          field_Boolean => 'Something true',
                                                          field_Integer => '100',
                                                          mandatory_and_long => '   ', ## Blank will trigger error too.
                                                        } ) );
ok( $clerk->fill_form($f) , "Ok the clerk can fill the form" );
ok( $f->field('field_Boolean')->value() , "Ok boolean field is true");
ok( $f->field('mandatory_and_long')->has_errors() , "Ok mandatory and long string has errors");
## diag(join(',' , @{$f->field('mandatory_and_long')->errors()} )  );
$f->reset();



ok( $clerk = Form::Toolkit::Clerk::Hash->new( source => { field_String => 'Blabla' , field_Date => 'BAD_DATE_STRING',
                                                       mandatory_and_long => 'S',
                                                       field_Set => [ 1 , 2 , 3 , 4 ],
                                                     } ) );
ok( $clerk->fill_form($f) , "Ok the clerk can fill the form" );
ok( $f->has_errors() , "Form has errors");
ok( $f->field('mandatory_str')->has_errors() , "Ok mandatory string has errors!");
ok( $f->field('mandatory_str')->does_role('Mandatory') , "Ok mandatory role test is valid");
ok( $f->field('mandatory_str')->does_role('+Form::Toolkit::FieldRole::Mandatory') , "Also works with explicit class");
ok( $f->field('mandatory_and_long')->has_errors() , "Ok mandatory and long string has errors");
$f->clear();
ok( ! $f->has_errors() , "Form has no errors after clear");

ok( $clerk = Form::Toolkit::Clerk::Hash->new( source => { field_String => 'Blabla' , field_Date => 'BAD_DATE_STRING',
                                                       mandatory_and_long => 'SJISJISJJ'
                                                     } ) );
ok( $clerk->fill_form($f) , "Ok the clerk can fill the form" );
ok( $f->has_errors() , "Form has errors");
ok( $f->field('mandatory_str')->has_errors() , "Ok mandatory string has errors!");
ok( ! $f->field('mandatory_and_long')->has_errors() , "Ok mandatory and long is ok");
$f->clear();
ok( ! $f->has_errors() , "Form has no errors after clear");

## Add a field that would be a repeat of the mandatory_str.
$f->add_field('String' , 'repeat_mand')->add_role('Repeat')->repeat_field($f->field('mandatory_and_long'));
$clerk->fill_form($f);
ok( $f->field('repeat_mand')->has_errors() , "Ok repeat_field has errors");
ok( $clerk = Form::Toolkit::Clerk::Hash->new( source => { field_String => 'Blabla' , field_Date => '1977-10-20',
                                                       mandatory_str => 'Something',
                                                       mandatory_and_long => 'SJISJISJJ',
                                                       repeat_mand => 'SJISJISJJ'
                                                     } ) );
$f->clear();
ok( ! $f->has_errors() );

$clerk->fill_form($f);
ok( ! $f->has_errors() , "Ok no global form errors");
ok( ! $f->field('repeat_mand')->has_errors() , "Ok repeat field is ok" );


ok( $clerk = Form::Toolkit::Clerk::Hash->new( source => { field_String => 'Blabla' , field_Date => '1977-10-20',
                                                       mandatory_str => 'Something',
                                                       mandatory_and_long => 'SJISJISJJ',
                                                       repeat_mand => 'SJISJISJJ',
                                                       email => '"£$%^&*(',
                                                     } ) );
$f->clear();
$clerk->fill_form($f);
ok( $f->has_errors() , "Has error because of emails");
ok( $f->field('email')->has_errors() , "Email field has errors" );

ok( $clerk = Form::Toolkit::Clerk::Hash->new( source => { field_String => 'Blabla' , field_Date => '1977-10-20',
                                                       mandatory_str => 'Something',
                                                       mandatory_and_long => 'SJISJISJJ',
                                                       repeat_mand => 'SJISJISJJ',
                                                       email => '            patriCIA.lemoine@example.com   ',
                                                     } ) );
$f->clear();
$clerk->fill_form($f);
ok( ! $f->has_errors() , "Has error because of emails");
ok( ! $f->field('email')->has_errors() , "Email field has errors" );
cmp_ok( $f->field('email')->value() , 'eq' , 'patricia.lemoine@example.com' );

done_testing();
