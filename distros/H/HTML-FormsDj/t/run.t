# -*-perl-*-
# testscript for HTML::FormsDj Classes by T. Linden
#
# needs to be invoked using the command "make test"
#
# Under normal circumstances every test should succeed.


use Data::Dumper;
#use Test::More tests => 57;
use Test::More qw(no_plan);


### 1
BEGIN { use_ok "HTML::FormsDj"};
require_ok( 'HTML::FormsDj' );

### 2
my $form = new HTML::FormsDj(
    field => {
              user => {
                       type     => 'text',
                       validate => sub { return 1; },
                       required => 1,
                      },
              password => {
                           name     => 'password',
                           type     => 'password',
                           validate => sub { return 1; },
                           required => 1,
                          },
   },
   name       => 'registerform',
);

my $pfield = {
                          'classes' => [
                                         'formfield'
                                       ],
                          'value' => '',
                          'default' => '',
                          'message' => '',
                          'label' => 'Password',
                          'id' => 'id_formfield_password',
                          'type' => 'password',
                          'field' => 'password'
                        };

my $empty = $form->as_is();
ok($empty->{fields}, 'meta generation');
foreach my $field ( @{$empty->{fields}}) {
  if($field->{field} eq 'password') {
    is_deeply($field, $pfield, 'check meta generated field');
  }
}

my $html = $form->as_p();
if($html =~ /input type/) {
  pass('html generation');
}
else {
  fail('html generation');
}
