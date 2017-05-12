use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Data::Dumper;
use Form::Sensible;

use Form::Sensible::Form;

my $lib_dir = $FindBin::Bin;
my @dirs = split '/', $lib_dir;
pop @dirs;
$lib_dir = join('/', @dirs);

my $form = Form::Sensible->create_form( {
                                            name => 'test',
                                            fields => [
{
        field_class => 'FileSelector',
        name => 'upload_file',
        valid_extensions => [ "jpg", "gif", "png" ],
        maximum_size => 262144,
},
                                                      ],
                                        } );

$form->set_values( {
    upload_file => '/etc/motd',
});
my $validation_result = $form->validate();
ok( !$validation_result->is_valid(), 'file upload with wrong extension' );

done_testing();
