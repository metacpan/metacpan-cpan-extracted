use strict;
use warnings;

use Test::More;
use Mail::Sendmail::Enhanced;

my $mail = Mail::Sendmail::Enhanced-> new (
    smtp     => 'example.com',
    from     => 'user@example.com',
    user     => 'user',
    pass     => 'password',
    method   => 'LOGIN',
    charset  => 'utf-8',
    required => 1,
    mime     => 0,
);

plan tests => 5;
#---------------------------------------------------------------------
#Test 1:
ok ( $mail->{smtp} eq 'example.com' );
#---------------------------------------------------------------------
#Test 2:
ok ( Mail::Sendmail::Enhanced::encode_qp('ąćęłńóśźż1234567890ĄĆĘŁŃÓŚŹŻ0987654321ąćęłńóśźż1234567890ĄĆĘŁŃÓŚŹŻ0987654321ąćęłńóśźż1234567890ĄĆĘŁŃÓŚŹŻ0987654321')
  eq
" =C4=85=C4=87=C4=99=C5=82=C5=84=C3=B3=C5=9B=C5=BA=C5=BC1234567890=C4
 =84=C4=86=C4=98=C5=81=C5=83=C3=93=C5=9A=C5=B9=C5=BB0987654321=C4=85=C4=87=C4
 =99=C5=82=C5=84=C3=B3=C5=9B=C5=BA=C5=BC1234567890=C4=84=C4=86=C4=98=C5=81=C5
 =83=C3=93=C5=9A=C5=B9=C5=BB0987654321=C4=85=C4=87=C4=99=C5=82=C5=84=C3=B3=C5
 =9B=C5=BA=C5=BC1234567890=C4=84=C4=86=C4=98=C5=81=C5=83=C3=93=C5=9A=C5=B9=C5
 =BB0987654321
");
#---------------------------------------------------------------------
#Test 3:
ok ( $mail-> send({to=>'user@example.com',subject=>'',message=>'',attachments_size_max=>  -1,attachments=>{'01-module.t'=>'t/01-module.t'}})
  eq 'Attachments are not allowed whereas some are preperad to send!');
#---------------------------------------------------------------------
#Test 4:
ok ( $mail-> send({to=>'user@example.com',subject=>'',message=>'',attachments_size_max=>1000,attachments=>{'01-module.t'=>'t/01-module.t'}})
  eq 'Attachment too big! [t/01-module.t: 2084 > 1000B max.]');
#---------------------------------------------------------------------
#Test 5:
ok ( $mail-> send({to=>'user@example.com',subject=>'',message=>'',attachments_size_max=>   0,attachments=>{'02-dream.t'=>'t/02-dream.t'}})
  eq 'Attachment does not exists! [t/02-dream.t]');
#---------------------------------------------------------------------
