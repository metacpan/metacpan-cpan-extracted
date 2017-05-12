use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "t/lib";
use DateTime;
use TestSchema;
my $lib_dir = $FindBin::Bin;
my @dirs = split '/', $lib_dir;
pop @dirs;
$lib_dir = join( '/', @dirs );
chomp $lib_dir;
my $schema = TestSchema->connect('dbi:SQLite::memory:');
$schema->deploy;
use Form::Sensible;
use Form::Sensible::Reflector::DBIC;
use Data::Dumper;
my $dt = DateTime->now;

# reflector WITH a submit button;
my $reflector = Form::Sensible::Reflector::DBIC->new();
my $form      = $reflector->reflect_from( $schema->resultset("Test"),
  { form => { name => 'test' }, with_trigger => 1 } );
my $renderer = Form::Sensible->get_renderer('HTML');

my $form2 = Form::Sensible->create_form(
  {
    name   => 'test',
    fields => [
      {
        field_class => 'Text',
        name        => 'username',
        validation  => {
          regex    => qr/^(.+){3,}$/,
          required => 1,
        },
      },
      {
        field_class => 'FileSelector',
        name        => 'file_upload',
        validation  => { required => 1, },    # wtf do we validate here?
      },
      {
        field_class        => 'Text',
        name               => 'date',
        default_form_value => $dt,
        validation         => {
          regex    => qr/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/,
          required => 1,
        },
      },
      {
        field_class => 'LongText',
        name        => 'big_text',
        validation  => {
          regex    => qr/^(.+){3,}$/,
          required => 1,
        },
      },
      {
        field_class  => 'Number',
        name         => 'number',
        integer_only => 1,
        validation   => {
          regex    => qr/^[0-9]+$/,
          required => 1,
        },
      },
      {
        field_class => 'Number',
        name        => 'decimal',
        validation  => {
          regex    => qr/^(\d.+)\.(\d.+)$/,
          required => 1,
        },

      },
      {
        field_class  => 'Number',
        name         => 'big_number',
        integer_only => 1,
        validation   => {
          regex    => qr/^[0-9]+$/,
          required => 1,
        },
      },

      {
        field_class => 'Text',
        name        => 'password',
        validation  => {
          regex    => qr/^(?=.{8,})(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).*$/,
          required => 1,
        },
      },
      {
        field_class => 'Trigger',
        name        => 'submit',
      },
    ],
  }
);

my $good_values = {
  username   => "dhoss",
  date       => "2008-09-01 12:35:45",
  big_text   => "asdflkjawofij24fj2i3f4j 2903 dfnqe2fw f",
  number     => 123,
  decimal    => 12.34,
  big_number => 1243567,
  password   => "mMMmm123",
};

my $bad_values = {
  username   => "1",
  date       => "Today",
  big_text   => "1",
  number     => "three",
  decimal    => 1,
  big_number => 2,
  password   => "a",
};

$form->set_values($good_values);
$form2->set_values($good_values);
my $v1 = $form->validate;
my $v2 = $form2->validate;
TODO: {
  local $TODO = "These need fixing";
  ok( $v1->is_valid, "form 1 valid" );
  ok( $v2->is_valid, "form 2 valid" );
  $form->set_values($bad_values);
  $form2->set_values($bad_values);
  my $bv1 = $form->validate;
  my $bv2 = $form2->validate;

  ok( !$bv1->is_valid, "form 1 invalid" );
  ok( !$bv2->is_valid, "form 2 invalid" );
  $form->set_values($good_values);
  $form2->set_values($good_values);
}
my $renderer2 = Form::Sensible->get_renderer('HTML');
my $output    = $renderer->render($form)->complete;
my $output_2  = $renderer2->render($form2)->complete;
is_deeply( $form->flatten, $form2->flatten,
  "form one hash matches form two hash" );

cmp_ok( $output, 'eq', $output_2, "Flat eq to pulled from DBIC" );
cmp_ok( $output, 'eq', $output_2, "Flat eq to pulled from DBIC" );

done_testing;
