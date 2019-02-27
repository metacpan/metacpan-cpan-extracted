use strict;
use warnings;
use Test::More;
use Storable qw(dclone);

use_ok('Form::Diva');

my $diva1 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form_name => 'diva1',
    form        => [
        { n => 'name', t => 'text', p => 'Your Name', l => 'Full Name' },
        { name => 'phone', type => 'tel', extra => 'required' },
        {qw / n email t email l Email c form-email placeholder doormat/},
        { name => 'our_id', type => 'number', extra => 'disabled' },
    ],    hidden =>
        [ { n => 'secret' }, 
        { n => 'hush', default => 'very secret' },
        { n => 'mystery', id => 'mystery_site_url', 
          extra => 'custom="bizarre"', type => "url"} ],
);

isa_ok($diva1, 'Form::Diva', 'Original object is a Form::Diva');
my $diva2 = $diva1->clone({ 
    neworder => ['our_id', 'email'] });
isa_ok($diva2, 'Form::Diva', 'New object is a Form::Diva');
is( scalar @{$diva2->{FormMap}}, 2, 'new object only has 2 rows in form');
$diva1->{FormHash} = undef;
undef $diva1 ;
note(  'deleting original obj should not affect subsequent tests');
is( $diva1 , undef, 'the original object is now undefined' );
is( $diva2->{FormMap}[1]{name}, 'email', 'last row in copy is email');

my $diva3 = $diva2->clone({ 
    neworder => ['phone', 'name'],
    form_name => 'newform',
    input_class => 'different' });
is( $diva3->{FormMap}[1]{name}, 'name', 'our next copy has name as a field');
#is( $diva3->form_name, 'newform', 'The new form has the new name');
is( $diva3->input_class, 'different', 'The new input_class is in effect');
is( $diva3->label_class, 'testclass', 'but we didnt change label_class');
is( $diva3->{HiddenMap}[1]{name},'hush', 
    'Check a hidden field to make sure it was cloned.');
my $diva4 = $diva2->clone({ 
    neworder => ['phone', 'name', 'secret', 'mystery', ],
    newhidden   => [ 'our_id', 'hush'],
    form_name => 'newform',
    id_base => 'new_clone_',
    input_class => 'different' });
is( $diva4->{FormMap}[0]{name}, 'phone', 'successfully crossmapped');
is( $diva4->{FormMap}[1]{name}, 'name', 'where one field moved');
is( $diva4->{FormMap}[2]{name}, 'secret', 'from hidden to normal');
is( $diva4->{HiddenMap}[0]{name}, 'our_id', 'and another got hid');
is( $diva4->{HiddenMap}[1]{name}, 'hush', '...');
is( $diva4->{FormMap}[3]{extra}, 'custom="bizarre"', 
    'test extra attribute of hidden converted to other type');
is( $diva4->{FormMap}[3]{type}, 'url', 
    'test type of hidden converted to other type');
is( $diva4->{FormMap}[3]{id}, 'mystery_site_url', 
    'test id of hidden converted to other type');

my $generated4 = $diva4->generate ;
is( $generated4->[2]{input},
    '<INPUT type="text" name="secret" id="formdiva_secret" class="different" value="">',
    'previously hidden field is now a textfield'     );
is( $generated4->[2]{label},
   '<LABEL for="formdiva_secret" id="formdiva_secret_label" class="testclass">Secret</LABEL>',
   'label for previously hidden secret field' );
like( $generated4->[3]{input},
   qr/id="mystery_site_url"/,
   'id for previously hidden field in generated input' );
like( $generated4->[3]{input},
   qr/type="url"/,
   'type for previously hidden field in generated input' );
like( $generated4->[3]{input},
   qr/custom="bizarre"/,
   'extra for previously hidden field in generated input' );
done_testing();
