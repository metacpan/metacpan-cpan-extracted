use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Differences;
use File::Temp ();
use ExtJS::Generator::DBIC::Model;
use Data::Dump::JavaScript qw( false true );
use lib 't/lib';

BEGIN {
    if ($] < 5.022) {
        require POSIX;
        POSIX::setlocale(&POSIX::LC_ALL, 'C');
    }
}

my $generator = ExtJS::Generator::DBIC::Model->new(
    schemaname => 'My::Schema',
    appname    => 'MyApp',
    json_args  => {
        space_after => 1,
        indent      => 1,
    },
    extjs_args => { extend => 'MyApp.data.Model' },
);

my $extjs_model_for_another;
lives_ok { $extjs_model_for_another = $generator->extjs_model('Another') }
"generation of 'Another' successful";
eq_or_diff(
    $extjs_model_for_another, [
        'MyApp.model.Another', {
            extend => 'MyApp.data.Model',
            alias => 'model.another',
            fields => [ {
                    name => 'id',
                    persist => false,
                    type => 'int',
                }, {
                    allowNull => true,
                    name => 'num',
                    type => 'int',
                },
            ],
            idProperty => 'id',

            #alias  => 'model.another',
            requires => [
                'Ext.data.field.Integer',
            ],
            #uses => [
            #    'MyApp.model.Basic',
            #],
        }
    ],
    "'Another' model ok"
);

my $extjs_models;
lives_ok { $extjs_models = $generator->extjs_models; }
'generation successful';

eq_or_diff(
    $extjs_models, {
        'MyApp.model.Another' => [
            'MyApp.model.Another', {
                extend => 'MyApp.data.Model',
                alias => 'model.another',
                fields => [ {
                        type => 'int',
                        persist => false,
                        name => 'id',
                    }, {
                        allowNull => true,
                        type => 'int',
                        name => 'num',
                    },
                ],
                idProperty => 'id',
                requires => [
                    'Ext.data.field.Integer',
                ],
            },
        ],
        'MyApp.model.Basic' => [
            'MyApp.model.Basic', {
                extend => 'MyApp.data.Model',
                alias => 'model.basic',
                fields => [ {
                        type => 'int',
                        persist => false,
                        name => 'id',
                    }, {
                        allowNull => true,
                        type    => 'int',
                        name    => 'another_id',
                        reference => {
                            inverse => 'get_Basic',
                            role => 'another_id',
                            type => 'Another',
                        },
                    }, {
                        type         => 'boolean',
                        name         => 'boolfield',
                        defaultValue => 1,
                    }, {
                        allowNull => true,
                        type => 'string',
                        name => 'description',
                    }, {
                        allowNull => true,
                        type => 'string',
                        name => 'email',
                    }, {
                        allowNull => true,
                        type => 'string',
                        name => 'emptytagdef',
                    }, {
                        allowNull => true,
                        type         => 'string',
                        defaultValue => '',
                        name         => 'explicitemptystring',
                    }, {
                        allowNull => true,
                        type => 'string',
                        name => 'explicitnulldef',
                    }, {
                        type => 'date',
                        name => 'timest',
                    }, {
                        type         => 'string',
                        defaultValue => 'hello',
                        name         => 'title',
                    },
                ],
                'idProperty' => 'id',
                requires => [
                    'Ext.data.field.Boolean',
                    'Ext.data.field.Date',
                    'Ext.data.field.Integer',
                    'Ext.data.field.String',
                ],
            },
        ],
    },
    "extjs_models output ok"
);

# this creates a File::Temp object which immediatly goes out of scope and
# results in deleting of the dir
my $non_existing_dirname = File::Temp->newdir->dirname;

diag("non-existing dir is $non_existing_dirname");
throws_ok {
    $generator->extjs_model_to_file( 'Another', $non_existing_dirname )
}
qr/No such file or directory/, "non existing output directory throws ok";

{
    my $dir     = File::Temp->newdir;
    my $dirname = $dir->dirname;
    diag("writing 'Another' to $dirname");
    lives_ok { $generator->extjs_model_to_file( 'Another', $dirname ) }
    "file generation of 'Another' ok";
}

{
    my $dir     = File::Temp->newdir;
    my $dirname = $dir->dirname;
    diag("writing all models to $dirname");
    lives_ok { $generator->extjs_all_to_file($dirname) }
    "file generation of all models ok";
}

done_testing;
