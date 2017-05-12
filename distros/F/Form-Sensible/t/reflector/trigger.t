use strict;
use warnings;
use Test::More;
use Form::Sensible;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use MockReflector;
use Data::Dumper;

my $reflector = MockReflector->new(  );
my $form = $reflector->reflect_from( undef, { form => { name => 'test' }, with_trigger => 1 } );
my $reflector_without_submit = MockReflector->new();
my $form_without_submit =
  $reflector_without_submit->reflect_from( undef,
    { form => { name => 'test' } } );

my $expected_without_submit = Form::Sensible->create_form(
    {
        name   => "test",
        fields => [
            {
                field_class => 'Text',
                name        => 'field1',
                validation  => { regex => qr/^(.+){3,}$/ },
            },
            {
                field_class => 'FileSelector',
                name        => 'field2',
                validation  => {},               # wtf do we validate here?
            },
            {
                field_class => 'Text',
                name        => 'field3',
                validation  => {
                    regex =>
                      qr/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/,
                },
            },
        ],
    }
);

my $expected = Form::Sensible->create_form(
    {
        name   => "test",
        fields => [
            {
                field_class => 'Text',
                name        => 'field1',
                validation  => { regex => qr/^(.+){3,}$/ },
            },
            {
                field_class => 'FileSelector',
                name        => 'field2',
                validation  => {},               # wtf do we validate here?
            },
            {
                field_class => 'Text',
                name        => 'field3',
                validation  => {
                    regex =>
                      qr/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/,
                },
            },
            {
                field_class => 'Trigger',
                name        => 'submit',
            }
        ],
    }
);
is_deeply( $form, $expected, "forms compare correctly" );
is_deeply( $form_without_submit, $expected_without_submit, "forms compare correctly" );
done_testing();
